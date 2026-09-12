# Check whether the four tweaks are still applied.
# No admin needed - read only.

function Line($n, $label, $actual, $want, $okText, $badText) {
    if ("$actual" -eq "$want") { $mark = "[OK]   $okText" } else { $mark = "[GONE] $badText" }
    "{0}. {1,-22} = {2,-14} {3}" -f $n, $label, $actual, $mark
}

""
"=== MapleStory tweak status ==="
""

$h = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -ErrorAction SilentlyContinue).HwSchMode
Line 1 "HAGS HwSchMode" $h 2 "on" "re-run fix.bat (driver reinstall resets this)"

$mpo = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -ErrorAction SilentlyContinue).OverlayTestMode
if ($null -eq $mpo) { $mpo = "(unset)" }
Line 2 "MPO OverlayTestMode" $mpo 5 "MPO off" "re-run fix.bat (Windows update resets this)"

$g = (Get-ItemProperty 'HKCU:\System\GameConfigStore' -ErrorAction SilentlyContinue).GameDVR_Enabled
Line 3 "GameDVR_Enabled" $g 0 "recording off" "re-run fix.bat"

$scheme = (powercfg /getactivescheme) -join ' '
if ($scheme -match '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') {
    "4. {0,-22} = {1,-14} {2}" -f "Power plan", "High perf", "[OK]   high performance"
} else {
    "4. {0,-22} = {1,-14} {2}" -f "Power plan", "NOT high", "[GONE] run: powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
}

""
"=== Memory (should show pagefile 0 if 64GB is working) ==="
$os = Get-CimInstance Win32_OperatingSystem
"RAM used : {0:N1} / {1:N1} GB" -f (($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB), ($os.TotalVisibleMemorySize/1MB)
Get-CimInstance Win32_PageFileUsage | ForEach-Object {
    "Pagefile : used $($_.CurrentUsage) MB / peak $($_.PeakUsage) MB  (0 = no swapping)"
}
""
Read-Host "Press Enter to close"
