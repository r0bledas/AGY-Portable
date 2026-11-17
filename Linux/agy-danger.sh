#!/usr/bin/env bash
# ==============================================================================
# Google Antigravity (AGY) - Dangerous Runner (Linux)
# Launches AGY with --dangerously-skip-permissions (auto-approves tool actions)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR/agy.sh" "$SCRIPT_DIR/agy-danger.sh" 2>/dev/null || true
export AGY_SKIP_PERMISSIONS=1
exec bash "$SCRIPT_DIR/agy.sh" "$@"
