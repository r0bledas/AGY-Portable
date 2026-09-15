#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - Dangerous Runner (macOS)
# Launches AGY CLI with --dangerously-skip-permissions enabled.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export AGY_SKIP_PERMISSIONS=1

exec "$SCRIPT_DIR/agy.command" "$@"
