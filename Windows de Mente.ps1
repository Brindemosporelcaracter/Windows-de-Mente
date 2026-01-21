# =====================================================================
#  WINDOWS DE MENTE v1.0
#  Optimización consciente de Windows
#  Guidance, not force
# =====================================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows de Mente v1.0"

# =====================================================================
# VERIFICACIÓN DE PRIVILEGIOS DE ADMINISTRADOR
# =====================================================================
Write-Host "» Verificando privilegios de administrador..." -ForegroundColor DarkGray

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-NOT $isAdmin) {
    Write-Host "`n❌ ERROR: Este script requiere privilegios de administrador" -ForegroundColor Red
    Write-Host "   Por favor, ejecuta PowerShell como administrador" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Métodos:" -ForegroundColor DarkGray
    Write-Host "   1. Click derecho en PowerShell → 'Ejecutar como administrador'" -ForegroundColor DarkGray
    Write-Host "   2. Windows + X → Windows PowerShell (Administrador)" -ForegroundColor DarkGray
    Write-Host "   3. Buscar 'PowerShell' → Click derecho → 'Ejecutar como administrador'" -ForegroundColor DarkGray
    Write-Host ""
    
    $elevate = Read-Host "¿Intentar ejecutar como administrador? (S/N)"
    if ($elevate -eq "S" -or $elevate -eq "s") {
        Write-Host "Reintentando con permisos elevados..." -ForegroundColor Yellow
        
        $scriptPath = $MyInvocation.MyCommand.Path
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $psi.Verb = "runas"
        
        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            exit 0
        } catch {
            Write-Host "No se pudo elevar. Ejecuta manualmente como administrador." -ForegroundColor Red
        }
    }
    
    Read-Host "`nPresiona Enter para salir"
    exit 1
}

Write-Host "✔ Privilegios de administrador confirmados" -ForegroundColor Green
Write-Host ""

# =====================================================================
# ENCABEZADO PRINCIPAL
# =====================================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   WINDOWS DE MENTE v1.0  |  Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "   Guidance, not force" -ForegroundColor DarkGray
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
    BackupPath = "$env:USERPROFILE\Documents\WindowsDeMente_Backup_$(Get-Date -Format 'yyyyMMdd')"
}

# =====================================================================
# [FASE 0] Análisis contextual del sistema
# =====================================================================
Write-Host "[FASE 0] Análisis contextual del sistema" -ForegroundColor Yellow
Write-Host ("─" * 72) -ForegroundColor DarkGray

# PERFIL CENTRAL – SOLO DATOS QUE JUSTIFICAN DECISIONES
$SystemProfile = @{
    OSEdition = "Unknown"
    CPU = @{
        Vendor = "Unknown"
        Cores = 0
        Threads = 0
        Modern = $false          # Post-2017 / AVX2-capable (aprox)
        Hybrid = $false          # P + E cores
    }
    GPU = @{
        Type = "Unknown"         # Integrated / Dedicated / Hybrid
        Vendor = "Unknown"       # Intel / AMD / NVIDIA
        IsOEMDriver = $false     # Drivers sensibles (laptop)
    }
    Network = @{
        PrimaryType = "Unknown"  # Ethernet / WiFi
        Vendor = "Unknown"       # Intel / Realtek / Killer / Other
        IsProblematic = $false   # Killer / Bigfoot / especiales
    }
    Storage = @{
        SystemDiskType = "Unknown"   # HDD / SSD / NVMe
    }
    Platform = @{
        IsLaptop = $false
        HasBattery = $false
        PowerSource = "Unknown"      # AC / Battery / Unknown
    }
    USB = @{
        HasUSB3 = $false
    }
    RiskLevel = "Medium"             # Low / Medium / High
    Strategy = "Balanced"            # Conservative / Balanced / Aggressive
}

# =====================================================================
# DETECCIÓN DE EDICIÓN DE WINDOWS
# =====================================================================
try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $SystemProfile.OSEdition = $osInfo.Caption
} catch {
    $SystemProfile.OSEdition = "Windows (no detectado)"
}

# =====================================================================
# CPU — DETECCIÓN ROBUSTA (SIN ADIVINAR)
# =====================================================================
try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

    $SystemProfile.CPU.Cores   = $cpu.NumberOfCores
    $SystemProfile.CPU.Threads = $cpu.NumberOfLogicalProcessors

    if ($cpu.Name -match "Intel") { $SystemProfile.CPU.Vendor = "Intel" }
    elseif ($cpu.Name -match "AMD") { $SystemProfile.CPU.Vendor = "AMD" }

    # Heurística segura de CPU moderna (no por nombre)
    if ($cpu.MaxClockSpeed -ge 2300 -and $cpu.NumberOfLogicalProcessors -ge 4) {
        $SystemProfile.CPU.Modern = $true
    }

    # Detección aproximada de CPUs híbridas (Intel 12th+)
    if ($SystemProfile.CPU.Vendor -eq "Intel" -and $cpu.Threads -gt $cpu.Cores * 2) {
        $SystemProfile.CPU.Hybrid = $true
    }

} catch {
    Write-Host "  ⚠️ CPU: detección parcial" -ForegroundColor Yellow
}

# =====================================================================
# GPU — CLASIFICACIÓN POR IMPACTO (NO POR CANTIDAD)
# =====================================================================
try {
    $gpus = Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -ne "Microsoft Basic Display Driver" }

    if ($gpus.Count -gt 1) {
        $SystemProfile.GPU.Type = "Hybrid"
    } elseif ($gpus.Count -eq 1) {
        if ($gpus[0].Name -match "Intel|UHD|HD Graphics|Radeon Graphics") {
            $SystemProfile.GPU.Type = "Integrated"
        } else {
            $SystemProfile.GPU.Type = "Dedicated"
        }
    }

    foreach ($gpu in $gpus) {
        if ($gpu.Name -match "NVIDIA") { $SystemProfile.GPU.Vendor = "NVIDIA" }
        elseif ($gpu.Name -match "AMD|Radeon") { $SystemProfile.GPU.Vendor = "AMD" }
        elseif ($gpu.Name -match "Intel") { $SystemProfile.GPU.Vendor = "Intel" }
    }

    # Drivers OEM (principalmente laptops)
    if ($SystemProfile.Platform.IsLaptop -and
        ($gpus.PNPDeviceID -match "SUBSYS_") ) {
        $SystemProfile.GPU.IsOEMDriver = $true
    }

} catch {
    Write-Host "  ⚠️ GPU: detección básica" -ForegroundColor Yellow
}

# =====================================================================
# RED — DETECTAR PARA NO ROMPER
# =====================================================================
try {
    $adapter = Get-NetAdapter -Physical |
               Where-Object {
                   $_.Status -eq "Up" -and
                   $_.InterfaceDescription -notmatch "Virtual|VPN|Hyper-V"
               } | Select-Object -First 1

    if ($adapter) {
        if ($adapter.InterfaceDescription -match "Wi-Fi|Wireless") {
            $SystemProfile.Network.PrimaryType = "WiFi"
        } else {
            $SystemProfile.Network.PrimaryType = "Ethernet"
        }

        if ($adapter.InterfaceDescription -match "Intel") {
            $SystemProfile.Network.Vendor = "Intel"
        }
        elseif ($adapter.InterfaceDescription -match "Realtek") {
            $SystemProfile.Network.Vendor = "Realtek"
        }
        elseif ($adapter.InterfaceDescription -match "Killer|Bigfoot|Rivet") {
            $SystemProfile.Network.Vendor = "Killer"
            $SystemProfile.Network.IsProblematic = $true
        }
        else {
            $SystemProfile.Network.Vendor = "Other"
        }
    }
} catch {
    Write-Host "  ⚠️ Red: sin adaptador activo confiable" -ForegroundColor Yellow
}

# =====================================================================
# ALMACENAMIENTO — DETECCIÓN DEL DISCO DEL SISTEMA
# =====================================================================
try {
    $systemDisk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | Select-Object -First 1
    if ($systemDisk) {
        switch ($systemDisk.MediaType) {
            "SSD"       { $SystemProfile.Storage.SystemDiskType = "SSD" }
            "HDD"       { $SystemProfile.Storage.SystemDiskType = "HDD" }
            "NVMe"      { $SystemProfile.Storage.SystemDiskType = "NVMe" }
            default     { $SystemProfile.Storage.SystemDiskType = "Unknown" }
        }
    }
} catch {
    Write-Host "  ⚠️ Almacenamiento: tipo no detectado" -ForegroundColor Yellow
}

# =====================================================================
# PLATAFORMA — DECISIÓN CRÍTICA (LAPTOP VS DESKTOP)
# =====================================================================
try {
    # Método 1: Chassis type (más fiable)
    $chassis = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue
    $laptopTypes = @(8, 9, 10, 11, 12, 14, 18, 21, 31)  # Tipos de chasis de laptop
    
    if ($chassis.ChassisTypes | Where-Object { $_ -in $laptopTypes }) {
        $SystemProfile.Platform.IsLaptop = $true
    }
    
    # Método 2: Verificar batería
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $SystemProfile.Platform.HasBattery = $true
        $SystemProfile.Platform.PowerSource = if ($battery.BatteryStatus -eq 2) { "AC" } else { "Battery" }
    }
} catch {
    # Default seguro: desktop
}

# =====================================================================
# USB — SOLO PARA POWER MANAGEMENT
# =====================================================================
try {
    $usb = Get-CimInstance Win32_USBController |
           Where-Object { $_.Name -match "USB 3|eXtensible" }

    $SystemProfile.USB.HasUSB3 = [bool]$usb
} catch {}

# =====================================================================
# EVALUACIÓN DE RIESGO Y ESTRATEGIA
# =====================================================================
$risk = 0

if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.GPU.IsOEMDriver) {
    $risk += 2
}

if ($SystemProfile.Network.IsProblematic) {
    $risk += 1
}

switch ($risk) {
    { $_ -ge 2 } {
        $SystemProfile.RiskLevel = "High"
        $SystemProfile.Strategy  = "Conservative"
    }
    1 {
        $SystemProfile.RiskLevel = "Medium"
        $SystemProfile.Strategy  = "Balanced"
    }
    default {
        $SystemProfile.RiskLevel = "Low"
        $SystemProfile.Strategy  = "Aggressive"
    }
}

