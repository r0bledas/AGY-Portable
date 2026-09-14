# Google Antigravity (AGY) - Portable Edition

A fully self-contained, USB-portable distribution of the **Google Antigravity CLI (`agy`)**.

---

## Setup

When using from a USB drive or fresh clone:

1. Run `setup-bin.ps1` in PowerShell (or manually place your `agy.exe` into the `bin/` folder).
2. Run `AGY-Launcher.exe` to manage logins and launch sessions.

---

## Quick Start

You can use AGY Portable in two ways:

### 1. Graphical Hub (Recommended)

Double-click **`AGY-Launcher.exe`**:
* **Status Dashboard**: Shows whether your USB drive is authenticated and whether the current host PC has credentials.
* **Import Host Login**: If the current PC is already logged into Antigravity, click "Import Host Login" to copy credentials to the USB drive (no administrator privileges required).
* **Sign In via Browser**: If on a new PC, click "Sign In via Browser" to complete browser OAuth directly to the USB drive.
* **Launch AGY CLI**: Starts an interactive CLI session using the portable environment.
* **Clear USB Login**: Removes credentials from the USB drive before lending or sharing it.

### 2. Command Line / Terminal

* Run **`agy.cmd <flags>`** directly from any terminal, script, or command prompt:
  ```cmd
  agy.cmd models
  agy.cmd -p "Explain quantum computing in one sentence"
  agy.cmd
  ```
* Double-click **`agy-shell.cmd`** to open an interactive command shell with `agy` in your `PATH`.

---

## Folder Layout

```
AGY-Portable/
├── AGY-Launcher.exe     # WinForms Portable Hub & Credential Manager (0 runtime dependencies)
├── agy.cmd              # Command-line launcher (for running in terminal)
├── agy-shell.cmd        # Interactive cmd shell pre-loaded with portable environment
├── setup-bin.ps1        # Auto-detects and copies agy.exe into bin/
├── build.ps1            # Script to rebuild AGY-Launcher.exe using Windows built-in csc.exe
├── README.md            # This documentation
│
├── bin/
│   └── agy.exe          # Google Antigravity CLI binary (~193 MB, ignored by git)
│
└── data/                # Completely isolated storage (never touches host PC, ignored by git)
    ├── home/
    │   └── .gemini/     # OAuth token, SQLite DBs, conversation logs, MCP configs, skills
    └── AppData/         # Local and roaming caches (e.g. Playwright browser engines)
```

---

## Security & Privacy

* **Zero Host Pollution**: All conversation history, skills, MCP configuration, and OAuth tokens are strictly confined to the `data/` directory on your USB drive.
* **No Admin Rights Required**: All credentials and data exist in user space. AGY Portable can run on restricted or standard user accounts without UAC prompts.
* **Safe Traveling**: Use the "Clear USB Login" button in `AGY-Launcher.exe` whenever you want to de-authenticate your USB drive.
