# Secure Git – Suspicious Co-Author Detector
```
   _____                              _______ __
  / ___/___  _______  __________     / ____(_) /_
  \__ \/ _ \/ ___/ / / / ___/ _ \   / / __/ / __/
 ___/ /  __/ /__/ /_/ / /  /  __/  / /_/ / / /_
/____/\___/\___/\__,_/_/   \___/   \____/_/\__/
```

**Secure Git** is an optimized Go implementation of my suspicious co-author detector for Git repositories. It is especially useful for identifying commits where AI assistants such as Claude Code, Qwen-coder, GitHub Copilot, and others have added themselves as co-authors without the developer’s consent.

## 🚨 Problem It Solves

Some AI assistants and automated development tools add `Co-authored-by:` lines to Git commits without the developer’s explicit consent, which can:

* Compromise legitimate code authorship.
* Violate intellectual property policies.
* Create licensing issues.
* Cause confusion in code ownership and traceability.

Secure Git automatically analyzes your repositories and generates detailed contamination reports.

## Why did I create this tool?

This tool was born out of a personal experience in which an AI model claimed co-authorship in a project that had taken over a year to develop. It was honestly frustrating to discover that after months of solitary work, an AI tool was attributing itself as a co-author simply because I had asked it to perform a commit on my behalf.

That situation clearly highlighted the need for a tool capable of detecting and reporting these unwanted co-author inclusions, helping developers protect their legitimate authorship.

## ✨ Features

* **🚀 High Performance**: Go implementation for faster analysis.
* **🔍 Advanced Detection**: Predefined patterns for common suspicious co-authors.
* **📊 Detailed Reports**: Complete statistics and lists of contaminated commits.
* **⚡ Parallel Processing**: Concurrent analysis of multiple repositories.
* **🔧 Configurable**: Customizable and persistent development directory.
* **🛡️ Safe**: Does not modify repositories — analysis and reporting only.
* **💾 Persistence**: Saves the development directory to a `.env` file for future runs.

## 📋 System Requirements

### Go Implementation

* **Go**: Version 1.16 or higher (for building).
* **Git**: Version 2.0 or higher.
* **Operating System**: Linux, macOS, or any Unix-like system.

## 🚀 Installation

### Method 1: Precompiled Binary

1. Download the binary for your operating system.
2. Make it executable: `chmod +x secure-git`
3. Run it: `./secure-git`

### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/mykeura/secure-git.git
cd secure-git

# Build
go build -o secure-git

# Make executable
chmod +x secure-git
```

## 📖 Usage

### Basic Execution

```bash
./secure-git
```

The first time you run the program, you will be prompted to enter your main development directory. This path will be saved for future executions.

### Sample Output

```bash
$ ./secure-git

==============================================================================
SECURE GIT – SUSPICIOUS CO-AUTHOR REPORT
==============================================================================

📊 GENERAL STATISTICS
   Repositories analyzed: 12
   Contaminated repositories: 2
   Clean repositories: 10

📛 CONTAMINATED REPOSITORIES
----------------------------------------

📁 /home/user/projects/api-service
   Total commits: 147
   Suspicious commits: 3
   Detected co-authors:
     • Co-authored-by: Claude <claude@anthropic.com>
     • Co-authored-by: Qwen-coder <qwen-coder@alibabacloud.com>

📁 /home/user/projects/frontend-app
   Total commits: 89
   Suspicious commits: 1
   Detected co-authors:
     • Co-authored-by: Claude <claude@anthropic.com>

✅ CLEAN REPOSITORIES
----------------------------------------
   /home/user/projects/docs (45 commits)
   /home/user/projects/utils (23 commits)
   ...

🚨 SECURITY ALERT
   2 contaminated repositories were found
   with a total of 4 suspicious commits

⚠️  RECOMMENDATIONS AND WARNINGS
   1. BACK UP THE .git DIRECTORY BEFORE PROCEEDING
   2. Review suspicious commits using: git log --oneline
   3. Consider rewriting history with: git rebase -i
   4. Configure Git hooks to prevent future contamination

⚠️  IMPORTANT WARNING
   Modifying commit history is a delicate process
   that can lead to data loss if not handled properly.
   Make sure you have advanced Git knowledge before proceeding.
```

## 🔍 Detected Patterns

Secure Git automatically detects the following suspicious co-author patterns:

### Specific AI Assistants

* **Qwen-coder** and variants (Alibaba Cloud)
* **ChatGPT** and OpenAI assistants
* **GitHub Copilot** (Microsoft)
* **CodeLlama**, **Claude**, **Llama**, **Mistral**
* **Amazon Q**, **Gemini**, **Aider**
* **AI Assistant** and generic variants

### Domain Patterns

* Co-authors using AI company domains:

  * `@openai.com`, `@anthropic.com`, `@microsoft.com`
  * `@google.com`, `@alibabacloud.com`, `@amazon.com`
  * `@facebook.com`, `@meta.com`

## ⚙️ Configuration

On first run, the program asks for your main development directory. This configuration is saved to a `.secure-git.env` file in your home directory for future executions.

## 🔄 CI/CD Integration

### GitHub Actions Example

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
          # Assuming the binary is included or downloaded
          ./secure-git
```

## 📝 License

This project is licensed under the GPLv3 License. See the `LICENSE` file for more details.

## 🤝 Contributing

Contributions are welcome. Please:

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## ⚠️ Disclaimer

This software is provided “as is”, without warranty of any kind. Users are responsible for verifying and validating the results before taking any action based on the generated reports.

---

**Did you find Secure Git useful?** ⭐ Star the repository to support the project!

---

