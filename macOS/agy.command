#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - All-in-One Portable Launcher (macOS)
# Double-click in macOS Finder or run in Terminal: ./agy.command [/help]
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Self-repair executable bits and strip Gatekeeper quarantine on sibling launchers
chmod +x "$SCRIPT_DIR/agy.command" "$SCRIPT_DIR/agy-danger.command" "$SCRIPT_DIR/../Linux/agy.sh" "$SCRIPT_DIR/../Linux/agy-danger.sh" 2>/dev/null || true
xattr -dr com.apple.quarantine "$SCRIPT_DIR" "$SCRIPT_DIR/../Linux" 2>/dev/null || true

# Detect if accidentally invoked via sudo and resolve the real user's HOME for credential import
REAL_HOME="$HOME"
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    echo "[Warning] Running with 'sudo' is not recommended — AGY-Portable runs entirely in user space."
    REAL_HOME=$(eval echo "~$SUDO_USER")
fi

# Shared root data directory or local data directory
if [ -d "$SCRIPT_DIR/../data" ] || [ -f "$SCRIPT_DIR/../README.md" ] || [ -d "$SCRIPT_DIR/../Windows" ]; then
    DATA_ROOT="$SCRIPT_DIR/../data"
else
    DATA_ROOT="$SCRIPT_DIR/data"
fi

PORTABLE_HOME="$DATA_ROOT/home"
PORTABLE_GEMINI="$PORTABLE_HOME/.gemini"
PORTABLE_TOKEN="$PORTABLE_GEMINI/jetski-standalone-oauth-token"
HOST_TOKEN="$REAL_HOME/.gemini/jetski-standalone-oauth-token"
BIN_DIR="$SCRIPT_DIR/bin"
AGY_BIN="$BIN_DIR/agy"

mkdir -p "$PORTABLE_GEMINI" "$DATA_ROOT/cache" "$DATA_ROOT/config" "$BIN_DIR"

export_env() {
    export HOME="$PORTABLE_HOME"
    export XDG_CONFIG_HOME="$DATA_ROOT/config"
    export XDG_DATA_HOME="$DATA_ROOT/share"
    export XDG_CACHE_HOME="$DATA_ROOT/cache"
    export PATH="$BIN_DIR:$SCRIPT_DIR:$PATH"
}

# Resolve or fix binary if needed
resolve_binary() {
    # If antigravity exists but agy doesn't, copy or link it
    if [ -f "$BIN_DIR/antigravity" ] && [ ! -f "$AGY_BIN" ]; then
        cp "$BIN_DIR/antigravity" "$AGY_BIN"
        chmod +x "$AGY_BIN" "$BIN_DIR/antigravity" 2>/dev/null
    fi

    # Fix permissions and macOS Gatekeeper quarantine
    if [ -f "$AGY_BIN" ]; then
        chmod +x "$AGY_BIN" 2>/dev/null
        xattr -dr com.apple.quarantine "$AGY_BIN" 2>/dev/null || true
        xattr -cr "$AGY_BIN" 2>/dev/null || true
        return 0
    fi
    return 1
}

# Download or update binary from Google
do_download() {
    echo "======================================================"
    echo "       Downloading Antigravity CLI for macOS"
    echo "======================================================"

    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        MANIFEST="darwin_arm64.json"
        DL_FALLBACK="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/darwin-arm/cli_mac_arm64.tar.gz"
    else
        MANIFEST="darwin_amd64.json"
        DL_FALLBACK="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/darwin-x64/cli_mac_x64.tar.gz"
    fi

    echo "Architecture: $ARCH"
    echo "Fetching release manifest from Google..."
    MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/$MANIFEST"

    DL_URL=$(curl -sL "$MANIFEST_URL" 2>/dev/null | grep -o '"url": *"[^"]*"' | head -n1 | cut -d'"' -f4)
    if [ -z "$DL_URL" ]; then
        DL_URL="$DL_FALLBACK"
    fi

    echo "Download URL: $DL_URL"
    TMP_ARCHIVE="$BIN_DIR/agy_archive.tar.gz"
    
    echo "Downloading (~50 MB compressed, ~190 MB uncompressed)..."
    if ! curl -L --progress-bar -o "$TMP_ARCHIVE" "$DL_URL"; then
        echo "[Error] Download failed."
        rm -f "$TMP_ARCHIVE"
        return 1
    fi

    echo "Extracting archive into $BIN_DIR..."
    tar -xzf "$TMP_ARCHIVE" -C "$BIN_DIR"
    rm -f "$TMP_ARCHIVE"

    # Archive extracts file named 'antigravity'
    if [ -f "$BIN_DIR/antigravity" ]; then
        cp -f "$BIN_DIR/antigravity" "$AGY_BIN"
    fi

    if [ -f "$AGY_BIN" ]; then
        chmod +x "$AGY_BIN" "$BIN_DIR/antigravity" 2>/dev/null
        # Remove macOS quarantine flag so Gatekeeper allows execution
        xattr -dr com.apple.quarantine "$AGY_BIN" 2>/dev/null || true
        xattr -cr "$AGY_BIN" 2>/dev/null || true
        echo "[Success] Antigravity CLI binary installed and ready in bin/agy!"
        return 0
    else
        echo "[Error] Failed to locate extracted binary in $BIN_DIR."
        return 1
    fi
}