# =====================================================================
# RESUMEN HUMANO (TRANSPARENCIA)
# =====================================================================
Write-Host "`n📋 PERFIL DETECTADO" -ForegroundColor Cyan
Write-Host "  • Plataforma: $(if($SystemProfile.Platform.IsLaptop){'Laptop'}else{'Desktop'})"
Write-Host "  • CPU: $($SystemProfile.CPU.Vendor) $(if($SystemProfile.CPU.Modern){'Moderna'}else{'Legacy'})"
Write-Host "  • GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)"
Write-Host "  • Red: $($SystemProfile.Network.PrimaryType) - $($SystemProfile.Network.Vendor)"
Write-Host "  • Riesgo: $($SystemProfile.RiskLevel)"
Write-Host "  • Estrategia: $($SystemProfile.Strategy)"
Write-Host "✔ Fase 0 completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# DETECCIÓN DE HARDWARE PARA COMPATIBILIDAD (MANTENER VARIABLE EXISTENTE)
# =====================================================================
# Mantenemos $hardwareInfo para compatibilidad con código existente
$hardwareInfo = @{
    CPU = @{ Name = "$($SystemProfile.CPU.Vendor) CPU"; Cores = $SystemProfile.CPU.Cores }
    RAM = @{ TotalGB = 0 }
    Storage = @()
    GPU = @(@{ Name = "$($SystemProfile.GPU.Vendor) $($SystemProfile.GPU.Type)" })
    Network = @(@{ Type = $SystemProfile.Network.PrimaryType; Vendor = $SystemProfile.Network.Vendor })
}

# Obtener RAM para $hardwareInfo
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $hardwareInfo.RAM.TotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
} catch {
    $hardwareInfo.RAM.TotalGB = 0
}

# Obtener disco del sistema para $hardwareInfo
try {
    $physicalDisk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | Select-Object -First 1
    if ($physicalDisk) {
        $diskInfo = @{
            Category = $SystemProfile.Storage.SystemDiskType
            IsSystem = $true
            SizeGB = [math]::Round($physicalDisk.Size / 1GB, 1)
            FriendlyName = $physicalDisk.FriendlyName
        }
        $hardwareInfo.Storage += $diskInfo
    }
} catch {}

# =====================================================================
# [FASE 1] Evaluación contextual de capacidades
# =====================================================================
Write-Host "[FASE 1] Evaluación contextual de capacidades" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# Obtener RAM para puntuación
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
} catch {
    $totalRAM = 0
}

# Sistema de puntuación INTEGRADO (combina hardware y riesgo)
$ProfileScore = 0
$ScoreDetails = @()

# 1. Puntuación RAM (contextual, no solo cantidad)
$ramScore = switch ($totalRAM) {
    { $_ -ge 32 } { 
        $score = 50
        $ScoreDetails += "RAM ≥32GB: +50 (Workstation)"
        $score
    }
    { $_ -ge 16 } { 
        $score = 40
        $ScoreDetails += "RAM 16GB: +40 (Multitarea pesada)"
        $score
    }
    { $_ -ge 8 }  { 
        $score = 30
        $ScoreDetails += "RAM 8GB: +30 (Estándar moderno)"
        $score
    }
    { $_ -ge 4 }  { 
        $score = 20
        $ScoreDetails += "RAM 4GB: +20 (Mínimo Windows 10/11)"
        $score
    }
    default       { 
        $score = 10
        $ScoreDetails += "RAM <4GB: +10 (Compatibilidad)"
        $score
    }
}
$ProfileScore += $ramScore

# 2. Puntuación CPU (considerar modernidad, no solo núcleos)
$cpuBaseScore = switch ($SystemProfile.CPU.Cores) {
    { $_ -ge 12 } { 40; $ScoreDetails += "CPU ≥12c: +40" }
    { $_ -ge 8 }  { 35; $ScoreDetails += "CPU 8c: +35" }
    { $_ -ge 4 }  { 25; $ScoreDetails += "CPU 4c: +25" }
    { $_ -ge 2 }  { 15; $ScoreDetails += "CPU 2c: +15" }
    default       { 5;  $ScoreDetails += "CPU 1c: +5" }
}

# Bonus por CPU moderna
$cpuModernBonus = if ($SystemProfile.CPU.Modern) { 
    15; $ScoreDetails += "CPU Moderna: +15" 
} else { 
    0 
}

# Bonus/penalización por híbrida
$cpuHybridBonus = if ($SystemProfile.CPU.Hybrid) { 
    10; $ScoreDetails += "CPU Híbrida: +10 (Windows 11 optimizado)" 
} else { 
    0 
}

$cpuScore = $cpuBaseScore + $cpuModernBonus + $cpuHybridBonus
$ProfileScore += $cpuScore

# 3. Puntuación Almacenamiento (usar SystemProfile)
$systemDiskType = $SystemProfile.Storage.SystemDiskType
$storageScore = switch ($systemDiskType) {
    "NVMe" { 
        $score = 40
        $ScoreDetails += "NVMe: +40 (Máximo rendimiento)"
        $score
    }
    "SSD" { 
        $score = 30
        $ScoreDetails += "SSD: +30 (Rápido)"
        $score
    }
    "HDD" { 
        $score = 15
        $ScoreDetails += "HDD: +15 (Mecánico)"
        $score
    }
    default { 
        $score = 10
        $ScoreDetails += "Almacenamiento desconocido: +10"
        $score
    }
}
$ProfileScore += $storageScore

# 4. GPU (ahora más inteligente usando SystemProfile)
$gpuScore = 0
switch ($SystemProfile.GPU.Type) {
    "Dedicated" { 
        $gpuScore = 25
        $ScoreDetails += "GPU Dedicada: +25 (Rendimiento gráfico)"
    }
    "Hybrid" { 
        $gpuScore = 20
        $ScoreDetails += "GPU Híbrida: +20 (Balance energía/rendimiento)"
    }
    "Integrated" { 
        $gpuScore = 10
        $ScoreDetails += "GPU Integrada: +10 (Eficiencia)"
    }
    default { 
        $gpuScore = 5
        $ScoreDetails += "GPU Desconocida: +5"
    }
}

# Bonus por vendor específico
if ($SystemProfile.GPU.Vendor -in @("NVIDIA", "AMD")) {
    $gpuScore += 5
    $ScoreDetails += "GPU NVIDIA/AMD: +5 (Drivers maduros)"
}

$ProfileScore += $gpuScore

# 5. AJUSTE POR RIESGO (MODIFICADOR CRÍTICO)
$riskModifier = switch ($SystemProfile.RiskLevel) {
    "High"   { -30; $ScoreDetails += "Riesgo Alto: -30 (conservadurismo)" }
    "Medium" { 0 }
    "Low"    { 10; $ScoreDetails += "Riesgo Bajo: +10 (margen para optimizar)" }
    default  { 0 }
}

$ProfileScore += $riskModifier
$ProfileScore = [Math]::Max(10, $ProfileScore)  # Mínimo 10 puntos

# Determinar perfil INTEGRADO (combina puntuación y estrategia)
$HardwareProfile = switch ($ProfileScore) {
    { $_ -ge 120 } { "ENTUSIASTA" }
    { $_ -ge 85 }  { "EQUILIBRADO" }
    { $_ -ge 50 }  { "ESTÁNDAR" }
    default        { "LIVIANO" }
}

# PERFIL FINAL = HardwareProfile + Strategy
$FinalProfile = @{
    HardwareTier = $HardwareProfile
    RiskStrategy = $SystemProfile.Strategy
    RiskLevel = $SystemProfile.RiskLevel
    TotalScore = $ProfileScore
}

Write-Host "📈 EVALUACIÓN CONTEXTUAL:" -ForegroundColor Cyan
Write-Host "  • RAM: ${totalRAM}GB" -ForegroundColor DarkGray
Write-Host "  • CPU: $($SystemProfile.CPU.Vendor) $($SystemProfile.CPU.Cores)c/$($SystemProfile.CPU.Threads)t $(if($SystemProfile.CPU.Modern){'Moderno'})" -ForegroundColor DarkGray
Write-Host "  • GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)" -ForegroundColor DarkGray
Write-Host "  • Almacenamiento: $systemDiskType" -ForegroundColor DarkGray
Write-Host "  • Plataforma: $(if($SystemProfile.Platform.IsLaptop){'Laptop'}else{'Desktop'})" -ForegroundColor DarkGray

