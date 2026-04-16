@echo off
:: Start-VMware-NoSleep.bat
:: Runs the PowerShell monitor with execution policy bypass

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  =========================================
echo   VMware-NoSleep -- Sleep Monitor
echo  =========================================
echo.
echo  Check interval : 30 seconds
echo  Log file       : VMware-NoSleep.log (same folder)
echo  Press Ctrl+C to stop.
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0VMware-NoSleep.ps1" -IntervalSeconds 30

pause
