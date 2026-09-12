# Undo everything maple_freeze_fix.ps1 changed.
# Run as Administrator via maple_freeze_revert.bat

$ErrorActionPreference = 'Continue'

Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -Value 1 -Type DWord
Write-Host "HAGS -> off (HwSchMode = 1)"

Set-ItemProperty 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -Value 1 -Type DWord
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name AllowGameDVR -ErrorAction SilentlyContinue
Write-Host "GameDVR -> on"

powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
Write-Host "Power plan -> Balanced"

Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name OverlayTestMode -ErrorAction SilentlyContinue
Write-Host "MPO -> on (default)"

$cs = Get-CimInstance Win32_ComputerSystem
Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile = $true} | Out-Null
Write-Host "Pagefile -> system managed"

Write-Host ""
Write-Host "Reverted. Reboot required."
Read-Host "Press Enter to close"
