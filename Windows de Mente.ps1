# ============================================================================
#  WINDOWS DE MENTE v2.0  — "La version que siempre debio ser"
#  "Cuando estes mal, cuando estes solo, no te olvides de mi..." - Charly Garcia
#
#  ARQUITECTURA:
#  [1] Diagnostico completo: hardware, Windows, rendimiento, red, disco, Event Log
#  [2] Optimizaciones 100% derivadas del diagnostico con razonamiento visible
#  [3] Limpieza con todos los items, ordenada por tamaño real
#  [4] Privacidad con deteccion de estado actual
#  [5] Reparacion siempre visible, aviso contextual segun diagnostico
#  [6] Log derecho en dos momentos: resumen diagnostico + explicacion por item
#  [7] P/Invoke para papelera (no bloquea WinForms)
#  [8] Backup real del registro antes de aplicar cambios
#  [9] Restauracion real desde backup
#  [10] Barra de estado en tiempo real
# ============================================================================

trap {
    $msg = "Algo salio mal:`n$_`nLinea: $($_.InvocationInfo.ScriptLineNumber)"
    try { [System.Windows.Forms.MessageBox]::Show($msg,"Windows De Mente - Error",0,16)|Out-Null }
    catch { Write-Host $msg }
    exit 1
}

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    try {
        $proc = Start-Process "PowerShell.exe" -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -PassThru -EA Stop
        if ($proc) { exit 0 }
    } catch {
        try { Add-Type -AssemblyName System.Windows.Forms } catch {}
        [System.Windows.Forms.MessageBox]::Show(
            "Necesito permisos de Administrador para hacer mi trabajo.`nClic derecho en el archivo -> Ejecutar como administrador.",
            "Permisos necesarios",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )|Out-Null
        exit 0
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class RecycleBinHelper {
    [DllImport("Shell32.dll", CharSet=CharSet.Unicode)]
    public static extern int SHEmptyRecycleBin(IntPtr hwnd, string pszRootPath, uint dwFlags);
    public const uint SHERB_NOCONFIRMATION = 0x00000001;
    public const uint SHERB_NOPROGRESSUI   = 0x00000002;
    public const uint SHERB_NOSOUND        = 0x00000004;
    public static void Empty() {
        SHEmptyRecycleBin(IntPtr.Zero, null, SHERB_NOCONFIRMATION|SHERB_NOPROGRESSUI|SHERB_NOSOUND);
    }
}
"@ -EA SilentlyContinue

# ----------------------------------------------------------------------------
#  VARIABLES GLOBALES
# ----------------------------------------------------------------------------
$script:Diagnostico        = $null
$script:ResumenDiag        = [System.Collections.Generic.List[string]]::new()
$script:Historial          = [System.Collections.Generic.List[PSObject]]::new()
$script:HistorialFile      = "$env:LOCALAPPDATA\WDM_Historial.xml"
$script:UltimoBackupPath   = $null
$script:ModoVistaPrevia    = $false
$script:CancelarReparacion = $false
$script:IsDarkMode         = $true

# ----------------------------------------------------------------------------
#  TEMAS
# ----------------------------------------------------------------------------
$themes = @{
    Dark = @{
        BgDark      = [System.Drawing.Color]::FromArgb(12,12,18)
        BgPanel     = [System.Drawing.Color]::FromArgb(20,20,30)
        BgCard      = [System.Drawing.Color]::FromArgb(28,28,42)
        BgCard2     = [System.Drawing.Color]::FromArgb(36,36,54)
        BgLog       = [System.Drawing.Color]::FromArgb(8,8,14)
        BgHeader    = [System.Drawing.Color]::FromArgb(16,16,26)
        BgStatus    = [System.Drawing.Color]::FromArgb(10,10,16)
        TextPrimary = [System.Drawing.Color]::FromArgb(238,238,255)
        TextSecond  = [System.Drawing.Color]::FromArgb(200,200,230)
        TextDim     = [System.Drawing.Color]::FromArgb(140,140,175)
        Accent      = [System.Drawing.Color]::FromArgb(0,210,255)
        Accent2     = [System.Drawing.Color]::FromArgb(130,90,255)
        Green       = [System.Drawing.Color]::FromArgb(0,220,130)
        Yellow      = [System.Drawing.Color]::FromArgb(255,210,0)
        Orange      = [System.Drawing.Color]::FromArgb(255,150,0)
        Red         = [System.Drawing.Color]::FromArgb(255,70,70)
        Purple      = [System.Drawing.Color]::FromArgb(180,100,255)
        BorderColor = [System.Drawing.Color]::FromArgb(50,50,76)
    }
    Light = @{
        BgDark      = [System.Drawing.Color]::FromArgb(225,228,238)
        BgPanel     = [System.Drawing.Color]::FromArgb(238,240,250)
        BgCard      = [System.Drawing.Color]::FromArgb(250,251,255)
        BgCard2     = [System.Drawing.Color]::FromArgb(230,234,246)
        BgLog       = [System.Drawing.Color]::FromArgb(244,245,252)
        BgHeader    = [System.Drawing.Color]::FromArgb(215,220,238)
        BgStatus    = [System.Drawing.Color]::FromArgb(205,210,228)
        TextPrimary = [System.Drawing.Color]::FromArgb(18,18,38)
        TextSecond  = [System.Drawing.Color]::FromArgb(45,50,78)
        TextDim     = [System.Drawing.Color]::FromArgb(90,98,130)
        Accent      = [System.Drawing.Color]::FromArgb(0,120,190)
        Accent2     = [System.Drawing.Color]::FromArgb(90,55,200)
        Green       = [System.Drawing.Color]::FromArgb(0,150,85)
        Yellow      = [System.Drawing.Color]::FromArgb(170,120,0)
        Orange      = [System.Drawing.Color]::FromArgb(190,90,0)
        Red         = [System.Drawing.Color]::FromArgb(190,25,25)
        Purple      = [System.Drawing.Color]::FromArgb(120,55,190)
        BorderColor = [System.Drawing.Color]::FromArgb(185,190,215)
    }
}
$script:colors = $themes.Dark

$fonts = @{
    Title    = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
    Header   = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    Body     = New-Object System.Drawing.Font("Segoe UI",9)
    BodyBold = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    Mono     = New-Object System.Drawing.Font("Cascadia Code",8)
    MonoSm   = New-Object System.Drawing.Font("Cascadia Code",7)
    Small    = New-Object System.Drawing.Font("Segoe UI",7)
    TabFont  = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    Status   = New-Object System.Drawing.Font("Segoe UI",8)
}

# ----------------------------------------------------------------------------
#  HELPERS DE UI
# ----------------------------------------------------------------------------
function Write-Log {
    param($Message, $ColorKey = "TextPrimary")
    $c = $script:colors[$ColorKey]
    if (-not $c) { $c = $script:colors.TextPrimary }
    try {
        $rtbLog.SelectionStart  = $rtbLog.TextLength
        $rtbLog.SelectionLength = 0
        $rtbLog.SelectionColor  = $c
        $rtbLog.AppendText("$Message`r`n")
        $rtbLog.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
}

function Write-LogSeparator {
    Write-Log "────────────────────────────" "BorderColor"
}

function Set-Status {
    param($Texto, $ColorKey = "TextDim")
    try {
        $lblStatus.Text      = $Texto
        $lblStatus.ForeColor = $script:colors[$ColorKey]
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
}

# Agrega una linea al resumen del diagnostico (se muestra al hacer clic en tabs)
function Add-Resumen {
    param($Linea)
    $script:ResumenDiag.Add($Linea)
}

function Show-ResumenDiag {
    $rtbLog.Clear()
    $rtbLog.SelectionColor = $script:colors.Accent
    $rtbLog.AppendText("LO QUE ENCONTRE EN TU PC`r`n")
    $rtbLog.SelectionColor = $script:colors.BorderColor
    $rtbLog.AppendText("────────────────────────────`r`n`r`n")
    foreach ($linea in $script:ResumenDiag) {
        # Lineas con prefijo [!] en naranja, [OK] en verde, resto normal
        if ($linea -match "^\[!\]") {
            $rtbLog.SelectionColor = $script:colors.Orange
            $rtbLog.AppendText("$linea`r`n")
        } elseif ($linea -match "^\[OK\]") {
            $rtbLog.SelectionColor = $script:colors.Green
            $rtbLog.AppendText("$linea`r`n")
        } elseif ($linea -match "^>>") {
            $rtbLog.SelectionColor = $script:colors.Yellow
            $rtbLog.AppendText("$linea`r`n")
        } elseif ($linea -eq "---") {
            $rtbLog.SelectionColor = $script:colors.BorderColor
            $rtbLog.AppendText("────────────────────────────`r`n")
        } else {
            $rtbLog.SelectionColor = $script:colors.TextDim
            $rtbLog.AppendText("$linea`r`n")
        }
    }
    $rtbLog.SelectionColor = $script:colors.TextDim
    $rtbLog.AppendText("`r`nHace clic en cualquier item para ver que hace exactamente.")
}

# ----------------------------------------------------------------------------
#  HISTORIAL
# ----------------------------------------------------------------------------
function Load-Historial {
    if (Test-Path $script:HistorialFile) {
        try {
            $data = Import-Clixml -Path $script:HistorialFile -EA 0
            if ($data) {
                $script:Historial = [System.Collections.Generic.List[PSObject]]::new()
                foreach ($item in $data) { $script:Historial.Add($item) }
            }
        } catch { $script:Historial = [System.Collections.Generic.List[PSObject]]::new() }
    }
}
function Save-Historial {
    try { $script:Historial | Export-Clixml -Path $script:HistorialFile -Force } catch {}
}
function Add-Historial {
    param($Nombre, $Tipo, $Exitosa = $true)
    $script:Historial.Insert(0,[PSCustomObject]@{
        Fecha=$( Get-Date); Nombre=$Nombre; Tipo=$Tipo; Exitosa=$Exitosa
    })
    if ($script:Historial.Count -gt 100) { $script:Historial.RemoveAt($script:Historial.Count-1) }
    Save-Historial
}

# ----------------------------------------------------------------------------
#  BACKUP
# ----------------------------------------------------------------------------
function Backup-OriginalState {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $bk = "$env:TEMP\WDM_Backup_$ts.reg"
    Write-Log "Guardando backup del registro..." "TextDim"
    $paths = @(
        "HKCU\Control Panel\Desktop",
        "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl",
        "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management",
        "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile",
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    )
    $reg = "Windows Registry Editor Version 5.00`r`n`r`n"
    foreach ($p in $paths) {
        $rp  = $p -replace "HKLM","HKEY_LOCAL_MACHINE" -replace "HKCU","HKEY_CURRENT_USER"
        $tmp = "$env:TEMP\wdm_$([guid]::NewGuid()).reg"
        reg export $rp $tmp /y 2>$null
        if (Test-Path $tmp) { $reg += Get-Content $tmp -Raw -EA 0; Remove-Item $tmp -Force -EA 0 }
    }
    $reg | Out-File $bk -Encoding Unicode -EA 0
    $script:UltimoBackupPath = $bk
    Write-Log "  Backup guardado." "Green"
    return $bk
}

# ----------------------------------------------------------------------------
#  DIAGNOSTICO COMPLETO
# ----------------------------------------------------------------------------
function Get-DiagnosticoCompleto {
    $script:ResumenDiag.Clear()

    $diag = [PSCustomObject]@{
        # Hardware
        CPUName=""; CPUCores=0; CPUFreqGHz=0
        RAMTotalGB=0; RAMSlots=0; RAMSpeedMHz=0; RequiereMasRAM=$false
        TieneSSD=$false; EsLaptop=$false
        DiscoLibreGB=0; DiscoTotalGB=0; DiscoLibrePct=0; DiscoPocoEspacio=$false
        BateriaOK=$true; BateriaPct=0
        # Windows
        WinVersion=""; WinBuild=0; WinDesactualizado=$false
        UptimeDias=0; RequiereReinicio=$false
        ArchivosSistemaOK=$true; DirtyBit=$false; PendingOperations=$false
        ErroresCriticos=0; ErroresRecientes=@()
        # Rendimiento
        LatenciaRegMs=0; MenuShowDelay=400; ContextMenuCount=0
        PagingExecutiveOK=$false; PrioridadProcesosOK=$false
        VisualEffectsOptimized=$false; NetworkThrottling=$true; TimerResOK=$false
        PowerPlanActivo=""; EsBalanced=$false
        ServiciosExternos=0
        # Red
        EsWiFi=$false; EsEthernet=$false; ProxyActivo=$false; ProxyServidor=""
        # Explorer / Shell
        IconCacheOK=$true; FontCacheOK=$true; MenuContextualOK=$true; ContextMenuRealCount=0
        # Disco
        IndexacionOK=$true; SuperfetchOK=$true; HibernacionActiva=$false; PagefileOK=$true
        # Registro
        EntradasHuerfanas=0; LatenciaRegistroOK=$true
        # WMI
        WMIOK=$true; WMILatenciaMs=0
        # Flags de recomendacion
        RecomendarReparacion=$false
        ProblemasGraves=@()
    }

    # ── HARDWARE ──────────────────────────────────────────────────────────────
    Write-Log "  Veo el hardware..." "TextDim"
    Set-Status "Analizando hardware..."
    try {
        $cimOpt = New-CimSessionOption -Protocol Dcom
        $cs = New-CimSession -SessionOption $cimOpt -OperationTimeoutSec 8 -EA Stop
        $cpu = Get-CimInstance -CimSession $cs Win32_Processor -EA 0 | Select-Object -First 1
        if ($cpu) {
            $diag.CPUName     = $cpu.Name.Trim()
            $diag.CPUCores    = [int]$cpu.NumberOfCores
            $diag.CPUFreqGHz  = [math]::Round($cpu.MaxClockSpeed/1000,1)
        }
        $ram = Get-CimInstance -CimSession $cs Win32_PhysicalMemory -EA 0
        if ($ram) {
            $diag.RAMTotalGB  = [math]::Round(($ram|Measure-Object Capacity -Sum).Sum/1GB,1)
            $diag.RAMSlots    = @($ram).Count
            $diag.RAMSpeedMHz = ($ram | Select-Object -First 1).Speed
        }
        $diag.RequiereMasRAM = $diag.RAMTotalGB -lt 8
        $bat = Get-CimInstance -CimSession $cs Win32_Battery -EA 0
        $diag.EsLaptop = ($null -ne $bat -and @($bat).Count -gt 0)
        if ($diag.EsLaptop -and $bat) {
            $diag.BateriaPct = try{[int]($bat | Select-Object -First 1).EstimatedChargeRemaining}catch{0}
            $diag.BateriaOK  = $diag.BateriaPct -gt 20
        }
        $disks = Get-CimInstance -CimSession $cs Win32_DiskDrive -EA 0
        if ($disks) { $diag.TieneSSD = (@($disks)|Where-Object{$_.Model -match "SSD|NVMe|M\.2|Solid"}).Count -gt 0 }
        $vol = Get-CimInstance -CimSession $cs Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -EA 0
        if ($vol) {
            $diag.DiscoLibreGB  = [math]::Round($vol.FreeSpace/1GB,1)
            $diag.DiscoTotalGB  = [math]::Round($vol.Size/1GB,1)
            $diag.DiscoLibrePct = if($vol.Size -gt 0){[math]::Round($vol.FreeSpace/$vol.Size*100)}else{0}
            $diag.DiscoPocoEspacio = $diag.DiscoLibrePct -lt 10
        }
        Remove-CimSession $cs -EA 0
    } catch {
        try {
            $cpu = Get-CimInstance Win32_Processor -EA 0 | Select-Object -First 1
            if ($cpu) { $diag.CPUName=$cpu.Name.Trim(); $diag.CPUCores=[int]$cpu.NumberOfCores; $diag.CPUFreqGHz=[math]::Round($cpu.MaxClockSpeed/1000,1) }
            $ram = Get-CimInstance Win32_PhysicalMemory -EA 0
            if ($ram) { $diag.RAMTotalGB=[math]::Round(($ram|Measure-Object Capacity -Sum).Sum/1GB,1); $diag.RAMSlots=@($ram).Count }
        } catch {}
    }
    [System.Windows.Forms.Application]::DoEvents()

    # ── WINDOWS / SISTEMA ─────────────────────────────────────────────────────
    Write-Log "  Verifico la version de Windows..." "TextDim"
    Set-Status "Verificando Windows..."
    try {
        $wv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA 0
        if ($wv) {
            $diag.WinVersion = "$($wv.ProductName) $($wv.DisplayVersion)"
            $diag.WinBuild   = [int]$wv.CurrentBuildNumber
            # Build minimo razonable para Win11: 22000, Win10: 19041
            $diag.WinDesactualizado = ($diag.WinBuild -lt 19041)
        }
        $uptime = (Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime((Get-CimInstance Win32_OperatingSystem -EA 0).LastBootUpTime)
        $diag.UptimeDias = [math]::Round($uptime.TotalDays,1)
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── RENDIMIENTO / REGISTRO ────────────────────────────────────────────────
    Write-Log "  Mido el rendimiento del sistema..." "TextDim"
    Set-Status "Midiendo rendimiento..."
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA 0
        $sw.Stop(); $diag.LatenciaRegMs = [math]::Round($sw.Elapsed.TotalMilliseconds,2)
        $msd = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -EA 0
        $diag.MenuShowDelay = if($msd){[int]$msd.MenuShowDelay}else{400}
        $count = 0
        foreach ($rp in @("HKCR\*\shellex\ContextMenuHandlers","HKCR\Directory\shellex\ContextMenuHandlers","HKCR\Folder\shellex\ContextMenuHandlers")) {
            $lines = reg query $rp 2>$null
            if ($lines) { $count += ($lines|Where-Object{$_ -match "^HKEY"}).Count }
        }
        $diag.ContextMenuCount = $count
        $dpe = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -EA 0).DisablePagingExecutive
        $diag.PagingExecutiveOK = ($diag.RAMTotalGB -ge 8 -and $dpe -eq 1) -or ($diag.RAMTotalGB -lt 8)
        $wps = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -EA 0).Win32PrioritySeparation
        if ($null -eq $wps) { $wps = 2 }
        $ideal = if($diag.CPUCores -ge 8){38}elseif($diag.CPUCores -ge 4){26}else{18}
        $diag.PrioridadProcesosOK = ($wps -eq $ideal)
        $nt = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -EA 0).NetworkThrottlingIndex
        $diag.NetworkThrottling = ($null -eq $nt -or $nt -ne 0xFFFFFFFF)
        $tr = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -EA 0).SystemResponsiveness
        $diag.TimerResOK = ($tr -eq 0 -or $tr -eq 1)
        $ve = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -EA 0).VisualFXSetting
        $diag.VisualEffectsOptimized = ($ve -eq 2)
        $planLine = powercfg /getactivescheme 2>$null | Select-Object -First 1
        if ($planLine -match "\((.+)\)$") { $diag.PowerPlanActivo = $Matches[1].Trim() }
        $diag.EsBalanced = $diag.PowerPlanActivo -match "Equilibrado|Balanced"
        $diag.ServiciosExternos = @(Get-Service -EA 0|Where-Object{$_.Status -eq "Running" -and $_.DisplayName -notmatch "Microsoft|Windows|@|Driver"}).Count

        # Prefetcher
        $idealPref = if($diag.TieneSSD){2}else{3}
        $curPref = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -EA 0).EnablePrefetcher
        $diag | Add-Member -NotePropertyName PrefetcherOK -NotePropertyValue ($curPref -eq $idealPref) -Force

        # NTFS Last Access
        $ntfsLa = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -EA 0).NtfsDisableLastAccessUpdate
        $diag | Add-Member -NotePropertyName NtfsLastAccessOK -NotePropertyValue ($ntfsLa -eq 1 -or $ntfsLa -eq 3) -Force

        # SystemResponsiveness
        $idealSR = if($diag.CPUCores -le 4){10}else{0}
        $curSR = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -EA 0).SystemResponsiveness
        $diag | Add-Member -NotePropertyName SystemResponsivenessOK -NotePropertyValue ($curSR -eq $idealSR) -Force

        # Explorer Separate Process
        $sep = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SeparateProcess" -EA 0).SeparateProcess
        $diag | Add-Member -NotePropertyName ExplorerSeparateOK -NotePropertyValue ($sep -eq 1) -Force
    } catch { Write-Log "  Rendimiento: revision parcial" "Yellow" }
    [System.Windows.Forms.Application]::DoEvents()

    # ── RED ───────────────────────────────────────────────────────────────────
    Write-Log "  Reviso la conexion de red..." "TextDim"
    Set-Status "Revisando red..."
    try {
        $nics = Get-CimInstance Win32_NetworkAdapter -Filter "NetEnabled=True" -EA 0
        foreach ($nic in @($nics)) {
            if ($nic.Description -match "Wi-Fi|Wireless|802\.11|WLAN") { $diag.EsWiFi=$true; break }
        }
        if (-not $diag.EsWiFi -and $nics) { $diag.EsEthernet=$true }
        $proxy = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -EA 0
        if ($proxy -and $proxy.ProxyEnable -eq 1) { $diag.ProxyActivo=$true; $diag.ProxyServidor=$proxy.ProxyServer }
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── DISCO ─────────────────────────────────────────────────────────────────
    Write-Log "  Chequeo el estado del disco..." "TextDim"
    Set-Status "Chequeando disco..."
    try {
        $dirty = fsutil dirty query $env:SystemDrive 2>$null
        $diag.DirtyBit = $dirty -match "SUCIO|dirty"
        $pend = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -EA 0
        $diag.PendingOperations = ($pend -and $pend.PendingFileRenameOperations.Count -gt 0)
        $diag.RequiereReinicio  = $diag.PendingOperations -or ($diag.UptimeDias -gt 7)
        $diag.ArchivosSistemaOK = (Test-Path "$env:SystemRoot\System32\ntoskrnl.exe") -and (Test-Path "$env:SystemRoot\System32\kernel32.dll")
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── EVENT LOG — clasificacion inteligente señal vs ruido ──────────────────
    Write-Log "  Busco errores recientes en Windows..." "TextDim"
    Set-Status "Revisando el historial de errores de Windows..."
    try {
        # ── RUIDO: proveedores que Windows genera normalmente, no indican falla real
        $patronesRuido = @(
            "Microsoft-Windows-Security-SPP",        # Activacion de licencia (muy comun en activadores)
            "Microsoft-Windows-WindowsUpdateClient", # WU haciendo su trabajo
            "Microsoft-Windows-Defrag",              # Desfragmentacion programada
            "Microsoft-Windows-Search",              # Indexador del buscador
            "Microsoft-Windows-Superfetch",          # Precarga de apps en RAM
            "ESENT",                                 # Base de datos interna de Windows (mantenimiento normal)
            "VSS",                                   # Shadow copies / puntos de restauracion
            "DistributedCOM",                        # COM interprocess, falla constantemente en Win10/11
            "Microsoft-Windows-UserModePowerService",# Gestion de energia, muy ruidoso
            "Winlogon",                              # Sesion de usuario, eventos normales
            "Microsoft-Windows-TaskScheduler",       # Tareas programadas que a veces fallan sin consecuencias
            "Microsoft-Windows-Bits-Client",         # Transferencias en background (Windows Update)
            "Microsoft-Windows-WMI"                  # WMI haciendo consultas internas
        )

        # ── SEÑAL: patrones que SÍ indican problemas reales del sistema
        $categoriasSenial = @{
            "Disco fisico fallando"         = @("disk","nvme","atapi","storahci","iaStorA","stornvme","cdrom")
            "Corrupcion del sistema"        = @("Ntfs","ntfs","chkdsk","volsnap","FsDepends")
            "Pantallazo azul / apagado brusco" = @("EventLog","bugcheck","Kernel-Power","Microsoft-Windows-Kernel-Power","Whea-Logger","WHEA")
            "Driver de video"               = @("dxgkrnl","nvlddmkm","igdkmd","amdkmdag","nvlddmkm","dxgmms")
            "Programa crasheando"           = @("Application Error","Windows Error Reporting","WerFault","Faulting")
            "Red con problemas"             = @("Tcpip","Dhcp","Netlogon","DNS","W32Time","NlaSvc")
            "Driver general"                = @("Service Control Manager")
        }

        $desde = (Get-Date).AddHours(-48)
        $todosEventos = Get-WinEvent -FilterHashtable @{
            LogName   = 'System','Application'
            Level     = 1,2
            StartTime = $desde
        } -MaxEvents 300 -EA 0

        $cantidadTotal  = 0
        $cantidadRuido  = 0
        $eventosSenial  = [System.Collections.Generic.List[PSObject]]::new()

        if ($todosEventos) {
            $cantidadTotal = @($todosEventos).Count
            foreach ($ev in $todosEventos) {
                $prov = $ev.ProviderName

                # Es ruido?
                $esRuido = $false
                foreach ($patron in $patronesRuido) {
                    if ($prov -like "*$patron*") { $esRuido = $true; break }
                }
                if ($esRuido) { $cantidadRuido++; continue }

                # Clasificar como señal con categoria
                $categoria = "Otro error del sistema"
                foreach ($cat in $categoriasSenial.GetEnumerator()) {
                    foreach ($keyword in $cat.Value) {
                        if ($prov -like "*$keyword*" -or $ev.Message -like "*$keyword*") {
                            $categoria = $cat.Key; break
                        }
                    }
                    if ($categoria -ne "Otro error del sistema") { break }
                }

                $eventosSenial.Add([PSCustomObject]@{
                    Tiempo    = $ev.TimeCreated
                    Proveedor = $prov
                    Categoria = $categoria
                    Mensaje   = $ev.Message.Split("`n")[0].Trim()
                })
            }

            # Agrupar señales por categoria para no repetir
            $senialAgrupada = $eventosSenial | Group-Object Categoria | Sort-Object Count -Descending

            $diag.ErroresCriticos  = $eventosSenial.Count
            $diag.ErroresRecientes = @($senialAgrupada | ForEach-Object {
                $ejemplos = ($_.Group | Select-Object -First 2 | ForEach-Object {
                    "      $($_.Tiempo.ToString('dd/MM HH:mm')) $($_.Proveedor)"
                }) -join "`n"
                "  [$($_.Count)x] $($_.Name):`n$ejemplos"
            })
            $diag | Add-Member -NotePropertyName ErroresRuido    -NotePropertyValue $cantidadRuido     -Force
            $diag | Add-Member -NotePropertyName ErroresTotalRaw -NotePropertyValue $cantidadTotal     -Force
            $diag | Add-Member -NotePropertyName SenialAgrupada  -NotePropertyValue $senialAgrupada   -Force
        }
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── EXPLORER / SHELL ──────────────────────────────────────────────────────
    Write-Log "  Reviso Explorer y el shell..." "TextDim"
    Set-Status "Revisando Explorer y shell..."
    try {
        # Cache de iconos
        $icSize = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -EA 0 | Measure-Object Length -Sum).Sum
        $diag.IconCacheOK = ($null -eq $icSize -or $icSize -lt 50MB)

        # Cache de fuentes
        $fdir = "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache"
        $fSize = if(Test-Path $fdir){(Get-ChildItem $fdir -File -EA 0 | Measure-Object Length -Sum).Sum}else{0}
        $diag.FontCacheOK = ($fSize -lt 100MB)

        # Menu contextual
        $cmCount = 0
        foreach ($rp in @("HKCR\*\shellex\ContextMenuHandlers","HKCR\Directory\shellex\ContextMenuHandlers","HKCR\Folder\shellex\ContextMenuHandlers")) {
            $lines = reg query $rp 2>$null
            if ($lines) { $cmCount += ($lines | Where-Object { $_ -match "^HKEY" }).Count }
        }
        $diag.ContextMenuRealCount = $cmCount
        $diag.MenuContextualOK     = $cmCount -le 15

        # Explorer crasheando — buscar en Event Log
        $expCrash = Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='Application Error';StartTime=(Get-Date).AddHours(-48)} -MaxEvents 20 -EA 0
        $diag | Add-Member -NotePropertyName ExplorerCrashes -NotePropertyValue (@($expCrash | Where-Object {$_.Message -match "explorer.exe"}).Count) -Force
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── DISCO / ESCRITURA CONTINUA ────────────────────────────────────────────
    Write-Log "  Reviso configuracion del disco..." "TextDim"
    Set-Status "Revisando escritura en disco..."
    try {
        # Indexacion
        $wsvc = Get-Service -Name "WSearch" -EA 0
        $diag.IndexacionOK = ($script:Diagnostico -and $diag.TieneSSD) -or ($null -eq $wsvc) -or ($wsvc.StartType -eq "Disabled")
        # En HDD con indexacion activa es problema real
        if (-not $diag.TieneSSD -and $wsvc -and $wsvc.StartType -ne "Disabled") { $diag.IndexacionOK = $false }

        # Superfetch
        $sfSvc = Get-Service -Name "SysMain" -EA 0
        if ($diag.TieneSSD -and $sfSvc -and $sfSvc.StartType -ne "Disabled") { $diag.SuperfetchOK = $false }
        elseif ($diag.RAMTotalGB -lt 6 -and $sfSvc -and $sfSvc.StartType -ne "Disabled") { $diag.SuperfetchOK = $false }
        else { $diag.SuperfetchOK = $true }

        # Hibernacion
        $diag.HibernacionActiva = (Test-Path "$env:SystemRoot\hiberfil.sys")

        # Pagefile
        $pf = Get-CimInstance Win32_PageFileSetting -EA 0
        if ($pf) {
            $primero = $pf | Select-Object -First 1
            $diag.PagefileOK = ($primero.InitialSize -gt 0 -and $primero.MaximumSize -gt 0)
        }
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── REGISTRO ──────────────────────────────────────────────────────────────
    Write-Log "  Reviso el registro de Windows..." "TextDim"
    Set-Status "Revisando registro..."
    try {
        $diag.LatenciaRegistroOK = ($diag.LatenciaRegMs -lt 50)
        $huerfanos = 0
        foreach ($rk in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")) {
            if (Test-Path $rk) {
                $props = Get-ItemProperty $rk -EA 0
                foreach ($prop in ($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" })) {
                    $exe = ($prop.Value -replace '"','' -split ' ')[0].Trim()
                    if ($exe -and -not (Test-Path $exe) -and $exe -notmatch "^%" -and $exe -notmatch "^[A-Z]{1}:\\Windows") {
                        $huerfanos++
                    }
                }
            }
        }
        $diag.EntradasHuerfanas = $huerfanos
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()

    # ── WMI ───────────────────────────────────────────────────────────────────
    Write-Log "  Verifico WMI..." "TextDim"
    Set-Status "Verificando WMI..."
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Get-CimInstance Win32_OperatingSystem -EA Stop
        $sw.Stop()
        $diag.WMILatenciaMs = [math]::Round($sw.Elapsed.TotalMilliseconds)
        $diag.WMIOK = ($diag.WMILatenciaMs -lt 3000)
        if (-not $diag.WMIOK) { $diag.ProblemasGraves += "WMI corrupto o muy lento ($($diag.WMILatenciaMs)ms)" }
    } catch {
        $diag.WMIOK = $false
        $diag.WMILatenciaMs = 9999
        $diag.ProblemasGraves += "WMI no responde"
    }
    [System.Windows.Forms.Application]::DoEvents()

    # ── BOOT TIME — Event ID 100 ──────────────────────────────────────────────
    Write-Log "  Mido el tiempo de arranque real..." "TextDim"
    Set-Status "Midiendo tiempo de arranque..."
    try {
        $bootEvent = Get-WinEvent -FilterHashtable @{
            LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"
            Id      = 100
        } -MaxEvents 1 -EA Stop

        # Propiedad 6 = BootTime total en ms, Propiedad 0 = MainPathBootTime
        $bootMs     = [int]$bootEvent.Properties[6].Value
        $mainPathMs = [int]$bootEvent.Properties[0].Value

        $diag | Add-Member -NotePropertyName BootTimeMs     -NotePropertyValue $bootMs     -Force
        $diag | Add-Member -NotePropertyName BootTimeMainMs -NotePropertyValue $mainPathMs -Force
        $diag | Add-Member -NotePropertyName BootSlow       -NotePropertyValue ($bootMs -gt 60000) -Force
        $diag | Add-Member -NotePropertyName BootMuySlow    -NotePropertyValue ($bootMs -gt 120000) -Force
    } catch {
        $diag | Add-Member -NotePropertyName BootTimeMs     -NotePropertyValue 0     -Force
        $diag | Add-Member -NotePropertyName BootTimeMainMs -NotePropertyValue 0     -Force
        $diag | Add-Member -NotePropertyName BootSlow       -NotePropertyValue $false -Force
        $diag | Add-Member -NotePropertyName BootMuySlow    -NotePropertyValue $false -Force
    }
    [System.Windows.Forms.Application]::DoEvents()

    # ── ARMAR RESUMEN DEL DIAGNOSTICO ─────────────────────────────────────────
    Add-Resumen "HARDWARE"
    Add-Resumen "  CPU:   $($diag.CPUName) ($($diag.CPUCores) cores, $($diag.CPUFreqGHz) GHz)"
    Add-Resumen "  RAM:   $($diag.RAMTotalGB) GB en $($diag.RAMSlots) slot(s)$(if($diag.RAMSpeedMHz -gt 0){" a $($diag.RAMSpeedMHz) MHz"})"
    Add-Resumen "  Disco: $(if($diag.TieneSSD){'SSD'}else{'HDD'}) — $($diag.DiscoLibreGB) GB libres de $($diag.DiscoTotalGB) GB ($($diag.DiscoLibrePct)%)"
    Add-Resumen "  Tipo:  $(if($diag.EsLaptop){'Laptop'}else{'Desktop'})"
    if ($diag.EsLaptop -and $diag.BateriaPct -gt 0) { Add-Resumen "  Bateria: $($diag.BateriaPct)%" }
    Add-Resumen "---"
    Add-Resumen "WINDOWS"
    Add-Resumen "  Version: $($diag.WinVersion) (build $($diag.WinBuild))"
    Add-Resumen "  Uptime:  $($diag.UptimeDias) dias sin reiniciar"

    if ($diag.WinDesactualizado) {
        Add-Resumen "[!] Tu Windows esta muy desactualizado (build $($diag.WinBuild))"
        $diag.ProblemasGraves += "Windows desactualizado"
    } else {
        Add-Resumen "[OK] Version de Windows al dia"
    }
    if ($diag.UptimeDias -gt 14) {
        Add-Resumen "[!] Llevas $($diag.UptimeDias) dias sin reiniciar — puede afectar el rendimiento"
    } elseif ($diag.RequiereReinicio -and $diag.PendingOperations) {
        Add-Resumen "[!] Hay operaciones pendientes que esperan un reinicio"
    } else {
        Add-Resumen "[OK] Uptime normal"
    }
    Add-Resumen "---"
    Add-Resumen "DISCO"
    if ($diag.DirtyBit) {
        Add-Resumen "[!] El disco tiene el dirty bit activo — hay inconsistencias sin resolver"
        $diag.ProblemasGraves += "Disco con dirty bit"
        $diag.RecomendarReparacion = $true
    } else {
        Add-Resumen "[OK] Disco sin errores detectados"
    }
    if ($diag.DiscoPocoEspacio) {
        Add-Resumen "[!] Poco espacio libre ($($diag.DiscoLibrePct)%) — la PC puede volverse lenta"
        $diag.ProblemasGraves += "Poco espacio en disco"
    }
    if (-not $diag.ArchivosSistemaOK) {
        Add-Resumen "[!] Faltan archivos criticos del sistema"
        $diag.ProblemasGraves += "Archivos del sistema faltantes"
        $diag.RecomendarReparacion = $true
    }
    Add-Resumen "---"
    Add-Resumen "RENDIMIENTO"
    if (-not $diag.PrioridadProcesosOK) {
        Add-Resumen "[!] Prioridad de CPU no esta optimizada para $($diag.CPUCores) cores"
        Add-Resumen "    >> Valor actual vs ideal para tu CPU: lo corrijo en Optimizaciones"
    } else {
        Add-Resumen "[OK] Prioridad de CPU correcta"
    }
    if ($diag.EsBalanced -and -not $diag.EsLaptop) {
        Add-Resumen "[!] Plan de energia: '$($diag.PowerPlanActivo)' — el CPU se frena innecesariamente"
    } else {
        Add-Resumen "[OK] Plan de energia: $($diag.PowerPlanActivo)"
    }
    if ($diag.MenuShowDelay -gt 0) {
        Add-Resumen "[!] Delay de menus: $($diag.MenuShowDelay)ms — se puede bajar a 0"
    }
    if (-not $diag.VisualEffectsOptimized) {
        Add-Resumen "[!] Efectos visuales sin optimizar — consumen RAM y CPU"
    }
    if ($diag.NetworkThrottling) {
        Add-Resumen "[!] Network throttling activo — la red esta siendo limitada"
    }
    if (-not $diag.SystemResponsivenessOK) {
        $idealSR = if($diag.CPUCores -le 4){10}else{0}
        Add-Resumen "[!] SystemResponsiveness no optimo para $($diag.CPUCores) cores (ideal: $idealSR)"
    } else {
        Add-Resumen "[OK] SystemResponsiveness correcto para $($diag.CPUCores) cores"
    }
    if (-not $diag.PrefetcherOK) {
        $idealPref = if($diag.TieneSSD){"2 (SSD)"}else{"3 (HDD)"}
        Add-Resumen "[!] Prefetcher no esta configurado para tu disco (ideal: $idealPref)"
    } else {
        Add-Resumen "[OK] Prefetcher configurado correctamente para $(if($diag.TieneSSD){'SSD'}else{'HDD'})"
    }
    if (-not $diag.NtfsLastAccessOK) {
        Add-Resumen "[!] NTFS Last Access activo — cada lectura genera escritura extra"
    } else {
        Add-Resumen "[OK] NTFS Last Access desactivado"
    }
    if ($diag.ServiciosExternos -gt 10) {
        $svcParaDesact = (Get-ServiciosParaDesactivar).Count
        if ($svcParaDesact -gt 0) {
            Add-Resumen "[!] $($diag.ServiciosExternos) servicios en segundo plano ($svcParaDesact se pueden desactivar)"
        } else {
            Add-Resumen "  $($diag.ServiciosExternos) servicios en segundo plano (ya optimizados)"
        }
    }
    Add-Resumen "---"
    Add-Resumen "EXPLORER / SHELL"
    if (-not $diag.MenuContextualOK) {
        Add-Resumen "[!] Menu contextual saturado: $($diag.ContextMenuRealCount) entradas (puede haber huerfanas)"
    } else {
        Add-Resumen "[OK] Menu contextual normal ($($diag.ContextMenuRealCount) entradas)"
    }
    if (-not $diag.IconCacheOK) {
        Add-Resumen "[!] Cache de iconos grande — puede causar iconos lentos o en blanco"
    } else {
        Add-Resumen "[OK] Cache de iconos normal"
    }
    if (-not $diag.FontCacheOK) {
        Add-Resumen "[!] Cache de fuentes muy grande — puede frenar el Explorer"
    } else {
        Add-Resumen "[OK] Cache de fuentes normal"
    }
    $expCr = try{$diag.ExplorerCrashes}catch{0}
    if ($expCr -gt 0) {
        Add-Resumen "[!] Explorer se cayo $expCr vez/veces en las ultimas 48hs"
        $diag.ProblemasGraves += "Explorer crasheando ($expCr veces)"
    }
    Add-Resumen "---"
    Add-Resumen "DISCO / ESCRITURA"
    if (-not $diag.IndexacionOK) {
        Add-Resumen "[!] Indexacion activa en HDD — escribe constantemente y frena el disco"
    } else {
        Add-Resumen "[OK] Indexacion $(if($diag.TieneSSD){'(SSD, no es problema)'}else{'correcta'})"
    }
    if (-not $diag.SuperfetchOK) {
        $razon = if($diag.TieneSSD){"en SSD genera escritura innecesaria"}else{"con $($diag.RAMTotalGB)GB RAM consume mas de lo que ayuda"}
        Add-Resumen "[!] SysMain/Superfetch activo — $razon"
    } else {
        Add-Resumen "[OK] SysMain configurado correctamente"
    }
    if ($diag.HibernacionActiva) {
        Add-Resumen "[!] Hibernacion activa — hiberfil.sys ocupa varios GB"
    } else {
        Add-Resumen "[OK] Hibernacion desactivada"
    }
    if (-not $diag.PagefileOK) {
        Add-Resumen "[!] Pagefile en modo automatico — Windows lo redimensiona constantemente"
    } else {
        Add-Resumen "[OK] Pagefile con tamano fijo"
    }
    Add-Resumen "---"
    Add-Resumen "REGISTRO"
    if ($diag.EntradasHuerfanas -gt 0) {
        Add-Resumen "[!] $($diag.EntradasHuerfanas) entrada(s) de arranque huerfanas (apuntan a programas que ya no existen)"
    } else {
        Add-Resumen "[OK] Entradas de arranque limpias"
    }
    if (-not $diag.LatenciaRegistroOK) {
        Add-Resumen "[!] Latencia del registro alta ($($diag.LatenciaRegMs)ms) — puede indicar fragmentacion"
    } else {
        Add-Resumen "[OK] Latencia del registro normal ($($diag.LatenciaRegMs)ms)"
    }
    Add-Resumen "---"
    Add-Resumen "WMI"
    if (-not $diag.WMIOK) {
        Add-Resumen "[!] WMI lento o corrupto ($($diag.WMILatenciaMs)ms) — causa lentitud general misteriosa"
        $diag.RecomendarReparacion = $true
    } else {
        Add-Resumen "[OK] WMI respondiendo normal ($($diag.WMILatenciaMs)ms)"
    }
    Add-Resumen "---"
    Add-Resumen "ARRANQUE"
    if ($diag.BootTimeMs -gt 0) {
        $bootSeg = [math]::Round($diag.BootTimeMs / 1000)
        if ($diag.BootMuySlow) {
            Add-Resumen "[!] Arranque muy lento: $bootSeg seg — algo esta bloqueando el inicio"
            $diag.ProblemasGraves += "Arranque muy lento ($bootSeg seg)"
        } elseif ($diag.BootSlow) {
            Add-Resumen "[!] Arranque lento: $bootSeg seg — puede mejorarse"
        } else {
            Add-Resumen "[OK] Arranque en $bootSeg seg"
        }
    } else {
        Add-Resumen "  Tiempo de arranque: no disponible (primer inicio o log vacio)"
    }
    Add-Resumen "---"
    Add-Resumen "RED"
    $redTipo = if($diag.EsWiFi){"WiFi"}elseif($diag.EsEthernet){"Ethernet"}else{"No detectada"}
    Add-Resumen "  Conexion: $redTipo"
    if ($diag.ProxyActivo) { Add-Resumen "[!] Proxy activo: $($diag.ProxyServidor)" }
    Add-Resumen "---"
    Add-Resumen "ERRORES RECIENTES (ultimas 48hs)"

    # Mostrar cuanto ruido fue filtrado
    $ruido = try{$diag.ErroresRuido}catch{0}
    $total = try{$diag.ErroresTotalRaw}catch{0}
    if ($ruido -gt 0) {
        Add-Resumen "  Filtre $ruido evento(s) de mantenimiento normal de Windows (ruido esperado)"
    }

    if ($diag.ErroresCriticos -eq 0) {
        Add-Resumen "[OK] No encontre errores que necesiten atencion"
    } else {
        Add-Resumen "[!] Encontre $($diag.ErroresCriticos) error(es) que merecen atencion:"
        Add-Resumen ""
        foreach ($e in $diag.ErroresRecientes) { Add-Resumen $e }

        # Solo recomendar reparacion si hay señales de disco, BSOD o archivos corruptos
        $seniales = try{$diag.SenialAgrupada}catch{$null}
        if ($seniales) {
            $categoriasGraves = @("Disco fisico fallando","Corrupcion del sistema","Pantallazo azul / apagado brusco","Driver de video")
            foreach ($sg in $seniales) {
                if ($sg.Name -in $categoriasGraves -and $sg.Count -ge 2) {
                    $diag.ProblemasGraves += "$($sg.Count)x $($sg.Name)"
                    $diag.RecomendarReparacion = $true
                }
            }
        }
    }

    if ($diag.ProblemasGraves.Count -gt 0) {
        Add-Resumen "---"
        Add-Resumen ">> PROBLEMAS QUE NECESITAN ATENCION:"
        foreach ($p in $diag.ProblemasGraves) { Add-Resumen "   - $p" }
        Add-Resumen ">> Revisa la pestana REPARACION"
    }

    return $diag
}

# ============================================================================
#  OPTIMIZACIONES — Check / Optimize
# ============================================================================
function Check-Win32PrioritySeparation {
    $ideal = if($script:Diagnostico.EsLaptop){2}elseif($script:Diagnostico.CPUCores -ge 8){38}elseif($script:Diagnostico.CPUCores -ge 4){26}else{18}
    $cur = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -EA 0).Win32PrioritySeparation
    return ($cur -eq $ideal)
}
function Optimize-Win32PrioritySeparation {
    $ideal = if($script:Diagnostico.EsLaptop){2}elseif($script:Diagnostico.CPUCores -ge 8){38}elseif($script:Diagnostico.CPUCores -ge 4){26}else{18}
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value $ideal -Type DWord -EA Stop
    Write-Log "  Prioridad CPU ajustada (valor: $ideal para $($script:Diagnostico.CPUCores) cores)" "Green"
    return $true
}

function Check-DisablePagingExecutive {
    if ($script:Diagnostico.RAMTotalGB -lt 8) { return $true }
    return ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -EA 0).DisablePagingExecutive -eq 1)
}
function Optimize-DisablePagingExecutive {
    if ($script:Diagnostico.RAMTotalGB -lt 8) { Write-Log "  Con poca RAM mejor no tocarlo" "TextDim"; return $true }
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -EA Stop
    Write-Log "  Kernel fijado en RAM ($($script:Diagnostico.RAMTotalGB) GB disponibles)" "Green"
    return $true
}

