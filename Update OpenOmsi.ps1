<#
OpenOmsi-RP updater: brings this openOMSI folder up to the newest OpenOmsi-RP release
(openOMSI with the ReShade fix and the Realistic Passengers changes), from
https://github.com/theprime01/OpenOmsi-RP/releases.

Double-click "Update OpenOmsi.cmd" beside it, or choose "Update now" in the launcher, which
starts this script and closes itself.

What it does:
 1. Waits for openOMSI and its launchers (from this folder) to close.
 2. Asks GitHub for the newest OpenOmsi-RP release and compares it with this folder's
    openomsi.exe.
 3. Downloads the release zip (the game with the Realistic Passengers pack) and checks it
    against the SHA-256 GitHub lists.
 4. Sets the files it replaces aside in ".update-backup\<old version>", then unpacks the zip
    over this folder. Your ReShade (dxgi.dll, ReShade.ini, presets, shaders), mods and
    settings are not in the zip, so they stay as they are.

Options:
  -Force          reinstall the newest release even when this folder already has it
  -FromLauncher   started by the launcher: waits for it to close, and starts it again after
#>
param(
    [switch]$Force,
    [switch]$FromLauncher
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is many times slower with its bar
$Repo = 'theprime01/OpenOmsi-RP'
$Game = $PSScriptRoot
$Log = Join-Path $Game 'Update OpenOmsi.log'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Done($code) {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host ''
    Read-Host 'Press Enter to close'
    exit $code
}
function Fail($msg) {
    Write-Host ''
    Write-Host "FAILED: $msg" -ForegroundColor Red
    Write-Host "Nothing in the game folder was changed unless it says so above. Log: $Log"
    Done 1
}
# 0.2.37-rp -> 0.2.37 as numbers
function Parts($v) { @(($v -replace '^[vV]', '' -replace '-.*$', '').Split('.') | ForEach-Object { [int]$_ }) }
function Newer($a, $b) {
    $x = Parts $a; $y = Parts $b
    for ($i = 0; $i -lt [Math]::Max($x.Count, $y.Count); $i++) {
        $p = if ($i -lt $x.Count) { $x[$i] } else { 0 }
        $q = if ($i -lt $y.Count) { $y[$i] } else { 0 }
        if ($p -ne $q) { return $p -gt $q }
    }
    $false
}
# openOMSI's processes started from this folder
function Running {
    @(Get-Process openomsi, openomsi-launcher, openomsi-launcher-app -ErrorAction SilentlyContinue |
        Where-Object { try { $_.Path -and (Split-Path $_.Path -Parent) -eq $Game } catch { $false } })
}

try { Start-Transcript -Path $Log | Out-Null } catch {}
Write-Host 'OpenOmsi-RP updater' -ForegroundColor Cyan
Write-Host "game folder: $Game"
Write-Host ''

$exe = Join-Path $Game 'openomsi.exe'
if (-not (Test-Path $exe)) { Fail "openomsi.exe is not here - put this script in your openOMSI folder" }

# 1. openOMSI closed
if (Running) {
    if ($FromLauncher) { Write-Host 'waiting for the launcher to close...' }
    else { Write-Host 'Close openOMSI and its launcher - waiting for them...' -ForegroundColor Yellow }
    $until = (Get-Date).AddMinutes(5)
    while ((Running) -and (Get-Date) -lt $until) { Start-Sleep -Milliseconds 500 }
    if (Running) { Fail 'openOMSI is still running - close it and run the updater again' }
}

# 2. what is here, what is out
$current = (Get-Item $exe).VersionInfo.ProductVersion
if (-not $current) { $current = '0' }
Write-Host "this folder: $current"
Write-Host 'asking GitHub for the newest release...'
$rel = $null
try {
    $rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = 'OpenOmsi-RP-updater' } -TimeoutSec 30
} catch {
    Fail "could not ask GitHub ($($_.Exception.Message)) - check the internet connection, or download the zip yourself from https://github.com/$Repo/releases"
}
$latest = $rel.tag_name -replace '^[vV]', ''
Write-Host "newest release: $latest"
if (-not (Newer $latest $current) -and -not $Force) {
    Write-Host ''
    Write-Host 'This folder already has the newest OpenOmsi-RP.' -ForegroundColor Green
    if ($FromLauncher) { Start-Process $exe -WorkingDirectory $Game }
    Done 0
}

