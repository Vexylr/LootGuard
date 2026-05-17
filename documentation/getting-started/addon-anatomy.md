# Addon anatomy

## Install location

Addons live under:

```
World of Warcraft\<flavor>\Interface\AddOns\<AddonName>\
```

Cataclysm Classic typically uses the `_classic_` or flavor-specific folder under your Battle.net WoW install. Run `documentation/scripts/detect-wow-path.ps1` to locate yours.

## Minimum layout

```
MyAddon/
  MyAddon.toc          # Required — metadata and file list
  MyAddon.lua          # Main logic (name from TOC)
  MyAddon.xml          # Optional — frames and templates
```

## Load order

1. WoW reads the **TOC** (Table of Contents).
2. Files listed in the TOC load in order.
3. `## LoadOnDemand: 1` defers loading until `LoadAddOn("Name")` is called.
4. Dependencies in `## Dependencies:` or `## OptionalDeps:` control load order relative to other addons.

## Lua environment

- Each addon file runs in a chunk with its own globals unless you use `local`.
- Common pattern: one table per addon (`MyAddon = {}`) and `local` helpers.
- `addonName, addonTable = ...` as the first line receives Blizzard’s addon private table (retail/modern pattern; check ui-source for Cata usage).

## XML and frames

- **FrameXML** defines UI with XML tags (`<Frame>`, `<Button>`, etc.) and Lua scripts.
- Templates inherit from Blizzard templates in `ui-source/Interface/FrameXML/`.
- Secure frames (action buttons, unit frames in combat) follow [secure execution rules](https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting).

## Taint (short version)

- Calling protected APIs from addon code **taints** execution paths.
- Tainted code cannot call secure functions during combat.
- Use hook templates, `hooksecurefunc`, and avoid writing to secure frame attributes in combat.
- Debug: `/console taintLog 1` then check `Logs\taint.log`.

## Where to look in this repo

| Need | Location |
|------|----------|
| Function exists? | `api-reference/GlobalAPI.lua` |
| Event name? | `api-reference/Events.lua` |
| How Blizzard does it | `ui-source/Interface/FrameXML/` |
| C_* documentation | `ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/` |
