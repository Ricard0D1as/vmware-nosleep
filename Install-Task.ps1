# ============================================================
#  Install-Task.ps1
#  Creates a Task Scheduler entry to run VMware-NoSleep.ps1
#  automatically at every Windows logon.
# ============================================================

$TaskName   = "VMware-NoSleep"
$TaskDesc   = "Monitors VMware VMs and prevents sleep/hibernation while any VM is active."
$ScriptPath = Join-Path $PSScriptRoot "VMware-NoSleep.ps1"
$LogonUser  = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if (-not (Test-Path $ScriptPath)) {
    Write-Host "[ERROR] File not found: $ScriptPath" -ForegroundColor Red
    Write-Host "        Make sure this script is in the same folder as VMware-NoSleep.ps1" -ForegroundColor Yellow
    pause
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host "  VMware-NoSleep -- Task Scheduler Installer" -ForegroundColor Cyan
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Script path : $ScriptPath" -ForegroundColor Gray
Write-Host " User        : $LogonUser" -ForegroundColor Gray
Write-Host " Task name   : $TaskName" -ForegroundColor Gray
Write-Host ""

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[INFO] Task already exists. Replacing..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$psArgs = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`" -IntervalSeconds 30 -Silent"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument $psArgs `
    -WorkingDirectory $PSScriptRoot

$TriggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $LogonUser

$Settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -Hidden

$Principal = New-ScheduledTaskPrincipal `
    -UserId $LogonUser `
    -LogonType Interactive `
    -RunLevel Highest

try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description $TaskDesc `
        -Action $Action `
        -Trigger $TriggerLogon `
        -Settings $Settings `
        -Principal $Principal `
        -Force | Out-Null

    Write-Host "[OK] Task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host " The task will:" -ForegroundColor White
    Write-Host "  - Start automatically at every Windows logon" -ForegroundColor Gray
    Write-Host "  - Run silently in the background (no visible window)" -ForegroundColor Gray
    Write-Host "  - Restart automatically on failure (up to 3 times)" -ForegroundColor Gray
    Write-Host "  - Write logs to: $PSScriptRoot\VMware-NoSleep.log" -ForegroundColor Gray
    Write-Host ""
    Write-Host " To manage : Win+R -> taskschd.msc" -ForegroundColor DarkCyan
    Write-Host " To remove : Run Uninstall-Task.bat" -ForegroundColor DarkCyan
    Write-Host ""

} catch {
    Write-Host "[ERROR] Failed to create task: $_" -ForegroundColor Red
    pause
    exit 1
}

$start = Read-Host " Start the monitor now without rebooting? (Y/N)"
if ($start -match "^[Yy]") {
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "[OK] Monitor started in the background." -ForegroundColor Green
}

pause
