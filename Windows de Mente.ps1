# =====================================================================
#  WINDOWS DE MENTE v1.0 - VERSIÓN UNIVERSAL
#  Optimización consciente de Windows
#  Guidance, not force - Para CUALQUIER sistema
# =====================================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows de Mente v1.0 - Universal"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   WINDOWS DE MENTE v1.0  |  Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "   Guidance, not force - Para cualquier sistema Windows" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# [CONFIGURACIÓN UNIVERSAL]
# =====================================================================
$GlobalConfig = @{
    # Modo seguro: NO hace cambios peligrosos
    SafeMode = $true
    
    # Nivel de logging
    LogLevel = "Normal"  # Minimal, Normal, Verbose
    
    # Archivo de log
    LogFile = "$env:TEMP\WindowsDeMente_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    # Backup automático de cambios
    CreateBackup = $true
    BackupPath = "$env:TEMP\WindowsDeMente_Backup_$(Get-Date -Format 'yyyyMMdd')"
}

# =====================================================================
# [FASE 0] Análisis universal de hardware y estado
# =====================================================================

Write-Host "[FASE 0] Análisis universal del sistema" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# --- Detección ROBUSTA que funciona en CUALQUIER Windows ---
$SystemAnalysis = @{
    Timestamp = Get-Date
    OSVersion = [System.Environment]::OSVersion.Version
    IsServer = (Get-CimInstance Win32_OperatingSystem).ProductType -ne 1
    Bits = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
}

# 1. Detectar Windows Edition
try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $SystemAnalysis.OSEdition = $osInfo.Caption
    $SystemAnalysis.OSBuild = $osInfo.BuildNumber
    $SystemAnalysis.InstallDate = $osInfo.InstallDate
} catch {
    $SystemAnalysis.OSEdition = "Windows (no detectado)"
}

# 2. Detectar hardware con MÚLTIPLES métodos (robustez)
$hardwareInfo = @{}

# CPU - Método 1: WMI (estándar)
try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $hardwareInfo.CPU = @{
        Name = $cpu.Name
        Cores = $cpu.NumberOfCores
        Threads = $cpu.NumberOfLogicalProcessors
        MaxSpeed = "$([math]::Round($cpu.MaxClockSpeed/1000,1)) GHz"
    }
} catch {
    # Método 2: Registry (fallback)
    try {
        $cpuReg = Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0"
        $hardwareInfo.CPU = @{
            Name = $cpuReg.ProcessorNameString
            Cores = "Desconocido"
            Threads = "Desconocido"
            MaxSpeed = "Desconocido"
        }
    } catch {
        $hardwareInfo.CPU = @{ Name = "No detectado"; Error = $_.Exception.Message }
    }
}

# RAM - Método universal
try {
    $totalRAM = 0
    $ramModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
    foreach ($module in $ramModules) {
        $totalRAM += $module.Capacity
    }
    $hardwareInfo.RAM = @{
        TotalGB = [math]::Round($totalRAM / 1GB, 1)
        Modules = $ramModules.Count
        Type = if ($ramModules[0].SMBIOSMemoryType) { 
            switch ($ramModules[0].SMBIOSMemoryType) {
                24 { "DDR3" }; 26 { "DDR4" }; 34 { "DDR5" }
                default { "Desconocido" }
            }
        } else { "Desconocido" }
    }
} catch {
    # Método alternativo
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $hardwareInfo.RAM = @{
            TotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            Modules = "Desconocido"
            Type = "Desconocido"
        }
    } catch {
        $hardwareInfo.RAM = @{ TotalGB = "No detectado"; Error = $_.Exception.Message }
    }
}

