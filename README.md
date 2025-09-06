# Secure Git - Detector de Co-autores Sospechosos

![GitHub](https://img.shields.io/badge/Git-Bash-4.0%2B-blue)
![License](https://img.shields.io/badge/Licencia-MIT-green)
![Platform](https://img.shields.io/badge/Plataforma-Linux%2FmacOS-lightgrey)

**Secure Git** es una herramienta de línea de comandos diseñada para detectar y reportar co-autores sospechosos en repositorios Git. Especialmente útil para identificar commits donde asistentes de IA como Qwen-coder, ChatGPT, GitHub Copilot y otros se han atribuido autoría sin consentimiento.

## 🚨 Problema que Resuelve

Algunos asistentes de IA y herramientas de desarrollo automático agregan líneas `Co-authored-by:` en los commits de Git sin el conocimiento del desarrollador, lo que puede:
- Comprometer la autoría legítima del código
- Violar políticas de propiedad intelectual
- Generar problemas de licenciamiento
- Crear confusión en la trazabilidad del código

Secure Git analiza automáticamente tus repositorios y genera reportes detallados de contaminación.

## ✨ Características

- **🔍 Detección Avanzada**: Patrones predefinidos para co-autores sospechosos comunes
- **📊 Reportes Detallados**: Estadísticas completas y listado de commits contaminados
- **⚡ Alto Rendimiento**: Búsqueda recursiva optimizada y procesamiento paralelo
- **🎨 Salida Colorida**: Interfaz intuitiva con soporte de colores robusto
- **🔧 Configurable**: Directorios personalizables y opciones flexibles
- **🛡️ Seguro**: No modifica repositorios, solo analiza y reporta

## 📋 Requisitos del Sistema

### Implementación Bash (Recomendada)
- **Bash**: Versión 4.0 o superior
- **Git**: Versión 2.0 o superior
- **Sistema Operativo**: Linux, macOS, o cualquier sistema Unix-like
- **Herramientas**: `grep`, `sed`, `awk` (generalmente preinstaladas)

### Implementación Python (Alternativa)
- **Python**: Versión 3.6 o superior
- **Git**: Versión 2.0 o superior

## 🚀 Instalación Rápida

### Implementación Bash (Principal)
```bash
# Descargar el script
curl -o secure-git.sh https://raw.githubusercontent.com/tu-usuario/secure-git/main/secure-git.sh

# Hacer ejecutable
chmod +x secure-git.sh

# Mover a PATH (opcional)
sudo mv secure-git.sh /usr/local/bin/secure-git
```

### Implementación Python (Alternativa)
```bash
# Descargar el script
curl -o secure-git.py https://raw.githubusercontent.com/tu-usuario/secure-git/main/secure-git.py

# Hacer ejecutable
chmod +x secure-git.py
```

### Método 2: Clonar Repositorio
```bash
git clone https://github.com/tu-usuario/secure-git.git
cd secure-git
chmod +x secure-git.sh secure-git.py
```

## 🔄 Implementaciones Disponibles

Secure Git ofrece dos implementaciones con diferentes características:

### 🐚 Implementación Bash (Principal)
- **Ventajas**: Más rápida, menor consumo de recursos, mayor portabilidad
- **Características**: Soporte de colores robusto, procesamiento paralelo, búsqueda profunda optimizada
- **Recomendada para**: Uso general, sistemas con recursos limitados, integración CI/CD

### 🐍 Implementación Python (Alternativa)
- **Ventajas**: Código más legible, fácil de extender, manejo de errores más robusto
- **Características**: Análisis estructurado, reportes detallados, fácil personalización
- **Recomendada para**: Desarrollo, debugging, sistemas donde Python es preferido

## 📖 Uso Básico

### Implementación Bash (Recomendada)
```bash
# Análisis en directorios por defecto
./secure-git.sh

# Análisis en directorios específicos
./secure-git.sh ~/proyectos ~/trabajo ~/desarrollo

# Modo silencioso (solo resultados críticos)
./secure-git.sh --quiet

# Procesamiento paralelo para mejor rendimiento
./secure-git.sh --parallel
```

### Implementación Python (Alternativa)
```bash
# Análisis básico
python3 secure-git.py

# Con Python ejecutable directo (si tiene shebang)
./secure-git.py
```

## 🔧 Opciones de Línea de Comandos

### Implementación Bash
| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `-h, --help` | Mostrar ayuda completa | `./secure-git.sh --help` |
| `-v, --version` | Mostrar versión | `./secure-git.sh --version` |
| `-d, --dirs` | Directorios específicos (separados por coma) | `./secure-git.sh -d "~/dev,~/code"` |
| `-r, --recursive` | Búsqueda recursiva (activado por defecto) | `./secure-git.sh --no-recursive` |
| `-p, --parallel` | Procesamiento paralelo | `./secure-git.sh -p` |
| `-q, --quiet` | Modo silencioso | `./secure-git.sh --quiet` |
| `--no-color` | Desactivar colores | `./secure-git.sh --no-color` |

### Implementación Python
La implementación Python actualmente no soporta opciones de línea de comandos y ejecuta un análisis automático en directorios predefinidos.

## 📊 Ejemplo de Salida

```bash
$ ./secure-git.sh ~/proyectos

==============================================================================
SECURE GIT - REPORTE DE CO-AUTORES SOSPECHOSOS (BASH)
==============================================================================

📊 ESTADÍSTICAS GENERALES
   Directorios analizados: 3
   Repositorios Git encontrados: 12
   Repositorios contaminados: 2
   Repositorios limpios: 10

📛 REPOSITORIOS CONTAMINADOS
----------------------------------------

📁 /home/usuario/proyectos/api-service
   Commits totales: 147
   Commits sospechosos: 3
   Co-autores detectados:
     • Co-authored-by: Qwen-coder <qwen-coder@alibabacloud.com>
     • Co-authored-by: GitHub Copilot

📁 /home/usuario/proyectos/frontend-app
   Commits totales: 89
   Commits sospechosos: 1
   Co-autores detectados:
     • Co-authored-by: AI Assistant

✅ REPOSITORIOS LIMPIOS (10)
----------------------------------------
   /home/usuario/proyectos/docs (45 commits)
   /home/usuario/proyectos/utils (23 commits)
   ...

🚨 ALERTA DE SEGURIDAD
   Se encontraron 2 repositorios contaminados
   con un total de 4 commits sospechosos

RECOMENDACIONES
   1. Revise los commits sospechosos con: git log --oneline
   2. Considere reescribir el historial con: git rebase -i
   3. Configure hooks de Git para prevenir futuras contaminaciones
```

## 🔍 Patrones Detectados

Secure Git detecta automáticamente los siguientes patrones de co-autores sospechosos:

### Asistentes de IA Específicos
- **Qwen-coder** y variantes (Alibaba Cloud)
- **ChatGPT** y asistentes OpenAI
- **GitHub Copilot** (Microsoft)
- **CodeLlama**, **Bard**, **Claude**, **Gemini**
- **AI Assistant** y variantes genéricas

### Patrones de Dominio
- Co-autores de dominios de empresas de IA:
  - `@openai.com`, `@anthropic.com`, `@microsoft.com`
  - `@google.com`, `@alibabacloud.com`, `@amazon.com`
  - `@facebook.com`, `@meta.com`

## ⚙️ Configuración Avanzada

### Archivo de Configuración
Puedes crear un archivo `config.json` para personalizar la búsqueda:

```json
{
    "search_directories": [
        "/home/usuario/proyectos",
        "/home/usuario/trabajo",
        "/home/usuario/desarrollo"
    ],
    "suspicious_patterns": [
        "Co-authored-by:\\s*[Qq]wen[-\\s]*[Cc]oder",
        "Co-authored-by:\\s*[Cc]hat[Gg][Pp][Tt]"
    ]
}
```

### Variables de Entorno
```bash
# Desactivar colores (útil para CI/CD)
export NO_COLOR=1

# Forzar colores
export FORCE_COLOR=1

# Directorios por defecto personalizados
export SECURE_GIT_DIRS="/path/to/projects,/another/path"
```

## 🛠️ Solución de Problemas

### Error: "Dependencias faltantes"
```bash
# En Ubuntu/Debian
sudo apt update && sudo apt install git grep sed awk

# En CentOS/RHEL
sudo yum install git grep sed awk

# En macOS (con Homebrew)
brew install git grep gnu-sed awk
```

### Error: "Permisos denegados"
```bash
# Verificar permisos del script
chmod +x secure-git.sh

# Ejecutar con permisos adecuados
./secure-git.sh
```

### Error: "No se encontraron repositorios Git"
- Verifica que los directorios especificados existan
- Usa rutas absolutas o expande `~` correctamente
- Asegúrate de tener permisos de lectura en los directorios

## 🔄 Integración con CI/CD

### Ejemplo para GitHub Actions
```yaml
name: Secure Git Scan
on: [push, pull_request]

jobs:
  secure-git:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Secure Git Scan
        run: |
          curl -s https://raw.githubusercontent.com/tu-usuario/secure-git/main/secure-git.sh | bash -s -- --quiet --no-color
        env:
          NO_COLOR: 1
```

### Ejemplo para GitLab CI
```yaml
secure_git_scan:
  script:
    - curl -s https://raw.githubusercontent.com/tu-usuario/secure-git/main/secure-git.sh | bash -s -- --quiet --no-color
  only:
    - merge_requests
```

## 📝 Licencia

Este proyecto está licenciado bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz un fork del proyecto
2. Crea una rama para tu característica (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## ⚠️ Aviso Legal

Este software se proporciona "tal cual", sin garantía de ningún tipo. Los usuarios son responsables de verificar y validar los resultados antes de tomar cualquier acción basada en los reportes generados.

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/tu-usuario/secure-git/issues)
- **Documentación**: [Wiki del Proyecto](https://github.com/tu-usuario/secure-git/wiki)
- **Email**: soporte@ejemplo.com

---

**¿Encontraste útil Secure Git?** ⭐ Dale una estrella al repositorio para apoyar el proyecto!