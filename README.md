# Google Antigravity (AGY) - Portable Edition

A multi-platform, fully self-contained, USB-portable distribution of the **Google Antigravity CLI (`agy`)** for **Windows**, **macOS**, and **Linux**.

All platforms share the same root `data/` folder, allowing your login credentials, conversations, skills, and settings to seamlessly persist across different operating systems on a single USB drive.

---

## Directory Structure

```
AGY-Portable/
│
├── Windows/                 # Windows distribution
│   ├── AGY-Launcher.exe     # WinForms Portable Hub & Credential Manager
│   ├── agy.cmd              # Command-line launcher (for terminal use)
│   ├── agy-shell.cmd        # Interactive Command Prompt with portable environment
│   ├── setup-bin.ps1        # Auto-detects and copies installed agy.exe into bin/
│   ├── build.ps1            # Rebuilds AGY-Launcher.exe using Windows csc.exe
│   ├── src/Program.cs       # Complete C# WinForms source code
│   └── bin/agy.exe          # Windows CLI binary (ignored by git)
│
├── macOS/                   # macOS distribution
│   ├── agy-portable.command # Double-clickable Finder launcher / interactive terminal menu
│   ├── agy.sh               # Quick CLI execution wrapper
│   ├── setup-bin.sh         # Auto-detects and copies installed macOS agy into bin/
│   └── bin/agy              # macOS CLI binary (ignored by git)
│
├── Linux/                   # Linux distribution
│   ├── agy-portable.sh      # Interactive terminal menu and CLI management hub
│   ├── agy.sh               # Quick CLI execution wrapper
│   ├── setup-bin.sh         # Auto-detects and copies installed Linux agy into bin/
│   └── bin/agy              # Linux CLI binary (ignored by git)
│
├── data/                    # Shared portable storage (never touches host PC, ignored by git)
│   ├── home/
│   │   └── .gemini/         # Shared OAuth tokens, SQLite DBs, conversation logs, skills
│   └── AppData/             # Local and roaming caches
│
├── .gitignore
└── README.md
```

---

## Usage by Platform

### Windows

1. **Setup**: Run `setup-bin.ps1` in PowerShell to automatically copy your local `agy.exe` into `Windows/bin/`.
2. **Graphical Hub**: Double-click `Windows/AGY-Launcher.exe` to manage logins (import host credentials, sign in, or clear credentials) and launch sessions.
3. **Command Line**:
   * Run `Windows/agy.cmd <flags>` directly from CMD or PowerShell.
   * Double-click `Windows/agy-shell.cmd` to open a command shell with `agy` in your `PATH`.

### macOS

1. **Setup**: Run `macOS/setup-bin.sh` in Terminal to copy your local `agy` into `macOS/bin/agy`.
2. **Interactive Terminal Hub**: Double-click `macOS/agy-portable.command` in Finder or run it in Terminal. It opens an interactive text menu with options to:
   * Launch AGY CLI
   * Open an interactive portable subshell
   * Import credentials from host Mac
   * Export credentials to host Mac
   * Sign in via browser
   * Clear USB credentials
3. **Command Line**:
   * `./macOS/agy.sh <flags>` (e.g. `./macOS/agy.sh models`)
   * `./macOS/agy-portable.command [status|import|export|clear|shell|run]`

### Linux

1. **Setup**: Run `Linux/setup-bin.sh` to copy your local `agy` into `Linux/bin/agy`.
2. **Interactive Terminal Hub**: Run `./Linux/agy-portable.sh` in a terminal. Provides the full interactive management menu and subcommands (`status`, `import`, `export`, `clear`, `shell`, `run`).
3. **Command Line**:
   * `./Linux/agy.sh <flags>` (e.g. `./Linux/agy.sh models`)

---

## Security & Privacy

* **Zero Host Pollution**: All credentials, SQLite conversation databases, logs, and skills live strictly inside `data/` on the USB drive.
* **Cross-Platform Sync**: Because SQLite databases and JSON OAuth tokens are cross-platform, a session started on Windows can be resumed on macOS or Linux using the same USB drive.
* **No Administrator Rights Required**: Credentials and configuration files exist solely in user space across all platforms.
* **Safe Traveling**: Clear your login token using the hub on any platform before sharing the USB drive.
