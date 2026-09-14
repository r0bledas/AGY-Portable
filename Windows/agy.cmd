@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: Google Antigravity (AGY) - All-in-One Portable Launcher (Windows)
:: Double-click in Windows Explorer or run in CMD / PowerShell: agy.cmd [/help]
:: ==============================================================================

set "WIN_DIR=%~dp0"
if "%WIN_DIR:~-1%"=="\" set "WIN_DIR=%WIN_DIR:~0,-1%"

:: Detect data directory (Shared root ../data or local ./data)
if exist "%WIN_DIR%\..\data" (
    set "DATA_ROOT=%WIN_DIR%\..\data"
) else if exist "%WIN_DIR%\..\README.md" (
    set "DATA_ROOT=%WIN_DIR%\..\data"
) else (
    set "DATA_ROOT=%WIN_DIR%\data"
)

set "PORTABLE_HOME=%DATA_ROOT%\home"
set "PORTABLE_GEMINI=%PORTABLE_HOME%\.gemini"
set "PORTABLE_TOKEN=%PORTABLE_GEMINI%\jetski-standalone-oauth-token"
set "HOST_TOKEN=%USERPROFILE%\.gemini\jetski-standalone-oauth-token"
set "BIN_DIR=%WIN_DIR%\bin"
set "AGY_BIN=%BIN_DIR%\agy.exe"

:: Temp runner sandbox configuration (bypasses Windows 11 USB execution policies)
set "TEMP_RUN_DIR=%TEMP%\agy-portable-%RANDOM%"
set "TEMP_RUN_EXE=%TEMP_RUN_DIR%\agy.exe"

:: Silently clean up any leftover runner sandboxes from previously interrupted sessions
for /d %%D in ("%TEMP%\agy-portable-*") do rmdir /s /q "%%D" 2>nul

:: Create required directories silently
if not exist "%PORTABLE_GEMINI%" mkdir "%PORTABLE_GEMINI%" 2>nul
if not exist "%DATA_ROOT%\AppData\Roaming" mkdir "%DATA_ROOT%\AppData\Roaming" 2>nul
if not exist "%DATA_ROOT%\AppData\Local" mkdir "%DATA_ROOT%\AppData\Local" 2>nul
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%" 2>nul

:: Handle arguments or launch interactive menu
if "%~1"=="" goto :do_menu

set "ARG1=%~1"
if /i "%ARG1%"=="/help" goto :show_help
if /i "%ARG1%"=="help" goto :show_help
if /i "%ARG1%"=="-h" goto :show_help
if /i "%ARG1%"=="--help" goto :show_help

if /i "%ARG1%"=="/download" goto :do_download
if /i "%ARG1%"=="download" goto :do_download
if /i "%ARG1%"=="/update" goto :do_download
if /i "%ARG1%"=="update" goto :do_download

if /i "%ARG1%"=="/status" goto :cmd_status
if /i "%ARG1%"=="status" goto :cmd_status

if /i "%ARG1%"=="/import" goto :cmd_import
if /i "%ARG1%"=="import" goto :cmd_import

if /i "%ARG1%"=="/export" goto :cmd_export
if /i "%ARG1%"=="export" goto :cmd_export

if /i "%ARG1%"=="/clear" goto :cmd_clear
if /i "%ARG1%"=="clear" goto :cmd_clear

if /i "%ARG1%"=="/login" goto :cmd_login
if /i "%ARG1%"=="login" goto :cmd_login
if /i "%ARG1%"=="/signin" goto :cmd_login
if /i "%ARG1%"=="signin" goto :cmd_login

if /i "%ARG1%"=="/shell" goto :do_shell
if /i "%ARG1%"=="shell" goto :do_shell

if /i "%ARG1%"=="/menu" goto :do_menu
if /i "%ARG1%"=="menu" goto :do_menu

if /i "%ARG1%"=="/danger" (
    set "AGY_SKIP_PERMISSIONS=1"
    shift
    if "%~1"=="" goto :do_menu
    goto :do_run
)

