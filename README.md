# Google Antigravity (AGY) - Portable Edition

A multi-platform, fully self-contained, USB-portable distribution of the **Google Antigravity CLI (`agy`)** for **Windows**, **macOS**, and **Linux**.

All platforms share the same root `data/` folder, allowing your login credentials, conversations, skills, and settings to seamlessly persist across different operating systems on a single USB drive.

---

## Directory Structure

```
AGY-Portable/
│
├── Windows/                 # Windows distribution
│   ├── agy.cmd              # All-in-one launcher: Menu hub + Direct CLI + Auto-downloader
│   ├── agy-admin.cmd        # Administrator launcher with auto UAC elevation
│   └── bin/agy.exe          # Windows CLI binary (ignored by git)
│
├── macOS/                   # macOS distribution (single file launcher)
│   ├── agy.command          # All-in-one launcher: Finder double-click + Terminal CLI + Auto-downloader
│   ├── File Not Opening.txt # Gatekeeper quarantine bypass instructions
│   └── bin/agy              # macOS CLI binary (ignored by git)
│
├── Linux/                   # Linux distribution (single file launcher)
│   ├── agy.sh               # All-in-one launcher: Terminal menu + CLI + Auto-downloader
│   └── bin/agy              # Linux CLI binary (ignored by git)
│
├── Release/                 # Automated release packages and publisher scripts
│   ├── AGY-Portable-v1.0.0-All-Platforms.zip
│   ├── AGY-Portable-v1.0.0-Windows.zip
│   ├── AGY-Portable-v1.0.0-macOS.zip
│   ├── AGY-Portable-v1.0.0-Linux.zip
│   ├── build-release.ps1
│   ├── publish-github-release.ps1
│   └── README.md
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

### Windows (Dual-Launcher Architecture)

Inside `Windows/`, two native command scripts provide complete control without requiring .NET compilation or unsigned binaries:

1. **Standard Launcher (`agy.cmd`)**:
   * **Interactive Hub**: Double-click `Windows/agy.cmd` in Windows Explorer to open the interactive terminal menu.
   * **Direct Pass-Through**: Run standard AGY CLI commands directly from CMD or PowerShell:
     * `Windows\agy.cmd models`
     * `Windows\agy.cmd -p "Explain relativity in one sentence"`
     * `Windows\agy.cmd --version`
   * **Slash Commands**: Run management commands directly:
     * `Windows\agy.cmd /help` - Show all available commands
     * `Windows\agy.cmd /download` - Download official Windows binary directly from Google
     * `Windows\agy.cmd /update` - Update binary to latest Google release
     * `Windows\agy.cmd /status` - Display binary readiness and OAuth login status
     * `Windows\agy.cmd /import` - Copy credentials from host PC (%USERPROFILE%\.gemini) to USB
     * `Windows\agy.cmd /export` - Export USB credentials to host PC (%USERPROFILE%\.gemini)
     * `Windows\agy.cmd /login` - Sign in via Google OAuth in browser
     * `Windows\agy.cmd /clear` - Wipe credentials from USB
     * `Windows\agy.cmd /shell` - Open portable command prompt
2. **Administrator Launcher (`agy-admin.cmd`)**:
   * Double-click `Windows/agy-admin.cmd` to automatically prompt for Windows UAC privilege elevation and run the portable hub with full Administrator privileges.
   * Supports all arguments and pass-through flags in elevated mode.
3. **Auto-Download**: If `bin/agy.exe` is missing, `agy.cmd` automatically asks to download the official Windows 64-bit binary directly from Google or copy an existing local installation.

### macOS (Single-File Launcher)

Inside `macOS/`, simply run `agy.command`:

1. **First Run on macOS (Gatekeeper Note)**:
   * When downloaded from the internet via a browser, macOS Gatekeeper attaches a quarantine attribute to downloaded files.
   * If macOS blocks opening `agy.command`, see `macOS/File Not Opening.txt` or run:
     * `xattr -cr /Volumes/<YourUSB>/AGY-Portable`
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
* **No Administrator Rights Required**: Credentials and configuration files exist solely in user space across all platforms. Use `agy-admin.cmd` only when system-level modifications are needed.
* **Safe Traveling**: Clear your login token using `/clear` or menu option [6] before sharing the USB drive.
