<#
.SYNOPSIS
  AGY-Portable multi-account manager (Windows).

  The Antigravity CLI stores its live login in the Windows Credential Manager
  under the generic credential target "gemini:antigravity" (a plain UTF-8 JSON
  blob). Swapping the token file alone does nothing on Windows, so this script
  snapshots/restores the real credential:

    data\accounts\<name>\credential.json   vault blob (source of truth on Windows)
    data\accounts\<name>\token             portable token file (macOS/Linux fallback)
    data\accounts\.active                  profile currently loaded

  Commands: list | save <name> | use <name> | current | refresh | remove <name> | rename <old> <new>
  Options:  -DataRoot <path> (override the auto-detected data\ folder)
            -Json             (machine-readable output on stdout, JSON only)
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(Position = 1)][string]$Name,
    [Parameter(Position = 2)][string]$NewName,
    [string]$DataRoot,
    [switch]$Json
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Fail([string]$Msg) {
    if ($Json) { [Console]::Error.WriteLine($Msg) } else { Write-Host $Msg }
    exit 1
}
function Out([string]$Msg) {
    if (-not $Json) { Write-Host $Msg }
}
function OutJson($Obj) {
    if ($Json) {
        [Console]::Out.WriteLine(($Obj | ConvertTo-Json -Depth 6 -Compress))
    }
}

# ---------------------------------------------------------------- paths
$WinDir = $PSScriptRoot
if (-not $DataRoot) {
    if (Test-Path -LiteralPath (Join-Path $WinDir '..\data')) {
        $DataRoot = [IO.Path]::GetFullPath((Join-Path $WinDir '..\data'))
    } elseif (Test-Path -LiteralPath (Join-Path $WinDir '..\README.md')) {
        $DataRoot = [IO.Path]::GetFullPath((Join-Path $WinDir '..\data'))
    } else {
        $DataRoot = Join-Path $WinDir 'data'
    }
}
$AccountsDir = Join-Path $DataRoot 'accounts'
$ActiveFile  = Join-Path $AccountsDir '.active'
$GeminiDir   = Join-Path $DataRoot 'home\.gemini'
$CliDir      = Join-Path $GeminiDir 'antigravity-cli'
$LiveToken   = Join-Path $CliDir 'antigravity-oauth-token'
$LegacyToken = Join-Path $GeminiDir 'jetski-standalone-oauth-token'
if (-not (Test-Path -LiteralPath $LiveToken) -and (Test-Path -LiteralPath $LegacyToken)) {
    New-Item -ItemType Directory -Force -Path $CliDir | Out-Null
    Copy-Item -LiteralPath $LegacyToken -Destination $LiveToken -Force
}

