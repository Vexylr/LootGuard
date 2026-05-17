# Patch API changes (Cataclysm Classic)

Summaries and links for Cata Classic patches relevant to addon authors. This project targets **4.4.2** / interface **40402**.

## Per-patch wiki pages

| Patch | Interface | Wiki |
|-------|-----------|------|
| 4.4.0 | 40400 | [Patch 4.4.0/API changes](https://warcraft.wiki.gg/wiki/Patch_4.4.0/API_changes) |
| 4.4.1 | 40401 | [Patch 4.4.1/API changes](https://warcraft.wiki.gg/wiki/Patch_4.4.1/API_changes) |
| 4.4.2 | **40402** | [Patch 4.4.2/API changes](https://warcraft.wiki.gg/wiki/Patch_4.4.2/API_changes) — **this project** |
| 4.4.3 | 40403 | Future — use live KethoDoc dump + git diffs when released |

## Notable changes

### 4.4.2

- Modern **auction house** enabled for Cataclysm Classic.
- **`C_AuctionHouse`** APIs available (see ui-source and api-reference diffs).

### 4.4.1

- See wiki consolidated diffs vs 4.4.0 for added/removed globals.

## GitHub compare (machine-readable diffs)

| Compare | Ketho (API dumps) | Gethe (UI source) |
|---------|-------------------|-------------------|
| 4.4.0 → 4.4.1 | [compare](https://github.com/Ketho/BlizzardInterfaceResources/compare/4.4.0...4.4.1) | [compare](https://github.com/Gethe/wow-ui-source/compare/4.4.0...4.4.1) |
| 4.4.1 → 4.4.2 | [compare](https://github.com/Ketho/BlizzardInterfaceResources/compare/4.4.1...4.4.2) | [compare](https://github.com/Gethe/wow-ui-source/compare/4.4.1...4.4.2) |
| 4.4.2 → 4.4.3 | When tag exists | When tag exists |

## After each patch

1. Run `documentation/scripts/sync-documentation.ps1`.
2. Optional: KethoDoc live dump from your client.
3. Update `documentation/VERSION.md` with `GetBuildInfo()`.
4. Bump `## Interface:` in your addon TOC.
