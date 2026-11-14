@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0index.html" (
  echo Error: This launcher must stay next to index.html.
  pause
  exit /b 1
)
echo Starting TARVOKA 3D Studio in your default browser...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Tarvoka-Studio.ps1"
if errorlevel 1 pause
