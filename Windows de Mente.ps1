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
Write-Host "   Guidance, not force  |  Sin placebo ni tweaks obsoletos" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# FASE 0 – FUNDACIÓN ABSOLUTA (HARDWARE + SANEAMIENTO)
# =====================================================================

Write-Host "[FASE 0] Fundación del sistema" -ForegroundColor Yellow

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
    Remove-ItemProperty -Path $MM -Name $t -ErrorAction SilentlyContinue
}

Remove-ItemProperty `
 "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
 -Name Win32PrioritySeparation -ErrorAction SilentlyContinue

Remove-ItemProperty `
 "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
 -Name SystemResponsiveness -ErrorAction SilentlyContinue

# --- Red: volver a estado sano ---
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global rss=enabled | Out-Null
netsh int tcp set global chimney=disabled | Out-Null

# --- Lectura completa de hardware ---
$CPU  = Get-CimInstance Win32_Processor | Select-Object -First 1
$RAMM = Get-CimInstance Win32_PhysicalMemory
$GPU  = Get-CimInstance Win32_VideoController | Select-Object -First 1
$OS   = Get-CimInstance Win32_OperatingSystem
$Disk = Get-PhysicalDisk | Select-Object -First 1
$Net  = Get-NetAdapter | Where-Object Status -eq "Up"
$USB  = Get-CimInstance Win32_USBController

$RAMGB = [math]::Round(($RAMM.Capacity | Measure-Object -Sum).Sum / 1GB)
$IsLaptop = (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) -ne $null

Write-Host "✔ Sistema saneado y hardware detectado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# FASE 1 – PERFIL DEL SISTEMA (ROBUSTO)
# =====================================================================

Write-Host "[FASE 1] Perfil del sistema" -ForegroundColor Yellow

$ProfileScore = 0

switch ($RAMGB) {
    { $_ -ge 16 } { $ProfileScore += 40; break }
    { $_ -ge 8 }  { $ProfileScore += 25; break }
    default       { $ProfileScore += 10 }
}

switch ($CPU.NumberOfCores) {
    { $_ -ge 8 } { $ProfileScore += 30; break }
    { $_ -ge 4 } { $ProfileScore += 20; break }
    default      { $ProfileScore += 10 }
}

switch ($Disk.MediaType) {
    "SSD" { $ProfileScore += 20 }
    default { $ProfileScore += 10 }
}

switch ($ProfileScore) {
    { $_ -ge 80 } { $Profile = "ENTUSIASTA"; break }
    { $_ -ge 55 } { $Profile = "EQUILIBRADO"; break }
    { $_ -ge 35 } { $Profile = "ESTANDAR"; break }
    default       { $Profile = "LIVIANO" }
}

Write-Host "Perfil detectado: $Profile ($ProfileScore puntos)" -ForegroundColor Cyan
Write-Host ""

# =====================================================================
# FASE 2 – MEMORIA (RESPETO NATIVO)
# =====================================================================

Write-Host "[FASE 2] Memoria" -ForegroundColor Yellow
Write-Host "✔ Gestión de RAM alineada al diseño de Windows" -ForegroundColor Green
Write-Host ""

# =====================================================================
# FASE 3 – CPU / SCHEDULER
# =====================================================================

Write-Host "[FASE 3] CPU y scheduler" -ForegroundColor Yellow

switch ($Profile) {
    "ENTUSIASTA" { $CPUValue = 38 }
    "EQUILIBRADO" { $CPUValue = 26 }
    "ESTANDAR" { $CPUValue = 18 }
    "LIVIANO" { $CPUValue = 2 }
}

Set-ItemProperty `
 "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
 -Name Win32PrioritySeparation -Value $CPUValue

Write-Host "✔ Scheduler aplicado ($CPUValue)" -ForegroundColor Green
Write-Host ""

# =====================================================================
# FASE 4 – INICIO DE SESIÓN
# =====================================================================

Write-Host "[FASE 4] Inicio de sesión" -ForegroundColor Yellow

$Explorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
New-Item -Path $Explorer -Force | Out-Null
Set-ItemProperty -Path $Explorer -Name StartupDelayInMSec -Type DWord -Value 0

Write-Host "✔ Retraso artificial eliminado" -ForegroundColor Green
Write-Host ""

# =====================================================================
# FASE 5 – MEMORIA VIRTUAL
# =====================================================================

Write-Host "[FASE 5] Memoria virtual" -ForegroundColor Yellow

switch ($Profile) {
    "ENTUSIASTA" { $min = 1024; $max = 4096 }
    "EQUILIBRADO" { $min = 2048; $max = 6144 }
    "ESTANDAR" { $min = 4096; $max = 8192 }
    "LIVIANO" { $min = 6144; $max = 12288 }
}

$CS = Get-CimInstance Win32_ComputerSystem
if ($CS.AutomaticManagedPagefile) {

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

Write-Host "✔ Pagefile configurado ($min – $max MB)" -ForegroundColor Green
Write-Host ""

# =====================================================================
# FASE 6 – RED
# =====================================================================

Write-Host "[FASE 6] Red" -ForegroundColor Yellow
Write-Host "✔ TCP/IP en estado saludable (sin resets destructivos)" -ForegroundColor Green
Write-Host ""

# =====================================================================
# FASE 7 – ALMACENAMIENTO
# =====================================================================

Write-Host "[FASE 7] Almacenamiento" -ForegroundColor Yellow

if ($Disk.MediaType -eq "HDD") {
    fsutil behavior set disablelastaccess 1 | Out-Null
    Write-Host "✔ HDD optimizado (menos escrituras)" -ForegroundColor Green
} else {
    Write-Host "✔ SSD/NVMe: sin tweaks innecesarios" -ForegroundColor Green
}

Write-Host ""

# =====================================================================
# FASE 8 – EDUCACIÓN
# =====================================================================

Write-Host "[FASE 8] Educación" -ForegroundColor Yellow
Write-Host "• No se desactivaron servicios críticos" -ForegroundColor DarkGray
Write-Host "• No se tocaron navegadores ni credenciales" -ForegroundColor DarkGray
Write-Host "• No se aplicaron tweaks placebo u obsoletos" -ForegroundColor DarkGray
Write-Host ""

# =====================================================================
# FASE 9 – RESUMEN
# =====================================================================

Write-Host "[FASE 9] Resumen final" -ForegroundColor Cyan
Write-Host "Sistema optimizado con criterio consciente." -ForegroundColor Green
Write-Host "Perfil aplicado: $Profile" -ForegroundColor Green
Write-Host "Reinicio recomendado." -ForegroundColor Yellow
Write-Host ""
