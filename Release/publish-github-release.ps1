# Publish GitHub Release Script
param(
    [string]$Tag = "v1.4.0",
    [string]$Title = "AGY-Portable v1.4.0 - Auto-Updater & Streamlined Release",
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

Write-Host "Creating GitHub Release $Tag on $repo..." -ForegroundColor Cyan

$releaseBody = @"
## Google Antigravity (AGY) - Portable Edition $Tag

A fully self-contained, USB-portable distribution of the Google Antigravity CLI (agy) for Windows, macOS, and Linux.

### Release Assets Included
- **AGY-Portable-$Tag-All-Platforms.zip**: Multi-platform USB distribution for Windows, macOS, and Linux.
- **AGY-Portable-$Tag-Windows.zip**: Standalone Windows release (All-in-one agy.cmd and agy-danger.cmd runners).
- **AGY-Portable-$Tag-macOS.zip**: Standalone macOS release (All-in-one agy.command launcher).
- **AGY-Portable-$Tag-Linux.zip**: Standalone Linux release (All-in-one agy.sh launcher).

### Highlights
- Single USB drive shares credentials and conversation history across Windows, macOS, and Linux.
- Interactive terminal menu, Google binary downloader, and 1-click credential sync across Windows, macOS, and Linux.
- Windows includes both standard user (agy.cmd) and auto-approved permissions (agy-danger.cmd) runners.
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
    Write-Host "Checking if release already exists..." -ForegroundColor Yellow
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/tags/$Tag" -Headers $headers
    Write-Host "[Found] Existing Release: $($release.html_url)" -ForegroundColor Green
    $uploadUrlBase = $release.upload_url -replace '\{\?name,label\}', ''
}

# Upload all zip files in Release folder for current version tag
$zipFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*$Tag*.zip"
foreach ($z in $zipFiles) {
    # Check if asset already exists in release and delete to overwrite
    $existingAsset = $release.assets | Where-Object { $_.name -eq $z.Name }
    if ($existingAsset) {
        Write-Host "Replacing existing asset: $($existingAsset.name)..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri $existingAsset.url -Method Delete -Headers $headers | Out-Null
    }

    Write-Host "Uploading asset: $($z.Name) ($($z.Length / 1KB | ForEach-Object { '{0:N1} KB' -f $_ }))..." -ForegroundColor Cyan
    $uploadUri = "$uploadUrlBase`?name=$($z.Name)"
    $bytes = [System.IO.File]::ReadAllBytes($z.FullName)
    
    $uploadHeaders = @{
        "Authorization" = "token $token"
        "User-Agent" = "PowerShell-Release-Publisher"
        "Content-Type" = "application/zip"
    }

    try {
        $res = Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $uploadHeaders -Body $bytes
        Write-Host "[Uploaded] $($z.Name)" -ForegroundColor Green
    } catch {
        Write-Host "[Skip/Error] $($z.Name): $_" -ForegroundColor Yellow
    }
}

Write-Host "Release publication complete! URL: $($release.html_url)" -ForegroundColor Green
