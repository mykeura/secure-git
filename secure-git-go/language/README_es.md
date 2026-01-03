# Secure Git - Detector de Co-autores Sospechosos

**Secure Git** es una versión optimizada en Go de mi detector de co-autores sospechosos en repositorios Git. Especialmente útil para identificar commits donde asistentes de IA como Claude Code, Qwen-coder, GitHub Copilot y otros se han atribuido autoría sin consentimiento.

## 🚨 Problema que Resuelve

Algunos asistentes de IA y herramientas de desarrollo automático agregan líneas `Co-authored-by:` en los commits de Git sin el concentimiento del desarrollador, lo que puede:
- Comprometer la autoría legítima del código.
- Violar políticas de propiedad intelectual.
- Generar problemas de licenciamiento.
- Crear confusión en la trazabilidad del código.

Secure Git analiza automáticamente tus repositorios y genera reportes detallados de contaminación.

## ¿Por qué creé este script?

Este script fue creado por una experiencia personal donde un modelo de IA se adjudicó la co-autoría en un proyecto de más de un año de desarrollo. La verdad, fue frustrante descubrir como después de meses de trabajo solitario una herramienta de AI se estaba ajudicando la co-autoria de mi trabajo simplemente por haber solicitado que hiciera un commit en mi lugar. Esta situación puso en evidencia la necesidad de una herramienta que pudiera detectar y reportar estas inclusiones no deseadas de co-autores, protegiendo así la autoría legítima de los desarrolladores.

## ✨ Características

- **🚀 Rendimiento superior**: Implementación en Go para análisis más rápido.
- **🔍 Detección Avanzada**: Patrones predefinidos para co-autores sospechosos comunes.
- **📊 Reportes Detallados**: Estadísticas completas y listado de commits contaminados.
- **⚡ Procesamiento Paralelo**: Análisis concurrente de múltiples repositorios.
- **🔧 Configurable**: Directorio de desarrollo personalizable y persistente.
- **🛡️ Seguro**: No modifica repositorios, solo analiza y reporta.
- **💾 Persistencia**: Guarda el directorio de desarrollo en archivo .env para futuras ejecuciones.

## 📋 Requisitos del Sistema

### Implementación Go
- **Go**: Versión 1.16 o superior (para compilar).
- **Git**: Versión 2.0 o superior.
- **Sistema Operativo**: Linux, macOS, o cualquier sistema Unix-like.

## 🚀 Instalación

### Método 1: Binario Precompilado
1. Descarga el binario correspondiente a tu sistema operativo.
2. Hazlo ejecutable: `chmod +x secure-git`
3. Ejecuta: `./secure-git`

### Método 2: Compilar desde el código fuente
```bash
# Clonar el repositorio
git clone https://github.com/mykeura/secure-git.git
cd secure-git

# Compilar
go build -o secure-git

# Hacer ejecutable
chmod +x secure-git
```

## 📖 Uso

### Ejecución básica
```bash
./secure-git
```

La primera vez que ejecutes el programa, se te pedirá que ingreses la carpeta principal de desarrollo. Esta ruta se guardará para futuras ejecuciones.

### Ejemplo de Salida
```bash
$ ./secure-git

==============================================================================
SECURE GIT - REPORTE DE CO-AUTORES SOSPECHOSOS
==============================================================================

📊 ESTADÍSTICAS GENERALES
   Repositorios analizados: 12
   Repositorios contaminados: 2
   Repositorios limpios: 10

📛 REPOSITORIOS CONTAMINADOS
----------------------------------------

📁 /home/usuario/proyectos/api-service
   Commits totales: 147
   Commits sospechosos: 3
   Co-autores detectados:
     • Co-authored-by: Co-authored-by: Claude <claude@anthropic.com>
     • Co-authored-by: Qwen-coder <qwen-coder@alibabacloud.com>

📁 /home/usuario/proyectos/frontend-app
   Commits totales: 89
   Commits sospechosos: 1
   Co-autores detectados:
     • Co-authored-by: Co-authored-by: Claude <claude@anthropic.com>

✅ REPOSITORIOS LIMPIOS
----------------------------------------
   /home/usuario/proyectos/docs (45 commits)
   /home/usuario/proyectos/utils (23 commits)
   ...

🚨 ALERTA DE SEGURIDAD
   Se encontraron 2 repositorios contaminados
   con un total de 4 commits sospechosos

⚠️  RECOMENDACIONES Y ADVERTENCIAS
   1. HAGA UNA COPIA DE SEGURIDAD DEL DIRECTORIO .git ANTES DE CONTINUAR
   2. Revise los commits sospechosos con: git log --oneline
   3. Considere reescribir el historial con: git rebase -i
   4. Configure hooks de Git para prevenir futuras contaminaciones

⚠️  ADVERTENCIA IMPORTANTE
   La modificación del historial de commits es un proceso delicado
   que puede causar pérdida de datos si no se maneja correctamente.
   Asegúrese de tener conocimientos avanzados de Git antes de proceder.
```

## 🔍 Patrones Detectados

Secure Git detecta automáticamente los siguientes patrones de co-autores sospechosos:

### Asistentes de IA Específicos
- **Qwen-coder** y variantes (Alibaba Cloud)
- **ChatGPT** y asistentes OpenAI
- **GitHub Copilot** (Microsoft)
- **CodeLlama**, **Claude**, **Llama**, **Mistral**
- **Amazon Q**, **Gemini**, **Aider**
- **AI Assistant** y variantes genéricas

### Patrones de Dominio
- Co-autores de dominios de empresas de IA:
  - `@openai.com`, `@anthropic.com`, `@microsoft.com`
  - `@google.com`, `@alibabacloud.com`, `@amazon.com`
  - `@facebook.com`, `@meta.com`

## ⚙️ Configuración

La primera vez que ejecutas el programa, se te solicita el directorio de desarrollo principal. Esta configuración se guarda en un archivo `.secure-git.env` en tu directorio home para futuras ejecuciones.

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
          # Asumiendo que el binario está incluido o se descarga
          ./secure-git
```

## 📝 Licencia

Este proyecto está licenciado bajo la Licencia GPLv3. Ver el archivo `LICENSE` para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz un fork del proyecto
2. Crea una rama para tu característica (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## ⚠️ Aviso Legal

Este software se proporciona "tal cual", sin garantía de ningún tipo. Los usuarios son responsables de verificar y validar los resultados antes de tomar cualquier acción basada en los reportes generados.

---

**¿Encontraste útil Secure Git?** ⭐ Dale una estrella al repositorio para apoyar el proyecto!