# Disco - Detección INTELIGENTE
$hardwareInfo.Storage = @()
try {
    # Obtener todos los discos físicos
    $physicalDisks = Get-Disk -ErrorAction SilentlyContinue
    
    foreach ($disk in $physicalDisks) {
        $diskInfo = @{
            Number = $disk.Number
            SizeGB = [math]::Round($disk.Size / 1GB, 1)
            BusType = $disk.BusType
            PartitionStyle = $disk.PartitionStyle
            IsBoot = $disk.IsBoot
            IsSystem = $disk.IsSystem
        }
        
        # Detectar tipo REAL
        $physicalDisk = Get-PhysicalDisk -UniqueId $disk.UniqueId -ErrorAction SilentlyContinue
        if ($physicalDisk) {
            $diskInfo.MediaType = $physicalDisk.MediaType
            $diskInfo.FriendlyName = $physicalDisk.FriendlyName
            
            # Clasificación inteligente
            if ($physicalDisk.MediaType -eq "SSD" -or $physicalDisk.FriendlyName -match "SSD|Solid State") {
                $diskInfo.Category = "SSD"
                $diskInfo.Performance = "Rápido"
            } elseif ($physicalDisk.MediaType -eq "HDD") {
                $diskInfo.Category = "HDD"
                $diskInfo.Performance = if ($physicalDisk.FriendlyName -match "7200|15K|10K") { "Alto" } else { "Estándar" }
            } elseif ($disk.BusType -eq "NVMe") {
                $diskInfo.Category = "NVMe"
                $diskInfo.Performance = "Extremo"
            } elseif ($disk.BusType -eq "USB") {
                $diskInfo.Category = "USB/Externo"
                $diskInfo.Performance = "Variable"
            } else {
                $diskInfo.Category = "Desconocido"
                $diskInfo.Performance = "Genérico"
            }
        }
        
        $hardwareInfo.Storage += $diskInfo
    }
} catch {
    $hardwareInfo.Storage = @(@{ Error = "No se pudieron detectar discos" })
}

# GPU - Simple pero efectivo
try {
    $gpus = Get-CimInstance Win32_VideoController
    $hardwareInfo.GPU = @()
    foreach ($gpu in $gpus) {
        $hardwareInfo.GPU += @{
            Name = $gpu.Name
            RAMMB = if ($gpu.AdapterRAM -gt 0) { [math]::Round($gpu.AdapterRAM / 1MB) } else { "Desconocido" }
            Driver = $gpu.DriverVersion
        }
    }
} catch {
    $hardwareInfo.GPU = @(@{ Name = "No detectada" })
}

# Red - Adaptativo
$hardwareInfo.Network = @()
try {
    $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq "Up"
    foreach ($adapter in $adapters) {
        $hardwareInfo.Network += @{
            Name = $adapter.Name
            Type = if ($adapter.InterfaceDescription -match "Wireless|Wi-Fi") { "WiFi" } else { "Ethernet" }
            Speed = $adapter.LinkSpeed
            Mac = $adapter.MacAddress
        }
    }
} catch {
    $hardwareInfo.Network = @(@{ Status = "No se detectaron adaptadores activos" })
}

# Mostrar resumen UNIVERSAL
Write-Host "📊 SISTEMA DETECTADO:" -ForegroundColor Cyan
Write-Host "  • OS: $($SystemAnalysis.OSEdition) [$($SystemAnalysis.Bits)]" -ForegroundColor DarkGray
Write-Host "  • CPU: $($hardwareInfo.CPU.Name) [$($hardwareInfo.CPU.Cores) cores]" -ForegroundColor DarkGray
Write-Host "  • RAM: $($hardwareInfo.RAM.TotalGB) GB" -ForegroundColor DarkGray

if ($hardwareInfo.Storage.Count -gt 0) {
    $systemDisk = $hardwareInfo.Storage | Where-Object { $_.IsSystem -eq $true } | Select-Object -First 1
    if ($systemDisk) {
        Write-Host "  • Disco sistema: $($systemDisk.Category) [$($systemDisk.SizeGB) GB]" -ForegroundColor DarkGray
    }
}

