#Requires -Version 5.1
<#
.SYNOPSIS
  Sync Cataclysm Classic addon documentation (Ketho API + Gethe UI source).
.PARAMETER SkipUiSource
  Skip cloning/updating ui-source.
.PARAMETER SkipApiReference
  Skip downloading Ketho api-reference files.
.PARAMETER AllGlobalStrings
  Download all GlobalStrings locales (large).
.PARAMETER LiveDump
  Copy KethoDoc SavedVariables dumps into api-reference/live-dump/.
.PARAMETER WowPath
  WoW install for -LiveDump (default: auto-detect _classic_).
#>
param(
    [switch]$SkipUiSource,
    [switch]$SkipApiReference,
    [switch]$AllGlobalStrings,
    [switch]$LiveDump,
    [string]$WowPath,
    [string[]]$PreferredTags = @('4.4.2', '4.4.3', '4.4.1', '4.4.0')
)

$ErrorActionPreference = 'Stop'

$docRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$apiDir = Join-Path $docRoot 'api-reference'
$liveDir = Join-Path $apiDir 'live-dump'
$uiDir = Join-Path $docRoot 'ui-source'
$versionFile = Join-Path $docRoot 'VERSION.md'
$tempDir = Join-Path $env:TEMP 'wow-doc-sync'

$kethoBase = 'https://raw.githubusercontent.com/Ketho/BlizzardInterfaceResources'
$getheRepo = 'https://github.com/Gethe/wow-ui-source.git'

$coreFiles = @(
    'GlobalAPI.lua', 'WidgetAPI.lua', 'Events.lua', 'CVars.lua', 'LuaEnum.lua',
    'FrameXML.lua', 'Templates.lua', 'Mixins.lua', 'Frames.lua',
    'AtlasInfo.lua', 'WidgetHierarchy.png'
)

function Resolve-AvailableTag {
    param([string]$OwnerRepo)
    foreach ($tag in $PreferredTags) {
        try {
            $uri = "https://api.github.com/repos/$OwnerRepo/git/refs/tags/$tag"
            Invoke-RestMethod -Uri $uri -ErrorAction Stop | Out-Null
            return $tag
        } catch {
            continue
        }
    }
    throw "No tag found among: $($PreferredTags -join ', ')"
}

function Invoke-DownloadFile {
    param([string]$Url, [string]$OutPath)
    $dir = Split-Path $OutPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Write-Host "  GET $([IO.Path]::GetFileName($OutPath))"
    Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing
}

function Update-VersionManifest {
    param([string]$KethoTag, [string]$GetheTag, [string]$SyncDate)
    if (-not (Test-Path $versionFile)) { return }
    $lines = Get-Content $versionFile
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like '*api-reference (Ketho)*') {
            $lines[$i] = "| api-reference (Ketho) | $SyncDate ($KethoTag) | ``sync-documentation.ps1`` |"
        }
        if ($lines[$i] -like '*ui-source (Gethe)*') {
            $lines[$i] = "| ui-source (Gethe) | $SyncDate ($GetheTag) | ``sync-documentation.ps1`` |"
        }
    }
    Set-Content -Path $versionFile -Value $lines
}

# --- API reference (Ketho) ---
$kethoTag = $null
$getheTag = $null
$syncDate = (Get-Date).ToString('yyyy-MM-dd')

if (-not $SkipApiReference) {
    $kethoTag = Resolve-AvailableTag 'Ketho/BlizzardInterfaceResources'
    Write-Host "Ketho BlizzardInterfaceResources @ $kethoTag" -ForegroundColor Cyan
    if (-not (Test-Path $apiDir)) { New-Item -ItemType Directory -Path $apiDir -Force | Out-Null }

    foreach ($file in $coreFiles) {
        $url = "$kethoBase/$kethoTag/Resources/$file"
        Invoke-DownloadFile -Url $url -OutPath (Join-Path $apiDir $file)
    }

  # GlobalStrings
    $gsUrl = "https://api.github.com/repos/Ketho/BlizzardInterfaceResources/contents/Resources/GlobalStrings?ref=$kethoTag"
    $gsItems = Invoke-RestMethod -Uri $gsUrl
    $locales = if ($AllGlobalStrings) { $gsItems } else { $gsItems | Where-Object { $_.name -eq 'enUS.lua' } }
    foreach ($item in $locales) {
        $out = Join-Path $apiDir "GlobalStrings\$($item.name)"
        Invoke-DownloadFile -Url $item.download_url -OutPath $out
    }
}

