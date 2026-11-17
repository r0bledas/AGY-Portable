# Publish GitHub Release Script
param(
    [string]$Tag = "v1.6.0",
    [string]$Title = "AGY Portable v1.6.0",
    [string]$KeyFile = "$env:USERPROFILE\Downloads\github-keys.txt"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $KeyFile)) {
    Write-Error "GitHub token file not found at: $KeyFile"
    exit 1
}

$token = (Get-Content -Path $KeyFile -Raw).Trim()
$repo = "r0bledas/AGY-Portable"

$headers = @{
    "Authorization" = "token $token"
    "User-Agent" = "PowerShell-Release-Publisher"
    "Accept" = "application/vnd.github.v3+json"
}

Write-Host "Publishing GitHub Release $Tag on $repo..." -ForegroundColor Cyan

$releaseBody = @"
# Unified All-Platforms Release

A fully self-contained, USB-portable distribution of the Google Antigravity CLI (`agy`) for Windows, macOS, and Linux in a single unified package.

### Release Packages Included
- **AGY-Portable-$Tag-All-Platforms.zip**: Complete cross-platform USB distribution with preserved `0755` Unix permissions (`create_system=3`) and `/` path separators.
- **AGY-Portable-$Tag-All-Platforms.tar.gz**: Tarball archive for macOS/Linux (`tar -xzf` preserves executable bits and avoids browser quarantine when fetched via `curl`/`gh`).

### macOS & Linux Quick Start
```bash
# Zero-permission instant launch (works even on 0644 or noexec USB drives):
bash macOS/agy.command /download
bash macOS/agy.command

# Or clear browser Gatekeeper quarantine + restore exec bits for Finder double-click:
xattr -cr . && chmod +x macOS/*.command Linux/*.sh
```

### Highlights
- Single unified release archive: all platforms (Windows, macOS, Linux) are bundled into one package.
- Single USB drive shares credentials and conversation history across Windows, macOS, and Linux.
- Dual-track optional updater: updates launcher scripts from GitHub and core CLI engine from Google independently.
- Dual-runner architecture across all OSes (`agy` standard mode and `agy-danger` auto-approve mode).
- Zero host system pollution; zero-trace temporary runner cleans up on exit.
"@

$postData = @{
    tag_name = $Tag
    target_commitish = "main"
    name = $Title
    body = $releaseBody
    draft = $false
    prerelease = $false
} | ConvertTo-Json

try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Method Post -Headers $headers -Body $postData
    Write-Host "[OK] Created Release: $($release.html_url)" -ForegroundColor Green
    $uploadUrlBase = $release.upload_url -replace '\{\?name,label\}', ''
} catch {
    Write-Host "Updating existing release $Tag..." -ForegroundColor Yellow
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/tags/$Tag" -Headers $headers
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/$($release.id)" -Method Patch -Headers $headers -Body $postData
    Write-Host "[Updated] Existing Release: $($release.html_url)" -ForegroundColor Green
    $uploadUrlBase = $release.upload_url -replace '\{\?name,label\}', ''
}

$assetsToUpload = Get-ChildItem -Path $PSScriptRoot | Where-Object {
    $_.Name -like "*$Tag*.zip" -or $_.Name -like "*$Tag*.tar.gz"
}

foreach ($a in $assetsToUpload) {
    $existingAsset = $release.assets | Where-Object { $_.name -eq $a.Name }
    if ($existingAsset) {
        Write-Host "Replacing existing asset: $($existingAsset.name)..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri $existingAsset.url -Method Delete -Headers $headers | Out-Null
    }

    Write-Host "Uploading asset: $($a.Name)..." -ForegroundColor Cyan
    $uploadUri = "$uploadUrlBase`?name=$($a.Name)"
    $bytes = [System.IO.File]::ReadAllBytes($a.FullName)
    $contentType = if ($a.Name.EndsWith(".tar.gz")) { "application/gzip" } else { "application/zip" }

    $uploadHeaders = @{
        "Authorization" = "token $token"
        "User-Agent" = "PowerShell-Release-Publisher"
        "Content-Type" = $contentType
    }

    $res = Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $uploadHeaders -Body $bytes
    Write-Host "[Uploaded] $($a.Name)" -ForegroundColor Green
}

Write-Host "Release publication complete! URL: $($release.html_url)" -ForegroundColor Green
