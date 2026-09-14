# Google Antigravity (AGY) - Portable Edition

A multi-platform, fully self-contained, USB-portable distribution of the **Google Antigravity CLI (`agy`)** for **Windows**, **macOS**, and **Linux**.

All platforms share the same root `data/` folder, allowing your login credentials, conversations, skills, and settings to seamlessly persist across different operating systems on a single USB drive.

---

## Directory Structure

```
AGY-Portable/
│
├── Windows/                 # Windows distribution
│   ├── AGY-Launcher.exe     # WinForms Hub & Credential Manager (with direct Google downloader)
│   ├── agy.cmd              # Command-line launcher (for CMD / PowerShell)
│   ├── agy-shell.cmd        # Interactive Command Prompt with portable environment
│   ├── setup-bin.ps1        # Auto-detects and copies installed agy.exe into bin/
│   ├── build.ps1            # Rebuilds AGY-Launcher.exe using Windows csc.exe
│   ├── src/Program.cs       # Complete C# WinForms source code
│   └── bin/agy.exe          # Windows CLI binary (ignored by git)
│
├── macOS/                   # macOS distribution (single file launcher)
│   ├── agy.command          # All-in-one launcher: Finder double-click + Terminal CLI + Auto-downloader
│   └── bin/agy              # macOS CLI binary (ignored by git)
│
├── Linux/                   # Linux distribution (single file launcher)
│   ├── agy.sh               # All-in-one launcher: Terminal menu + CLI + Auto-downloader
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

1. **Graphical Hub**: Double-click `Windows/AGY-Launcher.exe` to manage logins, download/update the core binary directly from Google, and launch sessions.
2. **Command Line**:
   * Run `Windows/agy.cmd <flags>` directly from CMD or PowerShell.
   * Double-click `Windows/agy-shell.cmd` to open a command shell with `agy` in your `PATH`.
3. **Download Core**: If `bin/agy.exe` is missing, click "Download CLI Binary" in the launcher to download it directly from Google servers or copy it from your local install.

### macOS (Single-File Launcher)

Inside `macOS/`, simply run `agy.command`:

1. **First Run on macOS (Gatekeeper Note)**:
   * When downloaded from the internet via a browser, macOS Gatekeeper attaches a quarantine attribute to downloaded files.
   * If macOS blocks opening `agy.command`, either:
     * **Right-click (or Control-click)** `agy.command` -> click **Open** -> click **Open** on the prompt. (Only needed once).
     * Or in Terminal run: `xattr -cr /Volumes/<YourUSB>/AGY-Portable`
2. **Interactive Menu**: Double-click `macOS/agy.command` in Finder to open the interactive terminal management menu.
3. **Auto-Download**: If `bin/agy` is missing, `agy.command` automatically asks if you want to download the official macOS binary directly from Google or copy an existing local install.
4. **Slash Commands**: Run commands directly in Terminal:
   * `./macOS/agy.command /help` - List all commands
   * `./macOS/agy.command /download` - Download/install official macOS binary from Google
   * `./macOS/agy.command /update` - Update binary to latest Google release
   * `./macOS/agy.command /status` - Check binary readiness and USB login status
   * `./macOS/agy.command /import` - Copy credentials from host Mac (~/.gemini) to USB
   * `./macOS/agy.command /export` - Export USB credentials to host Mac (~/.gemini)
   * `./macOS/agy.command /login` - Sign in via Google OAuth in browser
   * `./macOS/agy.command /clear` - Wipe login token from USB
   * `./macOS/agy.command /shell` - Open portable subshell
5. **Direct Pass-Through**: Run standard AGY CLI commands directly:
   * `./macOS/agy.command models`
   * `./macOS/agy.command -p "Explain relativity in one sentence"`

### Linux (Single-File Launcher)

Inside `Linux/`, simply run `agy.sh`:

1. **Interactive Menu**: Run `./Linux/agy.sh` without arguments to launch the text menu.
2. **Slash Commands**:
   * `./Linux/agy.sh /help` - List all commands
   * `./Linux/agy.sh /download` - Download/install official Linux binary from Google
   * `./Linux/agy.sh /update` - Update binary to latest Google release
   * `./Linux/agy.sh /status` - Check status
   * `./Linux/agy.sh /import` - Import host credentials to USB
   * `./Linux/agy.sh /export` - Export USB credentials to host
   * `./Linux/agy.sh /clear` - Wipe credentials from USB
3. **Direct Pass-Through**:
   * `./Linux/agy.sh models`

---

## Security & Privacy

* **Zero Host Pollution**: All credentials, SQLite conversation databases, logs, and skills live strictly inside `data/` on the USB drive.
* **Cross-Platform Sync**: Because SQLite databases and JSON OAuth tokens are cross-platform, a session started on Windows can be resumed on macOS or Linux using the same USB drive.
* **No Administrator Rights Required**: Credentials and configuration files exist solely in user space across all platforms.
* **Safe Traveling**: Clear your login token using `/clear` or the WinForms button before sharing the USB drive.
