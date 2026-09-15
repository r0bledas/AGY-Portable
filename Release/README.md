# AGY-Portable Release Packages

This directory contains standalone, ready-to-use distribution packages for AGY-Portable.

---

## Available Packages

* **AGY-Portable-v1.6.0-All-Platforms.zip**: Complete unified cross-platform USB package containing Windows, macOS, and Linux launchers with shared data routing.

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