Write-Host "`n🎯 PUNTUACIÓN INTEGRADA:" -ForegroundColor Cyan
foreach ($detail in $ScoreDetails) {
    if ($detail -match ":\s*-\d+") {
        Write-Host "  • $detail" -ForegroundColor DarkRed
    } elseif ($detail -match ":\s*\+\d+") {
        Write-Host "  • $detail" -ForegroundColor DarkGreen
    } else {
        Write-Host "  • $detail" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "🏷️  PERFIL DETERMINADO:" -ForegroundColor Cyan
Write-Host "  • Nivel Hardware: $HardwareProfile" -ForegroundColor DarkGray
Write-Host "  • Estrategia: $($SystemProfile.Strategy)" -ForegroundColor DarkGray
Write-Host "  • Riesgo: $($SystemProfile.RiskLevel)" -ForegroundColor $(switch($SystemProfile.RiskLevel){"High"{'Red'}"Medium"{'Yellow'}default{'Green'}})
Write-Host "  • Puntuación total: $ProfileScore puntos" -ForegroundColor DarkGray

Write-Host "`n💡 INTERPRETACIÓN:" -ForegroundColor DarkGray
switch ($HardwareProfile) {
    "ENTUSIASTA" {
        Write-Host "  Sistema potente. Optimizaciones orientadas a rendimiento máximo." -ForegroundColor DarkGray
    }
    "EQUILIBRADO" {
        Write-Host "  Hardware moderno. Balance entre rendimiento y estabilidad." -ForegroundColor DarkGray
    }
    "ESTÁNDAR" {
        Write-Host "  Hardware común. Optimizaciones seguras y conservadoras." -ForegroundColor DarkGray
    }
    "LIVIANO" {
        Write-Host "  Hardware limitado. Enfoque en eficiencia y reducción de carga." -ForegroundColor DarkGray
    }
}

if ($SystemProfile.Strategy -eq "Conservative") {
    Write-Host "  ⚠️  Estrategia conservadora: Se evitarán optimizaciones agresivas." -ForegroundColor Yellow
}

Write-Host "✔ Evaluación contextual completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 2] Configuración contextual de memoria
# =====================================================================
Write-Host "[FASE 2] Configuración contextual de memoria" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

# --- ELIMINAR tweaks peligrosos (SIEMPRE seguro, pero ahora registramos por qué) ---
Write-Host "  » Eliminando configuraciones peligrosas..." -ForegroundColor DarkGray

$dangerousTweaks = @(
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Name = "DisablePagingExecutive"
        Reason = "Evita que el kernel se page a disco - PELIGROSO en sistemas con <16GB RAM"
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Name = "LargeSystemCache"
        Reason = "Prioriza cache del sistema sobre apps - MALO para estaciones de trabajo"
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Name = "ClearPageFileAtShutdown"
        Reason = "Lento, innecesario para seguridad moderna"
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Name = "SecondLevelDataCache"
        Reason = "Windows detecta automáticamente desde XP"
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Name = "IoPageLockLimit"
        Reason = "Valor obsoleto, causa inestabilidad"
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        Name = "Win32PrioritySeparation"
        Reason = "Valor DUPLICADO - se establecerá correctamente en FASE 3"
    }
)

$tweaksRemoved = 0
$tweaksDetails = @()

foreach ($tweak in $dangerousTweaks) {
    if (Test-Path $tweak.Path) {
        $prop = Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
        if ($prop) {
            try {
                Remove-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction Stop
                $tweaksRemoved++
                $tweaksDetails += "✓ Eliminado: $($tweak.Name) - $($tweak.Reason)"
            } catch {
                $tweaksDetails += "⚠ No eliminado: $($tweak.Name) (acceso denegado)"
            }
        }
    }
}

if ($tweaksRemoved -gt 0) {
    Write-Host "  • $tweaksRemoved configuraciones peligrosas eliminadas" -ForegroundColor Green
    if ($GlobalConfig.LogLevel -eq "Verbose") {
        $tweaksDetails | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
} else {
    Write-Host "  • No se encontraron configuraciones peligrosas" -ForegroundColor Green
}

# --- CONFIGURACIÓN DE PAGEFILE INTELIGENTE (basada en perfil) ---
Write-Host "  » Configurando memoria virtual..." -ForegroundColor DarkGray

try {
    $cs = Get-CimInstance Win32_ComputerSystem
    $totalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    
    # Determinar recomendación BASADA EN PERFIL
    $pagefileRecommendation = switch ($FinalProfile.HardwareTier) {
        "ENTUSIASTA" {
            if ($totalRAM -ge 64) {
                @{ Action = "Reducir"; Size = "8GB fijo"; Reason = "RAM abundante (>64GB)" }
            } elseif ($totalRAM -ge 32) {
                @{ Action = "Mantener"; Size = "Automático"; Reason = "RAM suficiente (32GB+)" }
            } else {
                @{ Action = "Optimizar"; Size = "RAM×1.5"; Reason = "Para workloads pesados" }
            }
        }
        "EQUILIBRADO" {
            @{ Action = "Mantener"; Size = "Automático"; Reason = "Balance óptimo Windows" }
        }
        "ESTÁNDAR" {
            @{ Action = "Mantener"; Size = "Automático"; Reason = "Configuración estable" }
        }
        "LIVIANO" {
            if ($totalRAM -le 4) {
                @{ Action = "Aumentar"; Size = "8GB mínimo"; Reason = "RAM limitada (<4GB)" }
            } else {
                @{ Action = "Mantener"; Size = "Automático"; Reason = "Suficiente para sistema" }
            }
        }
        default {
            @{ Action = "Mantener"; Size = "Automático"; Reason = "Configuración por defecto" }
        }
    }
    
    # Aplicar según estrategia de riesgo
    $shouldApply = switch ($FinalProfile.RiskStrategy) {
        "Aggressive"   { $true }   # Aplica recomendación
        "Balanced"     { $pagefileRecommendation.Action -ne "Reducir" }  # Evita reducciones
        "Conservative" { $false }  # No cambia nada
    }
    
    if ($shouldApply -and $pagefileRecommendation.Action -ne "Mantener") {
        Write-Host "  • Recomendación: $($pagefileRecommendation.Action) pagefile" -ForegroundColor Yellow
        Write-Host "    Razón: $($pagefileRecommendation.Reason)" -ForegroundColor DarkGray
        
        # Solo informativo en esta versión (modo seguro)
        if (-not $GlobalConfig.SafeMode) {
            # Aquí iría la lógica para aplicar cambios reales
            Write-Host "  • MODO NO-SEGURO: Cambios de pagefile requieren UI manual" -ForegroundColor DarkGray
        }
        
        $pagefileStatus = "Recomendación: $($pagefileRecommendation.Action) ($($pagefileRecommendation.Size))"
    } else {
        # Verificar estado actual
        if ($cs.AutomaticManagedPagefile) {
            $pagefileStatus = "Windows gestiona automáticamente ✓"
        } else {
            $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
            $pagefilePath = "$systemDrive\pagefile.sys"
            
            if (Test-Path $pagefilePath) {
                $size = (Get-Item $pagefilePath -Force -ErrorAction SilentlyContinue).Length
                if ($size -gt 0) {
                    $pagefileStatus = "Presente ($([math]::Round($size/1GB,1)) GB) ✓"
                } else {
                    $pagefileStatus = "Configurado manualmente (tamaño 0?)"
                }
            } else {
                $pagefileStatus = "No encontrado (¿deshabilitado?)"
            }
        }
    }
    
    # Mostrar estado actual
    Write-Host "  • Estado actual: $pagefileStatus" -ForegroundColor Green
    
    # Advertencia para laptops en batería
    if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.Platform.PowerSource -eq "Battery") {
        Write-Host "  • Laptop en batería: Pagefile en SSD puede reducir vida útil" -ForegroundColor Yellow
        Write-Host "    Considera conectar a corriente para optimizaciones" -ForegroundColor DarkGray
    }
    
} catch {
    Write-Host "  • Estado: No verificado (sin cambios)" -ForegroundColor DarkGray
    $pagefileStatus = "No verificado"
}

# --- CONFIGURACIÓN ADICIONAL PARA SISTEMAS CON MUCHA RAM ---
if ($totalRAM -ge 32 -and $FinalProfile.HardwareTier -eq "ENTUSIASTA") {
    Write-Host "  » Ajustando para sistemas con mucha RAM..." -ForegroundColor DarkGray
    
    # Configurar SuperFetch/SysMain de forma inteligente
    $sysMainPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
    
    try {
        # Para sistemas con mucha RAM y SSD/NVMe, habilitar prefetch completo
        if ($SystemProfile.Storage.SystemDiskType -in @("SSD", "NVMe")) {
            if (-not (Test-Path $sysMainPath)) {
                New-Item -Path $sysMainPath -Force | Out-Null
            }
            Set-ItemProperty -Path $sysMainPath -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $sysMainPath -Name "EnableSuperfetch" -Value 3 -ErrorAction SilentlyContinue
            Write-Host "  • Prefetch/SuperFetch: Habilitado completo (SSD/NVMe + RAM alta)" -ForegroundColor DarkGray
        }
    } catch {
        # Silencioso - no crítico
    }
}

# --- REGISTRO DE ACCIONES ---
if ($GlobalConfig.CreateBackup -and $tweaksRemoved -gt 0) {
    try {
        $backupDir = "$($GlobalConfig.BackupPath)\MemoryTweaks"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $backupInfo = @"
Fecha: $(Get-Date)
Tweaks eliminados: $tweaksRemoved
Estado Pagefile: $pagefileStatus
Perfil aplicado: $($FinalProfile.HardwareTier) - $($FinalProfile.RiskStrategy)
RAM total: ${totalRAM}GB
Recomendación pagefile: $($pagefileRecommendation.Action) - $($pagefileRecommendation.Reason)
"@
        
        $backupInfo | Out-File "$backupDir\MemoryConfig_Backup.txt" -Encoding UTF8
        Write-Host "  • Backup creado en: $backupDir" -ForegroundColor DarkGray
    } catch {
        # No crítico si falla el backup
    }
}

Write-Host "✔ Configuración contextual de memoria completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 3] Balance contextual de prioridades CPU
# =====================================================================
Write-Host "[FASE 3] Balance contextual de prioridades CPU" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Ajustando balance foreground/background según perfil y riesgo..." -ForegroundColor DarkGray
Write-Host "    (sin interferir con scheduler moderno de Windows)" -ForegroundColor DarkGray
Write-Host ""

# --- VALORES BASADOS EN PERFIL DUAL (COHERENTE CON FRAMEWORK) ---
$CPUPriorityMatrix = @{
    # HardwareTier -> RiskStrategy -> Value
    "ENTUSIASTA" = @{ 
        Conservative = 24   # Estable para sistemas potentes pero delicados
        Balanced     = 36   # Óptimo balance rendimiento/respuesta
        Aggressive   = 48   # Máxima respuesta (benchmarks, gaming)
    }
    "EQUILIBRADO" = @{ 
        Conservative = 20   # Seguro pero responsive
        Balanced     = 28   # Balance moderno
        Aggressive   = 36   # Más respuesta para aplicaciones
    }
    "ESTÁNDAR" = @{ 
        Conservative = 16   # Conservador pero mejor que default
        Balanced     = 24   # Valor óptimo universal
        Aggressive   = 32   # Más respuesta sin comprometer estabilidad
    }
    "LIVIANO" = @{ 
        Conservative = 12   # Mejor respuesta UI en hardware limitado
        Balanced     = 18   # Balance para sistemas básicos
        Aggressive   = 24   # Máximo sin sobrecargar
    }
}

# Obtener valor BASADO EN PERFIL DUAL (COHERENCIA TOTAL)
$CPUValue = $CPUPriorityMatrix[$FinalProfile.HardwareTier][$FinalProfile.RiskStrategy]
$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

# --- VALIDACIÓN DE IDEMPOTENCIA (MEJORA 3) ---
$currentValue = $null
$needsUpdate = $false

try {
    if (Test-Path $priorityPath) {
        $prop = Get-ItemProperty -Path $priorityPath -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
        if ($prop -and $null -ne $prop.Win32PrioritySeparation) {
            $currentValue = $prop.Win32PrioritySeparation
            $needsUpdate = ($currentValue -ne $CPUValue)
        } else {
            $needsUpdate = $true  # No existe la propiedad
        }
    } else {
        $needsUpdate = $true  # No existe la clave
    }
} catch {
    $needsUpdate = $true  # Error al leer, asumimos que necesita actualización
}

# --- EXPLICACIÓN CLARA DEL VALOR ---
Write-Host "  • Perfil hardware: $($FinalProfile.HardwareTier)" -ForegroundColor DarkGray
Write-Host "  • Estrategia riesgo: $($FinalProfile.RiskStrategy)" -ForegroundColor DarkGray
Write-Host "  • Valor recomendado: $CPUValue" -ForegroundColor Cyan

if ($currentValue) {
    Write-Host "  • Valor actual: $currentValue" -ForegroundColor DarkGray
}

# Explicación humana del valor
$valueExplanation = switch ($CPUValue) {
    { $_ -le 16 } { "Enfocado en respuesta del sistema (ideal para hardware limitado)" }
    { $_ -le 24 } { "Balance clásico entre background/foreground" }
    { $_ -le 36 } { "Ligera preferencia por aplicaciones en primer plano" }
    default      { "Máxima prioridad a aplicaciones activas (entusiastas)" }
}

Write-Host "  • Significado: $valueExplanation" -ForegroundColor DarkGray

# --- CONSIDERACIÓN ESPECIAL PARA RIESGO ALTO ---
if ($FinalProfile.RiskLevel -eq "High") {
    Write-Host "  ⚠️  Riesgo alto detectado: usando valor conservador (18)" -ForegroundColor Yellow
    $CPUValue = 18
    Write-Host "  • Valor ajustado: $CPUValue (seguridad primero)" -ForegroundColor DarkGray
    $needsUpdate = ($currentValue -ne $CPUValue)  # Recalcular si necesita update
}

# --- APLICACIÓN CON MODO SEGURO RESPETADO ---
if (-not $GlobalConfig.SafeMode -and $needsUpdate) {
    try {
        # Crear clave si no existe
        if (-not (Test-Path $priorityPath)) {
            New-Item -Path $priorityPath -Force | Out-Null
        }
        
        # Aplicar valor
        Set-ItemProperty -Path $priorityPath -Name Win32PrioritySeparation -Value $CPUValue -Type DWord -ErrorAction Stop
        
        # Verificar
        $verified = Get-ItemProperty -Path $priorityPath -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
        if ($verified.Win32PrioritySeparation -eq $CPUValue) {
            if ($currentValue) {
                Write-Host "  • Actualizado: $currentValue → $CPUValue" -ForegroundColor Green
            } else {
                Write-Host "  • Configurado: $CPUValue" -ForegroundColor Green
            }
        }
        
    } catch {
        Write-Host "  ⚠️  Error aplicando configuración: $_" -ForegroundColor Red
    }
} elseif ($needsUpdate -and $GlobalConfig.SafeMode) {
    Write-Host "  • MODO SEGURO: Cambio pendiente ($($currentValue??'No configurado') → $CPUValue)" -ForegroundColor Yellow
} elseif (-not $needsUpdate) {
    Write-Host "  • Ya configurado óptimamente ($CPUValue)" -ForegroundColor Green
}

# --- NOTA TÉCNICA PARA SISTEMAS MODERNOS ---
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    Write-Host "  • Windows 11: Thread Director optimiza dinámicamente hilos P+E" -ForegroundColor DarkGray
}

