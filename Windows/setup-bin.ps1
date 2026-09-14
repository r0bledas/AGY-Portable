# AGY Binary Setup Script (Windows)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$targetBin = Join-Path $root "bin\agy.exe"

if (Test-Path $targetBin) {
    Write-Host "[OK] agy.exe is already present in bin\agy.exe ($((Get-Item $targetBin).Length / 1MB | ForEach-Object { '{0:N1} MB' -f $_ }))" -ForegroundColor Green
    exit 0
}

$binDir = Join-Path $root "bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

# 1. Check local PC installation
$candidates = @(
    "$env:LOCALAPPDATA\agy\bin\agy.exe",
    (Get-Command agy -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
) | Where-Object { $_ -and (Test-Path $_) }

if ($candidates.Count -gt 0) {
    $src = $candidates[0]
    Write-Host "Found installed AGY binary on this PC at: $src" -ForegroundColor Cyan
    Write-Host "Copying to $targetBin..." -ForegroundColor Cyan
    Copy-Item -Path $src -Destination $targetBin -Force
    Write-Host "[OK] Copied agy.exe into bin\agy.exe!" -ForegroundColor Green
    exit 0
}

# 2. Download directly from Google
Write-Host "No local agy.exe found on this PC." -ForegroundColor Yellow
Write-Host "Fetching latest Windows release manifest from Google..." -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$manifestUrl = "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json"
$dlUrl = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/windows-x64/cli_windows_x64.exe"

try {
    $manifest = Invoke-RestMethod -Uri $manifestUrl -Headers @{"User-Agent"="agy-portable/1.0"}
    if ($manifest.url) { $dlUrl = $manifest.url }
    Write-Host "Found release v$($manifest.version)" -ForegroundColor Green
} catch {
    Write-Host "Using default release URL..." -ForegroundColor Gray
}

Write-Host "Downloading Antigravity CLI (~193 MB) from Google servers..." -ForegroundColor Cyan
Write-Host "URL: $dlUrl" -ForegroundColor Gray

$tempFile = "$targetBin.downloading"
Invoke-WebRequest -Uri $dlUrl -OutFile $tempFile -UseBasicParsing
Move-Item -Path $tempFile -Destination $targetBin -Force

Write-Host "[OK] Successfully downloaded and installed agy.exe into bin\agy.exe!" -ForegroundColor Green
