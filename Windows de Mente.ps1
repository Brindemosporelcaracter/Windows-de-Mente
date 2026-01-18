Write-Host ""
Write-Host "=== Windows de Mente ===" -ForegroundColor Cyan
Write-Host "Guidance, not force | Optimización consciente" -ForegroundColor DarkGray
Write-Host ""

# ==========================================================
# BASELINE – ESTADO REAL DEL SISTEMA
# ==========================================================

$CS   = Get-CimInstance Win32_ComputerSystem
$OS   = Get-CimInstance Win32_OperatingSystem

$RAMGB = [math]::Round($CS.TotalPhysicalMemory / 1GB)
$AutoPF = $CS.AutomaticManagedPagefile
$PFUsage = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue

try {
    $DiskType = (Get-PhysicalDisk | Select-Object -First 1).MediaType
} catch {
    $DiskType = "UNKNOWN"
}

$CompactQuery = (compact.exe /compactOS:query) 2>$null
$CompactEnabled = ($CompactQuery -match "estado compacto")

$StartupDelay = (Get-ItemProperty `
 "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
 -Name StartupDelayInMSec -ErrorAction SilentlyContinue).StartupDelayInMSec

$Profile = "LOW"
if ($RAMGB -gt 4) { $Profile = "MID" }
if ($RAMGB -gt 8) { $Profile = "HIGH" }

# ==========================================================
# SNAPSHOT ANTES
# ==========================================================

Write-Host "[Estado detectado]" -ForegroundColor Yellow
Write-Host "RAM instalada: $RAMGB GB"
Write-Host "Perfil estimado: $Profile"
Write-Host "Disco principal: $DiskType"
Write-Host "Pagefile automático: $AutoPF"
if ($PFUsage) {
    Write-Host "Pagefile actual: $($PFUsage.AllocatedBaseSize) MB"
}
Write-Host "Startup delay: $StartupDelay ms"
Write-Host "CompactOS activo: $CompactEnabled"
Write-Host ""

# ==========================================================
# FASE 1 – MEMORIA
# ==========================================================

Write-Host "[1] Memoria del sistema" -ForegroundColor Cyan

$MM = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$BadTweaks = @(
 "DisablePagingExecutive",
 "LargeSystemCache",
 "ClearPageFileAtShutdown",
 "SecondLevelDataCache"
)

foreach ($t in $BadTweaks) {
    Remove-ItemProperty -Path $MM -Name $t -ErrorAction SilentlyContinue
}

Write-Host "Antes:"
Write-Host "• Windows podía usar reglas de memoria forzadas o antiguas"
Write-Host "• Eso suele causar pausas y uso excesivo de disco (swap)"
Write-Host "Ahora:"
Write-Host "• Memoria alineada a políticas soportadas por Microsoft"
Write-Host ""

# ==========================================================
# FASE 2 – CPU / SCHEDULER
# ==========================================================

Write-Host "[2] CPU y prioridad de tareas" -ForegroundColor Cyan

Set-ItemProperty `
 "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
 Win32PrioritySeparation 26

Set-ItemProperty `
 "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
 SystemResponsiveness 10

Write-Host "Antes:"
Write-Host "• CPU repartida de forma pareja entre todo"
Write-Host "Ahora:"
Write-Host "• Aplicaciones activas responden antes bajo carga"
Write-Host ""

# ==========================================================
# FASE 3 – INICIO DE SESIÓN
# ==========================================================

Write-Host "[3] Inicio del sistema" -ForegroundColor Cyan

$Explorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
New-Item -Path $Explorer -Force | Out-Null
Set-ItemProperty -Path $Explorer -Name StartupDelayInMSec -Type DWord -Value 0

Write-Host "Antes:"
Write-Host "• Escritorio visible, pero sistema aún ocupado"
Write-Host "Ahora:"
Write-Host "• Apps listas sin espera artificial"
Write-Host ""

# ==========================================================
# FASE 4 – MEMORIA VIRTUAL (PAGEFILE)
# ==========================================================

Write-Host "[4] Memoria virtual" -ForegroundColor Cyan

$min = 1024; $max = 2048
if ($Profile -eq "MID") { $min=2048; $max=4096 }
if ($Profile -eq "LOW") { $min=4096; $max=8192 }

if ($AutoPF) {
    Set-CimInstance `
     -Query "SELECT * FROM Win32_ComputerSystem" `
     -Property @{ AutomaticManagedPagefile = $false } | Out-Null

    Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue |
     Remove-CimInstance -ErrorAction SilentlyContinue

    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
        Name="C:\pagefile.sys"
        InitialSize=[uint32]$min
        MaximumSize=[uint32]$max
    } | Out-Null
}

Write-Host "Antes:"
Write-Host "• Tamaño de pagefile decidido sin conocer tu RAM"
Write-Host "Ahora:"
Write-Host "• Pagefile fijado en $min–$max MB según tu hardware"
Write-Host ""

# ==========================================================
# FASE 5 – ALMACENAMIENTO
# ==========================================================

Write-Host "[5] Almacenamiento" -ForegroundColor Cyan

if ($DiskType -eq "HDD") {
    fsutil behavior set disablelastaccess 1 | Out-Null

    Write-Host "Antes:"
    Write-Host "• Cada lectura generaba escrituras extra en el disco"
    Write-Host "Ahora:"
    Write-Host "• Menos trabajo mecánico → respuesta más fluida"
} else {
    Write-Host "SSD detectado → no se aplicaron cambios agresivos"
}
Write-Host ""

# ==========================================================
# FASE 6 – COMPACT OS
# ==========================================================

Write-Host "[6] Huella del sistema" -ForegroundColor Cyan

if ($Profile -ne "HIGH" -and -not $CompactEnabled) {
    compact.exe /compactOS:always | Out-Null

    Write-Host "Antes:"
    Write-Host "• Sistema sin compresión"
    Write-Host "Ahora:"
    Write-Host "• Huella reducida (~1–2 GB menos en disco)"
} else {
    Write-Host "CompactOS evaluado → no necesario"
}
Write-Host ""

# ==========================================================
# RESUMEN FINAL – POR FASE
# ==========================================================

Write-Host "=== RESUMEN DE CAMBIOS ===" -ForegroundColor Cyan
Write-Host "[Memoria]  → menos uso de disco cuando falta RAM"
Write-Host "[CPU]      → apps activas responden antes"
Write-Host "[Inicio]   → escritorio listo sin demoras falsas"
Write-Host "[Pagefile] → memoria virtual alineada a tu equipo"
Write-Host "[Disco]    → menos trabajo innecesario"
Write-Host "[Sistema]  → optimizado solo donde tenía sentido"
Write-Host ""

Write-Host "Tu sistema ahora es parte de un Windows de Mente." -ForegroundColor Green
Write-Host "Reinicio recomendado para consolidar los cambios."
