# MapleStory stutter / freeze mitigation
# Run as Administrator via maple_freeze_fix.bat
# Undo with maple_freeze_revert.bat

$ErrorActionPreference = 'Continue'
function Say($m) { Write-Host $m }

Say ""
Say "[1/5] HAGS (hardware accelerated GPU scheduling) -> ON"
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -Value 2 -Type DWord
Say "      HwSchMode = 2"

Say ""
Say "[2/5] GameDVR background recording -> OFF"
Set-ItemProperty 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -Value 0 -Type DWord
New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name AllowGameDVR -Value 0 -Type DWord
Say "      GameDVR_Enabled = 0"

Say ""
Say "[3/5] Power plan -> High performance"
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg /getactivescheme

Say ""
Say "[4/5] MPO (multi-plane overlay) -> OFF"
New-Item 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name OverlayTestMode -Value 5 -Type DWord
Say "      OverlayTestMode = 5"

Say ""
Say "[5/5] Pagefile"
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Say "      Installed RAM: $ramGB GB"
if ($ramGB -ge 48) {
    Say "      SKIPPED - with $ramGB GB there is no memory pressure, so a fixed"
    Say "      pagefile buys nothing. Leaving it system-managed."
} else {
    Say "      -> fixed 32768 MB (stops mid-game expansion stalls)"
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile = $false} | Out-Null
    }
    $pf = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'C:*' }
    if ($pf) {
        Set-CimInstance -InputObject $pf -Property @{InitialSize = 32768; MaximumSize = 32768} | Out-Null
    } else {
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name = 'C:\pagefile.sys'; InitialSize = 32768; MaximumSize = 32768} | Out-Null
    }
    Get-CimInstance Win32_PageFileSetting | ForEach-Object { Say "      $($_.Name): $($_.InitialSize) / $($_.MaximumSize) MB" }
}

Say ""
Say "=== DONE ==="
Say "REBOOT REQUIRED for HAGS and MPO to take effect."
Say ""
Read-Host "Press Enter to close"
