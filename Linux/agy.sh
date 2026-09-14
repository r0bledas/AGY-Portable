#!/usr/bin/env bash
# Quick CLI runner for Linux
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/agy-portable.sh" run "$@"
