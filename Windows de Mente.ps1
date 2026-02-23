<#
.SYNOPSIS
    Windows de Mente v1.0 - Diagnóstico + Optimización 
.DESCRIPTION
    FASE 0: Análisis completo de hardware, configuración y runtime
    FASE 1: Generación de fixes basados en diagnóstico
    FASE 2: Optimización automática con punto de restauración
    Requiere confirmación del usuario para reiniciar
.NOTES
    Versión: 1.0.0 (Con todas las correcciones)
    Autor: Windows de Mente
#>

#requires -RunAsAdministrator
#requires -Version 5.0

# [CONFIGURACIÓN GLOBAL] =====================================================
$ErrorActionPreference = "Stop"
$script:Report = @()
$script:Issues = @()
$script:Fixes = @()
$script:Environment = @{}
$script:StartTime = Get-Date

# [LISTAS BLANCAS Y CONSTANTES] ===============================================
$coreServices = @(
    'RpcSs', 'DcomLaunch', 'EventLog', 'Winmgmt', 'Dhcp',
    'BFE', 'MpsSvc', 'mpssvc', 'LanmanWorkstation', 'SamSs', 'Schedule',
    'Power', 'UserManager', 'WinDefend', 'WSearch', 'Spooler',
    'WpnService', 'Wcmsvc', 'ProfSvc', 'Themes', 'AudioSrv',
    'AudioEndpointBuilder', 'WlanSvc', 'NlaSvc', 'Dnscache',
    'SysMain', 'WdiServiceHost', 'wscsvc', 'SecurityHealthService',
    'RpcEptMapper', 'PlugPlay', 'BrokerInfrastructure', 'DPS',
    'SystemEventsBroker', 'TimeBrokerSvc', 'FontCache', 'sppsvc',
    'LicenseManager', 'gpsvc', 'TrkWks', 'BITS', 'CryptSvc',
    'DusmSvc', 'LSM', 'NcbService', 'PcaSvc', 'StateRepository',
    'StorSvc', 'TabletInputService', 'UsoSvc', 'VaultSvc',
    'WaaSMedicSvc', 'WEPHOSTSVC', 'WerSvc', 'wisvc'
)

$severityMap = @{
    "CRITICO"     = "🔴"
    "GRAVE"       = "🟠"
    "MODERADO"    = "🟡"
    "INFORMATIVO" = "🔵"
    "OPTIMIZADO"  = "✅"
    "HUERFANO_POTENCIAL" = "⚠️"
}

# [FUNCIONES AUXILIARES] =====================================================

function Add-Report {
    param(
        [string]$Category,
        [string]$Key,
        [string]$Value,
        [string]$Status = "OK",
        [string]$Recommendation = "",
        [string]$Severity = "INFORMATIVO"
    )
    
    if ($null -eq $Value) { $Value = "" }
    
    $script:Report += [PSCustomObject]@{
        Category = $Category
        Key = $Key
        Value = $Value
        Status = $Status
        Severity = $Severity
        Icon = $severityMap[$Severity]
        Recommendation = $Recommendation
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    if ($Status -ne "OK" -and $Status -ne "INFORMATIVO" -and $Status -ne "SERVICIO_CORE" -and $Status -ne "HUERFANO_POTENCIAL") {
        $script:Issues += [PSCustomObject]@{
            Category = $Category
            Key = $Key
            CurrentValue = $Value
            Issue = $Status
            Severity = $Severity
            Icon = $severityMap[$Severity]
            Suggestion = $Recommendation
        }
    }
}

function Add-Fix {
    param(
        [string]$Category,
        [string]$Key,
        [string]$Fix,
        [string]$Value,
        [string]$Status = "PENDIENTE"
    )
    
    $script:Fixes += [PSCustomObject]@{
        Category = $Category
        Key = $Key
        Fix = $Fix
        Value = $Value
        Status = $Status
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Test-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$ExpectedValue = $null,
        [scriptblock]$ValidationScript = $null
    )
    
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        $actualValue = $value.$Name
        
        if ($ValidationScript) {
            $result = & $ValidationScript $actualValue
            return @{
                Exists = $true
                Value = $actualValue
                Valid = $result.Valid
                Issue = $result.Issue
                Recommendation = $result.Recommendation
            }
        }
        elseif ($ExpectedValue -ne $null) {
            return @{
                Exists = $true
                Value = $actualValue
                Valid = ($actualValue -eq $ExpectedValue)
                Issue = if ($actualValue -ne $ExpectedValue) { "Valor incorrecto" } else { $null }
                Recommendation = if ($actualValue -ne $ExpectedValue) { "Debería ser $ExpectedValue" } else { $null }
            }
        }
        else {
            return @{
                Exists = $true
                Value = $actualValue
                Valid = $true
                Issue = $null
                Recommendation = $null
            }
        }
    }
    catch {
        return @{
            Exists = $false
            Value = $null
            Valid = $false
            Issue = "No existe en registro"
            Recommendation = "Considerar crear con valor por defecto"
        }
    }
}

function SafeToString {
    param($InputObject)
    if ($null -eq $InputObject) { return "" }
    try { return $InputObject.ToString().Trim() } catch { return "" }
}

function Extract-ExecutablePath {
    param([string]$CommandLine)
    
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return $null }
    
    $expanded = [System.Environment]::ExpandEnvironmentVariables($CommandLine)
    
    if ($expanded -match 'rundll32\.exe\s+"([^"]+\.dll)"') { return $matches[1] }
    if ($expanded -match 'cmd\.exe\s+/c\s+"([^"]+\.exe)"') { return $matches[1] }
    if ($expanded -match '"([^"]+\.exe)"') { return $matches[1] }
    if ($expanded -match '([A-Za-z]:\\[^" ]+\.exe)') { return $matches[1] }
    if ($expanded -match '([a-zA-Z0-9_]+\.exe)\b') {
        $exe = $matches[1]
        $found = Get-Command $exe -ErrorAction SilentlyContinue
        if ($found) { return $found.Source }
        return $exe
    }
    
    return $null
}

function Test-IsSSD {
    param([int]$DiskNumber)
    
    $phys = Get-PhysicalDisk -DeviceNumber $DiskNumber -ErrorAction SilentlyContinue
    if ($phys.MediaType -eq 3) { return $true }
    
    $ctrl = Get-WmiObject Win32_SCSIController | Where-Object { $_.Name -match "NVMe|AHCI" }
    if ($ctrl) { return $true }
    
    return $false
}