if /i "%ARG1%"=="/run" (
    shift
    goto :do_run
)

:: Default: Pass all arguments directly to agy.exe
goto :do_run

:: ==============================================================================
:: Functions & Routines
:: ==============================================================================

:set_env
set "USERPROFILE=%PORTABLE_HOME%"
set "HOME=%PORTABLE_HOME%"
set "HOMEDRIVE=%DATA_ROOT:~0,2%"
set "HOMEPATH=%DATA_ROOT:~2%\home"
set "APPDATA=%DATA_ROOT%\AppData\Roaming"
set "LOCALAPPDATA=%DATA_ROOT%\AppData\Local"
set "PATH=%TEMP_RUN_DIR%;%BIN_DIR%;%WIN_DIR%;%PATH%"
goto :eof

:ensure_bin
if exist "%AGY_BIN%" goto :eof

echo ======================================================
echo   Antigravity CLI binary not found in Windows\bin\agy.exe
echo ======================================================

:: Check host installation
set "HOST_AGY=%LOCALAPPDATA%\agy\bin\agy.exe"
if exist "%HOST_AGY%" (
    echo Found existing installation on this PC at: %HOST_AGY%
    set /p "COPY_CONFIRM=Copy from this PC to USB? [Y/n]: "
    if /i not "!COPY_CONFIRM!"=="n" (
        copy /y "%HOST_AGY%" "%AGY_BIN%" >nul
        echo [Success] Copied agy.exe into bin\agy.exe!
        goto :eof
    )
)

echo The binary can be downloaded directly from Google servers (~50 MB).
set /p "DL_CONFIRM=Download now? [Y/n]: "
if /i not "!DL_CONFIRM!"=="n" (
    call :do_download
    goto :eof
)

echo [Error] Execution aborted. Please place agy.exe in Windows\bin\agy.exe.
exit /b 1

:prepare_runner
call :ensure_bin
if not exist "%AGY_BIN%" exit /b 1
if defined RUNNER_READY if exist "%TEMP_RUN_EXE%" goto :eof

if not exist "%TEMP_RUN_DIR%" mkdir "%TEMP_RUN_DIR%" 2>nul

echo [Preparing Runner] Loading engine into temp sandbox for Windows 11...
echo Reading from USB drive. Please wait (~190 MB)...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$src = '%AGY_BIN%';" ^
    "$dst = '%TEMP_RUN_EXE%';" ^
    "$fileInfo = Get-Item $src;" ^
    "$totalBytes = $fileInfo.Length;" ^
    "$inStream = [System.IO.File]::OpenRead($src);" ^
    "$outStream = [System.IO.File]::Create($dst);" ^
    "$buffer = New-Object byte[] (4 * 1024 * 1024);" ^
    "$copied = 0;" ^
    "$lastPct = -1;" ^
    "try {" ^
    "    while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {" ^
    "        $outStream.Write($buffer, 0, $read);" ^
    "        $copied += $read;" ^
    "        $pct = [int](($copied / $totalBytes) * 100);" ^
    "        if ($pct -ne $lastPct -and $pct %% 10 -eq 0) {" ^
    "            $lastPct = $pct;" ^
    "            Write-Host ('  - Progress: ' + $pct + '%% (' + [int]($copied / 1MB) + ' MB / ' + [int]($totalBytes / 1MB) + ' MB)');" ^
    "        }" ^
    "    }" ^
    "} finally {" ^
    "    $inStream.Close();" ^
    "    $outStream.Close();" ^
    "};" ^
    "Unblock-File -Path $dst -ErrorAction SilentlyContinue;"

if not exist "%TEMP_RUN_EXE%" (
    echo [Error] Failed to load runner into temp sandbox.
    exit /b 1
)
set "RUNNER_READY=1"
echo [Ready] Engine loaded successfully.
echo.
goto :eof

:cleanup_runner
if exist "%TEMP_RUN_DIR%" (
    rmdir /s /q "%TEMP_RUN_DIR%" 2>nul
)
set "RUNNER_READY="
goto :eof

