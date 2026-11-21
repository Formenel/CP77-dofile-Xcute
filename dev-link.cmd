@echo off
rem dev-link.cmd - haengt das Mod aus source\ per Junction ins Spiel.
rem Spielpfad bei Bedarf anpassen.
setlocal
set "GAME=D:\SteamLibrary\steamapps\common\Cyberpunk 2077"
set "ZIEL=%GAME%\bin\x64\plugins\cyber_engine_tweaks\mods\dofile_xcute"
set "QUELLE=%~dp0bin\x64\plugins\cyber_engine_tweaks\mods\dofile_xcute"
if exist "%ZIEL%" (
  echo Ziel existiert schon: %ZIEL%
  echo Erst entfernen, dann erneut starten.
  exit /b 1
)
mklink /J "%ZIEL%" "%QUELLE%"