function Check-MenuShowDelay {
    $cur = (Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -EA 0).MenuShowDelay
    return ($cur -eq "0" -or $cur -eq 0)
}
function Optimize-MenuShowDelay {
    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -EA Stop
    Write-Log "  Menus instantaneos activados (antes: $($script:Diagnostico.MenuShowDelay)ms)" "Green"
    return $true
}

function Check-PowerPlan { return -not $script:Diagnostico.EsBalanced }
function Optimize-PowerPlan {
    $guid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    powercfg /setactive $guid 2>$null
    if ((powercfg /getactivescheme 2>$null) -match "8c5e7fda") {
        Write-Log "  Plan Alto Rendimiento activado" "Green"; return $true
    }
    Write-Log "  No se pudo cambiar el plan de energia" "Yellow"; return $false
}

function Check-VisualEffects { return $script:Diagnostico.VisualEffectsOptimized }
function Optimize-VisualEffects {
    $k = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (-not(Test-Path $k)) { New-Item $k -Force|Out-Null }
    Set-ItemProperty $k -Name "VisualFXSetting" -Value 2 -Type DWord -EA Stop
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $adv -Name "ListviewAlphaSelect" -Value 0 -Type DWord -EA 0
    Set-ItemProperty $adv -Name "TaskbarAnimations"   -Value 0 -Type DWord -EA 0
    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -EA 0
    Write-Log "  Efectos visuales reducidos — mas velocidad, menos consumo" "Green"
    return $true
}

