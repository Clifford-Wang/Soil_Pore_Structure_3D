@echo off
cd /d "%~dp0"
if not exist "input" mkdir "input"
SoilStructureCUDA.exe config_structure.txt
if errorlevel 1 (
  echo.
  echo Calculation failed. Check CUDA GPU, input files and configuration.
)
pause
