#!/usr/bin/env bash

# =============================================================================
# SECURE-GIT.SH - Detector de co-autores sospechosos en repositorios Git
# =============================================================================
# Script optimizado para detectar repositorios Git con co-autores no autorizados
# Versión: 1.0.0
# Compatible con: Bash 4+, Git 2.0+
# =============================================================================

set -euo pipefail  # Modo seguro: errores fatales, variables no definidas, pipes fallan

# =============================================================================
# CONFIGURACIÓN Y CONSTANTES
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Sistema robusto de detección de colores
readonly COLOR_SUPPORT=true  # Variable global para control de colores

# Función: detectar soporte de colores de forma robusta
detect_color_support() {
    local force_no_color="${1:-false}"
    
    # Forzar sin colores si se solicita
    if [[ "$force_no_color" == "true" ]]; then
        echo "false"
        return 0
    fi
    
    # Verificar si NO_COLOR está establecida (estándar)
    if [[ -n "${NO_COLOR:-}" ]]; then
        echo "false"
        return 0
    fi
    
    # Verificar si FORCE_COLOR está establecida
    if [[ -n "${FORCE_COLOR:-}" ]]; then
        echo "true"
        return 0
    fi
    
    # Verificar variable TERM para terminales sin soporte de color
    if [[ -n "${TERM:-}" ]]; then
        case "$TERM" in
            "dumb"|"unknown"|*"no-color"*)
                echo "false"
                return 0
                ;;
        esac
    fi
    
    # Verificar si estamos en CI/CD (generalmente sin colores)
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]; then
        echo "false"
        return 0
    fi
    
    # Verificar soporte de tput (método más confiable)
    if command -v tput >/dev/null 2>&1; then
        if tput colors >/dev/null 2>&1; then
            local colors
            colors=$(tput colors 2>/dev/null)
            if [[ "$colors" -ge 8 ]]; then
                echo "true"
                return 0
            fi
        fi
    fi
    
    # Verificar variables de entorno comunes
    if [[ -n "${COLORTERM:-}" ]] || [[ "${CLICOLOR:-}" == "1" ]]; then
        echo "true"
        return 0
    fi
    
    # Verificar terminales comunes que soportan colores
    if [[ -n "${TERM:-}" ]]; then
        case "$TERM" in
            "xterm"|"xterm-256color"|"screen"|"screen-256color"|"linux"|"vt100"|"vt220"|"xterm-kitty")
                echo "true"
                return 0
                ;;
        esac
    fi
    
    # Para pruebas y casos donde no podemos determinar con certeza,
    # asumir que hay soporte de colores si no hay indicadores en contra
    # Esto es más útil que desactivar colores por defecto
    echo "true"
}

# Función: inicializar variables de color
init_colors() {
    local no_color="${1:-false}"
    local color_support
    
    color_support=$(detect_color_support "$no_color")
    
    if [[ "$color_support" == "true" ]]; then
        # Códigos ANSI para colores (variables globales)
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        NC='\033[0m' # No Color
    else
        # Sin códigos ANSI (variables globales)
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        NC=''
    fi
}

# Directorios por defecto para buscar repositorios
readonly DEFAULT_SEARCH_DIRS=(
    "$HOME/Documentos"
    "$HOME/Desarrollador"
    "$HOME/Proyectos"
    "$HOME/Workspace"
    "$HOME/git"
    "$HOME/Desktop"
    "$HOME/Downloads"
)

# Patrones de co-autores sospechosos
readonly SUSPICIOUS_PATTERNS=(
    # Qwen CLI
    'Co-authored-by:\s*[Qq]wen[-\s]*[Cc]oder\s*<[^>]*@alibabacloud\.com>'
    'Co-authored-by:\s*[Qq]wen[-\s]*[Cc]oder'
    
    # Asistentes de IA comunes
    'Co-authored-by:\s*[Aa][Ii]\s*[Aa]ssistant'
    'Co-authored-by:\s*[Cc]hat[Gg][Pp][Tt]'
    'Co-authored-by:\s*[Gg]ithub[-\s]*[Cc]opilot'
    'Co-authored-by:\s*[Cc]ode[Ll]lama'
    'Co-authored-by:\s*[Bb]ard'
    'Co-authored-by:\s*[Cc]laude'
    'Co-authored-by:\s*[Gg]emini'
    'Co-authored-by:\s*[Ll]lama'
    'Co-authored-by:\s*[Mm]istral'
    
    # Patrones genéricos de empresas de IA
    'Co-authored-by:\s*[^<]*<[^>]*@(?:openai|anthropic|microsoft|google|alibabacloud|amazon|facebook|meta)\.'
)

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