function Check-NetworkThrottling { return -not $script:Diagnostico.NetworkThrottling }
function Optimize-NetworkThrottling {
    $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty $k -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -EA Stop
    Write-Log "  Network throttling desactivado" "Green"; return $true
}

function Get-IdealSystemResponsiveness {
    # 2-4 cores: 10 (reserva algo de CPU para el sistema)
    # 6+ cores:   0 (sobran cores, maxima respuesta para foreground)
    if ($script:Diagnostico.CPUCores -le 4) { return 10 } else { return 0 }
}
function Check-SystemResponsiveness {
    $ideal = Get-IdealSystemResponsiveness
    $cur = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -EA 0).SystemResponsiveness
    return ($cur -eq $ideal)
}
function Optimize-SystemResponsiveness {
    $ideal = Get-IdealSystemResponsiveness
    $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty $k -Name "SystemResponsiveness" -Value $ideal -Type DWord -EA Stop
    $razon = if($script:Diagnostico.CPUCores -le 4){"$($script:Diagnostico.CPUCores) cores — valor conservador (10)"}else{"$($script:Diagnostico.CPUCores) cores — maxima prioridad foreground (0)"}
    Write-Log "  SystemResponsiveness ajustado: $ideal ($razon)" "Green"
    return $true
}

$script:ServiciosObjetivo = @("DiagTrack","dmwappushservice","XboxNetApiSvc","XblAuthManager","SysMain","WSearch","TabletInputService","Fax","RetailDemo","MapsBroker","PhoneSvc","PrintNotify","RemoteRegistry")

function Get-ServiciosParaDesactivar {
    $activos = @()
    foreach ($s in $script:ServiciosObjetivo) {
        $svc = Get-Service -Name $s -EA 0
        if ($svc -and $svc.StartType -ne "Disabled" -and $svc.StartType -ne "Manual") { $activos += $s }
    }
    return $activos
}
function Check-ServiciosExternos {
    return ((Get-ServiciosParaDesactivar).Count -eq 0)
}
function Optimize-ServiciosExternos {
    $lista = Get-ServiciosParaDesactivar
    $count = 0
    foreach ($s in $lista) {
        try {
            Set-Service -Name $s -StartupType Disabled -EA Stop
            Stop-Service -Name $s -Force -EA 0
            $count++
        } catch {}
    }
    if ($count -gt 0) { Write-Log "  $count servicios desactivados: $($lista -join ', ')" "Green"; return $true }
    Write-Log "  No encontre servicios para desactivar" "TextDim"; return $false
}

# ── PREFETCHER ADAPTATIVO ──────────────────────────────────────────────────────

function Get-IdealPrefetcher {
    # HDD: 3 (boot + apps), SSD: 2 (solo apps, el boot en SSD es tan rapido que no necesita prefetch)
    if ($script:Diagnostico.TieneSSD) { return 2 } else { return 3 }
}
function Check-Prefetcher {
    $ideal = Get-IdealPrefetcher
    $cur = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -EA 0).EnablePrefetcher
    return ($cur -eq $ideal)
}
function Optimize-Prefetcher {
    $ideal = Get-IdealPrefetcher
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
    if (-not (Test-Path $k)) { New-Item $k -Force | Out-Null }
    Set-ItemProperty $k -Name "EnablePrefetcher" -Value $ideal -Type DWord -EA Stop
    $razon = if($script:Diagnostico.TieneSSD){"SSD — modo apps solamente (2)"}else{"HDD — modo completo boot+apps (3)"}
    Write-Log "  Prefetcher configurado para tu disco: $razon" "Green"
    return $true
}

# ── NTFS LAST ACCESS UPDATE ───────────────────────────────────────────────────

function Check-NtfsLastAccess {
    $cur = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -EA 0).NtfsDisableLastAccessUpdate
    # Valor 1 = desactivado (optimo), 0 o ausente = activo (genera escrituras)
    return ($cur -eq 1 -or $cur -eq 3)   # 3 = desactivado por el sistema en Win10+
}
function Optimize-NtfsLastAccess {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1 -Type DWord -EA Stop
    Write-Log "  NTFS Last Access desactivado — menos escrituras en disco$(if(-not $script:Diagnostico.TieneSSD){', especialmente util en HDD'})" "Green"
    return $true
}

# ── EXPLORER SEPARATE PROCESS ─────────────────────────────────────────────────

function Check-ExplorerSeparateProcess {
    $cur = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SeparateProcess" -EA 0).SeparateProcess
    return ($cur -eq 1)
}
function Optimize-ExplorerSeparateProcess {
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty $adv -Name "SeparateProcess" -Value 1 -Type DWord -EA Stop
    Write-Log "  Explorer configurado en proceso separado — un crash no arrastra al escritorio" "Green"
    return $true
}

# ── EXPLORER / SHELL ──────────────────────────────────────────────────────────

function Check-MenuContextual {
    # Cuenta entradas del menu contextual — mas de 15 lo hace lento en cualquier PC
    $count = 0
    foreach ($rp in @("HKCR\*\shellex\ContextMenuHandlers","HKCR\Directory\shellex\ContextMenuHandlers","HKCR\Folder\shellex\ContextMenuHandlers")) {
        $lines = reg query $rp 2>$null
        if ($lines) { $count += ($lines | Where-Object { $_ -match "^HKEY" }).Count }
    }
    $script:Diagnostico | Add-Member -NotePropertyName ContextMenuRealCount -NotePropertyValue $count -Force -EA 0
    return $count -le 15
}
function Optimize-MenuContextual {
    # Desactiva entradas huerfanas (apuntan a DLLs que ya no existen)
    $removidos = 0
    foreach ($base in @("HKCR\*\shellex\ContextMenuHandlers","HKCR\Directory\shellex\ContextMenuHandlers","HKCR\Folder\shellex\ContextMenuHandlers")) {
        $subkeys = reg query $base 2>$null | Where-Object { $_ -match "^HKEY" }
        foreach ($sk in $subkeys) {
            $val = (reg query $sk 2>$null | Where-Object { $_ -match "REG_SZ" } | Select-Object -First 1)
            if ($val -match "\{(.+)\}") {
                $clsid = $Matches[0]
                $dllPath = (reg query "HKCR\CLSID\$clsid\InProcServer32" /ve 2>$null | Where-Object { $_ -match "REG_" } | Select-Object -First 1)
                if ($dllPath -match "REG_\w+\s+(.+)$") {
                    $dll = $Matches[1].Trim()
                    if ($dll -and -not (Test-Path $dll)) {
                        reg delete $sk /f 2>$null | Out-Null
                        $removidos++
                    }
                }
            }
        }
    }
    Write-Log "  $removidos entradas huerfanas del menu contextual eliminadas" "Green"
    return $true
}

function Check-IconCache {
    $icdb = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db"
    $size = (Get-ChildItem $icdb -EA 0 | Measure-Object Length -Sum).Sum
    return ($null -eq $size -or $size -lt 50MB)
}
function Optimize-IconCache {
    $exp = ($null -ne (Get-Process explorer -EA 0))
    if ($exp) { Stop-Process -Name explorer -Force -EA 0; Start-Sleep -Milliseconds 600 }
    $count = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -EA 0).Count
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force -EA 0
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -EA 0
    if ($exp) { Start-Process explorer }
    Write-Log "  Cache de iconos y miniaturas regenerada ($count archivos)" "Green"
    return $true
}

function Check-FontCache {
    $svc = Get-Service -Name "FontCache" -EA 0
    $fdir = "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache"
    $size = if(Test-Path $fdir){(Get-ChildItem $fdir -File -EA 0 | Measure-Object Length -Sum).Sum}else{0}
    return ($size -lt 100MB)
}
function Optimize-FontCache {
    Stop-Service FontCache -Force -EA 0; Stop-Service "FontCache3.0.0.0" -Force -EA 0
    $dirs = @(
        "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache",
        "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache-System"
    )
    $count = 0
    foreach ($d in $dirs) { if (Test-Path $d) { $count += (Get-ChildItem $d -File -EA 0).Count; Remove-Item "$d\*" -Force -EA 0 } }
    Start-Service FontCache -EA 0
    Write-Log "  Cache de fuentes limpiada y regenerada ($count archivos)" "Green"
    return $true
}

# ── DISCO / ESCRITURA CONTINUA ────────────────────────────────────────────────

function Check-Indexacion {
    # En HDD la indexacion agresiva destruye el rendimiento
    if ($script:Diagnostico.TieneSSD) { return $true }  # En SSD no es problema
    $svc = Get-Service -Name "WSearch" -EA 0
    return ($null -eq $svc -or $svc.StartType -eq "Disabled")
}
function Optimize-Indexacion {
    if ($script:Diagnostico.TieneSSD) { Write-Log "  SSD detectado — indexacion no es problema" "TextDim"; return $true }
    try {
        Stop-Service WSearch -Force -EA 0
        Set-Service WSearch -StartupType Disabled -EA Stop
        # Deshabilitar indexacion en todas las unidades
        foreach ($drive in (Get-PSDrive -PSProvider FileSystem -EA 0 | Where-Object { $_.Root -match "^[A-Z]:\\" })) {
            $path = $drive.Root
            $shell = New-Object -ComObject Shell.Application -EA 0
            if ($shell) {
                try { $folder = $shell.Namespace($path); if($folder){$folder.Self.InvokeVerb("IndexingOptions")}} catch {}
            }
        }
        Write-Log "  Indexacion de Windows Search desactivada (HDD detectado)" "Green"; return $true
    } catch { Write-Log "  Error al desactivar indexacion: $_" "Red"; return $false }
}

