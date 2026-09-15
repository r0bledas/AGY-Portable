# Google Antigravity (AGY) - Portable Edition

A multi-platform, fully self-contained, USB-portable distribution of the **Google Antigravity CLI (`agy`)** for **Windows**, **macOS**, and **Linux**.

All platforms share the same root `data/` folder, allowing your login credentials, conversations, skills, and settings to seamlessly persist across different operating systems on a single USB drive.

---

## Directory Structure

```
AGY-Portable/
│
├── Windows/                 # Windows distribution
│   ├── agy.cmd              # Standard launcher (Hub + CLI + Auto-downloader)
│   ├── agy-danger.cmd       # Dangerous Runner (--dangerously-skip-permissions)
│   ├── updater.ps1          # Dual-track updater (GitHub scripts + Google CLI engine)
│   ├── if file not opening, run as admin.txt # Tip for Windows permissions
│   └── bin/agy.exe          # Windows CLI binary (ignored by git)
│
├── macOS/                   # macOS distribution
│   ├── agy.command          # Standard launcher (Finder double-click + Terminal CLI)
│   ├── agy-danger.command   # Dangerous Runner (--dangerously-skip-permissions)
│   ├── File Not Opening.txt # Gatekeeper quarantine bypass instructions
│   └── bin/agy              # macOS CLI binary (ignored by git)
│
├── Linux/                   # Linux distribution
│   ├── agy.sh               # Standard launcher (Terminal menu + CLI)
│   ├── agy-danger.sh        # Dangerous Runner (--dangerously-skip-permissions)
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

## Dual-Runner Architecture

Every supported operating system provides two dedicated entrypoint launchers side-by-side:

| Operating System | Standard Runner (Safe) | Dangerous Runner (Auto-Approve) |
|:-----------------|:-----------------------|:--------------------------------|
| **Windows**      | `Windows\agy.cmd`      | `Windows\agy-danger.cmd`        |
| **macOS**        | `macOS/agy.command`    | `macOS/agy-danger.command`      |
| **Linux**        | `Linux/agy.sh`         | `Linux/agy-danger.sh`           |

### Why Dual-Runner?
1. **Zero-Configuration Toggle**: Switching between interactive supervision and autonomous workflows requires no configuration file edits, no command-line flags, and no environment variable setup.
2. **Double-Click Simplicity**: In desktop environments (Windows Explorer, macOS Finder, Linux file managers), double-clicking the respective launcher immediately starts AGY in that desired mode.
3. **Safety by Default**: `agy` requires confirmation before executing commands or modifying files. `agy-danger` passes `--dangerously-skip-permissions`, letting the agent autonomously execute tasks without prompting.

---

## Unified Command Reference

All platforms share the exact same commands, arguments, and slash commands. Replace `<launcher>` with your platform's script (`Windows\agy.cmd`, `./macOS/agy.command`, or `./Linux/agy.sh`):

### Slash Commands

| Command | Action |
|:---|:---|
| `<launcher> /help` | Display interactive command and usage reference |
| `<launcher> /danger` | Launch hub or execute command with `--dangerously-skip-permissions` |
| `<launcher> /download` | Download official AGY binary directly from Google servers |
| `<launcher> /update` | Check for updates (GitHub scripts and/or Google core CLI engine) |
| `<launcher> /status` | Display binary readiness, OAuth credentials status, and active mode |
| `<launcher> /import` | Import host machine credentials (`~/.gemini`) into portable USB storage |
| `<launcher> /export` | Export USB credentials to host machine (`~/.gemini`) |
| `<launcher> /login` | Sign in via Google OAuth in your default browser |
| `<launcher> /clear` | Wipe login token from USB for safe lending |
| `<launcher> /shell` | Open an isolated command shell with portable paths preconfigured |
| `<launcher> /menu` | Open the interactive terminal menu hub |

### Direct CLI Pass-Through

Any standard Antigravity CLI command or flag can be passed directly through the launcher:

```bash
<launcher> models
<launcher> -p "Explain relativity in one sentence"
<launcher> --version
```

---

## Platform Notes

### Windows
* **Menu Hub**: Double-click `agy.cmd` or `agy-danger.cmd` to launch the interactive terminal menu.
* **If File Not Opening**: If Windows 11 blocks execution on removable media ("Acceso denegado"), right-click `agy.cmd` or `agy-danger.cmd` and select **Run as administrator**.
* **Zero-Trace Temp Runner**: `agy.cmd` loads the core engine into a temporary sandbox with a progress indicator to bypass USB drive execution policies, automatically purging upon exit.

### macOS
* **Gatekeeper Notice**: When downloaded from a web browser, macOS Gatekeeper may quarantine the scripts. If macOS blocks opening `agy.command`, run:
  ```bash
  xattr -cr /Volumes/<YourUSB>/AGY-Portable
  ```
  See `macOS/File Not Opening.txt` for details.
* **Finder Launch**: Double-click `agy.command` or `agy-danger.command` in Finder to launch.

### Linux
* **Terminal Launch**: Run `./Linux/agy.sh` or `./Linux/agy-danger.sh`.
* **Execution Permissions**: If needed, grant execution permissions:
  ```bash
  chmod +x Linux/agy.sh Linux/agy-danger.sh
  ```

---

## Security & Privacy

* **Zero Host Pollution**: All credentials, SQLite conversation databases, logs, and skills live strictly inside `data/` on the USB drive.
* **Cross-Platform Sync**: Because SQLite databases and JSON OAuth tokens are cross-platform, a session started on Windows can be resumed on macOS or Linux using the same USB drive.
* **No Administrator Rights Required**: Credentials and configuration files exist solely in user space across all platforms.
* **Safe Traveling**: Clear your login token using `/clear` or menu option `[6]` before sharing the USB drive.
