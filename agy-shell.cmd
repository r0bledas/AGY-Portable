@echo off
set "PORTABLE_ROOT=%~dp0"
if "%PORTABLE_ROOT:~-1%"=="\" set "PORTABLE_ROOT=%PORTABLE_ROOT:~0,-1%"

set "USERPROFILE=%PORTABLE_ROOT%\data\home"
set "HOME=%PORTABLE_ROOT%\data\home"
set "HOMEDRIVE=%PORTABLE_ROOT:~0,2%"
set "HOMEPATH=%PORTABLE_ROOT:~2%\data\home"
set "APPDATA=%PORTABLE_ROOT%\data\AppData\Roaming"
set "LOCALAPPDATA=%PORTABLE_ROOT%\data\AppData\Local"
set "PATH=%PORTABLE_ROOT%\bin;%PORTABLE_ROOT%;%PATH%"

title AGY Portable Shell
echo =======================================================
echo   Google Antigravity (AGY) - Portable Terminal Shell
echo   Root: %PORTABLE_ROOT%
echo =======================================================
echo.
echo Type 'agy' to start Antigravity CLI.
echo Type 'agy --help' for CLI options.
echo.
cmd.exe /k
