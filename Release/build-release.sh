#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="${1:-v2.0.0}"

cd "$ROOT_DIR"

echo "Ensuring executable mode bits (100755) in git index..."
git update-index --chmod=+x \
    macOS/agy.command \
    macOS/agy-danger.command \
    Linux/agy.sh \
    Linux/agy-danger.sh \
    Windows/agy.cmd \
    Windows/agy-danger.cmd

chmod +x macOS/agy.command macOS/agy-danger.command Linux/agy.sh Linux/agy-danger.sh Windows/agy.cmd Windows/agy-danger.cmd

ZIP_OUT="$SCRIPT_DIR/AGY-Portable-${VERSION}-All-Platforms.zip"
TAR_OUT="$SCRIPT_DIR/AGY-Portable-${VERSION}-All-Platforms.tar.gz"

rm -f "$ZIP_OUT" "$TAR_OUT"

git archive --format=zip -o "$ZIP_OUT" HEAD
git archive --format=tar.gz -o "$TAR_OUT" HEAD

echo "[Created] $ZIP_OUT"
echo "[Created] $TAR_OUT"

python3 - "$ZIP_OUT" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as zf:
    for info in zf.infolist():
        mode = info.external_attr >> 16
        if info.filename.endswith((".command", ".sh")):
            print(f"Verified: {oct(mode)}  create_system={info.create_system}  {info.filename}")
            assert mode == 0o100755, f"Expected 0o100755 on {info.filename}, got {oct(mode)}"
            assert "\\" not in info.filename, f"Backslash found in {info.filename}"
PY
