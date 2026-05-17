#Requires -Version 5.1
<#
.SYNOPSIS
  Clone KethoDoc and install into WoW Interface\AddOns.
#>
param(
    [string]$WowPath,
    [string]$RepoUrl = 'https://github.com/ketho-wow/KethoDoc.git',
    [string]$TempDir = "$env:TEMP\KethoDoc-clone"
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$detectScript = Join-Path $scriptDir 'detect-wow-path.ps1'

if (-not $WowPath) {
    $json = & $detectScript -Json | ConvertFrom-Json
    if ($json -is [array]) {
        $pick = $json | Where-Object { $_.Source -match '_classic_' } | Select-Object -First 1
        if (-not $pick) { $pick = $json[0] }
        $WowPath = $pick.Path
    } elseif ($json) {
        $WowPath = $json.Path
    }
}

if (-not $WowPath -or -not (Test-Path (Join-Path $WowPath 'Interface\AddOns'))) {
    throw "WoW path not found. Run detect-wow-path.ps1 or pass -WowPath."
}

$addonsDir = Join-Path $WowPath 'Interface\AddOns'
$dest = Join-Path $addonsDir 'KethoDoc'

Write-Host "Installing KethoDoc to: $dest" -ForegroundColor Cyan

if (Test-Path $TempDir) { Remove-Item -Recurse -Force $TempDir }
git clone --depth 1 $RepoUrl $TempDir

if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
Copy-Item -Path (Join-Path $TempDir '*') -Destination $dest -Recurse -Force

Write-Host 'Done. In-game:' -ForegroundColor Green
Write-Host '  1. Disable Blizzard_Deprecated on character AddOns screen'
Write-Host '  2. Enable KethoDoc, /reload'
Write-Host '  3. Run dumps; save editbox text to documentation\api-reference\live-dump\'
Write-Host '  4. sync-documentation.ps1 -LiveDump (optional copy from SavedVariables)'
