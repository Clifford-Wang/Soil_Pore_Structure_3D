@echo off
cd /d "%~dp0"
if not exist "input" mkdir "input"
if not exist "training" mkdir "training"
SoilSegmentationCUDA.exe config_segmentation.txt
if errorlevel 1 (
  echo.
  echo Segmentation failed. Check CUDA GPU, labeled training data and configuration.
)
pause
