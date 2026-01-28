# =====================================================================
#  WINDOWS DE MENTE v1.0 - OPTIMIZACIÓN INTELIGENTE
#  Optimización consciente de Windows
#  Guidance, not force - Detección específica por hardware
# =====================================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows de Mente v1.0 - Optimización Inteligente"

# =====================================================================
# CONFIGURACIÓN GLOBAL
# =====================================================================
$GlobalConfig = @{
    SafeMode = $false
    LogLevel = "Normal"
    LogFile = "$env:TEMP\WindowsDeMente_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    CreateBackup = $true
    BackupPath = "$env:USERPROFILE\Documents\WindowsDeMente_Backup_$(Get-Date -Format 'yyyyMMdd')"
    EnableBenchmark = $true
}

# =====================================================================
# INICIALIZAR VARIABLES GLOBALES
# =====================================================================
$SystemProfile = @{}
$OptimizationPlan = @()
$selectedOptimizations = @()
$HardwareProfile = "ESTÁNDAR"
$totalRAM = 0
$systemDiskType = "Unknown"

# =====================================================================
# FUNCIONES DE DETECCIÓN INTELIGENTE
# =====================================================================

function Get-CPUInfoDetallada {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    
    if (-not $cpu) {
        return @{
            Modelo = "No detectado"
            Generation = "Desconocida"
            Cores = 0
            Threads = 0
            BaseClock = 0
            L2Cache = "N/A"
            L3Cache = "N/A"
            Socket = "Unknown"
            Stepping = "Unknown"
            Revision = "Unknown"
            Family = 0
            HasTurbo = $false
            IsHybrid = $false
            Architecture = "Unknown"
        }
    }
    
    $details = @{
        Modelo = $cpu.Name.Trim()
        Cores = if ($cpu.NumberOfCores) { $cpu.NumberOfCores } else { 0 }
        Threads = if ($cpu.NumberOfLogicalProcessors) { $cpu.NumberOfLogicalProcessors } else { 0 }
        BaseClock = if ($cpu.MaxClockSpeed) { [math]::Round($cpu.MaxClockSpeed) } else { 0 }
        L2Cache = if ($cpu.L2CacheSize) { "$([math]::Round($cpu.L2CacheSize/1024, 1)) MB" } else { "N/A" }
        L3Cache = if ($cpu.L3CacheSize) { "$([math]::Round($cpu.L3CacheSize/1024, 1)) MB" } else { "N/A" }
        Socket = if ($cpu.SocketDesignation) { $cpu.SocketDesignation } else { "Unknown" }
        Stepping = if ($cpu.Stepping) { $cpu.Stepping } else { "Unknown" }
        Revision = if ($cpu.Revision) { $cpu.Revision } else { "Unknown" }
        Family = if ($cpu.Family) { $cpu.Family } else { 0 }
        HasTurbo = $false
        IsHybrid = $false
        Architecture = "Unknown"
        Generation = "Desconocida"
    }
    
    if ($cpu.Name -match "i[3579]-(\d{4})") {
        $modelNum = $Matches[1]
        switch -regex ($modelNum) {
            "^1[01]" { $details.Generation = "1ra Generación" }
            "^2[01]" { $details.Generation = "2da Generación" }
            "^3[01]" { $details.Generation = "3ra Generación" }
            "^4[01]" { $details.Generation = "4ta Generación" }
            "^5[01]" { $details.Generation = "5ta Generación" }
            "^6[01]" { $details.Generation = "6ta Generación" }
            "^7[01]" { $details.Generation = "7ma Generación" }
            "^8[01]" { $details.Generation = "8va Generación" }
            "^9[01]" { $details.Generation = "9na Generación" }
            "^10[01]" { $details.Generation = "10ma Generación" }
            "^11[01]" { $details.Generation = "11va Generación" }
            "^12[01]" { $details.Generation = "12va Generación" }
            "^13[01]" { $details.Generation = "13va Generación" }
            "^14[01]" { $details.Generation = "14va Generación" }
            default { $details.Generation = "Intel" }
        }
    }
    elseif ($cpu.Name -match "Ryzen") {
        if ($cpu.Name -match "Ryzen (\d)") {
            $gen = $Matches[1]
            $details.Generation = "AMD Ryzen $genxxx Series"
        }
        if ($cpu.Name -match "(\d{4})") {
            $modelNum = $Matches[1]
            $firstDigit = $modelNum[0]
            $details.Generation = "AMD Ryzen ${firstDigit}xxx Series"
        }
    }
    
    if ($cpu.Name -match "(Core|Pentium|Celeron|Atom)") {
        if ($cpu.Family -eq 6) {
            $details.Architecture = "Intel x86"
        }
    }
    
    if ($cpu.Name -match "Turbo|Boost|K$|X$|KS$") {
        $details.HasTurbo = $true
    }
    
    if ($cpu.Name -match "Alder Lake|Raptor Lake|Meteor Lake|Core Ultra") {
        $details.IsHybrid = $true
    }
    
    return $details
}

function Get-RAMInfoDetallada {
    $totalRAM = 0
    $modules = @()
    
    try {
        $memory = Get-CimInstance Win32_PhysicalMemory
        
        if ($memory) {
            foreach ($module in $memory) {
                $moduleCapacity = if ($module.Capacity) { $module.Capacity / 1GB } else { 0 }
                $totalRAM += $moduleCapacity
                
                $moduleDetails = @{
                    Capacity = [math]::Round($moduleCapacity, 1)
                    Type = switch ($module.MemoryType) {
                        20 { "DDR" }
                        21 { "DDR2" }
                        24 { "DDR3" }
                        26 { "DDR4" }
                        34 { "DDR5" }
                        default { "Unknown" }
                    }
                    Speed = if ($module.Speed) { "$($module.Speed) MHz" } else { "N/A" }
                    Manufacturer = if ($module.Manufacturer) { $module.Manufacturer.Trim() } else { "Unknown" }
                    PartNumber = if ($module.PartNumber) { $module.PartNumber.Trim() } else { "N/A" }
                }
                
                $modules += $moduleDetails
            }
        }
    } catch {
        Write-Host "  ⚠️  Error al analizar la RAM" -ForegroundColor Yellow
    }
    
    $channelMode = "Desconocido"
    if ($modules.Count -ge 2) {
        $firstModule = $modules[0]
        $allSame = $true
        
        foreach ($module in $modules) {
            if ($module.Capacity -ne $firstModule.Capacity -or $module.Type -ne $firstModule.Type) {
                $allSame = $false
                break
            }
        }
        
        if ($allSame) {
            if ($modules.Count -eq 2) { $channelMode = "Dual Channel" }
            elseif ($modules.Count -eq 4) { $channelMode = "Quad Channel" }
            else { $channelMode = "Multi Channel" }
        } else {
            $channelMode = "Configuración mixta"
        }
    } elseif ($modules.Count -eq 1) {
        $channelMode = "Single Channel"
    }
    
    return @{
        TotalGB = [math]::Round($totalRAM, 1)
        Modules = $modules
        ChannelMode = $channelMode
        IsUpgradeable = ($modules.Count -lt 4) -or ($modules.Count -eq 2 -and $modules[0].Capacity -lt 16)
    }
}

function Get-StorageInfoDetallada {
    $storage = @{
        SystemDrive = "C:"
        Drives = @()
        BottleneckRisk = "None"
        BottleneckReason = ""
    }
    
    try {
        $systemDrive = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).SystemDrive
        if ($systemDrive) {
            $storage.SystemDrive = $systemDrive
        }
    } catch {
        Write-Host "  ⚠️  Error obteniendo unidad del sistema" -ForegroundColor Yellow
    }
    
    try {
        $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        
        if ($disks) {
            foreach ($disk in $disks) {
                try {
                    $diskDetails = @{
                        DeviceID = if ($disk.DeviceID) { $disk.DeviceID } else { "Unknown" }
                        MediaType = if ($disk.MediaType) { $disk.MediaType.ToString() } else { "Unknown" }
                        SizeGB = if ($disk.Size) { [math]::Round($disk.Size / 1GB, 1) } else { 0 }
                        BusType = if ($disk.BusType) { $disk.BusType.ToString() } else { "Unknown" }
                        Model = if ($disk.FriendlyName) { $disk.FriendlyName } else { "Unknown" }
                        HealthStatus = if ($disk.HealthStatus) { $disk.HealthStatus.ToString() } else { "Unknown" }
                        OperationalStatus = if ($disk.OperationalStatus) { $disk.OperationalStatus.ToString() } else { "Unknown" }
                        RPM = "N/A"
                        SSDType = "N/A"
                    }
                    
                    if ($disk.MediaType -eq "HDD") {
                        $diskDetails.RPM = "7200 RPM"
                    }
                    
                    if ($disk.MediaType -eq "SSD") {
                        if ($disk.BusType -eq "NVMe") {
                            $diskDetails.SSDType = "NVMe"
                        } else {
                            $diskDetails.SSDType = "SATA"
                        }
                    }
                    
                    $storage.Drives += $diskDetails
                    
                    if ($storage.SystemDrive -like "*$($disk.DeviceID)*" -or 
                        ($storage.SystemDrive -eq "C:" -and $disk.DeviceID -eq 0)) {
                        if ($disk.MediaType -eq "HDD") {
                            $storage.BottleneckRisk = "Alto"
                            $storage.BottleneckReason = "Sistema en HDD"
                        } elseif ($disk.MediaType -eq "SSD" -and $disk.BusType -eq "SATA") {
                            $storage.BottleneckRisk = "Medio"
                            $storage.BottleneckReason = "Sistema en SSD SATA"
                        }
                    }
                    
                } catch {
                    Write-Host "  ⚠️  Error procesando disco" -ForegroundColor Yellow
                }
            }
        }
        
    } catch {
        Write-Host "  ⚠️  Error al acceder a información de almacenamiento" -ForegroundColor Yellow
    }
    
    return $storage
}