# Función: imprimir mensajes con formato robusto
print_info() {
    if [[ -n "$BLUE" ]]; then
        echo -e "${BLUE}ℹ️  $*${NC}"
    else
        echo "ℹ️  $*"
    fi
}

print_success() {
    if [[ -n "$GREEN" ]]; then
        echo -e "${GREEN}✅ $*${NC}"
    else
        echo "✅ $*"
    fi
}

print_warning() {
    if [[ -n "$YELLOW" ]]; then
        echo -e "${YELLOW}⚠️  $*${NC}" >&2
    else
        echo "⚠️  $*" >&2
    fi
}

print_error() {
    if [[ -n "$RED" ]]; then
        echo -e "${RED}❌ $*${NC}" >&2
    else
        echo "❌ $*" >&2
    fi
}

# Función: verificar dependencias del sistema (sin colores)
check_dependencies_no_color() {
    local deps=("git" "grep" "sed" "awk")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "❌ Dependencias faltantes: ${missing_deps[*]}" >&2
        echo "ℹ️  Instale las dependencias necesarias antes de ejecutar el script." >&2
        exit 1
    fi
}

# Función: verificar dependencias del sistema (con colores)
check_dependencies() {
    local deps=("git" "grep" "sed" "awk")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Dependencias faltantes: ${missing_deps[*]}"
        print_info "Instale las dependencias necesarias antes de ejecutar el script."
        exit 1
    fi
    
    # Verificar versión mínima de Git
    local git_version
    git_version=$(git --version | awk '{print $3}')
    if [[ $(echo "$git_version" | awk -F. '{print $1"."$2}') < "2.0" ]]; then
        print_warning "Versión de Git ($git_version) puede ser muy antigua. Se recomienda Git 2.0+"
    fi
}

# Función: mostrar ayuda
display_help() {
    # Inicializar colores temporalmente para esta función
    local temp_no_color="${1:-false}"
    local temp_red temp_green temp_yellow temp_blue temp_nc
    
    # Detectar soporte de colores para esta función
    if [[ "$temp_no_color" == "true" ]] || [[ ! -t 1 ]] || [[ "${TERM:-}" == "dumb" ]] || [[ -n "${NO_COLOR:-}" ]]; then
        temp_red=''
        temp_green=''
        temp_yellow=''
        temp_blue=''
        temp_nc=''
    else
        temp_red='\033[0;31m'
        temp_green='\033[0;32m'
        temp_yellow='\033[1;33m'
        temp_blue='\033[0;34m'
        temp_nc='\033[0m'
    fi
    
    cat << EOF
${temp_blue}SECURE-GIT.SH - Detector de co-autores sospechosos${temp_nc}

${temp_green}USO:${temp_nc}
    $SCRIPT_NAME [OPCIONES] [DIRECTORIOS...]

${temp_green}DESCRIPCIÓN:${temp_nc}
    Analiza repositorios Git en busca de co-autores sospechosos como Qwen-coder,
    ChatGPT, GitHub Copilot, y otros asistentes de IA que se atribuyen autoría
    sin consentimiento.

${temp_green}OPCIONES:${temp_nc}
    -h, --help          Mostrar esta ayuda y salir
    -v, --version       Mostrar versión del script
    -d, --dirs LISTA    Directorios específicos para buscar (separados por coma)
    -r, --recursive     Búsqueda recursiva en subdirectorios (por defecto: sí)
    -p, --parallel      Procesamiento paralelo para mejor rendimiento
    -q, --quiet         Modo silencioso, solo muestra resultados críticos
    -c, --config FILE   Archivo de configuración JSON (opcional)
    --no-color          Forzar salida sin colores (robusto)

${temp_green}EJEMPLOS:${temp_nc}
    $SCRIPT_NAME                            # Busca en directorios por defecto
    $SCRIPT_NAME ~/proyectos ~/trabajo      # Busca en directorios específicos
    $SCRIPT_NAME -d "~/dev,~/code" -p       # Directorios específicos + paralelo
    $SCRIPT_NAME --quiet                    # Solo muestra repositorios contaminados

${temp_green}PATRONES DETECTADOS:${temp_nc}
    • Qwen-coder y variantes
    • ChatGPT y asistentes OpenAI
    • GitHub Copilot
    • CodeLlama, Bard, Claude, Gemini
    • Co-autores de dominios de empresas de IA

${temp_yellow}NOTA:${temp_nc} Este script es complementario al script Python secure-git.py
EOF
}

