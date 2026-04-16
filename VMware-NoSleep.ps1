# ============================================================
#  VMware-NoSleep.ps1
#  Monitors running VMs in VMware Workstation/Player
#  and prevents sleep/hibernation while any VM is active.
# ============================================================

param (
    [int]$IntervalSeconds = 30,
    [switch]$Silent
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    if (-not $Silent) { Write-Host $line }
    Add-Content -Path "$PSScriptRoot\VMware-NoSleep.log" -Value $line
}

function Get-RunningVMs {
    $vms = Get-Process -Name "vmware-vmx" -ErrorAction SilentlyContinue
    return $vms
}

function Set-SleepPrevention {
    param([bool]$Enable)
    $signature = @"
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
"@
    $type = Add-Type -MemberDefinition $signature -Name "PowerMgmt" -Namespace "Win32" -PassThru
    if ($Enable) {
        $flags = [uint32]0x80000001
        $result = $type::SetThreadExecutionState($flags)
        return $result -ne 0
    } else {
        $flags = [uint32]0x80000000
        $result = $type::SetThreadExecutionState($flags)
        return $result -ne 0
    }
}

Write-Log "VMware-NoSleep started. Check interval: ${IntervalSeconds}s"
Write-Log "Press Ctrl+C to stop."

$wasPreventing = $false

try {
    while ($true) {
        $runningVMs = Get-RunningVMs
        $count = if ($runningVMs) { $runningVMs.Count } else { 0 }
        if ($count -gt 0) {
            if (-not $wasPreventing) {
                $ok = Set-SleepPrevention -Enable $true
                if ($ok) { Write-Log "[$count VM(s) running] Sleep/hibernation BLOCKED." "BLOCK" }
                else { Write-Log "Failed to block sleep." "WARN" }
                $wasPreventing = $true
            } else {
                Write-Log "[$count VM(s) running] Sleep still blocked." "OK"
            }
        } else {
            if ($wasPreventing) {
                $ok = Set-SleepPrevention -Enable $false
                if ($ok) { Write-Log "No active VMs. Sleep/hibernation RESTORED." "RESTORE" }
                else { Write-Log "Failed to restore sleep settings." "WARN" }
                $wasPreventing = $false
            } else {
                Write-Log "No active VMs. System in normal power mode." "OK"
            }
        }
        Start-Sleep -Seconds $IntervalSeconds
    }
}
finally {
    Set-SleepPrevention -Enable $false
    Write-Log "VMware-NoSleep stopped. Sleep/hibernation restored." "EXIT"
}
