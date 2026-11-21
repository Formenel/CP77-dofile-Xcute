# Changelog

## [0.2.0] - 2026-11-21

- UI, README, changelog and code comments in English.
- Language files: `lang/*.json`, selectable via a "Language" dropdown. English is built in as fallback; German (`de.json`) is included.
- Language choice is stored in `settings.lua` together with the debug option.

## [0.1.2] - 2026-11-21

- On first show per game start the window is enlarged to at least its content size. Larger windows are left alone.

## [0.1.1] - 2026-11-21

- "Debug output" checkbox: hides the "ok" message in the window and the CET console. Errors are still always shown.
- Setting is stored in `settings.lua` in the mod folder.

## [0.1.0] - 2026-11-21

- First version: lists `*.lua` from `mods/dofile_xcute/scripts/` in the CET overlay and runs them on click (`dofile` inside `pcall`).
- Example script `hello_xcute.lua`.
