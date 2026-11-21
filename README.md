# dofile Xcute

CET mod for Cyberpunk 2077: lists every `*.lua` file from a folder as a button in the CET overlay. One click runs the script. A replacement for the "dofiles" feature of the CET Mod Manager.

## Requirements

- Cyber Engine Tweaks (CET)

No RED4ext DLL, no `.asi` - pure Lua.

## Installation

- **Vortex:** install `dofile_xcute-<version>.zip`.
- **Manually:** extract the ZIP into the game's root folder (`Cyberpunk 2077\`). The mod then lives in:

```
bin\x64\plugins\cyber_engine_tweaks\mods\dofile_xcute\
```

## Usage

1. Put your own `.lua` files into `mods\dofile_xcute\scripts\`.
2. Open the CET overlay in game. The "dofile Xcute" window lists the scripts.
3. Click a button. The result is shown at the bottom of the window and in the CET console.

"Debug output" turns off the "ok" messages in the window and the console; errors are always shown.

"Rescan" picks up newly added files without reloading CET. The folder is also rescanned every time the overlay opens.

Settings (debug output, language) are stored in `settings.lua` in the mod folder.

## Languages

English is built in. Further languages are JSON files in `mods\dofile_xcute\lang\` and appear in the "Language" dropdown. Missing keys fall back to English.

To add a language, copy `en.json` to e.g. `fr.json` and translate the values. `_name` is the name shown in the dropdown. Keep the `%s` and `%d` placeholders.

## Limits (set by CET)

- CET restricts `dofile`, `dir` and `io` to the mod's own folder. Scripts must therefore live in `mods\dofile_xcute\scripts\`, not in `cyber_engine_tweaks\scripts\`.
- Scripts run in this mod's environment: they see `Game`, `GetSingleton` etc., but also share global variables with each other.
- Subfolders are not scanned.
