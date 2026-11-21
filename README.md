# dofile Xcute

CET-Mod fuer Cyberpunk 2077: zeigt im CET-Overlay alle `*.lua`-Dateien aus einem Ordner als Buttons. Ein Klick fuehrt das Skript aus. Ersatz fuer die "dofiles"-Funktion des CET Mod Managers.

## Voraussetzung

- Cyber Engine Tweaks (CET)

Keine RED4ext-DLL, kein `.asi` - reines Lua.

## Installation

- **Vortex:** `dofile_xcute-<version>.zip` installieren.
- **Von Hand:** ZIP ins Spiel-Hauptverzeichnis (`Cyberpunk 2077\`) entpacken. Das Mod liegt dann unter:

```
bin\x64\plugins\cyber_engine_tweaks\mods\dofile_xcute\
```

## Benutzung

1. Eigene `.lua` nach `mods\dofile_xcute\scripts\` legen.
2. Im Spiel das CET-Overlay oeffnen. Das Fenster "dofile Xcute" listet die Skripte.
3. Button klicken. Ergebnis steht unten im Fenster und in der CET-Konsole.

"Debug-Ausgabe" schaltet die "ok"-Meldungen in Fenster und Konsole ab; Fehler werden immer angezeigt. Die Einstellung landet in `settings.lua` im Mod-Ordner.

"Neu einlesen" holt neu abgelegte Dateien, ohne CET neu zu laden. Beim Oeffnen des Overlays wird ohnehin neu eingelesen.

## Grenzen (durch CET vorgegeben)

- CET sperrt `dofile`, `dir` und `io` auf den eigenen Mod-Ordner. Skripte muessen deshalb in `mods\dofile_xcute\scripts\` liegen, nicht in `cyber_engine_tweaks\scripts\`.
- Die Skripte laufen in der Umgebung dieses Mods: sie sehen `Game`, `GetSingleton` usw., teilen sich aber auch globale Variablen untereinander.
- Unterordner werden nicht durchsucht.
