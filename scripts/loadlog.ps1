$out = "$PSScriptRoot\loadlog_64gb.csv"
$apps = [ordered]@{
  maple  = @('MapleStory','BlackCipher64.aes')
  tft    = @('TFTClient-Win64-Shipping','LeagueClient','LeagueClientUx','LeagueClientUxRender','Riot Client','RiotClientServices','vgc')
  fconl  = @('fczf','NexonPlug','NexonLauncher64')
  chrome = @('chrome')
}
$engines = 'engtype_3D','engtype_VideoDecode','engtype_Copy','engtype_VideoProcessing','engtype_Compute'
$hdr = 'time,cpu_total,core_max,core_max_id,ram_pct,ram_gb,gpu_3D,gpu_VideoDecode,gpu_Copy,gpu_VideoProc,gpu_Compute,tft_ingame,pf_used_mb,pages_in'
foreach ($k in $apps.Keys) { $hdr += ",${k}_ram_mb,${k}_gpu" }
$hdr | Set-Content -Path $out -Encoding utf8

$end = (Get-Date).AddSeconds(270)
while ((Get-Date) -lt $end) {
  $cores = (Get-Counter '\Processor(*)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples
  $tot = ($cores | Where-Object InstanceName -eq '_total').CookedValue
  $per = $cores | Where-Object InstanceName -ne '_total' | Sort-Object CookedValue -Descending
  $os = Get-CimInstance Win32_OperatingSystem
  $ramUsed = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB
  $ramPct = $ramUsed / ($os.TotalVisibleMemorySize/1MB) * 100
  $pfUsed = 0
  $pfu = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
  if ($pfu) { $pfUsed = $pfu.CurrentUsage }
  $pin = 0
  $pc = (Get-Counter '\Memory\Pages Input/sec' -ErrorAction SilentlyContinue).CounterSamples
  if ($pc) { $pin = $pc[0].CookedValue }
  $ge = (Get-Counter '\GPU Engine(*)\Utilization Percentage' -ErrorAction SilentlyContinue).CounterSamples

  $row = '{0},{1:N1},{2:N1},{3},{4:N1},{5:N2}' -f (Get-Date -Format 'HH:mm:ss'),$tot,$per[0].CookedValue,$per[0].InstanceName,$ramPct,$ramUsed
  foreach ($e in $engines) {
    $v = 0; if ($ge) { $v = ($ge | Where-Object InstanceName -like "*$e*" | Measure-Object CookedValue -Sum).Sum }
    $row += ',{0:N1}' -f $v
  }
  $ingame = if (Get-Process -Name 'TFTClient-Win64-Shipping' -ErrorAction SilentlyContinue) { 1 } else { 0 }
  $row += ",$ingame,$pfUsed" + (',{0:N1}' -f $pin)

  foreach ($k in $apps.Keys) {
    $procs = Get-Process -Name $apps[$k] -ErrorAction SilentlyContinue
    $ram = 0; $g = 0
    if ($procs) {
      $ram = ($procs | Measure-Object WS -Sum).Sum / 1MB
      if ($ge) { foreach ($p in $procs) { $g += ($ge | Where-Object InstanceName -like "*pid_$($p.Id)_*" | Measure-Object CookedValue -Sum).Sum } }
    }
    $row += ',{0},{1:N1}' -f [int]$ram, $g
  }
  $row | Add-Content -Path $out -Encoding utf8
  Start-Sleep -Seconds 2
}
"DONE -> $out"
