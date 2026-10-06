# ban-helper.ps1 — DNS cache watcher: poison + SNI-reset detection
# Config: C:\ban-helper\ban-helper.env  (kendi değerlerini gir, repo'ya commit ETME)
$cfgFile = "C:\ban-helper\ban-helper.env"
if (Test-Path $cfgFile) { Get-Content $cfgFile | Where-Object { $_ -match '^\s*\$' } | Invoke-Expression }

$issdns  = $issdns  ?? "203.0.113.10"          # ISP poisoned resolver
$sshKey  = $sshKey  ?? "$env:USERPROFILE\.ssh\gateway-key"
$state   = $state   ?? "C:\ban-helper\state.txt"
$sshArgs = "ssh -p $sshPort -i $sshKey -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new $sshUser@$sshHost"
$done = @{}
if (Test-Path $state) { Get-Content $state | ForEach-Object { $done[$_.ToLower()] = 1 } }

# Tek instance:
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*ban-helper.ps1*' -and $_.ProcessId -ne $PID } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

function Ban-TR($domain) {
    ssh $sshArgs.Split(' ') "sudo $banCmd $domain" 2>$null
    $done[$domain] = 1
    Add-Content $state $domain
    Write-Host "$(Get-Date -Format 'HH:mm:ss') BANNED: $domain" -ForegroundColor Yellow
}

function Test-Site($domain) {
    try {
        $r = Resolve-DnsName $domain -Server $issdns -DnsOnly -QuickTimeout -ErrorAction Stop | Where-Object Type -eq 'A'
        $a = ($r | Select-Object -First 1).IPAddress
        foreach ($p in $poisonIps) { if ($a -eq $p) { return "poison" } }
    } catch { return "skip" }

    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $tcp.BeginConnect($domain, 443, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne(3000)) { return "down" }
        $tcp.EndConnect($iar)
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, { param($s,$c,$ch,$e) $true })
        $iar2 = $ssl.BeginAuthenticateAsClient($domain, $null, $null)   # PS 5.1: 3-arg!
        if (-not $iar2.AsyncWaitHandle.WaitOne(5000)) { return "blocked" }
        $ssl.EndAuthenticateAsClient($iar2)
        return "ok"
    } catch { return "reset" } finally { try { $tcp.Close() } catch {} }
}

Write-Host "ban-helper basladi" -ForegroundColor Cyan
while ($true) {
    try {
        $entries = Get-DnsClientCache | Select-Object -ExpandProperty Entry -Unique
        foreach ($raw in $entries) {
            $e = ($raw.ToLower()).TrimEnd('.')
            if ($done.ContainsKey($e)) { continue }
            if ($e -notmatch '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$') { $done[$e]=1; continue }
            switch (Test-Site $e) {
                "poison"  { Ban-TR $e }
                "blocked" { Ban-TR $e }
                "reset"   { Ban-TR $e }
                default   { $done[$e]=1; Add-Content $state $e }
            }
        }
    } catch {}
    Start-Sleep -Seconds 30
}
