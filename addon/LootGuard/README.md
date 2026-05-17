# LootGuard

Cataclysm Classic (4.4.3 / interface `40403`) addon for loot roll tracking, anti-ninja heuristics, player reputation (1–10), and in-game sync.

## Install

Copy the `LootGuard` folder to:

```
World of Warcraft\_classic_\Interface\AddOns\LootGuard\
```

Enable **LootGuard** on the character AddOns screen. Set `## Interface: 40403` if your client differs.

## Commands

| Command | Action |
|---------|--------|
| `/lootguard` or `/lg` | Toggle main window |
| `/lg session` | Open Session tab |
| `/lg ninja` or `/lg list` | Open Ninja List tab |
| `/lg config` | Open advanced settings (AceConfig) |
| `/lg sync` | Push reputation data to guild channel |

Enable **Load out of date AddOns** if your client interface differs from `40403`.

## Features

- Logs party/raid loot rolls via `C_LootHistory`
- Flags suspicious **Need** rolls (wrong armor/weapon for class)
- **Session** tab — per-run roll log
- **Ninja List** — flagged players (Watch / Suspected / Ninja)
- **Tooltip** — Loot Reputation score on player hover
- **Guild sync** — shares reputation snapshots with guildmates running LootGuard
- **Meet sync** — whisper handshake on mouseover/group roster

## Sync limits

Players must share a **guild** (for passive sync) or **meet in-game** (mouseover/roster whisper). There is no external server; two strangers on opposite ends of the world will not sync until they interact.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Addon won't load | Check `## Interface:` matches your client; run with `/console scriptErrors 1` |
| No rolls logged | Must be in party/raid; loot must use group roll UI (`C_LootHistory`) |
| Wrong armor not flagged | Item data still loading — wait a second; re-roll after cache fills |
| Sync not working | Same guild for guild sync; mouseover players for meet sync; both need LootGuard |
| Empty Ninja List | Default shows Suspected+ only; change in Advanced thresholds → “Ninja list shows” |
| Watch players missing | Set Ninja list to “Watch and above” in settings |

## Manual test checklist

1. Enter a dungeon in a party of 2+.
2. Roll Need/Greed on loot; confirm Session tab updates.
3. Roll Need on wrong armor type; confirm flag/reputation drop.
4. Hover player tooltip; see reputation line.
5. With 2 clients in same guild: `/lg sync` on one; `/reload` on other; check Ninja List.
6. Mouseover second client; verify whisper sync (enable meet sync).
7. Toggle guild/meet sync off in Settings; confirm behavior stops.

## Project layout

See [documentation/README.md](../../documentation/README.md) for API reference used during development.