ensure_bin() {
    if resolve_binary; then
        return 0
    fi

    echo "======================================================"
    echo " Antigravity CLI binary not found in macOS/bin/agy"
    echo "======================================================"

    # Check local Mac installation first
    SYS_AGY=$(which agy 2>/dev/null)
    if [ -z "$SYS_AGY" ] || [ ! -f "$SYS_AGY" ]; then
        CANDIDATES=(
            "$HOME/.local/bin/agy"
            "/usr/local/bin/agy"
            "/opt/homebrew/bin/agy"
            "$HOME/Library/Application Support/agy/bin/agy"
        )
        for c in "${CANDIDATES[@]}"; do
            if [ -f "$c" ]; then
                SYS_AGY="$c"
                break
            fi
        done
    fi

    if [ -n "$SYS_AGY" ] && [ -f "$SYS_AGY" ]; then
        echo "Found existing installation on this Mac at: $SYS_AGY"
        printf "Copy from this Mac to USB? [Y/n]: "
        read -r COPY_CONFIRM
        if [ "$COPY_CONFIRM" != "n" ] && [ "$COPY_CONFIRM" != "N" ]; then
            cp "$SYS_AGY" "$AGY_BIN"
            chmod +x "$AGY_BIN"
            xattr -dr com.apple.quarantine "$AGY_BIN" 2>/dev/null || true
            echo "[Success] Copied agy into bin/agy!"
            return 0
        fi
    fi

    echo "The binary can be downloaded directly from Google servers (~50 MB)."
    printf "Download now? [Y/n]: "
    read -r DL_CONFIRM
    if [ "$DL_CONFIRM" != "n" ] && [ "$DL_CONFIRM" != "N" ]; then
        do_download
        return $?
    fi

    echo "Aborted. Please place your macOS agy binary in macOS/bin/agy."
    return 1
}

show_status() {
    resolve_binary
    echo "======================================================"
    echo "       Google Antigravity (AGY) - macOS Hub"
    echo "======================================================"
    echo " Location: $SCRIPT_DIR"
    echo " Data Dir: $DATA_ROOT"
    
    if [ -f "$AGY_BIN" ]; then
        BIN_SIZE=$(ls -lh "$AGY_BIN" 2>/dev/null | awk '{print $5}')
        echo " CLI Core: Ready ($AGY_BIN, $BIN_SIZE)"
    else
        echo " CLI Core: MISSING (Use /download to install)"
    fi
    
    if [ -f "$PORTABLE_TOKEN" ]; then
        MOD_TIME=$(date -r "$PORTABLE_TOKEN" "+%Y-%m-%d %H:%M" 2>/dev/null || stat -f "%Sm" "$PORTABLE_TOKEN" 2>/dev/null || echo "Present")
        echo " USB Auth: Authenticated (Modified: $MOD_TIME)"
    else
        echo " USB Auth: Not logged in (Use /import or /login)"
    fi
    
    show_account_status

    if [ -f "$HOST_TOKEN" ]; then
        echo "Host Auth: Detected on this Mac ($HOST_TOKEN)"
    else
        echo "Host Auth: Not found on this Mac"
    fi
    if [ -n "$AGY_SKIP_PERMISSIONS" ]; then
        echo " Security: DANGEROUSLY SKIP PERMISSIONS (Auto-approves all tool actions)"
    else
        echo " Security: Standard (Prompts for tool approvals)"
    fi
    echo "------------------------------------------------------"
}