function New-RestorePoint {
    Write-Host "`n💾 Creando punto de restauración..." -ForegroundColor Cyan
    
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Windows de Mente v1.0 - Pre-optimización" -RestorePointType MODIFY_SETTINGS
        Write-Host "  ✅ Punto de restauración creado exitosamente" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ⚠️  No se pudo crear punto de restauración: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Get-CPUTemperature {
    try {
        $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue
        if ($temp -and $temp.CurrentTemperature -gt 2732) {
            $celsius = [math]::Round(($temp.CurrentTemperature - 2732) / 10, 1)
            return @{ Value = $celsius; Source = "WMI"; Valid = $true }
        }
        return @{ Value = "No disponible"; Source = "N/A"; Valid = $false }
    }
    catch {
        return @{ Value = "No disponible"; Source = "Error"; Valid = $false }
    }
}

function Test-DriverSigning {
    param([string]$DriverName, [string]$DriverPath)
    
    try {
        if (-not $DriverPath -or -not (Test-Path $DriverPath)) {
            return "Archivo no encontrado"
        }
        $signature = Get-AuthenticodeSignature -FilePath $DriverPath -ErrorAction SilentlyContinue
        if ($signature -and $signature.Status -eq "Valid") {
            return "Firmado"
        } elseif ($signature -and $signature.Status -eq "NotSigned") {
            return "No firmado"
        } else {
            return "Firma no verificada"
        }
    } catch {
        return "Error al verificar"
    }
}

function Get-DefenderImpact {
    try {
        $proc = Get-Process MsMpEng -ErrorAction SilentlyContinue
        if (-not $proc) { return $null }
        
        $cpuCounter = Get-Counter '\Process(MsMpEng)\% Processor Time' -ErrorAction SilentlyContinue
        $cpuNow = if ($cpuCounter) { [math]::Round($cpuCounter.CounterSamples.CookedValue, 1) } else { 0 }
        
        $mem = [math]::Round($proc.WorkingSet / 1MB, 1)
        
        return @{ CPU = $cpuNow; RAM = $mem }
    } catch {
        return $null
    }
}

# [DETECCIÓN DE ENTORNO] =====================================================

function Test-Environment {
    Write-Host "`n🔍 [00] Detectando entorno..." -ForegroundColor Cyan
    
    try {
        $cs = Get-WmiObject Win32_ComputerSystem
        $script:Environment.PartOfDomain = $cs.PartOfDomain
        $script:Environment.Domain = if ($cs.PartOfDomain) { $cs.Domain } else { "WORKGROUP" }
        
        $proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
        $script:Environment.HasProxy = [bool]($proxy.ProxyServer)
        $script:Environment.ProxyServer = if ($proxy.ProxyServer) { $proxy.ProxyServer } else { "No configurado" }
        
        $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
               Where-Object {$_.ServerAddresses -and $_.InterfaceAlias -notlike "*Loopback*"}
        $script:Environment.HasStaticDNS = ($dns | Where-Object {$_.ConnectionSpecificSuffix -eq $script:Environment.Domain}).Count -gt 0
        
        $script:Environment.IsCorpNetwork = $script:Environment.PartOfDomain -or $script:Environment.HasProxy
        
        Add-Report -Category "ENTORNO" -Key "Tipo" -Value $(if ($script:Environment.IsCorpNetwork) { "Corporativo" } else { "Personal" }) -Status "ENTORNO_RED" -Severity "INFORMATIVO"
        Add-Report -Category "ENTORNO" -Key "Dominio" -Value $script:Environment.Domain -Status "ENTORNO_RED" -Severity "INFORMATIVO"
        
        if ($script:Environment.IsCorpNetwork) {
            Write-Host "  ⚠️  Entorno corporativo detectado - Tests de red limitados" -ForegroundColor Yellow
        }
    }
    catch {
        Add-Report -Category "ENTORNO" -Key "Error" -Value "No se pudo detectar entorno" -Status "ERROR" -Severity "INFORMATIVO"
    }
}

# [BLOQUE 01: HARDWARE BASE] ==================================================

function Test-HardwareBase {
    Write-Host "`n🔍 [01] Analizando hardware base..." -ForegroundColor Cyan
    
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
        Add-Report -Category "HARDWARE" -Key "CPU" -Value "$($cpu.Name) | Cores: $($cpu.NumberOfCores) | Threads: $($cpu.NumberOfLogicalProcessors) | Max: $($cpu.MaxClockSpeed) MHz"
    } catch { Add-Report -Category "HARDWARE" -Key "CPU" -Value "Error" -Status "ERROR" -Severity "INFORMATIVO" }
    
    try {
        $ram = Get-CimInstance Win32_PhysicalMemory
        $totalRAM = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
        Add-Report -Category "HARDWARE" -Key "RAM" -Value "$([math]::Round($totalRAM,2)) GB"
        
        if ($totalRAM -lt 4) {
            Add-Report -Category "HARDWARE" -Key "RAM" -Value "$([math]::Round($totalRAM,2)) GB" -Status "LIMITACION_FISICA" -Severity "INFORMATIVO" -Recommendation "RAM extremadamente baja - Windows será muy lento"
        } elseif ($totalRAM -lt 8) {
            Add-Report -Category "HARDWARE" -Key "RAM" -Value "$([math]::Round($totalRAM,2)) GB" -Status "LIMITACION_FISICA" -Severity "INFORMATIVO" -Recommendation "RAM insuficiente para uso moderno - considerar ampliar"
        }
    } catch { Add-Report -Category "HARDWARE" -Key "RAM" -Value "Error" -Status "ERROR" -Severity "INFORMATIVO" }
    
    try {
        $disks = Get-PhysicalDisk
        $hasSSD = $false
        foreach ($disk in $disks) {
            $diskType = if ($disk.MediaType -eq 4) { "HDD" } elseif ($disk.MediaType -eq 3) { "SSD" } else { "Unknown" }
            if ($diskType -eq "SSD") { $hasSSD = $true }
            Add-Report -Category "HARDWARE" -Key "DISCO_$($disk.FriendlyName)" -Value "$diskType | $([math]::Round($disk.Size/1GB,2)) GB"
        }
        if (-not $hasSSD) {
            Add-Report -Category "HARDWARE" -Key "SISTEMA" -Value "Sin SSD detectado" -Status "LIMITACION_FISICA" -Severity "INFORMATIVO" -Recommendation "SSD recomendado para mejor rendimiento"
        }
    } catch { Add-Report -Category "HARDWARE" -Key "DISKS" -Value "Error" -Status "ERROR" -Severity "INFORMATIVO" }
}

