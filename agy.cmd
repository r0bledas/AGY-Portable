@echo off
setlocal
set "PORTABLE_ROOT=%~dp0"
if "%PORTABLE_ROOT:~-1%"=="\" set "PORTABLE_ROOT=%PORTABLE_ROOT:~0,-1%"

set "USERPROFILE=%PORTABLE_ROOT%\data\home"
set "HOME=%PORTABLE_ROOT%\data\home"
set "HOMEDRIVE=%PORTABLE_ROOT:~0,2%"
set "HOMEPATH=%PORTABLE_ROOT:~2%\data\home"
set "APPDATA=%PORTABLE_ROOT%\data\AppData\Roaming"
set "LOCALAPPDATA=%PORTABLE_ROOT%\data\AppData\Local"
set "PATH=%PORTABLE_ROOT%\bin;%PATH%"

if not exist "%PORTABLE_ROOT%\bin\agy.exe" (
    echo [ERROR] agy.exe not found at "%PORTABLE_ROOT%\bin\agy.exe"
    exit /b 1
)

"%PORTABLE_ROOT%\bin\agy.exe" %*
exit /b %ERRORLEVEL%
