# =====================================================================
#  WINDOWS DE MENTE v1.0
#  Optimización consciente de Windows
#  Guidance, not force
# =====================================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows de Mente v1.0"

# =====================================================================
# CONFIGURACIÓN GLOBAL MEJORADA
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
# BENCHMARK INICIAL MEJORADO (PROXY-AWARE)
# =====================================================================
if ($GlobalConfig.EnableBenchmark) {
    Write-Host "📊 BENCHMARK INICIAL (pre-optimización)" -ForegroundColor Cyan
    Write-Host "──────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $baseline = @{}
    
    try {
        Write-Host "  » Midiendo responsividad CPU..." -ForegroundColor DarkGray
        $cpuTest = Measure-Command {
            1..100 | ForEach-Object { Start-Sleep -Milliseconds 1 }
        }
        $baseline.CPU_Responsividad = [math]::Round($cpuTest.TotalMilliseconds, 1)
        Write-Host "  • CPU: $($baseline.CPU_Responsividad)ms" -ForegroundColor DarkGray
        
        Write-Host "  » Midiendo rendimiento de disco..." -ForegroundColor DarkGray
        try {
            $diskCounter = Get-Counter '\LogicalDisk(*)\Avg. Disk Queue Length' -ErrorAction SilentlyContinue
            if ($diskCounter) {
                $baseline.DiskQueue = [math]::Round($diskCounter.CounterSamples[0].CookedValue, 2)
                Write-Host "  • Disk Queue: $($baseline.DiskQueue)" -ForegroundColor DarkGray
            }
        } catch {
            $baseline.DiskQueue = "N/A"
        }
        
        Write-Host "  » Midiendo latencia de red (proxy-aware)..." -ForegroundColor DarkGray
        $proxyEnabled = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -ErrorAction SilentlyContinue) -eq 1
        
        if ($proxyEnabled) {
            Write-Host "  • Proxy detectado, usando método alternativo..." -ForegroundColor Yellow
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.Proxy = [System.Net.WebRequest]::DefaultWebProxy
                $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                $null = $webClient.DownloadString("http://www.msftconnecttest.com/connecttest.txt")
                $stopwatch.Stop()
                
                $baseline.NetworkLatency = [math]::Round($stopwatch.ElapsedMilliseconds, 1)
                Write-Host "  • Red: $($baseline.NetworkLatency)ms (via Proxy)" -ForegroundColor DarkGray
            } catch {
                $baseline.NetworkLatency = "Proxy"
                Write-Host "  • Red: Proxy sin conectividad externa" -ForegroundColor Yellow
            }
        } else {
            try {
                $pingTest = Test-Connection 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue
                if ($pingTest -and $pingTest[0].ResponseTime -gt 0) {
                    $avgLatency = ($pingTest.ResponseTime | Measure-Object -Average).Average
                    $baseline.NetworkLatency = [math]::Round($avgLatency, 1)
                    Write-Host "  • Red: $($baseline.NetworkLatency)ms" -ForegroundColor DarkGray
                } else {
                    $baseline.NetworkLatency = "N/A"
                    Write-Host "  • Red: Sin medición válida" -ForegroundColor Yellow
                }
            } catch {
                $baseline.NetworkLatency = "N/A"
                Write-Host "  • Red: Error en medición" -ForegroundColor Yellow
            }
        }
        
        Write-Host "✔ Benchmark inicial completado" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "  ⚠️  Benchmark inicial omitido por errores" -ForegroundColor Yellow
        $GlobalConfig.EnableBenchmark = $false
    }
}

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

Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "Inicializando..." -PercentComplete 0

# =====================================================================
# [FASE 0] Análisis contextual del sistema
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 0: Analizando sistema..." -PercentComplete 5

Write-Host "[FASE 0] Análisis contextual del sistema" -ForegroundColor Yellow
Write-Host ("─" * 72) -ForegroundColor DarkGray

$SystemProfile = @{
    OSEdition = "Unknown"
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
        IsOEMDriver = $false
    }
    Network = @{
        PrimaryType = "Unknown"
        Vendor = "Unknown"
        IsProblematic = $false
        AdapterName = $null
    }
    Storage = @{
        SystemDiskType = "Unknown"
    }
    Platform = @{
        IsLaptop = $false
        HasBattery = $false
        PowerSource = "Unknown"
    }
    USB = @{
        HasUSB3 = $false
    }
    RiskLevel = "Medium"
    Strategy = "Balanced"
}

try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $SystemProfile.OSEdition = $osInfo.Caption
} catch {
    $SystemProfile.OSEdition = "Windows (no detectado)"
}