function Get-GPUInfoDetallada {
    $gpus = @()
    
    try {
        $videoControllers = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | 
                          Where-Object { $_.Name -and $_.Name -ne "Microsoft Basic Display Driver" }
        
        if ($videoControllers) {
            foreach ($gpu in $videoControllers) {
                $gpuDetails = @{
                    Name = if ($gpu.Name) { $gpu.Name.Trim() } else { "Unknown" }
                    AdapterRAM = if ($gpu.AdapterRAM -gt 0) { 
                        [math]::Round($gpu.AdapterRAM / 1MB, 1) 
                    } else { "N/A" }
                    DriverVersion = if ($gpu.DriverVersion) { $gpu.DriverVersion } else { "N/A" }
                    DriverDate = "N/A"
                }
                
                if ($gpu.Name -match "NVIDIA") {
                    $gpuDetails.Vendor = "NVIDIA"
                    $gpuDetails.Model = "NVIDIA GPU"
                } elseif ($gpu.Name -match "AMD|Radeon") {
                    $gpuDetails.Vendor = "AMD"
                    $gpuDetails.Model = "AMD GPU"
                } elseif ($gpu.Name -match "Intel") {
                    $gpuDetails.Vendor = "Intel"
                    $gpuDetails.Model = "Intel Graphics"
                } else {
                    $gpuDetails.Vendor = "Unknown"
                    $gpuDetails.Model = "Unknown"
                }
                
                if ($gpu.PNPDeviceID -match "PCI\\VEN_") {
                    $gpuDetails.Connection = "PCIe"
                    if ($gpu.Name -match "UHD|HD Graphics|Radeon Graphics") {
                        $gpuDetails.Type = "Integrada"
                    } else {
                        $gpuDetails.Type = "Dedicada"
                    }
                } else {
                    $gpuDetails.Type = "Unknown"
                    $gpuDetails.Connection = "Unknown"
                }
                
                $gpus += $gpuDetails
            }
        }
        
    } catch {
        Write-Host "  ⚠️  Error al analizar la GPU" -ForegroundColor Yellow
    }
    
    return $gpus
}

function Get-NetworkInfoDetallada {
    $networkInfo = @{
        Adapters = @()
        HasProxy = $false
        ProxyServer = ""
        ConnectionType = "Desconocido"
        EthernetDetected = $false
        WiFiDetected = $false
    }
    
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
        
        foreach ($adapter in $adapters) {
            $adapterInfo = @{
                Name = $adapter.Name
                InterfaceDescription = $adapter.InterfaceDescription
                Status = $adapter.Status
                LinkSpeed = if ($adapter.LinkSpeed) { $adapter.LinkSpeed } else { "N/A" }
                MacAddress = $adapter.MacAddress
            }
            
            if ($adapter.InterfaceDescription -match "Wi-Fi|Wireless|802.11") {
                $adapterInfo.Type = "Wi-Fi"
                $networkInfo.WiFiDetected = $true
            } elseif ($adapter.InterfaceDescription -match "Ethernet|Gigabit|LAN") {
                $adapterInfo.Type = "Ethernet"
                $networkInfo.EthernetDetected = $true
            } else {
                $adapterInfo.Type = "Otro"
            }
            
            $networkInfo.Adapters += $adapterInfo
        }
        
        try {
            $proxySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
            
            if ($proxySettings) {
                if ($proxySettings.ProxyEnable -eq 1 -and $proxySettings.ProxyServer) {
                    $networkInfo.HasProxy = $true
                    $networkInfo.ProxyServer = $proxySettings.ProxyServer
                    $networkInfo.ProxyOverride = if ($proxySettings.ProxyOverride) { $proxySettings.ProxyOverride } else { "N/A" }
                }
            }
        } catch {
            Write-Host "  ⚠️  Error al verificar configuración de proxy" -ForegroundColor Yellow
        }
        
        if ($networkInfo.EthernetDetected) {
            $networkInfo.ConnectionType = "Ethernet"
        } elseif ($networkInfo.WiFiDetected) {
            $networkInfo.ConnectionType = "Wi-Fi"
        }
        
        try {
            $testResult = Test-NetConnection -ComputerName "8.8.8.8" -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            $networkInfo.HasInternet = $testResult.TcpTestSucceeded
            $networkInfo.PingMs = if ($testResult.PingSucceeded) { $testResult.PingReplyDetails.RoundtripTime } else { "N/A" }
        } catch {
            $networkInfo.HasInternet = $false
            $networkInfo.PingMs = "N/A"
        }
        
    } catch {
        Write-Host "  ⚠️  Error al analizar la red" -ForegroundColor Yellow
    }
    
    return $networkInfo
}

# =====================================================================
# [FASE 0] Análisis inteligente del sistema
# =====================================================================
Write-Host "[FASE 0] Análisis inteligente de tu sistema" -ForegroundColor Magenta
Write-Host ("─" * 70) -ForegroundColor DarkGray
Write-Host "🔍 Analizando tu hardware y configuración..." -ForegroundColor DarkGray
Write-Host ""

$SystemProfileDetallado = @{
    CPU = Get-CPUInfoDetallada
    RAM = Get-RAMInfoDetallada
    Storage = Get-StorageInfoDetallada
    GPU = Get-GPUInfoDetallada
    Network = Get-NetworkInfoDetallada
    Platform = @{
        IsLaptop = $false
        HasBattery = $false
    }
}

try {
    $chassis = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue
    if ($chassis) {
        $laptopTypes = @(8, 9, 10, 11, 12, 14, 18, 21, 31)
        if ($chassis.ChassisTypes | Where-Object { $_ -in $laptopTypes }) {
            $SystemProfileDetallado.Platform.IsLaptop = $true
        }
    }
    
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $SystemProfileDetallado.Platform.HasBattery = $true
    }
} catch {
    Write-Host "  ⚠️  Error detectando tipo de dispositivo" -ForegroundColor Yellow
}

Write-Host "✅ ANÁLISIS COMPLETADO:" -ForegroundColor Green
Write-Host ("─" * 70) -ForegroundColor DarkGray

Write-Host "🖥️  PROCESADOR:" -ForegroundColor Yellow
Write-Host "  • Modelo: $($SystemProfileDetallado.CPU.Modelo)" -ForegroundColor DarkGray
if ($SystemProfileDetallado.CPU.Generation -ne "Desconocida") {
    Write-Host "  • Generación: $($SystemProfileDetallado.CPU.Generation)" -ForegroundColor DarkGray
}
Write-Host "  • Núcleos/Hilos: $($SystemProfileDetallado.CPU.Cores)/$($SystemProfileDetallado.CPU.Threads)" -ForegroundColor DarkGray

Write-Host "💾 MEMORIA RAM:" -ForegroundColor Yellow
Write-Host "  • Total: $($SystemProfileDetallado.RAM.TotalGB) GB" -ForegroundColor DarkGray
Write-Host "  • Configuración: $($SystemProfileDetallado.RAM.ChannelMode)" -ForegroundColor DarkGray

Write-Host "💿 ALMACENAMIENTO:" -ForegroundColor Yellow
if ($SystemProfileDetallado.Storage.Drives.Count -gt 0) {
    $mainDrive = $SystemProfileDetallado.Storage.Drives[0]
    $driveType = if ($mainDrive.MediaType -eq "SSD") {
        if ($mainDrive.SSDType -eq "NVMe") { "NVMe (Rápido)" } else { "SSD SATA (Bueno)" }
    } else { "HDD (Más lento)" }
    Write-Host "  • Principal: $driveType - $($mainDrive.SizeGB)GB" -ForegroundColor DarkGray
}

Write-Host "🎮 GRÁFICOS:" -ForegroundColor Yellow
if ($SystemProfileDetallado.GPU.Count -gt 0) {
    $gpuType = if ($SystemProfileDetallado.GPU[0].Type -eq "Dedicada") { "Dedicada" } else { "Integrada" }
    Write-Host "  • $gpuType: $($SystemProfileDetallado.GPU[0].Name)" -ForegroundColor DarkGray
}

