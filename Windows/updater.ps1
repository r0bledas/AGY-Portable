param(
    [string]$Repo = "r0bledas/AGY-Portable",
    [string]$CurrentVersion = "v1.5.0",
    [string]$WinDir = $PSScriptRoot,
    [string]$BinDir = (Join-Path $PSScriptRoot "bin"),
    [string]$TargetExe = (Join-Path $PSScriptRoot "bin\agy.exe")
)

$ErrorActionPreference = "Stop"
$apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
$manifestUrl = "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json"

Write-Host "------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[Track 1] Launcher Scripts & Tools (GitHub)" -ForegroundColor Cyan

try {
    $release = Invoke-RestMethod -Uri $apiUrl -UserAgent "AGY-Portable" -UseBasicParsing
    $latestTag = $release.tag_name
    Write-Host ("  Current Launcher : " + $CurrentVersion)
    Write-Host ("  Latest on GitHub : " + $latestTag)

    $curClean = $CurrentVersion.TrimStart('v','V')
    $latestClean = $latestTag.TrimStart('v','V')
    $curParsed = [System.Version]::Parse($curClean)
    $latestParsed = [System.Version]::Parse($latestClean)

    $doScriptUpdate = $false
    if ($latestParsed -le $curParsed) {
        Write-Host "  Status: Launcher is up to date." -ForegroundColor Green
        $reinstall = Read-Host "  Re-download / repair latest launcher scripts anyway? [y/N]"
        if ($reinstall -eq "y" -or $reinstall -eq "Y") {
            $doScriptUpdate = $true
        }
    } else {
        Write-Host ("  [Update Available] A new launcher version (" + $latestTag + ") is ready!") -ForegroundColor Yellow
        $confirm = Read-Host "  Update launcher scripts now? [Y/n]"
        if ($confirm -ne "n" -and $confirm -ne "N") {
            $doScriptUpdate = $true
        }
    }

    if ($doScriptUpdate) {
        $asset = $null
        foreach ($a in $release.assets) {
            if ($a.name -like "*Windows.zip") {
                $asset = $a
                break
            }
        }

        if (-not $asset) {
            Write-Host "  [Error] Could not find Windows package in release assets." -ForegroundColor Red
        } else {
            $tempZip = Join-Path $env:TEMP ("agy_update_" + $latestTag + ".zip")
            $tempExtract = Join-Path $env:TEMP ("agy_extract_" + [Guid]::NewGuid().ToString())
            Write-Host ("  Downloading " + $asset.name + "...") -ForegroundColor Cyan
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -UserAgent "AGY-Portable" -UseBasicParsing
            Write-Host "  Extracting package..." -ForegroundColor Cyan
            Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
            Remove-Item $tempZip -Force
            Write-Host "  Updating scripts (credentials and bin remain safe)..." -ForegroundColor Cyan
            foreach ($item in (Get-ChildItem -Path $tempExtract)) {
                if ($item.Name -ne "bin" -and $item.Name -ne "data") {
                    Copy-Item -Path $item.FullName -Destination $WinDir -Recurse -Force
                }
            }
            Remove-Item $tempExtract -Recurse -Force
            Write-Host ("  [Success] Launcher scripts updated to " + $latestTag + "!") -ForegroundColor Green
        }
    }
} catch {
    Write-Host ("  [Notice] Could not check GitHub releases: " + $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[Track 2] Core Antigravity Engine (Google agy.exe)" -ForegroundColor Cyan

try {
    $localCliVer = "Not installed"
    if (Test-Path $TargetExe) {
        try {
            $rawVer = & $TargetExe --version 2>$null
            if ($rawVer) { $localCliVer = $rawVer.Trim() }
        } catch {}
    }
    Write-Host ("  Current Core CLI: " + $localCliVer)

    $googleMeta = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
    $googleVer = $googleMeta.version
    $googleUrl = $googleMeta.url
    Write-Host ("  Latest from Google: " + $googleVer)

    $doCliUpdate = $false
    if ($localCliVer -eq $googleVer) {
        Write-Host "  Status: Core engine is up to date." -ForegroundColor Green
        $reDl = Read-Host "  Re-download / repair official agy.exe anyway? [y/N]"
        if ($reDl -eq "y" -or $reDl -eq "Y") {
            $doCliUpdate = $true
        }
    } else {
        Write-Host ("  [Update Available] A new core engine (" + $googleVer + ") is ready!") -ForegroundColor Yellow
        $confirmCli = Read-Host "  Update core CLI engine (agy.exe) from Google? [Y/n]"
        if ($confirmCli -ne "n" -and $confirmCli -ne "N") {
            $doCliUpdate = $true
        }
    }

    if ($doCliUpdate) {
        if (-not (Test-Path $BinDir)) {
            [void](New-Item -ItemType Directory -Path $BinDir -Force)
        }

        if ($googleUrl.EndsWith(".exe")) {
            $tmpExe = Join-Path $BinDir "agy_new.exe"
            Write-Host ("  Downloading agy.exe v" + $googleVer + " (~190 MB)...") -ForegroundColor Cyan
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($googleUrl, $tmpExe)
            Move-Item -Path $tmpExe -Destination $TargetExe -Force
        } else {
            $zipPath = Join-Path $BinDir "agy_win.zip"
            Write-Host ("  Downloading archive v" + $googleVer + "...") -ForegroundColor Cyan
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($googleUrl, $zipPath)
            Write-Host "  Extracting archive..." -ForegroundColor Cyan
            Expand-Archive -Path $zipPath -DestinationPath $BinDir -Force
            Remove-Item $zipPath -Force
            if (Test-Path (Join-Path $BinDir "antigravity.exe")) {
                Move-Item -Path (Join-Path $BinDir "antigravity.exe") -Destination $TargetExe -Force
            }
        }
        Unblock-File -Path (Join-Path $BinDir "*") -ErrorAction SilentlyContinue
        Write-Host ("  [Success] Core engine updated to " + $googleVer + "!") -ForegroundColor Green
    }
} catch {
    Write-Host ("  [Notice] Could not check Google binary updates: " + $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "======================================================" -ForegroundColor DarkGray
Write-Host "Update check complete. All credentials and data remain safe." -ForegroundColor Green