:do_download
echo ======================================================
echo        Downloading Antigravity CLI for Windows
echo ======================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$binDir = '%BIN_DIR%';" ^
    "$targetExe = '%AGY_BIN%';" ^
    "$manifestUrl = 'https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json';" ^
    "$fallbackUrl = 'https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/windows-x64/cli_windows_x64.zip';" ^
    "Write-Host 'Fetching release metadata from Google...';" ^
    "try { $dlUrl = (Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing).url } catch { $dlUrl = $fallbackUrl };" ^
    "if (-not $dlUrl) { $dlUrl = $fallbackUrl };" ^
    "Write-Host ('Download URL: ' + $dlUrl);" ^
    "$zipPath = Join-Path $binDir 'agy_win.zip';" ^
    "Write-Host 'Downloading (~50 MB compressed, ~190 MB uncompressed)...' -ForegroundColor Cyan;" ^
    "Invoke-WebRequest -Uri $dlUrl -OutFile $zipPath -UseBasicParsing;" ^
    "Write-Host 'Extracting archive into bin...' -ForegroundColor Cyan;" ^
    "Expand-Archive -Path $zipPath -DestinationPath $binDir -Force;" ^
    "Remove-Item $zipPath -Force;" ^
    "if (Test-Path (Join-Path $binDir 'antigravity.exe')) { Move-Item -Path (Join-Path $binDir 'antigravity.exe') -Destination $targetExe -Force };" ^
    "Unblock-File -Path (Join-Path $binDir '*') -ErrorAction SilentlyContinue;" ^
    "Write-Host '[Success] Antigravity CLI installed successfully in bin\agy.exe!' -ForegroundColor Green;"
call :cleanup_runner
goto :eof

:show_status
echo ======================================================
echo        Google Antigravity (AGY) - Windows Hub
echo ======================================================
echo  Location: %WIN_DIR%
echo  Data Dir: %DATA_ROOT%

if exist "%AGY_BIN%" (
    echo  CLI Core: Ready [%AGY_BIN%]
) else (
    echo  CLI Core: MISSING [Use option 7 or /download to install]
)

if exist "%PORTABLE_TOKEN%" (
    echo  USB Auth: Authenticated [Token present]
) else (
    echo  USB Auth: Not logged in [Use option 3 or 5]
)

if exist "%HOST_TOKEN%" (
    echo Host Auth: Detected on this PC [%HOST_TOKEN%]
) else (
    echo Host Auth: Not found on this PC
)

if defined AGY_SKIP_PERMISSIONS (
    echo  Security: DANGEROUSLY SKIP PERMISSIONS [Auto-approves all tool actions]
) else (
    echo  Security: Standard [Prompts for tool approvals]
)
echo ------------------------------------------------------
goto :eof

:do_import
if not exist "%HOST_TOKEN%" (
    echo [Error] No host login credentials found at: %HOST_TOKEN%
    goto :eof
)
copy /y "%HOST_TOKEN%" "%PORTABLE_TOKEN%" >nul
echo [Success] Credentials copied from this PC to your USB drive!
goto :eof

:do_export
if not exist "%PORTABLE_TOKEN%" (
    echo [Error] No credentials found on USB to export.
    goto :eof
)
for %%I in ("%HOST_TOKEN%") do if not exist "%%~dpI" mkdir "%%~dpI" 2>nul
copy /y "%PORTABLE_TOKEN%" "%HOST_TOKEN%" >nul
echo [Success] Credentials exported to this PC (%HOST_TOKEN%).
goto :eof

:do_clear
if exist "%PORTABLE_TOKEN%" (
    del /f /q "%PORTABLE_TOKEN%" 2>nul
    echo [Success] USB credentials removed. Conversations and settings remain safe.
) else (
    echo No credentials found on USB to clear.
)
call :cleanup_runner
goto :eof