Write-Host "🌐 CONEXIÓN DE RED:" -ForegroundColor Yellow
Write-Host "  • Tipo: $($SystemProfileDetallado.Network.ConnectionType)" -ForegroundColor DarkGray
if ($SystemProfileDetallado.Network.HasProxy) {
    Write-Host "  • Proxy detectado: $($SystemProfileDetallado.Network.ProxyServer)" -ForegroundColor Cyan
}

if ($SystemProfileDetallado.Platform.IsLaptop) {
    Write-Host "💻 DISPOSITIVO:" -ForegroundColor Yellow
    Write-Host "  • Laptop detectado" -ForegroundColor DarkGray
    if ($SystemProfileDetallado.Platform.HasBattery) {
        Write-Host "  • Con batería" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "✅ Análisis completado" -ForegroundColor Green

# =====================================================================
# FUNCIÓN PARA GUARDAR REPORTE EN ESCRITORIO
# =====================================================================
function Save-SystemProfileReport {
    param(
        [hashtable]$SystemProfileDetallado,
        [hashtable]$FinalProfile,
        [array]$OptimizationPlan,
        [int]$appliedCount,
        [hashtable]$GlobalConfig,
        [int]$tweaksCorregidos,
        [int]$tweaksAjustados
    )
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $reportFileName = "Perfil_Sistema_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $reportPath = Join-Path $desktopPath $reportFileName
    
    $idealProfile = @{
        CPU = @{
            Modelo = "Intel Core i9-14900K o AMD Ryzen 9 7950X"
            Cores = 24
            Threads = 32
            BaseClock = 5500
            Cache = "36 MB L3"
        }
        RAM = @{
            TotalGB = 64
            Type = "DDR5 6000MHz"
            Channel = "Dual Channel"
        }
        Storage = @{
            Type = "NVMe PCIe 4.0"
            SizeGB = 2000
            Speed = "7,000 MB/s"
        }
        GPU = @{
            Modelo = "NVIDIA RTX 4080 / AMD RX 7900 XTX"
            VRAM = "16 GB GDDR6"
            Type = "Dedicada"
        }
        Network = @{
            Type = "Fibra óptica"
            Latency = "<10 ms"
            Speed = "1 Gbps"
        }
    }
    
    $cpuScore = 0
    $userCores = $SystemProfileDetallado.CPU.Cores
    if ($userCores -ge 16) { $cpuScore = 30 }
    elseif ($userCores -ge 12) { $cpuScore = 25 }
    elseif ($userCores -ge 8) { $cpuScore = 20 }
    elseif ($userCores -ge 6) { $cpuScore = 15 }
    elseif ($userCores -ge 4) { $cpuScore = 10 }
    elseif ($userCores -ge 2) { $cpuScore = 5 }
    
    if ($SystemProfileDetallado.CPU.Generation -match "(10ma|11va|12va|13va|14va|Ryzen [5-9])") {
        $cpuScore += 5
    }
    
    $ramScore = 0
    $userRAM = $SystemProfileDetallado.RAM.TotalGB
    if ($userRAM -ge 64) { $ramScore = 25 }
    elseif ($userRAM -ge 32) { $ramScore = 20 }
    elseif ($userRAM -ge 16) { $ramScore = 15 }
    elseif ($userRAM -ge 8) { $ramScore = 10 }
    elseif ($userRAM -ge 4) { $ramScore = 5 }
    
    if ($SystemProfileDetallado.RAM.ChannelMode -eq "Dual Channel") { $ramScore += 2 }
    elseif ($SystemProfileDetallado.RAM.ChannelMode -eq "Quad Channel") { $ramScore += 5 }
    
    $storageScore = 0
    $mainDrive = $SystemProfileDetallado.Storage.Drives | Select-Object -First 1
    if ($mainDrive) {
        switch -wildcard ($mainDrive.MediaType) {
            "*SSD*" {
                if ($mainDrive.SSDType -eq "NVMe") { $storageScore = 20 }
                else { $storageScore = 15 }
            }
            "*HDD*" { $storageScore = 5 }
            default { $storageScore = 0 }
        }
        
        if ($mainDrive.SizeGB -ge 1000) { $storageScore += 5 }
        elseif ($mainDrive.SizeGB -ge 500) { $storageScore += 3 }
    }
    
    $gpuScore = 0
    if ($SystemProfileDetallado.GPU.Count -gt 0) {
        $gpu = $SystemProfileDetallado.GPU[0]
        if ($gpu.Type -eq "Dedicada") { $gpuScore = 15 }
        elseif ($gpu.Type -eq "Integrada") { $gpuScore = 5 }
        
        if ($gpu.AdapterRAM -ge 12) { $gpuScore += 5 }
        elseif ($gpu.AdapterRAM -ge 8) { $gpuScore += 3 }
        elseif ($gpu.AdapterRAM -ge 4) { $gpuScore += 1 }
    }
    
    $userScore = $cpuScore + $ramScore + $storageScore + $gpuScore
    $maxPossibleScore = 105
    $userScore = [math]::Min($maxPossibleScore, $userScore)
    
    $relativeToOwnHardware = [math]::Round(($FinalProfile.RelativeScore / 100) * 100)
    $comparedToIdeal = [math]::Round(($userScore / $maxPossibleScore) * 100)
    
    $performanceCategory = switch ($comparedToIdeal) {
        { $_ -ge 80 } { "Rendimiento Premium" }
        { $_ -ge 60 } { "Rendimiento Alto" }
        { $_ -ge 40 } { "Rendimiento Medio" }
        { $_ -ge 20 } { "Rendimiento Básico" }
        default { "Rendimiento Mínimo" }
    }
    
    $performanceMessage = switch ($performanceCategory) {
        "Rendimiento Premium" { "¡Excelente! Tu PC está en el top de rendimiento." }
        "Rendimiento Alto" { "Muy buen rendimiento para cualquier tarea." }
        "Rendimiento Medio" { "Buen rendimiento para trabajo y entretenimiento." }
        "Rendimiento Básico" { "Adecuado para tareas cotidianas y ofimática." }
        "Rendimiento Mínimo" { "Apto para tareas básicas, considera mejoras." }
    }
    
    $reportContent = @"
════════════════════════════════════════════════════════════════════
                      📊 PERFIL DEL SISTEMA
════════════════════════════════════════════════════════════════════
Fecha del análisis: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Versión de Windows de Mente: v1.0

────────────────────────────────────────────────────────────────────
🖥️  HARDWARE DETECTADO
────────────────────────────────────────────────────────────────────
• Procesador: $($SystemProfileDetallado.CPU.Modelo)
  - Generación: $($SystemProfileDetallado.CPU.Generation)
  - Núcleos/Hilos: $($SystemProfileDetallado.CPU.Cores)/$($SystemProfileDetallado.CPU.Threads)
  
• Memoria RAM: $($SystemProfileDetallado.RAM.TotalGB) GB
  - Configuración: $($SystemProfileDetallado.RAM.ChannelMode)
  
• Almacenamiento: $(if($mainDrive){ "$($mainDrive.MediaType) - $($mainDrive.SizeGB)GB" }else{ "No detectado" })
  
• Gráficos: $(if($SystemProfileDetallado.GPU.Count -gt 0){ $SystemProfileDetallado.GPU[0].Name }else{ "No detectado" })
  - Tipo: $(if($SystemProfileDetallado.GPU.Count -gt 0){ $SystemProfileDetallado.GPU[0].Type }else{ "N/A" })

• Red: $($SystemProfileDetallado.Network.ConnectionType)
  $(if($SystemProfileDetallado.Network.HasProxy){ "Proxy: $($SystemProfileDetallado.Network.ProxyServer)" }else{ "Sin proxy configurado" })

• Dispositivo: $(if($SystemProfileDetallado.Platform.IsLaptop){ "Laptop" }else{ "Desktop" })

────────────────────────────────────────────────────────────────────
📈 ANÁLISIS DE RENDIMIENTO
────────────────────────────────────────────────────────────────────
• Score relativo a tu hardware: $relativeToOwnHardware/100
  → $(if($relativeToOwnHardware -ge 70){ "Tu PC funciona correctamente y aprovecha bien sus recursos actuales." }else{ "Hay margen para optimizar el uso de tu hardware actual." })

• Score comparado con el perfil ideal: $comparedToIdeal/100
  → El perfil ideal (100) corresponde a una PC de alta gama con:
     - CPU Intel i9-14900K o AMD Ryzen 9 7950X
     - 64 GB RAM DDR5 6000MHz
     - SSD NVMe PCIe 4.0 (2TB)
     - GPU dedicada RTX 4080 o similar
     - Conexión de fibra óptica (<10 ms)

• Categoría: $performanceCategory
  → $performanceMessage

────────────────────────────────────────────────────────────────────
📋 DESGLOSE DE PUNTUACIÓN
────────────────────────────────────────────────────────────────────
• Procesador: $cpuScore/35 (ideal: 35)
• Memoria RAM: $ramScore/25 (ideal: 25)
• Almacenamiento: $storageScore/25 (ideal: 25)
• Gráficos: $gpuScore/20 (ideal: 20)

────────────────────────────────────────────────────────────────────
🔧 OPTIMIZACIONES APLICADAS
────────────────────────────────────────────────────────────────────
• Tweaks peligrosos eliminados: $tweaksCorregidos
• Ajustes específicos para tu hardware: $tweaksAjustados
• Total de optimizaciones aplicadas: $appliedCount
• Modo: $(if($GlobalConfig.SafeMode){ 'Solo análisis (sin cambios)' }else{ 'Optimización activa' })

────────────────────────────────────────────────────────────────────
🎯 RECOMENDACIONES PERSONALIZADAS
────────────────────────────────────────────────────────────────────
"@
    
    $recommendations = @()
    
    if ($comparedToIdeal -lt 40) {
        $recommendations += "• Considera actualizar a un SSD si aún usas disco duro"
        $recommendations += "• Añadir más RAM mejoraría significativamente el rendimiento"
    }
    
    if ($SystemProfileDetallado.CPU.Generation -match "(1ra|2da|3ra|4ta)") {
        $recommendations += "• Tu procesador es antiguo, considera actualizar para mejor rendimiento"
    }
    
    if ($SystemProfileDetallado.RAM.TotalGB -lt 8) {
        $recommendations += "• Con menos de 8GB de RAM, limita las pestañas del navegador"
    }
    
    if ($SystemProfileDetallado.Storage.BottleneckRisk -eq "Alto") {
        $recommendations += "• El disco duro ralentiza tu sistema, un SSD sería una gran mejora"
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "• Tu sistema está bien configurado, mantén actualizados los drivers"
        $recommendations += "• Realiza mantenimiento periódico con herramientas de Windows"
    }
    
    $reportContent += "`n$($recommendations -join "`n")`n"
    
    $reportContent += @"
────────────────────────────────────────────────────────────────────
💡 CONSEJOS GENERALES
────────────────────────────────────────────────────────────────────
• Mantén Windows Update siempre activado
• Usa el limpiador de disco periódicamente
• Reinicia tu PC al menos una vez por semana
• Mantén al menos 15% de espacio libre en tu disco principal

════════════════════════════════════════════════════════════════════
                  Windows de Mente v1.0 - Optimización Inteligente
════════════════════════════════════════════════════════════════════
"@
    
    try {
        $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Host "📄 Reporte guardado en: $reportPath" -ForegroundColor Green
        Write-Host "   (Encontrarás el archivo en tu escritorio)" -ForegroundColor DarkGray
        return $true
    } catch {
        Write-Host "⚠️  No se pudo guardar el reporte" -ForegroundColor Yellow
        return $false
    }
}

# =====================================================================
# [FASE 0-B] Análisis de optimizaciones necesarias
# =====================================================================
Write-Host ""
Write-Host "[PLAN] Analizando optimizaciones recomendadas" -ForegroundColor Magenta
Write-Host ("─" * 70) -ForegroundColor DarkGray

$dangerousTweaks = @(
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"; Reason="PELIGROSO con menos de 16GB RAM"}
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="LargeSystemCache"; Reason="INAPROPIADO para estaciones de trabajo"}
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="ClearPageFileAtShutdown"; Reason="Lento e innecesario"}
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="SecondLevelDataCache"; Reason="Windows detecta automáticamente"}
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="IoPageLockLimit"; Reason="Puede causar inestabilidad"}
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"; Reason="Valor duplicado"}
)