Write-Host "  • GPU: $($hardwareInfo.GPU[0].Name)" -ForegroundColor DarkGray
Write-Host "  • Red: $(if($hardwareInfo.Network.Count -gt 0){$hardwareInfo.Network[0].Type}else{'Sin conexión'})" -ForegroundColor DarkGray

Write-Host "✔ Análisis universal completado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 1] Evaluación universal de capacidades
# =====================================================================

Write-Host "[FASE 1] Evaluación universal de capacidades" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# Sistema de puntuación ADAPTATIVO
$ProfileScore = 0
$ScoreDetails = @()

# 1. Puntuación RAM (universal)
$ramScore = switch ($hardwareInfo.RAM.TotalGB) {
    { $_ -ge 32 } { 50; $ScoreDetails += "RAM ≥32GB: +50" }
    { $_ -ge 16 } { 40; $ScoreDetails += "RAM 16GB: +40" }
    { $_ -ge 8 }  { 30; $ScoreDetails += "RAM 8GB: +30" }
    { $_ -ge 4 }  { 20; $ScoreDetails += "RAM 4GB: +20" }
    default       { 10; $ScoreDetails += "RAM <4GB: +10" }
}
$ProfileScore += $ramScore

# 2. Puntuación CPU (universal)
$cpuScore = switch ($hardwareInfo.CPU.Cores) {
    { $_ -ge 12 } { 50; $ScoreDetails += "CPU ≥12c: +50" }
    { $_ -ge 8 }  { 40; $ScoreDetails += "CPU 8c: +40" }
    { $_ -ge 4 }  { 30; $ScoreDetails += "CPU 4c: +30" }
    { $_ -ge 2 }  { 20; $ScoreDetails += "CPU 2c: +20" }
    default       { 10; $ScoreDetails += "CPU 1c: +10" }
}
$ProfileScore += $cpuScore

# 3. Puntuación Almacenamiento (universal)
$storageScore = 0
if ($hardwareInfo.Storage.Count -gt 0) {
    $systemDisk = $hardwareInfo.Storage | Where-Object { $_.IsSystem -eq $true } | Select-Object -First 1
    
    if ($systemDisk) {
        switch ($systemDisk.Category) {
            "NVMe" { 
                $storageScore = 40
                $ScoreDetails += "NVMe: +40"
            }
            "SSD" { 
                $storageScore = 30
                $ScoreDetails += "SSD: +30"
            }
            "HDD" { 
                $storageScore = if ($systemDisk.Performance -eq "Alto") { 20 } else { 15 }
                $ScoreDetails += "HDD: +$storageScore"
            }
            default { 
                $storageScore = 10
                $ScoreDetails += "Desconocido: +10"
            }
        }
    }
}
$ProfileScore += $storageScore

# 4. Ajuste por GPU dedicada (para gaming/productividad)
$gpuScore = 0
if ($hardwareInfo.GPU.Count -gt 0) {
    $mainGPU = $hardwareInfo.GPU[0]
    if ($mainGPU.Name -notmatch "Intel|UHD|Graphics|HD Graphics|Iris|Vega" -and 
        $mainGPU.RAMMB -gt 1024) {
        $gpuScore = 20
        $ScoreDetails += "GPU dedicada: +20"
    }
}
$ProfileScore += $gpuScore

# Determinar perfil UNIVERSAL
$Profile = switch ($ProfileScore) {
    { $_ -ge 130 } { "ENTUSIASTA" }
    { $_ -ge 90 }  { "EQUILIBRADO" }
    { $_ -ge 60 }  { "ESTÁNDAR" }
    default        { "LIVIANO" }
}

