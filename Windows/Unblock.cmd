@echo off
setlocal EnableDelayedExpansion
title AGY-Portable - USB Unblock Utility

set "CURR_DIR=%~dp0"
if "%CURR_DIR:~-1%"=="\" set "CURR_DIR=%CURR_DIR:~0,-1%"

:: Target the root of the USB drive or project directory
if exist "%CURR_DIR%\..\data" (
    set "TARGET_DIR=%CURR_DIR%\.."
) else if exist "%CURR_DIR%\..\README.md" (
    set "TARGET_DIR=%CURR_DIR%\.."
) else (
    set "TARGET_DIR=%CURR_DIR%"
)

echo ======================================================
echo      Google Antigravity (AGY) - USB Unblock Tool
echo ======================================================
echo This utility removes the Windows Mark of the Web
echo (Zone.Identifier) from all files on this USB drive.
echo.
echo Target folder: %TARGET_DIR%
echo Unblocking files... Please wait.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'SilentlyContinue';" ^
    "Get-ChildItem -Path '%TARGET_DIR%' -Recurse -Force | Unblock-File;" ^
    "Write-Host '[Success] All files on the USB drive have been unblocked!' -ForegroundColor Green;" ^
    "Write-Host 'You can now double-click agy.cmd or agy-admin.cmd without permission blocks.' -ForegroundColor Cyan;"

echo.
echo Press any key to exit...
pause >nul