show_help() {
    echo "================================================================="
    echo "  Google Antigravity (AGY) - macOS Portable Command Reference"
    echo "================================================================="
    echo "Usage: ./agy.command [command] [options]"
    echo ""
    echo "Slash Commands:"
    echo "  /help         Show this help screen with all available commands"
    echo "  /danger       Launch in dangerously-skip-permissions mode"
    echo "  /download     Download official AGY binary directly from Google"
    echo "  /update       Update AGY binary to the latest version from Google"
    echo "  /status       Display binary readiness and OAuth login status"
    echo "  /import [name] Import host credentials (~/.gemini) as a USB account"
    echo "  /export       Export USB credentials to host Mac (~/.gemini)"
    echo "  /login        Sign in via Google OAuth in your default browser"
    echo "  /clear        Sign out of the active account (saved accounts kept)"
    echo "  /clear all    Wipe ALL credentials and saved accounts (safe lending)"
    echo "  /account ...  Manage multiple accounts (list|use|add|save|remove|rename)"
    echo "                (/login re-signs the ACTIVE account; use /account add for another one)"
    echo "  /shell        Open an interactive shell with portable environment"
    echo "  /menu         Open the interactive terminal menu"
    echo "  /run [args]   Execute AGY CLI directly with arguments"
    echo ""
    echo "Direct CLI Pass-Through:"
    echo "  You can pass standard AGY CLI flags directly, for example:"
    echo "    ./agy.command models"
    echo "    ./agy.command -p \"Explain relativity in one sentence\""
    echo "    ./agy.command --version"
    echo "================================================================="
}

do_import() {
    if [ ! -f "$HOST_TOKEN" ]; then
        echo "[Error] No host login credentials found at: $HOST_TOKEN"
        return 1
    fi
    _name="${1:-host}"
    acct_require_name "$_name" || return 1
    acct_sync_back
    acct_store_token "$HOST_TOKEN" "$_name"
    acct_load_token "$_name"
    acct_set_active "$_name"
    echo "[Success] Credentials copied from this Mac to your USB drive as account '$_name'!"
}
do_export() {
    if [ ! -f "$PORTABLE_TOKEN" ]; then
        echo "[Error] No credentials found on USB to export."
        return 1
    fi
    HOST_GEMINI_DIR=$(dirname "$HOST_TOKEN")
    mkdir -p "$HOST_GEMINI_DIR"
    cp "$PORTABLE_TOKEN" "$HOST_TOKEN"
    echo "[Success] Credentials exported to this Mac ($HOST_TOKEN)."
}

do_clear() {
    if [ "$1" = "all" ]; then
        rm -f "$PORTABLE_TOKEN" "$PORTABLE_TOKEN.bak"
        rm -rf "${ACCOUNTS_DIR:?}"
        mkdir -p "$ACCOUNTS_DIR"
        echo "[Success] All credentials (active login + every saved account) removed from USB."
        return 0
    fi
    acct_sync_back
    if [ -f "$PORTABLE_TOKEN" ]; then
        rm -f "$PORTABLE_TOKEN"
        echo "[Success] USB credentials removed. Conversations and settings remain safe."
    else
        echo "No credentials found on USB to clear."
    fi
    acct_set_active ""
    _left=$(acct_count)
    if [ "$_left" -gt 0 ]; then
        echo "Note: $_left saved account(s) remain on USB. Use '/clear all' to wipe everything before lending."
    fi
}
do_run() {
    ensure_bin || exit 1
    export_env
    if [ -n "$AGY_SKIP_PERMISSIONS" ]; then
        "$AGY_BIN" --dangerously-skip-permissions "$@"
    else
        "$AGY_BIN" "$@"
    fi
}

do_shell() {
    ensure_bin || exit 1
    export_env
    echo "Starting interactive portable subshell..."
    echo "Type 'agy' to run the CLI. Type 'exit' to return."
    "${SHELL:-/bin/bash}"
}