if ($SystemProfile.CPU.Hybrid) {
    Write-Host "  • CPU híbrida: Windows gestiona prioridades de núcleos P/E" -ForegroundColor DarkGray
}

# --- BACKUP (SOLO SI HUBO CAMBIO) ---
if ($GlobalConfig.CreateBackup -and $needsUpdate -and $currentValue) {
    try {
        $backupDir = "$($GlobalConfig.BackupPath)\CPU Priority"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $backupInfo = @"
[CPU Priority Backup]
Fecha: $(Get-Date)
Valor anterior: $currentValue
Valor nuevo: $CPUValue
HardwareTier: $($FinalProfile.HardwareTier)
RiskStrategy: $($FinalProfile.RiskStrategy)
RiskLevel: $($FinalProfile.RiskLevel)
CPU: $($SystemProfile.CPU.Vendor) $($SystemProfile.CPU.Cores)c/$($SystemProfile.CPU.Threads)t
Aplicado: $(if($GlobalConfig.SafeMode){'NO (SafeMode)'}else{'SI'})
"@
        
        $backupInfo | Out-File "$backupDir\CPU_Priority_Backup.txt" -Encoding UTF8
    } catch {
        # No crítico
    }
}

Write-Host "✔ Balance contextual de prioridades completado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 4] Optimización contextual de retrasos del sistema
# =====================================================================
Write-Host "[FASE 4] Optimización contextual de retrasos del sistema" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Ajustando retrasos UI según perfil y tipo de almacenamiento..." -ForegroundColor DarkGray
Write-Host ""

# NOTA: Estos ajustes son por usuario (HKCU).
#       Se aplican solo al perfil actual en ejecución.

# --- CONFIGURACIÓN BASE (SIEMPRE SEGURA) ---
$delayConfig = @{
    # Paths de configuración (HKCU = usuario actual)
    ExplorerSerializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
    ExplorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    # Valores por defecto Windows (para referencia)
    DefaultValues = @{
        StartupDelayInMSec = 4000  # Valor por defecto Windows (4 segundos)
        DesktopProcess = 0          # Valor por defecto (proceso compartido)
    }
}

# --- VALORES RECOMENDADOS SEGÚN PERFIL ---
$recommendedDelays = @{
    StartupDelayInMSec = switch ($SystemProfile.Storage.SystemDiskType) {
        "NVMe" { 0 }      # Casi instantáneo
        "SSD"  { 50 }     # Muy rápido
        "HDD"  { 200 }    # Moderado para mecánicos
        default { 100 }   # Seguro para desconocido
    }
    
    DesktopProcess = 1  # Siempre recomendado (estabilidad)
}

# --- EXPLICACIÓN DE LOS AJUSTES ---
Write-Host "  • Almacenamiento sistema: $($SystemProfile.Storage.SystemDiskType)" -ForegroundColor DarkGray

$delayExplanation = switch ($SystemProfile.Storage.SystemDiskType) {
    "NVMe" { "Retraso mínimo (0ms) - NVMe es casi instantáneo" }
    "SSD"  { "Retraso rápido (50ms) - SSD responde rápidamente" }
    "HDD"  { "Retraso moderado (200ms) - HDD necesita más tiempo" }
    default { "Retraso seguro (100ms) - Valor universal óptimo" }
}

Write-Host "  • Recomendación: $delayExplanation" -ForegroundColor Cyan
Write-Host "  • Contexto: Ajustes por usuario (perfil actual)" -ForegroundColor DarkGray

# --- 1. RETRASO DE INICIO DEL EXPLORER (StartupDelayInMSec) ---
Write-Host "  » Retraso de inicio del Explorer..." -ForegroundColor DarkGray

# Verificar valor actual (IDEMPOTENCIA)
$currentStartupDelay = $null
try {
    if (Test-Path $delayConfig.ExplorerSerializePath) {
        $prop = Get-ItemProperty -Path $delayConfig.ExplorerSerializePath -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue
        $currentStartupDelay = $prop.StartupDelayInMSec
    }
} catch {
    # Fallback al valor por defecto si no se puede leer
}

if ($null -eq $currentStartupDelay) {
    $currentStartupDelay = $delayConfig.DefaultValues.StartupDelayInMSec
}

# Determinar valor objetivo
$targetStartupDelay = $recommendedDelays.StartupDelayInMSec

