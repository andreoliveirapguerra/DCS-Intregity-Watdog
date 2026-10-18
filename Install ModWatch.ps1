# Install the ModWatch client reporter into your DCS profile(s).
# No admin needed -- it only writes into your own Saved Games DCS folder.
#
#   Right-click -> Run with PowerShell,  or:  powershell -File "Install ModWatch.ps1"

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$hook = Join-Path $here "Scripts\Hooks\modreport_hook.lua"

if (-not (Test-Path $hook)) {
    Write-Host "Cannot find Scripts\Hooks\modreport_hook.lua next to this script." -ForegroundColor Red
    Read-Host "Press Enter to close"; exit 1
}

$sg = Join-Path $env:USERPROFILE "Saved Games"
$profiles = @(Get-ChildItem $sg -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "DCS*" -and (Test-Path (Join-Path $_.FullName "Config")) })

if ($profiles.Count -eq 0) {
    Write-Host "No DCS profile found under $sg." -ForegroundColor Yellow
    Write-Host "Copy Scripts\Hooks\modreport_hook.lua into <your DCS>\Scripts\Hooks\ by hand."
    Read-Host "Press Enter to close"; exit 1
}

Write-Host "`nModWatch client -- installing into:`n"
foreach ($p in $profiles) {
    $dest = Join-Path $p.FullName "Scripts\Hooks"
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item $hook (Join-Path $dest "modreport_hook.lua") -Force
    Write-Host ("  [installed]  {0}" -f (Join-Path $dest "modreport_hook.lua")) -ForegroundColor Green
}
Write-Host @"

Done. The reporter loads next time you start DCS, and tells each multiplayer
server you join which mods you run. It reads only your DCS folders and sends
only a short mod summary over the game's own chat channel.

Uninstall any time with "Uninstall ModWatch.ps1" (or just delete the file).
"@
Read-Host "Press Enter to close"
