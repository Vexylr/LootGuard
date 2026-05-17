# Debugging addons

## Script errors

Enable errors on screen:

```
/console scriptErrors 1
```

Reload UI after code changes:

```
/reload
```

## Print and dump

```lua
print("value", someTable)
DEFAULT_CHAT_FRAME:AddMessage("msg")
```

Use `/dump Expression` if you have an addon that provides it, or DevTools on builds that support it.

## Taint log

When you see *“Interface action failed because of an AddOn”*:

```
/console taintLog 1
```

Reproduce the issue, exit the game, open:

```
World of Warcraft\<flavor>\Logs\taint.log
```

Search for `blocked` and identify the addon/frame involved.

Disable:

```
/console taintLog 0
```

## Isolating conflicts

1. Disable all addons except yours.
2. Re-enable half at a time.
3. Use the character screen **AddOns** list; enable **Load out of date AddOns** only when testing interface mismatches.

## In-game API browser

On clients that support it, `/api` opens Blizzard’s API documentation (from `Blizzard_APIDocumentation`). Cross-check with `documentation/ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/`.

## Offline reference (this repo)

| Problem | Where to look |
|---------|----------------|
| Typo in API name | `api-reference/GlobalAPI.lua` |
| Wrong event | `api-reference/Events.lua` |
| CVar name | `api-reference/CVars.lua` |
| Enum constant | `api-reference/LuaEnum.lua` |
| Blizzard pattern | `ui-source/Interface/FrameXML/` |

## KethoDoc dumps

Refresh local API lists from your exact client — see [README.md](../README.md#live-dump-kethodoc).

## Development installs

Symlink or copy your addon folder into `Interface\AddOns\` so edits reload with `/reload` without repackaging.

```powershell
# Example: junction (run as appropriate for your paths)
cmd /c mklink /J "%WOW%\Interface\AddOns\MyAddon" "C:\path\to\repo\MyAddon"
```
