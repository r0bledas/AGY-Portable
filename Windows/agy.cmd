@echo off
setlocal
set "WIN_DIR=%~dp0"
if "%WIN_DIR:~-1%"=="\" set "WIN_DIR=%WIN_DIR:~0,-1%"

if exist "%WIN_DIR%\..\data" (
    set "DATA_ROOT=%WIN_DIR%\..\data"
) else (
    set "DATA_ROOT=%WIN_DIR%\data"
)

set "USERPROFILE=%DATA_ROOT%\home"
set "HOME=%DATA_ROOT%\home"
set "HOMEDRIVE=%DATA_ROOT:~0,2%"
set "HOMEPATH=%DATA_ROOT:~2%\home"
set "APPDATA=%DATA_ROOT%\AppData\Roaming"
set "LOCALAPPDATA=%DATA_ROOT%\AppData\Local"
set "PATH=%WIN_DIR%\bin;%WIN_DIR%;%PATH%"

if not exist "%WIN_DIR%\bin\agy.exe" (
    echo [ERROR] agy.exe not found at "%WIN_DIR%\bin\agy.exe"
    echo Run setup-bin.ps1 to copy agy.exe into bin\agy.exe.
    exit /b 1
)

"%WIN_DIR%\bin\agy.exe" %*
exit /b %ERRORLEVEL%
