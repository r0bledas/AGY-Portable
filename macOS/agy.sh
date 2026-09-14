#!/usr/bin/env bash
# Quick CLI runner for macOS
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/agy-portable.command" run "$@"