do_login() {
    ensure_bin || exit 1
    export_env
    echo "Launching Antigravity CLI to sign in..."
    echo "Follow the prompts in your browser or terminal to complete login."
    echo ""
    if [ -n "$AGY_SKIP_PERMISSIONS" ]; then
        "$AGY_BIN" --dangerously-skip-permissions
    else
        "$AGY_BIN"
    fi
}

# ------------------------------------------------------------------------------
# Multi-Account Profiles
#   data/accounts/<name>/token   saved credentials per profile
#   data/accounts/.active        name of the profile loaded into the live slot
#   The live slot ($PORTABLE_TOKEN) is what the AGY CLI actually reads.
# ------------------------------------------------------------------------------
ACCOUNTS_DIR="$DATA_ROOT/accounts"
ACTIVE_FILE="$ACCOUNTS_DIR/.active"

acct_valid() {
    case "$1" in
        ""|*[!A-Za-z0-9_-]*) return 1 ;;
    esac
    return 0
}

acct_get_active() {
    ACTIVE_ACCOUNT=""
    if [ -f "$ACTIVE_FILE" ]; then
        ACTIVE_ACCOUNT=$(head -n 1 "$ACTIVE_FILE" | tr -d '\r\n ')
        acct_valid "$ACTIVE_ACCOUNT" || ACTIVE_ACCOUNT=""
    fi
}

acct_set_active() {
    if [ -z "$1" ]; then
        rm -f "$ACTIVE_FILE"
    else
        # CRLF so the Windows launcher (set /p) reads the same file cleanly
        printf '%s\r\n' "$1" > "$ACTIVE_FILE"
    fi
    ACTIVE_ACCOUNT="$1"
}

acct_count() {
    _n=0
    for _d in "$ACCOUNTS_DIR"/*/; do
        [ -f "${_d}token" ] && _n=$((_n + 1))
    done
    echo "$_n"
}

acct_store_token() {
    # $1 = source token file, $2 = profile name
    mkdir -p "$ACCOUNTS_DIR/$2"
    chmod 700 "$ACCOUNTS_DIR/$2" 2>/dev/null
    cp -f "$1" "$ACCOUNTS_DIR/$2/token"
    chmod 600 "$ACCOUNTS_DIR/$2/token" 2>/dev/null
}

acct_load_token() {
    mkdir -p "$PORTABLE_GEMINI"
    cp -f "$ACCOUNTS_DIR/$1/token" "$PORTABLE_TOKEN"
    chmod 600 "$PORTABLE_TOKEN" 2>/dev/null
}

acct_migrate() {
    mkdir -p "$ACCOUNTS_DIR"
    acct_get_active
    [ -n "$ACTIVE_ACCOUNT" ] && return 0
    [ -f "$PORTABLE_TOKEN" ] || return 0
    [ "$(acct_count)" -eq 0 ] || return 0
    acct_store_token "$PORTABLE_TOKEN" default
    acct_set_active default
    echo "[Accounts] Existing login saved as profile \"default\"."
}

acct_sync_back() {
    # Persist the (possibly refreshed) live token into the active profile
    acct_get_active
    if [ -n "$ACTIVE_ACCOUNT" ] && [ -f "$PORTABLE_TOKEN" ]; then
        acct_store_token "$PORTABLE_TOKEN" "$ACTIVE_ACCOUNT"
    fi
    return 0
}

acct_require_name() {
    if ! acct_valid "$1"; then
        echo "[Error] Invalid account name '$1'. Use letters, digits, '-' or '_'."
        return 1
    fi
    return 0
}

show_account_status() {
    acct_get_active
    _cnt=$(acct_count)
    if [ -n "$ACTIVE_ACCOUNT" ]; then
        echo "  Account: $ACTIVE_ACCOUNT ($_cnt saved)"
    elif [ -f "$PORTABLE_TOKEN" ]; then
        echo "  Account: Unsaved login (use /account save <name>)"
    else
        echo "  Account: None ($_cnt saved)"
    fi
}

acct_list() {
    acct_get_active
    echo "======================================================"
    echo "                Saved AGY Accounts"
    echo "======================================================"
    _found=0
    for _d in "$ACCOUNTS_DIR"/*/; do
        [ -f "${_d}token" ] || continue
        _found=1
        _name=$(basename "$_d")
        if [ "$_name" = "$ACTIVE_ACCOUNT" ]; then
            echo "  * $_name   [active]"
        else
            echo "    $_name"
        fi
    done
    [ "$_found" -eq 0 ] && echo "  (no saved accounts - use /account add <name>)"
    if [ -z "$ACTIVE_ACCOUNT" ] && [ -f "$PORTABLE_TOKEN" ]; then
        echo "  Note: current login is not saved. Use /account save <name>"
    fi
    echo "------------------------------------------------------"
}

