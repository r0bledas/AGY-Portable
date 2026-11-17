@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: Google Antigravity (AGY) - All-in-One Portable Launcher (Windows)
:: Double-click in Windows Explorer or run in CMD / PowerShell: agy.cmd [/help]
:: ==============================================================================

set "CURRENT_VERSION=v2.0.0"
set "GITHUB_REPO=r0bledas/AGY-Portable"

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
set "ACCOUNTS_DIR=%DATA_ROOT%\accounts"
set "ACTIVE_FILE=%ACCOUNTS_DIR%\.active"

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
call :acct_migrate

:: Handle arguments or launch interactive menu
if "%~1"=="" goto :do_menu

set "ARG1=%~1"
if /i "%ARG1%"=="/help" goto :show_help
if /i "%ARG1%"=="help" goto :show_help
if /i "%ARG1%"=="-h" goto :show_help
if /i "%ARG1%"=="--help" goto :show_help

if /i "%ARG1%"=="/update" goto :cmd_update
if /i "%ARG1%"=="update" goto :cmd_update
if /i "%ARG1%"=="/check-updates" goto :cmd_update
if /i "%ARG1%"=="check-updates" goto :cmd_update

if /i "%ARG1%"=="/download" goto :do_download_bin
if /i "%ARG1%"=="download" goto :do_download_bin
if /i "%ARG1%"=="/download-bin" goto :do_download_bin
if /i "%ARG1%"=="download-bin" goto :do_download_bin

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

if /i "%ARG1%"=="/account" goto :cmd_account
if /i "%ARG1%"=="/accounts" goto :cmd_account
if /i "%ARG1%"=="/acc" goto :cmd_account

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
    call :do_download_bin
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

:do_download_bin
echo ======================================================
echo        Downloading Antigravity CLI for Windows
echo ======================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$binDir = '%BIN_DIR%';" ^
    "$targetExe = '%AGY_BIN%';" ^
    "$manifestUrl = 'https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json';" ^
    "$fallbackUrl = 'https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.3-5101874907578368/windows-x64/cli_windows_x64.exe';" ^
    "Write-Host 'Fetching release metadata from Google...';" ^
    "try { $dlUrl = (Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing).url } catch { $dlUrl = $fallbackUrl };" ^
    "if (-not $dlUrl) { $dlUrl = $fallbackUrl };" ^
    "Write-Host ('Download URL: ' + $dlUrl);" ^
    "$wc = New-Object System.Net.WebClient;" ^
    "if ($dlUrl.EndsWith('.exe')) {" ^
    "    $tmpExe = Join-Path $binDir 'agy_new.exe';" ^
    "    Write-Host 'Downloading binary (~190 MB)...' -ForegroundColor Cyan;" ^
    "    $wc.DownloadFile($dlUrl, $tmpExe);" ^
    "    Move-Item -Path $tmpExe -Destination $targetExe -Force;" ^
    "} else {" ^
    "    $zipPath = Join-Path $binDir 'agy_win.zip';" ^
    "    Write-Host 'Downloading (~50 MB compressed, ~190 MB uncompressed)...' -ForegroundColor Cyan;" ^
    "    $wc.DownloadFile($dlUrl, $zipPath);" ^
    "    Write-Host 'Extracting archive into bin...' -ForegroundColor Cyan;" ^
    "    Expand-Archive -Path $zipPath -DestinationPath $binDir -Force;" ^
    "    Remove-Item $zipPath -Force;" ^
    "    if (Test-Path (Join-Path $binDir 'antigravity.exe')) { Move-Item -Path (Join-Path $binDir 'antigravity.exe') -Destination $targetExe -Force };" ^
    "};" ^
    "Unblock-File -Path (Join-Path $binDir '*') -ErrorAction SilentlyContinue;" ^
    "Write-Host '[Success] Antigravity CLI installed successfully in bin\agy.exe!' -ForegroundColor Green;"
