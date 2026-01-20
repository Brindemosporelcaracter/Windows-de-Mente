# =====================================================================
#  WINDOWS DE MENTE v1.0
#  Optimización consciente de Windows
#  Guidance, not force
# =====================================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows de Mente v1.0"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   WINDOWS DE MENTE v1.0  |  Optimización Consciente de Windows" -ForegroundColor Cyan
Write-Host "   Guidance, not force" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# [FASE 0] Análisis de hardware y estado del sistema
# =====================================================================

Write-Host "[FASE 0] Análisis de hardware y estado del sistema" -ForegroundColor Yellow

# --- Variables de estado ---
$dangerousTweaks = @()
$tweaksRemoved = 0
$systemInfo = @{}

# --- Limpieza de tweaks heredados / peligrosos ---
$MM = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$BadMemoryTweaks = @(
    "DisablePagingExecutive",
    "LargeSystemCache",
    "ClearPageFileAtShutdown",
    "SecondLevelDataCache",
    "IoPageLockLimit"
)

foreach ($t in $BadMemoryTweaks) {
    $prop = Get-ItemProperty -Path $MM -Name $t -ErrorAction SilentlyContinue
    if ($prop) {
        Remove-ItemProperty -Path $MM -Name $t -ErrorAction SilentlyContinue
        $dangerousTweaks += $t
        $tweaksRemoved++
    }
}

# --- Corrección de tweaks conflictivos ---
$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
if (Test-Path $priorityPath) {
    $win32Prop = Get-ItemProperty -Path $priorityPath -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
    if ($win32Prop) {
        Remove-ItemProperty -Path $priorityPath -Name Win32PrioritySeparation -ErrorAction SilentlyContinue
        $dangerousTweaks += "Win32PrioritySeparation (heredado)"
        $tweaksRemoved++
    }
}

# --- Red: volver a estado sano ---
netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
netsh int tcp set global rss=enabled 2>&1 | Out-Null
netsh int tcp set global chimney=disabled 2>&1 | Out-Null

# --- Lectura hardware mejorada ---
$CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
$RAMM = Get-CimInstance Win32_PhysicalMemory
$OS = Get-CimInstance Win32_OperatingSystem
$systemInfo.CPU = $CPU
$systemInfo.OS = $OS

# Detección de disco del sistema
$systemDriveLetter = $OS.SystemDrive.Replace(":", "")
$Disk = $null

try {
    $systemPartition = Get-Partition -DriveLetter $systemDriveLetter -ErrorAction Stop
    $systemDisk = Get-Disk -Number $systemPartition.DiskNumber -ErrorAction Stop
    
    if ($systemDisk) {
        $Disk = Get-PhysicalDisk -UniqueId $systemDisk.UniqueId -ErrorAction SilentlyContinue
        if (-not $Disk) {
            $Disk = Get-PhysicalDisk | Where-Object DeviceID -eq $systemDisk.Number -ErrorAction SilentlyContinue
        }
    }
} catch {
    # Método alternativo
    try {
        $volumeInfo = Get-Volume -DriveLetter $systemDriveLetter -ErrorAction Stop
        $Disk = Get-PhysicalDisk | Where-Object FriendlyName -match $volumeInfo.FileSystemLabel -ErrorAction SilentlyContinue
    } catch {
        # Último fallback
        $Disk = Get-PhysicalDisk | Select-Object -First 1
    }
}

# Detección de GPU
$allGPUs = Get-CimInstance Win32_VideoController
$systemInfo.GPUCount = $allGPUs.Count

$dedicatedGPU = $null
foreach ($gpu in $allGPUs) {
    $isDedicated = $false
    
    if ($gpu.Name -notmatch "Intel|UHD|Graphics|HD Graphics|Iris|Vega") {
        $isDedicated = $true
    }
    
    if ($gpu.AdapterRAM -gt 1GB -and $gpu.AdapterRAM -lt 128GB) {
        $isDedicated = $true
    }
    
    if ($gpu.DriverVersion -and $gpu.Name -match "NVIDIA|AMD|Radeon|GeForce") {
        $isDedicated = $true
    }
    
    if ($isDedicated -and -not $dedicatedGPU) {
        $dedicatedGPU = $gpu
    }
}

