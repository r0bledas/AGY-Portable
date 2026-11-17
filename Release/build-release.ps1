# Build Release Packages for AGY-Portable (POSIX-preserving via git archive)
param(
    [string]$Version = "v1.6.0"
)

$ErrorActionPreference = "Stop"
$root = (Get-Item $PSScriptRoot).Parent.FullName
$releaseDir = $PSScriptRoot

Push-Location $root
try {
    Write-Host "Ensuring executable mode bits (100755) in git index..." -ForegroundColor Cyan
    git update-index --chmod=+x `
        macOS/agy.command `
        macOS/agy-danger.command `
        Linux/agy.sh `
        Linux/agy-danger.sh `
        Windows/agy.cmd `
        Windows/agy-danger.cmd

    # Verify index modes before archiving
    $modes = git ls-files -s macOS/agy.command macOS/agy-danger.command Linux/agy.sh Linux/agy-danger.sh
    foreach ($line in $modes) {
        if ($line -notmatch "^100755\s") {
            throw "Executable bit (100755) missing in git index for: $line. Commit index mode changes before building release."
        }
    }

    $zipPath = Join-Path $releaseDir "AGY-Portable-$Version-All-Platforms.zip"
    $tarPath = Join-Path $releaseDir "AGY-Portable-$Version-All-Platforms.tar.gz"

    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    if (Test-Path $tarPath) { Remove-Item $tarPath -Force }

    Write-Host "Building $zipPath via git archive (preserves 0755 Unix modes and '/' paths)..." -ForegroundColor Cyan
    git archive --format=zip -o $zipPath HEAD
    Write-Host "[Created] $zipPath" -ForegroundColor Green

    Write-Host "Building $tarPath via git archive..." -ForegroundColor Cyan
    git archive --format=tar.gz -o $tarPath HEAD
    Write-Host "[Created] $tarPath" -ForegroundColor Green

    Write-Host "Release packages generated successfully in: $releaseDir" -ForegroundColor Cyan
} finally {
    Pop-Location
}