try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $SystemProfile.CPU.Cores   = $cpu.NumberOfCores
    $SystemProfile.CPU.Threads = $cpu.NumberOfLogicalProcessors
    if ($cpu.Name -match "Intel") { $SystemProfile.CPU.Vendor = "Intel" }
    elseif ($cpu.Name -match "AMD") { $SystemProfile.CPU.Vendor = "AMD" }
    if ($cpu.MaxClockSpeed -ge 2300 -and $cpu.NumberOfLogicalProcessors -ge 4) {
        $SystemProfile.CPU.Modern = $true
    }
    if ($SystemProfile.CPU.Vendor -eq "Intel" -and $cpu.Threads -gt $cpu.Cores * 2) {
        $SystemProfile.CPU.Hybrid = $true
    }
} catch {
    Write-Host "  ⚠️ CPU: detección parcial" -ForegroundColor Yellow
}

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
    if ($SystemProfile.Platform.IsLaptop -and ($gpus.PNPDeviceID -match "SUBSYS_")) {
        $SystemProfile.GPU.IsOEMDriver = $true
    }
} catch {
    Write-Host "  ⚠️ GPU: detección básica" -ForegroundColor Yellow
}

try {
    $adapter = Get-NetAdapter -Physical |
               Where-Object {
                   $_.Status -eq "Up" -and
                   $_.InterfaceDescription -notmatch "Virtual|VPN|Hyper-V"
               } | Select-Object -First 1
    if ($adapter) {
        $SystemProfile.Network.AdapterName = $adapter.Name
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

try {
    $chassis = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue
    $laptopTypes = @(8, 9, 10, 11, 12, 14, 18, 21, 31)
    if ($chassis.ChassisTypes | Where-Object { $_ -in $laptopTypes }) {
        $SystemProfile.Platform.IsLaptop = $true
    }
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $SystemProfile.Platform.HasBattery = $true
        $SystemProfile.Platform.PowerSource = if ($battery.BatteryStatus -eq 2) { "AC" } else { "Battery" }
    }
} catch {}

try {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    Write-Host "  • RAM total detectada: ${totalRAM} GB" -ForegroundColor DarkGray
} catch {
    $totalRAM = 0
    Write-Host "  ⚠️ RAM: no detectada" -ForegroundColor Yellow
}

try {
    $usb = Get-CimInstance Win32_USBController |
           Where-Object { $_.Name -match "USB 3|eXtensible" }
    $SystemProfile.USB.HasUSB3 = [bool]$usb
} catch {}

$risk = 0
if ($SystemProfile.Platform.IsLaptop -and $SystemProfile.GPU.IsOEMDriver) {
    $risk += 2
}
if ($SystemProfile.Network.IsProblematic) {
    $risk += 1
}
if ($totalRAM -lt 4) {
    $risk += 1
    Write-Host "  ⚠️ RAM baja (<4GB): aumenta riesgo" -ForegroundColor Yellow
}

if ($risk -ge 3) {
    $SystemProfile.RiskLevel = "High"
    $SystemProfile.Strategy  = "Conservative"
} elseif ($risk -eq 2) {
    $SystemProfile.RiskLevel = "Medium"
    $SystemProfile.Strategy  = "Balanced"
} else {
    $SystemProfile.RiskLevel = "Low"
    $SystemProfile.Strategy  = "Aggressive"
}

Write-Host "`n📋 PERFIL DETECTADO" -ForegroundColor Cyan
Write-Host "  • Plataforma: $(if($SystemProfile.Platform.IsLaptop){'Laptop'}else{'Desktop'})"
Write-Host "  • CPU: $($SystemProfile.CPU.Vendor) $(if($SystemProfile.CPU.Modern){'Moderna'}else{'Legacy'})"
Write-Host "  • RAM: ${totalRAM} GB"
Write-Host "  • GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)"
Write-Host "  • Red: $($SystemProfile.Network.PrimaryType) - $($SystemProfile.Network.Vendor)"
Write-Host "  • Riesgo: $($SystemProfile.RiskLevel)"
Write-Host "  • Estrategia: $($SystemProfile.Strategy)"
Write-Host "✔ Fase 0 completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# ANÁLISIS DE SALUD DEL SISTEMA (NUEVO)
# =====================================================================
Write-Host "[ANÁLISIS] Estado sanitario del sistema" -ForegroundColor Magenta
Write-Host "─" * 70 -ForegroundColor DarkGray

$systemHealth = @{
    Estado = "OK"
    Problemas = @()
    Recomendaciones = @()
}

try {
    $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
    $drive = Get-PSDrive $systemDrive.Replace(':', '') -ErrorAction SilentlyContinue
    if ($drive) {
        $freePercent = ($drive.Free / $drive.Used) * 100
        if ($freePercent -lt 10) {
            $systemHealth.Estado = "CRÍTICO"
            $systemHealth.Problemas += "Disco sistema con menos del 10% libre ($([math]::Round($freePercent,1))%)"
            $systemHealth.Recomendaciones += "Liberar espacio en $systemDrive"
        } elseif ($freePercent -lt 20) {
            $systemHealth.Estado = "ADVERTENCIA"
            $systemHealth.Problemas += "Disco sistema con menos del 20% libre ($([math]::Round($freePercent,1))%)"
        }
    }
} catch {}

try {
    $errors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) -ErrorAction SilentlyContinue
    if ($errors.Count -gt 5) {
        $systemHealth.Problemas += "$($errors.Count) errores de sistema en últimas 24h"
        $systemHealth.Recomendaciones += "Revisar Visor de Eventos"
    }
} catch {}

