#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - Dangerous Runner (macOS)
# Launches AGY CLI with --dangerously-skip-permissions enabled.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR/agy.command" "$SCRIPT_DIR/agy-danger.command" 2>/dev/null || true
export AGY_SKIP_PERMISSIONS=1

exec bash "$SCRIPT_DIR/agy.command" "$@"
