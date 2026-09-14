#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - All-in-One Portable Launcher (Linux)
# Run in terminal: ./agy.sh [/help] or double-click in desktop file manager
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if [ -d "$SCRIPT_DIR/../data" ] || [ -f "$SCRIPT_DIR/../README.md" ] || [ -d "$SCRIPT_DIR/../Windows" ]; then
    DATA_ROOT="$SCRIPT_DIR/../data"
else
    DATA_ROOT="$SCRIPT_DIR/data"
fi

PORTABLE_HOME="$DATA_ROOT/home"
PORTABLE_GEMINI="$PORTABLE_HOME/.gemini"
PORTABLE_TOKEN="$PORTABLE_GEMINI/jetski-standalone-oauth-token"
HOST_TOKEN="$HOME/.gemini/jetski-standalone-oauth-token"
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

resolve_binary() {
    if [ -f "$BIN_DIR/antigravity" ] && [ ! -f "$AGY_BIN" ]; then
        cp "$BIN_DIR/antigravity" "$AGY_BIN"
        chmod +x "$AGY_BIN" "$BIN_DIR/antigravity" 2>/dev/null
    fi

    if [ -f "$AGY_BIN" ]; then
        chmod +x "$AGY_BIN" 2>/dev/null
        return 0
    fi
    return 1
}

do_download() {
    echo "======================================================"
    echo "       Downloading Antigravity CLI for Linux"
    echo "======================================================"

    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        MANIFEST="linux_arm64.json"
        DL_FALLBACK="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/linux-arm/cli_linux_arm64.tar.gz"
    else
        MANIFEST="linux_amd64.json"
        DL_FALLBACK="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/linux-x64/cli_linux_x64.tar.gz"
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

    echo "Downloading (~50 MB compressed, ~200 MB uncompressed)..."
    if ! curl -L --progress-bar -o "$TMP_ARCHIVE" "$DL_URL"; then
        echo "[Error] Download failed."
        rm -f "$TMP_ARCHIVE"
        return 1
    fi

    echo "Extracting archive into $BIN_DIR..."
    tar -xzf "$TMP_ARCHIVE" -C "$BIN_DIR"
    rm -f "$TMP_ARCHIVE"

    if [ -f "$BIN_DIR/antigravity" ]; then
        cp -f "$BIN_DIR/antigravity" "$AGY_BIN"
    fi

    if [ -f "$AGY_BIN" ]; then
        chmod +x "$AGY_BIN" "$BIN_DIR/antigravity" 2>/dev/null
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
    echo " Antigravity CLI binary not found in Linux/bin/agy"
    echo "======================================================"

    SYS_AGY=$(which agy 2>/dev/null)
    if [ -z "$SYS_AGY" ] || [ ! -f "$SYS_AGY" ]; then
        CANDIDATES=(
            "$HOME/.local/bin/agy"
            "/usr/local/bin/agy"
            "$HOME/.agy/bin/agy"
        )
        for c in "${CANDIDATES[@]}"; do
            if [ -f "$c" ]; then
                SYS_AGY="$c"
                break
            fi
        done
    fi

    if [ -n "$SYS_AGY" ] && [ -f "$SYS_AGY" ]; then
        echo "Found existing installation on this Linux machine at: $SYS_AGY"
        printf "Copy from this machine to USB? [Y/n]: "
        read -r COPY_CONFIRM
        if [ "$COPY_CONFIRM" != "n" ] && [ "$COPY_CONFIRM" != "N" ]; then
            cp "$SYS_AGY" "$AGY_BIN"
            chmod +x "$AGY_BIN"
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

    echo "Aborted. Please place your Linux agy binary in Linux/bin/agy."
    return 1
}