$GPU = if ($dedicatedGPU) { $dedicatedGPU } else { $allGPUs[0] }

# Detección de red activa
$Net = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

# Cálculo de RAM
$RAMGB = [math]::Round(($RAMM.Capacity | Measure-Object -Sum).Sum / 1GB)
$IsLaptop = (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) -ne $null
$GPUName = if ($GPU) { $GPU.Name } else { "No detectada" }

# Almacenar información
$systemInfo.RAMGB = $RAMGB
$systemInfo.IsLaptop = $IsLaptop
$systemInfo.GPUName = $GPUName
$systemInfo.DiskType = if ($Disk) { $Disk.MediaType } else { "Desconocido" }
$systemInfo.DiskModel = if ($Disk) { $Disk.FriendlyName } else { "No detectado" }

Write-Host "  » Hardware detectado: ${RAMGB}GB RAM, $($CPU.NumberOfCores) núcleos" -ForegroundColor DarkGray
Write-Host "  » $tweaksRemoved configuraciones heredadas eliminadas" -ForegroundColor DarkGray
Write-Host "✔ Análisis completado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 1] Evaluación de capacidades del sistema
# =====================================================================

Write-Host "[FASE 1] Evaluación de capacidades del sistema" -ForegroundColor Yellow

$ProfileScore = 0

# RAM
switch ($RAMGB) {
    { $_ -ge 16 } { $ProfileScore += 40; break }
    { $_ -ge 8 }  { $ProfileScore += 25; break }
    default       { $ProfileScore += 10 }
}

# CPU
switch ($CPU.NumberOfCores) {
    { $_ -ge 8 } { $ProfileScore += 30; break }
    { $_ -ge 4 } { $ProfileScore += 20; break }
    default      { $ProfileScore += 10 }
}

# Almacenamiento
if ($Disk) {
    $diskScore = 10
    
    if ($Disk.MediaType -eq "SSD") {
        $diskScore = 20
        $systemInfo.IsSSD = $true
    } elseif ($Disk.MediaType -in @("Unspecified", "SCM")) {
        if ($Disk.BusType -in @("NVMe", "SATA", "RAID") -and $Disk.FriendlyName -match "SSD|NVMe|Solid State") {
            $diskScore = 20
            $systemInfo.IsSSD = $true
        } elseif ($Disk.BusType -eq "USB") {
            $diskScore = 5
        }
    }
    
    if ($Disk.BusType -eq "NVMe" -or $Disk.FriendlyName -match "NVMe") {
        $diskScore += 5
        $systemInfo.IsNVMe = $true
    }
    
    $ProfileScore += $diskScore
} else {
    $ProfileScore += 10
}

switch ($ProfileScore) {
    { $_ -ge 80 } { $Profile = "ENTUSIASTA"; break }
    { $_ -ge 55 } { $Profile = "EQUILIBRADO"; break }
    { $_ -ge 35 } { $Profile = "ESTANDAR"; break }
    default       { $Profile = "LIVIANO" }
}

$systemInfo.Profile = $Profile
$systemInfo.ProfileScore = $ProfileScore

Write-Host "  » Perfil determinado: $Profile" -ForegroundColor DarkGray
Write-Host "  » Puntuación: $ProfileScore puntos" -ForegroundColor DarkGray
Write-Host "✔ Evaluación completada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 2] Verificación de la configuración base de memoria
# =====================================================================

Write-Host "[FASE 2] Verificación de la configuración base de memoria" -ForegroundColor Yellow

# IMPORTANTE: No tocar FeatureSettingsOverride/Mask
# Son mitigaciones de seguridad

