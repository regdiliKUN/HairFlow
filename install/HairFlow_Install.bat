@echo off
rem HairFlow installer wrapper - allows running the PowerShell script without
rem changing the machine-wide execution policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0HairFlow_Install.ps1" %*
echo.
pause