show_status() {
    resolve_binary
    echo "======================================================"
    echo "       Google Antigravity (AGY) - Linux Hub"
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
        MOD_TIME=$(date -r "$PORTABLE_TOKEN" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Present")
        echo " USB Auth: Authenticated (Modified: $MOD_TIME)"
    else
        echo " USB Auth: Not logged in (Use /import or /login)"
    fi
    
    if [ -f "$HOST_TOKEN" ]; then
        echo "Host Auth: Detected on this machine ($HOST_TOKEN)"
    else
        echo "Host Auth: Not found on this machine"
    fi
    echo "------------------------------------------------------"
}

show_help() {
    echo "================================================================="
    echo "  Google Antigravity (AGY) - Linux Portable Command Reference"
    echo "================================================================="
    echo "Usage: ./agy.sh [command] [options]"
    echo ""
    echo "Slash Commands:"
    echo "  /help         Show this help screen with all available commands"
    echo "  /download     Download official AGY binary directly from Google"
    echo "  /update       Update AGY binary to the latest version from Google"
    echo "  /status       Display binary readiness and OAuth login status"
    echo "  /import       Import host machine credentials (~/.gemini) to USB"
    echo "  /export       Export USB credentials to host machine (~/.gemini)"
    echo "  /login        Sign in via Google OAuth in your default browser"
    echo "  /clear        Wipe login credentials from USB for safe lending"
    echo "  /shell        Open an interactive shell with portable environment"
    echo "  /menu         Open the interactive terminal menu"
    echo "  /run [args]   Execute AGY CLI directly with arguments"
    echo ""
    echo "Direct CLI Pass-Through:"
    echo "  You can pass standard AGY CLI flags directly, for example:"
    echo "    ./agy.sh models"
    echo "    ./agy.sh -p \"Explain relativity in one sentence\""
    echo "    ./agy.sh --version"
    echo "================================================================="
}

do_import() {
    if [ ! -f "$HOST_TOKEN" ]; then
        echo "[Error] No host login credentials found at: $HOST_TOKEN"
        return 1
    fi
    mkdir -p "$PORTABLE_GEMINI"
    cp "$HOST_TOKEN" "$PORTABLE_TOKEN"
    echo "[Success] Credentials copied from this machine to your USB drive!"
}

do_export() {
    if [ ! -f "$PORTABLE_TOKEN" ]; then
        echo "[Error] No credentials found on USB to export."
        return 1
    fi
    HOST_GEMINI_DIR=$(dirname "$HOST_TOKEN")
    mkdir -p "$HOST_GEMINI_DIR"
    cp "$PORTABLE_TOKEN" "$HOST_TOKEN"
    echo "[Success] Credentials exported to this machine ($HOST_TOKEN)."
}

do_clear() {
    if [ -f "$PORTABLE_TOKEN" ]; then
        rm -f "$PORTABLE_TOKEN"
        echo "[Success] USB credentials removed. Conversations and settings remain safe."
    else
        echo "No credentials found on USB to clear."
    fi
}

do_run() {
    ensure_bin || exit 1
    export_env
    "$AGY_BIN" "$@"
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
    "$AGY_BIN"
}

do_menu() {
    while true; do
        clear
        show_status
        echo " [1] Launch AGY CLI"
        echo " [2] Open Interactive Portable Shell"
        echo " [3] Import Login from this Machine (/import)"
        echo " [4] Export USB Login to this Machine (/export)"
        echo " [5] Sign In via Browser (/login)"
        echo " [6] Clear USB Login (/clear)"
        echo " [7] Download / Update Core Binary (/download)"
        echo " [8] Show Command Help (/help)"
        echo " [0] Exit"
        echo "------------------------------------------------------"
        printf " Select an option [0-8]: "
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

if [ $# -eq 0 ]; then
    do_menu
    exit 0
fi

ARG1="$1"
case "$ARG1" in
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
        do_import
        ;;
    /export|export)
        do_export
        ;;
    /clear|clear)
        do_clear
        ;;
    /login|login|/signin|signin)
        do_login
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
