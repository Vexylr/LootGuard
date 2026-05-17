# SavedVariables

## Declaration

In your `.toc`:

```toc
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB
```

WoW creates global tables with these names and persists them to disk between sessions.

## Storage location

Under your WoW install:

```
WTF\Account\<AccountName>\SavedVariables\MyAddon.lua
WTF\Account\<AccountName>\<Realm>\<Character>\SavedVariables\MyAddon.lua
```

Account-wide vs per-character depends on which directive you used.

## Usage pattern

```lua
-- Defaults on first load
MyAddonDB = MyAddonDB or {
    scale = 1.0,
    enabled = true,
}

function MyAddon:SaveSetting(key, value)
    MyAddonDB[key] = value
end
```

WoW saves on logout and periodically; do not rely on instant disk writes mid-session for crash recovery.

## Format

- Tables serialize to Lua source (not JSON).
- Only **serializable** values persist: numbers, strings, booleans, tables of the same. No functions, userdata, or frames.
- Keep tables small; large SavedVariables slow login.

## Migration

When you change schema, version your DB:

```lua
MyAddonDB = MyAddonDB or {}
if (MyAddonDB.version or 0) < 2 then
    -- migrate old keys
    MyAddonDB.version = 2
end
```

## Debugging

- Inspect files in `WTF/.../SavedVariables/` while logged out.
- `/dump MyAddonDB` in-game (with a debug addon or DevTools if available on Classic).
