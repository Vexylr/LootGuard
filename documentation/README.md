# Cataclysm Classic 4.4.3 — Addon API Documentation

Offline reference for WoW **Cataclysm Classic** addon development. Target patch **4.4.3**, interface **`40403`**.

## Quick start

1. **Interface for your addon TOC** — see [VERSION.md](VERSION.md). Verify in-game:
   ```lua
   /run print(GetBuildInfo())
   /run print((select(4, GetBuildInfo())))  -- interface version if returned
   ```
2. **Find a global API** — search `api-reference/GlobalAPI.lua` (or `api-reference/live-dump/` after a KethoDoc dump).
3. **Find an event** — search `api-reference/Events.lua`.
4. **Find C_* APIs** — browse `ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/` or use in-game `/api`.
5. **UI patterns** — browse `ui-source/Interface/FrameXML/`.

## Folder map

| Path | Contents |
|------|----------|
| [VERSION.md](VERSION.md) | Pinned patch, interface, build, sync dates |
| [SOURCES.md](SOURCES.md) | Upstream repos and licenses |
| [getting-started/](getting-started/) | TOC, anatomy, SavedVariables, debugging |
| [api-reference/](api-reference/) | Ketho machine-readable API dumps |
| [api-reference/live-dump/](api-reference/live-dump/) | Dumps from *your* client via KethoDoc |
| [ui-source/](ui-source/) | Full [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) checkout |
| [patch-notes/](patch-notes/) | Per-patch API change links |
| [external-links.md](external-links.md) | Online references |
| [scripts/](scripts/) | Sync and install helpers |

## Refresh documentation

From the project root:

```powershell
.\documentation\scripts\sync-documentation.ps1
```

Options:

- `-SkipUiSource` — skip git clone/pull of ui-source
- `-SkipApiReference` — skip Ketho download
- `-AllGlobalStrings` — download all locale GlobalStrings (large)
- `-LiveDump` — copy KethoDoc output from WoW install into `api-reference/live-dump/`

Install KethoDoc into your game:

```powershell
.\documentation\scripts\install-kethodoc.ps1
```

Detect WoW install path:

```powershell
.\documentation\scripts\detect-wow-path.ps1
```

If nothing is found, set your Cata Classic folder and re-run:

```powershell
$env:WOW_CATA_PATH = "D:\Games\World of Warcraft\_classic_"
.\documentation\scripts\detect-wow-path.ps1
```

## Live dump (KethoDoc)

1. Run `install-kethodoc.ps1` (or copy [KethoDoc](https://github.com/ketho-wow/KethoDoc) manually).
2. **Disable** the `Blizzard_Deprecated` addon for accurate dumps.
3. Log into **Cataclysm Classic**, type `/ketho` or use the KethoDoc UI.
4. Run each dump and save the editbox text to `documentation/api-reference/live-dump/`:

   | In-game / slash | Save as |
   |-----------------|---------|
   | `DumpGlobalAPI` | `GlobalAPI.lua` |
   | `DumpWidgetAPI` | `WidgetAPI.lua` |
   | `DumpEvents` | `Events.lua` |
   | `DumpCVars` | `CVars.lua` |
   | `DumpLuaEnums` | `LuaEnum.lua` |
   | `DumpFrameXML` | `FrameXML.lua` |
   | `DumpFrames` | `Frames.lua` |

5. Update [VERSION.md](VERSION.md) with `GetBuildInfo()` output.
6. Re-run `sync-documentation.ps1 -LiveDump` if you configured automatic copy paths.

## Ready checklist (before building your addon)

| Check | How |
|-------|-----|
| Interface for TOC | `VERSION.md` → `## Interface: 40403` in `YourAddon.toc` |
| API exists on Cata | Grep `api-reference/GlobalAPI.lua` |
| Event name | Grep `api-reference/Events.lua` |
| Blizzard UI example | Search `ui-source/Interface/FrameXML/` |
| After a game patch | `sync-documentation.ps1` + optional KethoDoc live dump |

## IDE

Lua Language Server uses [.luarc.json](.luarc.json) (and root `.luarc.json`) so globals resolve against `api-reference/` and `ui-source/`.
