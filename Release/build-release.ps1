# Build Release Packages for AGY-Portable
$ErrorActionPreference = "Stop"
$root = (Get-Item $PSScriptRoot).Parent.FullName
$releaseDir = $PSScriptRoot
$version = "v1.4.0"

Write-Host "Building AGY-Portable $version Release Packages..." -ForegroundColor Cyan

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

# 2. Windows Standalone Package
$winDir = Join-Path $env:TEMP "AGY-Portable-Windows"
if (Test-Path $winDir) { Remove-Item $winDir -Recurse -Force }
New-Item -ItemType Directory -Path $winDir -Force | Out-Null

Copy-Item -Path (Join-Path $root "Windows\*") -Destination $winDir -Recurse
if (Test-Path (Join-Path $winDir "bin\agy.exe")) {
    Remove-Item (Join-Path $winDir "bin\agy.exe") -Force
}
New-Item -ItemType File -Path (Join-Path $winDir "bin\.gitkeep") -Force | Out-Null
Copy-Item -Path (Join-Path $root "README.md") -Destination (Join-Path $winDir "README.md") -Force

$winZip = Join-Path $releaseDir "AGY-Portable-$version-Windows.zip"
if (Test-Path $winZip) { Remove-Item $winZip -Force }
Compress-Archive -Path "$winDir\*" -DestinationPath $winZip -CompressionLevel Optimal
Remove-Item $winDir -Recurse -Force
Write-Host "[Created] $winZip" -ForegroundColor Green

# 3. macOS Standalone Package
$macDir = Join-Path $env:TEMP "AGY-Portable-macOS"
if (Test-Path $macDir) { Remove-Item $macDir -Recurse -Force }
New-Item -ItemType Directory -Path $macDir -Force | Out-Null

Copy-Item -Path (Join-Path $root "macOS\*") -Destination $macDir -Recurse
if (Test-Path (Join-Path $macDir "bin\agy")) {
    Remove-Item (Join-Path $macDir "bin\agy") -Force
}
New-Item -ItemType File -Path (Join-Path $macDir "bin\.gitkeep") -Force | Out-Null
Copy-Item -Path (Join-Path $root "README.md") -Destination (Join-Path $macDir "README.md") -Force

$macZip = Join-Path $releaseDir "AGY-Portable-$version-macOS.zip"
if (Test-Path $macZip) { Remove-Item $macZip -Force }
Compress-Archive -Path "$macDir\*" -DestinationPath $macZip -CompressionLevel Optimal
Remove-Item $macDir -Recurse -Force
Write-Host "[Created] $macZip" -ForegroundColor Green

# 4. Linux Standalone Package
$linuxDir = Join-Path $env:TEMP "AGY-Portable-Linux"
if (Test-Path $linuxDir) { Remove-Item $linuxDir -Recurse -Force }
New-Item -ItemType Directory -Path $linuxDir -Force | Out-Null

Copy-Item -Path (Join-Path $root "Linux\*") -Destination $linuxDir -Recurse
if (Test-Path (Join-Path $linuxDir "bin\agy")) {
    Remove-Item (Join-Path $linuxDir "bin\agy") -Force
}
New-Item -ItemType File -Path (Join-Path $linuxDir "bin\.gitkeep") -Force | Out-Null
Copy-Item -Path (Join-Path $root "README.md") -Destination (Join-Path $linuxDir "README.md") -Force

$linuxZip = Join-Path $releaseDir "AGY-Portable-$version-Linux.zip"
if (Test-Path $linuxZip) { Remove-Item $linuxZip -Force }
Compress-Archive -Path "$linuxDir\*" -DestinationPath $linuxZip -CompressionLevel Optimal
Remove-Item $linuxDir -Recurse -Force
Write-Host "[Created] $linuxZip" -ForegroundColor Green

Write-Host "All Release packages generated successfully in: $releaseDir" -ForegroundColor Cyan
