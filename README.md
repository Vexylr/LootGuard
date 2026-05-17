# LootGuard — Cataclysm Classic 4.4.2

Anti-ninja loot tracking for **World of Warcraft: Cataclysm Classic** (interface **40402**).

| Path | Purpose |
|------|---------|
| [`addon/LootGuard/`](addon/LootGuard/) | Installable addon — copy into `_classic_\Interface\AddOns\` |
| [`documentation/`](documentation/) | Offline API reference, guides, sync scripts |

## Install the addon

Copy [`addon/LootGuard`](addon/LootGuard) to:

```
World of Warcraft\_classic_\Interface\AddOns\LootGuard\
```

Enable **LootGuard** on the AddOns screen. Commands: `/lg`, `/lg session`, `/lg ninja`, `/lg sync`, `/lg config`.

See [addon/LootGuard/README.md](addon/LootGuard/README.md) for features, troubleshooting, and test checklist.

## Documentation

Target patch **4.4.2**. Refresh API dumps locally:

```powershell
.\documentation\scripts\sync-documentation.ps1
```

The full Blizzard UI tree (`documentation/ui-source/`) is not in git — run the sync script to fetch it. See [documentation/README.md](documentation/README.md).

## Sync model (in-game)

- **Guild sync** — reputation snapshots via addon messages
- **Meet sync** — whisper handshake on roster/mouseover
- No external server required (Discord bridge is optional future work)

## Author

[Vexylr](https://github.com/Vexylr) — C# / Python, [CRMSWIN](https://www.crmswin.net/index.htm)
