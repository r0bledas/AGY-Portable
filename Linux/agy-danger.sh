#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - Dangerous Runner (Linux)
# Launches AGY with --dangerously-skip-permissions (auto-approves tool actions)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export AGY_SKIP_PERMISSIONS=1
exec "$SCRIPT_DIR/agy.sh" "$@"
