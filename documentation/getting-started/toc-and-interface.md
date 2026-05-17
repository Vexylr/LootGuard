# TOC format and interface version

## TOC basics

The `.toc` file is plain text:

- Lines starting with `##` are **directives** (metadata).
- Other non-comment lines are **files to load** (relative to the addon folder).
- Lines starting with `#` are comments.

Example for Cataclysm Classic (4.4.2):

```toc
## Interface: 40402
## Title: My Addon
## Notes: Short description
## Author: YourName
## Version: 1.0.0
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB

MyAddon.xml
MyAddon.lua
```

## Interface number

`## Interface:` must match the client your addon targets. Mismatch shows **“out of date”** on the character screen (unless the user enables “Load out of date AddOns”).

| Patch | Interface (Cata Classic) |
|-------|--------------------------|
| 4.4.0 | 40400 |
| 4.4.1 | 40401 |
| 4.4.2 | **40402** (this project) |
| 4.4.3 | 40403 |

Verify your client:

```lua
/run print(GetBuildInfo())
```

See [VERSION.md](../VERSION.md) for the pinned value used in this workspace.

## Multiple flavors

Blizzard loads flavor-specific TOC files when present:

| File | Used when |
|------|-----------|
| `MyAddon.toc` | Default fallback |
| `MyAddon_Classic.toc` | Classic flavors (includes Cata Classic) |

For Cata-only addons, a single TOC with `## Interface: 40402` is often enough.

## Common directives

| Directive | Purpose |
|-----------|---------|
| `## Interface:` | Required — API compatibility |
| `## Title:` | Display name |
| `## Notes:` | Description |
| `## Author:` | Author |
| `## Version:` | Version string |
| `## SavedVariables:` | Account-wide saved vars table name |
| `## SavedVariablesPerCharacter:` | Per-character saved vars |
| `## Dependencies:` | Required addons (load first) |
| `## OptionalDeps:` | Optional addons |
| `## LoadOnDemand:` | `1` = load only when requested |
| `## DefaultState:` | `disabled` to start disabled |
| `## X-*` | Custom metadata (ignored by client) |

Full reference: [TOC format — Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format).

## Load list tips

- List XML before Lua if frames must exist before scripts run.
- Split modules as separate files; list each in the TOC.
- Do not list files that are `LoadOnDemand` submodules unless you load them manually.
