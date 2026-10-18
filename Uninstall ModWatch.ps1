# Remove the ModWatch client reporter from your DCS profile(s).

$ErrorActionPreference = "Stop"
$sg = Join-Path $env:USERPROFILE "Saved Games"
$profiles = @(Get-ChildItem $sg -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "DCS*" })

$removed = 0
foreach ($p in $profiles) {
    $f = Join-Path $p.FullName "Scripts\Hooks\modreport_hook.lua"
    if (Test-Path $f) {
        Remove-Item $f -Force
        Write-Host ("  [removed]  {0}" -f $f) -ForegroundColor Green
        $removed++
    }
}
if ($removed -eq 0) { Write-Host "Nothing to remove -- ModWatch was not installed." -ForegroundColor Yellow }
else { Write-Host "`nModWatch client removed." }
Read-Host "Press Enter to close"
