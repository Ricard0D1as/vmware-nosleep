@echo off
:: Install-Task.bat
:: Launches the task installer with automatic elevation

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Install-Task.ps1"