# [BLOQUE 02: ERRORES CRÍTICOS] ===============================================

function Test-CriticalErrors {
    Write-Host "`n🔍 [02] Buscando errores críticos..." -ForegroundColor Cyan
    
    try {
        $whea = Get-WinEvent -FilterHashtable @{LogName='System'; ID=47,18; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue
        if ($whea) {
            Add-Report -Category "ERRORES" -Key "WHEA" -Value "$($whea.Count) errores en 24h" -Status "WHEA_ERROR" -Severity "CRITICO" -Recommendation "Posible problema de hardware - Revisar Event Viewer"
        }
    } catch {}
    
    try {
        $ntfs = fsutil dirty query C: 2>$null
        if ($ntfs -match "sucio") {
            Add-Report -Category "ERRORES" -Key "NTFS" -Value "Disco C: sucio" -Status "NTFS_DIRTY" -Severity "CRITICO" -Recommendation "Ejecutar chkdsk /f C:"
        }
    } catch {}
    
    try {
        $badDrivers = Get-WmiObject Win32_SystemDriver | Where-Object { $_.State -ne "Running" -and $_.StartMode -eq "Auto" }
        foreach ($drv in $badDrivers) {
            Add-Report -Category "ERRORES" -Key "Driver_$($drv.Name)" -Value "$($drv.DisplayName) no carga" -Status "DRIVER_ERROR" -Severity "GRAVE" -Recommendation "Reinstalar driver"
        }
    } catch {}
}

# [BLOQUE 03: CPU AVANZADO] ===================================================

function Test-CPUAdvanced {
    Write-Host "`n🔍 [03] Analizando CPU avanzado..." -ForegroundColor Cyan
    
    $temp = Get-CPUTemperature
    if ($temp.Valid) {
        Add-Report -Category "CPU" -Key "Temperatura" -Value "$($temp.Value) °C (fuente: $($temp.Source))"
        if ($temp.Value -gt 85) {
            Add-Report -Category "CPU" -Key "Temperatura" -Value "$($temp.Value) °C" -Status "TEMP_CRITICA" -Severity "CRITICO" -Recommendation "Temperatura crítica - Revisar cooling"
        } elseif ($temp.Value -gt 75) {
            Add-Report -Category "CPU" -Key "Temperatura" -Value "$($temp.Value) °C" -Status "TEMP_ALTA" -Severity "GRAVE" -Recommendation "Temperatura alta - Limpiar cooler"
        }
    } else {
        Add-Report -Category "CPU" -Key "Temperatura" -Value "No medible por software" -Status "INFORMATIVO" -Recommendation "Usar HWMonitor para temperatura real"
    }
    
    try {
        $perf = Get-Counter '\Processor Information(_total)\% Processor Performance' -ErrorAction SilentlyContinue
        if ($perf) {
            $freqPercent = [math]::Round($perf.CounterSamples.CookedValue, 1)
            Add-Report -Category "CPU" -Key "Frecuencia" -Value "$freqPercent% de máxima"
            if ($freqPercent -lt 50) {
                Add-Report -Category "CPU" -Key "Throttling" -Value "$freqPercent%" -Status "THROTTLING" -Severity "GRAVE" -Recommendation "CPU throttling activo - Posible sobrecalentamiento"
            }
        }
    } catch {}
    
    try {
        $dpcs = Get-Counter '\Processor Information(_total)\DPC Rate' -ErrorAction SilentlyContinue
        if ($dpcs) {
            $dpcRate = [math]::Round($dpcs.CounterSamples.CookedValue, 0)
            Add-Report -Category "CPU" -Key "DPC" -Value "$dpcRate DPC/seg"
            if ($dpcRate -gt 1000) {
                Add-Report -Category "CPU" -Key "DPC" -Value "$dpcRate DPC/seg" -Status "DPC_ALTO" -Severity "GRAVE" -Recommendation "Drivers causando alta latencia - Revisar red/audio"
            }
        }
        
        $wptPath = "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit"
        if (Test-Path $wptPath) {
            Add-Report -Category "CPU" -Key "DPC_Profiling" -Value "WPT disponible para análisis DPC detallado" -Status "INFORMATIVO"
        }
    } catch {}
    
    try {
        $parking = powercfg /query 2>$null | Select-String "Core Parking"
        if ($parking) {
            Add-Report -Category "CPU" -Key "CoreParking" -Value "Configurado" -Status "INFORMATIVO"
        }
    } catch {}
}

# [BLOQUE 04: MEMORIA AVANZADA] ===============================================

function Test-MemoryAdvanced {
    Write-Host "`n🔍 [04] Analizando memoria avanzada..." -ForegroundColor Cyan
    
    try {
        $faults = Get-Counter '\Memory\Page Faults/sec' -ErrorAction SilentlyContinue
        if ($faults) {
            $hardFaults = [math]::Round($faults.CounterSamples.CookedValue, 0)
            Add-Report -Category "MEMORIA" -Key "HardFaults" -Value "$hardFaults pg/seg"
            
            if ($hardFaults -gt 100) {
                Add-Report -Category "MEMORIA" -Key "HardFaults" -Value "$hardFaults pg/seg" -Status "HARD_FAULTS_ALTOS" -Severity "GRAVE" -Recommendation "Hard faults muy altos - Síntoma de RAM insuficiente"
            } elseif ($hardFaults -gt 50) {
                Add-Report -Category "MEMORIA" -Key "HardFaults" -Value "$hardFaults pg/seg" -Status "HARD_FAULTS_MODERADOS" -Severity "MODERADO" -Recommendation "Hard faults elevados - Posible falta de RAM"
            }
        }
    } catch {}
    
    try {
        $commit = Get-Counter '\Memory\Commit Limit' -ErrorAction SilentlyContinue
        $commitUsed = Get-Counter '\Memory\Committed Bytes' -ErrorAction SilentlyContinue
        if ($commit -and $commitUsed) {
            $limit = [math]::Round($commit.CounterSamples.CookedValue / 1GB, 2)
            $used = [math]::Round($commitUsed.CounterSamples.CookedValue / 1GB, 2)
            $percent = [math]::Round(($used / $limit) * 100, 1)
            Add-Report -Category "MEMORIA" -Key "Commit" -Value "$used GB / $limit GB ($percent%)"
            
            if ($percent -gt 90) {
                Add-Report -Category "MEMORIA" -Key "Commit" -Value "$percent%" -Status "COMMIT_ALTO" -Severity "CRITICO" -Recommendation "Commit charge crítico - Aumentar pagefile"
            }
        }
    } catch {}
    
    try {
        $pool = Get-Counter '\Memory\Pool Nonpaged Bytes' -ErrorAction SilentlyContinue
        if ($pool) {
            $poolMB = [math]::Round($pool.CounterSamples.CookedValue / 1MB, 2)
            Add-Report -Category "MEMORIA" -Key "PoolNonPaged" -Value "$poolMB MB"
            
            if ($poolMB -gt 500) {
                Add-Report -Category "MEMORIA" -Key "PoolNonPaged" -Value "$poolMB MB" -Status "POOL_ALTO" -Severity "MODERADO" -Recommendation "Non-paged pool alto - Posible leak de driver"
            }
        }
    } catch {}
}

# [BLOQUE 05: DISCO AVANZADO] =================================================

function Test-DiskAdvanced {
    Write-Host "`n🔍 [05] Analizando disco avanzado..." -ForegroundColor Cyan
    
    try {
        $queue = Get-Counter '\LogicalDisk(*)\Current Disk Queue Length' -ErrorAction SilentlyContinue
        if ($queue) {
            $avgQueue = ($queue.CounterSamples | Where-Object {$_.CookedValue -gt 0} | Measure-Object -Property CookedValue -Average).Average
            Add-Report -Category "DISCO" -Key "QueueLength" -Value "$([math]::Round($avgQueue,2))"
            
            if ($avgQueue -gt 2) {
                Add-Report -Category "DISCO" -Key "QueueLength" -Value "$([math]::Round($avgQueue,2))" -Status "QUEUE_ALTA" -Severity "GRAVE" -Recommendation "Cola de disco alta - Posible bottleneck"
            }
        }
    } catch {}
    
    try {
        $busy = Get-Counter '\LogicalDisk(*)\% Disk Time' -ErrorAction SilentlyContinue
        if ($busy) {
            $avgBusy = ($busy.CounterSamples | Where-Object {$_.CookedValue -gt 0} | Measure-Object -Property CookedValue -Average).Average
            Add-Report -Category "DISCO" -Key "DiskBusy" -Value "$([math]::Round($avgBusy,1))%"
            
            if ($avgBusy -gt 90) {
                Add-Report -Category "DISCO" -Key "DiskBusy" -Value "$([math]::Round($avgBusy,1))%" -Status "DISK_SATURADO" -Severity "GRAVE" -Recommendation "Disco saturado"
            }
        }
    } catch {}
    
    try {
        $writes = Get-Counter '\LogicalDisk(*)\Disk Writes/sec' -ErrorAction SilentlyContinue
        if ($writes) {
            $totalWrites = ($writes.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum
            Add-Report -Category "DISCO" -Key "Escrituras" -Value "$([math]::Round($totalWrites/1024,2)) MB/s"
        }
    } catch {}
    
    $volumes = Get-Volume | Where-Object DriveType -eq 'Fixed'
    foreach ($vol in $volumes) {
        if ($vol.DriveLetter) {
            try {
                $trimStatus = fsutil fsInfo ntfsInfo "$($vol.DriveLetter):\" 2>$null | Select-String "TRIM"
                $hasSSD = Test-IsSSD -DiskNumber (Get-Partition -DriveLetter $vol.DriveLetter | Select-Object -ExpandProperty DiskNumber)
                
                if ($hasSSD -and -not $trimStatus) {
                    Add-Report -Category "DISCO" -Key "TRIM_$($vol.DriveLetter)" -Value "Deshabilitado en $($vol.DriveLetter):" -Status "TRIM_DESACTIVADO" -Severity "GRAVE" -Recommendation "Habilitar TRIM para SSD"
                }
            } catch {}
        }
    }
}

# [BLOQUE 06: RED AVANZADA - POR INTERFAZ] ====================================

function Test-NetworkAdvanced {
    Write-Host "`n🔍 [06] Analizando red avanzada..." -ForegroundColor Cyan
    
    try {
        $adapters = Get-NetAdapter | Where-Object Status -eq "Up"
        foreach ($ad in $adapters) {
            Add-Report -Category "RED" -Key "Adaptador_$($ad.Name)" -Value "$($ad.LinkSpeed) | $($ad.FullDuplex)" -Severity "INFORMATIVO"
            
            $driver = Get-NetAdapterDriver -Name $ad.Name -ErrorAction SilentlyContinue
            if ($driver) {
                $driverDate = $driver.DriverDate
                Add-Report -Category "RED" -Key "Driver_$($ad.Name)" -Value $driverDate -Severity "INFORMATIVO"
                
                if ((Get-Date) - $driverDate -gt (New-TimeSpan -Days 365)) {
                    Add-Report -Category "RED" -Key "Driver_$($ad.Name)" -Value $driverDate -Status "DRIVER_VIEJO" -Severity "MODERADO" -Recommendation "Driver de red desactualizado"
                }
            }
            
            $ifGuid = $ad.InterfaceGuid
            $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$ifGuid"
            
            $tcpNoDelay = Get-ItemProperty -Path $ifPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
            if ($tcpNoDelay -and $tcpNoDelay.TCPNoDelay -eq 0) {
                Add-Report -Category "RED" -Key "Nagle_$($ad.Name)" -Value "Habilitado (TCPNoDelay=0)" -Status "NAGLE_ACTIVO" -Severity "MODERADO" -Recommendation "Nagle activo - Puede aumentar latencia"
            }
            
            $tcpAck = Get-ItemProperty -Path $ifPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
            if ($tcpAck -and $tcpAck.TcpAckFrequency -eq 1) {
                Add-Report -Category "RED" -Key "AckFreq_$($ad.Name)" -Value "$($tcpAck.TcpAckFrequency)" -Status "ACK_FRECUENTE" -Severity "MODERADO" -Recommendation "ACKs muy frecuentes - Aumentar a 2"
            }
        }
    } catch {}
    
    try {
        $autotuning = netsh int tcp show global 2>$null | Select-String "Receive Window Auto-Tuning"
        if ($autotuning -match "disabled") {
            Add-Report -Category "RED" -Key "AutoTuning" -Value "Deshabilitado" -Status "AUTOTUNING_OFF" -Severity "MODERADO" -Recommendation "Auto-tuning deshabilitado - Limita throughput"
        }
    } catch {}
    
    if (-not $script:Environment.IsCorpNetwork) {
        try {
            $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop
            if ($gateway) {
                $ping = Test-Connection $gateway -Count 5 -ErrorAction SilentlyContinue
                if ($ping) {
                    $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
                    $loss = (($ping | Where-Object {$_.Status -ne "Success"}).Count) * 20
                    Add-Report -Category "RED" -Key "Latencia_Gateway" -Value "$([math]::Round($avgLatency,1)) ms"
                    
                    if ($avgLatency -gt 100) {
                        Add-Report -Category "RED" -Key "Latencia_Gateway" -Value "$([math]::Round($avgLatency,1)) ms" -Status "LATENCIA_ALTA" -Severity "MODERADO" -Recommendation "Latencia alta a gateway"
                    }
                    
                    Add-Report -Category "RED" -Key "Perdida_Gateway" -Value "$loss%"
                    if ($loss -gt 5) {
                        Add-Report -Category "RED" -Key "Perdida_Gateway" -Value "$loss%" -Status "PERDIDA_ALTA" -Severity "GRAVE" -Recommendation "Pérdida de paquetes - Revisar conexión"
                    }
                }
            }
        } catch {}
    }
}

# [BLOQUE 07: SERVICIOS CON TRIGGER DETECTION] ===============================

function Test-Services {
    Write-Host "`n🔍 [07] Analizando servicios..." -ForegroundColor Cyan
    
    try {
        $services = Get-WmiObject Win32_Service -ErrorAction Stop
        
        foreach ($svc in $services) {
            if ($svc.Name -in $coreServices) {
                Add-Report -Category "SERVICIOS" -Key "Service_$($svc.Name)" -Value "$($svc.DisplayName) - CORE" -Status "SERVICIO_CORE" -Severity "INFORMATIVO"
                continue
            }
            
            $exePath = Extract-ExecutablePath $svc.PathName
            if ($exePath -and $svc.StartMode -eq "Auto") {
                $fullPath = if ([System.IO.Path]::IsPathRooted($exePath)) {
                    $exePath
                } else {
                    $found = Get-Command $exePath -ErrorAction SilentlyContinue
                    if ($found) { $found.Source } else { $exePath }
                }
                
                if (-not (Test-Path $fullPath -ErrorAction SilentlyContinue)) {
                    Add-Report -Category "SERVICIOS" -Key "Broken_$($svc.Name)" -Value "$($svc.DisplayName) - Posible huérfano" -Status "HUERFANO_POTENCIAL" -Severity "MODERADO" -Recommendation "Verificar manualmente antes de deshabilitar"
                }
            }
            
            $triggers = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$($svc.Name)\TriggerInfo" -ErrorAction SilentlyContinue
            if ($svc.StartMode -eq "Auto" -and $svc.State -ne "Running" -and -not $triggers) {
                Add-Report -Category "SERVICIOS" -Key "ServiceState_$($svc.Name)" -Value "$($svc.DisplayName) - Auto pero $($svc.State)" -Status "ESTADO_INCOHERENTE" -Severity "MODERADO" -Recommendation "Verificar dependencias"
            }
        }
    } catch {}
}

# [BLOQUE 08: TAREAS PROGRAMADAS] =============================================

function Test-ScheduledTasks {
    Write-Host "`n🔍 [08] Analizando tareas programadas..." -ForegroundColor Cyan
    
    $systemPaths = @("\Microsoft\Windows", "\Microsoft\Windows\Update", "\Microsoft\Windows\Maintenance")
    
    try {
        $allTasks = Get-ScheduledTask -ErrorAction SilentlyContinue
        
        foreach ($task in $allTasks) {
            $isSystemTask = $false
            foreach ($path in $systemPaths) {
                if ($task.TaskPath -like "$path*") { $isSystemTask = $true; break }
            }
            
            if (-not $isSystemTask) {
                foreach ($action in $task.Actions) {
                    if ($action.Execute) {
                        $exePath = Extract-ExecutablePath $action.Execute
                        if ($exePath) {
                            $fullPath = if ([System.IO.Path]::IsPathRooted($exePath)) {
                                $exePath
                            } else {
                                $found = Get-Command $exePath -ErrorAction SilentlyContinue
                                if ($found) { $found.Source } else { $exePath }
                            }
                            
                            if (-not (Test-Path $fullPath -ErrorAction SilentlyContinue)) {
                                Add-Report -Category "TAREAS" -Key "Orphan_$($task.TaskName)" -Value "Ejecutable no encontrado" -Status "HUERFANO_POTENCIAL" -Severity "MODERADO" -Recommendation "Verificar si el software asociado está instalado"
                            }
                        }
                    }
                }
            }
        }
    } catch {}
}

# [BLOQUE 09: RESTOS DE SOFTWARE] =============================================

function Test-SoftwareRemnants {
    Write-Host "`n🔍 [09] Analizando restos de software..." -ForegroundColor Cyan
    
    $runPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )
    
    foreach ($path in $runPaths) {
        try {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($items) {
                $items.PSObject.Properties | Where-Object { $_.MemberType -eq "NoteProperty" } | ForEach-Object {
                    $exePath = Extract-ExecutablePath $_.Value
                    if ($exePath) {
                        $fullPath = if ([System.IO.Path]::IsPathRooted($exePath)) {
                            $exePath
                        } else {
                            $found = Get-Command $exePath -ErrorAction SilentlyContinue
                            if ($found) { $found.Source } else { $exePath }
                        }
                        
                        if (-not (Test-Path $fullPath -ErrorAction SilentlyContinue)) {
                            Add-Report -Category "RESTOS" -Key "Run_$($_.Name)" -Value "Entrada huérfana" -Status "HUERFANO_POTENCIAL" -Severity "MODERADO" -Recommendation "Eliminar entrada manualmente si el software ya no existe"
                        }
                    }
                }
            }
        } catch {}
    }
}

# [BLOQUE 10: BOOT] ===========================================================

function Test-Boot {
    Write-Host "`n🔍 [10] Analizando configuración de boot..." -ForegroundColor Cyan
    
    try {
        $fastStart = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue).HiberbootEnabled
        $hasSSD = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object MediaType -eq 3
        $isLaptop = (Get-CimInstance Win32_SystemEnclosure).ChassisTypes -match "8|9|10|11|12|14|18|21|30|31|32"
        
        Add-Report -Category "BOOT" -Key "FastStartup" -Value $(if ($fastStart -eq 1) { "Habilitado" } else { "Deshabilitado" })
        
        if ($fastStart -eq 1 -and $hasSSD -and -not $isLaptop) {
            Add-Report -Category "BOOT" -Key "FastStartup" -Value "Habilitado en SSD Desktop" -Status "INFORMATIVO" -Recommendation "En desktop con SSD, fast startup no es necesario pero tampoco daña. Decisión personal."
        }
    } catch {}
    
    try {
        $timeout = bcdedit /enum 2>$null | Select-String "timeout"
        if ($timeout -match "(\d+)") {
            $bootTimeout = [int]$matches[1]
            Add-Report -Category "BOOT" -Key "Timeout" -Value "$bootTimeout seg"
            
            if ($bootTimeout -gt 30) {
                Add-Report -Category "BOOT" -Key "Timeout" -Value "$bootTimeout seg" -Status "TIMEOUT_ALTO" -Severity "MODERADO" -Recommendation "Reducir timeout a 10-15 segundos"
            }
        }
    } catch {}
}