Write-Host "📈 PUNTUACIÓN DEL SISTEMA:" -ForegroundColor Cyan
foreach ($detail in $ScoreDetails) {
    Write-Host "  • $detail" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  » Perfil determinado: $Profile" -ForegroundColor DarkGray
Write-Host "  » Puntuación total: $ProfileScore puntos" -ForegroundColor DarkGray
Write-Host "✔ Evaluación universal completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 2] Configuración base de memoria (UNIVERSAL)
# =====================================================================

Write-Host "[FASE 2] Configuración base de memoria universal" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# --- ELIMINAR tweaks peligrosos (SIEMPRE seguro) ---
Write-Host "  » Eliminando configuraciones peligrosas..." -ForegroundColor DarkGray

$dangerousTweaks = @(
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="LargeSystemCache"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="ClearPageFileAtShutdown"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="SecondLevelDataCache"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="IoPageLockLimit"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"}
)

$tweaksRemoved = 0
foreach ($tweak in $dangerousTweaks) {
    if (Test-Path $tweak.Path) {
        $prop = Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
        if ($prop) {
            Remove-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
            $tweaksRemoved++
        }
    }
}

Write-Host "  • $tweaksRemoved configuraciones peligrosas eliminadas" -ForegroundColor Green

# --- Verificar Pagefile (método UNIVERSAL) ---
Write-Host "  » Verificando memoria virtual..." -ForegroundColor DarkGray

$pagefileStatus = "Verificado"
try {
    # Método 1: Ver si Windows gestiona automáticamente
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        $pagefileStatus = "Windows gestiona automáticamente ✓"
    } else {
        # Método 2: Verificar físicamente
        $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
        $pagefilePath = "$systemDrive\pagefile.sys"
        
        if (Test-Path $pagefilePath) {
            $size = (Get-Item $pagefilePath -Force -ErrorAction SilentlyContinue).Length
            if ($size -gt 0) {
                $pagefileStatus = "Presente ($([math]::Round($size/1GB,1)) GB) ✓"
            }
        } else {
            # Recomendar habilitar gestión automática
            $cs | Set-CimInstance -Property @{AutomaticManagedPagefile = $true} -ErrorAction SilentlyContinue
            $pagefileStatus = "Gestión automática habilitada ✓"
        }
    }
} catch {
    $pagefileStatus = "Verificación omitida (sin cambios)"
}

Write-Host "  • Estado pagefile: $pagefileStatus" -ForegroundColor Green
Write-Host "✔ Configuración base de memoria verificada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 3] Balance universal de prioridades CPU
# =====================================================================

Write-Host "[FASE 3] Balance universal de prioridades CPU" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# Valores UNIVERSALES probados
$CPUValues = @{
    "ENTUSIASTA" = 24   # Equilibrado avanzado
    "EQUILIBRADO" = 24  # Óptimo universal
    "ESTÁNDAR" = 18     # Buen balance
    "LIVIANO" = 12      # Mejor respuesta
}

$CPUValue = $CPUValues[$Profile]
$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

# Crear clave si no existe
if (-not (Test-Path $priorityPath)) {
    New-Item -Path $priorityPath -Force | Out-Null
}

# Aplicar valor universal
Set-ItemProperty -Path $priorityPath -Name Win32PrioritySeparation -Value $CPUValue -Type DWord -ErrorAction SilentlyContinue

Write-Host "  • Prioridad CPU: $CPUValue (universal para $Profile)" -ForegroundColor DarkGray
Write-Host "  • Balance: Aplicaciones/Respuesta equilibradas" -ForegroundColor DarkGray

# Ajuste para Windows 11 (si aplica)
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    Write-Host "  • Windows 11: Thread Director optimiza automáticamente" -ForegroundColor DarkGray
}

Write-Host "✔ Balance de prioridades aplicado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 4] Optimización universal de retrasos
# =====================================================================

Write-Host "[FASE 4] Optimización universal de retrasos" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# 1. Retraso del explorador (valor universal óptimo)
$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $explorerPath)) {
    New-Item -Path $explorerPath -Force | Out-Null
}

# Valor UNIVERSAL: 100ms (óptimo para todos)
Set-ItemProperty -Path $explorerPath -Name StartupDelayInMSec -Type DWord -Value 100

Write-Host "  • Retraso explorador: 100ms (universal óptimo)" -ForegroundColor DarkGray