:do_run
call :prepare_runner
if not exist "%TEMP_RUN_EXE%" exit /b 1
call :set_env
if defined AGY_SKIP_PERMISSIONS (
    "%TEMP_RUN_EXE%" --dangerously-skip-permissions %*
) else (
    "%TEMP_RUN_EXE%" %*
)
set "RUN_EXIT=%ERRORLEVEL%"
if not defined IN_MENU (
    call :cleanup_runner
)
exit /b %RUN_EXIT%

:do_shell
call :prepare_runner
call :set_env
echo.
echo Starting interactive portable shell...
echo Type 'agy' to run the CLI. Type 'exit' to return.
echo.
cmd.exe /k
if not defined IN_MENU (
    call :cleanup_runner
)
goto :eof

:do_login
call :prepare_runner
if not exist "%TEMP_RUN_EXE%" exit /b 1
call :set_env
echo Launching Antigravity CLI to sign in...
echo Follow the prompts in your browser or terminal to complete login.
echo.
if defined AGY_SKIP_PERMISSIONS (
    "%TEMP_RUN_EXE%" --dangerously-skip-permissions
) else (
    "%TEMP_RUN_EXE%"
)
if not defined IN_MENU (
    call :cleanup_runner
)
goto :eof

:show_help
echo =================================================================
echo   Google Antigravity (AGY) - Windows Portable Command Reference
echo =================================================================
echo Usage: agy.cmd [command] [options]
echo.
echo Slash Commands:
echo   /help         Show this help screen with all available commands
echo   /download     Download official AGY binary directly from Google
echo   /update       Update AGY binary to the latest version from Google
echo   /status       Display binary readiness and OAuth login status
echo   /import       Import host PC credentials (%%USERPROFILE%%\.gemini) to USB
echo   /export       Export USB credentials to host PC (%%USERPROFILE%%\.gemini)
echo   /login        Sign in via Google OAuth in your default browser
echo   /clear        Wipe login credentials from USB for safe lending
echo   /shell        Open an interactive shell with portable environment
echo   /danger       Launch in dangerously-skip-permissions mode
echo   /menu         Open the interactive terminal menu
echo   /run [args]   Execute AGY CLI directly with arguments
echo.
echo Direct CLI Pass-Through:
echo   You can pass standard AGY CLI flags directly, for example:
echo     agy.cmd models
echo     agy.cmd -p "Explain relativity in one sentence"
echo     agy.cmd --version
echo =================================================================
goto :eof

:cmd_status
call :show_status
goto :eof

:cmd_import
call :do_import
goto :eof

:cmd_export
call :do_export
goto :eof

:cmd_clear
call :do_clear
goto :eof

:cmd_login
call :do_login
goto :eof

:do_menu
set "IN_MENU=1"
cls
call :show_status
if defined AGY_SKIP_PERMISSIONS (
    echo  [1] Launch AGY CLI [DANGEROUSLY SKIP PERMISSIONS]
) else (
    echo  [1] Launch AGY CLI
)
echo  [2] Open Interactive Portable Shell (/shell)
echo  [3] Import Login from this PC (/import)
echo  [4] Export USB Login to this PC (/export)
echo  [5] Sign In via Browser (/login)
echo  [6] Clear USB Login (/clear)
echo  [7] Download / Update Core Binary (/download)
echo  [8] Show Command Help (/help)
echo  [0] Exit
echo ------------------------------------------------------
set /p "OPT= Select an option [0-8]: "

if "%OPT%"=="1" (
    echo.
    call :do_run
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="2" (
    echo.
    call :do_shell
    goto :do_menu
)
if "%OPT%"=="3" (
    echo.
    call :do_import
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="4" (
    echo.
    call :do_export
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="5" (
    echo.
    call :do_login
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="6" (
    echo.
    call :do_clear
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="7" (
    echo.
    call :do_download
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="8" (
    echo.
    call :show_help
    echo.
    pause
    goto :do_menu
)
if "%OPT%"=="0" (
    call :cleanup_runner
    echo Goodbye!
    exit /b 0
)

echo Invalid option.
timeout /t 1 >nul
goto :do_menu