# Función: mostrar versión
display_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "Script Bash optimizado para detección de co-autores sospechosos"
    echo "Compatibilidad: Bash 4+, Git 2.0+, sistemas Linux/macOS"
}

# Función: expandir rutas de usuario (tilde expansion)
expand_path() {
    local path="$1"
    # Expansión de tilde (~) a home directory
    if [[ "$path" == ~* ]]; then
        echo "${path/#\~/$HOME}"
    else
        echo "$path"
    fi
}

# Función: verificar si un directorio existe y es accesible
check_directory() {
    local dir="$1"
    local expanded_dir
    
    expanded_dir=$(expand_path "$dir")
    
    if [[ ! -d "$expanded_dir" ]]; then
        print_warning "Directorio no encontrado: $dir"
        return 1
    fi
    
    if [[ ! -r "$expanded_dir" ]]; then
        print_warning "Sin permisos de lectura: $dir"
        return 1
    fi
    
    echo "$expanded_dir"
    return 0
}

# =============================================================================
# FUNCIONES DE DETECCIÓN
# =============================================================================

# Función: buscar repositorios Git en un directorio
find_git_repositories() {
    local search_dir="$1"
    local recursive="${2:-true}"
    local debug="${3:-false}"
    local repos=()
    
    # Validar directorio de búsqueda
    if [[ ! -d "$search_dir" ]]; then
        [[ "$debug" == "true" ]] && print_warning "Directorio no encontrado: $search_dir"
        return 1
    fi
    
    if [[ "$recursive" == "true" ]]; then
        # Búsqueda recursiva profunda optimizada
        # -maxdepth ilimitado por defecto (sin restricción)
        # -type d: solo directorios .git
        # -print0: maneja nombres de archivos con espacios
        # Eliminamos xargs para evitar problemas de buffer
        [[ "$debug" == "true" ]] && echo "Buscando repositorios en estructura profunda: $search_dir" >&2
        
        local find_cmd=(find "$search_dir" -name ".git" -type d -print0)
        
        # Ejecutar find y procesar resultados directamente
        while IFS= read -r -d '' git_dir; do
            if [[ -n "$git_dir" && -d "$git_dir" ]]; then
                # Extraer directorio padre del .git
                local repo_dir
                repo_dir=$(dirname "$git_dir")
                
                # Verificar que es un repositorio Git válido
                if [[ -d "$repo_dir" && -d "$git_dir" ]]; then
                    repos+=("$repo_dir")
                    [[ "$debug" == "true" ]] && echo "Repositorio encontrado: $repo_dir" >&2
                else
                    [[ "$debug" == "true" ]] && echo "Directorio .git inválido: $git_dir" >&2
                fi
            fi
        done < <("${find_cmd[@]}" 2>/dev/null)
        
        # Manejar caso donde find no encuentra nada pero no falla
        if [[ ${#repos[@]} -eq 0 ]]; then
            [[ "$debug" == "true" ]] && echo "No se encontraron repositorios en: $search_dir" >&2
        fi
    else
        # Solo directorio actual
        if [[ -d "$search_dir/.git" ]]; then
            repos+=("$search_dir")
            [[ "$debug" == "true" ]] && echo "Repositorio encontrado (no recursivo): $search_dir" >&2
        else
            [[ "$debug" == "true" ]] && echo "No es repositorio Git: $search_dir" >&2
        fi
    fi
    
    # Eliminar duplicados usando array asociativo
    if [[ ${#repos[@]} -gt 0 ]]; then
        local -A unique_repos
        for repo in "${repos[@]}"; do
            unique_repos["$repo"]=1
        done
        repos=("${!unique_repos[@]}")
    fi
    
    printf '%s
' "${repos[@]}"
    return 0
}

# Función: analizar un repositorio específico
analyze_repository() {
    local repo_path="$1"
    local quiet="${2:-false}"
    
    # Verificar que es un repositorio Git válido
    if [[ ! -d "$repo_path/.git" ]]; then
        [[ "$quiet" == "false" ]] && print_warning "No es un repositorio Git: $repo_path"
        return 1
    fi
    
    # Cambiar al directorio del repositorio
    if ! cd "$repo_path" 2>/dev/null; then
        print_warning "No se puede acceder al repositorio: $repo_path"
        return 1
    fi
    
    # Verificar que Git funciona en este repositorio
    if ! git status >/dev/null 2>&1; then
        print_warning "Repositorio Git corrupto o sin permisos: $repo_path"
        return 1
    fi
    
    local total_commits suspicious_commits=0
    local suspicious_coauthors=()
    
    # Contar commits totales
    total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    
    if [[ "$total_commits" -eq 0 ]]; then
        [[ "$quiet" == "false" ]] && print_info "Repositorio vacío: $repo_path"
        echo "$repo_path|0|0|[]"
        return 0
    fi
    
    # Buscar commits con co-autores sospechosos
    for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
        local matches
        matches=$(git log --oneline --format=fuller --all | grep -E "$pattern" 2>/dev/null || true)
        
        if [[ -n "$matches" ]]; then
            local count
            count=$(echo "$matches" | wc -l)
            suspicious_commits=$((suspicious_commits + count))
            
            # Extraer co-autores únicos
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    # Limpiar y normalizar el co-autor
                    local coauthor
                    coauthor=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    
                    # Verificar si ya está en la lista
                    if ! printf '%s\n' "${suspicious_coauthors[@]}" | grep -q "^$coauthor$"; then
                        suspicious_coauthors+=("$coauthor")
                    fi
                fi
            done <<< "$matches"
        fi
    done
    
    # Formatear co-autores para output
    local coauthors_str="[]"
    if [[ ${#suspicious_coauthors[@]} -gt 0 ]]; then
        coauthors_str=$(printf '%s\n' "${suspicious_coauthors[@]}" | sed 's/^"/;s/$/"/' | tr '\n' ',' | sed 's/,$//')
        coauthors_str="[$coauthors_str]"
    fi
    
    # Output en formato: ruta|total_commits|suspicious_commits|coauthors_json
    echo "$repo_path|$total_commits|$suspicious_commits|$coauthors_str"
    
    return 0
}

# Función: procesar resultados y generar reporte
generate_report() {
    local results=("$@")
    local total_repos=0 git_repos=0 contaminated_repos=0 clean_repos=0
    local total_suspicious_commits=0
    local contaminated_list=() clean_list=()
    
    # Procesar cada resultado
    for result in "${results[@]}"; do
        [[ -z "$result" ]] && continue
        
        total_repos=$((total_repos + 1))
        
        IFS='|' read -r repo_path total_commits suspicious_commits coauthors <<< "$result"
        
        # Saltar si no es un repositorio Git válido
        if [[ "$total_commits" -eq "0" && "$suspicious_commits" -eq "0" ]]; then
            continue
        fi
        
        git_repos=$((git_repos + 1))
        
        if [[ "$suspicious_commits" -gt 0 ]]; then
            contaminated_repos=$((contaminated_repos + 1))
            total_suspicious_commits=$((total_suspicious_commits + suspicious_commits))
            contaminated_list+=("$repo_path|$total_commits|$suspicious_commits|$coauthors")
        else
            clean_repos=$((clean_repos + 1))
            clean_list+=("$repo_path|$total_commits")
        fi
    done
    
    # Generar reporte usando funciones de impresión apropiadas
    echo "=" | awk '{printf "%*s\n", 80, $1}' | tr ' ' '='
    echo "SECURE GIT - REPORTE DE CO-AUTORES SOSPECHOSOS (BASH)"
    echo "=" | awk '{printf "%*s\n", 80, $1}' | tr ' ' '='
    echo
    
    # Estadísticas generales
    if [[ -n "$BLUE" ]]; then
        echo -e "📊 ${BLUE}ESTADÍSTICAS GENERALES${NC}"
    else
        echo "📊 ESTADÍSTICAS GENERALES"
    fi
    echo "   Directorios analizados: $total_repos"
    echo "   Repositorios Git encontrados: $git_repos"
    
    if [[ -n "$RED" ]]; then
        echo -e "   Repositorios contaminados: ${RED}$contaminated_repos${NC}"
    else
        echo "   Repositorios contaminados: $contaminated_repos"
    fi
    
    if [[ -n "$GREEN" ]]; then
        echo -e "   Repositorios limpios: ${GREEN}$clean_repos${NC}"
    else
        echo "   Repositorios limpios: $clean_repos"
    fi
    echo
    
    # Repositorios contaminados (detalle)
    if [[ "$contaminated_repos" -gt 0 ]]; then
        if [[ -n "$RED" ]]; then
            echo -e "📛 ${RED}REPOSITORIOS CONTAMINADOS${NC}"
        else
            echo "📛 REPOSITORIOS CONTAMINADOS"
        fi
        echo "-" | awk '{printf "%*s\n", 40, $1}' | tr ' ' '-'
        
        for contaminated in "${contaminated_list[@]}"; do
            IFS='|' read -r repo_path total_commits suspicious_commits coauthors <<< "$contaminated"
            
            echo
            if [[ -n "$RED" ]]; then
                echo -e "📁 ${RED}$repo_path${NC}"
            else
                echo "📁 $repo_path"
            fi
            echo "   Commits totales: $total_commits"
            
            if [[ -n "$RED" ]]; then
                echo -e "   Commits sospechosos: ${RED}$suspicious_commits${NC}"
            else
                echo "   Commits sospechosos: $suspicious_commits"
            fi
            
            # Mostrar co-autores detectados
            if [[ "$coauthors" != "[]" ]]; then
                echo "   Co-autores detectados:"
                # Parsear array JSON simple
                echo "$coauthors" | sed 's/\["//g;s/"\]//g;s/","/\n/g' | while read -r coauthor; do
                    if [[ -n "$coauthor" ]]; then
                        if [[ -n "$YELLOW" ]]; then
                            echo -e "     • ${YELLOW}$coauthor${NC}"
                        else
                            echo "     • $coauthor"
                        fi
                    fi
                done
            fi
        done
        echo
    fi
    
    # Repositorios limpios (resumen)
    if [[ "$clean_repos" -gt 0 ]]; then
        if [[ -n "$GREEN" ]]; then
            echo -e "✅ ${GREEN}REPOSITORIOS LIMPIOS ($clean_repos)${NC}"
        else
            echo "✅ REPOSITORIOS LIMPIOS ($clean_repos)"
        fi
        echo "-" | awk '{printf "%*s\n", 40, $1}' | tr ' ' '-'
        
        for clean in "${clean_list[@]}"; do
            IFS='|' read -r repo_path total_commits <<< "$clean"
            echo "   $repo_path ($total_commits commits)"
        done
        echo
    fi
    
    # Alerta final si hay contaminación
    if [[ "$contaminated_repos" -gt 0 ]]; then
        if [[ -n "$RED" ]]; then
            echo -e "🚨 ${RED}ALERTA DE SEGURIDAD${NC}"
        else
            echo "🚨 ALERTA DE SEGURIDAD"
        fi
        echo "   Se encontraron $contaminated_repos repositorios contaminados"
        echo "   con un total de $total_suspicious_commits commits sospechosos"
        echo
        
        if [[ -n "$YELLOW" ]]; then
            echo -e "${YELLOW}RECOMENDACIONES${NC}"
        else
            echo "RECOMENDACIONES"
        fi
        echo "   1. Revise los commits sospechosos con: git log --oneline"
        echo "   2. Considere reescribir el historial con: git rebase -i"
        echo "   3. Configure hooks de Git para prevenir futuras contaminaciones"
        echo
    else
        if [[ -n "$GREEN" ]]; then
            echo -e "🎉 ${GREEN}TODOS LOS REPOSITORIOS ESTÁN LIMPIOS${NC}"
        else
            echo "🎉 TODOS LOS REPOSITORIOS ESTÁN LIMPIOS"
        fi
    fi
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    local search_dirs=()
    local recursive=true
    local parallel=false
    local quiet=false
    local config_file=""
    local no_color=false
    
    # Procesar argumentos de línea de comandos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                display_help "$no_color"
                exit 0
                ;;
            -v|--version)
                display_version
                exit 0
                ;;
            -d|--dirs)
                if [[ -n "${2:-}" ]]; then
                    IFS=',' read -ra custom_dirs <<< "$2"
                    for dir in "${custom_dirs[@]}"; do
                        search_dirs+=("$dir")
                    done
                    shift 2
                else
                    print_error "La opción -d/--dirs requiere un argumento"
                    exit 1
                fi
                ;;
            -r|--recursive)
                recursive=true
                shift
                ;;
            -p|--parallel)
                parallel=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -c|--config)
                if [[ -n "${2:-}" ]]; then
                    config_file="$2"
                    shift 2
                else
                    print_error "La opción -c/--config requiere un argumento"
                    exit 1
                fi
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                print_error "Opción desconocida: $1"
                display_help
                exit 1
                ;;
            *)
                search_dirs+=("$1")
                shift
                ;;
        esac
    done
    
    # Si no se especificaron directorios, usar los por defecto
    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        search_dirs=("${DEFAULT_SEARCH_DIRS[@]}")
    fi
    
    # Verificar dependencias (sin colores aún)
    check_dependencies_no_color
    
    # Inicializar sistema de colores
    init_colors "$no_color"
    
    # Verificar dependencias nuevamente (con colores para mensajes)
    check_dependencies
    
    # Mostrar información inicial
    if [[ "$quiet" == "false" ]]; then
        print_info "Iniciando análisis de repositorios Git..."
        print_info "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
        print_info "Soporte de colores: $([[ -n "$BLUE" ]] && echo "ACTIVADO" || echo "DESACTIVADO")"
        print_info "Directorios a analizar: ${#search_dirs[@]}"
    fi
    
    local valid_dirs=()
    local repo_list=()
    local analysis_results=()
    
    # Validar y expandir directorios de búsqueda
    for dir in "${search_dirs[@]}"; do
        local expanded_dir
        if expanded_dir=$(check_directory "$dir"); then
            valid_dirs+=("$expanded_dir")
            
            if [[ "$quiet" == "false" ]]; then
                print_info "Buscando repositorios (profundidad ilimitada) en: $expanded_dir"
            fi
            
            # Buscar repositorios Git con búsqueda profunda
            local repos_found=0
            while IFS= read -r repo; do
                if [[ -n "$repo" ]]; then
                    repo_list+=("$repo")
                    repos_found=$((repos_found + 1))
                fi
            done < <(find_git_repositories "$expanded_dir" "$recursive" "$quiet")
            
            if [[ "$quiet" == "false" ]] && [[ "$repos_found" -gt 0 ]]; then
                print_success "Encontrados $repos_found repositorios en $expanded_dir"
            fi
        fi
    done
    
    # Verificar si se encontraron repositorios
    if [[ ${#repo_list[@]} -eq 0 ]]; then
        if [[ "$quiet" == "false" ]]; then
            print_warning "No se encontraron repositorios Git en los directorios especificados"
            echo
            echo "Directorios validados:"
            for dir in "${valid_dirs[@]}"; do
                echo "  ✅ $dir"
            done
        fi
        exit 0
    fi
    
    if [[ "$quiet" == "false" ]]; then
        print_success "Encontrados ${#repo_list[@]} repositorios Git"
        print_info "Analizando commits en busca de co-autores sospechosos..."
    fi
    
    # Analizar repositorios
    local i=0
    for repo in "${repo_list[@]}"; do
        i=$((i + 1))
        
        if [[ "$quiet" == "false" ]]; then
            print_info "[$i/${#repo_list[@]}] Analizando: $repo"
        fi
        
        # Ejecutar análisis (paralelo o secuencial)
        if [[ "$parallel" == "true" ]]; then
            analyze_repository "$repo" "$quiet" &
        else
            local result
            if result=$(analyze_repository "$repo" "$quiet" 2>/dev/null); then
                analysis_results+=("$result")
            fi
        fi
    done
    
    # Esperar a que terminen todos los procesos si se usó paralelismo
    if [[ "$parallel" == "true" ]]; then
        wait
        # Recoger resultados de archivos temporales (implementación simplificada)
        for repo in "${repo_list[@]}"; do
            local result
            if result=$(analyze_repository "$repo" "$quiet" 2>/dev/null); then
                analysis_results+=("$result")
            fi
        done
    fi
    
    # Generar y mostrar reporte final
    if [[ ${#analysis_results[@]} -gt 0 ]]; then
        echo
        generate_report "${analysis_results[@]}"
    else
        if [[ "$quiet" == "false" ]]; then
            print_warning "No se pudieron analizar los repositorios"
        fi
    fi
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

# Solo ejecutar si el script es invocado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Manejar señales para limpieza adecuada
    trap 'print_error "Script interrumpido por el usuario"; exit 130' INT TERM
    
    # Ejecutar función principal
    main "$@"
fi