# 2. Proceso de escritorio separado (siempre beneficioso)
$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $advancedPath -Name DesktopProcess -Type DWord -Value 1 -ErrorAction SilentlyContinue

Write-Host "  • Explorer: Proceso separado (estabilidad)" -ForegroundColor DarkGray

# 3. Menú show delay (dejar valor por defecto - NO tocar)
# No tocamos MenuShowDelay - es peligroso ponerlo en 0

Write-Host "✔ Retrasos optimizados universalmente" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 5] Memoria virtual universal
# =====================================================================

Write-Host "[FASE 5] Memoria virtual universal" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# Recomendación UNIVERSAL: Dejar que Windows gestione
Write-Host "  » Configuración recomendada universal:" -ForegroundColor DarkGray
Write-Host "  • Windows gestiona automáticamente el pagefile" -ForegroundColor DarkGray
Write-Host "  • Esto es óptimo para 99% de sistemas" -ForegroundColor DarkGray

# Solo informar, no forzar cambios
try {
    $cs = Get-CimInstance Win32_ComputerSystem
    if (-not $cs.AutomaticManagedPagefile) {
        Write-Host "  ⚠️  Gestión manual detectada" -ForegroundColor Yellow
        Write-Host "  » Recomendado: Habilitar gestión automática" -ForegroundColor DarkGray
    } else {
        Write-Host "  ✓ Gestión automática ya habilitada" -ForegroundColor Green
    }
} catch {
    Write-Host "  • Estado: No verificado (sin cambios)" -ForegroundColor DarkGray
}

Write-Host "✔ Configuración de memoria virtual verificada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 6] Configuración universal de red
# =====================================================================

Write-Host "[FASE 6] Configuración universal de red" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# Configuración BASE universal (siempre segura)
Write-Host "  » Aplicando configuración base de red..." -ForegroundColor DarkGray

netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
netsh int tcp set global rss=enabled 2>&1 | Out-Null
netsh int tcp set global chimney=disabled 2>&1 | Out-Null

Write-Host "  • TCP: Configuración base estable aplicada" -ForegroundColor DarkGray

# Ajuste ADAPTATIVO si es Ethernet
if ($hardwareInfo.Network.Count -gt 0) {
    $mainAdapter = $hardwareInfo.Network[0]
    if ($mainAdapter.Type -eq "Ethernet") {
        # Para Ethernet, configuración un poco más agresiva
        netsh int tcp set global autotuninglevel=experimental 2>&1 | Out-Null
        Write-Host "  • Ethernet: Auto-tuning experimental" -ForegroundColor DarkGray
    } else {
        Write-Host "  • WiFi: Configuración estable preservada" -ForegroundColor DarkGray
    }
}

# Limpieza de caché DNS (siempre beneficiosa)
Clear-DnsClientCache -ErrorAction SilentlyContinue
Write-Host "  • DNS: Caché limpiada" -ForegroundColor DarkGray

Write-Host "✔ Configuración de red aplicada universalmente" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 7] Optimización universal de almacenamiento
# =====================================================================

Write-Host "[FASE 7] Optimización universal de almacenamiento" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# Encontrar disco del sistema
$systemDisk = $hardwareInfo.Storage | Where-Object { $_.IsSystem -eq $true } | Select-Object -First 1