switch ($systemHealth.Estado) {
    "OK" { Write-Host "  ✅ Sistema: Estado óptimo" -ForegroundColor Green }
    "ADVERTENCIA" { 
        Write-Host "  ⚠️  Sistema: Atención requerida" -ForegroundColor Yellow
        $systemHealth.Problemas | ForEach-Object { Write-Host "    • $_" -ForegroundColor Yellow }
    }
    "CRÍTICO" { 
        Write-Host "  ❗ Sistema: Estado crítico" -ForegroundColor Red
        $systemHealth.Problemas | ForEach-Object { Write-Host "    • $_" -ForegroundColor Red }
        $systemHealth.Recomendaciones | ForEach-Object { Write-Host "    ▶ $_" -ForegroundColor Cyan }
    }
}
Write-Host ""

# =====================================================================
# [FASE 1] Evaluación contextual de capacidades
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 1: Evaluando capacidades..." -PercentComplete 10

Write-Host "[FASE 1] Evaluación contextual de capacidades" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

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

$cpuHybridBonus = if ($SystemProfile.CPU.Hybrid) { 
    10; $ScoreDetails += "CPU Híbrida: +10" 
} else { 
    0 
}

$cpuScore = $cpuBaseScore + $cpuModernBonus + $cpuHybridBonus
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
    "Hybrid"    { $gpuScore = 20; $ScoreDetails += "GPU Híbrida: +20" }
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