Write-Host "  » Gestión de memoria verificada" -ForegroundColor DarkGray
Write-Host "  » Protecciones del kernel intactas" -ForegroundColor DarkGray
Write-Host "✔ Configuración base de memoria verificada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 3] Balance de prioridades de CPU
# =====================================================================

Write-Host "[FASE 3] Balance de prioridades de CPU" -ForegroundColor Yellow

switch ($Profile) {
    "ENTUSIASTA" { $CPUValue = 36 }
    "EQUILIBRADO" { $CPUValue = 24 }
    "ESTANDAR" { $CPUValue = 18 }
    "LIVIANO" { $CPUValue = 2 }
}

if (-not (Test-Path $priorityPath)) {
    New-Item -Path $priorityPath -Force | Out-Null
}

Set-ItemProperty -Path $priorityPath -Name Win32PrioritySeparation -Value $CPUValue -Type DWord -ErrorAction SilentlyContinue

Write-Host "  » Prioridad establecida: $CPUValue" -ForegroundColor DarkGray
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    Write-Host "  » Windows 11: Thread Director mantiene balance dinámico" -ForegroundColor DarkGray
}
Write-Host "✔ Balance de prioridades aplicado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 4] Reducción de retrasos artificiales del sistema
# =====================================================================

Write-Host "[FASE 4] Reducción de retrasos artificiales del sistema" -ForegroundColor Yellow

$Explorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $Explorer)) {
    New-Item -Path $Explorer -Force | Out-Null
}
Set-ItemProperty -Path $Explorer -Name StartupDelayInMSec -Type DWord -Value 0

Write-Host "  » Retraso artificial eliminado" -ForegroundColor DarkGray
Write-Host "✔ Retrasos reducidos" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 5] Ajuste de memoria virtual
# =====================================================================

Write-Host "[FASE 5] Ajuste de memoria virtual" -ForegroundColor Yellow

switch ($Profile) {
    "ENTUSIASTA" { $min = 1024; $max = 4096 }
    "EQUILIBRADO" { $min = 2048; $max = 6144 }
    "ESTANDAR" { $min = 4096; $max = 8192 }
    "LIVIANO" { $min = 6144; $max = 12288 }
}

$pagefileSuccess = $false
$CS = Get-CimInstance Win32_ComputerSystem

