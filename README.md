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
│   ├── accounts/            # Named account profiles (token per profile + .active marker)
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
| `<launcher> /status` | Display binary readiness, OAuth credentials status, and active account |
| `<launcher> /import [name]` | Import host machine credentials (`~/.gemini`) as a USB account (default name: `host`) |
| `<launcher> /export` | Export USB credentials to host machine (`~/.gemini`) |
| `<launcher> /login` | Sign in via Google OAuth in your default browser (re-signs the active account) |
| `<launcher> /clear` | Sign out of the active account (saved accounts are kept) |
| `<launcher> /clear all` | Wipe ALL credentials and saved accounts for safe lending |
| `<launcher> /account list` | List saved accounts (`*` marks the active one) |
| `<launcher> /account use <name>` | Switch the active account (instant on Windows) |
| `<launcher> /account add <name>` | Sign in with a new account and save it as a profile |
| `<launcher> /account save <name>` | Save the current login as a profile |
| `<launcher> /account status` | Show the account currently signed in |
| `<launcher> /account remove <name>` | Delete a saved (inactive) account |
| `<launcher> /account rename <old> <new>` | Rename a saved account |
| `<launcher> /shell` | Open an isolated command shell with portable paths preconfigured |
| `<launcher> /menu` | Open the interactive terminal menu hub |

### Multiple Accounts

AGY-Portable keeps named credential profiles under `data/accounts/<name>/`:

- `credential.json` - the Windows Credential Manager blob (`gemini:antigravity`), which is what the AGY CLI actually reads on Windows.
- `token` - the portable OAuth token file, used on macOS/Linux.
- `data/accounts/.active` - the profile currently loaded.

On Windows the CLI stores its login in the Windows Credential Manager, so
`/account use`, `/account save`, and `/account status` operate on that vault
through `Windows/accounts.ps1`. Switching accounts is instant - no browser, no
re-login. On macOS/Linux the token file is the credential and the same commands
swap it in place.

Use `/account add` or `/account save` to create profiles and `/account use`
to switch between them. Conversations, settings, and skills remain shared
across all accounts. Profile names may contain letters, digits, `-` and `_`.

> `data/accounts/` is excluded by `.gitignore`, so credentials are never
> committed. Each Windows user has their own credential vault, so profiles
> created on one machine are portable to another via the USB drive.

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
* **Zero-Permission Quick Launch (Always Works)**: Calling `bash` directly bypasses missing executable bits (`0644`) and USB `noexec` mounts:
  ```bash
  bash macOS/agy.command /help
  bash macOS/agy.command /download
  bash macOS/agy.command
  ```
* **Gatekeeper & Permissions One-Liner (Enables Finder Double-Click)**: Browser-downloaded archives receive `com.apple.quarantine`, and FAT/exFAT USB drives or Windows-built ZIP tools may strip executable mode bits. Fix both at once from the `AGY-Portable` root:
  ```bash
  xattr -cr . && chmod +x macOS/*.command Linux/*.sh
  ```
  See `macOS/File Not Opening.txt` for step-by-step instructions.
* **Finder Launch**: Double-click `agy.command` or `agy-danger.command` in Finder to launch.
* **Do Not Use `sudo`**: Never run `sudo ./agy.command`. On a non-executable file, `sudo` prints a misleading `sudo: command not found` error, and running as `root` changes `$HOME` and prevents importing your user credentials.

### Linux
* **Zero-Permission Quick Launch**: Works immediately even without `+x` permissions:
  ```bash
  bash Linux/agy.sh /help
  bash Linux/agy.sh /download
  bash Linux/agy.sh
  ```
* **Terminal Launch**: Run `./Linux/agy.sh` or `./Linux/agy-danger.sh`.
* **Execution Permissions**: If needed, grant execution permissions:
  ```bash
  chmod +x Linux/agy.sh Linux/agy-danger.sh
  ```

### First-Run Binary Download
* The release archive (`~18 KB`) contains only the portable launchers and directory structure (no 200 MB proprietary binaries bundled). On first launch, run `<launcher> /download` (or follow the interactive prompt) with an active internet connection to fetch the official Google CLI binary for your OS, or let the launcher copy an existing local `agy` installation onto the USB drive.

---

## Security & Privacy

* **Zero Host Pollution**: All credentials, SQLite conversation databases, logs, and skills live strictly inside `data/` on the USB drive.
* **Per-Profile Credentials**: Saved account tokens live under `data/accounts/` (excluded by `.gitignore`) and are stored with restrictive permissions (`chmod 600`) where the OS allows. Use `/clear all` before lending the drive.
* **Cross-Platform Sync**: Because SQLite databases and JSON OAuth tokens are cross-platform, a session started on Windows can be resumed on macOS or Linux using the same USB drive.
* **No Administrator Rights Required**: Credentials and configuration files exist solely in user space across all platforms.
* **Safe Traveling**: Sign out with `/clear` (or wipe everything with `/clear all`) before sharing the USB drive.