$CPUPriorityMatrix = @{
    "ENTUSIASTA" = @{Conservative=24; Balanced=36; Aggressive=48}
    "EQUILIBRADO" = @{Conservative=20; Balanced=28; Aggressive=36}
    "ESTÁNDAR" = @{Conservative=16; Balanced=24; Aggressive=32}
    "LIVIANO" = @{Conservative=12; Balanced=18; Aggressive=24}
}

$ramGB = $SystemProfileDetallado.RAM.TotalGB
$cpuCores = $SystemProfileDetallado.CPU.Cores

if ($ramGB -ge 32 -and $cpuCores -ge 8) {
    $HardwareProfile = "ENTUSIASTA"
} elseif ($ramGB -ge 16 -and $cpuCores -ge 6) {
    $HardwareProfile = "EQUILIBRADO"
} elseif ($ramGB -ge 8 -and $cpuCores -ge 4) {
    $HardwareProfile = "ESTÁNDAR"
} else {
    $HardwareProfile = "LIVIANO"
}

$risk = 0
if ($SystemProfileDetallado.Platform.IsLaptop) { $risk += 1 }
if ($ramGB -lt 4) { $risk += 2 }
if ($SystemProfileDetallado.Storage.BottleneckRisk -eq "Alto") { $risk += 1 }

if ($risk -ge 3) {
    $SystemProfileStrategy = "Conservative"
    $SystemProfileRiskLevel = "Alto"
} elseif ($risk -eq 2) {
    $SystemProfileStrategy = "Balanced"
    $SystemProfileRiskLevel = "Medio"
} else {
    $SystemProfileStrategy = "Aggressive"
    $SystemProfileRiskLevel = "Bajo"
}

$CPUValue = $CPUPriorityMatrix[$HardwareProfile][$SystemProfileStrategy]

$OptimizationPlan = @()

$cpuGen = $SystemProfileDetallado.CPU.Generation
$powerPlanReason = "Procesador detectado: $cpuGen"
if ($cpuGen -like "*1ra Generación*" -or $cpuGen -like "*2da Generación*") {
    $powerPlanAction = "Power Plan: Equilibrado"
} elseif ($cpuGen -like "*Ryzen*") {
    $powerPlanAction = "Power Plan: Ryzen Balanced"
} else {
    $powerPlanAction = "Power Plan: $HardwareProfile"
}

$OptimizationPlan += @{
    Fase = 2
    Nombre = "Plan de Energía"
    Accion = $powerPlanAction
    Necesario = $true
    Razon = $powerPlanReason
    Impacto = "Rendimiento adaptado a tu procesador"
}

$dangerTweaks = @()
foreach ($tweak in $dangerousTweaks) {
    if (Test-Path $tweak.Path) {
        $prop = Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
        if ($prop) { $dangerTweaks += $tweak.Name }
    }
}
$memoryNeeded = ($dangerTweaks.Count -gt 0)
$memoryReason = if ($dangerTweaks.Count -gt 0) {
    "$($dangerTweaks.Count) ajustes peligrosos detectados"
} else {
    "Configuración de memoria ya es segura"
}
$OptimizationPlan += @{
    Fase = 3
    Nombre = "Configuración de Memoria"
    Accion = if ($dangerTweaks.Count -gt 0) { "Eliminar $($dangerTweaks.Count) ajustes" } else { "Verificar" }
    Necesario = $memoryNeeded
    Razon = $memoryReason
    Impacto = "Mayor estabilidad"
}

$networkNeeded = $true
$networkReason = "Optimización adaptada a tu conexión"
if ($SystemProfileDetallado.Network.HasProxy) {
    $networkReason += " (con proxy detectado)"
}
$OptimizationPlan += @{
    Fase = 4
    Nombre = "Optimización de Red"
    Accion = "Ajustar TCP"
    Necesario = $networkNeeded
    Razon = $networkReason
    Impacto = "Conexión más estable"
}

$cpuPriorityNeeded = $true
$cpuPriorityReason = "Balance según perfil ($HardwareProfile/$SystemProfileStrategy)"
$OptimizationPlan += @{
    Fase = 5
    Nombre = "Prioridades CPU"
    Accion = "Configurar valor: $CPUValue"
    Necesario = $cpuPriorityNeeded
    Razon = $cpuPriorityReason
    Impacto = "Mejor multitarea"
}

$mainStorage = $SystemProfileDetallado.Storage.Drives | Select-Object -First 1
if ($mainStorage) {
    $storageType = if ($mainStorage.MediaType -eq "SSD") {
        if ($mainStorage.SSDType -eq "NVMe") { "NVMe" } else { "SSD SATA" }
    } else { "HDD" }
    
    $storageReason = "Optimización para $storageType"
    $storageImpact = if ($storageType -eq "NVMe") { "Máximo rendimiento" }
                     elseif ($storageType -eq "SSD SATA") { "SSD más rápido" }
                     else { "HDD más responsivo" }
    
    $OptimizationPlan += @{
        Fase = 6
        Nombre = "Almacenamiento"
        Accion = "Configurar para $storageType"
        Necesario = $true
        Razon = $storageReason
        Impacto = $storageImpact
    }
}

if ($mainStorage) {
    $recommendedDelay = if ($mainStorage.MediaType -eq "SSD" -and $mainStorage.SSDType -eq "NVMe") { 0 }
                       elseif ($mainStorage.MediaType -eq "SSD") { 50 }
                       else { 200 }
    
    $OptimizationPlan += @{
        Fase = 7
        Nombre = "Interfaz"
        Accion = "Retrasos UI: ${recommendedDelay}ms"
        Necesario = $true
        Razon = "Animaciones optimizadas para $storageType"
        Impacto = "Interfaz más fluida"
    }
}