call :cleanup_runner
goto :eof

:check_updates
echo ======================================================
echo                 Checking for Updates
echo ======================================================
echo  Launcher Version: %CURRENT_VERSION%
echo  Repository:       https://github.com/%GITHUB_REPO%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%WIN_DIR%\updater.ps1" -Repo "%GITHUB_REPO%" -CurrentVersion "%CURRENT_VERSION%" -WinDir "%WIN_DIR%" -BinDir "%BIN_DIR%" -TargetExe "%AGY_BIN%"
call :cleanup_runner
goto :eof

:show_status
echo ======================================================
echo        Google Antigravity (AGY) - Windows Hub
echo ======================================================
echo  Version:  %CURRENT_VERSION%
echo  Location: %WIN_DIR%
echo  Data Dir: %DATA_ROOT%

if exist "%AGY_BIN%" (
    echo  CLI Core: Ready [%AGY_BIN%]
) else (
    echo  CLI Core: MISSING [Use /download to install or option 7]
)

if exist "%PORTABLE_TOKEN%" (
    echo  USB Auth: Authenticated [Token present]
) else (
    echo  USB Auth: Not logged in [Use option 3 or 5]
)

call :show_account_status

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
set "ACCT_NAME=%~1"
if "%ACCT_NAME%"=="" set "ACCT_NAME=host"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
call :acct_sync_back
call :acct_store_token "%HOST_TOKEN%" "%ACCT_NAME%"
call :acct_load_token "%ACCT_NAME%"
call :acct_set_active "%ACCT_NAME%"
echo [Success] Credentials copied from this PC to your USB drive as account "%ACCT_NAME%".
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
if /i "%~1"=="all" (
    if exist "%PORTABLE_TOKEN%" del /f /q "%PORTABLE_TOKEN%" 2>nul
    if exist "%PORTABLE_TOKEN%.bak" del /f /q "%PORTABLE_TOKEN%.bak" 2>nul
    if exist "%ACCOUNTS_DIR%" rmdir /s /q "%ACCOUNTS_DIR%" 2>nul
    mkdir "%ACCOUNTS_DIR%" 2>nul
    set "ACTIVE_ACCOUNT="
    echo [Success] All credentials - active login and every saved account - removed from USB.
    call :cleanup_runner
    goto :eof
)
call :acct_sync_back
if exist "%PORTABLE_TOKEN%" (
    del /f /q "%PORTABLE_TOKEN%" 2>nul
    echo [Success] USB credentials removed. Conversations and settings remain safe.
) else (
    echo No credentials found on USB to clear.
)
call :acct_set_active ""
call :acct_count
if not "%ACCT_COUNT%"=="0" echo Note: %ACCT_COUNT% saved account profiles remain on USB. Use "/clear all" to wipe everything before lending.
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

:: ==============================================================================
:: Multi-Account Profiles
::   data\accounts\<name>\token   saved credentials per profile
::   data\accounts\.active        name of the profile loaded into the live slot
::   The live slot (%PORTABLE_TOKEN%) is what the AGY CLI actually reads.
:: ==============================================================================