# ---------------------------------------------------------------- native credential access
if (-not ('AGY.NativeCred' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

namespace AGY {
    public static class NativeCred {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct CREDENTIAL {
            public uint Flags;
            public uint Type;
            public IntPtr TargetName;
            public IntPtr Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public uint CredentialBlobSize;
            public IntPtr CredentialBlob;
            public uint Persist;
            public uint AttributeCount;
            public IntPtr Attributes;
            public IntPtr TargetAlias;
            public IntPtr UserName;
        }

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredRead(string target, uint type, uint flags, out IntPtr credential);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredWrite(ref CREDENTIAL credential, uint flags);

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern void CredFree(IntPtr buffer);

        public const string Target = "gemini:antigravity";
        public const string User = "antigravity";

        public static byte[] ReadBlob() {
            IntPtr p;
            if (!CredRead(Target, 1, 0, out p)) return null;
            CREDENTIAL c = (CREDENTIAL)Marshal.PtrToStructure(p, typeof(CREDENTIAL));
            byte[] data = new byte[c.CredentialBlobSize];
            if (c.CredentialBlobSize > 0) {
                Marshal.Copy(c.CredentialBlob, data, 0, (int)c.CredentialBlobSize);
            }
            CredFree(p);
            return data;
        }

        public static bool WriteBlob(byte[] data) {
            CREDENTIAL cred = new CREDENTIAL();
            cred.Type = 1;                                   // CRED_TYPE_GENERIC
            cred.TargetName = Marshal.StringToHGlobalUni(Target);
            cred.UserName = Marshal.StringToHGlobalUni(User);
            cred.CredentialBlobSize = (uint)data.Length;
            cred.CredentialBlob = Marshal.AllocHGlobal(data.Length);
            Marshal.Copy(data, 0, cred.CredentialBlob, data.Length);
            cred.Persist = 2;                                // CRED_PERSIST_LOCAL_MACHINE
            bool ok = CredWrite(ref cred, 0);
            Marshal.FreeHGlobal(cred.TargetName);
            Marshal.FreeHGlobal(cred.UserName);
            Marshal.FreeHGlobal(cred.CredentialBlob);
            return ok;
        }
    }
}
'@
}

# ---------------------------------------------------------------- helpers
function Get-VaultBlob {
    try { return [AGY.NativeCred]::ReadBlob() } catch { return $null }
}

function Set-VaultBlob([byte[]]$Blob) {
    if (-not [AGY.NativeCred]::WriteBlob($Blob)) {
        $err = [ComponentModel.Win32Exception]::new([Runtime.InteropServices.Marshal]::GetLastWin32Error()).Message
        Fail "CredWrite failed: $err"
    }
}

function Get-BlobEmail([byte[]]$Blob) {
    try {
        $txt = [Text.Encoding]::UTF8.GetString($Blob)
        $obj = $txt | ConvertFrom-Json
        return [string]$obj.id_token_email
    } catch { return '' }
}

function Get-ActiveName {
    if (Test-Path -LiteralPath $ActiveFile) {
        $n = ([IO.File]::ReadAllText($ActiveFile)).Trim()
        if ($n -match '^[-A-Za-z0-9_]{1,64}$') { return $n }
    }
    return ''
}

function Set-ActiveName([string]$N) {
    if (-not (Test-Path -LiteralPath $AccountsDir)) {
        [void](New-Item -ItemType Directory -Path $AccountsDir -Force)
    }
    if ($N) {
        [IO.File]::WriteAllText($ActiveFile, "$N`r`n", (New-Object Text.UTF8Encoding($false)))
    } elseif (Test-Path -LiteralPath $ActiveFile) {
        Remove-Item -LiteralPath $ActiveFile -Force
    }
}

function Test-Name([string]$N) {
    return ($N -and $N -match '^[-A-Za-z0-9_]{1,64}$')
}

function Write-TokenFile([byte[]]$Blob, [string]$Dest) {
    # Rebuild the portable token file (subset the CLI itself writes next to the vault):
    # { token: {access_token, token_type, refresh_token, expiry}, auth_method }
    $obj = ([Text.Encoding]::UTF8.GetString($Blob)) | ConvertFrom-Json
    $t = $obj.token
    $file = [ordered]@{
        token = [ordered]@{
            access_token  = $t.access_token
            token_type    = $t.token_type
            refresh_token = $t.refresh_token
            expiry        = $t.expiry
        }
        auth_method = $obj.auth_method
    }
    if (-not (Test-Path -LiteralPath $GeminiDir)) {
        [void](New-Item -ItemType Directory -Path $GeminiDir -Force)
    }
    $json = (($file | ConvertTo-Json -Depth 5) -replace "`r`n", "`n") + "`n"
    [IO.File]::WriteAllText($Dest, $json, (New-Object Text.UTF8Encoding($false)))
}

function Get-ProfileEntry([string]$Dir) {
    $credFile = Join-Path $Dir 'credential.json'
    $tokFile  = Join-Path $Dir 'token'
    $email = ''
    if (Test-Path -LiteralPath $credFile) {
        $email = Get-BlobEmail ([IO.File]::ReadAllBytes($credFile))
    }
    return [pscustomobject]@{
        name           = (Split-Path $Dir -Leaf)
        email          = $email
        has_credential = (Test-Path -LiteralPath $credFile)
        has_token      = (Test-Path -LiteralPath $tokFile)
    }
}

$validCommands = @('list', 'save', 'use', 'current', 'refresh', 'remove', 'rename')

if ($Command -notin $validCommands) {
    Fail "Usage: accounts.ps1 [list|save <name>|use <name>|current|refresh|remove <name>|rename <old> <new>] [-Json]"
}

# ---------------------------------------------------------------- list
if ($Command -eq 'list') {
    $vaultBlob = Get-VaultBlob
    $curEmail = if ($vaultBlob) { Get-BlobEmail $vaultBlob } else { '' }
    $active = Get-ActiveName
    $entries = @()
    if (Test-Path -LiteralPath $AccountsDir) {
        foreach ($dir in Get-ChildItem -LiteralPath $AccountsDir -Directory | Sort-Object Name) {
            $e = Get-ProfileEntry $dir.FullName
            $entries += [pscustomobject]@{
                name           = $e.name
                email          = $e.email
                active         = ($active -eq $e.name)
                current        = ($e.email -and $e.email -eq $curEmail)
                has_credential = $e.has_credential
                has_token      = $e.has_token
            }
        }
    }
    $signedIn = [bool]$vaultBlob
    if ($Json) {
        OutJson @{ signed_in = $signedIn; current_email = $curEmail; active = $active; profiles = $entries }
    } else {
        Out '======================================================'
        Out '                 Saved AGY Accounts'
        Out '======================================================'
        if (-not $signedIn) { Out '  (not signed in on this machine)' }
        if (-not $entries) { Out '  [no saved accounts - use: accounts.ps1 save NAME]' }
        foreach ($e in $entries) {
            $mark = ''
            if ($e.current) { $mark = '[in vault]' }
            if ($e.active)  { $mark = '[active]' }
            $mail = if ($e.email) { " <$($e.email)>" } else { '' }
            Out ("  " + $(if ($e.active) { '* ' } else { '  ' }) + $e.name + $mail + $(if ($mark) { " $mark" } else { '' }))
        }
        Out '------------------------------------------------------'
    }
    exit 0
}

# ---------------------------------------------------------------- current
if ($Command -eq 'current') {
    $vaultBlob = Get-VaultBlob
    if (-not $vaultBlob) {
        if ($Json) { OutJson @{ signed_in = $false; email = ''; profile = '' } }
        else { Out 'Not signed in on this machine.' }
        exit 0
    }
    $email = Get-BlobEmail $vaultBlob
    $profile = ''
    if (Test-Path -LiteralPath $AccountsDir) {
        foreach ($dir in Get-ChildItem -LiteralPath $AccountsDir -Directory) {
            $e = Get-ProfileEntry $dir.FullName
            if ($e.email -and $e.email -eq $email) { $profile = $e.name; break }
        }
    }
    if ($Json) { OutJson @{ signed_in = $true; email = $email; profile = $profile } }
    else { Out ($email + $(if ($profile) { " [$profile]" } else { '' })) }
    exit 0
}

# ---------------------------------------------------------------- save
if ($Command -eq 'save') {
    if (-not (Test-Name $Name)) { Fail "Invalid account name '$Name'. Use letters, digits, - or _." }
    $vaultBlob = Get-VaultBlob
    if (-not $vaultBlob) { Fail 'Not signed in on this machine. Sign in with agy /login first, then save.' }
    $profDir = Join-Path $AccountsDir $Name
    if (-not (Test-Path -LiteralPath $profDir)) { [void](New-Item -ItemType Directory -Path $profDir -Force) }
    $email = Get-BlobEmail $vaultBlob
    [IO.File]::WriteAllBytes((Join-Path $profDir 'credential.json'), $vaultBlob)
    Write-TokenFile $vaultBlob (Join-Path $profDir 'token')
    Set-ActiveName $Name
    $dup = ''
    if (Test-Path -LiteralPath $AccountsDir) {
        foreach ($dir in Get-ChildItem -LiteralPath $AccountsDir -Directory | Where-Object { $_.Name -ne $Name }) {
            $e = Get-ProfileEntry $dir.FullName
            if ($e.email -and $e.email -eq $email) { $dup = $e.name; break }
        }
    }
    if ($Json) { OutJson @{ name = $Name; email = $email; duplicate_with = $dup } }
    else {
        Out "[Success] Account '$Name' saved as $email and set active."
        if ($dup) { Out "Note: profile '$dup' holds the same account." }
    }
    exit 0
}

# ---------------------------------------------------------------- use
if ($Command -eq 'use') {
    if (-not (Test-Name $Name)) { Fail "Invalid account name '$Name'." }
    $credFile = Join-Path $AccountsDir ($Name + '\credential.json')
    if (-not (Test-Path -LiteralPath $credFile)) {
        Fail "No saved account named '$Name'. Run accounts.ps1 list."
    }
    $blob = [IO.File]::ReadAllBytes($credFile)
    Set-VaultBlob $blob
    if (Test-Path -LiteralPath (Join-Path $AccountsDir ($Name + '\token'))) {
        Copy-Item -LiteralPath (Join-Path $AccountsDir ($Name + '\token')) -Destination $LiveToken -Force
    }
    Set-ActiveName $Name
    $email = Get-BlobEmail $blob
    if ($Json) { OutJson @{ name = $Name; email = $email } }
    else { Out "[Success] Active account: $Name ($email)" }
    exit 0
}

# ---------------------------------------------------------------- refresh
if ($Command -eq 'refresh') {
    $profile = $Name
    if (-not $profile) { $profile = Get-ActiveName }
    if (-not $profile) {
        if ($Json) { OutJson @{ refreshed = $false; reason = 'no active profile' } }
        else { Out 'No active profile to refresh.' }
        exit 0
    }
    $profDir = Join-Path $AccountsDir $profile
    $credFile = Join-Path $profDir 'credential.json'
    if (-not (Test-Path -LiteralPath $credFile)) {
        if ($Json) { OutJson @{ refreshed = $false; reason = 'profile has no credential.json' } }
        else { Out "Profile '$profile' has no credential.json." }
        exit 0
    }
    $vaultBlob = Get-VaultBlob
    if (-not $vaultBlob) {
        if ($Json) { OutJson @{ refreshed = $false; reason = 'not signed in' } }
        else { Out 'Not signed in on this machine.' }
        exit 0
    }
    $storedEmail = Get-BlobEmail ([IO.File]::ReadAllBytes($credFile))
    $vaultEmail  = Get-BlobEmail $vaultBlob
    if ($storedEmail -and $vaultEmail -and $storedEmail -ne $vaultEmail) {
        if ($Json) { OutJson @{ refreshed = $false; reason = 'email mismatch' } }
        else { Out "Skipped: vault account ($vaultEmail) differs from profile '$profile' ($storedEmail)." }
        exit 0
    }
    [IO.File]::WriteAllBytes($credFile, $vaultBlob)
    Write-TokenFile $vaultBlob (Join-Path $profDir 'token')
    if ($Json) { OutJson @{ refreshed = $true; profile = $profile; email = $vaultEmail } }
    else { Out "[Success] Refreshed profile '$profile' ($vaultEmail)." }
    exit 0
}

# ---------------------------------------------------------------- remove
if ($Command -eq 'remove') {
    if (-not (Test-Name $Name)) { Fail "Invalid account name '$Name'." }
    $profDir = Join-Path $AccountsDir $Name
    if (-not (Test-Path -LiteralPath $profDir)) { Fail "No saved account named '$Name'." }
    $active = Get-ActiveName
    if ($active -eq $Name) { Fail "'$Name' is the active account. Switch to another account first." }
    Remove-Item -LiteralPath $profDir -Recurse -Force
    if ($Json) { OutJson @{ removed = $Name } }
    else { Out "[Success] Removed account '$Name'." }
    exit 0
}

# ---------------------------------------------------------------- rename
if ($Command -eq 'rename') {
    if (-not (Test-Name $Name) -or -not (Test-Name $NewName)) { Fail 'Invalid account name(s).' }
    $oldDir = Join-Path $AccountsDir $Name
    if (-not (Test-Path -LiteralPath $oldDir)) { Fail "No saved account named '$Name'." }
    if (Test-Path -LiteralPath (Join-Path $AccountsDir $NewName)) { Fail "An account named '$NewName' already exists." }
    Rename-Item -LiteralPath $oldDir -NewName $NewName
    if ((Get-ActiveName) -eq $Name) { Set-ActiveName $NewName }
    if ($Json) { OutJson @{ renamed = $Name; to = $NewName } }
    else { Out "[Success] Renamed '$Name' to '$NewName'." }
    exit 0
}