acct_use() {
    acct_require_name "$1" || return 1
    if [ ! -f "$ACCOUNTS_DIR/$1/token" ]; then
        echo "[Error] No saved account named '$1'. Run /account list."
        return 1
    fi
    acct_sync_back
    acct_load_token "$1"
    acct_set_active "$1"
    echo "[Success] Active account: $1"
}

acct_save() {
    acct_require_name "$1" || return 1
    if [ ! -f "$PORTABLE_TOKEN" ]; then
        echo "[Error] Not logged in. Use /login or /account add <name> first."
        return 1
    fi
    acct_store_token "$PORTABLE_TOKEN" "$1"
    acct_set_active "$1"
    echo "[Success] Current login saved as '$1' and set active."
}

acct_add() {
    acct_require_name "$1" || return 1
    if [ -f "$ACCOUNTS_DIR/$1/token" ]; then
        echo "[Error] Account '$1' already exists. Use /account use $1."
        return 1
    fi
    acct_sync_back
    _prev="$ACTIVE_ACCOUNT"
    [ -f "$PORTABLE_TOKEN" ] && mv -f "$PORTABLE_TOKEN" "$PORTABLE_TOKEN.bak"
    acct_set_active ""
    echo "Sign in with the Google account for '$1'."
    echo "When login completes, exit AGY to save the profile."
    echo ""
    ( do_login )
    if [ -f "$PORTABLE_TOKEN" ]; then
        acct_store_token "$PORTABLE_TOKEN" "$1"
        acct_set_active "$1"
        rm -f "$PORTABLE_TOKEN.bak"
        echo "[Success] Account '$1' added and set active."
    else
        echo "[Error] Login was not completed. Restoring previous account."
        [ -f "$PORTABLE_TOKEN.bak" ] && mv -f "$PORTABLE_TOKEN.bak" "$PORTABLE_TOKEN"
        acct_set_active "$_prev"
        return 1
    fi
}

acct_remove() {
    acct_require_name "$1" || return 1
    if [ ! -d "$ACCOUNTS_DIR/$1" ]; then
        echo "[Error] No saved account named '$1'."
        return 1
    fi
    acct_get_active
    if [ "$1" = "$ACTIVE_ACCOUNT" ]; then
        echo "[Error] '$1' is the active account. Switch to another account first, or use /clear."
        return 1
    fi
    rm -rf "${ACCOUNTS_DIR:?}/$1"
    echo "[Success] Removed account '$1'."
}

acct_rename() {
    acct_require_name "$1" || return 1
    acct_require_name "$2" || return 1
    if [ ! -d "$ACCOUNTS_DIR/$1" ]; then
        echo "[Error] No saved account named '$1'."
        return 1
    fi
    if [ -e "$ACCOUNTS_DIR/$2" ]; then
        echo "[Error] An account named '$2' already exists."
        return 1
    fi
    mv "$ACCOUNTS_DIR/$1" "$ACCOUNTS_DIR/$2"
    acct_get_active
    [ "$ACTIVE_ACCOUNT" = "$1" ] && acct_set_active "$2"
    echo "[Success] Renamed '$1' to '$2'."
}

acct_help() {
    echo "Account commands:"
    echo "  /account list                 List saved accounts (* = active)"
    echo "  /account use <name>           Switch the active account"
    echo "  /account add <name>           Sign in with a new account and save it"
    echo "  /account save <name>          Save the current login as a profile"
    echo "  /account remove <name>        Delete a saved (inactive) account"
    echo "  /account rename <old> <new>   Rename a saved account"
}