:acct_validate
set "ACCT_OK="
if "%~1"=="" goto :eof
echo(%~1| findstr /r /x "[-A-Za-z0-9_]*" >nul && set "ACCT_OK=1"
goto :eof

:acct_err_name
echo [Error] Invalid account name "%ACCT_NAME%". Use letters, digits, - or _.
goto :eof

:acct_get_active
set "ACTIVE_ACCOUNT="
if exist "%ACTIVE_FILE%" set /p ACTIVE_ACCOUNT=<"%ACTIVE_FILE%"
if not defined ACTIVE_ACCOUNT goto :eof
set "ACTIVE_ACCOUNT=%ACTIVE_ACCOUNT: =%"
call :acct_validate "%ACTIVE_ACCOUNT%"
if not defined ACCT_OK set "ACTIVE_ACCOUNT="
goto :eof

:acct_set_active
if "%~1"=="" (
    if exist "%ACTIVE_FILE%" del /f /q "%ACTIVE_FILE%" >nul 2>&1
    set "ACTIVE_ACCOUNT="
    goto :eof
)
if not exist "%ACCOUNTS_DIR%" mkdir "%ACCOUNTS_DIR%" 2>nul
>"%ACTIVE_FILE%" echo(%~1
set "ACTIVE_ACCOUNT=%~1"
goto :eof

:acct_count
set "ACCT_COUNT=0"
if not exist "%ACCOUNTS_DIR%" goto :eof
for /d %%D in ("%ACCOUNTS_DIR%\*") do if exist "%%~fD\token" set /a ACCT_COUNT+=1
goto :eof

:acct_store_token
if not exist "%ACCOUNTS_DIR%\%~2" mkdir "%ACCOUNTS_DIR%\%~2" 2>nul
copy /y "%~1" "%ACCOUNTS_DIR%\%~2\token" >nul
goto :eof

:acct_load_token
if not exist "%PORTABLE_GEMINI%" mkdir "%PORTABLE_GEMINI%" 2>nul
copy /y "%ACCOUNTS_DIR%\%~1\token" "%PORTABLE_TOKEN%" >nul
goto :eof

:acct_migrate
if exist "%WIN_DIR%\accounts.ps1" goto :eof
if not exist "%ACCOUNTS_DIR%" mkdir "%ACCOUNTS_DIR%" 2>nul
call :acct_get_active
if defined ACTIVE_ACCOUNT goto :eof
if not exist "%PORTABLE_TOKEN%" goto :eof
call :acct_count
if not "%ACCT_COUNT%"=="0" goto :eof
call :acct_store_token "%PORTABLE_TOKEN%" "default"
call :acct_set_active "default"
echo [Accounts] Existing login saved as profile "default".
goto :eof

:acct_sync_back
:: Persist the (possibly refreshed) live token into the active profile
call :acct_get_active
if not defined ACTIVE_ACCOUNT goto :eof
if not exist "%PORTABLE_TOKEN%" goto :eof
call :acct_store_token "%PORTABLE_TOKEN%" "%ACTIVE_ACCOUNT%"
goto :eof

:show_account_status
if exist "%WIN_DIR%\accounts.ps1" (
    for /f "usebackq delims=" %%L in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%WIN_DIR%\accounts.ps1' current"`) do (
        echo   Account: %%L
    )
    goto :eof
)
call :acct_get_active
call :acct_count
if defined ACTIVE_ACCOUNT (
    echo   Account: %ACTIVE_ACCOUNT% [%ACCT_COUNT% saved]
) else if exist "%PORTABLE_TOKEN%" (
    echo   Account: Unsaved login [use /account save NAME]
) else (
    echo   Account: None [%ACCT_COUNT% saved]
)
goto :eof

:acct_list
call :acct_get_active
echo ======================================================
echo                 Saved AGY Accounts
echo ======================================================
set "ACCT_FOUND="
if exist "%ACCOUNTS_DIR%" for /d %%D in ("%ACCOUNTS_DIR%\*") do (
    if exist "%%~fD\token" (
        set "ACCT_FOUND=1"
        if /i "%%~nxD"=="!ACTIVE_ACCOUNT!" (
            echo   * %%~nxD   [active]
        ) else (
            echo     %%~nxD
        )
    )
)
if not defined ACCT_FOUND echo   [no saved accounts - use /account add NAME]
if not defined ACTIVE_ACCOUNT if exist "%PORTABLE_TOKEN%" echo   Note: current login is not saved. Use /account save NAME
echo ------------------------------------------------------
goto :eof

:acct_use
set "ACCT_NAME=%~1"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
if not exist "%ACCOUNTS_DIR%\%ACCT_NAME%\token" (
    echo [Error] No saved account named "%ACCT_NAME%". Run /account list.
    goto :eof
)
call :acct_sync_back
call :acct_load_token "%ACCT_NAME%"
call :acct_set_active "%ACCT_NAME%"
echo [Success] Active account: %ACCT_NAME%
goto :eof

:acct_save
set "ACCT_NAME=%~1"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
if not exist "%PORTABLE_TOKEN%" (
    echo [Error] Not logged in. Use /login or /account add NAME first.
    goto :eof
)
call :acct_store_token "%PORTABLE_TOKEN%" "%ACCT_NAME%"
call :acct_set_active "%ACCT_NAME%"
echo [Success] Current login saved as "%ACCT_NAME%" and set active.
goto :eof

:acct_add
set "ACCT_NAME=%~1"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
if exist "%ACCOUNTS_DIR%\%ACCT_NAME%\token" (
    echo [Error] Account "%ACCT_NAME%" already exists. Use /account use %ACCT_NAME%
    goto :eof
)
call :acct_sync_back
set "ACCT_PREV=%ACTIVE_ACCOUNT%"
if exist "%PORTABLE_TOKEN%" move /y "%PORTABLE_TOKEN%" "%PORTABLE_TOKEN%.bak" >nul
call :acct_set_active ""
echo Sign in with the Google account for "%ACCT_NAME%".
echo When login completes, exit AGY to save the profile.
echo.
call :do_login
if exist "%PORTABLE_TOKEN%" (
    call :acct_store_token "%PORTABLE_TOKEN%" "%ACCT_NAME%"
    call :acct_set_active "%ACCT_NAME%"
    if exist "%PORTABLE_TOKEN%.bak" del /f /q "%PORTABLE_TOKEN%.bak" 2>nul
    echo [Success] Account "%ACCT_NAME%" added and set active.
) else (
    echo [Error] Login was not completed. Restoring previous account.
    if exist "%PORTABLE_TOKEN%.bak" move /y "%PORTABLE_TOKEN%.bak" "%PORTABLE_TOKEN%" >nul
    call :acct_set_active "%ACCT_PREV%"
)
goto :eof

:acct_remove
set "ACCT_NAME=%~1"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
if not exist "%ACCOUNTS_DIR%\%ACCT_NAME%" (
    echo [Error] No saved account named "%ACCT_NAME%".
    goto :eof
)
call :acct_get_active
if /i "%ACCT_NAME%"=="%ACTIVE_ACCOUNT%" (
    echo [Error] "%ACCT_NAME%" is the active account. Switch to another account first, or use /clear.
    goto :eof
)
rmdir /s /q "%ACCOUNTS_DIR%\%ACCT_NAME%" 2>nul
echo [Success] Removed account "%ACCT_NAME%".
goto :eof

:acct_rename
set "ACCT_NAME=%~1"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
set "ACCT_OLD=%~1"
set "ACCT_NAME=%~2"
call :acct_validate "%ACCT_NAME%"
if not defined ACCT_OK goto :acct_err_name
if not exist "%ACCOUNTS_DIR%\%ACCT_OLD%" (
    echo [Error] No saved account named "%ACCT_OLD%".
    goto :eof
)
if exist "%ACCOUNTS_DIR%\%ACCT_NAME%" (
    echo [Error] An account named "%ACCT_NAME%" already exists.
    goto :eof
)
ren "%ACCOUNTS_DIR%\%ACCT_OLD%" "%ACCT_NAME%"
call :acct_get_active
if /i "%ACTIVE_ACCOUNT%"=="%ACCT_OLD%" call :acct_set_active "%ACCT_NAME%"
echo [Success] Renamed "%ACCT_OLD%" to "%ACCT_NAME%".
goto :eof

:acct_help
echo Account commands:
echo   /account list                 List saved accounts [* = active]
echo   /account use NAME             Switch the active account
echo   /account add NAME             Sign in with a new account and save it
echo   /account save NAME            Save the current login as a profile
echo   /account status               Show the account currently signed in
echo   /account remove NAME          Delete a saved [inactive] account
echo   /account rename OLD NEW       Rename a saved account
goto :eof

:cmd_account
if exist "%WIN_DIR%\accounts.ps1" goto :cmd_account_ps1
set "ACCT_SUB=%~2"
if "%ACCT_SUB%"=="" goto :acct_list
if /i "%ACCT_SUB%"=="list" goto :acct_list
if /i "%ACCT_SUB%"=="ls" goto :acct_list
if /i "%ACCT_SUB%"=="use" goto :cmd_account_use
if /i "%ACCT_SUB%"=="switch" goto :cmd_account_use
if /i "%ACCT_SUB%"=="add" goto :cmd_account_add
if /i "%ACCT_SUB%"=="new" goto :cmd_account_add
if /i "%ACCT_SUB%"=="save" goto :cmd_account_save
if /i "%ACCT_SUB%"=="remove" goto :cmd_account_remove
if /i "%ACCT_SUB%"=="rm" goto :cmd_account_remove
if /i "%ACCT_SUB%"=="delete" goto :cmd_account_remove
if /i "%ACCT_SUB%"=="del" goto :cmd_account_remove
if /i "%ACCT_SUB%"=="rename" goto :cmd_account_rename
if /i "%ACCT_SUB%"=="mv" goto :cmd_account_rename
if /i "%ACCT_SUB%"=="help" goto :acct_help
echo [Error] Unknown account command: %ACCT_SUB%
call :acct_help
exit /b 1

:cmd_account_use
call :acct_use "%~3"
goto :eof
:cmd_account_add
call :acct_add "%~3"
call :cleanup_runner
goto :eof
:cmd_account_save
call :acct_save "%~3"
goto :eof
:cmd_account_remove
call :acct_remove "%~3"
goto :eof
:cmd_account_rename
call :acct_rename "%~3" "%~4"
goto :eof

:: ---------------------------------------------------------------------------
:: Vault-based account commands (Windows Credential Manager via accounts.ps1).
:: The AGY CLI on Windows reads "gemini:antigravity" from Credential Manager;
:: the token file is only a fallback for macOS/Linux, so these are the real ones.
:: ---------------------------------------------------------------------------
:cmd_account_ps1
set "AGY_ACCT_PS1=%WIN_DIR%\accounts.ps1"
set "ACCT_SUB=%~2"
if "%ACCT_SUB%"=="" goto :acct_list_ps1
if /i "%ACCT_SUB%"=="list" goto :acct_list_ps1
if /i "%ACCT_SUB%"=="ls" goto :acct_list_ps1
if /i "%ACCT_SUB%"=="use" goto :acct_use_ps1
if /i "%ACCT_SUB%"=="switch" goto :acct_use_ps1
if /i "%ACCT_SUB%"=="save" goto :acct_save_ps1
if /i "%ACCT_SUB%"=="add" goto :acct_add_ps1
if /i "%ACCT_SUB%"=="new" goto :acct_add_ps1
if /i "%ACCT_SUB%"=="remove" goto :acct_remove_ps1
if /i "%ACCT_SUB%"=="rm" goto :acct_remove_ps1
if /i "%ACCT_SUB%"=="delete" goto :acct_remove_ps1
if /i "%ACCT_SUB%"=="del" goto :acct_remove_ps1
if /i "%ACCT_SUB%"=="rename" goto :acct_rename_ps1
if /i "%ACCT_SUB%"=="mv" goto :acct_rename_ps1
if /i "%ACCT_SUB%"=="status" goto :acct_current_ps1
if /i "%ACCT_SUB%"=="current" goto :acct_current_ps1
if /i "%ACCT_SUB%"=="help" goto :acct_help
echo [Error] Unknown account command: %ACCT_SUB%
call :acct_help
exit /b 1

:acct_list_ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" list
goto :eof

:acct_use_ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" use "%~3"
goto :eof

:acct_save_ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" save "%~3"
goto :eof

:acct_add_ps1
if "%~3"=="" (
    echo Usage: agy.cmd /account add NAME
    goto :eof
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" list
echo.
echo To add a NEW Google account:
echo   1. Run:   agy.cmd /login
echo   2. Type:  /logout   (confirm), then  /exit
echo   3. Run:   agy.cmd /login  and sign in with the OTHER account
echo   4. Save:  agy.cmd /account save "%~3"
goto :eof

:acct_remove_ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" remove "%~3"
goto :eof

:acct_rename_ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" rename "%~3" "%~4"
goto :eof

:acct_current_ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGY_ACCT_PS1%" current
goto :eof

:acct_menu
if exist "%WIN_DIR%\accounts.ps1" goto :acct_menu_ps1
cls
call :acct_list
echo  [U] Switch account      [A] Add account - sign in
echo  [S] Save current login  [R] Remove account
echo  [N] Rename account      [B] Back
echo ------------------------------------------------------
set "AOPT="
set "AN="
set "AN2="
set /p "AOPT= Select an option: "
if "%AOPT%"=="" goto :eof
if /i "%AOPT%"=="B" goto :eof
if /i "%AOPT%"=="U" (
    set /p "AN= Account to use: "
    call :acct_use "!AN!"
)
if /i "%AOPT%"=="A" (
    set /p "AN= New account name: "
    call :acct_add "!AN!"
)
if /i "%AOPT%"=="S" (
    set /p "AN= Save current login as: "
    call :acct_save "!AN!"
)
if /i "%AOPT%"=="R" (
    set /p "AN= Account to remove: "
    call :acct_remove "!AN!"
)
if /i "%AOPT%"=="N" (
    set /p "AN= Current name: "
    set /p "AN2= New name: "
    call :acct_rename "!AN!" "!AN2!"
)
echo.
pause
goto :acct_menu

:acct_menu_ps1
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%WIN_DIR%\accounts.ps1" list
echo ------------------------------------------------------
set "AN="
set /p "AN= Account to use [Enter for none]: "
if "%AN%"=="" goto :eof
powershell -NoProfile -ExecutionPolicy Bypass -File "%WIN_DIR%\accounts.ps1" use "%AN%"
echo.
pause
goto :acct_menu_ps1

:show_help
echo =================================================================
echo   Google Antigravity (AGY) - Windows Portable Command Reference
echo =================================================================
echo Version: %CURRENT_VERSION%
echo Usage:   agy.cmd [command] [options]
echo.
echo Slash Commands:
echo   /help         Show this help screen with all available commands
echo   /update       Check for updates (GitHub scripts and Google CLI engine)
echo   /download     Download official AGY binary directly from Google
echo   /status       Display binary readiness, OAuth login status, and version
echo   /import [name] Import host PC credentials (%%USERPROFILE%%\.gemini) as a USB account
echo   /export       Export USB credentials to host PC (%%USERPROFILE%%\.gemini)
echo   /login        Sign in via Google OAuth in your default browser
echo   /clear        Sign out of the active account [saved accounts kept]
echo   /clear all    Wipe ALL credentials and saved accounts [safe lending]
echo   /account ...  Manage multiple accounts: list, use, add, save, remove, rename
echo                 /login re-signs the ACTIVE account; use /account add for another one
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

:cmd_update
call :check_updates
goto :eof

:cmd_import
call :do_import "%~2"
goto :eof

:cmd_export
call :do_export
goto :eof

:cmd_clear
call :do_clear "%~2"
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
echo  [7] Check for updates (/update)
echo  [8] Show Command Help (/help)
echo  [9] Manage Accounts (/account)
echo  [0] Exit
echo ------------------------------------------------------
set /p "OPT= Select an option [0-9]: "

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
    call :check_updates
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
if "%OPT%"=="9" (
    call :acct_menu
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