# 3. the zip
$base = $latest -replace '-rp$', ''
$want = "openOMSI-$base-windows-x64-RP-full.zip"
$asset = $rel.assets | Where-Object { $_.name -eq $want } | Select-Object -First 1
if (-not $asset) { Fail "the release $latest has no $want (yet) - try again in a few minutes" }

$work = Join-Path $env:TEMP "openomsi-rp-update-$base"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "$work\files" | Out-Null
$zip = Join-Path $work $want
Write-Host ("downloading {0} ({1:N0} MB)..." -f $want, ($asset.size / 1MB))
# curl.exe (in Windows 10 and 11) resumes and is fast; Invoke-WebRequest when it is missing
$curl = "$env:SystemRoot\System32\curl.exe"
if (Test-Path $curl) {
    & $curl -L --fail -sS --retry 3 -o $zip $asset.browser_download_url
    if ($LASTEXITCODE -ne 0) { Fail "the download broke off (curl $LASTEXITCODE)" }
} else {
    try { Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing } catch { Fail "the download failed: $($_.Exception.Message)" }
}
if ($asset.size -and (Get-Item $zip).Length -ne $asset.size) { Fail 'the download is not complete' }
if ($asset.digest -match '^sha256:([0-9a-fA-F]{64})$') {
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $Matches[1].ToUpper()) { Fail 'the download does not match its SHA-256 - try again' }
    Write-Host 'checked: SHA-256 matches' -ForegroundColor Green
}

# 4. unpack, set aside what gets replaced, put the new files in
Write-Host 'unpacking...'
& "$env:SystemRoot\System32\tar.exe" -xf $zip -C "$work\files"
if ($LASTEXITCODE -ne 0) { Fail 'the zip could not be unpacked' }
$backup = Join-Path $Game ".update-backup\$current"
$new = Get-ChildItem "$work\files" -Recurse -File
Write-Host "setting the old files aside in $backup..."
foreach ($f in $new) {
    $path = $f.FullName.Substring("$work\files".Length + 1)
    $old = Join-Path $Game $path
    # (the figures are only added to, and are many: they are not copied aside)
    if ((Test-Path $old) -and $path -notlike 'Humans\*') {
        $to = Join-Path $backup $path
        New-Item -ItemType Directory -Force (Split-Path $to -Parent) | Out-Null
        Copy-Item $old $to -Force
    }
}
Write-Host 'installing...'
try {
    foreach ($f in $new) {
        $path = $f.FullName.Substring("$work\files".Length + 1)
        $to = Join-Path $Game $path
        New-Item -ItemType Directory -Force (Split-Path $to -Parent) | Out-Null
        Copy-Item $f.FullName $to -Force
    }
} catch {
    Write-Host "installing failed: $($_.Exception.Message) - putting the old files back" -ForegroundColor Red
    if (Test-Path $backup) { Copy-Item "$backup\*" $Game -Recurse -Force }
    Fail 'the update could not be installed (the old files are back)'
}
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host "Done: OpenOmsi-RP $latest is installed." -ForegroundColor Green
Write-Host "(the old files are in $backup - delete that folder whenever you like)"
if (-not (Test-Path (Join-Path $Game 'dxgi.dll'))) {
    Write-Host ''
    Write-Host "ReShade is not in this folder yet: install it (reshade.me) for openomsi.exe with DirectX 10/11/12." -ForegroundColor Yellow
}
if ($FromLauncher) { Start-Process $exe -WorkingDirectory $Game }
Done 0
