#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - Portable Hub (Linux)
# Run from terminal: ./agy-portable.sh [cmd] or double-click in file manager
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if [ -d "$SCRIPT_DIR/../data" ]; then
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

mkdir -p "$PORTABLE_GEMINI" "$DATA_ROOT/cache" "$DATA_ROOT/config"

export_env() {
    export HOME="$PORTABLE_HOME"
    export XDG_CONFIG_HOME="$DATA_ROOT/config"
    export XDG_DATA_HOME="$DATA_ROOT/share"
    export XDG_CACHE_HOME="$DATA_ROOT/cache"
    export PATH="$BIN_DIR:$SCRIPT_DIR:$PATH"
}

check_bin() {
    if [ ! -f "$AGY_BIN" ]; then
        SYS_AGY=$(which agy 2>/dev/null)
        if [ -n "$SYS_AGY" ] && [ -f "$SYS_AGY" ]; then
            echo "[Notice] Portable bin/agy not found. Found system binary at: $SYS_AGY"
            echo "Copying $SYS_AGY to $AGY_BIN..."
            mkdir -p "$BIN_DIR"
            cp "$SYS_AGY" "$AGY_BIN"
            chmod +x "$AGY_BIN"
        elif [ -f "$HOME/.local/bin/agy" ]; then
            echo "Copying $HOME/.local/bin/agy to $AGY_BIN..."
            mkdir -p "$BIN_DIR"
            cp "$HOME/.local/bin/agy" "$AGY_BIN"
            chmod +x "$AGY_BIN"
        else
            echo "[Error] Antigravity CLI binary not found in bin/agy."
            echo "Run ./setup-bin.sh or place the Linux 'agy' binary into Linux/bin/."
            return 1
        fi
    fi
    chmod +x "$AGY_BIN" 2>/dev/null
    return 0
}

show_status() {
    echo "======================================================"
    echo "       Google Antigravity (AGY) - Linux Hub"
    echo "======================================================"
    echo " Location: $SCRIPT_DIR"
    echo " Data Dir: $DATA_ROOT"
    
    if [ -f "$AGY_BIN" ]; then
        BIN_SIZE=$(ls -lh "$AGY_BIN" 2>/dev/null | awk '{print $5}')
        echo " CLI Core: Ready ($AGY_BIN, $BIN_SIZE)"
    else
        echo " CLI Core: MISSING (Expected at bin/agy)"
    fi
    
    if [ -f "$PORTABLE_TOKEN" ]; then
        MOD_TIME=$(date -r "$PORTABLE_TOKEN" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Present")
        echo " USB Auth: Authenticated (Modified: $MOD_TIME)"
    else
        echo " USB Auth: Not logged in (Use import or sign in)"
    fi
    
    if [ -f "$HOST_TOKEN" ]; then
        echo "Host Auth: Detected on this machine ($HOST_TOKEN)"
    else
        echo "Host Auth: Not found on this machine"
    fi
    echo "------------------------------------------------------"
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
    check_bin || exit 1
    export_env
    "$AGY_BIN" "$@"
}

do_shell() {
    check_bin || exit 1
    export_env
    echo "Starting interactive portable subshell..."
    echo "Type 'agy' to run the CLI. Type 'exit' to return."
    "${SHELL:-/bin/bash}"
}

do_login() {
    check_bin || exit 1
    export_env
    echo "Initiating browser login flow..."
    "$AGY_BIN" models
}

CMD="${1:-menu}"

case "$CMD" in
    status)
        show_status
        ;;
    import)
        do_import
        ;;
    export)
        do_export
        ;;
    clear)
        do_clear
        ;;
    login)
        do_login
        ;;
    shell)
        do_shell
        ;;
    run)
        shift
        do_run "$@"
        ;;
    menu)
        while true; do
            clear
            show_status
            echo " [1] Launch AGY CLI"
            echo " [2] Open Interactive Portable Shell"
            echo " [3] Import Login from this Machine"
            echo " [4] Export USB Login to this Machine"
            echo " [5] Sign In via Browser"
            echo " [6] Clear USB Login"
            echo " [7] Refresh Status"
            echo " [0] Exit"
            echo "------------------------------------------------------"
            printf " Select an option [0-7]: "
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
        ;;
    *)
        do_run "$@"
        ;;
esac
