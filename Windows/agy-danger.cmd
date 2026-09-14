@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: Google Antigravity (AGY) - Dangerous Runner (Auto-Approve All Permissions)
:: Launches AGY CLI with --dangerously-skip-permissions enabled.
:: ==============================================================================

set "AGY_SKIP_PERMISSIONS=1"
title AGY-Portable [DANGEROUSLY SKIP PERMISSIONS]

call "%~dp0agy.cmd" %*
exit /b %ERRORLEVEL%
