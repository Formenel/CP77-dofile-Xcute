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

## Editor

"New" in the main window opens an empty script, the pencil button next to a script opens it for editing.

- **Save** writes the file and checks its syntax (without running it). With a syntax error the file is saved anyway and the error is shown, so nothing gets lost.
- **Save & run** saves and runs the script right away.
- **Rename** by changing the file name and saving.
- **Paste clipboard** replaces the text with the clipboard content, e.g. a script copied from a website. Ctrl+C / Ctrl+V / Ctrl+Z work inside the text field as usual.
- **Delete** removes the script after a confirmation.

The editor only works inside `mods\dofile_xcute\scripts\` - CET does not allow access anywhere else. It is a plain text field: no syntax highlighting, no line numbers.

## Languages

English is built in. Further languages are JSON files in `mods\dofile_xcute\lang\` and appear in the "Language" dropdown. Missing keys fall back to English.

To add a language, copy `en.json` to e.g. `fr.json` and translate the values. `_name` is the name shown in the dropdown. Keep the `%s` and `%d` placeholders.

## Limits (set by CET)

- CET restricts `dofile`, `dir` and `io` to the mod's own folder. Scripts must therefore live in `mods\dofile_xcute\scripts\`, not in `cyber_engine_tweaks\scripts\`.
- Scripts run in this mod's environment: they see `Game`, `GetSingleton` etc., but also share global variables with each other.
- Subfolders are not scanned.
