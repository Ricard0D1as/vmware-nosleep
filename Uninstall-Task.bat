@echo off
:: Uninstall-Task.bat
:: Removes the VMware-NoSleep scheduled task

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  Removing VMware-NoSleep scheduled task...
echo.

powershell -Command "Unregister-ScheduledTask -TaskName 'VMware-NoSleep' -Confirm:$false -ErrorAction SilentlyContinue; Write-Host ' [OK] Task removed successfully.' -ForegroundColor Green"

echo.
pause
