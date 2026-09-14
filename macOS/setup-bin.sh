#!/usr/bin/env bash
# macOS AGY Setup Script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_TARGET="$SCRIPT_DIR/bin/agy"
mkdir -p "$SCRIPT_DIR/bin"

if [ -f "$BIN_TARGET" ]; then
    echo "[OK] agy binary is already present in bin/agy."
    chmod +x "$BIN_TARGET"
    exit 0
fi

SYS_AGY=$(which agy 2>/dev/null)
if [ -n "$SYS_AGY" ] && [ -f "$SYS_AGY" ]; then
    echo "Found installed agy at: $SYS_AGY"
    echo "Copying to $BIN_TARGET..."
    cp "$SYS_AGY" "$BIN_TARGET"
    chmod +x "$BIN_TARGET"
    echo "[OK] Copied agy into bin/agy!"
    exit 0
fi

CANDIDATES=(
    "$HOME/.local/bin/agy"
    "/usr/local/bin/agy"
    "/opt/homebrew/bin/agy"
    "$HOME/Library/Application Support/agy/bin/agy"
)

for c in "${CANDIDATES[@]}"; do
    if [ -f "$c" ]; then
        echo "Found agy at: $c"
        cp "$c" "$BIN_TARGET"
        chmod +x "$BIN_TARGET"
        echo "[OK] Copied agy into bin/agy!"
        exit 0
    fi
done

echo "[Warning] Could not find an installed agy on this Mac."
echo "Please copy your macOS agy binary into macOS/bin/agy."