$hotfixesNeeded = $true
$hotfixReason = "Soluciones específicas para tu configuración"
if ($ramGB -lt 4) { $hotfixReason += " (RAM baja)" }
if ($SystemProfileDetallado.Storage.BottleneckRisk -eq "Alto") { $hotfixReason += " (HDD lento)" }
if ($SystemProfileDetallado.Network.HasProxy) { $hotfixReason += " (Proxy detectado)" }

$OptimizationPlan += @{
    Fase = "Hotfixes"
    Nombre = "Ajustes Rápidos"
    Accion = "Aplicar ajustes detectados"
    Necesario = $hotfixesNeeded
    Razon = $hotfixReason
    Impacto = "Sistema más estable"
}

Write-Host ""
Write-Host "📋 PLAN DE OPTIMIZACIÓN" -ForegroundColor Cyan
Write-Host ("─" * 70) -ForegroundColor DarkGray

$totalOptimizations = $OptimizationPlan.Count
$neededOptimizations = ($OptimizationPlan | Where-Object { $_.Necesario }).Count

Write-Host "🔍 RESUMEN:" -ForegroundColor Yellow
Write-Host "  • Perfil de Hardware: $HardwareProfile" -ForegroundColor DarkGray
Write-Host "  • Estrategia: $SystemProfileStrategy" -ForegroundColor DarkGray
Write-Host "  • Optimizaciones detectadas: $totalOptimizations" -ForegroundColor DarkGray
Write-Host "  • Optimizaciones recomendadas: $neededOptimizations" -ForegroundColor DarkGray
Write-Host ""

foreach ($phase in $OptimizationPlan | Sort-Object { if ($_.Fase -is [int]) { $_.Fase } else { 99 } }) {
    $phaseColor = if ($phase.Necesario) { "Green" } else { "DarkGray" }
    $checkmark = if ($phase.Necesario) { "✓" } else { "○" }
    
    Write-Host "  $checkmark [$($phase.Fase)] $($phase.Nombre)" -ForegroundColor $phaseColor
    Write-Host "     • Acción: $($phase.Accion)" -ForegroundColor DarkGray
    if ($phase.Necesario) {
        Write-Host "     • Razón: $($phase.Razon)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎯 OPCIONES DE OPTIMIZACIÓN" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray
Write-Host "  1️⃣  OPTIMIZACIÓN COMPLETA" -ForegroundColor Green
Write-Host "     → Aplica las $neededOptimizations optimizaciones recomendadas" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2️⃣  OPTIMIZACIÓN SELECTIVA" -ForegroundColor Yellow
Write-Host "     → Elige qué optimizaciones aplicar" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  3️⃣  MODO SEGURO" -ForegroundColor Magenta
Write-Host "     → Solo muestra recomendaciones" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4️⃣  SALIR" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$opcion = Read-Host "Selecciona una opción (1-4)"

$selectedOptimizations = @()
$GlobalConfig.SafeMode = $false

switch ($opcion) {
    "1" {
        Write-Host ""
        Write-Host "🚀 OPTIMIZACIÓN COMPLETA ACTIVADA" -ForegroundColor Green
        Write-Host "Aplicando las $neededOptimizations optimizaciones..." -ForegroundColor DarkGray
        $GlobalConfig.SafeMode = $false
        $selectedOptimizations = $OptimizationPlan | Where-Object { $_.Necesario }
    }
    "2" {
        Write-Host ""
        Write-Host "🔄 OPTIMIZACIÓN SELECTIVA" -ForegroundColor Yellow
        Write-Host ("─" * 70) -ForegroundColor DarkGray
        
        foreach ($phase in $OptimizationPlan | Where-Object { $_.Necesario } | Sort-Object { if ($_.Fase -is [int]) { $_.Fase } else { 99 } }) {
            $default = "S"
            $respuesta = Read-Host "  ¿Aplicar [$($phase.Fase)] $($phase.Nombre)? (S/N) [Por defecto: $default]"
            if ($respuesta -eq "" -or $respuesta -eq "S" -or $respuesta -eq "s") {
                $selectedOptimizations += $phase
                Write-Host "    ✓ Activado" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Omitido" -ForegroundColor DarkGray
            }
            Write-Host ""
        }
        
        if ($selectedOptimizations.Count -eq 0) {
            Write-Host "⚠️  No seleccionaste ninguna optimización." -ForegroundColor Yellow
            Write-Host "   Ejecutando en modo seguro..." -ForegroundColor Yellow
            $GlobalConfig.SafeMode = $true
        } else {
            Write-Host "✅ Seleccionaste $($selectedOptimizations.Count) optimizaciones" -ForegroundColor Green
            $selectedOptimizations | ForEach-Object { Write-Host "  • [$($_.Fase)] $($_.Nombre)" -ForegroundColor DarkGray }
            Write-Host ""
            $GlobalConfig.SafeMode = $false
        }
    }
    "3" {
        Write-Host ""
        Write-Host "🛡️  MODO SEGURO ACTIVADO" -ForegroundColor Yellow
        Write-Host "Solo se mostrarán recomendaciones." -ForegroundColor DarkGray
        $GlobalConfig.SafeMode = $true
        $selectedOptimizations = @()
    }
    "4" {
        Write-Host ""
        Write-Host "👋 Saliendo de Windows de Mente v1.0" -ForegroundColor Cyan
        Write-Host "Gracias por usar nuestra herramienta." -ForegroundColor DarkGray
        exit 0
    }
    default {
        Write-Host ""
        Write-Host "⚠️  Opción no válida. Ejecutando Optimización Completa." -ForegroundColor Yellow
        Write-Host "Aplicando las $neededOptimizations optimizaciones..." -ForegroundColor DarkGray
        $GlobalConfig.SafeMode = $false
        $selectedOptimizations = $OptimizationPlan | Where-Object { $_.Necesario }
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   INICIANDO OPTIMIZACIÓN..." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# ACTUALIZAR VARIABLES GLOBALES
# =====================================================================
$totalRAM = $SystemProfileDetallado.RAM.TotalGB

$SystemProfile = @{
    CPU = @{
        Vendor = "Unknown"
        Cores = 0
        Threads = 0
        Modern = $false
        Hybrid = $false
    }
    GPU = @{
        Type = "Unknown"
        Vendor = "Unknown"
    }
    Storage = @{
        SystemDiskType = "Unknown"
    }
    RiskLevel = "Medium"
    Strategy = "Balanced"
    Platform = @{
        IsLaptop = $SystemProfileDetallado.Platform.IsLaptop
        HasBattery = $SystemProfileDetallado.Platform.HasBattery
    }
}

$SystemProfile.CPU.Cores = $SystemProfileDetallado.CPU.Cores
$SystemProfile.CPU.Threads = $SystemProfileDetallado.CPU.Threads
$SystemProfile.RiskLevel = $SystemProfileRiskLevel
$SystemProfile.Strategy = $SystemProfileStrategy

if ($mainStorage) {
    if ($mainStorage.MediaType -eq "SSD") {
        if ($mainStorage.SSDType -eq "NVMe") {
            $SystemProfile.Storage.SystemDiskType = "NVMe"
        } else {
            $SystemProfile.Storage.SystemDiskType = "SSD"
        }
    } else {
        $SystemProfile.Storage.SystemDiskType = "HDD"
    }
}

if ($SystemProfileDetallado.CPU.Modelo -match "Intel") {
    $SystemProfile.CPU.Vendor = "Intel"
} elseif ($SystemProfileDetallado.CPU.Modelo -match "AMD|Ryzen") {
    $SystemProfile.CPU.Vendor = "AMD"
}

$SystemProfile.CPU.Modern = $false
if ($SystemProfileDetallado.CPU.Generation -like "*10ma*" -or 
    $SystemProfileDetallado.CPU.Generation -like "*11va*" -or 
    $SystemProfileDetallado.CPU.Generation -like "*12va*" -or
    $SystemProfileDetallado.CPU.Generation -like "*13va*" -or
    $SystemProfileDetallado.CPU.Generation -like "*14va*" -or
    $SystemProfileDetallado.CPU.Generation -like "*Ryzen*") {
    $SystemProfile.CPU.Modern = $true
}

if ($SystemProfileDetallado.GPU.Count -gt 0) {
    $SystemProfile.GPU.Vendor = $SystemProfileDetallado.GPU[0].Vendor
    $SystemProfile.GPU.Type = if ($SystemProfileDetallado.GPU[0].Type -eq "Dedicada") { "Dedicated" } else { "Integrated" }
}

Write-Host "✅ Sistema analizado y listo para optimización" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 1] Evaluación contextual
# =====================================================================
Write-Host "[FASE 1] Evaluación contextual de capacidades" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$ProfileScore = 0
$ScoreDetails = @()

$ramScore = switch ($totalRAM) {
    { $_ -ge 64 } { 60; $ScoreDetails += "RAM ≥64GB: +60" }
    { $_ -ge 32 } { 50; $ScoreDetails += "RAM ≥32GB: +50" }
    { $_ -ge 16 } { 40; $ScoreDetails += "RAM 16GB: +40" }
    { $_ -ge 8 }  { 30; $ScoreDetails += "RAM 8GB: +30" }
    { $_ -ge 4 }  { 20; $ScoreDetails += "RAM 4GB: +20" }
    default       { 5;  $ScoreDetails += "RAM <4GB: +5" }
}
$ProfileScore += $ramScore

$cpuBaseScore = switch ($SystemProfile.CPU.Cores) {
    { $_ -ge 12 } { 40; $ScoreDetails += "CPU ≥12c: +40" }
    { $_ -ge 8 }  { 35; $ScoreDetails += "CPU 8c: +35" }
    { $_ -ge 4 }  { 25; $ScoreDetails += "CPU 4c: +25" }
    { $_ -ge 2 }  { 15; $ScoreDetails += "CPU 2c: +15" }
    default       { 5;  $ScoreDetails += "CPU 1c: +5" }
}

$cpuModernBonus = if ($SystemProfile.CPU.Modern) { 
    15; $ScoreDetails += "CPU Moderna: +15" 
} else { 
    0 
}

$cpuScore = $cpuBaseScore + $cpuModernBonus
$ProfileScore += $cpuScore

$systemDiskType = $SystemProfile.Storage.SystemDiskType
$storageScore = switch ($systemDiskType) {
    "NVMe" { 40; $ScoreDetails += "NVMe: +40" }
    "SSD"  { 30; $ScoreDetails += "SSD: +30" }
    "HDD"  { 15; $ScoreDetails += "HDD: +15" }
    default { 10; $ScoreDetails += "Almacenamiento: +10" }
}
$ProfileScore += $storageScore

$gpuScore = 0
switch ($SystemProfile.GPU.Type) {
    "Dedicated" { $gpuScore = 25; $ScoreDetails += "GPU Dedicada: +25" }
    "Integrated"{ $gpuScore = 10; $ScoreDetails += "GPU Integrada: +10" }
    default     { $gpuScore = 5;  $ScoreDetails += "GPU: +5" }
}

if ($SystemProfile.GPU.Vendor -in @("NVIDIA", "AMD")) {
    $gpuScore += 5
    $ScoreDetails += "GPU NVIDIA/AMD: +5"
}

$ProfileScore += $gpuScore

$riskModifier = switch ($SystemProfile.RiskLevel) {
    "High"   { -30; $ScoreDetails += "Riesgo Alto: -30" }
    "Low"    { 10; $ScoreDetails += "Riesgo Bajo: +10" }
    default  { 0 }
}

$ProfileScore += $riskModifier
$ProfileScore = [Math]::Max(10, $ProfileScore)

if ($ProfileScore -ge 120) {
    $HardwareProfile = "ENTUSIASTA"
} elseif ($ProfileScore -ge 85) {
    $HardwareProfile = "EQUILIBRADO"
} elseif ($ProfileScore -ge 50) {
    $HardwareProfile = "ESTÁNDAR"
} else {
    $HardwareProfile = "LIVIANO"
}

$categoryLimits = @{
    "ENTUSIASTA" = @{
        MaxScore = 150
        Description = "Hardware de gama alta"
        TargetScore = 120
    }
    "EQUILIBRADO" = @{
        MaxScore = 120
        Description = "Hardware moderno medio"
        TargetScore = 95
    }
    "ESTÁNDAR" = @{
        MaxScore = 100
        Description = "Hardware común"
        TargetScore = 80
    }
    "LIVIANO" = @{
        MaxScore = 80
        Description = "Hardware limitado"
        TargetScore = 65
    }
}

$categoryInfo = $categoryLimits[$HardwareProfile]
$relativeScore = [math]::Round(($ProfileScore / $categoryInfo.TargetScore) * 100)

$FinalProfile = @{
    HardwareTier = $HardwareProfile
    RiskStrategy = $SystemProfile.Strategy
    RiskLevel = $SystemProfile.RiskLevel
    TotalScore = $ProfileScore
    RelativeScore = $relativeScore
    CategoryMax = $categoryInfo.MaxScore
    CategoryTarget = $categoryInfo.TargetScore
}

Write-Host "📈 EVALUACIÓN CONTEXTUAL:" -ForegroundColor Cyan
Write-Host "  • RAM: ${totalRAM}GB" -ForegroundColor DarkGray
Write-Host "  • CPU: $($SystemProfile.CPU.Vendor) $($SystemProfile.CPU.Cores)c/$($SystemProfile.CPU.Threads)t" -ForegroundColor DarkGray
Write-Host "  • GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)" -ForegroundColor DarkGray
Write-Host "  • Almacenamiento: $systemDiskType" -ForegroundColor DarkGray

Write-Host "`n🎯 PUNTUACIÓN:" -ForegroundColor Cyan
Write-Host "  • Puntuación total: $ProfileScore puntos" -ForegroundColor DarkGray
Write-Host "  • Nivel Hardware: $HardwareProfile" -ForegroundColor DarkGray
Write-Host "  • Estrategia: $($SystemProfile.Strategy)" -ForegroundColor DarkGray
Write-Host "  • Rendimiento: $relativeScore% del óptimo para tu hardware" -ForegroundColor $(switch($relativeScore){ {$_ -ge 85}{'Green'} {$_ -ge 70}{'Yellow'} default{'Red'}})

Write-Host "✔ Evaluación contextual completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 2] Power Plan
# =====================================================================
Write-Host "[FASE 2] Configuración de Power Plan" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

Write-Host "  » Aplicando plan de energía..." -ForegroundColor DarkGray
Write-Host ""

try {
    $currentScheme = powercfg /getactivescheme
    Write-Host "  • Esquema actual: $($currentScheme | Select-String -Pattern 'GUID' | ForEach-Object { $_.ToString().Split(':')[1].Trim() })" -ForegroundColor DarkGray
} catch {
    Write-Host "  ⚠️  No se pudo determinar esquema actual" -ForegroundColor Yellow
}

$shouldRunPhase2 = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq 2 }).Count -gt 0
} else {
    $true
}