# [BLOQUE 11: DRIVERS] ========================================================

function Test-Drivers {
    Write-Host "`n🔍 [11] Analizando drivers..." -ForegroundColor Cyan
    
    try {
        $drivers = Get-WmiObject Win32_SystemDriver | Where-Object { $_.State -eq "Running" }
        foreach ($drv in $drivers) {
            $signStatus = Test-DriverSigning -DriverName $drv.Name -DriverPath $drv.PathName
            if ($signStatus -eq "No firmado") {
                Add-Report -Category "DRIVERS" -Key "NoFirmado_$($drv.Name)" -Value "$($drv.DisplayName)" -Status "DRIVER_NO_FIRMADO" -Severity "MODERADO" -Recommendation "Driver sin firma digital - Considerar actualizar"
            }
        }
    } catch {}
    
    try {
        $legacy = Get-WmiObject Win32_SystemDriver | Where-Object { $_.Description -match "legacy|legado" }
        foreach ($drv in $legacy) {
            Add-Report -Category "DRIVERS" -Key "Legacy_$($drv.Name)" -Value "$($drv.DisplayName)" -Status "DRIVER_LEGACY" -Severity "INFORMATIVO" -Recommendation "Driver en modo legado - Buscar versión moderna si es necesario"
        }
    } catch {}
}

