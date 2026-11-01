# =====================================================================
#  PC-Telemetri.ps1
#  Gosterge paneli duvar kagidi icin sistem verisi saglar.
#  http://localhost:8765/  adresinden JSON verir:
#    cpu, ram, disk (yuzde), temp (C), netType, signal (Wi-Fi %), ssid,
#    online, ping (ms), down/up (MB/s), uptimeMin
#  Yonetici yetkisi gerekmez. Kapatmak icin: Gorev Yoneticisi > powershell
# =====================================================================

$Port = 8765

$LogFile = Join-Path $PSScriptRoot "telemetri-log.txt"
function Log($msg) { try { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg" | Out-File -FilePath $LogFile -Append -Encoding utf8 } catch {} }
if ((Test-Path $LogFile) -and ((Get-Item $LogFile).Length -gt 512KB)) { Remove-Item $LogFile -ErrorAction SilentlyContinue }

function New-Listener($prefixes) {
    $l = New-Object System.Net.HttpListener
    foreach ($p in $prefixes) { $l.Prefixes.Add($p) }
    $l.Start()
    return $l
}
$listener = $null
foreach ($set in @(@("http://localhost:$Port/", "http://127.0.0.1:$Port/"), @("http://localhost:$Port/"))) {
    try { $listener = New-Listener $set; Log "Dinleniyor: $($set -join ', ')"; break }
    catch { Log "Baslatilamadi ($($set -join ', ')): $($_.Exception.Message)" }
}
if (-not $listener) { Write-Host "Port $Port kullanilamiyor (script zaten calisiyor olabilir). Ayrinti: $LogFile"; exit 1 }

$pinger   = New-Object System.Net.NetworkInformation.Ping
$prevRx   = $null; $prevTx = $null; $prevAt = $null
$tempVal  = $null; $tempAt = [datetime]::MinValue
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$state    = @{}

# ---------------- Sicaklik ----------------
function Find-LhmTemp($node, $list) {
    if ($node.Text -match 'CPU Package|Tctl|Tdie|Core \(Tctl' -and "$($node.Value)" -match '^([\d\.,]+)\s*.?C$') {
        [void]$list.Add([double]($matches[1] -replace ',', '.'))
    }
    foreach ($c in $node.Children) { Find-LhmTemp $c $list }
}

function Get-CpuTemp {
    # 1) LibreHardwareMonitor web sunucusu (Options > Remote Web Server > Run)
    try {
        $j = Invoke-RestMethod -Uri "http://localhost:8085/data.json" -TimeoutSec 1 -ErrorAction Stop
        $list = New-Object System.Collections.ArrayList
        Find-LhmTemp $j $list
        if ($list.Count -gt 0) { return ($list | Measure-Object -Maximum).Maximum }
    } catch {}
    # 2) LibreHardwareMonitor / OpenHardwareMonitor WMI
    foreach ($ns in 'root/LibreHardwareMonitor', 'root/OpenHardwareMonitor') {
        try {
            $s = Get-CimInstance -Namespace $ns -ClassName Sensor -ErrorAction Stop |
                 Where-Object { $_.SensorType -eq 'Temperature' -and $_.Name -match 'CPU Package|Tctl|Tdie|Core' }
            if ($s) { return ($s | Measure-Object -Property Value -Maximum).Maximum }
        } catch {}
    }
    # 3) Windows ACPI termal bolgesi (bazi anakartlarda calisir)
    try {
        $t = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1
        if ($t -and $t.CurrentTemperature -gt 0) { return [math]::Round($t.CurrentTemperature / 10 - 273.15, 1) }
    } catch {}
    return $null
}

# ---------------- Ag ----------------
function Get-NetInfo {
    $r = @{ type = 'none'; signal = 0; ssid = $null }
    try {
        $out = netsh wlan show interfaces 2>$null
        $connected = $out | Select-String -Pattern '^\s*(State|Durum)\s*:\s*(connected|bagli|ba.l.)\s*$'
        $sig  = $out | Select-String -Pattern '^\s*(Signal|Sinyal)\s*:\s*%?\s*(\d+)\s*%?' | Select-Object -First 1
        $ssid = $out | Select-String -Pattern '^\s*SSID\s*:\s*(.+)$' | Select-Object -First 1
        if ($sig) {
            $r.type   = 'wifi'
            $r.signal = [int]$sig.Matches[0].Groups[2].Value
            if ($ssid) { $r.ssid = $ssid.Matches[0].Groups[1].Value.Trim() }
        }
    } catch {}
    if ($r.type -eq 'none') {
        try {
            $eth = Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' }
            if ($eth) { $r.type = 'ethernet'; $r.signal = 100; $r.ssid = $eth[0].Name }
        } catch {}
    }
    return $r
}

function Get-Ping {
    foreach ($h in '1.1.1.1', '8.8.8.8') {
        try { $p = $pinger.Send($h, 800); if ($p.Status -eq 'Success') { return [int]$p.RoundtripTime } } catch {}
    }
    return $null
}

# ---------------- Toplama ----------------
function Update-State {
    $now = Get-Date

    $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $os  = Get-CimInstance Win32_OperatingSystem
    $ram = 100 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize * 100)
    $c   = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    $disk = if ($c) { $c.Used / ($c.Used + $c.Free) * 100 } else { 0 }

    if (($now - $script:tempAt).TotalSeconds -ge 5) { $script:tempVal = Get-CpuTemp; $script:tempAt = $now }

    $net  = Get-NetInfo
    $ping = Get-Ping

    $down = 0; $up = 0
    try {
        $st = Get-NetAdapterStatistics -ErrorAction Stop
        $rx = ($st | Measure-Object -Property ReceivedBytes -Sum).Sum
        $tx = ($st | Measure-Object -Property SentBytes -Sum).Sum
        if ($script:prevAt) {
            $dt = ($now - $script:prevAt).TotalSeconds
            if ($dt -gt 0) {
                $down = [math]::Max(0, ($rx - $script:prevRx) / $dt / 1MB)
                $up   = [math]::Max(0, ($tx - $script:prevTx) / $dt / 1MB)
            }
        }
        $script:prevRx = $rx; $script:prevTx = $tx; $script:prevAt = $now
    } catch {}

    $script:state = [ordered]@{
        cpu       = [math]::Round([double]$cpu, 1)
        ram       = [math]::Round($ram, 1)
        disk      = [math]::Round($disk, 1)
        temp      = $script:tempVal
        netType   = $net.type
        signal    = $net.signal
        ssid      = $net.ssid
        online    = ($ping -ne $null)
        ping      = $ping
        down      = [math]::Round($down, 3)
        up        = [math]::Round($up, 3)
        uptimeMin = [math]::Round(($now - $bootTime).TotalMinutes, 1)
    }
}

function Send-State($ctx) {
    $json  = $script:state | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $res = $ctx.Response
    $res.Headers.Add("Access-Control-Allow-Origin", "*")
    $res.Headers.Add("Cache-Control", "no-store")
    $res.ContentType = "application/json; charset=utf-8"
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
}

Write-Host "PC-Telemetri calisiyor: http://localhost:$Port/"
try { Update-State; Log "Ilk veri: $($script:state | ConvertTo-Json -Compress)" } catch { Log "Ilk veri hatasi: $($_.Exception.Message)" }
$pending = $listener.GetContextAsync()

while ($listener.IsListening) {
    $until = (Get-Date).AddSeconds(2)
    while ((Get-Date) -lt $until) {
        if ($pending.Wait(200)) {
            try { Send-State $pending.Result } catch { Log "Gonderim hatasi: $($_.Exception.Message)" }
            $pending = $listener.GetContextAsync()
        }
    }
    try { Update-State } catch { Log "Veri toplama hatasi: $($_.Exception.Message)" }
}
