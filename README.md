# Google Antigravity (AGY) - Portable Edition

A fully self-contained, USB-portable distribution of the **Google Antigravity CLI (`agy`)**.

---

## 🚀 Quick Start

You can use AGY Portable in two ways:

### 1. Graphical Hub (Recommended)
Double-click **`AGY-Launcher.exe`**:
* **Status Dashboard**: Instantly shows whether your USB drive is authenticated and whether the current PC has existing credentials.
* **1-Click Import**: If the current PC is already logged into Antigravity, click **"📥 Import from this PC"** to instantly copy credentials to the USB drive (no admin required!).
* **Direct Sign In**: If on a new PC, click **"🌐 Direct Sign In"** to complete browser OAuth directly to the USB drive.
* **Launch CLI**: Click **"🚀 Launch AGY CLI"** to start your session.
* **Clear Credentials**: Click **"🗑️ Clear USB Login"** to wipe credentials before sharing your USB drive.

### 2. Command Line / Terminal
* Run **`agy.cmd <flags>`** directly from any terminal, script, or command prompt.
  ```cmd
  agy.cmd models
  agy.cmd -p "Explain quantum computing in one sentence"
  agy.cmd
  ```
* Double-click **`agy-shell.cmd`** to open an interactive command shell with `agy` in your `PATH`.

---

## 📂 Folder Layout

```
AGY-Portable/
├── AGY-Launcher.exe     # WinForms Portable Hub & Credential Manager (0 runtime dependencies)
├── agy.cmd              # Command-line launcher (for running in terminal)
├── agy-shell.cmd        # Interactive cmd shell pre-loaded with portable environment
├── build.ps1            # Script to rebuild AGY-Launcher.exe using Windows built-in csc.exe
├── README.md            # This documentation
│
├── bin/
│   └── agy.exe          # Google Antigravity CLI binary (~193 MB)
│
└── data/                # Completely isolated storage (never touches host PC)
    ├── home/
    │   └── .gemini/     # OAuth token, SQLite DBs, conversation logs, MCP configs, skills
    └── AppData/         # Local & roaming caches (e.g. Playwright browser engines)
```

---

## 🔒 Security & Privacy

* **Zero Host Pollution**: All conversation history, skills, MCP configuration, and OAuth tokens are strictly confined to the `data/` directory on your USB drive.
* **No Admin Rights Required**: All credentials and data exist in user space. AGY Portable can run on restricted or standard user accounts without UAC prompts.
* **Safe Traveling**: Use the "Clear USB Login" button in `AGY-Launcher.exe` whenever you want to de-authenticate your USB drive.
