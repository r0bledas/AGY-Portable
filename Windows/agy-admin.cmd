@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: Google Antigravity (AGY) - Administrator Launcher (Windows)
:: Automatically requests UAC elevation if not already running as Administrator.
:: ==============================================================================

:: Check for administrative rights
net session >nul 2>&1
if %ERRORLEVEL% equ 0 goto :is_admin

:: Not admin - request UAC elevation via PowerShell
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo Requesting Administrator privileges (UAC)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$argsList = '/c set _AGY_ELEVATED_SPAWN=1 & call ""%~f0"" %*';" ^
    "Start-Process -FilePath 'cmd.exe' -ArgumentList $argsList -WorkingDirectory '%SCRIPT_DIR%' -Verb RunAs"
exit /b %ERRORLEVEL%

:is_admin
cd /d "%~dp0"
title AGY-Portable [Administrator]
call "%~dp0agy.cmd" %*
set "EXIT_CODE=%ERRORLEVEL%"

:: If spawned in a new window via UAC elevation and arguments were passed, pause to keep output visible
if defined _AGY_ELEVATED_SPAWN (
    if not "%~1"=="" (
        echo.
        echo ------------------------------------------------------
        echo [Elevated execution finished. Press any key to exit...]
        pause >nul
    )
)

exit /b %EXIT_CODE%