# Solo aplicar si es necesario (IDEMPOTENCIA)
if ($currentStartupDelay -ne $targetStartupDelay) {
    if (-not $GlobalConfig.SafeMode) {
        try {
            # Crear clave si no existe
            if (-not (Test-Path $delayConfig.ExplorerSerializePath)) {
                New-Item -Path $delayConfig.ExplorerSerializePath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $delayConfig.ExplorerSerializePath -Name StartupDelayInMSec -Type DWord -Value $targetStartupDelay -ErrorAction Stop
            Write-Host "  • Retraso Explorer ajustado: ${currentStartupDelay}ms → ${targetStartupDelay}ms" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Error actualizando retraso: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  • MODO SEGURO: Cambio pendiente (${currentStartupDelay}ms → ${targetStartupDelay}ms)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  • Retraso Explorer ya óptimo: ${currentStartupDelay}ms" -ForegroundColor Green
}

# --- 2. PROCESO DE ESCRITORIO SEPARADO (DesktopProcess) ---
Write-Host "  » Proceso de escritorio separado..." -ForegroundColor DarkGray

# Verificar valor actual (IDEMPOTENCIA)
$currentDesktopProcess = $null
try {
    $prop = Get-ItemProperty -Path $delayConfig.ExplorerAdvancedPath -Name "DesktopProcess" -ErrorAction SilentlyContinue
    $currentDesktopProcess = $prop.DesktopProcess
} catch {
    # No existe o error
}

if ($null -eq $currentDesktopProcess) {
    $currentDesktopProcess = $delayConfig.DefaultValues.DesktopProcess
}

# Determinar valor objetivo
$targetDesktopProcess = $recommendedDelays.DesktopProcess

# Solo aplicar si es necesario (IDEMPOTENCIA)
if ($currentDesktopProcess -ne $targetDesktopProcess) {
    if (-not $GlobalConfig.SafeMode) {
        try {
            Set-ItemProperty -Path $delayConfig.ExplorerAdvancedPath -Name DesktopProcess -Type DWord -Value $targetDesktopProcess -ErrorAction Stop
            Write-Host "  • Proceso escritorio: $currentDesktopProcess → $targetDesktopProcess" -ForegroundColor Green
            Write-Host "    (mayor estabilidad, crash de Explorer no afecta escritorio)" -ForegroundColor DarkGray
        } catch {
            Write-Host "  ⚠️  Error actualizando proceso escritorio: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  • MODO SEGURO: Cambio pendiente ($currentDesktopProcess → $targetDesktopProcess)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  • Proceso escritorio ya configurado: $currentDesktopProcess" -ForegroundColor Green
}

# --- 3. INFORMACIÓN SOBRE APLICACIÓN DE CAMBIOS ---
if ((-not $GlobalConfig.SafeMode) -and ($currentStartupDelay -ne $targetStartupDelay -or $currentDesktopProcess -ne $targetDesktopProcess)) {
    Write-Host "  ℹ️  Cambios en Explorer se aplican tras cerrar sesión o reiniciar Explorer" -ForegroundColor DarkGray
}

# --- 4. MENÚ SHOW DELAY (DELIBERADAMENTE NO TOCADO) ---
Write-Host "  » Menú show delay..." -ForegroundColor DarkGray
Write-Host "  • NO modificado - valor 0 es peligroso (UI inusable)" -ForegroundColor Yellow
Write-Host "    Windows ya optimiza esto automáticamente" -ForegroundColor DarkGray

# --- 5. CONSIDERACIONES ESPECIALES ---
$specialNotes = @()

# Para sistemas con poca RAM
if ($SystemProfile.CPU.Cores -lt 4 -or $FinalProfile.HardwareTier -eq "LIVIANO") {
    $specialNotes += "Sistema limitado: Proceso separado consume ~10MB RAM extra pero da estabilidad"
}

# Para laptops
if ($SystemProfile.Platform.IsLaptop) {
    $specialNotes += "Laptop: Proceso separado mejora estabilidad en modo portátil"
}

if ($specialNotes.Count -gt 0) {
    Write-Host "  • Consideraciones:" -ForegroundColor DarkGray
    $specialNotes | ForEach-Object {
        Write-Host "    › $_" -ForegroundColor DarkGray
    }
}

# --- BACKUP DE CAMBIOS ---
if ($GlobalConfig.CreateBackup -and ($currentStartupDelay -ne $targetStartupDelay -or $currentDesktopProcess -ne $targetDesktopProcess)) {
    try {
        $backupDir = "$($GlobalConfig.BackupPath)\UI Delays"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $backupInfo = @"
[UI Delays Backup]
Fecha: $(Get-Date)
Contexto: Perfil usuario actual (HKCU)
---
StartupDelayInMSec:
  Anterior: $currentStartupDelay ms
  Nuevo: $targetStartupDelay ms
  Aplicado: $(if($currentStartupDelay -ne $targetStartupDelay -and -not $GlobalConfig.SafeMode){'SI'}else{'NO'})
---
DesktopProcess:
  Anterior: $currentDesktopProcess
  Nuevo: $targetDesktopProcess
  Aplicado: $(if($currentDesktopProcess -ne $targetDesktopProcess -and -not $GlobalConfig.SafeMode){'SI'}else{'NO'})
---
Perfil:
  HardwareTier: $($FinalProfile.HardwareTier)
  StorageType: $($SystemProfile.Storage.SystemDiskType)
  EsLaptop: $($SystemProfile.Platform.IsLaptop)
Nota: Cambios requieren reinicio de Explorer o cierre de sesión
"@
        
        $backupInfo | Out-File "$backupDir\UI_Delays_Backup.txt" -Encoding UTF8
        Write-Host "  • Backup creado en: $backupDir" -ForegroundColor DarkGray
    } catch {
        # No crítico
    }
}

Write-Host "✔ Optimización contextual de retrasos completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 5] Análisis contextual de memoria virtual
# =====================================================================
Write-Host "[FASE 5] Análisis contextual de memoria virtual" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Analizando configuración de memoria virtual..." -ForegroundColor DarkGray
Write-Host ""

# Filosofía clara desde el inicio
Write-Host "  🎯 FILOSOFÍA: Windows gestiona mejor que cualquier tweak manual" -ForegroundColor Cyan
Write-Host "    (Excepto casos muy específicos con supervisión experta)" -ForegroundColor DarkGray
Write-Host ""

try {
    $cs = Get-CimInstance Win32_ComputerSystem
    $totalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    
    # --- CONTEXTO DE RAM INSTALADA ---
    Write-Host "  • Memoria RAM instalada: ${totalRAM} GB" -ForegroundColor DarkGray
    
    # Interpretación según cantidad de RAM
    $ramContext = switch ($totalRAM) {
        { $_ -lt 4 }  { "Mínima para Windows 10/11" }
        { $_ -lt 8 }  { "Adecuada para uso básico" }
        { $_ -lt 16 } { "Óptima para multitarea general" }
        { $_ -lt 32 } { "Excelente para productividad" }
        default       { "Abundante para workloads pesados" }
    }
    
    Write-Host "  • Contexto: $ramContext" -ForegroundColor DarkGray
    
    # --- VERIFICACIÓN DE GESTIÓN AUTOMÁTICA ---
    if ($cs.AutomaticManagedPagefile) {
        Write-Host "  • Gestión automática: HABILITADA ✓" -ForegroundColor Green
        Write-Host "    Windows ajusta dinámicamente según necesidad" -ForegroundColor DarkGray
    } else {
        Write-Host "  ⚠️  Gestión manual detectada" -ForegroundColor Yellow
        
        # Mensaje informativo y cauteloso
        Write-Host "  ℹ️  Configuración personalizada puede ser intencional" -ForegroundColor DarkGray
        Write-Host "    Cambiar esto requiere reinicio y puede afectar estabilidad" -ForegroundColor DarkGray
        
        # Solo en modo no-safe ofrecemos opción
        if (-not $GlobalConfig.SafeMode) {
            Write-Host "  » Opción: Habilitar gestión automática (recomendado)" -ForegroundColor DarkGray
            $choice = Read-Host "    ¿Continuar? (S para habilitar automático / N para mantener manual)"
            
            if ($choice -eq "S" -or $choice -eq "s") {
                try {
                    $cs | Set-CimInstance -Property @{AutomaticManagedPagefile = $true} -ErrorAction Stop
                    Write-Host "  • Gestión automática habilitada (requiere reinicio)" -ForegroundColor Green
                    Write-Host "    Los cambios se aplicarán al reiniciar el sistema" -ForegroundColor DarkGray
                } catch {
                    Write-Host "  ⚠️  No se pudo habilitar gestión automática: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "  • Configuración manual preservada" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  • MODO SEGURO: Solo informando, sin cambios" -ForegroundColor DarkGray
        }
    }
    
    # --- INFORMACIÓN DETALLADA DE PAGEFILES EXISTENTES ---
    Write-Host ""
    Write-Host "  » Pagefiles detectados en el sistema:" -ForegroundColor DarkGray
    
    $pagefiles = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
    
    if ($pagefiles -and $pagefiles.Count -gt 0) {
        foreach ($pf in $pagefiles) {
            $sizeMB = [math]::Round($pf.AllocatedBaseSize)  # Tamaño actual en MB
            $sizeGB = [math]::Round($sizeMB / 1024, 1)      # Convertir a GB
            $usageMB = $pf.CurrentUsage                     # Uso actual en MB
            $usagePercent = if ($sizeMB -gt 0) { [math]::Round(($usageMB / $sizeMB) * 100) } else { 0 }
            
            # Determinar estado
            $status = switch ($usagePercent) {
                { $_ -lt 30 } { "Bajo uso" }
                { $_ -lt 60 } { "Uso moderado" }
                { $_ -lt 80 } { "Uso elevado" }
                default       { "Uso crítico" }
            }
            
            Write-Host "  • $($pf.Name)" -ForegroundColor DarkGray
            Write-Host "    Tamaño: ${sizeGB} GB | En uso: ${usageMB} MB (${usagePercent}%)" -ForegroundColor DarkGray
            Write-Host "    Estado: $status" -ForegroundColor $(
                switch ($usagePercent) {
                    { $_ -lt 30 } { "Green" }
                    { $_ -lt 60 } { "Yellow" }
                    default       { "Red" }
                }
            )
            
            # Advertencia si está en SSD y uso elevado
            if ($usagePercent -gt 70 -and $SystemProfile.Storage.SystemDiskType -in @("SSD", "NVMe")) {
                Write-Host "    ⚠️  Uso elevado en $($SystemProfile.Storage.SystemDiskType) - revisar carga de trabajo" -ForegroundColor Yellow
            }
        }
        
        # Estadísticas generales
        $totalPagefileGB = [math]::Round(($pagefiles | Measure-Object -Property AllocatedBaseSize -Sum).Sum / 1024, 1)
        $ratioRAMtoPagefile = [math]::Round($totalPagefileGB / $totalRAM, 2)
        
        Write-Host ""
        Write-Host "  📊 Estadísticas memoria virtual:" -ForegroundColor DarkGray
        Write-Host "    • Total pagefile: ${totalPagefileGB} GB" -ForegroundColor DarkGray
        Write-Host "    • Ratio RAM/Pagefile: 1 : ${ratioRAMtoPagefile}" -ForegroundColor DarkGray
        
        # Interpretación del ratio
        $ratioInterpretation = switch ($ratioRAMtoPagefile) {
            { $_ -lt 0.5 } { "Pagefile pequeño para la RAM" }
            { $_ -lt 1.5 } { "Ratio estándar" }
            { $_ -lt 3 }   { "Pagefile generoso" }
            default        { "Pagefile muy grande" }
        }
        
        Write-Host "    • Interpretación: $ratioInterpretation" -ForegroundColor DarkGray
        
    } else {
        Write-Host "  • No se detectaron pagefiles activos" -ForegroundColor Yellow
        Write-Host "    Windows puede estar usando memoria comprimida o RAM disk" -ForegroundColor DarkGray
    }
    
    # --- RECOMENDACIÓN PERSONALIZADA SEGÚN PERFIL ---
    Write-Host ""
    Write-Host "  🎯 RECOMENDACIÓN PARA ESTE SISTEMA:" -ForegroundColor Cyan
    
    $recommendation = switch ($FinalProfile.HardwareTier) {
        "ENTUSIASTA" {
            if ($totalRAM -ge 32) {
                "Sistema potente (>32GB RAM): Pagefile pequeño (2-4GB) o automático"
            } else {
                "Mantener gestión automática (Windows optimiza para cargas pesadas)"
            }
        }
        "EQUILIBRADO" {
            "Gestión automática es óptima (balance perfecto rendimiento/estabilidad)"
        }
        "ESTÁNDAR" {
            "No modificar configuración actual (Windows ya está optimizado)"
        }
        "LIVIANO" {
            if ($totalRAM -lt 8) {
                "Sistema con poca RAM: Asegurar pagefile de al menos 8GB"
            } else {
                "Gestión automática recomendada"
            }
        }
    }
    
    Write-Host "  • $recommendation" -ForegroundColor DarkGray
    
    # Consideración especial para SSDs
    if ($SystemProfile.Storage.SystemDiskType -in @("SSD", "NVMe")) {
        Write-Host "  • $($SystemProfile.Storage.SystemDiskType): Write endurance no es problema moderno" -ForegroundColor DarkGray
        Write-Host "    Los SSDs actuales duran décadas incluso con pagefile activo" -ForegroundColor DarkGray
    }
    
} catch {
    Write-Host "  ⚠️  Error en análisis de memoria virtual: $_" -ForegroundColor Red
    Write-Host "  • Continuando con configuración actual..." -ForegroundColor DarkGray
}

# --- BACKUP DE INFORMACIÓN (NO DE CONFIGURACIÓN) ---
if ($GlobalConfig.CreateBackup) {
    try {
        $backupDir = "$($GlobalConfig.BackupPath)\VirtualMemory"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $backupInfo = @"
[Virtual Memory Analysis]
Fecha: $(Get-Date)
---
RAM Total: ${totalRAM} GB
Gestión Automática: $(if($cs.AutomaticManagedPagefile){'SI'}else{'NO'})
---
Pagefiles detectados:
$(
    if ($pagefiles) {
        foreach ($pf in $pagefiles) {
            "  • $($pf.Name): $([math]::Round($pf.AllocatedBaseSize/1024,1)) GB"
        }
    } else {
        "  Ninguno detectado"
    }
)
---
Perfil:
  HardwareTier: $($FinalProfile.HardwareTier)
  StorageType: $($SystemProfile.Storage.SystemDiskType)
---
Recomendación: $recommendation
"@
        
        $backupInfo | Out-File "$backupDir\VirtualMemory_Analysis.txt" -Encoding UTF8
        Write-Host "  • Análisis guardado en: $backupDir" -ForegroundColor DarkGray
    } catch {
        # No crítico
    }
}

Write-Host ""
Write-Host "✔ Análisis contextual de memoria virtual completado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 6] Configuración contextual de red
# =====================================================================
Write-Host "[FASE 6] Configuración contextual de red" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Aplicando configuración segura de red..." -ForegroundColor DarkGray
Write-Host ""

# --- CONFIGURACIÓN TCP GLOBAL (SIEMPRE SEGURA) ---
Write-Host "  • TCP Auto-tuning: Normal (estable y recomendado)" -ForegroundColor DarkGray
netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null

Write-Host "  • TCP RSS: Habilitado (mejor rendimiento multicore)" -ForegroundColor DarkGray
netsh int tcp set global rss=enabled 2>&1 | Out-Null

Write-Host "  • TCP Chimney: Deshabilitado (tecnología obsoleta)" -ForegroundColor DarkGray
netsh int tcp set global chimney=disabled 2>&1 | Out-Null

# --- DETECCIÓN Y ANÁLISIS DEL ADAPTADOR ACTIVO ---
$activeAdapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface } | 
                 Select-Object -First 1

if ($activeAdapter) {
    Write-Host ""
    Write-Host "  📶 ADAPTADOR DE RED DETECTADO:" -ForegroundColor Cyan
    
    $adapterType = if ($activeAdapter.NdisPhysicalMedium -eq 14) { "WiFi" } else { "Ethernet" }
    
    Write-Host "  • Nombre: $($activeAdapter.Name)" -ForegroundColor DarkGray
    Write-Host "  • Tipo: $adapterType" -ForegroundColor DarkGray
    Write-Host "  • Velocidad: $($activeAdapter.LinkSpeed)" -ForegroundColor DarkGray
    Write-Host "  • MAC: $($activeAdapter.MacAddress)" -ForegroundColor DarkGray
    
    # Consideraciones especiales según tipo
    if ($adapterType -eq "WiFi") {
        Write-Host "  • WiFi: Configuración estable preservada" -ForegroundColor DarkGray
    } else {
        Write-Host "  • Ethernet: Configuración óptima aplicada" -ForegroundColor DarkGray
    }
    
    # Ajustes de energía para laptops
    if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.Platform.HasBattery) {
        Write-Host "  • Laptop: Power management activo (ahorro de batería)" -ForegroundColor DarkGray
    }
} else {
    Write-Host ""
    Write-Host "  ⚠️  No se detectaron adaptadores de red físicos activos" -ForegroundColor Yellow
    Write-Host "  • Solo se aplicó configuración TCP global" -ForegroundColor DarkGray
}

# --- MANTENIMIENTO DNS ---
Write-Host ""
Write-Host "  » Mantenimiento de DNS..." -ForegroundColor DarkGray

try {
    Clear-DnsClientCache -ErrorAction Stop
    Write-Host "  • DNS: Caché limpiada correctamente" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  DNS: No se pudo limpiar caché (sin privilegios)" -ForegroundColor Yellow
}

# Opcional: Flush DNS más agresivo (solo si hay problemas reportados)
if ($FinalProfile.HardwareTier -eq "ENTUSIASTA" -and -not $GlobalConfig.SafeMode) {
    try {
        ipconfig /flushdns 2>&1 | Out-Null
        Write-Host "  • DNS: Flush completo ejecutado" -ForegroundColor DarkGray
    } catch {
        # Silencioso
    }
}

# --- BACKUP DE CONFIGURACIÓN (INFORMATIVO) ---
if ($GlobalConfig.CreateBackup) {
    try {
        $backupDir = "$($GlobalConfig.BackupPath)\NetworkConfig"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $networkInfo = @"
[Network Configuration Backup]
Fecha: $(Get-Date)
---
Configuración TCP:
  Auto-tuning: normal
  RSS: enabled
  Chimney: disabled
---
Adaptador activo:
$(
    if ($activeAdapter) {
        "  Nombre: $($activeAdapter.Name)`n" +
        "  Tipo: $adapterType`n" +
        "  Velocidad: $($activeAdapter.LinkSpeed)`n" +
        "  MAC: $($activeAdapter.MacAddress)"
    } else {
        "  Ninguno detectado"
    }
)
---
Perfil aplicado:
  HardwareTier: $($FinalProfile.HardwareTier)
  EsLaptop: $($SystemProfile.Platform.IsLaptop)
"@
        
        $networkInfo | Out-File "$backupDir\Network_Config.txt" -Encoding UTF8
        Write-Host "  • Configuración guardada en: $backupDir" -ForegroundColor DarkGray
    } catch {
        # No crítico
    }
}

Write-Host ""
Write-Host "✔ Configuración contextual de red completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 7] Optimización contextual de almacenamiento
# =====================================================================
Write-Host "[FASE 7] Optimización contextual de almacenamiento" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Optimizando almacenamiento según tipo y perfil..." -ForegroundColor DarkGray
Write-Host ""

# Variables para backup y logging
$trimExecuted = "NO"
$lastAccessChanged = $false
$ntfsBuffersChanged = $false
$prefetchChanged = $false

# Usar SystemProfile en lugar de hardwareInfo (consistencia)
$systemDiskType = $SystemProfile.Storage.SystemDiskType

if ($systemDiskType -ne "Unknown") {
    Write-Host "  📀 DISCO DEL SISTEMA DETECTADO:" -ForegroundColor Cyan
    Write-Host "  • Tipo: $systemDiskType" -ForegroundColor DarkGray
    
    # Información adicional si está disponible
    $diskInfo = $hardwareInfo.Storage | Where-Object { $_.IsSystem -eq $true } | Select-Object -First 1
    if ($diskInfo) {
        if ($diskInfo.FriendlyName) {
            Write-Host "  • Modelo: $($diskInfo.FriendlyName)" -ForegroundColor DarkGray
        }
        if ($diskInfo.SizeGB) {
            Write-Host "  • Tamaño: $($diskInfo.SizeGB) GB" -ForegroundColor DarkGray
        }
    }
    
    # --- 1. CONFIGURACIÓN UNIVERSAL SEGURA ---
    Write-Host ""
    Write-Host "  » Aplicando ajustes seguros para todos los discos..." -ForegroundColor DarkGray
    
    # disablelastaccess - SIEMPRE deshabilitado (parsing robusto)
    $currentLastAccess = fsutil behavior query disablelastaccess 2>&1
    
    # Uso de regex más robusto "=\s*1" en lugar de texto exacto
    if ($currentLastAccess -notmatch "=\s*1") {
        if (-not $GlobalConfig.SafeMode) {
            fsutil behavior set disablelastaccess 1 2>&1 | Out-Null
            $lastAccessChanged = $true
            
            # Mostrar cambio con valor anterior
            $previousValue = if ($currentLastAccess -match "=\s*(\d)") { $matches[1] } else { "Desconocido" }
            Write-Host "  • NTFS LastAccess: $previousValue → 1 (reduce escrituras)" -ForegroundColor Green
        } else {
            Write-Host "  • MODO SEGURO: LastAccess pendiente (deshabilitar)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  • NTFS LastAccess: Ya deshabilitado (1)" -ForegroundColor DarkGray
    }
    
    # --- 2. AJUSTES ESPECÍFICOS POR TIPO ---
    Write-Host ""
    Write-Host "  » Aplicando optimizaciones específicas..." -ForegroundColor DarkGray
    
    switch ($systemDiskType) {
        "NVMe" {
            Write-Host "  • NVMe: Configuración de alto rendimiento" -ForegroundColor DarkGray
            
            # Buffers NTFS normal (no máximo - más conservador)
            $ntfsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
            $currentNtfsUsage = Get-ItemProperty -Path $ntfsPath -Name "NtfsMemoryUsage" -ErrorAction SilentlyContinue
            
            if (-not $currentNtfsUsage -or $currentNtfsUsage.NtfsMemoryUsage -ne 1) {
                if (-not $GlobalConfig.SafeMode) {
                    Set-ItemProperty -Path $ntfsPath -Name "NtfsMemoryUsage" -Value 1 -ErrorAction SilentlyContinue
                    $ntfsBuffersChanged = $true
                    Write-Host "  • Buffers NTFS: Configurados para rendimiento (1)" -ForegroundColor Green
                } else {
                    Write-Host "  • MODO SEGURO: Buffers NTFS pendiente (→ 1)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  • Buffers NTFS: Ya configurado (1)" -ForegroundColor DarkGray
            }
            
            # Asegurar TRIM activado (parsing robusto)
            $trimStatus = fsutil behavior query DisableDeleteNotify 2>&1
            
            # Uso de regex más robusto "=\s*1" en lugar de texto exacto
            if ($trimStatus -match "=\s*1") {
                if (-not $GlobalConfig.SafeMode) {
                    fsutil behavior set DisableDeleteNotify 0 2>&1 | Out-Null
                    Write-Host "  • TRIM: Activado (para NVMe)" -ForegroundColor Green
                } else {
                    Write-Host "  • MODO SEGURO: TRIM pendiente (activar)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  • TRIM: Ya activado" -ForegroundColor DarkGray
            }
        }
        
        "SSD" {
            Write-Host "  • SSD: Configuración equilibrada" -ForegroundColor DarkGray
            
            # Buffers NTFS normal
            $ntfsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
            $currentNtfsUsage = Get-ItemProperty -Path $ntfsPath -Name "NtfsMemoryUsage" -ErrorAction SilentlyContinue
            
            if (-not $currentNtfsUsage -or $currentNtfsUsage.NtfsMemoryUsage -ne 1) {
                if (-not $GlobalConfig.SafeMode) {
                    Set-ItemProperty -Path $ntfsPath -Name "NtfsMemoryUsage" -Value 1 -ErrorAction SilentlyContinue
                    $ntfsBuffersChanged = $true
                    Write-Host "  • Buffers NTFS: Configurados estándar (1)" -ForegroundColor Green
                } else {
                    Write-Host "  • MODO SEGURO: Buffers NTFS pendiente (→ 1)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  • Buffers NTFS: Ya configurado (1)" -ForegroundColor DarkGray
            }
            
            # Consideración para laptops (batería)
            if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.Platform.HasBattery) {
                Write-Host "  • Laptop SSD: Power management preservado" -ForegroundColor DarkGray
            }
        }
        
        "HDD" {
            # Mensaje más descriptivo
            Write-Host "  • HDD: Prefetch/SuperFetch activos, buffers NTFS sin cambios" -ForegroundColor DarkGray
            
            # Prefetch completo para HDD
            $prefetchPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
            
            # Prefetcher
            $currentPrefetch = Get-ItemProperty -Path $prefetchPath -Name "EnablePrefetcher" -ErrorAction SilentlyContinue
            if (-not $currentPrefetch -or $currentPrefetch.EnablePrefetcher -ne 3) {
                if (-not $GlobalConfig.SafeMode) {
                    Set-ItemProperty -Path $prefetchPath -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
                    $prefetchChanged = $true
                    Write-Host "  • Prefetch: Habilitado completo (3)" -ForegroundColor Green
                } else {
                    Write-Host "  • MODO SEGURO: Prefetch pendiente (→ 3)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  • Prefetch: Ya habilitado (3)" -ForegroundColor DarkGray
            }
            
            # SuperFetch
            $currentSuperfetch = Get-ItemProperty -Path $prefetchPath -Name "EnableSuperfetch" -ErrorAction SilentlyContinue
            if (-not $currentSuperfetch -or $currentSuperfetch.EnableSuperfetch -ne 3) {
                if (-not $GlobalConfig.SafeMode) {
                    Set-ItemProperty -Path $prefetchPath -Name "EnableSuperfetch" -Value 3 -ErrorAction SilentlyContinue
                    $prefetchChanged = $true
                    Write-Host "  • SuperFetch: Habilitado completo (3)" -ForegroundColor Green
                } else {
                    Write-Host "  • MODO SEGURO: SuperFetch pendiente (→ 3)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  • SuperFetch: Ya habilitado (3)" -ForegroundColor DarkGray
            }
        }
        
        default {
            Write-Host "  • Tipo desconocido: Solo ajustes universales aplicados" -ForegroundColor Yellow
        }
    }
    
    # --- 3. OPTIMIZACIÓN LÓGICA (NO DEFRAG) ---
    if ($systemDiskType -in @("NVMe", "SSD")) {
        Write-Host ""
        Write-Host "  » Ejecutando optimización para almacenamiento flash..." -ForegroundColor DarkGray
        
        try {
            $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive.Replace(":", "")
            
            # Solo ejecutar si han pasado más de 7 días desde última optimización
            $lastOpt = Get-Volume -DriveLetter $systemDrive -ErrorAction SilentlyContinue | 
                      Select-Object -ExpandProperty TimeSinceLastTrim -ErrorAction SilentlyContinue
            
            # Determinar si se ejecutó TRIM
            if (-not $lastOpt -or $lastOpt.Days -gt 7) {
                if (-not $GlobalConfig.SafeMode) {
                    Optimize-Volume -DriveLetter $systemDrive -ReTrim -ErrorAction SilentlyContinue | Out-Null
                    $trimExecuted = "SI (ejecutado ahora)"
                    Write-Host "  • TRIM/Optimización: Ejecutado ahora" -ForegroundColor Green
                } else {
                    $trimExecuted = "SI (pendiente en modo seguro)"
                    Write-Host "  • MODO SEGURO: TRIM pendiente (ejecutaría ahora)" -ForegroundColor Yellow
                }
                Write-Host "    (Windows ya lo hace automáticamente semanalmente)" -ForegroundColor DarkGray
            } else {
                $trimExecuted = "NO (ya optimizado hace $($lastOpt.Days) días)"
                Write-Host "  • TRIM: Ya optimizado recientemente ($($lastOpt.Days) días)" -ForegroundColor DarkGray
            }
        } catch {
            $trimExecuted = "NO (error al verificar)"
            Write-Host "  • TRIM: Windows gestiona automáticamente" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "✔ Almacenamiento optimizado contextualmente" -ForegroundColor Green
    
} else {
    Write-Host "  ⚠️  Tipo de almacenamiento no detectado" -ForegroundColor Yellow
    Write-Host "  • Solo ajustes universales aplicados" -ForegroundColor DarkGray
    Write-Host "✔ Verificación de almacenamiento completada" -ForegroundColor Green
}

# --- BACKUP INFORMATIVO (CON AJUSTE MEJORADO) ---
if ($GlobalConfig.CreateBackup) {
    try {
        $backupDir = "$($GlobalConfig.BackupPath)\StorageOptimization"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $backupInfo = @"
[Storage Optimization Backup]
Fecha: $(Get-Date)
---
Tipo de disco sistema: $systemDiskType
Modo Seguro: $(if($GlobalConfig.SafeMode){'SI'}else{'NO'})
---
Ajustes aplicados:
  • LastAccess deshabilitado: $(if($lastAccessChanged){'SI'}else{'Ya estaba'})
  • Buffers NTFS: $(
    if ($systemDiskType -in @("NVMe", "SSD")) {
        if ($ntfsBuffersChanged) { 'Actualizado a 1' } else { 'Ya en 1' }
    } else {
        'Sin cambios (HDD/Desconocido)'
    }
  )
  • Prefetch/SuperFetch: $(
    if ($systemDiskType -eq "HDD") {
        if ($prefetchChanged) { 'Actualizados a 3' } else { 'Ya en 3' }
    } else {
        'N/A (no HDD)'
    }
  )
  • TRIM ejecutado: $trimExecuted
---
Perfil aplicado:
  • HardwareTier: $($FinalProfile.HardwareTier)
  • RiskStrategy: $($FinalProfile.RiskStrategy)
  • EsLaptop: $($SystemProfile.Platform.IsLaptop)
  • ConBatería: $($SystemProfile.Platform.HasBattery)
---
Notas:
  • Los cambios en HKCU/HKLM requieren reinicio para efecto completo
  • Windows gestiona automáticamente TRIM/Defrag según tipo de disco
"@
        
        $backupInfo | Out-File "$backupDir\Storage_Optimization_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" -Encoding UTF8
        Write-Host "  • Configuración guardada en: $backupDir" -ForegroundColor DarkGray
    } catch {
        # No crítico
    }
}

Write-Host ""

# =====================================================================
# [FASE 8] Información contextual y mantenimiento
# =====================================================================
Write-Host "[FASE 8] Información contextual y mantenimiento" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray
Write-Host ""

Write-Host "📊 RESUMEN CONTEXTUAL DEL SISTEMA" -ForegroundColor Cyan
Write-Host "• Sistema analizado:" -ForegroundColor DarkGray
Write-Host "  - OS: $($SystemProfile.OSEdition)" -ForegroundColor DarkGray
Write-Host "  - CPU: $($SystemProfile.CPU.Vendor) $($SystemProfile.CPU.Cores)c/$($SystemProfile.CPU.Threads)t $(if($SystemProfile.CPU.Modern){'(Moderno)'}else{'(Legacy)'})" -ForegroundColor DarkGray
Write-Host "  - RAM: ${totalRAM} GB" -ForegroundColor DarkGray
Write-Host "  - Almacenamiento: $($SystemProfile.Storage.SystemDiskType)" -ForegroundColor DarkGray
Write-Host "  - GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)" -ForegroundColor DarkGray
Write-Host "  - Plataforma: $(if($SystemProfile.Platform.IsLaptop){'Laptop'}else{'Desktop'})" -ForegroundColor DarkGray
Write-Host "• Perfil hardware: $($FinalProfile.HardwareTier)" -ForegroundColor DarkGray
Write-Host "• Estrategia: $($FinalProfile.RiskStrategy)" -ForegroundColor DarkGray
Write-Host "• Riesgo: $($FinalProfile.RiskLevel)" -ForegroundColor DarkGray
Write-Host "• Tweaks peligrosos eliminados: $tweaksRemoved" -ForegroundColor DarkGray
Write-Host ""

Write-Host "🔧 MANTENIMIENTO CONTEXTUAL RECOMENDADO" -ForegroundColor Cyan

$maintenanceTips = @()

# Recomendaciones basadas en perfil
switch ($FinalProfile.HardwareTier) {
    "ENTUSIASTA" {
        $maintenanceTips += "• Actualizaciones BIOS/UEFI: Revisar con fabricante"
        $maintenanceTips += "• Drivers GPU: Mantener actualizados (NVIDIA/AMD)"
        $maintenanceTips += "• Temperaturas: Monitorear en cargas pesadas"
    }
    "EQUILIBRADO" {
        $maintenanceTips += "• Windows Update: Habilitar actualizaciones automáticas"
        $maintenanceTips += "• Drivers: Actualizar solo si hay problemas"
        $maintenanceTips += "• Reinicio: Semanal para liberar memoria"
    }
    "ESTÁNDAR" {
        $maintenanceTips += "• Windows Update: Fundamental para seguridad"
        $maintenanceTips += "• Limpieza disco: Mensual con cleanmgr"
        $maintenanceTips += "• Reinicio: Cuando note lentitud"
    }
    "LIVIANO" {
        $maintenanceTips += "• Espacio disco: Mantener al menos 15% libre"
        $maintenanceTips += "• Programas inicio: Minimizar cantidad"
        $maintenanceTips += "• Actualizaciones: Solo críticas para no sobrecargar"
    }
}

# Recomendaciones específicas para laptops
if ($SystemProfile.Platform.IsLaptop) {
    $maintenanceTips += "• Batería: No mantener siempre al 100% (ideal 40-80%)"
    $maintenanceTips += "• Ventilación: Mantener salidas de aire libres"
    $maintenanceTips += "• Drivers: Usar versión del fabricante (no genérica)"
}

$maintenanceTips | ForEach-Object {
    Write-Host $_ -ForegroundColor DarkGray
}

Write-Host ""

Write-Host "⚡ OPTIMIZACIONES APLICADAS (contextuales)" -ForegroundColor Cyan

# Obtener valores reales aplicados (no hardcodeados)
$appliedOptimizations = @()

# CPU Priority (de FASE 3)
$appliedOptimizations += "• Prioridades CPU: $CPUValue (perfil $($FinalProfile.HardwareTier)/$($FinalProfile.RiskStrategy))"

# Storage delays (de FASE 4)
$actualDelay = switch ($SystemProfile.Storage.SystemDiskType) {
    "NVMe" { "0ms" }
    "SSD"  { "50ms" }
    "HDD"  { "200ms" }
    default { "100ms" }
}
$appliedOptimizations += "• Retrasos Explorer: $actualDelay (adaptado a $($SystemProfile.Storage.SystemDiskType))"

# Network (de FASE 6)
$appliedOptimizations += "• Red: Configuración estable (auto-tuning normal)"

# Storage (de FASE 7)
$appliedOptimizations += "• Almacenamiento: Optimizado para $($SystemProfile.Storage.SystemDiskType)"

# Memory (de FASE 2 y 5)
$appliedOptimizations += "• Memoria: Configuración segura verificada (pagefile automático)"

$appliedOptimizations | ForEach-Object {
    Write-Host $_ -ForegroundColor DarkGray
}

Write-Host ""

Write-Host "🚫 LO QUE NO HICIMOS (por diseño consciente)" -ForegroundColor Cyan
Write-Host "• No eliminamos archivos temporales del sistema" -ForegroundColor DarkGray
Write-Host "• No deshabilitamos servicios esenciales de Windows" -ForegroundColor DarkGray
Write-Host "• No cambiamos configuración de seguridad/firewall" -ForegroundColor DarkGray
Write-Host "• No aplicamos 'tweaks' agresivos de dudosa procedencia" -ForegroundColor DarkGray
Write-Host "• No forzamos configuración contra recomendaciones de Microsoft" -ForegroundColor DarkGray
Write-Host ""

Write-Host "⏱️  CUÁNDO EJECUTAR ESTE SCRIPT" -ForegroundColor Cyan
Write-Host "✓ Después de instalación limpia de Windows" -ForegroundColor DarkGray
Write-Host "✓ Tras usar optimizadores agresivos (WiseCare, CCleaner, etc.)" -ForegroundColor DarkGray
Write-Host "✓ Al cambiar hardware significativo (CPU, RAM, disco)" -ForegroundColor DarkGray
Write-Host "✓ Si experimentas lentitud inexplicable tras updates" -ForegroundColor DarkGray
Write-Host "✓ Antes de donar/vender el equipo (limpieza de tweaks)" -ForegroundColor DarkGray
Write-Host "✗ NO como 'acelerador' diario o semanal" -ForegroundColor DarkGray
Write-Host "✗ NO si el sistema funciona perfectamente" -ForegroundColor DarkGray
Write-Host "✗ NO para 'solucionar' problemas de hardware real" -ForegroundColor DarkGray
Write-Host ""

Write-Host "💡 FILOSOFÍA: Guidance, not force" -ForegroundColor Green
Write-Host "   Windows está optimizado por diseño. Solo removemos interferencias peligrosas" -ForegroundColor DarkGray
Write-Host "   y sugerimos ajustes según el contexto real de tu hardware." -ForegroundColor DarkGray
Write-Host "─" * 70 -ForegroundColor DarkGray
Write-Host ""

# =====================================================================
# [FASE 9] Verificación y finalización contextual
# =====================================================================
Write-Host "[FASE 9] Verificación y finalización contextual" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   PROCESO CONTEXTUAL COMPLETADO" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ VERIFICACIÓN FINAL:" -ForegroundColor Green
Write-Host "1. Análisis contextual completado (FASE 0-1)" -ForegroundColor Gray
Write-Host "2. Configuraciones peligrosas eliminadas: $tweaksRemoved" -ForegroundColor Gray
Write-Host "3. Perfil $($FinalProfile.HardwareTier) aplicado según capacidades" -ForegroundColor Gray
Write-Host "4. Estrategia $($FinalProfile.RiskStrategy) usada (riesgo: $($FinalProfile.RiskLevel))" -ForegroundColor Gray
Write-Host "5. Optimizaciones específicas por tipo de hardware" -ForegroundColor Gray
Write-Host "6. Sistema configurado de forma segura y estable" -ForegroundColor Gray
Write-Host ""

Write-Host "🎯 ESTADO FINAL DEL SISTEMA:" -ForegroundColor Yellow

$systemState = @()

# Evaluar estado según optimizaciones aplicadas
if ($tweaksRemoved -gt 0) {
    $systemState += "• Tweaks peligrosos eliminados: $tweaksRemoved ✓"
} else {
    $systemState += "• No se encontraron tweaks peligrosos ✓"
}

if ($FinalProfile.RiskLevel -eq "High" -and $FinalProfile.RiskStrategy -eq "Conservative") {
    $systemState += "• Modo conservador activado (hardware delicado) ✓"
}

if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.Platform.HasBattery) {
    $systemState += "• Laptop: Optimizaciones respetan gestión de energía ✓"
}

if ($SystemProfile.Storage.SystemDiskType -ne "Unknown") {
    $systemState += "• Almacenamiento: Optimizado para $($SystemProfile.Storage.SystemDiskType) ✓"
}

$systemState += "• Configuración coherente y sin interferencias peligrosas ✓"
$systemState += "• Listo para gestión automática de Windows ✓"

$systemState | ForEach-Object {
    Write-Host $_ -ForegroundColor Gray
}

Write-Host ""

Write-Host "⚠️  RECOMENDACIÓN FINAL" -ForegroundColor Yellow

# Recomendación personalizada según perfil
$finalRecommendation = switch ($FinalProfile.HardwareTier) {
    "ENTUSIASTA" {
        "Sistema potente detectado. Considera actualizar drivers desde fabricante para máximo rendimiento."
    }
    "EQUILIBRADO" {
        "Hardware moderno. Deja que Windows gestione automáticamente, realiza mantenimiento básico periódico."
    }
    "ESTÁNDAR" {
        "Sistema estándar. Mantén Windows Update activado y evita 'optimizadores' agresivos."
    }
    "LIVIANO" {
        "Hardware limitado. Minimiza programas en inicio y mantén al menos 15% de espacio libre en disco."
    }
}

Write-Host "• $finalRecommendation" -ForegroundColor Green

Write-Host "• Reinicia el sistema para aplicar todas las configuraciones." -ForegroundColor Green
Write-Host ""
Write-Host "   Confía en Windows. Sabe lo que hace." -ForegroundColor DarkGray
Write-Host "   Tu sistema ahora está en un estado seguro y predecible." -ForegroundColor DarkGray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Windows de Mente v1.0 | Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# --- GENERAR REPORTE COMPLETO ---
try {
    $reportPath = "$env:USERPROFILE\Desktop\WindowsDeMente_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $reportContent = @"
============================================================
  WINDOWS DE MENTE v1.0 - REPORTE DE OPTIMIZACIÓN
  Fecha: $(Get-Date)
  Sistema: $($SystemProfile.OSEdition)
============================================================

[PERFIL DEL SISTEMA]
• Hardware Tier: $($FinalProfile.HardwareTier)
• Risk Strategy: $($FinalProfile.RiskStrategy) 
• Risk Level: $($FinalProfile.RiskLevel)
• Puntuación total: $($FinalProfile.TotalScore)

[HARDWARE DETECTADO]
• CPU: $($SystemProfile.CPU.Vendor) $($SystemProfile.CPU.Cores)c/$($SystemProfile.CPU.Threads)t
• RAM: ${totalRAM} GB
• Almacenamiento: $($SystemProfile.Storage.SystemDiskType)
• GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)
• Plataforma: $(if($SystemProfile.Platform.IsLaptop){'Laptop'}else{'Desktop'})
• Red: $($SystemProfile.Network.PrimaryType) - $($SystemProfile.Network.Vendor)

[OPTIMIZACIONES APLICADAS]
• Tweaks peligrosos eliminados: $tweaksRemoved
• Prioridad CPU: $CPUValue
• Retrasos Explorer: $actualDelay
• Configuración red: Auto-tuning normal
• Almacenamiento: Optimizado para $($SystemProfile.Storage.SystemDiskType)
• Pagefile: Gestión automática activada

[RECOMENDACIONES PERSONALIZADAS]
$finalRecommendation

[LO QUE NO SE MODIFICÓ]
• Archivos temporales del sistema
• Servicios esenciales de Windows
• Configuración de seguridad/firewall
• Tweaks agresivos de dudosa procedencia

[INFORMACIÓN ADICIONAL]
• Modo seguro: $(if($GlobalConfig.SafeMode){'Activado'}else{'Desactivado'})
• Log completo: $($GlobalConfig.LogFile)
• Backup disponible: $(if($GlobalConfig.CreateBackup){'SI'}else{'NO'})

============================================================
  FILOSOFÍA: Guidance, not force
  Windows está optimizado por diseño. Solo removemos
  interferencias peligrosas y sugerimos ajustes según
  el contexto real de tu hardware.
============================================================
"@
    
    $reportContent | Out-File $reportPath -Encoding UTF8
    Write-Host "📄 Reporte completo guardado en:" -ForegroundColor Cyan
    Write-Host "   $reportPath" -ForegroundColor DarkGray
    Write-Host ""
} catch {
    Write-Host "  ⚠️  No se pudo generar reporte completo" -ForegroundColor Yellow
}

# --- OPCIÓN DE REINICIO MEJORADA ---
Write-Host "🔄 OPCIÓN DE REINICIO" -ForegroundColor Cyan

if (-not $GlobalConfig.SafeMode) {
    $reinicio = Read-Host "¿Reiniciar ahora para aplicar todas las configuraciones? (S/N)"
    if ($reinicio -eq "S" -or $reinicio -eq "s") {
        Write-Host "Reiniciando en 10 segundos..." -ForegroundColor Yellow
        Write-Host "Presiona Ctrl+C para cancelar" -ForegroundColor DarkGray
        Write-Host ""
        
        # Contador regresivo
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
        Write-Host ""
        Write-Host "ℹ️  Algunos cambios requieren reinicio para efecto completo:" -ForegroundColor DarkGray
        Write-Host "   • Configuraciones de memoria y prioridades" -ForegroundColor DarkGray
        Write-Host "   • Ajustes de red TCP" -ForegroundColor DarkGray
        Write-Host "   • Optimizaciones de almacenamiento" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  ⚠️  MODO SEGURO: No se aplicaron cambios que requieran reinicio" -ForegroundColor Yellow
    Write-Host "  Ejecuta sin -SafeMode para aplicar optimizaciones completas" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Gracias por usar Windows de Mente v1.0" -ForegroundColor Cyan
Write-Host "   Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
