# Build Release Packages for AGY-Portable
$ErrorActionPreference = "Stop"
$root = (Get-Item $PSScriptRoot).Parent.FullName
$releaseDir = $PSScriptRoot
$version = "v1.6.0"

Write-Host "Building AGY-Portable $version Release Package (All-Platforms)..." -ForegroundColor Cyan

# 1. Multiplatform Package (Windows + macOS + Linux)
$multiDir = Join-Path $env:TEMP "AGY-Portable-Multiplatform"
if (Test-Path $multiDir) { Remove-Item $multiDir -Recurse -Force }
New-Item -ItemType Directory -Path $multiDir -Force | Out-Null

Copy-Item -Path (Join-Path $root "Windows") -Destination (Join-Path $multiDir "Windows") -Recurse -Exclude "*.exe.old"
# Exclude the 193MB binary from the zip so it can be hosted on GitHub / shared easily
if (Test-Path (Join-Path $multiDir "Windows\bin\agy.exe")) {
    Remove-Item (Join-Path $multiDir "Windows\bin\agy.exe") -Force
}
New-Item -ItemType File -Path (Join-Path $multiDir "Windows\bin\.gitkeep") -Force | Out-Null

Copy-Item -Path (Join-Path $root "macOS") -Destination (Join-Path $multiDir "macOS") -Recurse
if (Test-Path (Join-Path $multiDir "macOS\bin\agy")) {
    Remove-Item (Join-Path $multiDir "macOS\bin\agy") -Force
}
New-Item -ItemType File -Path (Join-Path $multiDir "macOS\bin\.gitkeep") -Force | Out-Null

Copy-Item -Path (Join-Path $root "Linux") -Destination (Join-Path $multiDir "Linux") -Recurse
if (Test-Path (Join-Path $multiDir "Linux\bin\agy")) {
    Remove-Item (Join-Path $multiDir "Linux\bin\agy") -Force
}
New-Item -ItemType File -Path (Join-Path $multiDir "Linux\bin\.gitkeep") -Force | Out-Null

Copy-Item -Path (Join-Path $root "README.md") -Destination (Join-Path $multiDir "README.md") -Force

$multiZip = Join-Path $releaseDir "AGY-Portable-$version-All-Platforms.zip"
if (Test-Path $multiZip) { Remove-Item $multiZip -Force }
Compress-Archive -Path "$multiDir\*" -DestinationPath $multiZip -CompressionLevel Optimal
Remove-Item $multiDir -Recurse -Force
Write-Host "[Created] $multiZip" -ForegroundColor Green

Write-Host "Unified All-Platforms release package generated successfully in: $releaseDir" -ForegroundColor Cyan