if ($shouldRunPhase2 -and -not $GlobalConfig.SafeMode) {
    try {
        switch ($HardwareProfile) {
            "LIVIANO" {
                powercfg /setactive SCHEME_MIN 2>&1 | Out-Null
                Write-Host "  • Power Plan: Alto Rendimiento" -ForegroundColor Green
            }
            "ENTUSIASTA" {
                $ultimateResult = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
                if ($ultimateResult -match "Error") {
                    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
                    Write-Host "  • Power Plan: Alto Rendimiento" -ForegroundColor Green
                } else {
                    powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
                    Write-Host "  • Power Plan: Ultimate Performance" -ForegroundColor Green
                }
            }
            default {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
                Write-Host "  • Power Plan: Equilibrado" -ForegroundColor Green
            }
        }

        if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.Platform.HasBattery) {
            Write-Host ""
            Write-Host "  » Ajustando para laptop..." -ForegroundColor DarkGray
            powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 2>&1 | Out-Null
            powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>&1 | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 2>&1 | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>&1 | Out-Null
            Write-Host "  • CPU: 100% en AC y batería" -ForegroundColor Green
        }

        $newScheme = powercfg /getactivescheme
        if ($newScheme -match "GUID") {
            Write-Host "  • Power Plan aplicado correctamente" -ForegroundColor Green
        }

    } catch {
        Write-Host "  ⚠️  Error configurando Power Plan" -ForegroundColor Red
    }
} else {
    Write-Host "  • [OMITIDO] Power Plan recomendado: $HardwareProfile" -ForegroundColor DarkGray
}

Write-Host "✔ Configuración de Power Plan completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 3] Optimización de memoria basada en hardware
# =====================================================================
Write-Host "[FASE 3] Optimización de memoria" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$shouldRunPhase3 = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq 3 }).Count -gt 0
} else {
    $true
}

$tweaksCorregidos = 0
$tweaksAjustados = 0

