# AGY-Portable Release Packages

This directory contains standalone, ready-to-use distribution packages for AGY-Portable.

---

## Available Packages

* **AGY-Portable-v1.0.0-All-Platforms.zip**: Complete cross-platform USB package containing Windows, macOS, and Linux launchers with shared data routing.
* **AGY-Portable-v1.0.0-Windows.zip**: Standalone Windows package containing AGY-Launcher.exe, agy.cmd, and agy-shell.cmd.
* **AGY-Portable-v1.0.0-macOS.zip**: Standalone macOS package containing agy.command and File Not Opening.txt.
* **AGY-Portable-v1.0.0-Linux.zip**: Standalone Linux package containing agy.sh.

---

## Rebuilding Releases

To rebuild these zip packages at any time:
```powershell
powershell -ExecutionPolicy Bypass -File .\build-release.ps1
```

## Publishing to GitHub Releases

To automatically create a GitHub Release and upload these zip archives:
```powershell
powershell -ExecutionPolicy Bypass -File .\publish-github-release.ps1
```