function Check-Superfetch {
    $svc = Get-Service -Name "SysMain" -EA 0
    if ($null -eq $svc) { return $true }
    # En SSD SysMain debe estar desactivado (escribe innecesariamente)
    # En HDD puede ayudar, pero con poca RAM perjudica
    if ($script:Diagnostico.TieneSSD) { return $svc.StartType -eq "Disabled" }
    if ($script:Diagnostico.RAMTotalGB -lt 6) { return $svc.StartType -eq "Disabled" }
    return $true
}
function Optimize-Superfetch {
    $svc = Get-Service -Name "SysMain" -EA 0
    if ($null -eq $svc) { Write-Log "  SysMain no encontrado" "TextDim"; return $true }
    if ($script:Diagnostico.TieneSSD) {
        Stop-Service SysMain -Force -EA 0; Set-Service SysMain -StartupType Disabled -EA Stop
        Write-Log "  SysMain desactivado — en SSD genera escritura innecesaria" "Green"; return $true
    }
    if ($script:Diagnostico.RAMTotalGB -lt 6) {
        Stop-Service SysMain -Force -EA 0; Set-Service SysMain -StartupType Disabled -EA Stop
        Write-Log "  SysMain desactivado — con poca RAM consume mas de lo que ayuda" "Green"; return $true
    }
    return $true
}

function Check-Hibernacion {
    return (-not (Test-Path "$env:SystemRoot\hiberfil.sys"))
}
function Optimize-Hibernacion {
    powercfg /hibernate off 2>$null
    if (-not (Test-Path "$env:SystemRoot\hiberfil.sys")) {
        Write-Log "  Hibernacion desactivada — hiberfil.sys eliminado" "Green"; return $true
    }
    Write-Log "  No se pudo eliminar hiberfil.sys" "Yellow"; return $false
}

function Check-Pagefile {
    $pf = Get-CimInstance Win32_PageFileSetting -EA 0
    if ($null -eq $pf) { return $true }
    # Malo: InitialSize=0 y MaximumSize=0 (Windows lo maneja automatico pero redimensiona constantemente)
    $primero = $pf | Select-Object -First 1
    return ($primero.InitialSize -gt 0 -and $primero.MaximumSize -gt 0)
}
function Optimize-Pagefile {
    try {
        $ram = [math]::Round($script:Diagnostico.RAMTotalGB * 1024)
        # Inicial: 1x RAM, Maximo: 2x RAM (evita redimensionamiento constante)
        $inicial = [math]::Max(1024, $ram)
        $maximo  = [math]::Max(2048, $ram * 2)
        $cs = Get-CimInstance Win32_ComputerSystem -EA Stop
        $cs.AutomaticManagedPagefile = $false
        Set-CimInstance -CimInstance $cs -EA 0
        $pf = Get-CimInstance Win32_PageFileSetting -EA 0
        if ($pf) {
            $pf | ForEach-Object { $_.InitialSize = $inicial; $_.MaximumSize = $maximo; Set-CimInstance -CimInstance $_ -EA 0 }
        } else {
            New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="$env:SystemDrive\pagefile.sys";InitialSize=$inicial;MaximumSize=$maximo} -EA 0 | Out-Null
        }
        Write-Log "  Pagefile fijo: $($inicial)MB inicial / $($maximo)MB maximo — sin redimensionamiento" "Green"; return $true
    } catch { Write-Log "  No se pudo configurar el pagefile: $_" "Red"; return $false }
}

# ── REGISTRO ──────────────────────────────────────────────────────────────────

function Check-LatenciaRegistro {
    return ($script:Diagnostico.LatenciaRegMs -lt 50)
}
function Optimize-LatenciaRegistro {
    try {
        # Compact del registro — reduce fragmentacion interna
        $tempReg = "$env:TEMP\wdm_reg_compact.bat"
        @"
@echo off
reg export HKLM "$env:TEMP\hklm_backup_compact.reg" /y >nul 2>&1
"@ | Out-File $tempReg -Encoding ASCII
        # Limpiar MRU y entradas de arranque huerfanas
        $runKeys = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        )
        $huerfanos = 0
        foreach ($rk in $runKeys) {
            if (Test-Path $rk) {
                $props = Get-ItemProperty $rk -EA 0
                foreach ($prop in ($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" })) {
                    $val = $prop.Value -replace '"','' -replace "'",''
                    $exe = ($val -split ' ')[0].Trim()
                    if ($exe -and -not (Test-Path $exe) -and $exe -notmatch "^%") {
                        Remove-ItemProperty $rk -Name $prop.Name -EA 0
                        $huerfanos++
                    }
                }
            }
        }
        # Limpiar uninstall entries huerfanas
        $uninstKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $removed = 0
        if (Test-Path $uninstKey) {
            Get-ChildItem $uninstKey -EA 0 | ForEach-Object {
                $inst = (Get-ItemProperty $_.PSPath -Name "InstallLocation" -EA 0).InstallLocation
                if ($inst -and $inst.Length -gt 3 -and -not (Test-Path $inst)) {
                    Remove-Item $_.PSPath -Recurse -Force -EA 0; $removed++
                }
            }
        }
        Write-Log "  Registro limpiado: $huerfanos entradas de arranque huerfanas, $removed desinstaladores fantasma" "Green"
        return $true
    } catch { Write-Log "  Error limpiando registro: $_" "Red"; return $false }
}

function Check-EntradasArranque {
    $huerfanos = 0
    foreach ($rk in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")) {
        if (Test-Path $rk) {
            $props = Get-ItemProperty $rk -EA 0
            foreach ($prop in ($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" })) {
                $exe = ($prop.Value -replace '"','' -split ' ')[0].Trim()
                if ($exe -and -not (Test-Path $exe) -and $exe -notmatch "^%" -and $exe -notmatch "^[A-Z]{1}:\\Windows") {
                    $huerfanos++
                }
            }
        }
    }
    $script:Diagnostico | Add-Member -NotePropertyName EntradasHuerfanas -NotePropertyValue $huerfanos -Force -EA 0
    return $huerfanos -eq 0
}

# ── WMI ───────────────────────────────────────────────────────────────────────

function Check-WMI {
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Get-CimInstance Win32_OperatingSystem -EA Stop
        $sw.Stop()
        $script:Diagnostico | Add-Member -NotePropertyName WMILatenciaMs -NotePropertyValue ([math]::Round($sw.Elapsed.TotalMilliseconds)) -Force -EA 0
        return $sw.Elapsed.TotalMilliseconds -lt 3000
    } catch {
        $script:Diagnostico | Add-Member -NotePropertyName WMILatenciaMs -NotePropertyValue 9999 -Force -EA 0
        return $false
    }
}
function Optimize-WMI {
    Write-Log "  Reconstruyendo repositorio WMI..." "Yellow"
    try {
        Stop-Service winmgmt -Force -EA 0; Start-Sleep -Milliseconds 500
        $wmiDir = "$env:SystemRoot\System32\wbem"
        $result = & "$wmiDir\winmgmt.exe" /resetrepository 2>&1
        Start-Service winmgmt -EA 0; Start-Sleep -Milliseconds 800
        # Recompilar MOFs
        Get-ChildItem "$wmiDir\*.mof" -EA 0 | ForEach-Object {
            & "$wmiDir\mofcomp.exe" $_.FullName 2>$null | Out-Null
        }
        Write-Log "  WMI reconstruido correctamente" "Green"; return $true
    } catch { Write-Log "  Error reconstruyendo WMI: $_" "Red"; return $false }
}

# ============================================================================
#  LIMPIEZAS — GetSize (retorna bytes para ordenar) / GetSizeStr / Clear
# ============================================================================
function Get-RecycleBinBytes {
    try {
        $shell = New-Object -ComObject Shell.Application
        $rb = $shell.Namespace(10); $sz = 0
        foreach ($item in $rb.Items()) { try { $sz += $rb.GetDetailsOf($item,21) -replace '[^\d]','' -as [long] } catch {} }
        return [long]$sz
    } catch { return 0 }
}
function Get-RecycleBinSize { $b=Get-RecycleBinBytes; return Format-Bytes $b }
function Clear-RecycleBin {
    try { [RecycleBinHelper]::Empty() } catch { Remove-Item "C:\`$Recycle.Bin\*" -Recurse -Force -EA 0 }
    Write-Log "  Papelera vaciada" "Green"; return $true
}

function Get-WUCacheBytes {
    $p="$env:SystemRoot\SoftwareDistribution\Download"
    if (Test-Path $p) { return [long](Get-ChildItem $p -Recurse -File -EA 0|Measure-Object Length -Sum).Sum }
    return 0
}
function Get-WUCacheSize { return Format-Bytes (Get-WUCacheBytes) }
function Clear-WUCache {
    Stop-Service wuauserv -Force -EA 0; Stop-Service bits -Force -EA 0; Start-Sleep -Milliseconds 500
    $p="$env:SystemRoot\SoftwareDistribution"
    $bk="$p.old.$(Get-Date -Format 'yyyyMMddHHmmss')"
    if (Test-Path $p) { try{Move-Item $p $bk -Force -EA Stop}catch{Remove-Item "$p\Download\*" -Recurse -Force -EA 0} }
    New-Item "$p\Download" -ItemType Directory -Force|Out-Null
    Start-Service wuauserv -EA 0; Start-Service bits -EA 0
    Write-Log "  Cache de Windows Update limpiada" "Green"; return $true
}

function Get-TempFilesBytes {
    $total=0
    foreach ($p in @($env:TEMP,"$env:SystemRoot\Temp")) {
        if (Test-Path $p) { $s=(Get-ChildItem $p -Recurse -File -EA 0|Measure-Object Length -Sum).Sum; if($s){$total+=[long]$s} }
    }
    return $total
}
function Get-TempFilesSize { return Format-Bytes (Get-TempFilesBytes) }
function Clear-TempFiles {
    $count=0
    foreach ($p in @("$env:TEMP\*","$env:SystemRoot\Temp\*")) {
        $count+=(Get-ChildItem $p -Recurse -File -EA 0).Count
        Remove-Item $p -Recurse -Force -EA 0
    }
    Write-Log "  $count archivos temporales eliminados" "Green"; return $true
}

function Get-ThumbCacheBytes {
    $p="$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    if (Test-Path $p) { return [long](Get-ChildItem "$p\thumbcache_*.db" -EA 0|Measure-Object Length -Sum).Sum }
    return 0
}
function Get-ThumbCacheSize { return Format-Bytes (Get-ThumbCacheBytes) }
function Clear-ThumbCache {
    $exp=($null -ne (Get-Process explorer -EA 0))
    if ($exp) { Stop-Process -Name explorer -Force -EA 0; Start-Sleep -Milliseconds 500 }
    $count=(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -EA 0).Count
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -EA 0
    if ($exp) { Start-Process explorer }
    Write-Log "  $count archivos de miniaturas eliminados" "Green"; return $true
}

function Get-CrashDumpsBytes {
    $total=0
    foreach ($p in @("$env:SystemRoot\Minidump","$env:LOCALAPPDATA\CrashDumps","$env:SystemRoot\MEMORY.DMP")) {
        if (Test-Path $p) { $s=(Get-ChildItem $p -Recurse -File -EA 0|Measure-Object Length -Sum).Sum; if($s){$total+=[long]$s} }
    }
    return $total
}
function Get-CrashDumpsSize { return Format-Bytes (Get-CrashDumpsBytes) }
function Clear-CrashDumps {
    $count=0
    foreach ($p in @("$env:SystemRoot\Minidump\*","$env:LOCALAPPDATA\CrashDumps\*")) {
        $count+=(Get-ChildItem $p -File -EA 0).Count; Remove-Item $p -Force -EA 0
    }
    if (Test-Path "$env:SystemRoot\MEMORY.DMP") { Remove-Item "$env:SystemRoot\MEMORY.DMP" -Force -EA 0; $count++ }
    Write-Log "  $count volcados de error eliminados" "Green"; return $true
}

function Get-InstallerLogsBytes {
    $total=0
    foreach ($p in @("$env:SystemRoot\Logs\CBS","$env:SystemRoot\INF","$env:TEMP")) {
        if (Test-Path $p) { $s=(Get-ChildItem $p -Filter "*.log" -File -EA 0|Measure-Object Length -Sum).Sum; if($s){$total+=[long]$s} }
    }
    return $total
}
function Get-InstallerLogsSize { return Format-Bytes (Get-InstallerLogsBytes) }
function Clear-InstallerLogs {
    $count=0
    foreach ($p in @("$env:SystemRoot\Logs\CBS\*.log","$env:SystemRoot\INF\*.log","$env:TEMP\*.log")) {
        $count+=(Get-ChildItem $p -File -EA 0).Count; Remove-Item $p -Force -EA 0
    }
    Write-Log "  $count logs de instaladores eliminados" "Green"; return $true
}

function Get-BrowserCacheBytes {
    $total=0
    foreach ($p in @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:APPDATA\Mozilla\Firefox\Profiles"
    )) { if (Test-Path $p) { $s=(Get-ChildItem $p -Recurse -File -EA 0|Measure-Object Length -Sum).Sum; if($s){$total+=[long]$s} } }
    return $total
}
function Get-BrowserCacheSize { return Format-Bytes (Get-BrowserCacheBytes) }
function Clear-BrowserCache {
    $count=0
    foreach ($p in @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*"
    )) { $count+=(Get-ChildItem $p -Recurse -File -EA 0).Count; Remove-Item $p -Recurse -Force -EA 0 }
    Write-Log "  Cache de navegadores limpiada ($count archivos)" "Green"; return $true
}

function Get-StoreCacheBytes {
    $p="$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache"
    if (Test-Path $p) { return [long](Get-ChildItem $p -Recurse -File -EA 0|Measure-Object Length -Sum).Sum }
    return 0
}
function Get-StoreCacheSize { return Format-Bytes (Get-StoreCacheBytes) }
function Clear-StoreCache {
    wsreset.exe 2>$null
    Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache\*" -Recurse -Force -EA 0
    Write-Log "  Cache de Microsoft Store limpiada" "Green"; return $true
}

function Get-PrefetchBytes {
    $p="$env:SystemRoot\Prefetch"
    if (Test-Path $p) { return [long](Get-ChildItem $p -File -EA 0|Measure-Object Length -Sum).Sum }
    return 0
}
function Get-PrefetchSize { return Format-Bytes (Get-PrefetchBytes) }
function Clear-Prefetch {
    $count=(Get-ChildItem "$env:SystemRoot\Prefetch\*.pf" -EA 0).Count
    Remove-Item "$env:SystemRoot\Prefetch\*.pf" -Force -EA 0
    Write-Log "  $count archivos prefetch eliminados" "Green"; return $true
}