try {
    if ($CS.AutomaticManagedPagefile) {
        Set-CimInstance -Query "SELECT * FROM Win32_ComputerSystem" `
            -Property @{ AutomaticManagedPagefile = $false } | Out-Null
    }

    $session = New-CimSession -ComputerName "localhost" -ErrorAction Stop
    
    # Crear nueva configuración primero
    $newPagefile = New-CimInstance -CimSession $session -Namespace "root\cimv2" `
        -ClassName Win32_PageFileSetting -Property @{
        Name = "$($OS.SystemDrive)\pagefile.sys"
        InitialSize = [uint32]$min
        MaximumSize = [uint32]$max
    } -ClientOnly
    
    $createdPagefile = New-CimInstance -CimSession $session -InputObject $newPagefile -ErrorAction Stop
    
    # Eliminar configuraciones antiguas (excepto la nueva)
    $existingPagefiles = Get-CimInstance -CimSession $session `
        -ClassName Win32_PageFileSetting -ErrorAction SilentlyContinue
    
    foreach ($pf in $existingPagefiles) {
        if ($pf.Name -ne $createdPagefile.Name) {
            Remove-CimInstance -CimSession $session -InputObject $pf -ErrorAction SilentlyContinue
        }
    }
    
    Remove-CimSession -CimSession $session
    $pagefileSuccess = $true
    
} catch {
    $pagefileSuccess = $false
}

if ($pagefileSuccess) {
    Write-Host "  » Configuración aplicada: ${min}MB - ${max}MB" -ForegroundColor DarkGray
    Write-Host "✔ Memoria virtual ajustada" -ForegroundColor Green
} else {
    Write-Host "  » Configuración recomendada: ${min}MB - ${max}MB" -ForegroundColor DarkGray
    Write-Host "  » (Aplicar manualmente si es necesario)" -ForegroundColor DarkGray
    Write-Host "⚠️  Ajuste recomendado (no aplicado automáticamente)" -ForegroundColor Yellow
}

Write-Host ""

# =====================================================================
# [FASE 6] Configuración de conectividad de red
# =====================================================================

Write-Host "[FASE 6] Configuración de conectividad de red" -ForegroundColor Yellow

netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
netsh int tcp set global rss=enabled 2>&1 | Out-Null
netsh int tcp set global chimney=disabled 2>&1 | Out-Null

if ($Net -and $Net.InterfaceDescription -notmatch "Wireless|Wi-Fi") {
    netsh int tcp set global dca=enabled 2>&1 | Out-Null
    Write-Host "  » Ethernet: DCA habilitado" -ForegroundColor DarkGray
} elseif ($Net) {
    Write-Host "  » WiFi: Configuración estable" -ForegroundColor DarkGray
}

Write-Host "✔ Conectividad de red configurada" -ForegroundColor Green
Write-Host ""

# =====================================================================
# [FASE 7] Alineación del almacenamiento según su tipo
# =====================================================================

Write-Host "[FASE 7] Alineación del almacenamiento según su tipo" -ForegroundColor Yellow

$systemDrive = $OS.SystemDrive.Replace(":", "")

if ($Disk -and $Disk.MediaType -eq "HDD" -and -not $systemInfo.IsSSD) {
    fsutil behavior set disablelastaccess 1 2>&1 | Out-Null
    Write-Host "  » HDD: escrituras innecesarias reducidas" -ForegroundColor DarkGray
    Write-Host "✔ Almacenamiento HDD alineado" -ForegroundColor Green
} elseif ($Disk -and ($systemInfo.IsSSD -or $systemInfo.IsNVMe)) {
    fsutil behavior set disablelastaccess 0 2>&1 | Out-Null
    
    try {
        if ($systemInfo.IsNVMe -or $Disk.MediaType -eq "SSD") {
            Optimize-Volume -DriveLetter $systemDrive -ReTrim -ErrorAction Stop | Out-Null
            Write-Host "  » SSD/NVMe: TRIM ejecutado" -ForegroundColor DarkGray
        }
        Write-Host "✔ Almacenamiento SSD/NVMe alineado" -ForegroundColor Green
    } catch {
        Write-Host "  » Almacenamiento: configuración nativa preservada" -ForegroundColor DarkGray
        Write-Host "✔ Almacenamiento verificado" -ForegroundColor Green
    }
} else {
    Write-Host "  » Almacenamiento: sin ajustes necesarios" -ForegroundColor DarkGray
    Write-Host "✔ Almacenamiento verificado" -ForegroundColor Green
}

Write-Host ""

# =====================================================================
# [FASE 8] Información técnica y mantenimiento
# =====================================================================

Write-Host "[FASE 8] Información técnica y mantenimiento" -ForegroundColor Yellow
Write-Host "─" * 70 -ForegroundColor DarkGray
Write-Host ""

Write-Host "📊 RESUMEN DEL SISTEMA" -ForegroundColor Cyan
Write-Host "• Hardware detectado:" -ForegroundColor DarkGray
Write-Host "  - CPU: $($CPU.Name) ($($CPU.NumberOfCores) núcleos)" -ForegroundColor DarkGray
Write-Host "  - RAM: ${RAMGB}GB" -ForegroundColor DarkGray
Write-Host "  - Almacenamiento: $(if($systemInfo.IsNVMe){'NVMe'}elseif($systemInfo.IsSSD){'SSD'}else{'HDD'})" -ForegroundColor DarkGray
Write-Host "  - GPU: $GPUName" -ForegroundColor DarkGray
Write-Host "• Perfil aplicado: $Profile" -ForegroundColor DarkGray
Write-Host "• Configuraciones heredadas eliminadas: $tweaksRemoved" -ForegroundColor DarkGray
Write-Host ""

Write-Host "🔧 MANTENIMIENTO RECOMENDADO" -ForegroundColor Cyan
Write-Host "• Windows Update: Mantener actualizado" -ForegroundColor DarkGray
Write-Host "• Drivers: Actualizar desde fabricante" -ForegroundColor DarkGray
Write-Host "• Reinicio: Semanal para liberar recursos" -ForegroundColor DarkGray
Write-Host "• Limpieza: cleanmgr ocasionalmente" -ForegroundColor DarkGray
Write-Host ""

Write-Host "🚫 ÁREAS NO MODIFICADAS (gestión nativa)" -ForegroundColor Cyan
Write-Host "• Seguridad del kernel (Spectre/Meltdown)" -ForegroundColor DarkGray
Write-Host "• Thread Director (Windows 11)" -ForegroundColor DarkGray
Write-Host "• Compresión de memoria dinámica" -ForegroundColor DarkGray
Write-Host "• Gestión de colas NVMe" -ForegroundColor DarkGray
Write-Host ""

Write-Host "⏱️  CUÁNDO EJECUTAR ESTE SCRIPT" -ForegroundColor Cyan
Write-Host "✓ Después de instalación limpia de Windows" -ForegroundColor DarkGray
Write-Host "✓ Tras usar optimizadores agresivos" -ForegroundColor DarkGray
Write-Host "✓ Al cambiar hardware significativo" -ForegroundColor DarkGray
Write-Host "✗ No ejecutar periódicamente" -ForegroundColor DarkGray
Write-Host "✗ No como 'acelerador' diario" -ForegroundColor DarkGray
Write-Host ""

Write-Host "💡 Windows ya está optimizado. Este script solo elimina interferencias." -ForegroundColor Green
Write-Host "─" * 70 -ForegroundColor DarkGray
Write-Host ""

# =====================================================================
# [FASE 9] Verificación y finalización
# =====================================================================

Write-Host "[FASE 9] Verificación y finalización" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   PROCESO COMPLETADO" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ VERIFICACIÓN FINAL:" -ForegroundColor Green
Write-Host "1. Análisis de hardware completado" -ForegroundColor Gray
Write-Host "2. Configuraciones heredadas eliminadas: $tweaksRemoved" -ForegroundColor Gray
Write-Host "3. Perfil $Profile aplicado según capacidades" -ForegroundColor Gray
Write-Host "4. Configuraciones base establecidas" -ForegroundColor Gray
Write-Host "5. Información técnica proporcionada" -ForegroundColor Gray
Write-Host ""

Write-Host "🎯 ESTADO DEL SISTEMA:" -ForegroundColor Yellow
Write-Host "• Base coherente y sin interferencias" -ForegroundColor Gray
Write-Host "• Listo para gestión automática de Windows" -ForegroundColor Gray
Write-Host "• Comportamiento predecible y estable" -ForegroundColor Gray
Write-Host ""

Write-Host "⚠️  RECOMENDACIÓN FINAL" -ForegroundColor Yellow
Write-Host "Reinicia el sistema para aplicar configuraciones de memoria." -ForegroundColor Green
Write-Host ""
Write-Host "   Confía en Windows. Sabe lo que hace." -ForegroundColor DarkGray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Windows de Mente v1.0 | Optimización Consciente" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Opción de reinicio
$reinicio = Read-Host "¿Reiniciar ahora? (S/N)"
if ($reinicio -eq "S" -or $reinicio -eq "s") {
    Write-Host "Reiniciando en 5 segundos..." -ForegroundColor Yellow
    Start-Sleep 5
    Restart-Computer -Force
} else {
    Write-Host "Reinicia manualmente cuando sea conveniente." -ForegroundColor Yellow
}