# [BLOQUE 12: WINDOWS CONFIG] =================================================

function Test-WindowsConfig {
    Write-Host "`n🔍 [12] Analizando configuración de Windows..." -ForegroundColor Cyan
    
    try {
        $telemetry = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -ErrorAction SilentlyContinue
        $telemetryLevel = if ($telemetry) { $telemetry.AllowTelemetry } else { 3 }
        Add-Report -Category "CONFIG" -Key "Telemetria" -Value "Nivel $telemetryLevel"
        
        if ($telemetryLevel -gt 1) {
            Add-Report -Category "CONFIG" -Key "Telemetria" -Value "Nivel $telemetryLevel" -Status "TELEMETRIA_ALTA" -Severity "INFORMATIVO" -Recommendation "Valor por defecto de Windows. Reducir si preocupa privacidad."
        }
    } catch {}
    
    $defender = Get-DefenderImpact
    if ($defender) {
        Add-Report -Category "CONFIG" -Key "Defender" -Value "CPU: $($defender.CPU)% | RAM: $($defender.RAM) MB"
        if ($defender.CPU -gt 20) {
            Add-Report -Category "CONFIG" -Key "Defender" -Value "CPU $($defender.CPU)%" -Status "DEFENDER_ACTIVO" -Severity "INFORMATIVO" -Recommendation "Defender escaneando - Programar scan en horario inactivo"
        }
    }
    
    try {
        $search = Get-Process SearchIndexer -ErrorAction SilentlyContinue
        if ($search) {
            $cpuSearch = [math]::Round($search.CPU, 1)
            $memSearch = [math]::Round($search.WorkingSet / 1MB, 1)
            Add-Report -Category "CONFIG" -Key "Indexador" -Value "CPU: $cpuSearch% | RAM: $memSearch MB"
            
            if ($cpuSearch -gt 10) {
                Add-Report -Category "CONFIG" -Key "Indexador" -Value "CPU $cpuSearch%" -Status "INDEXADOR_ACTIVO" -Severity "INFORMATIVO" -Recommendation "Indexador reconstruyendo índice - Normal tras actualizaciones"
            }
        }
    } catch {}
}