if ($shouldRunPhase3) {
    Write-Host "  » Aplicando ajustes específicos para tu hardware..." -ForegroundColor DarkGray
    Write-Host ""

    # TWEAKS SIEMPRE PELIGROSOS
    $alwaysBadTweaks = @(
        @{
            Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Name="DisablePagingExecutive"
            Accion="ELIMINAR"
        },
        @{
            Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Name="IoPageLockLimit"
            Accion="ELIMINAR"
        },
        @{
            Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Name="PagedPoolSize"
            Accion="ELIMINAR"
        }
    )

    # TWEAKS CONDICIONALES BASADOS EN HARDWARE
    $conditionalTweaks = @()

    if ($esHDD) {
        Write-Host "  💾 HDD detectado: optimizando para disco mecánico..." -ForegroundColor Cyan
        $conditionalTweaks += @{
            Path="HKLM:\SYSTEM\CurrentControlSet\Services\SysMain"
            Name="Start"
            Valor=3
            Razon="SuperFetch beneficioso para HDD"
        }
    } elseif ($esSSD) {
        Write-Host "  💿 SSD detectado: optimizando para almacenamiento flash..." -ForegroundColor Cyan
    }

    if ($ramGB -lt 8) {
        Write-Host "  📉 RAM baja detectada: optimizando uso de memoria..." -ForegroundColor Yellow
        $conditionalTweaks += @{
            Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
            Name="AlwaysUnloadDLL"
            Valor=1
            Razon="Liberar RAM en sistemas con poca memoria"
        }
    } elseif ($ramGB -ge 32) {
        Write-Host "  📈 RAM abundante detectada: ajustando para alto rendimiento..." -ForegroundColor Green
    }

    # EJECUTAR CORRECCIONES
    foreach ($tweak in $alwaysBadTweaks) {
        if (Test-Path $tweak.Path) {
            $existe = Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
            if ($existe -and -not $GlobalConfig.SafeMode -and $tweak.Accion -eq "ELIMINAR") {
                Remove-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
                $tweaksCorregidos++
            }
        }
    }

    foreach ($tweak in $conditionalTweaks) {
        if (Test-Path $tweak.Path) {
            $valorActual = Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
            
            if ($valorActual -and -not $GlobalConfig.SafeMode) {
                $currentVal = $valorActual.$($tweak.Name)
                if ($currentVal -ne $tweak.Valor) {
                    Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Valor -ErrorAction SilentlyContinue
                    $tweaksAjustados++
                }
            }
        }
    }

    # VERIFICAR MEMORIA VIRTUAL
    Write-Host ""
    Write-Host "  » Verificando memoria virtual..." -ForegroundColor DarkGray
    try {
        $cs = Get-CimInstance Win32_ComputerSystem
        if ($cs.AutomaticManagedPagefile) {
            Write-Host "  • Gestión automática de pagefile: ACTIVADA ✓" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Gestión manual de pagefile detectada" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  • Estado: No verificado" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  📊 RESULTADOS:" -ForegroundColor Cyan
    if ($tweaksCorregidos -gt 0 -or $tweaksAjustados -gt 0) {
        Write-Host "  • Tweaks peligrosos eliminados: $tweaksCorregidos" -ForegroundColor Green
        Write-Host "  • Ajustes específicos para tu hardware: $tweaksAjustados" -ForegroundColor Green
    } else {
        Write-Host "  • No se requirieron cambios significativos" -ForegroundColor Green
    }

} else {
    Write-Host "  • [OMITIDO] Optimización de memoria" -ForegroundColor DarkGray
}

Write-Host "✔ Optimización de memoria completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 4] Optimización de red
# =====================================================================
Write-Host "[FASE 4] Optimización de red" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$shouldRunPhase4 = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq 4 }).Count -gt 0
} else {
    $true
}

if ($shouldRunPhase4 -and -not $GlobalConfig.SafeMode) {
    Write-Host "  » Aplicando configuración optimizada de red..." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  📊 CONEXIÓN DETECTADA:" -ForegroundColor Cyan
    Write-Host "  • Tipo: $($SystemProfileDetallado.Network.ConnectionType)" -ForegroundColor DarkGray
    
    if ($SystemProfileDetallado.Network.HasProxy) {
        Write-Host "  • Proxy detectado: $($SystemProfileDetallado.Network.ProxyServer)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  » Ajustando configuración TCP..." -ForegroundColor DarkGray
    
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    Write-Host "  • TCP Auto-tuning: Normal" -ForegroundColor DarkGray
    
    netsh int tcp set global rss=enabled 2>&1 | Out-Null
    Write-Host "  • TCP RSS: Habilitado" -ForegroundColor DarkGray
    
    if ($SystemProfileDetallado.Network.HasProxy) {
        netsh int tcp set global timestamps=disabled 2>&1 | Out-Null
        Write-Host "  • TCP Timestamps: Deshabilitado (optimizado para proxy)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "  » Mantenimiento de DNS..." -ForegroundColor DarkGray
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Host "  • DNS: Caché limpiada" -ForegroundColor Green
    } catch {
        Write-Host "  • DNS: No se pudo limpiar caché" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  ✅ Red optimizada" -ForegroundColor Green
} else {
    Write-Host "  • [OMITIDO] Optimización de red" -ForegroundColor DarkGray
}

Write-Host "✔ Optimización de red completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 5] Balance de prioridades CPU
# =====================================================================
Write-Host "[FASE 5] Balance de prioridades CPU" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$shouldRunPhase5 = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq 5 }).Count -gt 0
} else {
    $true
}

if ($shouldRunPhase5 -and -not $GlobalConfig.SafeMode) {
    Write-Host "  » Ajustando balance según perfil..." -ForegroundColor DarkGray
    Write-Host ""

    $priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

    try {
        if (-not (Test-Path $priorityPath)) {
            New-Item -Path $priorityPath -Force | Out-Null
        }
        Set-ItemProperty -Path $priorityPath -Name Win32PrioritySeparation -Value $CPUValue -Type DWord -ErrorAction Stop
        Write-Host "  • Prioridad CPU configurada: $CPUValue" -ForegroundColor Green
        Write-Host "    (Perfil: $HardwareProfile, Estrategia: $($SystemProfile.Strategy))" -ForegroundColor DarkGray
    } catch {
        Write-Host "  ⚠️  Error aplicando prioridad CPU" -ForegroundColor Red
    }
} else {
    Write-Host "  • [OMITIDO] Balance de prioridades CPU" -ForegroundColor DarkGray
}

Write-Host "✔ Balance de prioridades completado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 6] Optimización de almacenamiento
# =====================================================================
Write-Host "[FASE 6] Optimización de almacenamiento" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$shouldRunPhase6 = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq 6 }).Count -gt 0
} else {
    $true
}

if ($shouldRunPhase6 -and $systemDiskType -ne "Unknown") {
    Write-Host "  » Optimizando almacenamiento..." -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  📀 DISCO DEL SISTEMA: $systemDiskType" -ForegroundColor Cyan
    
    Write-Host "  » Aplicando ajustes seguros..." -ForegroundColor DarkGray
    
    $currentLastAccess = fsutil behavior query disablelastaccess 2>&1
    if ($currentLastAccess -notmatch "=\s*1" -and -not $GlobalConfig.SafeMode) {
        fsutil behavior set disablelastaccess 1 2>&1 | Out-Null
        Write-Host "  • NTFS LastAccess: Deshabilitado" -ForegroundColor Green
    } else {
        Write-Host "  • NTFS LastAccess: Ya deshabilitado" -ForegroundColor DarkGray
    }
    
    switch ($systemDiskType) {
        "NVMe" {
            Write-Host "  • NVMe: Configuración de alto rendimiento" -ForegroundColor DarkGray
        }
        "SSD" {
            Write-Host "  • SSD: Configuración equilibrada" -ForegroundColor DarkGray
        }
        "HDD" {
            Write-Host "  • HDD: Prefetch/SuperFetch habilitados" -ForegroundColor DarkGray
        }
    }
    
    if ($systemDiskType -in @("NVMe", "SSD") -and -not $GlobalConfig.SafeMode) {
        Write-Host "  » Ejecutando optimización para almacenamiento flash..." -ForegroundColor DarkGray
        try {
            $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive.Replace(":", "")
            Optimize-Volume -DriveLetter $systemDrive -ReTrim -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  • TRIM/Optimización: Ejecutado" -ForegroundColor Green
        } catch {
            Write-Host "  • TRIM: Windows gestiona automáticamente" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  • [OMITIDO] Optimización de almacenamiento" -ForegroundColor DarkGray
}

Write-Host "✔ Optimización de almacenamiento completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 7] Optimización de interfaz
# =====================================================================
Write-Host "[FASE 7] Optimización de interfaz" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$shouldRunPhase7 = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq 7 }).Count -gt 0
} else {
    $true
}

if ($shouldRunPhase7 -and -not $GlobalConfig.SafeMode) {
    Write-Host "  » Ajustando retrasos UI..." -ForegroundColor DarkGray
    Write-Host ""

    $delayConfig = @{
        ExplorerSerializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
        ExplorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    }

    try {
        if (-not (Test-Path $delayConfig.ExplorerSerializePath)) {
            New-Item -Path $delayConfig.ExplorerSerializePath -Force | Out-Null
        }
        Set-ItemProperty -Path $delayConfig.ExplorerSerializePath -Name StartupDelayInMSec -Type DWord -Value $recommendedDelay -ErrorAction SilentlyContinue
        Write-Host "  • Retraso Explorer ajustado: ${recommendedDelay}ms" -ForegroundColor Green
        Write-Host "    (optimizado para $systemDiskType)" -ForegroundColor DarkGray
    } catch {
        Write-Host "  ⚠️  Error ajustando retraso Explorer" -ForegroundColor Yellow
    }
    
    try {
        Set-ItemProperty -Path $delayConfig.ExplorerAdvancedPath -Name DesktopProcess -Type DWord -Value 1 -ErrorAction SilentlyContinue
        Write-Host "  • Proceso escritorio: Separado" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Error configurando proceso escritorio" -ForegroundColor Yellow
    }
} else {
    Write-Host "  • [OMITIDO] Optimización de interfaz" -ForegroundColor DarkGray
}

