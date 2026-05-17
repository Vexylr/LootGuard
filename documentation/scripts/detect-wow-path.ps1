#Requires -Version 5.1
<#
.SYNOPSIS
  Locate World of Warcraft install folders (Cataclysm Classic / _classic_).
#>
param(
    [switch]$Json
)

$ErrorActionPreference = 'SilentlyContinue'

function Test-WowRoot {
    param([string]$Path)
    if (-not $Path) { return $false }
    $exe = Join-Path $Path 'Wow.exe'
    $addons = Join-Path $Path 'Interface\AddOns'
    return (Test-Path $exe) -and (Test-Path $addons)
}

$candidates = [System.Collections.Generic.List[object]]::new()

# Explicit env override
if ($env:WOW_CATA_PATH -and (Test-WowRoot $env:WOW_CATA_PATH)) {
    $candidates.Add([pscustomobject]@{ Path = $env:WOW_CATA_PATH; Source = 'WOW_CATA_PATH' })
}

$searchRoots = @(
    "${env:ProgramFiles(x86)}\World of Warcraft",
    "$env:ProgramFiles\World of Warcraft",
    "$env:PUBLIC\Games\World of Warcraft"
)

# Battle.net library layout
$bn = "$env:ProgramData\Battle.net"
if (Test-Path $bn) {
    Get-ChildItem -Path $bn -Recurse -Filter 'product.db' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $root = $_.Directory.Parent.FullName
            if ($root) { $searchRoots += $root }
        }
}

$searchRoots = $searchRoots | Select-Object -Unique

foreach ($root in $searchRoots) {
    if (-not (Test-Path $root)) { continue }
    foreach ($sub in @('_classic_', '_classic_ptr_', '_classic_beta_', '_retail_', '_ptr_', '_beta_')) {
        $p = Join-Path $root $sub
        if (Test-WowRoot $p) {
            $candidates.Add([pscustomobject]@{ Path = $p; Source = "subdir:$sub" })
        }
    }
    if (Test-WowRoot $root) {
        $candidates.Add([pscustomobject]@{ Path = $root; Source = 'root' })
    }
}

$unique = $candidates | Sort-Object Path -Unique

if ($Json) {
    $unique | ConvertTo-Json -Depth 3
    exit 0
}

Write-Host 'World of Warcraft installs (Interface\AddOns present):' -ForegroundColor Cyan
if (-not $unique.Count) {
    Write-Host '  None found. Set WOW_CATA_PATH to your Cata Classic folder.' -ForegroundColor Yellow
    exit 1
}

foreach ($c in $unique) {
    Write-Host "  $($c.Path)" -ForegroundColor Green
    Write-Host "    ($($c.Source))"
}

$classic = $unique | Where-Object { $_.Source -match '_classic_' } | Select-Object -First 1
if ($classic) {
    Write-Host ''
    Write-Host "Suggested Cata/Classic path: $($classic.Path)" -ForegroundColor Cyan
    Write-Host 'Verify in-game: /run local v,b,d=GetBuildInfo(); print(v,b,d)'
}

exit 0