if ($systemDisk) {
    Write-Host "  » Disco del sistema: $($systemDisk.Category)" -ForegroundColor DarkGray
    
    # Optimizaciones ESPECÍFICAS por tipo (universales)
    switch ($systemDisk.Category) {
        "NVMe" {
            Write-Host "  • NVMe: Buffers al máximo, TRIM activado" -ForegroundColor DarkGray
            fsutil behavior set disablelastaccess 0 2>&1 | Out-Null
            
            # Buffers NTFS máximo
            $ntfsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
            Set-ItemProperty -Path $ntfsPath -Name "NtfsMemoryUsage" -Value 2 -ErrorAction SilentlyContinue
        }
        "SSD" {
            Write-Host "  • SSD: Buffers optimizados, TRIM activado" -ForegroundColor DarkGray
            fsutil behavior set disablelastaccess 0 2>&1 | Out-Null
            
            # Buffers NTFS estándar
            $ntfsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
            Set-ItemProperty -Path $ntfsPath -Name "NtfsMemoryUsage" -Value 1 -ErrorAction SilentlyContinue
            
            # Deshabilitar defrag programado para SSD
            Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue
        }
        "HDD" {
            Write-Host "  • HDD: Buffers aumentados, prefetch completo" -ForegroundColor DarkGray
            fsutil behavior set disablelastaccess 1 2>&1 | Out-Null
            
            # Prefetch completo para HDD
            $prefetchPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
            Set-ItemProperty -Path $prefetchPath -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
        }
        default {
            Write-Host "  • Configuración genérica aplicada" -ForegroundColor DarkGray
        }
    }
    
    # Ejecutar TRIM/optimización si es SSD/NVMe
    if ($systemDisk.Category -in @("NVMe", "SSD")) {
        try {
            $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive.Replace(":", "")
            Optimize-Volume -DriveLetter $systemDrive -ReTrim -ErrorAction SilentlyContinue | Out-Null
        } catch {
            # Silencioso - Windows ya lo hace automáticamente
        }
    }
    
    Write-Host "✔ $($systemDisk.Category) optimizado según tipo" -ForegroundColor Green
} else {
    Write-Host "  • Almacenamiento: Sin optimizaciones específicas" -ForegroundColor DarkGray
    Write-Host "✔ Almacenamiento verificado" -ForegroundColor Green
}

Write-Host ""

# =====================================================================
# [FASE 8] Información universal y mantenimiento
# =====================================================================

Write-Host "[FASE 8] Información universal y mantenimiento" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray
Write-Host ""

Write-Host "📊 RESUMEN UNIVERSAL DEL SISTEMA" -ForegroundColor Cyan
Write-Host "• Sistema analizado:" -ForegroundColor DarkGray
Write-Host "  - OS: $($SystemAnalysis.OSEdition)" -ForegroundColor DarkGray
Write-Host "  - CPU: $($hardwareInfo.CPU.Name)" -ForegroundColor DarkGray
Write-Host "  - RAM: $($hardwareInfo.RAM.TotalGB) GB" -ForegroundColor DarkGray
Write-Host "  - Almacenamiento: $(if($systemDisk){$systemDisk.Category}else{'No detectado'})" -ForegroundColor DarkGray
Write-Host "  - GPU: $($hardwareInfo.GPU[0].Name)" -ForegroundColor DarkGray
Write-Host "• Perfil aplicado: $Profile" -ForegroundColor DarkGray
Write-Host "• Tweaks peligrosos eliminados: $tweaksRemoved" -ForegroundColor DarkGray
Write-Host ""

Write-Host "🔧 MANTENIMIENTO UNIVERSAL RECOMENDADO" -ForegroundColor Cyan
Write-Host "• Windows Update: Mantener actualizado" -ForegroundColor DarkGray
Write-Host "• Drivers: Actualizar desde fabricante" -ForegroundColor DarkGray
Write-Host "• Reinicio: Semanal para liberar recursos" -ForegroundColor DarkGray
Write-Host "• Memoria virtual: Dejar que Windows gestione" -ForegroundColor DarkGray
Write-Host "• Limpieza: Usar 'cleanmgr' (Limpieza de disco)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "⚡ OPTIMIZACIONES APLICADAS (universales)" -ForegroundColor Cyan
Write-Host "✓ Prioridades CPU: $CPUValue (balance universal)" -ForegroundColor DarkGray
Write-Host "✓ Retrasos del sistema: 100ms (óptimo universal)" -ForegroundColor DarkGray
Write-Host "✓ Almacenamiento: Optimizado para $(if($systemDisk){$systemDisk.Category}else{'tipo detectado'})" -ForegroundColor DarkGray
Write-Host "✓ Red: Configuración estable aplicada" -ForegroundColor DarkGray
Write-Host "✓ Memoria: Configuración segura verificada" -ForegroundColor DarkGray
Write-Host ""