Write-Host "✔ Optimización de interfaz completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE Hotfixes] Ajustes rápidos
# =====================================================================
Write-Host "[HOTFIXES] Ajustes rápidos" -ForegroundColor Magenta
Write-Host ("─" * 70) -ForegroundColor DarkGray

$shouldRunHotfixes = if ($opcion -eq "2") {
    ($selectedOptimizations | Where-Object { $_.Fase -eq "Hotfixes" }).Count -gt 0
} else {
    $true
}

$hotfixesApplied = @()

if ($shouldRunHotfixes -and -not $GlobalConfig.SafeMode) {
    try {
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        if ($wuService.Status -ne "Running") {
            Start-Service wuauserv -ErrorAction SilentlyContinue
            $hotfixesApplied += "Servicio Windows Update reactivado"
        }
    } catch {}

    try {
        ipconfig /flushdns 2>&1 | Out-Null
        ipconfig /registerdns 2>&1 | Out-Null
        $hotfixesApplied += "Cache DNS limpiada"
    } catch {}

    if ($SystemProfile.Storage.SystemDiskType -eq "HDD" -and $totalRAM -lt 8) {
        try {
            $prefetchPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
            Set-ItemProperty -Path $prefetchPath -Name EnablePrefetcher -Value 3 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $prefetchPath -Name EnableSuperfetch -Value 3 -ErrorAction SilentlyContinue
            $hotfixesApplied += "Prefetch/SuperFetch optimizado para HDD"
        } catch {}
    }

    if ($hotfixesApplied.Count -gt 0) {
        Write-Host "  🔧 Hotfixes aplicados:" -ForegroundColor Cyan
        $hotfixesApplied | ForEach-Object { Write-Host "    • $_" -ForegroundColor Green }
    } else {
        Write-Host "  ✅ No se requirieron hotfixes inmediatos" -ForegroundColor Green
    }
} else {
    Write-Host "  • [OMITIDO] Ajustes rápidos" -ForegroundColor DarkGray
}
Write-Host ""

# =====================================================================
# [FASE 9] Resumen final
# =====================================================================
Write-Host "[FASE 9] Resumen final" -ForegroundColor Yellow
Write-Host ("─" * 70) -ForegroundColor DarkGray

$appliedCount = 0
if ($shouldRunPhase2 -and -not $GlobalConfig.SafeMode) { $appliedCount++ }
if ($shouldRunPhase3) { $appliedCount++ }
if ($shouldRunPhase4 -and -not $GlobalConfig.SafeMode) { $appliedCount++ }
if ($shouldRunPhase5 -and -not $GlobalConfig.SafeMode) { $appliedCount++ }
if ($shouldRunPhase6 -and -not $GlobalConfig.SafeMode) { $appliedCount++ }
if ($shouldRunPhase7 -and -not $GlobalConfig.SafeMode) { $appliedCount++ }
if ($shouldRunHotfixes -and -not $GlobalConfig.SafeMode -and $hotfixesApplied.Count -gt 0) { $appliedCount++ }

Write-Host "✅ VERIFICACIÓN FINAL:" -ForegroundColor Green
if ($shouldRunPhase2 -and -not $GlobalConfig.SafeMode) { 
    Write-Host "1. Power Plan $HardwareProfile aplicado ✓" -ForegroundColor Gray
}
if ($shouldRunPhase3) { 
    Write-Host "2. Tweaks peligrosos eliminados: $tweaksCorregidos ✓" -ForegroundColor Gray
}
if ($shouldRunPhase4 -and -not $GlobalConfig.SafeMode) { 
    Write-Host "3. Network optimizado ✓" -ForegroundColor Gray
}
if ($shouldRunPhase5 -and -not $GlobalConfig.SafeMode) { 
    Write-Host "4. CPU Priority: $CPUValue ✓" -ForegroundColor Gray
}
if ($shouldRunPhase6 -and -not $GlobalConfig.SafeMode) { 
    Write-Host "5. Storage optimizado para $systemDiskType ✓" -ForegroundColor Gray
}
if ($shouldRunPhase7 -and -not $GlobalConfig.SafeMode) { 
    Write-Host "6. UI delays ajustados para $systemDiskType ✓" -ForegroundColor Gray
}
if ($shouldRunHotfixes -and -not $GlobalConfig.SafeMode -and $hotfixesApplied.Count -gt 0) {
    Write-Host "7. Hotfixes aplicados: $($hotfixesApplied.Count) ✓" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 RESUMEN DE OPTIMIZACIONES:" -ForegroundColor Cyan
Write-Host "  • Total recomendadas: $neededOptimizations" -ForegroundColor DarkGray
Write-Host "  • Total aplicadas: $appliedCount" -ForegroundColor DarkGray
Write-Host "  • Modo: $(if($GlobalConfig.SafeMode){'Solo análisis'}else{'Optimización activa'})" -ForegroundColor $(if($GlobalConfig.SafeMode){'Yellow'}else{'Green'})

Save-SystemProfileReport -SystemProfileDetallado $SystemProfileDetallado -FinalProfile $FinalProfile -OptimizationPlan $OptimizationPlan -appliedCount $appliedCount -GlobalConfig $GlobalConfig -tweaksCorregidos $tweaksCorregidos -tweaksAjustados $tweaksAjustados

Write-Host ""
Write-Host "🎯 RENDIMIENTO CONTEXTUAL:" -ForegroundColor Cyan
Write-Host "  • Categoría hardware: $HardwareProfile" -ForegroundColor DarkGray
Write-Host "  • Tu puntuación: $ProfileScore/$($categoryInfo.MaxScore)" -ForegroundColor DarkGray
Write-Host "  • Rendimiento relativo: $relativeScore% del óptimo para tu hardware" -ForegroundColor $(switch($relativeScore){ {$_ -ge 85}{'Green'} {$_ -ge 70}{'Yellow'} default{'Red'}})

$graphLength = [math]::Round(($ProfileScore / $categoryInfo.MaxScore) * 20)
$graphBar = "█" * $graphLength + "░" * (20 - $graphLength)
Write-Host "  [0%] [$graphBar] [100%]" -ForegroundColor Cyan

Write-Host ""
Write-Host "⚠️  RECOMENDACIÓN FINAL" -ForegroundColor Yellow
$finalRecommendation = switch ($HardwareProfile) {
    "ENTUSIASTA" { "Sistema potente. Considera actualizar drivers para máximo rendimiento." }
    "EQUILIBRADO" { "Hardware moderno. Realiza mantenimiento básico periódico." }
    "ESTÁNDAR" { "Sistema estándar. Mantén Windows Update activado." }
    "LIVIANO" { "Hardware limitado. Minimiza programas en inicio." }
}
Write-Host "• $finalRecommendation" -ForegroundColor Green

if ($appliedCount -gt 0 -and -not $GlobalConfig.SafeMode) {
    Write-Host "• Reinicia el sistema para aplicar todas las configuraciones." -ForegroundColor Green
}

Write-Host ""
Write-Host "   Confía en Windows. Sabe lo que hace." -ForegroundColor DarkGray

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Windows de Mente v1.0 | Optimización Inteligente de Windows" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

try {
    [Console]::Beep(2000, 300)
    Start-Sleep -Milliseconds 100
    [Console]::Beep(1500, 200)
} catch {}

if ($appliedCount -gt 0 -and -not $GlobalConfig.SafeMode) {
    $reinicio = Read-Host "¿Reiniciar ahora para aplicar todas las configuraciones? (S/N)"
    if ($reinicio -eq "S" -or $reinicio -eq "s") {
        Write-Host "Reiniciando en 10 segundos..." -ForegroundColor Yellow
        Write-Host "Presiona Ctrl+C para cancelar" -ForegroundColor DarkGray
        Write-Host ""
        
        10..1 | ForEach-Object {
            Write-Host "  $_..." -ForegroundColor DarkGray
            Start-Sleep 1
        }
        
        try {
            Restart-Computer -Force
        } catch {
            Write-Host "  ⚠️  No se pudo reiniciar automáticamente" -ForegroundColor Red
            Write-Host "  Por favor, reinicia manualmente cuando sea conveniente." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Reinicia manualmente cuando sea conveniente." -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  No se requirieron cambios o modo seguro activado" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Gracias por usar Windows de Mente v1.0" -ForegroundColor Cyan
Write-Host "   Optimización Inteligente de Windows" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
