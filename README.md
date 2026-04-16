# VMware-NoSleep

A lightweight PowerShell utility that automatically prevents Windows from sleeping or hibernating while VMware Workstation/Player virtual machines are running, and restores normal power behaviour as soon as all VMs are closed.

## How It Works

The monitor polls for `vmware-vmx` processes (one per running VM) every 30 seconds.

| State | Action |
|---|---|
| One or more VMs running | Calls `SetThreadExecutionState` (Win32 API) to block sleep and hibernation |
| No VMs running | Releases the restriction — Windows resumes normal power management |

No system settings are permanently modified. Everything is scoped to the process lifetime.

## Files

| File | Description |
|---|---|
| `VMware-NoSleep.ps1` | Core monitor script |
| `Start-VMware-NoSleep.bat` | Manual launcher (with visible console) |
| `Install-Task.ps1` | Creates a Task Scheduler entry (runs at logon, hidden) |
| `Install-Task.bat` | Launcher for the installer (auto-elevates to admin) |
| `Uninstall-Task.bat` | Removes the scheduled task |

## Quick Start

### Option A — Run manually
1. Download or clone the repository
2. Double-click `Start-VMware-NoSleep.bat`
3. Leave the window open in the background

### Option B — Install as a scheduled task (recommended)
1. Place all files in a permanent folder (e.g. `C:\Scripts\VMware-NoSleep\`)
2. Double-click `Install-Task.bat` — requests admin elevation automatically
3. When prompted, choose Y to start the monitor immediately

The task runs silently at every Windows logon from that point on.

## Requirements

- Windows 10 / 11
- PowerShell 5.1 or later (included with Windows)
- VMware Workstation or VMware Player

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `-IntervalSeconds` | 30 | How often in seconds to check for running VMs |
| `-Silent` | false | Suppress console output (log file is always written) |

Example:

```powershell
powershell -ExecutionPolicy Bypass -File VMware-NoSleep.ps1 -IntervalSeconds 10 -Silent
```

## Logs

```
[2025-04-16 14:03:01] [INFO]    VMware-NoSleep started. Check interval: 30s
[2025-04-16 14:03:01] [OK]      No active VMs. System in normal power mode.
[2025-04-16 14:03:31] [BLOCK]   [2 VM(s) running] Sleep/hibernation BLOCKED.
[2025-04-16 14:04:01] [OK]      [2 VM(s) running] Sleep still blocked.
[2025-04-16 14:04:31] [RESTORE] No active VMs. Sleep/hibernation RESTORED.
[2025-04-16 14:04:31] [EXIT]    VMware-NoSleep stopped. Sleep/hibernation restored.
```

## Uninstalling

Run `Uninstall-Task.bat` to remove the scheduled task. The script files can then be deleted manually.

## License

MIT
