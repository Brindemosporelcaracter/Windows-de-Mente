$script = @'
# WINDOWS DE MENTE v1.0 - Ejecutar en PowerShell como Administrador

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nERROR: Ejecuta PowerShell como ADMINISTRADOR" -ForegroundColor Red
    exit
}

# Preguntas iniciales (Read-Host para consola abierta)
$choice = Read-Host "¿Dónde querés el log final? (1 = Consola, 2 = Escritorio) [Por defecto: 1]"
if ($choice -eq "2") { $logToDesktop = $true } else { $logToDesktop = $false }

$applyResp = Read-Host "¿Aplicar cambios al sistema? (S/N) [Por defecto: N]"
if ($applyResp -eq "S" -or $applyResp -eq "s") { $applyChanges = $true } else { $applyChanges = $false }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempLogDir = Join-Path -Path $env:TEMP -ChildPath "WindowsDeMente_Logs"
if (-not (Test-Path $tempLogDir)) { New-Item -Path $tempLogDir -ItemType Directory | Out-Null }
$logFileTemp = Join-Path $tempLogDir "WDM_Log_$timestamp.txt"

function Log {
    param([string]$text)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $text"
    Add-Content -Path $logFileTemp -Value $line
    Write-Host $text
}

Clear-Host
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "WINDOWS DE MENTE v1.0 - Optimización Consciente con Métricas" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Log "Inicio de Windows de Mente v1.0"

function Get-Metrics {
    $metrics = [ordered]@{}
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue

        $metrics.CPUUsage = if ($cpu -and $cpu.LoadPercentage -ne $null) { $cpu.LoadPercentage } else { 0 }
        $metrics.RAMFreeMB = if ($os -and $os.FreePhysicalMemory -ne $null) { [math]::Round($os.FreePhysicalMemory/1024,1) } else { 0 }
        $metrics.DiskFreeGB = if ($disk -and $disk.FreeSpace -ne $null) { [math]::Round($disk.FreeSpace/1GB,1) } else { 0 }
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue
        $metrics.NetworkLatencyMs = if ($ping) { [math]::Round(($ping | Measure-Object ResponseTime -Average).Average,1) } else { 0 }
    } catch {
        $metrics.CPUUsage = 0
        $metrics.RAMFreeMB = 0
        $metrics.DiskFreeGB = 0
        $metrics.NetworkLatencyMs = 0
    }
    return $metrics
}

Write-Host "`n[FASE 0] Métricas iniciales del sistema:" -ForegroundColor Yellow
$before = Get-Metrics
Log ("Métricas antes: CPU {0}%, RAM libre {1} MB, Disco libre {2} GB, Latencia red {3} ms" -f $before.CPUUsage, $before.RAMFreeMB, $before.DiskFreeGB, $before.NetworkLatencyMs)
Write-Host "  • CPU Uso: $($before.CPUUsage)%" -ForegroundColor DarkGray
Write-Host "  • RAM Libre: $($before.RAMFreeMB) MB" -ForegroundColor DarkGray
Write-Host "  • Disco Libre: $($before.DiskFreeGB) GB" -ForegroundColor DarkGray
Write-Host "  • Latencia Red: $($before.NetworkLatencyMs) ms" -ForegroundColor DarkGray

$cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $cpu) { $cpu = @{ NumberOfCores = 1; Name = "Desconocida" } }
$ramModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
$totalRAMGB = if ($ramModules) { [math]::Round(($ramModules | Measure-Object Capacity -Sum).Sum / 1GB, 1) } else { 0 }
$disco = $null
try { $disco = Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
$esSSD = $false
if ($disco -and $disco.MediaType) { $esSSD = ($disco.MediaType -match "SSD|NVMe") }
$diskType = if ($esSSD) { 'SSD' } else { 'HDD' }

Write-Host "`n[FASE 1] Hardware detectado:" -ForegroundColor Yellow
Write-Host "  • CPU: $($cpu.Name)" -ForegroundColor DarkGray
Write-Host "  • RAM total: $totalRAMGB GB" -ForegroundColor DarkGray
Write-Host "  • Disco: $diskType" -ForegroundColor DarkGray
Log ("Hardware detectado: CPU '{0}', RAM {1} GB, Disco: {2}" -f $cpu.Name, $totalRAMGB, $diskType)

$puntos = 0
if ($cpu.NumberOfCores -ge 8) { $puntos += 30 } elseif ($cpu.NumberOfCores -ge 6) { $puntos += 25 } elseif ($cpu.NumberOfCores -ge 4) { $puntos += 20 } else { $puntos += 10 }
if ($totalRAMGB -ge 16) { $puntos += 30 } elseif ($totalRAMGB -ge 8) { $puntos += 20 } else { $puntos += 10 }
if ($esSSD) { $puntos += 40 } else { $puntos += 15 }

if ($puntos -ge 85) {
    $categoria = "ENTUSIASTA"
} elseif ($puntos -ge 60) {
    $categoria = "EQUILIBRADO"
} elseif ($puntos -ge 40) {
    $categoria = "ESTÁNDAR"
} else {
    $categoria = "LIVIANO"
}

Write-Host "  • Categoría: $categoria (Score: $puntos/100)" -ForegroundColor Cyan
Log ("Categoria: {0} (Score {1})" -f $categoria, $puntos)

Write-Host "`n[FASE 2] Plan de energía..." -ForegroundColor Yellow
if ($applyChanges) {
    try {
        if ($categoria -eq "ENTUSIASTA") { $planGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" } else { $planGUID = "381b4222-f694-41f0-9685-ff5bb260df2e" }
        powercfg /setactive $planGUID | Out-Null
        Write-Host "  ✓ Plan de energía configurado" -ForegroundColor Green
        Log ("Plan de energía aplicado: {0}" -f $planGUID)
    } catch {
        Write-Host "  ⚠️ No se pudo cambiar plan de energía" -ForegroundColor Yellow
        Log ("Error cambiando plan de energía: {0}" -f $_.ToString())
    }
} else {
    Write-Host "  • Modo informe: plan de energía no modificado" -ForegroundColor DarkGray
    Log "Modo informe: plan de energía no modificado"
}

Write-Host "`n[FASE 3] Red (Ethernet / Wi‑Fi / Proxy)..." -ForegroundColor Yellow
try {
    $regRed = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    if (-not (Test-Path $regRed)) { New-Item -Path $regRed -Force | Out-Null }
    if ($applyChanges) {
        Set-ItemProperty -Path $regRed -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $regRed -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        netsh interface tcp set global autotuninglevel=normal | Out-Null
        netsh interface tcp set global congestionprovider=ctcp | Out-Null
        Write-Host "  ✓ Tweaks TCP aplicados" -ForegroundColor Green
        Log "Tweaks TCP aplicados"
    } else {
        Write-Host "  • Modo informe: tweaks TCP no aplicados" -ForegroundColor DarkGray
        Log "Modo informe: tweaks TCP no aplicados"
    }

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq "Up"}
    if ($adapters) {
        foreach ($adapter in $adapters) {
            Write-Host "  • Adaptador activo: $($adapter.Name) - $($adapter.InterfaceDescription)" -ForegroundColor DarkGray
            if ($adapter.InterfaceDescription -match "Wi-Fi|Wireless") {
                Write-Host "    → Wi‑Fi detectado" -ForegroundColor Cyan
            } elseif ($adapter.InterfaceDescription -match "Ethernet") {
                Write-Host "    → Ethernet detectado" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "  • No se detectaron adaptadores activos" -ForegroundColor DarkGray
    }

    $proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
    if ($proxy -and $proxy.ProxyEnable -eq 1) {
        Write-Host "  • Proxy detectado: $($proxy.ProxyServer)" -ForegroundColor Yellow
        Log ("Proxy detectado: {0}" -f $proxy.ProxyServer)
    } else {
        Write-Host "  • No se detectó proxy en usuario actual" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  ⚠️ Error detectando adaptadores de red" -ForegroundColor Yellow
    Log ("Error detectando adaptadores: {0}" -f $_.ToString())
}

Write-Host "`n[FASE 4] CPU..." -ForegroundColor Yellow
try {
    $regCPU = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    if (-not (Test-Path $regCPU)) { New-Item -Path $regCPU -Force | Out-Null }
    if ($cpu.NumberOfCores -ge 6) { $valorCPU = 36 } else { $valorCPU = 24 }
    if ($applyChanges) {
        Set-ItemProperty -Path $regCPU -Name "Win32PrioritySeparation" -Value $valorCPU -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✓ Win32PrioritySeparation ajustado a $valorCPU" -ForegroundColor Green
        Log ("Win32PrioritySeparation = {0}" -f $valorCPU)
    } else {
        Write-Host "  • Modo informe: Win32PrioritySeparation no modificado" -ForegroundColor DarkGray
        Log ("Modo informe: Win32PrioritySeparation no modificado; valor sugerido {0}" -f $valorCPU)
    }
} catch {
    Write-Host "  ⚠️ Error ajustando prioridad CPU" -ForegroundColor Yellow
    Log ("Error prioridad CPU: {0}" -f $_.ToString())
}

Write-Host "`n[FASE 5] Almacenamiento..." -ForegroundColor Yellow
try {
    $regPrefetch = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
    if (-not (Test-Path $regPrefetch)) { New-Item -Path $regPrefetch -Force | Out-Null }
    $valorPrefetch = if ($esSSD) { 0 } else { 3 }
    if ($applyChanges) {
        Set-ItemProperty -Path $regPrefetch -Name "EnablePrefetcher" -Value $valorPrefetch -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $regPrefetch -Name "EnableSuperfetch" -Value $valorPrefetch -Type DWord -ErrorAction SilentlyContinue
        if ($esSSD) {
            fsutil behavior set DisableDeleteNotify 0 | Out-Null
            try { Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue } catch {}
            Write-Host "  ✓ TRIM habilitado (SSD)" -ForegroundColor Green
            Log "TRIM habilitado"
        } else {
            try { Enable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue } catch {}
            Write-Host "  ✓ Desfragmentación programada habilitada (HDD)" -ForegroundColor Green
            Log "ScheduledDefrag habilitada"
        }
        Write-Host "  ✓ Prefetch/Superfetch ajustado (valor: $valorPrefetch)" -ForegroundColor Green
        Log ("Prefetch ajustado a {0}" -f $valorPrefetch)
    } else {
        Write-Host "  • Modo informe: ajustes de almacenamiento no aplicados" -ForegroundColor DarkGray
        Log "Modo informe: ajustes de almacenamiento no aplicados"
    }
} catch {
    Write-Host "  ⚠️ Error en optimización de almacenamiento" -ForegroundColor Yellow
    Log ("Error almacenamiento: {0}" -f $_.ToString())
}

Write-Host "`n[FASE 6] Servicios..." -ForegroundColor Yellow
$delayedCandidates = @("WSearch","SysMain","OneSyncSvc")
foreach ($svc in $delayedCandidates) {
    try {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            if ($applyChanges) {
                Set-Service -Name $svc -StartupType AutomaticDelayedStart -ErrorAction SilentlyContinue
                Write-Host "  ✓ Servicio puesto en AutomaticDelayedStart: $svc" -ForegroundColor Green
                Log ("Servicio {0} puesto en AutomaticDelayedStart" -f $svc)
            } else {
                Write-Host "  • Modo informe: servicio no modificado: $svc" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "  • Servicio no encontrado: $svc" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  ⚠️ Error ajustando servicio $svc" -ForegroundColor Yellow
        Log ("Error servicio {0}: {1}" -f $svc, $_.ToString())
    }
}
try { ipconfig /flushdns | Out-Null; Write-Host "  ✓ Cache DNS limpiada" -ForegroundColor Green; Log "DNS flush" } catch {}

Write-Host "`n[FASE 7] Programas de inicio..." -ForegroundColor Yellow
$backupKeyHKCU = "HKCU:\Software\WindowsDeMente\Backup\Run"
$backupKeyHKLM = "HKLM:\Software\WindowsDeMente\Backup\Run"
if (-not (Test-Path $backupKeyHKCU)) { New-Item -Path $backupKeyHKCU -Force | Out-Null }
if (-not (Test-Path $backupKeyHKLM)) { New-Item -Path $backupKeyHKLM -Force | Out-Null }

function Backup-And-Remove-RunValue {
    param([string]$rootPath,[string]$valueName)
    try {
        $item = Get-ItemProperty -Path $rootPath -ErrorAction SilentlyContinue
        if (-not $item) { return $false }
        $value = $null
        if ($item.PSObject.Properties.Name -contains $valueName) { $value = $item.$valueName }
        if ($null -ne $value) {
            if ($rootPath -like "HKCU:*") { $dest = $backupKeyHKCU } else { $dest = $backupKeyHKLM }
            if (-not (Test-Path $dest)) { New-Item -Path $dest -Force | Out-Null }
            New-ItemProperty -Path $dest -Name $valueName -Value $value -Force | Out-Null
            Remove-ItemProperty -Path $rootPath -Name $valueName -ErrorAction SilentlyContinue
            Log ("Movido '{0}' de '{1}' a backup" -f $valueName, $rootPath)
            return $true
        } else { return $false }
    } catch {
        Log ("Error moviendo '{0}' de '{1}': {2}" -f $valueName, $rootPath, $_.ToString())
        return $false
    }
}

function Get-RunValueNames { param([string]$path) $names = @(); try { $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue; if ($props) { $names = $props.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } | Select-Object -ExpandProperty Name } } catch {}; return $names }

$hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (Test-Path $hkcuRun) {
    $vals = Get-RunValueNames -path $hkcuRun
    foreach ($v in $vals) {
        if ($v -match "Update|Updater|GoogleUpdate|AdobeARM|OneDriveSetup|Spotify|Steam") {
            if ($applyChanges) {
                if (Backup-And-Remove-RunValue -rootPath $hkcuRun -valueName $v) { Write-Host "  ✓ Startup movido (HKCU): $v" -ForegroundColor Green } else { Write-Host "  ⚠️ No se pudo mover (HKCU): $v" -ForegroundColor Yellow }
            } else {
                Write-Host "  • Modo informe: startup detectado (HKCU): $v" -ForegroundColor DarkGray
            }
        } else { Write-Host "  • Mantener startup (HKCU): $v" -ForegroundColor DarkGray }
    }
} else { Write-Host "  • HKCU Run no existe" -ForegroundColor DarkGray }

$hklmRun = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
if (Test-Path $hklmRun) {
    $vals = Get-RunValueNames -path $hklmRun
    foreach ($v in $vals) {
        if ($v -match "Update|Updater|GoogleUpdate|AdobeARM|OneDriveSetup|Spotify|Steam") {
            if ($applyChanges) {
                if (Backup-And-Remove-RunValue -rootPath $hklmRun -valueName $v) { Write-Host "  ✓ Startup movido (HKLM): $v" -ForegroundColor Green } else { Write-Host "  ⚠️ No se pudo mover (HKLM): $v" -ForegroundColor Yellow }
            } else {
                Write-Host "  • Modo informe: startup detectado (HKLM): $v" -ForegroundColor DarkGray
            }
        } else { Write-Host "  • Mantener startup (HKLM): $v" -ForegroundColor DarkGray }
    }
} else { Write-Host "  • HKLM Run no existe" -ForegroundColor DarkGray }

Write-Host "`n[FASE 7.5] Inicio y Apagado" -ForegroundColor Yellow
$backupReg = "HKLM:\Software\WindowsDeMente\Backup\Shutdown"
if (-not (Test-Path $backupReg)) { New-Item -Path $backupReg -Force | Out-Null }

function Backup-ShutdownValues {
    $keys = @(
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control";Name="WaitToKillServiceTimeout"},
        @{Path="HKCU:\Control Panel\Desktop";Name="WaitToKillAppTimeout"},
        @{Path="HKCU:\Control Panel\Desktop";Name="HungAppTimeout"},
        @{Path="HKCU:\Control Panel\Desktop";Name="AutoEndTasks"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power";Name="HiberbootEnabled"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management";Name="ClearPageFileAtShutdown"}
    )
    foreach ($k in $keys) {
        try {
            $val = (Get-ItemProperty -Path $k.Path -Name $k.Name -ErrorAction SilentlyContinue).$($k.Name)
            if ($null -eq $val) { $val = "" }
            New-ItemProperty -Path $backupReg -Name ($k.Name) -Value $val -Force | Out-Null
        } catch {}
    }
    Log "Backup de valores de inicio/apagado guardado en $backupReg"
}

function Apply-ShutdownOptimizations {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "5000" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "1000" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value "1" -ErrorAction SilentlyContinue

    $fastStartupReg = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    if (-not (Test-Path $fastStartupReg)) { New-Item -Path $fastStartupReg -Force | Out-Null }
    if ($esSSD) {
        Set-ItemProperty -Path $fastStartupReg -Name "HiberbootEnabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Log "Fast Startup habilitado (SSD)"
    } else {
        Set-ItemProperty -Path $fastStartupReg -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Log "Fast Startup deshabilitado (HDD)"
    }

    Log "Valores de inicio/apagado aplicados (moderados)."
}

function Restore-ShutdownValues {
    try {
        $props = Get-ItemProperty -Path $backupReg -ErrorAction SilentlyContinue
        if ($props) {
            foreach ($p in $props.PSObject.Properties) {
                $name = $p.Name
                $val = $p.Value
                switch ($name) {
                    "WaitToKillServiceTimeout" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name $name -Value $val -ErrorAction SilentlyContinue }
                    "WaitToKillAppTimeout" { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name $name -Value $val -ErrorAction SilentlyContinue }
                    "HungAppTimeout" { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name $name -Value $val -ErrorAction SilentlyContinue }
                    "AutoEndTasks" { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name $name -Value $val -ErrorAction SilentlyContinue }
                    "HiberbootEnabled" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name $name -Value $val -ErrorAction SilentlyContinue }
                    "ClearPageFileAtShutdown" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name $name -Value $val -ErrorAction SilentlyContinue }
                }
            }
            Log "Valores de inicio/apagado restaurados desde backup."
        } else {
            Log "No se encontró backup para restaurar."
        }
    } catch {
        Log ("Error restaurando valores: {0}" -f $_.ToString())
    }
}

if ($applyChanges) {
    Backup-ShutdownValues
    Apply-ShutdownOptimizations
} else {
    Log "Modo informe: no se aplicaron cambios de inicio/apagado"
}

Write-Host "`n[FASE 8] Interfaz y experiencia..." -ForegroundColor Yellow
try {
    if ($applyChanges) {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "100" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MinAnimate" -Value "0" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value "0" -ErrorAction SilentlyContinue
        Write-Host "  ✓ Ajustes UI aplicados" -ForegroundColor Green
        Log "Ajustes UI aplicados"
    } else {
        Write-Host "  • Modo informe: ajustes UI no aplicados" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  ⚠️ Error aplicando ajustes UI" -ForegroundColor Yellow
    Log ("Error UI: {0}" -f $_.ToString())
}

Write-Host "`n[FASE 9] Memoria virtual..." -ForegroundColor Yellow
try {
    if ($applyChanges -and $totalRAMGB -lt 8 -and $totalRAMGB -gt 0) {
        $min = [math]::Round($totalRAMGB * 1024 * 1.5)
        $max = [math]::Round($totalRAMGB * 1024 * 3)
        try { wmic pagefileset where name="C:\\pagefile.sys" delete > $null 2>&1 } catch {}
        try {
            wmic pagefileset create name="C:\\pagefile.sys" InitialSize=$min MaximumSize=$max > $null 2>&1
            Write-Host "  ✓ Pagefile ajustado a Min:${min}MB Max:${max}MB" -ForegroundColor Green
            Log ("Pagefile personalizado: Min {0}MB Max {1}MB" -f $min, $max)
        } catch {
            Write-Host "  ⚠️ No se pudo ajustar pagefile con wmic; se deja administrado por sistema" -ForegroundColor Yellow
            Log ("Error pagefile wmic: {0}" -f $_.ToString())
        }
    } else {
        Write-Host "  • Pagefile: no modificado (modo informe o RAM suficiente)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  ⚠️ Error ajustando memoria virtual" -ForegroundColor Yellow
    Log ("Error memoria virtual: {0}" -f $_.ToString())
}

Write-Host "`n[FASE 10] Verificación básica de Windows Update..." -ForegroundColor Yellow
try {
    $wuSvc = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    if ($wuSvc -and $wuSvc.Status -ne "Running") {
        if ($applyChanges) { Start-Service wuauserv -ErrorAction SilentlyContinue; Write-Host "  ✓ Windows Update activado" -ForegroundColor Green; Log "Windows Update activado" } else { Write-Host "  • Windows Update no modificado (modo informe)" -ForegroundColor DarkGray }
    } else {
        Write-Host "  • Windows Update ya activo" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  ⚠️ No se pudo verificar Windows Update" -ForegroundColor Yellow
    Log ("Error Windows Update: {0}" -f $_.ToString())
}

Write-Host "`n[FASE FINAL] Métricas después de optimización:" -ForegroundColor Yellow
$after = Get-Metrics
Log ("Métricas después: CPU {0}%, RAM libre {1} MB, Disco libre {2} GB, Latencia red {3} ms" -f $after.CPUUsage, $after.RAMFreeMB, $after.DiskFreeGB, $after.NetworkLatencyMs)
Write-Host "  • CPU Uso: $($after.CPUUsage)%" -ForegroundColor DarkGray
Write-Host "  • RAM Libre: $($after.RAMFreeMB) MB" -ForegroundColor DarkGray
Write-Host "  • Disco Libre: $($after.DiskFreeGB) GB" -ForegroundColor DarkGray
Write-Host "  • Latencia Red: $($after.NetworkLatencyMs) ms" -ForegroundColor DarkGray

$deltaCPU = $after.CPUUsage - $before.CPUUsage
$deltaRAM = $after.RAMFreeMB - $before.RAMFreeMB
$deltaDisk = $after.DiskFreeGB - $before.DiskFreeGB
$deltaPing = $after.NetworkLatencyMs - $before.NetworkLatencyMs

$improvements = @()
if ($applyChanges) {
    $improvements += "Se movieron entradas de autostart sospechosas a backup (menos procesos al arranque)."
    $improvements += "Se pusieron servicios no críticos en delayed start (menos carga al inicio sin deshabilitar servicios)."
    $improvements += "Se ajustó prioridad de CPU y parámetros TCP (mejor respuesta en multitarea y conexiones compatibles)."
    if ($esSSD) { $improvements += "TRIM habilitado y desfragmentación programada deshabilitada (mejor rendimiento y vida útil del SSD)." } else { $improvements += "Desfragmentación programada habilitada para HDD (mejor rendimiento en accesos secuenciales con el tiempo)." }
    $improvements += "Ajustes de inicio/apagado: timeouts reducidos y Fast Startup condicional (arranque/apagado más rápidos según hardware)."
    if ($totalRAMGB -lt 8 -and $totalRAMGB -gt 0) { $improvements += "Pagefile ajustado para compensar RAM limitada (mejor estabilidad en multitarea)." } else { $improvements += "Pagefile administrado por sistema (óptimo para sistemas con RAM suficiente)." }
    $improvements += "Se limpiaron caché DNS y se aplicaron tweaks TCP globales."
} else {
    $improvements += "Modo informe: no se aplicaron cambios. Ejecutá el script y elegí 'S' en la pregunta para aplicar optimizaciones."
}

$summaryLines = @()
$summaryLines += "═══════════════════════════════════════════════════════════════"
$summaryLines += "Resumen Windows de Mente v1.0 - $timestamp"
$summaryLines += "Hardware: $($cpu.Name) | RAM total: $totalRAMGB GB | Disco: $diskType"
$summaryLines += "Categoria: $categoria (Score $puntos)"
$summaryLines += "Métricas antes: CPU $($before.CPUUsage)%, RAM libre $($before.RAMFreeMB) MB, Disco libre $($before.DiskFreeGB) GB, Latencia $($before.NetworkLatencyMs) ms"
$summaryLines += "Métricas después: CPU $($after.CPUUsage)%, RAM libre $($after.RAMFreeMB) MB, Disco libre $($after.DiskFreeGB) GB, Latencia $($after.NetworkLatencyMs) ms"
$summaryLines += ("Deltas: CPU {0}% ; RAM {1} MB ; Disco {2} GB ; Latencia {3} ms" -f $deltaCPU, $deltaRAM, $deltaDisk, $deltaPing)
$summaryLines += ""
$summaryLines += "¿Por qué debería sentirse mejor tu equipo?"
foreach ($imp in $improvements) { $summaryLines += "  • $imp" }
$summaryLines += ""
$summaryLines += "Log temporal: $logFileTemp"
$summaryLines += "═══════════════════════════════════════════════════════════════"

Add-Content -Path $logFileTemp -Value ($summaryLines -join "`r`n")
Log "Resumen agregado al log temporal"

# Intentar copiar log al Escritorio del usuario o al Escritorio público; si falla, mantener en TEMP
$logName = "WindowsDeMente_Log_$timestamp.txt"
$userDesktop = $null
try { $userDesktop = [Environment]::GetFolderPath("Desktop") } catch {}
$publicDesktop = $null
try { $publicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory") } catch {}

$wrote = $false
if ($logToDesktop -and $userDesktop) {
    $finalUserLog = Join-Path $userDesktop $logName
    try {
        Copy-Item -Path $logFileTemp -Destination $finalUserLog -Force
        foreach ($line in $summaryLines) { Write-Host $line }
        Write-Host ""
        Write-Host "Optimización completada - Log guardado en el Escritorio:" -ForegroundColor Green
        Write-Host " $finalUserLog" -ForegroundColor White
        Log ("Log final copiado a Escritorio de usuario: {0}" -f $finalUserLog)
        $wrote = $true
    } catch {
        Log ("No se pudo copiar log al Escritorio de usuario: {0}" -f $_.ToString())
    }
}

if (-not $wrote -and $logToDesktop -and $publicDesktop) {
    $finalPublicLog = Join-Path $publicDesktop $logName
    try {
        Copy-Item -Path $logFileTemp -Destination $finalPublicLog -Force
        foreach ($line in $summaryLines) { Write-Host $line }
        Write-Host ""
        Write-Host "Optimización completada - Log guardado en el Escritorio público:" -ForegroundColor Green
        Write-Host " $finalPublicLog" -ForegroundColor White
        Log ("Log final copiado a Escritorio público: {0}" -f $finalPublicLog)
        $wrote = $true
    } catch {
        Log ("No se pudo copiar log al Escritorio público: {0}" -f $_.ToString())
    }
}

if (-not $wrote) {
    foreach ($line in $summaryLines) { Write-Host $line }
    Write-Host ""
    Write-Host "Optimización completada - Resumen final mostrado arriba." -ForegroundColor Green
    Write-Host "Log temporal: $logFileTemp" -ForegroundColor DarkGray
    Log "Resumen mostrado en consola; log mantenido en temporal"
}

# Guardar marcador para medir boot si se reinicia
$bootMarker = Join-Path $tempLogDir "WDM_boot_marker_$timestamp.txt"
try { Set-Content -Path $bootMarker -Value (Get-Date).ToString("o") -Encoding UTF8 } catch {}

# Preguntar reinicio solo si se aplicaron cambios
if ($applyChanges) {
    $resp = Read-Host "`nReiniciar ahora para aplicar todos los cambios? (S/N) [Por defecto: N]"
    if ($resp -eq "S" -or $resp -eq "s") {
        Write-Host "`nReiniciando en 10 segundos... (Ctrl+C para cancelar)" -ForegroundColor Yellow
        for ($i = 10; $i -gt 0; $i--) { Write-Host "  $i..." -ForegroundColor Gray; Start-Sleep -Seconds 1 }
        Restart-Computer -Force
    } else {
        Write-Host "`nReinicia manualmente cuando puedas. Los cambios estarán activos tras reinicio." -ForegroundColor Cyan
    }
} else {
    Write-Host "`nNo se aplicaron cambios. Ejecutá el script y elegí 'S' para aplicar optimizaciones." -ForegroundColor Cyan
}

Log "Fin de ejecución"
Write-Host ""
'@

$path = Join-Path $env:TEMP "WindowsDeMente_v1.0.ps1"
Set-Content -Path $path -Value $script -Encoding UTF8
Write-Host "Se creó el archivo temporal: $path"
Write-Host "Ejecutando el script desde el archivo temporal..."
& $path
