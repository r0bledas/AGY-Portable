# AGY Binary Setup Script
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$targetBin = Join-Path $root "bin\agy.exe"

if (Test-Path $targetBin) {
    Write-Host "[OK] agy.exe is already present in bin\agy.exe ($((Get-Item $targetBin).Length / 1MB | ForEach-Object { '{0:N1} MB' -f $_ }))" -ForegroundColor Green
    exit 0
}

# Ensure bin folder exists
$binDir = Join-Path $root "bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

# Look for host agy.exe
$candidates = @(
    "$env:LOCALAPPDATA\agy\bin\agy.exe",
    (Get-Command agy -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
) | Where-Object { $_ -and (Test-Path $_) }

if ($candidates.Count -gt 0) {
    $src = $candidates[0]
    Write-Host "Found installed AGY binary at: $src" -ForegroundColor Cyan
    Write-Host "Copying to $targetBin..." -ForegroundColor Cyan
    Copy-Item -Path $src -Destination $targetBin -Force
    Write-Host "[OK] Copied agy.exe into bin\agy.exe!" -ForegroundColor Green
} else {
    Write-Warning "Could not find an installed agy.exe on this system."
    Write-Host "Please copy your agy.exe into the 'bin\' folder to complete setup." -ForegroundColor Yellow
}