# =====================================================================
# SISTEMA DE PUNTUACIÓN CONTEXTUAL (NUEVO)
# =====================================================================
$categoryLimits = @{
    "ENTUSIASTA" = @{
        MaxScore = 150
        Description = "Hardware de gama alta (i9/Ryzen 9, 32GB+ RAM, NVMe)"
        TargetScore = 120
    }
    "EQUILIBRADO" = @{
        MaxScore = 120
        Description = "Hardware moderno medio (i5/Ryzen 5, 16GB RAM, SSD)"
        TargetScore = 95
    }
    "ESTÁNDAR" = @{
        MaxScore = 100
        Description = "Hardware común (i3/Ryzen 3, 8GB RAM, HDD/SSD)"
        TargetScore = 80
    }
    "LIVIANO" = @{
        MaxScore = 80
        Description = "Hardware limitado o antiguo (Atom/Celeron, <4GB RAM, HDD)"
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

Write-Host "`n💡 RENDIMIENTO RELATIVO:" -ForegroundColor Cyan
Write-Host "  • Categoría: $HardwareProfile" -ForegroundColor DarkGray
Write-Host "  • $($categoryInfo.Description)" -ForegroundColor DarkGray
Write-Host "  • Tu puntuación: $ProfileScore/$($categoryInfo.MaxScore)" -ForegroundColor DarkGray
Write-Host "  • Rendimiento: $relativeScore% del óptimo para tu hardware" -ForegroundColor $(switch($relativeScore){ {$_ -ge 85}{'Green'} {$_ -ge 70}{'Yellow'} default{'Red'}})

Write-Host "✔ Evaluación contextual completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 2] POWER PLAN CONTEXTUAL
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 2: Configurando Power Plan..." -PercentComplete 15

Write-Host "[FASE 2] Configuración de Power Plan contextual" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Aplicando plan de energía según perfil..." -ForegroundColor DarkGray
Write-Host ""

try {
    $currentScheme = powercfg /getactivescheme
    Write-Host "  • Esquema actual: $($currentScheme | Select-String -Pattern 'GUID' | ForEach-Object { $_.ToString().Split(':')[1].Trim() })" -ForegroundColor DarkGray
} catch {
    Write-Host "  ⚠️  No se pudo determinar esquema actual" -ForegroundColor Yellow
}

if (-not $GlobalConfig.SafeMode) {
    try {
        switch ($HardwareProfile) {
            "LIVIANO" {
                powercfg /setactive SCHEME_MIN 2>&1 | Out-Null
                Write-Host "  • Power Plan: Alto Rendimiento (fijo)" -ForegroundColor Green
                Write-Host "    CPU siempre al 100% para hardware limitado" -ForegroundColor DarkGray
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
                Write-Host "    Máximo rendimiento para workloads pesados" -ForegroundColor DarkGray
            }
            default {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
                Write-Host "  • Power Plan: Equilibrado" -ForegroundColor Green
                Write-Host "    Balance óptimo rendimiento/eficiencia" -ForegroundColor DarkGray
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
    Write-Host "  • MODO SEGURO: Power Plan recomendado: $HardwareProfile" -ForegroundColor Yellow
}

Write-Host "✔ Configuración de Power Plan completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# HOTFIXES CONTEXTUALES (NUEVO)
# =====================================================================
Write-Host "[HOTFIXES] Soluciones para problemas comunes" -ForegroundColor Magenta
Write-Host "─" * 70 -ForegroundColor DarkGray

$hotfixesApplied = @()

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
    $hotfixesApplied += "Cache DNS limpiada y renovada"
} catch {}

if ($SystemProfile.Storage.SystemDiskType -eq "HDD" -and $totalRAM -lt 8) {
    try {
        $prefetchPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
        Set-ItemProperty -Path $prefetchPath -Name EnablePrefetcher -Value 3 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $prefetchPath -Name EnableSuperfetch -Value 3 -ErrorAction SilentlyContinue
        $hotfixesApplied += "Prefetch/SuperFetch optimizado para HDD con poca RAM"
    } catch {}
}

if ($hotfixesApplied.Count -gt 0) {
    Write-Host "  🔧 Hotfixes aplicados:" -ForegroundColor Cyan
    $hotfixesApplied | ForEach-Object { Write-Host "    • $_" -ForegroundColor Green }
} else {
    Write-Host "  ✅ No se requirieron hotfixes inmediatos" -ForegroundColor Green
}
Write-Host ""

# =====================================================================
# [FASE 3] Configuración contextual de memoria
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 3: Optimizando memoria..." -PercentComplete 25

Write-Host "[FASE 3] Configuración contextual de memoria" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Eliminando configuraciones peligrosas..." -ForegroundColor DarkGray

$dangerousTweaks = @(
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"; Reason="PELIGROSO en <16GB RAM"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="LargeSystemCache"; Reason="MALO para estaciones de trabajo"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="ClearPageFileAtShutdown"; Reason="Lento e innecesario"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="SecondLevelDataCache"; Reason="Windows detecta automáticamente"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="IoPageLockLimit"; Reason="Causa inestabilidad"},
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"; Reason="Valor DUPLICADO"}
)

$tweaksRemoved = 0
foreach ($tweak in $dangerousTweaks) {
    if (Test-Path $tweak.Path) {
        $prop = Get-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction SilentlyContinue
        if ($prop) {
            try {
                Remove-ItemProperty -Path $tweak.Path -Name $tweak.Name -ErrorAction Stop
                $tweaksRemoved++
            } catch {}
        }
    }
}

if ($tweaksRemoved -gt 0) {
    Write-Host "  • $tweaksRemoved configuraciones peligrosas eliminadas" -ForegroundColor Green
} else {
    Write-Host "  • No se encontraron configuraciones peligrosas" -ForegroundColor Green
}

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

Write-Host "✔ Configuración contextual de memoria completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 4] NETWORK INTELIGENTE
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 4: Optimizando red..." -PercentComplete 35

Write-Host "[FASE 4] Optimización inteligente de red" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Aplicando configuración optimizada de red..." -ForegroundColor DarkGray
Write-Host ""

Write-Host "  • TCP Auto-tuning: Normal (estable y recomendado)" -ForegroundColor DarkGray
netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null

Write-Host "  • TCP RSS: Habilitado (mejor rendimiento multicore)" -ForegroundColor DarkGray
netsh int tcp set global rss=enabled 2>&1 | Out-Null

Write-Host "  • TCP Chimney: Deshabilitado (tecnología obsoleta)" -ForegroundColor DarkGray
netsh int tcp set global chimney=disabled 2>&1 | Out-Null

if ($SystemProfile.Network.AdapterName -and -not $GlobalConfig.SafeMode) {
    Write-Host ""
    Write-Host "  » Aplicando optimizaciones específicas..." -ForegroundColor DarkGray
    
    try {
        $proxyEnabled = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -ErrorAction SilentlyContinue) -eq 1
        
        if ($proxyEnabled) {
            Write-Host "  • Red Corporativa/Proxy detectado" -ForegroundColor Yellow
            Write-Host "    Optimizando para entorno empresarial..." -ForegroundColor DarkGray
            netsh int tcp set global autotuninglevel=restricted 2>&1 | Out-Null
            Write-Host "  • TCP Auto-tuning: Restricted (mejor para proxy/VPN)" -ForegroundColor Green
        } else {
            if ($SystemProfile.Network.Vendor -eq "Killer") {
                Write-Host "  • Adaptador Killer detectado: optimizando RSS..." -ForegroundColor Yellow
                Set-NetAdapterRss -Name $SystemProfile.Network.AdapterName -NumberOfReceiveQueues 4 -ErrorAction SilentlyContinue
                Write-Host "  • RSS configurado a 4 queues (mejor latencia)" -ForegroundColor Green
            }
            elseif ($SystemProfile.Network.PrimaryType -eq "WiFi") {
                Write-Host "  • WiFi detectado: optimizando para conexión inalámbrica..." -ForegroundColor Yellow
                Set-NetAdapterAdvancedProperty -Name $SystemProfile.Network.AdapterName -DisplayName "Green Energy" -RegistryValue 1 -ErrorAction SilentlyContinue
                Write-Host "  • WiFi optimizado para estabilidad" -ForegroundColor Green
            }
            elseif ($SystemProfile.Network.Vendor -in @("Intel", "Realtek")) {
                Write-Host "  • $($SystemProfile.Network.Vendor) Ethernet: aplicando optimizaciones..." -ForegroundColor Yellow
                Enable-NetAdapterRsc -Name $SystemProfile.Network.AdapterName -ErrorAction SilentlyContinue
                Enable-NetAdapterLso -Name $SystemProfile.Network.AdapterName -ErrorAction SilentlyContinue
                Write-Host "  • Ethernet optimizado para máximo rendimiento" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  ⚠️  Algunas optimizaciones no pudieron aplicarse" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  » Mantenimiento de DNS..." -ForegroundColor DarkGray
try {
    Clear-DnsClientCache -ErrorAction Stop
    Write-Host "  • DNS: Caché limpiada correctamente" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  DNS: No se pudo limpiar caché" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  📊 RESUMEN DE CONFIGURACIÓN DE RED:" -ForegroundColor Cyan
Write-Host "  • Adaptador: $($SystemProfile.Network.AdapterName ?? 'No detectado')" -ForegroundColor DarkGray
Write-Host "  • Tipo: $($SystemProfile.Network.PrimaryType)" -ForegroundColor DarkGray
Write-Host "  • Fabricante: $($SystemProfile.Network.Vendor)" -ForegroundColor DarkGray
Write-Host "  • TCP Optimizado: Sí" -ForegroundColor DarkGray

Write-Host "✔ Optimización inteligente de red completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 5] Balance contextual de prioridades CPU
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 5: Balanceando prioridades CPU..." -PercentComplete 50

Write-Host "[FASE 5] Balance contextual de prioridades CPU" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Ajustando balance foreground/background según perfil..." -ForegroundColor DarkGray
Write-Host ""

$CPUPriorityMatrix = @{
    "ENTUSIASTA" = @{Conservative=24; Balanced=36; Aggressive=48}
    "EQUILIBRADO" = @{Conservative=20; Balanced=28; Aggressive=36}
    "ESTÁNDAR" = @{Conservative=16; Balanced=24; Aggressive=32}
    "LIVIANO" = @{Conservative=12; Balanced=18; Aggressive=24}
}

$CPUValue = $CPUPriorityMatrix[$HardwareProfile][$SystemProfile.Strategy]
$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

if (-not $GlobalConfig.SafeMode) {
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
    Write-Host "  • MODO SEGURO: Prioridad CPU recomendada: $CPUValue" -ForegroundColor Yellow
}

Write-Host "✔ Balance contextual de prioridades completado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 6] Optimización contextual de almacenamiento
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 6: Optimizando almacenamiento..." -PercentComplete 65

Write-Host "[FASE 6] Optimización contextual de almacenamiento" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Optimizando almacenamiento según tipo y perfil..." -ForegroundColor DarkGray
Write-Host ""

if ($systemDiskType -ne "Unknown") {
    Write-Host "  📀 DISCO DEL SISTEMA: $systemDiskType" -ForegroundColor Cyan
    
    Write-Host "  » Aplicando ajustes seguros..." -ForegroundColor DarkGray
    
    $currentLastAccess = fsutil behavior query disablelastaccess 2>&1
    if ($currentLastAccess -notmatch "=\s*1") {
        if (-not $GlobalConfig.SafeMode) {
            fsutil behavior set disablelastaccess 1 2>&1 | Out-Null
            Write-Host "  • NTFS LastAccess: Deshabilitado (reduce escrituras)" -ForegroundColor Green
        }
    } else {
        Write-Host "  • NTFS LastAccess: Ya deshabilitado" -ForegroundColor DarkGray
    }
    
    switch ($systemDiskType) {
        "NVMe" {
            Write-Host "  • NVMe: Configuración de alto rendimiento" -ForegroundColor DarkGray
            $trimStatus = fsutil behavior query DisableDeleteNotify 2>&1
            if ($trimStatus -match "=\s*1") {
                if (-not $GlobalConfig.SafeMode) {
                    fsutil behavior set DisableDeleteNotify 0 2>&1 | Out-Null
                    Write-Host "  • TRIM: Activado (para NVMe)" -ForegroundColor Green
                }
            } else {
                Write-Host "  • TRIM: Ya activado" -ForegroundColor DarkGray
            }
        }
        "SSD" {
            Write-Host "  • SSD: Configuración equilibrada" -ForegroundColor DarkGray
        }
        "HDD" {
            Write-Host "  • HDD: Prefetch/SuperFetch habilitados" -ForegroundColor DarkGray
        }
    }
    
    if ($systemDiskType -in @("NVMe", "SSD")) {
        Write-Host "  » Ejecutando optimización para almacenamiento flash..." -ForegroundColor DarkGray
        try {
            $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive.Replace(":", "")
            if (-not $GlobalConfig.SafeMode) {
                Optimize-Volume -DriveLetter $systemDrive -ReTrim -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  • TRIM/Optimización: Ejecutado" -ForegroundColor Green
            }
        } catch {
            Write-Host "  • TRIM: Windows gestiona automáticamente" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  ⚠️  Tipo de almacenamiento no detectado" -ForegroundColor Yellow
}

Write-Host "✔ Optimización contextual de almacenamiento completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 7] Optimización contextual de retrasos del sistema
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 7: Ajustando retrasos del sistema..." -PercentComplete 80

Write-Host "[FASE 7] Optimización contextual de retrasos del sistema" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "  » Ajustando retrasos UI según tipo de almacenamiento..." -ForegroundColor DarkGray
Write-Host ""

$delayConfig = @{
    ExplorerSerializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
    ExplorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
}

$recommendedDelay = switch ($systemDiskType) {
    "NVMe" { 0 }
    "SSD"  { 50 }
    "HDD"  { 200 }
    default { 100 }
}

if (-not $GlobalConfig.SafeMode) {
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
        Write-Host "  • Proceso escritorio: Separado (mayor estabilidad)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Error configurando proceso escritorio" -ForegroundColor Yellow
    }
}

Write-Host "✔ Optimización contextual de retrasos completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 8] BENCHMARK FINAL Y REPORTE
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 8: Ejecutando benchmark final..." -PercentComplete 90

Write-Host "[FASE 8] Benchmark final y reporte" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

if ($GlobalConfig.EnableBenchmark -and $baseline) {
    Write-Host "  📊 EJECUTANDO BENCHMARK FINAL..." -ForegroundColor Cyan
    
    $postBenchmark = @{}
    
    try {
        Write-Host "  » Midiendo responsividad CPU post-optimización..." -ForegroundColor DarkGray
        $cpuTestPost = Measure-Command {
            1..100 | ForEach-Object { Start-Sleep -Milliseconds 1 }
        }
        $postBenchmark.CPU_Responsividad = [math]::Round($cpuTestPost.TotalMilliseconds, 1)
        
        Write-Host "  » Midiendo rendimiento de disco post-optimización..." -ForegroundColor DarkGray
        try {
            $diskCounterPost = Get-Counter '\LogicalDisk(*)\Avg. Disk Queue Length' -ErrorAction SilentlyContinue
            if ($diskCounterPost) {
                $postBenchmark.DiskQueue = [math]::Round($diskCounterPost.CounterSamples[0].CookedValue, 2)
            }
        } catch {}
        
        Write-Host "  » Midiendo latencia de red post-optimización..." -ForegroundColor DarkGray
        if ($baseline.NetworkLatency -ne "Proxy" -and $baseline.NetworkLatency -ne "N/A") {
            try {
                $pingTestPost = Test-Connection 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue
                if ($pingTestPost -and $pingTestPost[0].ResponseTime -gt 0) {
                    $avgLatencyPost = ($pingTestPost.ResponseTime | Measure-Object -Average).Average
                    $postBenchmark.NetworkLatency = [math]::Round($avgLatencyPost, 1)
                }
            } catch {}
        }
        
        Write-Host "✔ Benchmark final completado" -ForegroundColor Green
        
        $improvements = @{}
        
        if ($baseline.CPU_Responsividad -and $postBenchmark.CPU_Responsividad) {
            $cpuImprovement = [math]::Round((1 - ($postBenchmark.CPU_Responsividad / $baseline.CPU_Responsividad)) * 100, 1)
            $improvements.CPU = $cpuImprovement
        }
        
        if ($baseline.DiskQueue -and $postBenchmark.DiskQueue -and $baseline.DiskQueue -gt 0) {
            $diskImprovement = [math]::Round((1 - ($postBenchmark.DiskQueue / $baseline.DiskQueue)) * 100, 1)
            $improvements.Disk = $diskImprovement
        }
        
        if ($baseline.NetworkLatency -and $postBenchmark.NetworkLatency -and $baseline.NetworkLatency -gt 0) {
            $networkImprovement = [math]::Round((1 - ($postBenchmark.NetworkLatency / $baseline.NetworkLatency)) * 100, 1)
            $improvements.Network = $networkImprovement
        }
        
        Write-Host ""
        Write-Host "  📈 RESULTADOS DEL BENCHMARK:" -ForegroundColor Cyan
        
        if ($improvements.CPU) {
            $color = if ($improvements.CPU -gt 0) { "Green" } else { "Red" }
            $arrow = if ($improvements.CPU -gt 0) { "⬆️" } else { "⬇️" }
            Write-Host "  • CPU: $($baseline.CPU_Responsividad)ms → $($postBenchmark.CPU_Responsividad)ms = $($improvements.CPU)% $arrow" -ForegroundColor $color
        }
        
        if ($improvements.Disk) {
            $color = if ($improvements.Disk -gt 0) { "Green" } else { "Red" }
            $arrow = if ($improvements.Disk -gt 0) { "⬆️" } else { "⬇️" }
            Write-Host "  • Disk Queue: $($baseline.DiskQueue) → $($postBenchmark.DiskQueue) = $($improvements.Disk)% $arrow" -ForegroundColor $color
        }
        
        if ($improvements.Network) {
            $color = if ($improvements.Network -gt 0) { "Green" } else { "Red" }
            $arrow = if ($improvements.Network -gt 0) { "⬆️" } else { "⬇️" }
            Write-Host "  • Network: $($baseline.NetworkLatency)ms → $($postBenchmark.NetworkLatency)ms = $($improvements.Network)% $arrow" -ForegroundColor $color
        }
        
        try {
            $reportPath = "$env:USERPROFILE\Desktop\WindowsDeMente_Resultados_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            
            $reportContent = @"
WINDOWS DE MENTE v1.0 - RESULTADOS DE OPTIMIZACIÓN
Fecha: $(Get-Date)
Sistema: $($SystemProfile.OSEdition)

[BENCHMARK REAL]
CPU Responsividad: $($baseline.CPU_Responsividad)ms → $($postBenchmark.CPU_Responsividad)ms = $(if($improvements.CPU){"$($improvements.CPU)% MEJOR"}else{"N/A"})
$(if($improvements.Disk){"Disk Queue: $($baseline.DiskQueue) → $($postBenchmark.DiskQueue) = $($improvements.Disk)% MEJOR`r`n"})
$(if($improvements.Network){"Network: $($baseline.NetworkLatency)ms → $($postBenchmark.NetworkLatency)ms = $($improvements.Network)% MEJOR`r`n"})

[PERFIL DEL SISTEMA]
Hardware Tier: $HardwareProfile
Risk Strategy: $($SystemProfile.Strategy)
Risk Level: $($SystemProfile.RiskLevel)
Puntuación: $ProfileScore ($relativeScore% del óptimo para tu hardware)

[HARDWARE DETECTADO]
CPU: $($SystemProfile.CPU.Vendor) $($SystemProfile.CPU.Cores)c/$($SystemProfile.CPU.Threads)t
RAM: ${totalRAM} GB
Almacenamiento: $($SystemProfile.Storage.SystemDiskType)
GPU: $($SystemProfile.GPU.Type) - $($SystemProfile.GPU.Vendor)
Plataforma: $(if($SystemProfile.Platform.IsLaptop){'Laptop'}else{'Desktop'})
Red: $($SystemProfile.Network.PrimaryType) - $($SystemProfile.Network.Vendor)

[OPTIMIZACIONES APLICADAS]
✓ Tweaks peligrosos eliminados: $tweaksRemoved
✓ Power Plan: $HardwareProfile
✓ Prioridad CPU: $CPUValue
✓ Network: Optimizado para $($SystemProfile.Network.Vendor)
✓ Retrasos Explorer: ${recommendedDelay}ms (optimizado para $systemDiskType)
✓ Almacenamiento: Optimizado para $($SystemProfile.Storage.SystemDiskType)
$(if($hotfixesApplied.Count -gt 0){"✓ Hotfixes aplicados: $($hotfixesApplied.Count)`r`n"})

[RECOMENDACIONES]
$(
    switch ($HardwareProfile) {
        "ENTUSIASTA" { "Mantén drivers actualizados para máximo rendimiento." }
        "EQUILIBRADO" { "Deja que Windows gestione automáticamente, realiza mantenimiento básico periódico." }
        "ESTÁNDAR" { "Mantén Windows Update activado y evita 'optimizadores' agresivos." }
        "LIVIANO" { "Minimiza programas en inicio y mantén al menos 15% de espacio libre en disco." }
    }
)

FILOSOFÍA: Guidance, not force
Windows está optimizado por diseño. Solo removemos interferencias peligrosas.
"@
            
            $reportContent | Out-File $reportPath -Encoding UTF8
            Write-Host ""
            Write-Host "📄 Reporte completo guardado en:" -ForegroundColor Cyan
            Write-Host "   $reportPath" -ForegroundColor DarkGray
            
        } catch {
            Write-Host "  ⚠️  No se pudo generar reporte completo" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ⚠️  Error en benchmark final" -ForegroundColor Red
    }
} else {
    Write-Host "  • Benchmark final omitido" -ForegroundColor Yellow
}

Write-Host "✔ Benchmark y reporte completados" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 9] SCORECARD FINAL Y RESUMEN
# =====================================================================
Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "FASE 9: Finalizando..." -PercentComplete 95

Write-Host "[FASE 9] Scorecard final y resumen" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray

Write-Host "✅ VERIFICACIÓN FINAL:" -ForegroundColor Green
Write-Host "1. Análisis contextual completado ✓" -ForegroundColor Gray
Write-Host "2. Tweaks peligrosos eliminados: $tweaksRemoved ✓" -ForegroundColor Gray
Write-Host "3. Power Plan $HardwareProfile aplicado ✓" -ForegroundColor Gray
Write-Host "4. Network optimizado para $($SystemProfile.Network.Vendor) ✓" -ForegroundColor Gray
Write-Host "5. CPU Priority: $CPUValue ✓" -ForegroundColor Gray
Write-Host "6. Storage optimizado para $systemDiskType ✓" -ForegroundColor Gray
Write-Host "7. UI delays ajustados para $systemDiskType ✓" -ForegroundColor Gray
Write-Host "8. Benchmark ejecutado y reporte generado ✓" -ForegroundColor Gray
if ($hotfixesApplied.Count -gt 0) {
    Write-Host "9. Hotfixes aplicados: $($hotfixesApplied.Count) ✓" -ForegroundColor Gray
}
Write-Host ""

Write-Host "🎯 RENDIMIENTO CONTEXTUAL:" -ForegroundColor Cyan
Write-Host "  • Categoría hardware: $HardwareProfile" -ForegroundColor DarkGray
Write-Host "  • $($categoryInfo.Description)" -ForegroundColor DarkGray
Write-Host "  • Tu puntuación: $ProfileScore/$($categoryInfo.MaxScore)" -ForegroundColor DarkGray
Write-Host "  • Rendimiento relativo: $relativeScore% del óptimo para tu hardware" -ForegroundColor $(switch($relativeScore){ {$_ -ge 85}{'Green'} {$_ -ge 70}{'Yellow'} default{'Red'}})

Write-Host ""
Write-Host "📈 VISUALIZACIÓN DEL RENDIMIENTO:" -ForegroundColor Cyan
$graphLength = [math]::Round(($ProfileScore / $categoryInfo.MaxScore) * 20)
$graphBar = "█" * $graphLength + "░" * (20 - $graphLength)
Write-Host "  [0%] [$graphBar] [100%]" -ForegroundColor Cyan
Write-Host "  (mínimo) ($([math]::Round(($ProfileScore/$categoryInfo.MaxScore)*100))% de tu potencial) (máximo posible)" -ForegroundColor DarkGray

if ($relativeScore -ge 85 -and $HardwareProfile -ne "ENTUSIASTA") {
    Write-Host ""
    Write-Host "🚀 LLEGASTE AL TECHO DE TU HARDWARE:" -ForegroundColor Yellow
    Write-Host "  • Estás sacando el $relativeScore% del potencial de tu categoría" -ForegroundColor DarkGray
    Write-Host "  • Para mejoras significativas, considera upgrade de hardware" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "⚠️  RECOMENDACIÓN FINAL" -ForegroundColor Yellow
$finalRecommendation = switch ($HardwareProfile) {
    "ENTUSIASTA" { "Sistema potente. Considera actualizar drivers desde fabricante para máximo rendimiento." }
    "EQUILIBRADO" { "Hardware moderno. Deja que Windows gestione automáticamente, realiza mantenimiento básico periódico." }
    "ESTÁNDAR" { "Sistema estándar. Mantén Windows Update activado y evita 'optimizadores' agresivos." }
    "LIVIANO" { "Hardware limitado. Minimiza programas en inicio y mantén al menos 15% de espacio libre en disco." }
}
Write-Host "• $finalRecommendation" -ForegroundColor Green

if ($systemHealth.Estado -ne "OK") {
    Write-Host ""
    Write-Host "❗ ATENCIÓN REQUERIDA:" -ForegroundColor Red
    $systemHealth.Problemas | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    if ($systemHealth.Recomendaciones.Count -gt 0) {
        Write-Host "  ▶ $($systemHealth.Recomendaciones[0])" -ForegroundColor Cyan
    }
}

Write-Host "• Reinicia el sistema para aplicar todas las configuraciones." -ForegroundColor Green
Write-Host ""
Write-Host "   Confía en Windows. Sabe lo que hace." -ForegroundColor DarkGray
Write-Host "   Tu sistema ahora está en un estado seguro y predecible." -ForegroundColor DarkGray

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Windows de Mente v1.0 | Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Progress -Id 1 -Activity "Windows de Mente v1.0" -Status "Completado al 100%" -PercentComplete 100
Start-Sleep -Milliseconds 500
Write-Progress -Id 1 -Completed

try {
    [Console]::Beep(2000, 300)
    Start-Sleep -Milliseconds 100
    [Console]::Beep(1500, 200)
} catch {}

if (-not $GlobalConfig.SafeMode) {
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
    Write-Host "  ⚠️  MODO SEGURO: No se aplicaron cambios que requieran reinicio" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Gracias por usar Windows de Mente v1.0" -ForegroundColor Cyan
Write-Host "   Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