# [BLOQUE 13: RUNTIME AVANZADO] ===============================================

function Test-RuntimeAdvanced {
    Write-Host "`n🔍 [13] Analizando runtime avanzado..." -ForegroundColor Cyan
    
    $samples = 3
    $sampleInterval = 1
    
    $cpuSamples = @()
    for ($i = 1; $i -le $samples; $i++) {
        $cpu = Get-Counter '\Processor(_total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($cpu) { $cpuSamples += [math]::Round($cpu.CounterSamples.CookedValue, 1) }
        if ($i -lt $samples) { Start-Sleep -Seconds $sampleInterval }
    }
    $avgCPU = if ($cpuSamples) { ($cpuSamples | Measure-Object -Average).Average } else { 0 }
    Add-Report -Category "RUNTIME" -Key "CPU_Actual" -Value "$([math]::Round($avgCPU,1))%"
    
    if ($avgCPU -gt 80) {
        Add-Report -Category "RUNTIME" -Key "CPU_Actual" -Value "$([math]::Round($avgCPU,1))%" -Status "CPU_ALTO" -Severity "GRAVE" -Recommendation "CPU consistentemente alto - Revisar procesos"
    }
    
    try {
        $highCPU = Get-Process | Where-Object { $_.CPU -gt 20 } | Select-Object -ExpandProperty ProcessName -Unique
        if ($highCPU) {
            Add-Report -Category "RUNTIME" -Key "Procesos_CPU" -Value "$($highCPU -join ', ')" -Status "PROCESOS_ALTOS" -Severity "MODERADO" -Recommendation "Revisar procesos con alto CPU"
        }
    } catch {}
    
    try {
        $highRAM = Get-Process | Where-Object { $_.WorkingSet -gt 500MB } | Select-Object -ExpandProperty ProcessName -Unique
        if ($highRAM) {
            Add-Report -Category "RUNTIME" -Key "Procesos_RAM" -Value "$($highRAM -join ', ')" -Status "PROCESOS_ALTOS" -Severity "MODERADO" -Recommendation "Revisar procesos con alto consumo RAM"
        }
    } catch {}
}

