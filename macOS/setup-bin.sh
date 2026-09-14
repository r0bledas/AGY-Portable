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

# 1. Check for installed agy on host Mac
SYS_AGY=$(which agy 2>/dev/null)
if [ -n "$SYS_AGY" ] && [ -f "$SYS_AGY" ]; then
    echo "Found installed agy at: $SYS_AGY"
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

# 2. Download from Google
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    MANIFEST="darwin_arm64.json"
    DL_FALLBACK="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/darwin-arm/cli_mac_arm64.tar.gz"
else
    MANIFEST="darwin_amd64.json"
    DL_FALLBACK="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/darwin-x64/cli_mac_x64.tar.gz"
fi

echo "No local agy found on this Mac. Downloading from Google servers ($ARCH)..."
MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/$MANIFEST"

DL_URL=$(curl -sL "$MANIFEST_URL" | grep -o '"url": *"[^"]*"' | cut -d'"' -f4)
if [ -z "$DL_URL" ]; then
    DL_URL="$DL_FALLBACK"
fi

echo "Downloading from: $DL_URL"
TMP_ARCHIVE="$SCRIPT_DIR/bin/agy_temp.tar.gz"
curl -L -o "$TMP_ARCHIVE" "$DL_URL"
tar -xzf "$TMP_ARCHIVE" -C "$SCRIPT_DIR/bin"
rm -f "$TMP_ARCHIVE"
chmod +x "$BIN_TARGET"
echo "[OK] Successfully downloaded and configured macOS agy binary!"
