# TARVOKA 3D Studio - local-only web server for the Godot WebGL export.
# No admin rights, internet connection, Python, npm, Node, or installation.
# Bind exclusively to Windows loopback: other devices cannot reach it.
param([switch]$NoBrowser)
$ErrorActionPreference = "Stop"
$Root = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
$RootPrefix = $Root + [System.IO.Path]::DirectorySeparatorChar
$Listener = $null
$Port = 8765

foreach ($TryPort in 8765..8775) {
    try {
        $Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $TryPort)
        $Listener.Start()
        $Port = $TryPort
        break
    } catch {
        if ($Listener -ne $null) { $Listener.Stop() }
        $Listener = $null
    }
}
if ($null -eq $Listener) {
    Write-Host "No hay un puerto libre entre 8765 y 8775." -ForegroundColor Red
    Read-Host "Pulsa Enter para salir"
    exit 1
}

$Mime = @{
    ".html"="text/html; charset=utf-8"
    ".js"="text/javascript; charset=utf-8"
    ".wasm"="application/wasm"
    ".pck"="application/octet-stream"
    ".png"="image/png"
    ".svg"="image/svg+xml"
    ".ico"="image/x-icon"
    ".json"="application/json"
    ".css"="text/css; charset=utf-8"
}
$WebUrl = "http://127.0.0.1:$Port/"
Write-Host ""
Write-Host "TARVOKA ESTUDIO 3D - VERSION PC" -ForegroundColor Cyan
Write-Host "Abre: $WebUrl" -ForegroundColor Green
Write-Host "El servidor es privado: solo accesible en esta computadora."
Write-Host "Manten esta ventana abierta mientras usas el Estudio."
Write-Host "Cierra con Ctrl+C."
Write-Host ""
if (-not $NoBrowser) { Start-Process $WebUrl }

try {
    while ($Listener.Server.IsBound) {
        $Client = $Listener.AcceptTcpClient()
        try {
            $Client.ReceiveTimeout = 15000
            $Client.SendTimeout = 15000
            $Stream = $Client.GetStream()
            $Reader = [System.IO.StreamReader]::new(
                $Stream,[System.Text.Encoding]::ASCII,$false,1024,$true)
            $FirstLine = $Reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($FirstLine)) { continue }
            while ($true) {
                $HeaderLine = $Reader.ReadLine()
                if ([string]::IsNullOrEmpty($HeaderLine)) { break }
            }
            $Fields = $FirstLine.Split(" ")
            if ($Fields.Length -lt 2) { continue }
            $Method = $Fields[0]
            $Raw = $Fields[1].Split("?")[0].Split("#")[0]
            $Relative = [Uri]::UnescapeDataString($Raw).TrimStart("/").Replace(
                "/",[System.IO.Path]::DirectorySeparatorChar)
            if ($Relative -eq "") { $Relative = "index.html" }
            $Path = [System.IO.Path]::GetFullPath((Join-Path $Root $Relative))
            $GoodPath = $Path.StartsWith($RootPrefix,
                [System.StringComparison]::OrdinalIgnoreCase)
            $Status = "200 OK"
            $Payload = [byte[]]@()
            $ContentType = "application/octet-stream"
            if (-not $GoodPath -or $Method -notin @("GET","HEAD")) {
                $Status = "403 Forbidden"
            } elseif (-not [System.IO.File]::Exists($Path)) {
                $Status = "404 Not Found"
            } else {
                $Payload = [System.IO.File]::ReadAllBytes($Path)
                $Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
                if ($Mime.ContainsKey($Extension)) { $ContentType = $Mime[$Extension] }
            }
            $Header = "HTTP/1.1 $Status`r`nContent-Type: $ContentType`r`nContent-Length: $($Payload.Length)`r`nCache-Control: no-store`r`nConnection: close`r`nX-Content-Type-Options: nosniff`r`n`r`n"
            $HeaderBytes = [System.Text.Encoding]::ASCII.GetBytes($Header)
            $Stream.Write($HeaderBytes,0,$HeaderBytes.Length)
            if ($Method -eq "GET" -and $Payload.Length -gt 0) {
                $Stream.Write($Payload,0,$Payload.Length)
            }
            $Stream.Flush()
        } catch {
            # A cancelled or stale browser request is not a game error.
        } finally {
            $Client.Close()
        }
    }
} finally {
    $Listener.Stop()
}
