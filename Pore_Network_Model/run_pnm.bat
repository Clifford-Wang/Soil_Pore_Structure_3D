@echo off
cd /d "%~dp0"
if not exist "SoilPNMCUDA.exe" (
  echo SoilPNMCUDA.exe not found. Download the executable from the GitHub release.
  pause
  exit /b 1
)
"SoilPNMCUDA.exe" "config_pnm.txt"
if errorlevel 1 echo PNM solver exited with an error. Review the messages above.
pause