# [FASE 1 - GENERAR FIXES] ====================================================

function Generate-Fixes {
    Write-Host "`n🔧 [FASE 1] Generando fixes basados en diagnóstico..." -ForegroundColor Cyan
    
    foreach ($issue in $script:Issues) {
        switch ($issue.Key) {
            "NTFS" { 
                if ($issue.CurrentValue -match "sucio") {
                    Add-Fix -Category $issue.Category -Key $issue.Key -Fix "chkdsk /f C:" -Value $issue.CurrentValue
                }
            }
            "TRIM_*" { 
                if ($issue.Status -eq "TRIM_DESACTIVADO") {
                    Add-Fix -Category $issue.Category -Key $issue.Key -Fix "fsutil behavior set DisableDeleteNotify 0" -Value $issue.CurrentValue
                }
            }
            "Nagle_*" { 
                if ($issue.Status -eq "NAGLE_ACTIVO") {
                    $ifGuid = $issue.Key -replace "Nagle_", ""
                    $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$ifGuid"
                    Add-Fix -Category $issue.Category -Key $issue.Key -Fix "Set-ItemProperty -Path '$ifPath' -Name TCPNoDelay -Value 1" -Value $issue.CurrentValue
                }
            }
            "AckFreq_*" { 
                if ($issue.Status -eq "ACK_FRECUENTE") {
                    $ifGuid = $issue.Key -replace "AckFreq_", ""
                    $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$ifGuid"
                    Add-Fix -Category $issue.Category -Key $issue.Key -Fix "Set-ItemProperty -Path '$ifPath' -Name TcpAckFrequency -Value 2" -Value $issue.CurrentValue
                }
            }
            "AutoTuning" { 
                if ($issue.Status -eq "AUTOTUNING_OFF") {
                    Add-Fix -Category $issue.Category -Key $issue.Key -Fix "netsh int tcp set global autotuninglevel=normal" -Value $issue.CurrentValue
                }
            }
            "Timeout" { 
                if ($issue.Status -eq "TIMEOUT_ALTO") {
                    Add-Fix -Category $issue.Category -Key $issue.Key -Fix "bcdedit /timeout 10" -Value $issue.CurrentValue
                }
            }
        }
    }
    
    Write-Host "  ✅ Generados $($script:Fixes.Count) fixes" -ForegroundColor Green
}

# [RESUMEN EJECUTIVO] =========================================================

function Show-ExecutiveSummary {
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "║                 WINDOWS DE MENTE v1.0 - DIAGNÓSTICO COMPLETO                ║" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "="*80 -ForegroundColor Cyan
    
    $critical = $script:Issues | Where-Object { $_.Severity -eq "CRITICO" }
    $grave = $script:Issues | Where-Object { $_.Severity -eq "GRAVE" }
    $moderate = $script:Issues | Where-Object { $_.Severity -eq "MODERADO" }
    $info = $script:Report | Where-Object { $_.Status -in @("LIMITACION_FISICA", "ENTORNO_RED", "SERVICIO_CORE", "INFORMATIVO") }
    
    Write-Host "`n📋 RESUMEN EJECUTIVO - PROBLEMAS DETECTADOS:" -ForegroundColor Yellow
    Write-Host "-"*60
    
    if ($critical) {
        Write-Host "`n🔴 CRÍTICOS (deben corregirse antes de continuar):" -ForegroundColor Red
        foreach ($i in $critical) {
            Write-Host "  ❌ $($i.Category) - $($i.Key)" -ForegroundColor Red
            Write-Host "     → $($i.Suggestion)" -ForegroundColor White
        }
    }
    
    if ($grave) {
        Write-Host "`n🟠 GRAVES (afectan rendimiento significativamente):" -ForegroundColor DarkYellow
        foreach ($i in $grave) {
            Write-Host "  ⚠️  $($i.Category) - $($i.Key)" -ForegroundColor DarkYellow
            Write-Host "     → $($i.Suggestion)" -ForegroundColor White
        }
    }
    
    if ($moderate) {
        Write-Host "`n🟡 MODERADOS (optimizables):" -ForegroundColor Yellow
        foreach ($i in $moderate) {
            Write-Host "  ⚡ $($i.Category) - $($i.Key)" -ForegroundColor Yellow
            Write-Host "     → $($i.Suggestion)" -ForegroundColor White
        }
    }
    
    if ($info) {
        Write-Host "`n🔵 INFORMATIVOS (limitaciones/entorno):" -ForegroundColor Blue
        foreach ($i in $info) {
            Write-Host "  ℹ️  $($i.Category) - $($i.Key): $($i.Value)" -ForegroundColor Blue
        }
    }
    
    Write-Host "`n" + "="*60
    Write-Host "📊 ESTADÍSTICAS:" -ForegroundColor Cyan
    Write-Host "  🔴 Críticos: $($critical.Count)" -ForegroundColor Red
    Write-Host "  🟠 Graves: $($grave.Count)" -ForegroundColor DarkYellow
    Write-Host "  🟡 Moderados: $($moderate.Count)" -ForegroundColor Yellow
    Write-Host "  🔵 Informativos: $($info.Count)" -ForegroundColor Blue
    Write-Host "  ✅ Total checks: $($script:Report.Count)" -ForegroundColor Green
}