do_account() {
    _sub="$1"
    [ $# -gt 0 ] && shift
    case "$_sub" in
        ""|list|ls)            acct_list ;;
        use|switch)            acct_use "$1" ;;
        add|new)               acct_add "$1" ;;
        save)                  acct_save "$1" ;;
        remove|rm|delete|del)  acct_remove "$1" ;;
        rename|mv)             acct_rename "$1" "$2" ;;
        help|-h|--help)        acct_help ;;
        *)
            echo "[Error] Unknown account command: $_sub"
            acct_help
            return 1
            ;;
    esac
}

acct_menu() {
    while true; do
        clear
        acct_list
        echo " [U] Switch account      [A] Add account (sign in)"
        echo " [S] Save current login  [R] Remove account"
        echo " [N] Rename account      [B] Back"
        echo "------------------------------------------------------"
        printf " Select an option: "
        read -r AOPT
        case "$AOPT" in
            u|U) printf " Account to use: ";        read -r AN; acct_use "$AN" ;;
            a|A) printf " New account name: ";      read -r AN; acct_add "$AN" ;;
            s|S) printf " Save current login as: "; read -r AN; acct_save "$AN" ;;
            r|R) printf " Account to remove: ";     read -r AN; acct_remove "$AN" ;;
            n|N) printf " Current name: ";          read -r AN
                 printf " New name: ";              read -r AN2; acct_rename "$AN" "$AN2" ;;
            b|B|"") return 0 ;;
            *) echo "Invalid option." ;;
        esac
        echo ""
        read -r -p "Press Enter to continue..."
    done
}

do_menu() {
    while true; do
        clear
        show_status
        if [ -n "$AGY_SKIP_PERMISSIONS" ]; then
            echo " [1] Launch AGY CLI [DANGEROUSLY SKIP PERMISSIONS]"
        else
            echo " [1] Launch AGY CLI"
        fi
        echo " [2] Open Interactive Portable Shell"
        echo " [3] Import Login from this Mac (/import)"
        echo " [4] Export USB Login to this Mac (/export)"
        echo " [5] Sign In via Browser (/login)"
        echo " [6] Clear USB Login (/clear)"
        echo " [7] Download / Update Core Binary (/download)"
        echo " [8] Show Command Help (/help)"
        echo " [9] Manage Accounts (/account)"
        echo " [0] Exit"
        echo "------------------------------------------------------"
        printf " Select an option [0-9]: "
        read -r OPTION
        case "$OPTION" in
            1)
                echo ""
                do_run
                echo ""
                read -r -p "Press Enter to return to menu..."
                ;;
            2)
                echo ""
                do_shell
                ;;
            3)
                echo ""
                do_import
                echo ""
                read -r -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                do_export
                echo ""
                read -r -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                do_login
                echo ""
                read -r -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                do_clear
                echo ""
                read -r -p "Press Enter to continue..."
                ;;
            7)
                echo ""
                do_download
                echo ""
                read -r -p "Press Enter to continue..."
                ;;
            8)
                echo ""
                show_help
                echo ""
                read -r -p "Press Enter to return to menu..."
                ;;
            9)
                acct_menu
                ;;
            0)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

# If no arguments given, open menu
acct_migrate

if [ $# -eq 0 ]; then
    do_menu
    exit 0
fi

ARG1="$1"
case "$ARG1" in
    /danger|danger|--danger)
        export AGY_SKIP_PERMISSIONS=1
        shift
        if [ $# -eq 0 ]; then
            do_menu
        else
            do_run "$@"
        fi
        ;;
    /help|help|-h|--help)
        show_help
        ;;
    /download|download|/update|update)
        do_download
        ;;
    /status|status)
        show_status
        ;;
    /import|import)
        do_import "$2"
        ;;
    /export|export)
        do_export
        ;;
    /clear|clear)
        do_clear "$2"
        ;;
    /login|login|/signin|signin)
        do_login
        ;;
    /account|/accounts|/acc)
        shift
        do_account "$@"
        ;;
    /shell|shell)
        do_shell
        ;;
    /menu|menu)
        do_menu
        ;;
    /run)
        shift
        do_run "$@"
        ;;
    *)
        do_run "$@"
        ;;
esac
