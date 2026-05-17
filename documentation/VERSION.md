# Version manifest

## Target (this project)

| Field | Value |
|-------|-------|
| Game | Cataclysm Classic |
| Patch | **4.4.3** |
| TOC interface | **40403** |
| TOC file suffix | `_Classic.toc` (if using flavor-specific TOC) |

## Bootstrapped from public mirrors

| Source | Tag / branch | Notes |
|--------|--------------|-------|
| [Ketho/BlizzardInterfaceResources](https://github.com/Ketho/BlizzardInterfaceResources) | `4.4.2` (fallback until `4.4.3` tag exists) | `api-reference/` |
| [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) | `4.4.2` (fallback until `4.4.3` tag exists) | `ui-source/` |

Public mirrors may lag your installed client. Prefer **live-dump** when available.

## Live client (fill in after KethoDoc / in-game check)

```
Version:     (paste GetBuildInfo() line 1)
Build:       (paste GetBuildInfo() line 2)
Date:        (paste GetBuildInfo() line 3)
Interface:   (paste GetBuildInfo() line 4 or TOC value)
Dumped:      YYYY-MM-DD
```

Example slash command:

```lua
/run local v,b,d,i=GetBuildInfo(); print(v,b,d,i)
```

## Last sync

| Component | Date | Script |
|-----------|------|--------|
| api-reference (Ketho) | 2026-05-17 (4.4.2) | `sync-documentation.ps1` |
| ui-source (Gethe) | 2026-05-17 (skipped) | `sync-documentation.ps1` |
| live-dump | _not yet_ | KethoDoc + `-LiveDump` |