# [FASE 2 - OPTIMIZACIÓN] =====================================================

function Start-Optimization {
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "║                 FASE 2: OPTIMIZACIÓN AUTOMÁTICA                            ║" -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "="*80 -ForegroundColor Cyan
    
    if ($script:Fixes.Count -eq 0) {
        Write-Host "`n✅ No hay optimizaciones pendientes." -ForegroundColor Green
        return $false
    }
    
    $restorePoint = New-RestorePoint
    
    Write-Host "`n📋 SE APLICARÁN LAS SIGUIENTES OPTIMIZACIONES:" -ForegroundColor Yellow
    Write-Host "-"*60
    
    foreach ($fix in $script:Fixes) {
        $issue = $script:Issues | Where-Object { $_.Key -eq $fix.Key } | Select-Object -First 1
        $icon = if ($issue) { $issue.Icon } else { "⚙️" }
        Write-Host "  $icon $($fix.Category) - $($fix.Key)" -ForegroundColor White
        Write-Host "     Comando: $($fix.Fix)" -ForegroundColor Gray
    }
    
    Write-Host "`n"
    $confirm = Read-Host "¿Aplicar estas optimizaciones? (S/N)"
    
    if ($confirm -ne "S" -and $confirm -ne "s") {
        Write-Host "`n⏸️  Optimización cancelada por el usuario." -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "`n⚙️  Aplicando optimizaciones..." -ForegroundColor Cyan
    
    $successCount = 0
    $failCount = 0
    
    foreach ($fix in $script:Fixes) {
        try {
            Write-Host "  → Aplicando: $($fix.Fix)" -ForegroundColor Gray
            Invoke-Expression $fix.Fix | Out-Null
            $fix.Status = "EXITOSO"
            $successCount++
        }
        catch {
            Write-Host "     ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            $fix.Status = "FALLIDO"
            $failCount++
        }
    }
    
    Write-Host "`n📊 RESULTADO OPTIMIZACIÓN:" -ForegroundColor Cyan
    Write-Host "  ✅ Exitosas: $successCount" -ForegroundColor Green
    Write-Host "  ❌ Fallidas: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
    
    return $true
}

# [CONFIRMACIÓN REINICIO] =====================================================

function Confirm-Reboot {
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "║                 OPTIMIZACIÓN COMPLETADA                                     ║" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "="*80 -ForegroundColor Cyan
    
    Write-Host "`n⏱️  Tiempo total de ejecución: $([math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 1)) minutos" -ForegroundColor Yellow
    
    $pendingFixes = $script:Fixes | Where-Object { $_.Status -eq "PENDIENTE" }
    if ($pendingFixes) {
        Write-Host "`n⚠️  Quedaron $($pendingFixes.Count) optimizaciones sin aplicar." -ForegroundColor Yellow
    }
    
    Write-Host "`n🔄 Algunos cambios requieren reinicio para aplicarse completamente." -ForegroundColor Cyan
    $reboot = Read-Host "`n¿Reiniciar ahora? (S/N)"
    
    if ($reboot -eq "S" -or $reboot -eq "s") {
        Write-Host "`n🔄 Reiniciando en 10 segundos..." -ForegroundColor Green
        shutdown /r /t 10 /c "Windows de Mente v1.0 - Reinicio para aplicar optimizaciones"
    } else {
        Write-Host "`n✅ Proceso completado. Reinicie manualmente para aplicar todos los cambios." -ForegroundColor Green
    }
}

# [MAIN] ======================================================================

Clear-Host
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     WINDOWS DE MENTE v1.0 - DIAGNÓSTICO + OPTIMIZACIÓN      ║
║                                                              ║
║     • FASE 0: Diagnóstico completo (15-20 min)              ║
║     • FASE 1: Generación de fixes                           ║
║     • FASE 2: Optimización con punto de restauración        ║
║     • Reinicio opcional                                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "⏱️  El diagnóstico tomará 15-20 minutos..." -ForegroundColor Yellow
Write-Host ""

# Ejecutar todos los bloques de diagnóstico
$blocks = @(
    "Test-Environment",
    "Test-HardwareBase",
    "Test-CriticalErrors",
    "Test-CPUAdvanced",
    "Test-MemoryAdvanced",
    "Test-DiskAdvanced",
    "Test-NetworkAdvanced",
    "Test-Services",
    "Test-ScheduledTasks",
    "Test-SoftwareRemnants",
    "Test-Boot",
    "Test-Drivers",
    "Test-WindowsConfig",
    "Test-RuntimeAdvanced"
)

$blockNumber = 1
foreach ($block in $blocks) {
    try {
        & $block
    }
    catch {
        Write-Host "  ⚠️  Error en bloque $blockNumber : $($_.Exception.Message)" -ForegroundColor Red
        Add-Report -Category "ERROR" -Key $block -Value "Falló ejecución" -Status "ERROR" -Severity "INFORMATIVO"
    }
    $blockNumber++
}

# Exportar reporte de diagnóstico
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportPath = "$PSScriptRoot\WindowsDeMente_Diagnostico_$timestamp.csv"
$script:Report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8

# Mostrar resumen
Show-ExecutiveSummary

# Preguntar si continuar
Write-Host "`n"
$continue = Read-Host "¿Continuar con FASE 1 y FASE 2 - Optimización? (S/N)"

if ($continue -eq "S" -or $continue -eq "s") {
    # FASE 1: Generar fixes
    Generate-Fixes
    
    # FASE 2: Aplicar optimizaciones
    $optimized = Start-Optimization
    
    # Exportar fixes aplicados
    $fixesPath = "$PSScriptRoot\WindowsDeMente_Fixes_$timestamp.csv"
    $script:Fixes | Export-Csv -Path $fixesPath -NoTypeInformation -Encoding UTF8
    
    if ($optimized) {
        Confirm-Reboot
    }
} else {
    Write-Host "`n⏸️  Proceso detenido por el usuario." -ForegroundColor Yellow
}

Write-Host "`n📁 Reportes guardados en: $PSScriptRoot" -ForegroundColor Cyan
Write-Host "`n✅ Windows de Mente v1.0 completado!" -ForegroundColor Green
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
