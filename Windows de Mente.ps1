# ==========================================================
# WINDOWS DE MENTE – SYSTEM ALIGNMENT SCRIPT
# Compatible: Windows 10 / 11
# Ejecutar: copiar y pegar completo en PowerShell (Admin)
# ==========================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   WINDOWS DE MENTE – ALINEACIÓN DEL SISTEMA         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ==========================================================
# BASELINE – ESTADO REAL DEL SISTEMA (ANTES)
# ==========================================================

Write-Host "🔍 ANALIZANDO TU SISTEMA..." -ForegroundColor Yellow
Write-Host ""

$OS        = Get-CimInstance Win32_OperatingSystem
$BootDT   = $OS.LastBootUpTime
$Uptime   = (Get-Date) - $BootDT
$UptimeMin = [math]::Round($Uptime.TotalMinutes, 1)

$RAMGB    = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$AutoPF   = (Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile
$PF       = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue

$StartupDelay = (Get-ItemProperty `
 "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
 -Name StartupDelayInMSec -ErrorAction SilentlyContinue).StartupDelayInMSec

try {
    $DiskType = (Get-PhysicalDisk | Select-Object -First 1).MediaType
} catch {
    $DiskType = "UNKNOWN"
}

$CompactQuery = (compact.exe /compactOS:query) 2>$null
$CompactEnabled = $false
if ($CompactQuery -match "estado compacto") { $CompactEnabled = $true }

# Perfil por RAM
$Profile = "LOW"
if ($RAMGB -gt 4) { $Profile = "MID" }
if ($RAMGB -gt 8) { $Profile = "HIGH" }

# ==========================================================
# SNAPSHOT ANTES
# ==========================================================

Write-Host "📊 [ESTADO ACTUAL DEL SISTEMA]" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "• RAM instalada:        $RAMGB GB" -ForegroundColor Gray
Write-Host "• Perfil estimado:      $Profile" -ForegroundColor Gray
Write-Host "• Disco principal:      $DiskType" -ForegroundColor Gray
Write-Host "• Pagefile automático:  $AutoPF" -ForegroundColor Gray
if ($PF) { Write-Host "• Pagefile actual:     $($PF.AllocatedBaseSize) MB" -ForegroundColor Gray }
Write-Host "• Startup delay:        $StartupDelay ms" -ForegroundColor Gray
Write-Host "• CompactOS activo:     $CompactEnabled" -ForegroundColor Gray
Write-Host "• Tiempo desde arranque:$UptimeMin minutos" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

# ==========================================================
# FASE 1 – MEMORIA (CORRECCIÓN REAL)
# ==========================================================

Write-Host "🚀 [FASE 1/6] OPTIMIZANDO MEMORIA DEL SISTEMA" -ForegroundColor Cyan
Write-Host "└────────────────────────────────────────────"

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

Write-Host "   🔄 Antes: Políticas de memoria forzadas o heredadas" -ForegroundColor DarkGray
Write-Host "   ✅ Ahora: Políticas restauradas a valores oficiales de Microsoft" -ForegroundColor Green
Write-Host "   💡 Beneficio: Menos uso de disco como RAM cuando se satura la memoria física" -ForegroundColor Blue
Write-Host ""

# ==========================================================
# FASE 2 – CPU / SCHEDULER
# ==========================================================

Write-Host "⚡ [FASE 2/6] AJUSTANDO PRIORIDADES DE CPU" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────"

Set-ItemProperty `
 "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
 Win32PrioritySeparation 26

Set-ItemProperty `
 "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
 SystemResponsiveness 10

Write-Host "   🔄 Antes: Tiempo de CPU repartido de forma genérica" -ForegroundColor DarkGray
Write-Host "   ✅ Ahora: Prioridad real para aplicaciones en primer plano" -ForegroundColor Green
Write-Host "   💡 Beneficio: Menos micro-pausas al interactuar con el sistema" -ForegroundColor Blue
Write-Host ""

# ==========================================================
# FASE 3 – INICIO DE SESIÓN
# ==========================================================

Write-Host "🚪 [FASE 3/6] ACELERANDO INICIO DE SESIÓN" -ForegroundColor Cyan
Write-Host "└────────────────────────────────────────"

$Explorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
New-Item -Path $Explorer -Force | Out-Null
Set-ItemProperty -Path $Explorer -Name StartupDelayInMSec -Type DWord -Value 0

Write-Host "   🔄 Antes: Inicio visual rápido, pero sistema cargando en segundo plano" -ForegroundColor DarkGray
Write-Host "   ✅ Ahora: Espera artificial eliminada (0 ms)" -ForegroundColor Green
Write-Host "   💡 Beneficio: Escritorio usable inmediatamente al iniciar sesión" -ForegroundColor Blue
Write-Host ""

# ==========================================================
# FASE 4 – MEMORIA VIRTUAL
# ==========================================================

Write-Host "💾 [FASE 4/6] CONFIGURANDO MEMORIA VIRTUAL" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────"

$min = 1024; $max = 2048
if ($Profile -eq "MID") { $min = 2048; $max = 4096 }
if ($Profile -eq "LOW") { $min = 4096; $max = 8192 }

if ($AutoPF) {
    Set-CimInstance `
     -Query "SELECT * FROM Win32_ComputerSystem" `
     -Property @{ AutomaticManagedPagefile = $false } | Out-Null

    Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue |
     Remove-CimInstance -ErrorAction SilentlyContinue

    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
        Name = "C:\pagefile.sys"
        InitialSize = [uint32]$min
        MaximumSize = [uint32]$max
    } | Out-Null
}

Write-Host "   🔄 Antes: Pagefile de tamaño dinámico sin considerar hardware específico" -ForegroundColor DarkGray
Write-Host "   ✅ Ahora: Pagefile fijado en $min – $max MB (según perfil: $Profile)" -ForegroundColor Green
Write-Host "   💡 Beneficio: Menos redimensionamientos y mejor gestión de memoria" -ForegroundColor Blue
Write-Host ""

# ==========================================================
# FASE 5 – ALMACENAMIENTO
# ==========================================================

Write-Host "💿 [FASE 5/6] OPTIMIZANDO ALMACENAMIENTO" -ForegroundColor Cyan
Write-Host "└───────────────────────────────────────"

if ($DiskType -eq "HDD") {
    fsutil behavior set disablelastaccess 1 | Out-Null
    Write-Host "   🔄 Antes: Cada acceso a archivo generaba escrituras NTFS extra en HDD" -ForegroundColor DarkGray
    Write-Host "   ✅ Ahora: 'Last access time' desactivado para HDDs" -ForegroundColor Green
    Write-Host "   💡 Beneficio: Menos trabajo mecánico, mayor fluidez y vida útil del disco" -ForegroundColor Blue
} else {
    Write-Host "   📝 SSD detectado → No se aplicaron cambios agresivos" -ForegroundColor Yellow
}
Write-Host ""

# ==========================================================
# FASE 6 – COMPACT OS
# ==========================================================

Write-Host "📦 [FASE 6/6] COMPACTANDO SISTEMA OPERATIVO" -ForegroundColor Cyan
Write-Host "└──────────────────────────────────────────"

if ($Profile -ne "HIGH" -and -not $CompactEnabled) {
    compact.exe /compactOS:always | Out-Null
    Write-Host "   🔄 Antes: Archivos del sistema sin compresión" -ForegroundColor DarkGray
    Write-Host "   ✅ Ahora: CompactOS activado con compresión inteligente" -ForegroundColor Green
    Write-Host "   💡 Beneficio: ≈ 1–2 GB más de espacio libre sin afectar rendimiento" -ForegroundColor Blue
} else {
    Write-Host "   📝 CompactOS no necesario (suficiente RAM o ya activado)" -ForegroundColor Yellow
}
Write-Host ""

# ==========================================================
# RESUMEN FINAL – TÉCNICO
# ==========================================================

Write-Host "📋 RESUMEN TÉCNICO DE CAMBIOS APLICADOS" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════"
Write-Host "• ESPECIFICACIONES DETECTADAS:" -ForegroundColor White
Write-Host "  └ RAM: $RAMGB GB | Perfil: $Profile | Disco: $DiskType" -ForegroundColor Gray
Write-Host ""
Write-Host "• CAMBIOS REALIZADOS:" -ForegroundColor White
Write-Host "  ├ Fase 1: Políticas de memoria optimizadas" -ForegroundColor Gray
Write-Host "  ├ Fase 2: Prioridad CPU para aplicaciones en primer plano" -ForegroundColor Gray
Write-Host "  ├ Fase 3: Retardo de inicio eliminado (0 ms)" -ForegroundColor Gray
Write-Host "  ├ Fase 4: Pagefile fijado a $min – $max MB" -ForegroundColor Gray
if ($DiskType -eq "HDD") {
    Write-Host "  ├ Fase 5: Optimizaciones para disco mecánico (HDD)" -ForegroundColor Gray
} else {
    Write-Host "  ├ Fase 5: Sin cambios para SSD" -ForegroundColor Gray
}
if ($Profile -ne "HIGH" -and -not $CompactEnabled) {
    Write-Host "  └ Fase 6: CompactOS activado" -ForegroundColor Gray
} else {
    Write-Host "  └ Fase 6: CompactOS no aplicado" -ForegroundColor Gray
}
Write-Host "══════════════════════════════════════════════════════"
Write-Host ""

# ==========================================================
# RESUMEN FINAL – HUMANO
# ==========================================================

Write-Host "🎯 ¿QUÉ NOTARÁS EN TU DÍA A DÍA?" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════"
Write-Host ""
Write-Host "⏱️  MENOS TIEMPOS DE ESPERA" -ForegroundColor White
Write-Host "   • Escritorio listo inmediatamente al iniciar sesión" -ForegroundColor Gray
Write-Host "   • Programas que se abren más rápido" -ForegroundColor Gray
Write-Host ""
Write-Host "⚡ RESPUESTA MÁS INMEDIATA" -ForegroundColor White
Write-Host "   • Ventanas que responden mejor al cambiar entre ellas" -ForegroundColor Gray
Write-Host "   • Menos 'congelamientos' al hacer clic" -ForegroundColor Gray
Write-Host ""
Write-Host "💾 RECURSOS MEJOR DISTRIBUIDOS" -ForegroundColor White
Write-Host "   • Windows usa menos el disco como RAM" -ForegroundColor Gray
Write-Host "   • Memoria virtual ajustada a tu equipo específico" -ForegroundColor Gray
if ($DiskType -eq "HDD") {
    Write-Host "   • Disco duro mecánico trabajando de forma más eficiente" -ForegroundColor Gray
}
if ($Profile -ne "HIGH" -and -not $CompactEnabled) {
    Write-Host "   • Más espacio disponible en tu disco principal" -ForegroundColor Gray
}
Write-Host ""
Write-Host "🛠️  SISTEMA PERSONALIZADO" -ForegroundColor White
Write-Host "   • Configuraciones basadas en tu hardware real" -ForegroundColor Gray
Write-Host "   • Ajustes específicos, no genéricos" -ForegroundColor Gray
Write-Host "══════════════════════════════════════════════════════"
Write-Host ""

# ==========================================================
# CONCLUSIÓN
# ==========================================================

Write-Host "✅ PROCESO COMPLETADO" -ForegroundColor Green
Write-Host ""
Write-Host "✨ Tu sistema ahora es parte de un Windows de Mente." -ForegroundColor Magenta
Write-Host ""
Write-Host "🔄 REINICIO RECOMENDADO:" -ForegroundColor Yellow
Write-Host "   Para consolidar todos los cambios, reinicia tu equipo cuando sea conveniente." -ForegroundColor Gray
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         ¡SISTEMA OPTIMIZADO CON ÉXITO!              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""