# --- UI source (Gethe) ---
if (-not $SkipUiSource) {
    $getheTag = Resolve-AvailableTag 'Gethe/wow-ui-source'
    Write-Host "Gethe wow-ui-source @ $getheTag" -ForegroundColor Cyan

    if (Test-Path (Join-Path $uiDir '.git')) {
        Push-Location $uiDir
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        git fetch --depth 1 origin tag $getheTag 2>&1 | Out-Null
        git checkout $getheTag 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            git fetch --depth 1 origin tag $getheTag 2>&1 | Out-Null
            git checkout FETCH_HEAD 2>&1 | Out-Null
        }
        $ErrorActionPreference = $prevEap
        Pop-Location
    } else {
        if (Test-Path $uiDir) { Remove-Item -Recurse -Force $uiDir }
        git clone --depth 1 --branch $getheTag $getheRepo $uiDir
    }
}

# --- Live dump copy ---
if ($LiveDump) {
    $detectScript = Join-Path $PSScriptRoot 'detect-wow-path.ps1'
    if (-not $WowPath) {
        $json = & $detectScript -Json | ConvertFrom-Json
        if ($json -is [array]) {
            $pick = $json | Where-Object { $_.Source -match '_classic_' } | Select-Object -First 1
            if ($pick) { $WowPath = $pick.Path }
        } elseif ($json) { $WowPath = $json.Path }
    }
    if (-not $WowPath) { Write-Warning 'LiveDump: WoW path not found; skip.' }
    else {
        Write-Host "LiveDump from: $WowPath" -ForegroundColor Cyan
        if (-not (Test-Path $liveDir)) { New-Item -ItemType Directory -Path $liveDir -Force | Out-Null }
        $svRoot = Join-Path $WowPath 'WTF'
        $patterns = @('GlobalAPI.lua', 'WidgetAPI.lua', 'Events.lua', 'CVars.lua', 'LuaEnum.lua', 'FrameXML.lua', 'Frames.lua')
        $found = 0
        Get-ChildItem -Path $svRoot -Recurse -Filter 'KethoDoc*.lua' -ErrorAction SilentlyContinue | ForEach-Object {
            $dest = Join-Path $liveDir $_.Name
            Copy-Item $_.FullName $dest -Force
            $found++
        }
        foreach ($name in $patterns) {
            Get-ChildItem -Path $svRoot -Recurse -Filter $name -ErrorAction SilentlyContinue |
                Where-Object { $_.DirectoryName -match 'SavedVariables' } |
                Select-Object -First 1 |
                ForEach-Object {
                    Copy-Item $_.FullName (Join-Path $liveDir $name) -Force
                    $found++
                }
        }
        if ($found -eq 0) {
            Write-Warning 'No KethoDoc dumps found under WTF. Save editbox output manually to api-reference/live-dump/.'
        } else {
            Write-Host "Copied $found file(s) to live-dump/" -ForegroundColor Green
            if (Test-Path $versionFile) {
                $lines = Get-Content $versionFile
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -like '*live-dump*' -and $lines[$i].StartsWith('|')) {
                        $lines[$i] = "| live-dump | $syncDate | KethoDoc + ``-LiveDump`` |"
                    }
                }
                Set-Content -Path $versionFile -Value $lines
            }
        }
    }
}

if ($kethoTag -or $getheTag) {
    $kt = if ($kethoTag) { $kethoTag } else { 'skipped' }
    $gt = if ($getheTag) { $getheTag } else { 'skipped' }
    Update-VersionManifest -KethoTag $kt -GetheTag $gt -SyncDate $syncDate
}

Write-Host ''
Write-Host 'Sync complete.' -ForegroundColor Green
Write-Host "  api-reference: $apiDir"
Write-Host "  ui-source:     $uiDir"