function Get-TmpSueltosBytes {
    $total=0
    foreach ($p in @("$env:USERPROFILE","$env:SystemDrive\")) {
        $s=(Get-ChildItem $p -Filter "*.tmp" -File -EA 0|Measure-Object Length -Sum).Sum
        if ($s) { $total+=[long]$s }
    }
    return $total
}
function Get-TmpSueltosSize { return Format-Bytes (Get-TmpSueltosBytes) }
function Clear-TmpSueltos {
    $count = 0
    foreach ($p in @("$env:USERPROFILE","$env:SystemDrive\")) {
        $archivos = Get-ChildItem $p -Filter "*.tmp" -File -EA 0
        foreach ($f in $archivos) {
            try {
                Remove-Item $f.FullName -Force -EA Stop
                $count++
            } catch {
                # Archivo en uso por el sistema (ej: DumpStack.log.tmp) — se ignora silenciosamente
            }
        }
    }
    Write-Log "  $count archivos .tmp sueltos eliminados" "Green"; return $true
}

function Get-ExplorerHistBytes { return 0 }
function Get-ExplorerHistSize  { return "Historial" }
function Clear-ExplorerHist {
    Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -EA 0
    Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" -EA 0
    $rp="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $rp) { Get-ChildItem $rp -EA 0|Remove-Item -Recurse -Force -EA 0 }
    Write-Log "  Historial del Explorador limpiado" "Green"; return $true
}

function Get-SearchHistBytes { return 0 }
function Get-SearchHistSize  { return "Historial" }
function Clear-SearchHist {
    $k="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (Test-Path $k) { Set-ItemProperty $k -Name "BingSearchEnabled" -Value 0 -Type DWord -EA 0 }
    $db="$env:LOCALAPPDATA\Microsoft\Windows\Explorer\SearchHistory"
    if (Test-Path $db) { Remove-Item "$db\*" -Recurse -Force -EA 0 }
    Write-Log "  Historial de busqueda limpiado" "Green"; return $true
}

function Get-DNSCacheBytes { return 0 }
function Get-DNSCacheSize  { return "Cache" }
function Clear-DNSCache {
    ipconfig /flushdns 2>&1|Out-Null
    Write-Log "  Cache DNS vaciada" "Green"; return $true
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -gt 1GB) { return "{0:N2} GB" -f ($Bytes/1GB) }
    if ($Bytes -gt 1MB) { return "{0:N0} MB" -f ($Bytes/1MB) }
    if ($Bytes -gt 1KB) { return "{0:N0} KB" -f ($Bytes/1KB) }
    if ($Bytes -gt 0)   { return "$Bytes B" }
    return "< 1 KB"
}

# ============================================================================
#  PRIVACIDAD
# ============================================================================
function Load-PrivacidadItems {
    return @(
        @{
            Nombre="ID de Publicidad"
            Func={ $k="HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}; Set-ItemProperty $k -Name "Enabled" -Value 0 -Type DWord -EA 0; Write-Log "  ID de publicidad desactivado" "Green"; return $true }
            Check={ (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -EA 0).Enabled -eq 0 }
            Explicacion="Windows le asigna un ID a tu PC para que las apps te rastreen entre ellas. Al apagarlo deja de ser parte de esa red de seguimiento. No cambia nada en el uso diario."
        },
        @{
            Nombre="Bloquear Ubicacion"
            Func={ $k="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}; Set-ItemProperty $k -Name "Value" -Value "Deny" -Type String -EA 0; Write-Log "  Acceso a ubicacion bloqueado" "Green"; return $true }
            Check={ (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -EA 0).Value -eq "Deny" }
            Explicacion="Apps pueden pedirle a Windows tu ubicacion GPS. Si no usas nada que la necesite (clima, mapas) es mejor bloquearla. Las apps que la necesiten van a pedirte permiso igual."
        },
        @{
            Nombre="Telemetria de diagnostico"
            Func={
                Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -EA 0
                Stop-Service DiagTrack -Force -EA 0; Set-Service DiagTrack -StartupType Disabled -EA 0
                Write-Log "  Telemetria desactivada" "Green"; return $true
            }
            Check={ (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -EA 0).AllowTelemetry -eq 0 }
            Explicacion="Windows manda constantemente datos de como usas la PC a Microsoft. Esto lo corta sin afectar actualizaciones ni el funcionamiento normal."
        },
        @{
            Nombre="Historial de actividad"
            Func={
                $k="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}
                Set-ItemProperty $k -Name "EnableActivityFeed"    -Value 0 -Type DWord -EA 0
                Set-ItemProperty $k -Name "PublishUserActivities" -Value 0 -Type DWord -EA 0
                Set-ItemProperty $k -Name "UploadUserActivities"  -Value 0 -Type DWord -EA 0
                Write-Log "  Historial de actividad desactivado" "Green"; return $true
            }
            Check={ (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -EA 0).EnableActivityFeed -eq 0 }
            Explicacion="Windows guarda todo lo que haces (apps abiertas, archivos vistos) y puede subirlo a la nube de Microsoft. Esto borra y desactiva ese historial completamente."
        },
        @{
            Nombre="Acceso al Microfono"
            Func={ $k="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"; if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}; Set-ItemProperty $k -Name "Value" -Value "Deny" -Type String -EA 0; Write-Log "  Microfono bloqueado para apps" "Green"; return $true }
            Check={ (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" -Name "Value" -EA 0).Value -eq "Deny" }
            Explicacion="Bloquea el acceso al microfono para apps en general. Zoom, Teams y Meet te van a pedir permiso de forma explicita cuando los necesiten, eso sigue funcionando normalmente."
        },
        @{
            Nombre="Acceso a la Camara"
            Func={ $k="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"; if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}; Set-ItemProperty $k -Name "Value" -Value "Deny" -Type String -EA 0; Write-Log "  Camara bloqueada para apps" "Green"; return $true }
            Check={ (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" -Name "Value" -EA 0).Value -eq "Deny" }
            Explicacion="Bloquea el acceso a la camara para apps en general. Las apps que la necesiten (videollamadas) te van a pedir permiso igual cuando las uses."
        },
        @{
            Nombre="Busqueda Bing en inicio"
            Func={ $k="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}; Set-ItemProperty $k -Name "BingSearchEnabled" -Value 0 -Type DWord -EA 0; Set-ItemProperty $k -Name "CortanaConsent" -Value 0 -Type DWord -EA 0; Write-Log "  Bing desactivado del menu inicio" "Green"; return $true }
            Check={ (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -EA 0).BingSearchEnabled -eq 0 }
            Explicacion="Cuando buscas en el menu inicio, Windows manda lo que escribis a Bing (internet). Con esto la busqueda queda solo en tu PC, sin enviar nada afuera."
        }
    )
}

# ============================================================================
#  REPARACIONES
# ============================================================================
function Show-ProgressDialog {
    param([string]$Titulo, [array]$Pasos, [array]$Explicaciones)
    $pf=New-Object System.Windows.Forms.Form
    $pf.Text=$Titulo; $pf.Size=New-Object System.Drawing.Size(620,280)
    $pf.StartPosition="CenterScreen"; $pf.ControlBox=$false
    $pf.TopMost=$true; $pf.BackColor=$script:colors.BgCard

    $pb=New-Object System.Windows.Forms.ProgressBar
    $pb.Location=New-Object System.Drawing.Point(20,20); $pb.Size=New-Object System.Drawing.Size(560,28)
    $pb.Minimum=0; $pb.Maximum=100; $pb.Value=0

    $lPaso=New-Object System.Windows.Forms.Label
    $lPaso.Location=New-Object System.Drawing.Point(20,60); $lPaso.Size=New-Object System.Drawing.Size(560,20)
    $lPaso.Text="Arrancando..."; $lPaso.Font=$fonts.BodyBold; $lPaso.ForeColor=$script:colors.TextPrimary

    $lExpl=New-Object System.Windows.Forms.Label
    $lExpl.Location=New-Object System.Drawing.Point(20,88); $lExpl.Size=New-Object System.Drawing.Size(560,80)
    $lExpl.Font=$fonts.Body; $lExpl.ForeColor=$script:colors.TextSecond

    $bCancel=New-Object System.Windows.Forms.Button
    $bCancel.Text="PARA, ME ARREPENTI"
    $bCancel.Location=New-Object System.Drawing.Point(460,215); $bCancel.Size=New-Object System.Drawing.Size(140,30)
    $bCancel.BackColor=$script:colors.Red; $bCancel.ForeColor=$script:colors.TextPrimary
    $bCancel.FlatStyle="Flat"; $bCancel.FlatAppearance.BorderSize=0
    $bCancel.Add_Click({$script:CancelarReparacion=$true})

    $pf.Controls.AddRange(@($pb,$lPaso,$lExpl,$bCancel))
    $pf.Show(); [System.Windows.Forms.Application]::DoEvents()

    $total=$Pasos.Count
    for ($i=0; $i -lt $total; $i++) {
        if ($script:CancelarReparacion) { break }
        $li=$i
        $pb.Value=[math]::Round(($li/$total)*100)
        $lPaso.Text="Paso $($li+1) de $total  —  $($Pasos[$li].Nombre)"
        $lExpl.Text=$Explicaciones[$li]
        [System.Windows.Forms.Application]::DoEvents()
        try { & $Pasos[$li].Comando } catch { Write-Log "  Error en $($Pasos[$li].Nombre): $_" "Orange" }
        [System.Windows.Forms.Application]::DoEvents()
    }
    $pb.Value=100; [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 400; $pf.Close()
}

function Invoke-Reparaciones {
    param([array]$Seleccionadas)
    $script:CancelarReparacion=$false
    $pasos=@(); $expls=@()
    if ("chkdsk" -in $Seleccionadas) {
        $pasos+=@{Nombre="CHKDSK — Programando revision del disco";Comando={
            $ans=if((Get-Culture).TwoLetterISOLanguageName -eq "es"){"S"}else{"Y"}
            cmd /c "echo $ans | chkdsk $env:SystemDrive /f /r" 2>&1|ForEach-Object{Write-Log "    $_" "TextDim"}
            Write-Log "  CHKDSK correra al proximo reinicio." "Yellow"
        }}
        $expls+="CHKDSK revisa y repara el disco duro a nivel fisico. Corre antes de que Windows cargue, al reiniciar."
    }
    if ("dism" -in $Seleccionadas) {
        $pasos+=@{Nombre="DISM — Restaurando imagen del sistema";Comando={
            Write-Log "  Iniciando DISM — necesita internet y puede tardar varios minutos..." "Yellow"

            $dismForm = New-Object System.Windows.Forms.Form
            $dismForm.Text = "DISM — Restaurando imagen del sistema"
            $dismForm.Size = New-Object System.Drawing.Size(580, 200)
            $dismForm.StartPosition = "CenterScreen"
            $dismForm.ControlBox = $false
            $dismForm.TopMost = $true
            $dismForm.BackColor = $script:colors.BgCard

            $dismLblTitulo = New-Object System.Windows.Forms.Label
            $dismLblTitulo.Location = New-Object System.Drawing.Point(20, 18)
            $dismLblTitulo.Size = New-Object System.Drawing.Size(540, 20)
            $dismLblTitulo.Text = "Restaurando imagen del sistema desde servidores de Microsoft..."
            $dismLblTitulo.Font = $fonts.BodyBold
            $dismLblTitulo.ForeColor = $script:colors.Accent

            $dismPb = New-Object System.Windows.Forms.ProgressBar
            $dismPb.Location = New-Object System.Drawing.Point(20, 48)
            $dismPb.Size = New-Object System.Drawing.Size(540, 24)
            $dismPb.Minimum = 0
            $dismPb.Maximum = 100
            $dismPb.Value = 0

            $dismLblPct = New-Object System.Windows.Forms.Label
            $dismLblPct.Location = New-Object System.Drawing.Point(20, 80)
            $dismLblPct.Size = New-Object System.Drawing.Size(540, 20)
            $dismLblPct.Text = "Conectando con servidores de Microsoft..."
            $dismLblPct.Font = $fonts.Body
            $dismLblPct.ForeColor = $script:colors.TextSecond

            $dismLblEstado = New-Object System.Windows.Forms.Label
            $dismLblEstado.Location = New-Object System.Drawing.Point(20, 106)
            $dismLblEstado.Size = New-Object System.Drawing.Size(540, 40)
            $dismLblEstado.Font = $fonts.Small
            $dismLblEstado.ForeColor = $script:colors.TextDim
            $dismLblEstado.Text = "DISM descarga archivos limpios desde Microsoft. Necesita internet activo."

            $dismForm.Controls.AddRange(@($dismLblTitulo, $dismPb, $dismLblPct, $dismLblEstado))
            $dismForm.Show()
            [System.Windows.Forms.Application]::DoEvents()

            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "dism.exe"
            $psi.Arguments = "/online /cleanup-image /restorehealth"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.CreateNoWindow = $true
            $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8

            $dismProc = New-Object System.Diagnostics.Process
            $dismProc.StartInfo = $psi
            $dismProc.Start() | Out-Null

            while (-not $dismProc.StandardOutput.EndOfStream) {
                $linea = $dismProc.StandardOutput.ReadLine()
                if (-not $linea) { continue }
                Write-Log "    $linea" "TextDim"
                # DISM imprime "[ ==  10.0% ] " etc.
                if ($linea -match "\[\s*[=\s]*\s*(\d+\.?\d*)\s*%\s*\]") {
                    $pct = [math]::Min(100, [int][double]$Matches[1])
                    $dismPb.Value = $pct
                    $dismLblPct.Text = "$pct% completado..."
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }

            $dismProc.WaitForExit()
            $dismPb.Value = 100
            $dismLblPct.Text = "100% — DISM completado"
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 800
            $dismForm.Close()

            if ($dismProc.ExitCode -eq 0) {
                Write-Log "  DISM completado correctamente." "Green"
            } else {
                Write-Log "  DISM termino con advertencias (codigo $($dismProc.ExitCode))." "Orange"
                Write-Log "  Revisa tu conexion a internet y volvelo a intentar si es necesario." "Yellow"
            }
        }}
        $expls+="DISM descarga y reemplaza archivos del sistema danados desde servidores de Microsoft. Necesita internet."
    }
    if ("sfc" -in $Seleccionadas) {
        $pasos+=@{Nombre="SFC — Verificando archivos del sistema";Comando={
            # SFC emite Unicode de ancho completo — hay que leerlo con OutputDataReceived
            # y parsear el porcentaje que el mismo SFC imprime en cada linea
            Write-Log "  Iniciando SFC — puede tardar varios minutos..." "Yellow"

            # Dialogo dedicado para SFC con barra animada en tiempo real
            $sfcForm = New-Object System.Windows.Forms.Form
            $sfcForm.Text = "SFC — Verificando archivos del sistema"
            $sfcForm.Size = New-Object System.Drawing.Size(580, 200)
            $sfcForm.StartPosition = "CenterScreen"
            $sfcForm.ControlBox = $false
            $sfcForm.TopMost = $true
            $sfcForm.BackColor = $script:colors.BgCard

            $sfcLblTitulo = New-Object System.Windows.Forms.Label
            $sfcLblTitulo.Location = New-Object System.Drawing.Point(20, 18)
            $sfcLblTitulo.Size = New-Object System.Drawing.Size(540, 20)
            $sfcLblTitulo.Text = "Escaneando archivos del sistema de Windows..."
            $sfcLblTitulo.Font = $fonts.BodyBold
            $sfcLblTitulo.ForeColor = $script:colors.Accent

            $sfcPb = New-Object System.Windows.Forms.ProgressBar
            $sfcPb.Location = New-Object System.Drawing.Point(20, 48)
            $sfcPb.Size = New-Object System.Drawing.Size(540, 24)
            $sfcPb.Minimum = 0
            $sfcPb.Maximum = 100
            $sfcPb.Value = 0
            $sfcPb.Style = "Continuous"

            $sfcLblPct = New-Object System.Windows.Forms.Label
            $sfcLblPct.Location = New-Object System.Drawing.Point(20, 80)
            $sfcLblPct.Size = New-Object System.Drawing.Size(540, 20)
            $sfcLblPct.Text = "0% completado..."
            $sfcLblPct.Font = $fonts.Body
            $sfcLblPct.ForeColor = $script:colors.TextSecond

            $sfcLblEstado = New-Object System.Windows.Forms.Label
            $sfcLblEstado.Location = New-Object System.Drawing.Point(20, 106)
            $sfcLblEstado.Size = New-Object System.Drawing.Size(540, 40)
            $sfcLblEstado.Font = $fonts.Small
            $sfcLblEstado.ForeColor = $script:colors.TextDim
            $sfcLblEstado.Text = "SFC verifica cada archivo protegido de Windows. No cierres esta ventana."

            $sfcForm.Controls.AddRange(@($sfcLblTitulo, $sfcPb, $sfcLblPct, $sfcLblEstado))
            $sfcForm.Show()
            [System.Windows.Forms.Application]::DoEvents()

            # Correr SFC como proceso con redireccion de stdout (Unicode)
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "$env:SystemRoot\System32\sfc.exe"
            $psi.Arguments = "/scannow"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.CreateNoWindow = $true
            # SFC escribe en Unicode (UTF-16 LE) — sin esto sale basura
            $psi.StandardOutputEncoding = [System.Text.Encoding]::Unicode

            $sfcProc = New-Object System.Diagnostics.Process
            $sfcProc.StartInfo = $psi

            $sfcResultado = "No se pudo leer el resultado"
            $sfcProc.Start() | Out-Null

            while (-not $sfcProc.StandardOutput.EndOfStream) {
                $linea = $sfcProc.StandardOutput.ReadLine()
                if (-not $linea) { continue }

                Write-Log "    $linea" "TextDim"

                # Parsear el porcentaje que SFC mismo imprime: "Verificación 45% completada."
                if ($linea -match "(\d{1,3})\s*%") {
                    $pct = [int]$Matches[1]
                    if ($pct -ge 0 -and $pct -le 100) {
                        $sfcPb.Value = $pct
                        $sfcLblPct.Text = "$pct% completado..."
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                }

                # Capturar linea de resultado final
                if ($linea -match "no encontro|did not find|encontro y reparo|found corrupt|no pudo|could not") {
                    $sfcResultado = $linea.Trim()
                }
            }

            $sfcProc.WaitForExit()
            $sfcPb.Value = 100
            $sfcLblPct.Text = "100% — Escaneo completado"
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 800
            $sfcForm.Close()

            # Leer el log real que deja SFC en CBS.log para el resultado definitivo
            $cbsLog = "$env:SystemRoot\Logs\CBS\CBS.log"
            if (Test-Path $cbsLog) {
                $cbsLineas = Get-Content $cbsLog -Tail 30 -EA 0
                $sfcSummary = $cbsLineas | Where-Object { $_ -match "Successfully repaired|could not be repaired|did not find any integrity|no encontro ninguna" } | Select-Object -Last 1
                if ($sfcSummary) { $sfcResultado = $sfcSummary.Trim() }
            }

            # Mostrar resultado con color segun que encontro
            if ($sfcResultado -match "reparo|repaired") {
                Write-Log "  SFC reparo archivos danados." "Orange"
                Write-Log "  Reinicia para que los cambios tomen efecto." "Yellow"
            } elseif ($sfcResultado -match "no encontro|did not find|integrity violations") {
                Write-Log "  SFC no encontro archivos danados — el sistema esta limpio." "Green"
            } elseif ($sfcResultado -match "no pudo|could not") {
                Write-Log "  SFC encontro archivos que no pudo reparar — ejecuta DISM primero." "Red"
            } else {
                Write-Log "  SFC completado. Revisa Reparacion > CBS.log para mas detalles." "TextDim"
            }
        }}
        $expls+="SFC escanea y repara archivos de Windows protegidos que esten danados o falten."
    }
    if ("network" -in $Seleccionadas) {
        $pasos+=@{Nombre="Reset de red";Comando={
            netsh int ip reset  2>&1|ForEach-Object{Write-Log "    $_" "TextDim"}
            netsh winsock reset 2>&1|ForEach-Object{Write-Log "    $_" "TextDim"}
            ipconfig /flushdns  2>&1|ForEach-Object{Write-Log "    $_" "TextDim"}
        }}
        $expls+="Reinicia la pila de red de Windows. Puede interrumpir la conexion un momento."
    }
    if ($pasos.Count -eq 0) { return }
    Show-ProgressDialog -Titulo "Reparando el sistema..." -Pasos $pasos -Explicaciones $expls
    Write-Log ""
    if ($script:CancelarReparacion) {
        Write-Log "Cancelaste. Lo que ya corrio quedo aplicado." "Yellow"
        Set-Status "Reparacion cancelada" "Yellow"
    } else {
        Write-Log "Reparaciones terminadas." "Green"
        if ("chkdsk" -in $Seleccionadas) { Write-Log "  Reinicia para que CHKDSK actue sobre el disco." "Yellow" }
        if ("network" -in $Seleccionadas) { Write-Log "  Reinicia para aplicar los cambios de red." "Yellow" }
        Set-Status "Reparaciones completadas" "Green"
    }
}

# ============================================================================
#  INTERFAZ
# ============================================================================
$form=New-Object System.Windows.Forms.Form
$form.Text="Windows De Mente v2.0"
$form.Size=New-Object System.Drawing.Size(1380,820)
$form.MinimumSize=New-Object System.Drawing.Size(1200,740)
$form.StartPosition="CenterScreen"
$form.BackColor=$script:colors.BgDark

# HEADER
$headerPanel=New-Object System.Windows.Forms.Panel
$headerPanel.Location=New-Object System.Drawing.Point(0,0)
$headerPanel.Size=New-Object System.Drawing.Size(1380,54)
$headerPanel.BackColor=$script:colors.BgHeader
$headerPanel.Anchor="Top,Left,Right"

$lblTitle=New-Object System.Windows.Forms.Label
$lblTitle.Text="WINDOWS DE MENTE v2.0"
$lblTitle.Font=$fonts.Title
$lblTitle.ForeColor=$script:colors.Accent
$lblTitle.Location=New-Object System.Drawing.Point(10,10)
$lblTitle.AutoSize=$true
$headerPanel.Controls.Add($lblTitle)

$lblSubtitle=New-Object System.Windows.Forms.Label
$lblSubtitle.Text="'Cuando estas mal, cuando estas solo, no te olvides de mi...' - Charly Garcia"
$lblSubtitle.Font=$fonts.Body
$lblSubtitle.ForeColor=$script:colors.TextDim
$lblSubtitle.Location=New-Object System.Drawing.Point(340,18)
$lblSubtitle.AutoSize=$true
$headerPanel.Controls.Add($lblSubtitle)

$btnTheme=New-Object System.Windows.Forms.Button
$btnTheme.Text="CLARO"; $btnTheme.Font=$fonts.BodyBold
$btnTheme.ForeColor=$script:colors.TextPrimary; $btnTheme.BackColor=$script:colors.BgCard2
$btnTheme.FlatStyle="Flat"; $btnTheme.FlatAppearance.BorderSize=0
$btnTheme.Location=New-Object System.Drawing.Point(1248,10)
$btnTheme.Size=New-Object System.Drawing.Size(100,34)
$btnTheme.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnTheme.Anchor="Top,Right"
$btnTheme.Add_Click({
    $script:IsDarkMode=-not $script:IsDarkMode
    if($script:IsDarkMode){$script:colors=$themes.Dark;$btnTheme.Text="CLARO"}
    else{$script:colors=$themes.Light;$btnTheme.Text="OSCURO"}
    Apply-Theme
})
$headerPanel.Controls.Add($btnTheme)
$form.Controls.Add($headerPanel)

# LEFT PANEL
$leftPanel=New-Object System.Windows.Forms.Panel
$leftPanel.Location=New-Object System.Drawing.Point(5,58)
$leftPanel.Size=New-Object System.Drawing.Size(235,728)
$leftPanel.BackColor=$script:colors.BgPanel
$leftPanel.Anchor="Top,Left,Bottom"

$lblHwTitle=New-Object System.Windows.Forms.Label
$lblHwTitle.Text="TU EQUIPO"
$lblHwTitle.Font=$fonts.Header
$lblHwTitle.ForeColor=$script:colors.Accent
$lblHwTitle.Location=New-Object System.Drawing.Point(5,6)
$lblHwTitle.AutoSize=$true
$leftPanel.Controls.Add($lblHwTitle)

$rtbHardware=New-Object System.Windows.Forms.RichTextBox
$rtbHardware.Location=New-Object System.Drawing.Point(5,28)
$rtbHardware.Size=New-Object System.Drawing.Size(225,155)
$rtbHardware.BackColor=$script:colors.BgLog
$rtbHardware.ForeColor=$script:colors.TextSecond
$rtbHardware.Font=$fonts.MonoSm
$rtbHardware.ReadOnly=$true
$rtbHardware.BorderStyle="None"
$leftPanel.Controls.Add($rtbHardware)

$btnAnalyze=New-Object System.Windows.Forms.Button
$btnAnalyze.Text="ANALIZAR MI PC"
$btnAnalyze.Font=$fonts.BodyBold
$btnAnalyze.ForeColor=$script:colors.BgDark
$btnAnalyze.BackColor=$script:colors.Accent
$btnAnalyze.FlatStyle="Flat"
$btnAnalyze.FlatAppearance.BorderSize=0
$btnAnalyze.Location=New-Object System.Drawing.Point(5,188)
$btnAnalyze.Size=New-Object System.Drawing.Size(225,36)
$btnAnalyze.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnAnalyze.Add_Click({
    $btnAnalyze.Enabled=$false
    $rtbHardware.Clear(); $rtbLog.Clear()
    $script:ResumenDiag.Clear()
    Set-Status "Analizando tu PC, un momento..." "Yellow"
    Write-Log "Hola! Voy a revisar todo el equipo." "Accent"
    Write-Log "Lo hago bloque por bloque para no congelar la pantalla." "TextDim"
    Write-Log ""
    [System.Windows.Forms.Application]::DoEvents()

    $script:Diagnostico = Get-DiagnosticoCompleto

    if (-not $script:Diagnostico) {
        Write-Log "No pude completar el diagnostico." "Red"
        Set-Status "Error en el diagnostico" "Red"
        $btnAnalyze.Enabled=$true; return
    }

    # Mostrar hardware en panel izquierdo
    $rtbHardware.Clear()
    $rtbHardware.SelectionColor=$script:colors.Accent
    $rtbHardware.AppendText("$($script:Diagnostico.CPUName)`r`n")
    $rtbHardware.SelectionColor=$script:colors.TextSecond
    $rtbHardware.AppendText("$($script:Diagnostico.CPUCores) cores  $($script:Diagnostico.CPUFreqGHz) GHz`r`n")
    $rtbHardware.AppendText("RAM:   $($script:Diagnostico.RAMTotalGB) GB")
    if ($script:Diagnostico.RAMSpeedMHz -gt 0) { $rtbHardware.AppendText("  ($($script:Diagnostico.RAMSpeedMHz) MHz)") }
    $rtbHardware.AppendText("`r`n")
    $rtbHardware.AppendText("Disco: $(if($script:Diagnostico.TieneSSD){'SSD'}else{'HDD'})  $($script:Diagnostico.DiscoLibreGB)/$($script:Diagnostico.DiscoTotalGB) GB libres`r`n")
    $rtbHardware.AppendText("Tipo:  $(if($script:Diagnostico.EsLaptop){'Laptop'}else{'Desktop'})`r`n")
    $redTipo=if($script:Diagnostico.EsWiFi){"WiFi"}elseif($script:Diagnostico.EsEthernet){"Ethernet"}else{"?"}
    $rtbHardware.AppendText("Red:   $redTipo`r`n")
    $rtbHardware.AppendText("Plan:  $($script:Diagnostico.PowerPlanActivo)`r`n")
    $rtbHardware.AppendText("Win:   $($script:Diagnostico.WinVersion)`r`n")
    $rtbHardware.AppendText("Up:    $($script:Diagnostico.UptimeDias) dias`r`n")
    if ($script:Diagnostico.BootTimeMs -gt 0) {
        $bootSeg = [math]::Round($script:Diagnostico.BootTimeMs / 1000)
        $bootColor = if($script:Diagnostico.BootMuySlow){$script:colors.Red}elseif($script:Diagnostico.BootSlow){$script:colors.Orange}else{$script:colors.Green}
        $rtbHardware.SelectionColor = $bootColor
        $rtbHardware.AppendText("Boot:  $bootSeg seg`r`n")
        $rtbHardware.SelectionColor = $script:colors.TextSecond
    }
    if ($script:Diagnostico.ErroresCriticos -gt 0) {
        $rtbHardware.SelectionColor=$script:colors.Orange
        $rtbHardware.AppendText("Errores 48hs: $($script:Diagnostico.ErroresCriticos)`r`n")
    }

    # Cargar pestanas
    Load-OptimizacionesTab
    Load-LimpiezaTab
    Load-PrivacidadTab
    Load-ReparacionTab
    Refresh-HistorialDisplay

    # Mostrar resumen del diagnostico en el log
    Show-ResumenDiag

    Set-Status "Analisis completo. Revisa las pestanas y aplica lo que quieras." "Green"
    $btnAnalyze.Enabled=$true
})
$leftPanel.Controls.Add($btnAnalyze)

$lblHistTitle=New-Object System.Windows.Forms.Label
$lblHistTitle.Text="ULTIMOS CAMBIOS"
$lblHistTitle.Font=$fonts.Header
$lblHistTitle.ForeColor=$script:colors.Accent
$lblHistTitle.Location=New-Object System.Drawing.Point(5,236)
$lblHistTitle.AutoSize=$true
$leftPanel.Controls.Add($lblHistTitle)

$lvHistorial=New-Object System.Windows.Forms.ListView
$lvHistorial.Location=New-Object System.Drawing.Point(5,258)
$lvHistorial.Size=New-Object System.Drawing.Size(225,462)
$lvHistorial.View="Details"
$lvHistorial.FullRowSelect=$true
$lvHistorial.GridLines=$false
$lvHistorial.BackColor=$script:colors.BgCard
$lvHistorial.ForeColor=$script:colors.TextSecond
$lvHistorial.Font=$fonts.Small
$lvHistorial.BorderStyle="None"
$lvHistorial.HeaderStyle="None"
$lvHistorial.CheckBoxes=$false
$lvHistorial.UseCompatibleStateImageBehavior=$false
$lvHistorial.Columns.Add("Fecha",60)|Out-Null
$lvHistorial.Columns.Add("Cambio",153)|Out-Null
$leftPanel.Controls.Add($lvHistorial)
$form.Controls.Add($leftPanel)

# CENTER PANEL
$centerPanel=New-Object System.Windows.Forms.Panel
$centerPanel.Location=New-Object System.Drawing.Point(245,58)
$centerPanel.Size=New-Object System.Drawing.Size(670,728)
$centerPanel.BackColor=$script:colors.BgPanel
$centerPanel.Anchor="Top,Left,Bottom,Right"

$tabControl=New-Object System.Windows.Forms.TabControl
$tabControl.Location=New-Object System.Drawing.Point(5,5)
$tabControl.Size=New-Object System.Drawing.Size(660,618)
$tabControl.Font=$fonts.TabFont
$tabControl.BackColor=$script:colors.BgCard
$tabControl.Anchor="Top,Left,Bottom,Right"

$emptyImgList=New-Object System.Windows.Forms.ImageList
$emptyImgList.ImageSize=New-Object System.Drawing.Size(1,1)

# Evento: al cambiar de pestana, mostrar resumen del diagnostico si no hay item seleccionado
$tabControl.Add_SelectedIndexChanged({
    if ($script:Diagnostico) { Show-ResumenDiag }
})

# TAB OPTIMIZACIONES
$tabOpt=New-Object System.Windows.Forms.TabPage
$tabOpt.Text="OPTIMIZACIONES"; $tabOpt.BackColor=$script:colors.BgCard

$lvOpt=New-Object System.Windows.Forms.ListView
$lvOpt.Location=New-Object System.Drawing.Point(3,3)
$lvOpt.Size=New-Object System.Drawing.Size(652,578)
$lvOpt.View="Details"; $lvOpt.FullRowSelect=$true; $lvOpt.SmallImageList=$emptyImgList
$lvOpt.GridLines=$false; $lvOpt.BackColor=$script:colors.BgCard; $lvOpt.ForeColor=$script:colors.TextPrimary
$lvOpt.Font=$fonts.Mono; $lvOpt.BorderStyle="None"; $lvOpt.HeaderStyle="Nonclickable"
$lvOpt.CheckBoxes=$true; $lvOpt.UseCompatibleStateImageBehavior=$false
$lvOpt.Columns.Add("Que optimizo",340)|Out-Null
$lvOpt.Columns.Add("Por que lo recomiendo",296)|Out-Null
$lvOpt.Add_SelectedIndexChanged({
    if ($lvOpt.SelectedItems.Count -gt 0) {
        $item=$lvOpt.SelectedItems[0]
        $rtbLog.Clear()
        $rtbLog.SelectionColor=$script:colors.Accent;      $rtbLog.AppendText("$($item.Text)`r`n")
        $rtbLog.SelectionColor=$script:colors.BorderColor; $rtbLog.AppendText("────────────────────────────`r`n`r`n")
        $rtbLog.SelectionColor=$script:colors.TextPrimary; $rtbLog.AppendText("$($item.Tag.Explicacion)`r`n")
        $rtbLog.SelectionColor=$script:colors.TextDim;     $rtbLog.AppendText("`r`nHace clic en otro item o cambia de pestana para ver el resumen completo.")
    }
})
$tabOpt.Controls.Add($lvOpt)

# TAB LIMPIEZA
$tabLimp=New-Object System.Windows.Forms.TabPage
$tabLimp.Text="LIMPIEZA"; $tabLimp.BackColor=$script:colors.BgCard

$lvLimp=New-Object System.Windows.Forms.ListView
$lvLimp.Location=New-Object System.Drawing.Point(3,3)
$lvLimp.Size=New-Object System.Drawing.Size(652,578)
$lvLimp.View="Details"; $lvLimp.FullRowSelect=$true; $lvLimp.SmallImageList=$emptyImgList
$lvLimp.GridLines=$false; $lvLimp.BackColor=$script:colors.BgCard; $lvLimp.ForeColor=$script:colors.TextPrimary
$lvLimp.Font=$fonts.Mono; $lvLimp.BorderStyle="None"; $lvLimp.HeaderStyle="Nonclickable"
$lvLimp.CheckBoxes=$true; $lvLimp.UseCompatibleStateImageBehavior=$false
$lvLimp.Columns.Add("Que limpio",330)|Out-Null
$lvLimp.Columns.Add("Espacio que libero",160)|Out-Null
$lvLimp.Columns.Add("Estado",145)|Out-Null
$lvLimp.Add_SelectedIndexChanged({
    if ($lvLimp.SelectedItems.Count -gt 0) {
        $item=$lvLimp.SelectedItems[0]; $info=$item.Tag
        $rtbLog.Clear()
        $rtbLog.SelectionColor=$script:colors.Accent;      $rtbLog.AppendText("$($info.Nombre)`r`n")
        $rtbLog.SelectionColor=$script:colors.BorderColor; $rtbLog.AppendText("────────────────────────────`r`n`r`n")
        $rtbLog.SelectionColor=$script:colors.TextPrimary; $rtbLog.AppendText("$($info.Explicacion)`r`n`r`n")
        $rtbLog.SelectionColor=$script:colors.Green;       $rtbLog.AppendText("Espacio a recuperar: $($item.SubItems[1].Text)")
        $rtbLog.SelectionColor=$script:colors.TextDim;     $rtbLog.AppendText("`r`n`r`nHace clic en otro item o cambia de pestana para ver el resumen completo.")
    }
})
$tabLimp.Controls.Add($lvLimp)

# TAB PRIVACIDAD
$tabPriv=New-Object System.Windows.Forms.TabPage
$tabPriv.Text="PRIVACIDAD"; $tabPriv.BackColor=$script:colors.BgCard

$lvPriv=New-Object System.Windows.Forms.ListView
$lvPriv.Location=New-Object System.Drawing.Point(3,3)
$lvPriv.Size=New-Object System.Drawing.Size(652,578)
$lvPriv.View="Details"; $lvPriv.FullRowSelect=$true; $lvPriv.SmallImageList=$emptyImgList
$lvPriv.GridLines=$false; $lvPriv.BackColor=$script:colors.BgCard; $lvPriv.ForeColor=$script:colors.TextPrimary
$lvPriv.Font=$fonts.Mono; $lvPriv.BorderStyle="None"; $lvPriv.HeaderStyle="Nonclickable"
$lvPriv.CheckBoxes=$true; $lvPriv.UseCompatibleStateImageBehavior=$false
$lvPriv.Columns.Add("Ajuste de privacidad",430)|Out-Null
$lvPriv.Columns.Add("Estado actual",205)|Out-Null
$lvPriv.Add_SelectedIndexChanged({
    if ($lvPriv.SelectedItems.Count -gt 0) {
        $item=$lvPriv.SelectedItems[0]
        $rtbLog.Clear()
        $rtbLog.SelectionColor=$script:colors.Accent;      $rtbLog.AppendText("$($item.Tag.Nombre)`r`n")
        $rtbLog.SelectionColor=$script:colors.BorderColor; $rtbLog.AppendText("────────────────────────────`r`n`r`n")
        $rtbLog.SelectionColor=$script:colors.TextPrimary; $rtbLog.AppendText("$($item.Tag.Explicacion)`r`n")
        $rtbLog.SelectionColor=$script:colors.TextDim;     $rtbLog.AppendText("`r`nHace clic en otro item o cambia de pestana para ver el resumen completo.")
    }
})
$tabPriv.Controls.Add($lvPriv)

# TAB REPARACION
$tabRep=New-Object System.Windows.Forms.TabPage
$tabRep.Text="REPARACION"; $tabRep.BackColor=$script:colors.BgCard

$lvRep=New-Object System.Windows.Forms.ListView
$lvRep.Location=New-Object System.Drawing.Point(3,3)
$lvRep.Size=New-Object System.Drawing.Size(652,500)
$lvRep.View="Details"; $lvRep.FullRowSelect=$true; $lvRep.SmallImageList=$emptyImgList
$lvRep.GridLines=$false; $lvRep.BackColor=$script:colors.BgCard; $lvRep.ForeColor=$script:colors.TextPrimary
$lvRep.Font=$fonts.Mono; $lvRep.BorderStyle="None"; $lvRep.HeaderStyle="Nonclickable"
$lvRep.CheckBoxes=$true; $lvRep.UseCompatibleStateImageBehavior=$false
$lvRep.Columns.Add("Herramienta",340)|Out-Null
$lvRep.Columns.Add("Cuando usarla",295)|Out-Null
$lvRep.Add_SelectedIndexChanged({
    if ($lvRep.SelectedItems.Count -gt 0) {
        $item=$lvRep.SelectedItems[0]
        $rtbLog.Clear()
        $rtbLog.SelectionColor=$script:colors.Purple;      $rtbLog.AppendText("$($item.Text)`r`n")
        $rtbLog.SelectionColor=$script:colors.BorderColor; $rtbLog.AppendText("────────────────────────────`r`n`r`n")
        $exp=switch($item.Tag){
            "chkdsk"  {"CHKDSK revisa y repara el disco duro a nivel fisico. Lo hace antes de que Windows cargue, en el proximo reinicio. Usalo si la PC tarda en arrancar, aparecen archivos corruptos o el diagnostico detecto el dirty bit."}
            "dism"    {"DISM restaura la imagen del sistema descargando archivos limpios desde servidores de Microsoft. Usalo si SFC encuentra errores que no puede reparar, o si Windows se comporta raro. Necesita internet y puede tardar varios minutos."}
            "sfc"     {"SFC escanea todos los archivos del sistema de Windows y reemplaza los danados o faltantes. Es el primer paso ante pantallazos azules o crashes repetidos. No necesita internet."}
            "network" {"Reinicia toda la pila de red de Windows: IP, Winsock y DNS. Usalo si tenes problemas de conexion, paginas que no cargan, o juegos que no conectan aunque tengas internet. Reinicia despues para que tome efecto."}
        }
        $rtbLog.SelectionColor=$script:colors.TextPrimary; $rtbLog.AppendText("$exp`r`n")
        $rtbLog.SelectionColor=$script:colors.TextDim;     $rtbLog.AppendText("`r`nHace clic en otro item o cambia de pestana para ver el resumen completo.")
    }
})

$btnRunRep=New-Object System.Windows.Forms.Button
$btnRunRep.Text="EJECUTAR REPARACIONES SELECCIONADAS"
$btnRunRep.Font=$fonts.BodyBold
$btnRunRep.ForeColor=$script:colors.TextPrimary; $btnRunRep.BackColor=$script:colors.Purple
$btnRunRep.FlatStyle="Flat"; $btnRunRep.FlatAppearance.BorderSize=0
$btnRunRep.Location=New-Object System.Drawing.Point(3,507)
$btnRunRep.Size=New-Object System.Drawing.Size(652,36)
$btnRunRep.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnRunRep.Add_Click({
    $sel=@()
    for($i=0;$i -lt $lvRep.Items.Count;$i++){if($lvRep.Items[$i].Checked){$sel+=$lvRep.Items[$i].Tag}}
    if($sel.Count -eq 0){
        [System.Windows.Forms.MessageBox]::Show("Tilda al menos una herramienta antes de ejecutar.","Windows De Mente",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null
        return
    }
    $conf=[System.Windows.Forms.MessageBox]::Show(
        "Voy a ejecutar: $($sel -join ', ')`n`n¿Arrancamos?",
        "Confirmar reparacion",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if($conf -eq "Yes"){Set-Status "Ejecutando reparaciones..." "Purple"; Invoke-Reparaciones -Seleccionadas $sel}
})
$tabRep.Controls.Add($lvRep)
$tabRep.Controls.Add($btnRunRep)
$tabControl.TabPages.AddRange(@($tabOpt,$tabLimp,$tabPriv,$tabRep))
$centerPanel.Controls.Add($tabControl)

# BOTONES INFERIORES
$btnVistaPrevia=New-Object System.Windows.Forms.Button
$btnVistaPrevia.Text="VER SIN ROMPER NADA"; $btnVistaPrevia.Font=$fonts.Body
$btnVistaPrevia.ForeColor=$script:colors.TextPrimary; $btnVistaPrevia.BackColor=$script:colors.BgCard2
$btnVistaPrevia.FlatStyle="Flat"; $btnVistaPrevia.FlatAppearance.BorderSize=0
$btnVistaPrevia.Location=New-Object System.Drawing.Point(5,628)
$btnVistaPrevia.Size=New-Object System.Drawing.Size(205,38)
$btnVistaPrevia.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnVistaPrevia.Anchor="Bottom,Left"
$btnVistaPrevia.Add_Click({
    $script:ModoVistaPrevia=-not $script:ModoVistaPrevia
    if($script:ModoVistaPrevia){
        $btnVistaPrevia.BackColor=$script:colors.Accent; $btnVistaPrevia.ForeColor=$script:colors.BgDark
        $btnVistaPrevia.Text="VISTA PREVIA (ON)"
        Write-Log "Modo vista previa activado." "Green"
        Write-Log "Hace clic en cada item y te cuento que haria, sin tocar nada." "TextDim"
    } else {
        $btnVistaPrevia.BackColor=$script:colors.BgCard2; $btnVistaPrevia.ForeColor=$script:colors.TextPrimary
        $btnVistaPrevia.Text="VER SIN ROMPER NADA"
        Write-Log "Modo normal." "TextDim"
    }
})
$centerPanel.Controls.Add($btnVistaPrevia)

$btnAplicar=New-Object System.Windows.Forms.Button
$btnAplicar.Text="APLICAR SELECCIONADAS"; $btnAplicar.Font=$fonts.BodyBold
$btnAplicar.ForeColor=$script:colors.BgDark; $btnAplicar.BackColor=$script:colors.Green
$btnAplicar.FlatStyle="Flat"; $btnAplicar.FlatAppearance.BorderSize=0
$btnAplicar.Location=New-Object System.Drawing.Point(215,628)
$btnAplicar.Size=New-Object System.Drawing.Size(225,38)
$btnAplicar.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnAplicar.Anchor="Bottom,Left"
$btnAplicar.Add_Click({
    if(-not $script:Diagnostico){
        [System.Windows.Forms.MessageBox]::Show("Primero hace clic en 'ANALIZAR MI PC'.","Windows De Mente",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null
        return
    }
    if($script:ModoVistaPrevia){Write-Log "Desactiva el modo vista previa para poder aplicar." "Orange"; return}

    $totalSel=0
    for($i=0;$i -lt $lvOpt.Items.Count;$i++){if($lvOpt.Items[$i].Checked){$totalSel++}}
    for($i=0;$i -lt $lvLimp.Items.Count;$i++){if($lvLimp.Items[$i].Checked){$totalSel++}}
    for($i=0;$i -lt $lvPriv.Items.Count;$i++){if($lvPriv.Items[$i].Checked){$totalSel++}}

    if($totalSel -eq 0){
        [System.Windows.Forms.MessageBox]::Show("No tildaste ninguna accion. Marco las que queres aplicar primero.","Windows De Mente",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null
        return
    }
    $conf=[System.Windows.Forms.MessageBox]::Show(
        "Voy a aplicar $totalSel cambio(s).`n`nAntes guardo un backup del registro por las dudas.`n`n?Arrancamos?",
        "Confirmar",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if($conf -ne "Yes"){return}

    Backup-OriginalState|Out-Null
    $ok=0; $fail=0
    Set-Status "Aplicando cambios..." "Yellow"

    for($i=0;$i -lt $lvOpt.Items.Count;$i++){
        if($lvOpt.Items[$i].Checked){
            $item=$lvOpt.Items[$i]; $opt=$item.Tag
            Write-Log "Aplicando: $($item.Text)..." "Yellow"
            try{
                $r=& $opt.Func
                if($r){$ok++;$item.Checked=$false;$item.SubItems[1].Text="Hecho";$item.ForeColor=$script:colors.Green;Add-Historial $item.Text "Optimizacion"}
                else{$fail++}
            }catch{$fail++;Write-Log "  Error: $_" "Red"}
        }
    }
    for($i=0;$i -lt $lvLimp.Items.Count;$i++){
        if($lvLimp.Items[$i].Checked){
            $item=$lvLimp.Items[$i]; $info=$item.Tag
            Write-Log "Limpiando: $($item.Text)..." "Yellow"
            try{
                $r=& $info.Action
                if($r){$ok++;$item.Checked=$false;$item.SubItems[2].Text="Limpio";$item.ForeColor=$script:colors.Green;Add-Historial $item.Text "Limpieza"}
                else{$fail++}
            }catch{$fail++;Write-Log "  Error: $_" "Red"}
        }
    }
    for($i=0;$i -lt $lvPriv.Items.Count;$i++){
        if($lvPriv.Items[$i].Checked){
            $item=$lvPriv.Items[$i]; $opt=$item.Tag
            Write-Log "Aplicando: $($item.Text)..." "Yellow"
            try{
                $r=& $opt.Func
                if($r){$ok++;$item.Checked=$false;$item.SubItems[1].Text="Hecho";$item.ForeColor=$script:colors.Green;Add-Historial $item.Text "Privacidad"}
                else{$fail++}
            }catch{$fail++;Write-Log "  Error: $_" "Red"}
        }
    }

    Write-Log ""
    if($fail -gt 0){Write-Log "Aplique $ok cambio(s). $fail no pudo completarse." "Yellow"; Set-Status "Listo con $ok cambios ($fail errores)" "Yellow"}
    else{Write-Log "Listo! Aplique $ok cambio(s) sin problemas." "Green"; Set-Status "Listo  $ok cambios aplicados" "Green"}
    Refresh-HistorialDisplay
})
$centerPanel.Controls.Add($btnAplicar)

$btnRestaurar=New-Object System.Windows.Forms.Button
$btnRestaurar.Text="RESTAURAR BACKUP"; $btnRestaurar.Font=$fonts.BodyBold
$btnRestaurar.ForeColor=$script:colors.TextPrimary; $btnRestaurar.BackColor=$script:colors.BgCard2
$btnRestaurar.FlatStyle="Flat"; $btnRestaurar.FlatAppearance.BorderColor=$script:colors.Red; $btnRestaurar.FlatAppearance.BorderSize=1
$btnRestaurar.Location=New-Object System.Drawing.Point(445,628)
$btnRestaurar.Size=New-Object System.Drawing.Size(220,38)
$btnRestaurar.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnRestaurar.Anchor="Bottom,Left"
$btnRestaurar.Add_Click({
    if(-not $script:UltimoBackupPath -or -not(Test-Path $script:UltimoBackupPath)){
        $backups=Get-ChildItem "$env:TEMP\WDM_Backup_*.reg" -EA 0|Sort-Object LastWriteTime -Descending
        if($backups){$script:UltimoBackupPath=$backups[0].FullName}
        else{
            [System.Windows.Forms.MessageBox]::Show("No encontre ningun backup.`nEl backup se crea automaticamente cuando aplicas cambios.","Sin backup",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null
            return
        }
    }
    $c=[System.Windows.Forms.MessageBox]::Show(
        "Voy a restaurar el registro desde:`n$script:UltimoBackupPath`n`nLa PC va a reiniciar para aplicar los cambios.`n`n?Continuar?",
        "Restaurar backup",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if($c -eq "Yes"){
        try{
            reg import $script:UltimoBackupPath 2>&1|Out-Null
            Write-Log "Backup importado. Reiniciando en 10 segundos..." "Yellow"
            Set-Status "Reiniciando para restaurar..." "Orange"
            shutdown /r /t 10; $form.Close()
        }catch{Write-Log "No pude importar el backup: $_" "Red"}
    }
})
$centerPanel.Controls.Add($btnRestaurar)
$form.Controls.Add($centerPanel)

# RIGHT PANEL — LOG
$rightPanel=New-Object System.Windows.Forms.Panel
$rightPanel.Location=New-Object System.Drawing.Point(920,58)
$rightPanel.Size=New-Object System.Drawing.Size(450,728)
$rightPanel.BackColor=$script:colors.BgPanel
$rightPanel.Anchor="Top,Right,Bottom"

$lblLog=New-Object System.Windows.Forms.Label
$lblLog.Text="QUE HACE ESTO?"
$lblLog.Font=$fonts.Header
$lblLog.ForeColor=$script:colors.Accent
$lblLog.Location=New-Object System.Drawing.Point(5,6)
$lblLog.AutoSize=$true
$rightPanel.Controls.Add($lblLog)

$rtbLog=New-Object System.Windows.Forms.RichTextBox
$rtbLog.Location=New-Object System.Drawing.Point(5,28)
$rtbLog.Size=New-Object System.Drawing.Size(440,692)
$rtbLog.BackColor=$script:colors.BgLog
$rtbLog.ForeColor=$script:colors.TextPrimary
$rtbLog.Font=$fonts.Mono
$rtbLog.ReadOnly=$true
$rtbLog.BorderStyle="None"
$rtbLog.Anchor="Top,Left,Bottom,Right"
$rightPanel.Controls.Add($rtbLog)
$form.Controls.Add($rightPanel)

# BARRA DE ESTADO
$statusBar=New-Object System.Windows.Forms.Panel
$statusBar.Location=New-Object System.Drawing.Point(0,772)
$statusBar.Size=New-Object System.Drawing.Size(1380,24)
$statusBar.BackColor=$script:colors.BgStatus
$statusBar.Anchor="Bottom,Left,Right"

$lblStatus=New-Object System.Windows.Forms.Label
$lblStatus.Text="Listo  —  hace clic en 'ANALIZAR MI PC' para empezar"
$lblStatus.Font=$fonts.Status
$lblStatus.ForeColor=$script:colors.TextDim
$lblStatus.Location=New-Object System.Drawing.Point(8,4)
$lblStatus.Size=New-Object System.Drawing.Size(1200,16)
$statusBar.Controls.Add($lblStatus)

$lblVer=New-Object System.Windows.Forms.Label
$lblVer.Text="WDM v2.0"; $lblVer.Font=$fonts.Status
$lblVer.ForeColor=$script:colors.TextDim
$lblVer.Location=New-Object System.Drawing.Point(1320,4)
$lblVer.AutoSize=$true; $lblVer.Anchor="Bottom,Right"
$statusBar.Controls.Add($lblVer)
$form.Controls.Add($statusBar)

# ============================================================================
#  FUNCIONES DE PESTANAS
# ============================================================================
function Load-OptimizacionesTab {
    $lvOpt.Items.Clear()
    if(-not $script:Diagnostico){return}

    $svcParaDesact = Get-ServiciosParaDesactivar
    $opts=@(
        @{
            Nombre="Prioridad de procesos (CPU)"
            Motivo="Tu CPU tiene $($script:Diagnostico.CPUCores) cores — el valor optimo para priorizar el programa activo es $( if($script:Diagnostico.CPUCores -ge 8){38}elseif($script:Diagnostico.CPUCores -ge 4){26}else{18})"
            Check={Check-Win32PrioritySeparation}; Func={Optimize-Win32PrioritySeparation}
            Condicion={-not $script:Diagnostico.PrioridadProcesosOK}
            Explicacion="Windows reparte el tiempo del CPU entre todos los procesos por igual. Este ajuste le dice que le de prioridad al programa que estas usando en este momento. Se nota en juegos, edicion de video y cualquier tarea que necesite respuesta rapida."
        },
        @{
            Nombre="Kernel de Windows en RAM"
            Motivo="Tenes $($script:Diagnostico.RAMTotalGB) GB de RAM — el kernel puede quedarse siempre en memoria"
            Check={Check-DisablePagingExecutive}; Func={Optimize-DisablePagingExecutive}
            Condicion={$script:Diagnostico.RAMTotalGB -ge 8 -and -not $script:Diagnostico.PagingExecutiveOK}
            Explicacion="Con $($script:Diagnostico.RAMTotalGB) GB de RAM podemos pedirle a Windows que mantenga el nucleo del sistema siempre en memoria en vez de usar el disco. El resultado es un sistema mas responsivo en general, especialmente al cambiar entre programas."
        },
        @{
            Nombre="Menus instantaneos (0ms)"
            Motivo="Tus menus tienen un delay de $($script:Diagnostico.MenuShowDelay)ms que se puede bajar a cero"
            Check={Check-MenuShowDelay}; Func={Optimize-MenuShowDelay}
            Condicion={$script:Diagnostico.MenuShowDelay -gt 0}
            Explicacion="Windows tiene un delay de $($script:Diagnostico.MenuShowDelay)ms antes de mostrar los menus del sistema. Lo bajo a 0: los menus aparecen al instante cuando pasas el mouse. Es un cambio chico pero se nota."
        },
        @{
            Nombre="Plan de energia: Alto Rendimiento"
            Motivo="Tu plan es '$($script:Diagnostico.PowerPlanActivo)' — frena el CPU innecesariamente en un desktop"
            Check={Check-PowerPlan}; Func={Optimize-PowerPlan}
            Condicion={$script:Diagnostico.EsBalanced -and -not $script:Diagnostico.EsLaptop}
            Explicacion="Tu plan actual ('$($script:Diagnostico.PowerPlanActivo)') frena la frecuencia del procesador para ahorrar energia. Como es un desktop que siempre esta conectado, activo el plan Alto Rendimiento: el CPU corre a su maxima velocidad siempre."
        },
        @{
            Nombre="Efectos visuales reducidos"
            Motivo="Las animaciones y transparencias de Windows consumen RAM y CPU sin aportar velocidad"
            Check={Check-VisualEffects}; Func={Optimize-VisualEffects}
            Condicion={-not $script:Diagnostico.VisualEffectsOptimized}
            Explicacion="Windows tiene animaciones, sombras y transparencias que consumen recursos innecesariamente. Las reduzco al minimo: se pierde algo de estetica pero se gana velocidad real. Especialmente notable en PCs con poca RAM o procesadores mas viejos."
        },
        @{
            Nombre="Network throttling desactivado"
            Motivo="Windows limita la red para priorizar multimedia — te frena en descargas y juegos"
            Check={Check-NetworkThrottling}; Func={Optimize-NetworkThrottling}
            Condicion={$script:Diagnostico.NetworkThrottling}
            Explicacion="Windows limita el uso de red para darle prioridad a contenido multimedia. Si no estas haciendo streaming critico constantemente, esto libera el ancho de banda para descargas, juegos online y videollamadas."
        },

        @{
            Nombre="Desactivar servicios innecesarios"
            Motivo="Encontre $($svcParaDesact.Count) servicios desactivables: $($svcParaDesact -join ', ')"
            Check={Check-ServiciosExternos}; Func={Optimize-ServiciosExternos}
            Condicion={$svcParaDesact.Count -gt 0}
            Explicacion="Hay servicios corriendo en segundo plano que no aportan nada en el uso diario. Los desactivo: Xbox, telemetria, fax, registro remoto y otros. Resultado: arranque mas rapido y mas RAM libre."
        },
        @{
            Nombre="Limpiar menu contextual (clic derecho)"
            Motivo="$($script:Diagnostico.ContextMenuRealCount) entradas en el menu — puede tener huerfanas que lo frenan"
            Check={Check-MenuContextual}; Func={Optimize-MenuContextual}
            Condicion={-not $script:Diagnostico.MenuContextualOK}
            Explicacion="Cada programa que instalan agrega entradas al clic derecho. Las que apuntan a programas ya desinstalados quedan como fantasmas y frenan la apertura del menu. Las elimino sin tocar las que funcionan."
        },
        @{
            Nombre="Regenerar cache de iconos"
            Motivo="La cache de iconos esta grande — puede causar iconos en blanco o que tardan en aparecer"
            Check={Check-IconCache}; Func={Optimize-IconCache}
            Condicion={-not $script:Diagnostico.IconCacheOK}
            Explicacion="Windows guarda una copia de todos los iconos para mostrarlos rapido. Cuando esta base de datos se corrompe o crece demasiado, los iconos aparecen en blanco, tardan en cargar o muestran el icono equivocado. Al limpiarla Windows la regenera sola."
        },
        @{
            Nombre="Regenerar cache de fuentes"
            Motivo="La cache de fuentes esta grande y puede estar fragmentada"
            Check={Check-FontCache}; Func={Optimize-FontCache}
            Condicion={-not $script:Diagnostico.FontCacheOK}
            Explicacion="Windows precarga todas las fuentes para mostrarlas rapido en cualquier programa. Si esta cache crece demasiado o se corrompe, el Explorer tarda mas en abrir ventanas y algunos programas demoran al arrancar. Se regenera sola al reiniciar."
        },
        @{
            Nombre="Desactivar indexacion del disco (HDD)"
            Motivo="Indexacion activa en HDD — Windows Search escribe constantemente y frena el disco"
            Check={Check-Indexacion}; Func={Optimize-Indexacion}
            Condicion={-not $script:Diagnostico.TieneSSD -and -not $script:Diagnostico.IndexacionOK}
            Explicacion="En discos HDD, el servicio de busqueda de Windows escribe continuamente para mantener un indice de todos tus archivos. Esto genera cuellos de botella cuando el disco ya esta ocupado leyendo o escribiendo. En SSD no es problema, en HDD frena todo."
        },
        @{
            Nombre="Desactivar SysMain/Superfetch"
            Motivo=$(if($script:Diagnostico.TieneSSD){"SSD detectado — SysMain genera escritura innecesaria"}else{"Con $($script:Diagnostico.RAMTotalGB)GB RAM Superfetch consume mas de lo que ayuda"})
            Check={Check-Superfetch}; Func={Optimize-Superfetch}
            Condicion={-not $script:Diagnostico.SuperfetchOK}
            Explicacion=$(if($script:Diagnostico.TieneSSD){"Superfetch fue disenado para HDDs. En un SSD no tiene sentido: genera escrituras innecesarias que acortan la vida del disco y no aportan velocidad real. Se desactiva sin perder nada."}else{"Con $($script:Diagnostico.RAMTotalGB)GB de RAM, Superfetch ocupa una porcion importante de la memoria disponible tratando de predecir que vas a usar. Con poca RAM es contraproducente: liberar esa memoria es mejor que la prediccion."})
        },
        @{
            Nombre="Desactivar hibernacion (liberar espacio)"
            Motivo="hiberfil.sys ocupa varios GB y genera escritura extra en el disco"
            Check={Check-Hibernacion}; Func={Optimize-Hibernacion}
            Condicion={$script:Diagnostico.HibernacionActiva}
            Explicacion="La hibernacion guarda todo el contenido de la RAM en el disco para apagarse rapido. El archivo hiberfil.sys ocupa el equivalente a tu RAM (en tu caso ~$($script:Diagnostico.RAMTotalGB)GB). Si nunca usas hibernar, es espacio y escrituras tiradas. El apagado y encendido normal en Windows moderno es muy rapido igual."
        },
        @{
            Nombre="Pagefile con tamano fijo"
            Motivo="Pagefile en modo automatico — Windows lo redimensiona constantemente generando escritura"
            Check={Check-Pagefile}; Func={Optimize-Pagefile}
            Condicion={-not $script:Diagnostico.PagefileOK}
            Explicacion="Cuando el pagefile esta en 'administrado por Windows', el sistema lo agranda y achica segun necesidad, generando escrituras constantes en el disco. Fijarlo en un tamano inicial y maximo evita ese ciclo y da rendimiento mas predecible, especialmente en HDD."
        },
        @{
            Nombre="Limpiar registro de arranque"
            Motivo="$($script:Diagnostico.EntradasHuerfanas) entrada(s) en el arranque apuntan a programas que ya no existen"
            Check={Check-EntradasArranque}; Func={Optimize-LatenciaRegistro}
            Condicion={$script:Diagnostico.EntradasHuerfanas -gt 0 -or -not $script:Diagnostico.LatenciaRegistroOK}
            Explicacion="Cada vez que desinstalan un programa puede quedar una entrada en el registro que Windows intenta ejecutar al arrancar. Como el archivo ya no existe, Windows espera, falla y sigue. Son segundos perdidos en cada inicio. Tambien limpio entradas de desinstaladores fantasma."
        },
        @{
            Nombre="Reconstruir WMI"
            Motivo="WMI responde lento ($($script:Diagnostico.WMILatenciaMs)ms) — causa lentitud general misteriosa"
            Check={Check-WMI}; Func={Optimize-WMI}
            Condicion={-not $script:Diagnostico.WMIOK}
            Explicacion="WMI (Windows Management Instrumentation) es el motor interno que Windows usa para casi todo: hardware, servicios, diagnósticos. Cuando se corrompe, el sistema entero se vuelve lento de forma misteriosa — programas que tardan en abrir, Task Manager lento, scripts que no responden. Reconstruirlo puede hacer una diferencia enorme."
        },
        @{
            Nombre="SystemResponsiveness optimo para tu CPU"
            Motivo="Valor actual no esta ajustado para $($script:Diagnostico.CPUCores) cores — foreground compite con background"
            Check={Check-SystemResponsiveness}; Func={Optimize-SystemResponsiveness}
            Condicion={-not $script:Diagnostico.SystemResponsivenessOK}
            Explicacion="SystemResponsiveness controla cuanto CPU reserva Windows para tareas en segundo plano. Con pocos cores (2-4) conviene un valor de 10 para que el sistema no quede sin aire. Con muchos cores (6+) se puede poner en 0 para maxima prioridad al foreground. Tu script elige el valor ideal segun tu hardware real."
        },
        @{
            Nombre="Prefetcher adaptativo para tu disco"
            Motivo=$(if($script:Diagnostico.TieneSSD){"SSD detectado — Prefetcher en modo apps (evita prefetch de boot innecesario)"}else{"HDD detectado — Prefetcher en modo completo boot+apps (3)"})
            Check={Check-Prefetcher}; Func={Optimize-Prefetcher}
            Condicion={-not $script:Diagnostico.PrefetcherOK}
            Explicacion=$(if($script:Diagnostico.TieneSSD){"En SSD el arranque es tan rapido que prefetchear el boot no suma nada, y puede generar escrituras innecesarias. Se configura en modo 2 (solo apps). En HDD el modo 3 (boot + apps) acelera el inicio porque el disco es lento y la precarga si ayuda."}else{"En HDD el Prefetcher en modo 3 precarga datos de arranque y de las apps que usas seguido, reduciendo los tiempos de carga porque el disco mecanico es lento por naturaleza."})
        },
        @{
            Nombre="Desactivar NTFS Last Access Update"
            Motivo="Cada lectura de archivo genera una escritura extra en disco — innecesario"
            Check={Check-NtfsLastAccess}; Func={Optimize-NtfsLastAccess}
            Condicion={-not $script:Diagnostico.NtfsLastAccessOK}
            Explicacion="Por defecto NTFS anota la fecha y hora del ultimo acceso cada vez que se lee un archivo. Eso significa que leer genera una escritura adicional. En HDD es un overhead real y constante. Desactivarlo no rompe nada: Windows 10/11 ya lo desactivan internamente en muchos casos, pero no siempre queda en el valor correcto."
        },
        @{
            Nombre="Explorer en proceso separado"
            Motivo=$(if($script:Diagnostico.ExplorerCrashes -gt 0){"Explorer crasheo $($script:Diagnostico.ExplorerCrashes) veces en 48hs — proceso separado lo aisla"}else{"Modo preventivo: un crash de Explorer no arrastra al escritorio"})
            Check={Check-ExplorerSeparateProcess}; Func={Optimize-ExplorerSeparateProcess}
            Condicion={-not $script:Diagnostico.ExplorerSeparateOK}
            Explicacion="Por defecto todas las ventanas del Explorador corren en el mismo proceso. Si una carpeta con archivos corruptos o un DLL malo cuelga una ventana, arrastra a todas. Con SeparateProcess=1 cada ventana corre aislada: si una se cae, las demas siguen funcionando y el escritorio no se va."
        }
    )

    foreach($opt in $opts){
        if(-not(& $opt.Condicion)){continue}
        $item=New-Object System.Windows.Forms.ListViewItem
        $item.Text=$opt.Nombre
        $item.Tag=[PSCustomObject]@{Nombre=$opt.Nombre;Check=$opt.Check;Func=$opt.Func;Explicacion=$opt.Explicacion}
        $done=try{& $opt.Check}catch{$false}
        if($done){
            $item.SubItems.Add("Ya estaba optimizado")|Out-Null
            $item.ForeColor=$script:colors.Green; $item.Checked=$false
        } else {
            $item.SubItems.Add($opt.Motivo)|Out-Null
            $item.Checked=$true
        }
        $lvOpt.Items.Add($item)|Out-Null
    }

    if($lvOpt.Items.Count -eq 0){
        Write-Log "Tu PC ya esta optimizada en todos los puntos que revise." "Green"
    }
}

function Load-LimpiezaTab {
    $lvLimp.Items.Clear()

    # Definir items con funcion de bytes para ordenar
    $limpiezas=@(
        @{Nombre="Papelera de Reciclaje";    BytesFunc={Get-RecycleBinBytes};   SizeFunc={Get-RecycleBinSize};   Action={Clear-RecycleBin};    Explicacion="Lo que mandaste a la papelera sigue ocupando espacio en disco hasta que la vacias. No borro nada que no hayas mandado vos mismo ahi."},
        @{Nombre="Windows Update Cleanup";   BytesFunc={Get-WUCacheBytes};      SizeFunc={Get-WUCacheSize};      Action={Clear-WUCache};       Explicacion="Windows Update guarda copias de todas las actualizaciones instaladas. Las viejas ya no sirven — si necesitas desinstalar una actualizacion, ya no podras, pero eso casi nunca pasa."},
        @{Nombre="Archivos temporales";      BytesFunc={Get-TempFilesBytes};    SizeFunc={Get-TempFilesSize};    Action={Clear-TempFiles};     Explicacion="Programas y Windows dejan archivos basura en las carpetas Temp que se van acumulando. Todos son seguros de borrar."},
        @{Nombre="Cache de navegadores";     BytesFunc={Get-BrowserCacheBytes}; SizeFunc={Get-BrowserCacheSize}; Action={Clear-BrowserCache};  Explicacion="Edge y Chrome guardan copias locales de paginas web para cargarlas mas rapido. Pueden crecer mucho y no se limpian solos."},
        @{Nombre="Cache de miniaturas";      BytesFunc={Get-ThumbCacheBytes};   SizeFunc={Get-ThumbCacheSize};   Action={Clear-ThumbCache};    Explicacion="Las vistas previas de imagenes y videos se guardan en archivos que crecen sin control. Al limpiarlos, el Explorador los regenera solos la proxima vez que los necesite."},
        @{Nombre="Volcados de error (Dumps)";BytesFunc={Get-CrashDumpsBytes};   SizeFunc={Get-CrashDumpsSize};   Action={Clear-CrashDumps};    Explicacion="Cuando Windows o un programa tira un pantallazo azul, guarda un volcado de memoria. Son archivos grandes y, salvo que estes depurando un crash activo, no sirven para nada."},
        @{Nombre="Logs de instaladores";     BytesFunc={Get-InstallerLogsBytes};SizeFunc={Get-InstallerLogsSize};Action={Clear-InstallerLogs}; Explicacion="Cada instalacion de programas o actualizaciones deja archivos de registro. Se acumulan por meses o anios y pueden pesar varios GB sin que lo sepas."},
        @{Nombre="Cache de Microsoft Store"; BytesFunc={Get-StoreCacheBytes};   SizeFunc={Get-StoreCacheSize};   Action={Clear-StoreCache};    Explicacion="La Tienda de Windows acumula archivos temporales que pueden causar problemas para instalar o actualizar apps. Limpiarla no desinstala nada."},
        @{Nombre="Prefetch obsoleto";        BytesFunc={Get-PrefetchBytes};     SizeFunc={Get-PrefetchSize};     Action={Clear-Prefetch};      Explicacion="Windows guarda datos de arranque rapido de programas. Si un programa ya no existe, su prefetch queda ahi ocupando espacio."},
        @{Nombre="Archivos .tmp sueltos";    BytesFunc={Get-TmpSueltosBytes};   SizeFunc={Get-TmpSueltosSize};   Action={Clear-TmpSueltos};    Explicacion="Archivos temporales que quedaron sueltos en el escritorio o raiz del disco. Seguros de eliminar."},
        @{Nombre="Cache DNS";                BytesFunc={Get-DNSCacheBytes};     SizeFunc={Get-DNSCacheSize};     Action={Clear-DNSCache};      Explicacion="Windows recuerda las IPs de los sitios que visitaste. Vaciarlo puede resolver problemas de conexion con sitios que cambiaron de servidor."},
        @{Nombre="Historial del Explorador"; BytesFunc={Get-ExplorerHistBytes}; SizeFunc={Get-ExplorerHistSize}; Action={Clear-ExplorerHist};  Explicacion="Windows recuerda las ultimas carpetas abiertas, busquedas y archivos recientes. Limpiar esto no borra ningun archivo, solo el historial de navegacion."},
        @{Nombre="Historial de busqueda";    BytesFunc={Get-SearchHistBytes};   SizeFunc={Get-SearchHistSize};   Action={Clear-SearchHist};    Explicacion="El menu inicio guarda todo lo que buscaste. Tambien desactivo que mande tus busquedas a Bing: la busqueda queda solo en tu PC."}
    )

    # Calcular tamanios y ordenar de mayor a menor
    Set-Status "Calculando espacio a liberar..." "TextDim"
    $conBytes = foreach($l in $limpiezas) {
        $bytes=try{& $l.BytesFunc}catch{0}
        [PSCustomObject]@{Item=$l;Bytes=[long]$bytes}
    }
    $ordenados = $conBytes | Sort-Object Bytes -Descending

    foreach($entry in $ordenados){
        $l=$entry.Item
        $item=New-Object System.Windows.Forms.ListViewItem
        $item.Text=$l.Nombre
        $item.Tag=[PSCustomObject]@{Nombre=$l.Nombre;GetSize=$l.SizeFunc;Action=$l.Action;Explicacion=$l.Explicacion}
        $szStr=try{& $l.SizeFunc}catch{"?"}
        $item.SubItems.Add($szStr)|Out-Null
        $item.SubItems.Add("")|Out-Null
        $item.Checked=$true
        $lvLimp.Items.Add($item)|Out-Null
    }
    Set-Status "Analisis completo. Revisa las pestanas y aplica lo que quieras." "Green"
}

function Load-PrivacidadTab {
    $lvPriv.Items.Clear()
    $privItems=Load-PrivacidadItems
    foreach($p in $privItems){
        $item=New-Object System.Windows.Forms.ListViewItem
        $item.Text=$p.Nombre
        $item.Tag=[PSCustomObject]@{Nombre=$p.Nombre;Func=$p.Func;Explicacion=$p.Explicacion}
        $done=try{& $p.Check}catch{$false}
        if($done){
            $item.SubItems.Add("Protegido")|Out-Null
            $item.ForeColor=$script:colors.Green; $item.Checked=$false
        } else {
            $item.SubItems.Add("Sin proteccion")|Out-Null
            $item.Checked=$true
        }
        $lvPriv.Items.Add($item)|Out-Null
    }
}

function Load-ReparacionTab {
    $lvRep.Items.Clear()
    $tieneKernelPower = $script:Diagnostico -and ($script:Diagnostico.ProblemasGraves -join " ") -match "Pantallazo|brusco|BSOD"
    $tieneDiscoFalla  = $script:Diagnostico -and (($script:Diagnostico.ProblemasGraves -join " ") -match "Disco fisico|dirty bit" -or $script:Diagnostico.DirtyBit)
    $tieneArchivos    = $script:Diagnostico -and -not $script:Diagnostico.ArchivosSistemaOK
    $tieneWMI         = $script:Diagnostico -and -not $script:Diagnostico.WMIOK
    $tieneRed         = $script:Diagnostico -and ($script:Diagnostico.ProblemasGraves -join " ") -match "Red con problemas"

    @(
        @{N="CHKDSK  —  Revisar y reparar el disco";  C="Disco lento, errores o dirty bit detectado"; T="chkdsk"}
        @{N="DISM  —  Restaurar imagen del sistema";   C="Archivos corruptos que SFC no pudo reparar"; T="dism"}
        @{N="SFC  —  Verificar archivos del sistema";  C="Crashes, pantallazos azules o archivos daniados"; T="sfc"}
        @{N="Reset de red (Winsock + IP + DNS)";       C="Problemas de conexion o internet inestable"; T="network"}
    ) | ForEach-Object {
        $item=New-Object System.Windows.Forms.ListViewItem
        $item.Text=$_.N; $item.Tag=$_.T
        $item.SubItems.Add($_.C)|Out-Null
        $item.Checked=switch($_.T){
            "chkdsk"  { $tieneDiscoFalla }
            "dism"    { $tieneArchivos }
            "sfc"     { $tieneArchivos -or $tieneKernelPower }
            "network" { $tieneRed }
            default   { $false }
        }
        # Resaltar en naranja los pre-tildados
        if ($item.Checked) { $item.ForeColor = $script:colors.Orange }
        $lvRep.Items.Add($item)|Out-Null
    }
}

function Show-AvisoReparacion {
    $rtbLog.Clear()
    $rtbLog.SelectionColor=$script:colors.Purple
    $rtbLog.AppendText("REPARACION DEL SISTEMA`r`n")
    $rtbLog.SelectionColor=$script:colors.BorderColor
    $rtbLog.AppendText("────────────────────────────`r`n`r`n")
    if(-not $script:Diagnostico){
        $rtbLog.SelectionColor=$script:colors.Yellow
        $rtbLog.AppendText("Primero ejecuta el diagnostico para que pueda decirte que herramientas necesitas.`r`n")
        return
    }
    if($script:Diagnostico.RecomendarReparacion -or $script:Diagnostico.ProblemasGraves.Count -gt 0){
        $rtbLog.SelectionColor=$script:colors.Orange
        $rtbLog.AppendText("Encontre problemas que conviene reparar:`r`n`r`n")
        foreach($p in $script:Diagnostico.ProblemasGraves){
            $rtbLog.SelectionColor=$script:colors.Orange
            $rtbLog.AppendText("  - $p`r`n")
        }
        $rtbLog.AppendText("`r`n")
        $rtbLog.SelectionColor=$script:colors.Yellow
        $rtbLog.AppendText("Los items correspondientes ya estan pre-marcados.`r`nRevisa cuales queres ejecutar y hace clic en el boton de abajo.`r`n")
    } else {
        $rtbLog.SelectionColor=$script:colors.Green
        $rtbLog.AppendText("Tu PC no muestra problemas que necesiten reparacion urgente.`r`n`r`n")
        $rtbLog.SelectionColor=$script:colors.TextPrimary
        $rtbLog.AppendText("Estas herramientas estan disponibles por si las necesitas en algun momento.`r`n`r`n")
        $rtbLog.SelectionColor=$script:colors.TextDim
        $rtbLog.AppendText("Hace clic en cualquier herramienta para ver para que sirve exactamente.")
    }
}

# Sobreescribir el evento del tab para mostrar aviso en REPARACION
$tabControl.Add_SelectedIndexChanged({
    if($tabControl.SelectedTab -eq $tabRep){
        Show-AvisoReparacion
    } elseif($script:Diagnostico){
        Show-ResumenDiag
    }
})

function Refresh-HistorialDisplay {
    $lvHistorial.Items.Clear()
    for($i=0;$i -lt [math]::Min(30,$script:Historial.Count);$i++){
        $e=$script:Historial[$i]
        $item=New-Object System.Windows.Forms.ListViewItem
        $item.Text=$e.Fecha.ToString("dd/MM HH:mm")
        $item.SubItems.Add($e.Nombre)|Out-Null
        $item.ForeColor=if($e.Exitosa){$script:colors.Green}else{$script:colors.Red}
        $lvHistorial.Items.Add($item)|Out-Null
    }
}

function Apply-Theme {
    $c=$script:colors
    $form.BackColor=$c.BgDark
    $headerPanel.BackColor=$c.BgHeader
    $lblTitle.ForeColor=$c.Accent; $lblSubtitle.ForeColor=$c.TextDim
    $btnTheme.BackColor=$c.BgCard2; $btnTheme.ForeColor=$c.TextPrimary
    $leftPanel.BackColor=$c.BgPanel
    $lblHwTitle.ForeColor=$c.Accent
    $rtbHardware.BackColor=$c.BgLog; $rtbHardware.ForeColor=$c.TextSecond
    $btnAnalyze.BackColor=$c.Accent; $btnAnalyze.ForeColor=$c.BgDark
    $lblHistTitle.ForeColor=$c.Accent
    $lvHistorial.BackColor=$c.BgCard; $lvHistorial.ForeColor=$c.TextSecond
    $centerPanel.BackColor=$c.BgPanel; $tabControl.BackColor=$c.BgCard
    foreach($tp in @($tabOpt,$tabLimp,$tabPriv,$tabRep)){$tp.BackColor=$c.BgCard;$tp.ForeColor=$c.TextPrimary}
    foreach($lv in @($lvOpt,$lvLimp,$lvPriv,$lvRep)){$lv.BackColor=$c.BgCard;$lv.ForeColor=$c.TextPrimary}
    $btnVistaPrevia.BackColor=$c.BgCard2; $btnVistaPrevia.ForeColor=$c.TextPrimary
    $btnAplicar.BackColor=$c.Green; $btnAplicar.ForeColor=$c.BgDark
    $btnRestaurar.BackColor=$c.BgCard2; $btnRestaurar.ForeColor=$c.TextPrimary; $btnRestaurar.FlatAppearance.BorderColor=$c.Red
    $rightPanel.BackColor=$c.BgPanel; $lblLog.ForeColor=$c.Accent
    $rtbLog.BackColor=$c.BgLog; $rtbLog.ForeColor=$c.TextPrimary
    $statusBar.BackColor=$c.BgStatus; $lblStatus.ForeColor=$c.TextDim; $lblVer.ForeColor=$c.TextDim
}

# ============================================================================
#  ARRANQUE
# ============================================================================
$form.Add_Shown({
    Apply-Theme
    Load-Historial
    Refresh-HistorialDisplay

    $rtbLog.SelectionColor=$script:colors.Accent
    $rtbLog.AppendText("WINDOWS DE MENTE v2.0`r`n")
    $rtbLog.SelectionColor=$script:colors.TextDim
    $rtbLog.AppendText("'Cuando estas mal, no te olvides de mi...'`r`n`r`n")
    $rtbLog.SelectionColor=$script:colors.TextPrimary
    $rtbLog.AppendText("Hola! Estoy aca para ayudarte a que tu PC ande mejor.`r`n`r`n")
    $rtbLog.SelectionColor=$script:colors.Yellow
    $rtbLog.AppendText("Para empezar, hace clic en ANALIZAR MI PC`r`n`r`n")
    $rtbLog.SelectionColor=$script:colors.TextDim
    $rtbLog.AppendText("Voy a revisar el hardware, el estado de Windows,`r`n")
    $rtbLog.AppendText("el rendimiento, la red, el disco y los errores`r`n")
    $rtbLog.AppendText("recientes para contarte exactamente que encontre`r`n")
    $rtbLog.AppendText("y por que te propongo cada cosa.")
})

$form.Add_FormClosing({Save-Historial})
$form.ShowDialog()|Out-Null
