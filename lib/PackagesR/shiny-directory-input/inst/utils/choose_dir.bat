:: choose_dir.bat
:: launches a folder chooser and outputs choice to stdout
:: https://stackoverflow.com/a/15885133/1683264
:: Enhanced for Windows 11 compatibility

@echo off
setlocal

if -%1-==-- (
  set "caption='Please choose a folder.'"
) else (
  set "caption='%1'"
)

REM Fix: Enhanced PowerShell command for Windows 11 compatibility
set "psCommand="$folder = (new-object -COM 'Shell.Application').BrowseForFolder(0,%caption%,0,0); if($folder) { $folder.self.path } else { 'NONE' }""

REM Fix: Better error handling for Windows 11
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command %psCommand% 2^>nul`) do set "folder=%%I"

REM Fix: Handle empty result
if "-%folder%-"=="--" set "folder=NONE"
if "%folder%"=="" set "folder=NONE"

setlocal enabledelayedexpansion
echo !folder!
endlocal