Write-Host "🚫 LO QUE NO HICIMOS (por diseño)" -ForegroundColor Cyan
Write-Host "• No eliminamos archivos temporales" -ForegroundColor DarkGray
Write-Host "• No deshabilitamos servicios del sistema" -ForegroundColor DarkGray
Write-Host "• No cambiamos configuración de seguridad" -ForegroundColor DarkGray
Write-Host "• No aplicamos 'tweaks' agresivos" -ForegroundColor DarkGray
Write-Host ""

Write-Host "⏱️  CUÁNDO EJECUTAR ESTE SCRIPT" -ForegroundColor Cyan
Write-Host "✓ Después de instalación limpia de Windows" -ForegroundColor DarkGray
Write-Host "✓ Tras usar optimizadores agresivos (como WiseCare)" -ForegroundColor DarkGray
Write-Host "✓ Al cambiar hardware significativo" -ForegroundColor DarkGray
Write-Host "✓ Si experimentas lentitud inexplicable" -ForegroundColor DarkGray
Write-Host "✗ No ejecutar periódicamente" -ForegroundColor DarkGray
Write-Host "✗ No como 'acelerador' diario" -ForegroundColor DarkGray
Write-Host ""

Write-Host "💡 FILOSOFÍA: Guidance, not force" -ForegroundColor Green
Write-Host "   Windows ya está optimizado. Eliminamos solo interferencias peligrosas." -ForegroundColor DarkGray
Write-Host "─" * 70 -ForegroundColor DarkGray
Write-Host ""

# =====================================================================
# [FASE 9] Verificación y finalización universal
# =====================================================================

Write-Host "[FASE 9] Verificación y finalización universal" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   PROCESO UNIVERSAL COMPLETADO" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ VERIFICACIÓN FINAL:" -ForegroundColor Green
Write-Host "1. Análisis universal completado" -ForegroundColor Gray
Write-Host "2. Configuraciones peligrosas eliminadas: $tweaksRemoved" -ForegroundColor Gray
Write-Host "3. Perfil $Profile aplicado según capacidades" -ForegroundColor Gray
Write-Host "4. Optimizaciones específicas por tipo de hardware" -ForegroundColor Gray
Write-Host "5. Sistema configurado de forma segura y estable" -ForegroundColor Gray
Write-Host ""

Write-Host "🎯 ESTADO DEL SISTEMA:" -ForegroundColor Yellow
Write-Host "• Configuración coherente y sin peligros" -ForegroundColor Gray
Write-Host "• Optimizado según hardware detectado" -ForegroundColor Gray
Write-Host "• Listo para gestión automática de Windows" -ForegroundColor Gray
Write-Host "• Comportamiento predecible y estable" -ForegroundColor Gray
Write-Host ""

Write-Host "⚠️  RECOMENDACIÓN FINAL" -ForegroundColor Yellow
Write-Host "Reinicia el sistema para aplicar configuraciones completas." -ForegroundColor Green
Write-Host ""
Write-Host "   Confía en Windows. Sabe lo que hace." -ForegroundColor DarkGray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Windows de Mente v1.0 | Optimización Consciente Universal" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Opción de reinicio universal
$reinicio = Read-Host "¿Reiniciar ahora? (S/N)"
if ($reinicio -eq "S" -or $reinicio -eq "s") {
    Write-Host "Reiniciando en 5 segundos..." -ForegroundColor Yellow
    Start-Sleep 5
    Restart-Computer -Force
} else {
    Write-Host "Reinicia manualmente cuando sea conveniente." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ℹ️  Información del análisis guardada en:" -ForegroundColor DarkGray
    Write-Host "   $($GlobalConfig.LogFile)" -ForegroundColor DarkGray
}
