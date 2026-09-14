$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    Write-Error "csc.exe not found at $csc"
    exit 1
}

Write-Host "Compiling AGY-Launcher.exe with .NET Framework 4.8 csc.exe..." -ForegroundColor Cyan
& $csc /target:winexe /out:"$PSScriptRoot\AGY-Launcher.exe" /platform:anycpu /optimize+ /r:System.dll,System.Windows.Forms.dll,System.Drawing.dll,System.Core.dll "$PSScriptRoot\src\Program.cs"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful! Output: $PSScriptRoot\AGY-Launcher.exe" -ForegroundColor Green
} else {
    Write-Host "Build Failed." -ForegroundColor Red
}
