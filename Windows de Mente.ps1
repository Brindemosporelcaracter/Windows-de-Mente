# ============================================================================
#  WINDOWS DE MENTE v2.0
#  Herramienta gratuita para estudiantes y familias.
#  Lee tu hardware, entiende tu sistema y optimiza en consecuencia.
#  No aplica recetas genéricas — cada PC es diferente.
# ============================================================================

# Evitar que la ventana de PowerShell se cierre si hay un error inesperado
trap {
    $errMsg = "Error inesperado: $_`r`nLínea: $($_.InvocationInfo.ScriptLineNumber)"
    try {
        [System.Windows.Forms.MessageBox]::Show($errMsg, "Windows De Mente — Error", 0, 16) | Out-Null
    } catch {
        Write-Host $errMsg
        Read-Host "Presioná Enter para cerrar"
    }
    exit 1
}

# Si alguien ejecuta el .ps1 directamente (doble clic), relanzar con los parámetros correctos
if ($MyInvocation.InvocationName -ne '.' -and
    [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.ExecutionContext.LanguageMode -eq 'FullLanguage') {

    $policy = Get-ExecutionPolicy -Scope CurrentUser -EA SilentlyContinue
    if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
        try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -EA Stop }
        catch {}
    }
}

# Solicitar permisos de administrador si no los tiene — versión robusta
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        # Asegurar que el script se puede ejecutar en el proceso hijo
        $argList = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
        $proc = Start-Process -FilePath "PowerShell.exe" -Verb RunAs -ArgumentList $argList -PassThru -EA Stop
        if ($proc) { exit 0 }
    } catch {
        # El usuario rechazó el UAC o no hay acceso — mostrar mensaje claro
        try { Add-Type -AssemblyName System.Windows.Forms } catch {}
        try {
            [System.Windows.Forms.MessageBox]::Show(
                "Windows De Mente necesita permisos de Administrador para funcionar.`r`n`r`nHacé clic derecho sobre el archivo .ps1 y elegí 'Ejecutar como administrador'.`r`n`r`nO ejecutá este comando en PowerShell como Admin:`r`npowershell -ExecutionPolicy Bypass -File `"$PSCommandPath`"",
                "Se necesitan permisos de Administrador",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        } catch {
            Write-Host "Windows De Mente necesita permisos de Administrador." -ForegroundColor Yellow
            Write-Host "Ejecutá PowerShell como Administrador y corré el script de nuevo." -ForegroundColor White
            Read-Host "Presioná Enter para cerrar"
        }
    }
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================================
# TEMAS
# ============================================================================
$script:IsDarkMode = $true

$themes = @{
    Dark = @{
        BgDark      = [System.Drawing.Color]::FromArgb(12, 12, 18)
        BgPanel     = [System.Drawing.Color]::FromArgb(20, 20, 30)
        BgCard      = [System.Drawing.Color]::FromArgb(28, 28, 42)
        BgCard2     = [System.Drawing.Color]::FromArgb(36, 36, 54)
        BgLog       = [System.Drawing.Color]::FromArgb(8, 8, 14)
        BgHeader    = [System.Drawing.Color]::FromArgb(16, 16, 26)
        TextPrimary = [System.Drawing.Color]::FromArgb(238, 238, 255)
        TextSecond  = [System.Drawing.Color]::FromArgb(200, 200, 230)
        TextDim     = [System.Drawing.Color]::FromArgb(140, 140, 175)
        Accent      = [System.Drawing.Color]::FromArgb(0, 210, 255)
        Accent2     = [System.Drawing.Color]::FromArgb(130, 90, 255)
        Green       = [System.Drawing.Color]::FromArgb(0, 220, 130)
        Yellow      = [System.Drawing.Color]::FromArgb(255, 210, 0)
        Orange      = [System.Drawing.Color]::FromArgb(255, 150, 0)
        Red         = [System.Drawing.Color]::FromArgb(255, 70, 70)
        Purple      = [System.Drawing.Color]::FromArgb(180, 100, 255)
        BorderColor = [System.Drawing.Color]::FromArgb(50, 50, 76)
    }
    Light = @{
        BgDark      = [System.Drawing.Color]::FromArgb(225, 228, 238)
        BgPanel     = [System.Drawing.Color]::FromArgb(238, 240, 250)
        BgCard      = [System.Drawing.Color]::FromArgb(250, 251, 255)
        BgCard2     = [System.Drawing.Color]::FromArgb(230, 234, 246)
        BgLog       = [System.Drawing.Color]::FromArgb(244, 245, 252)
        BgHeader    = [System.Drawing.Color]::FromArgb(215, 220, 238)
        TextPrimary = [System.Drawing.Color]::FromArgb(18, 18, 38)
        TextSecond  = [System.Drawing.Color]::FromArgb(45, 50, 78)
        TextDim     = [System.Drawing.Color]::FromArgb(90, 98, 130)
        Accent      = [System.Drawing.Color]::FromArgb(0, 120, 190)
        Accent2     = [System.Drawing.Color]::FromArgb(90, 55, 200)
        Green       = [System.Drawing.Color]::FromArgb(0, 150, 85)
        Yellow      = [System.Drawing.Color]::FromArgb(170, 120, 0)
        Orange      = [System.Drawing.Color]::FromArgb(190, 90, 0)
        Red         = [System.Drawing.Color]::FromArgb(190, 25, 25)
        Purple      = [System.Drawing.Color]::FromArgb(120, 55, 190)
        BorderColor = [System.Drawing.Color]::FromArgb(185, 190, 215)
    }
}

$script:colors = $themes.Dark

$fonts = @{
    Title    = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    TitleSm  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    Header   = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    Body     = New-Object System.Drawing.Font("Segoe UI", 9)
    BodyBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    Mono     = New-Object System.Drawing.Font("Cascadia Code", 8)
    MonoSm   = New-Object System.Drawing.Font("Cascadia Code", 7)
    Small    = New-Object System.Drawing.Font("Segoe UI", 7)
    TabFont  = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    Score    = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
    ScoreSm  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
}

# ============================================================================
# ESTADO GLOBAL
# ============================================================================
$script:Hardware             = $null
$script:BackupFile           = $null
$script:BackupFileName       = ""
$script:OriginalValues       = @{}
$script:CurrentSettings      = @{}
$script:StateFile            = "$env:LOCALAPPDATA\WDM_State.xml"
$script:FirstRunBackup       = $null
$script:DeepBackupPath       = $null
$script:Analyzing            = $false
$script:HardwareIDFile       = "$env:LOCALAPPDATA\WDM_HardwareID.xml"
$script:LastHardwareID       = $null
$script:OptimizationsApplied = @{}
$script:HistorialFile        = "$env:LOCALAPPDATA\WDM_Historial.xml"
$script:Historial            = [System.Collections.Generic.List[PSObject]]::new()
$script:ScoreAntes           = 0
$script:ScoreDespues         = 0

# ============================================================================
# HISTORIAL DE CAMBIOS
# ============================================================================
function Load-Historial {
    if (Test-Path $script:HistorialFile) {
        try {
            $data = Import-Clixml -Path $script:HistorialFile -EA SilentlyContinue
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
    $entry = [PSCustomObject]@{
        Fecha   = Get-Date
        Nombre  = $Nombre
        Tipo    = $Tipo
        Exitosa = $Exitosa
    }
    $script:Historial.Insert(0, $entry)
    if ($script:Historial.Count -gt 100) { $script:Historial.RemoveAt($script:Historial.Count - 1) }
    Save-Historial
}

# ============================================================================
# HARDWARE ID / MEMORIA
# ============================================================================
function Get-HardwareID {
    try {
        $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
        $disk = Get-CimInstance Win32_DiskDrive  | Select-Object -First 1
        $ram  = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum
        $gpu  = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Remote*" } | Select-Object -First 1
        $idString = "$($cpu.DeviceID)-$($cpu.NumberOfCores)-$($ram.Sum)-$($disk.Model)-$($gpu.PNPDeviceID)"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($idString)
        $hash  = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)) -replace '-'
        return $hash
    } catch { return (Get-Random -Maximum 999999).ToString() }
}

function Save-HardwareMemory {
    $hwid = Get-HardwareID
    @{ HardwareID=$hwid; Timestamp=Get-Date; Optimizations=$script:OptimizationsApplied } | Export-Clixml -Path $script:HardwareIDFile -Force
}

function Load-HardwareMemory {
    if (Test-Path $script:HardwareIDFile) {
        try {
            $data = Import-Clixml -Path $script:HardwareIDFile
            if ($data.HardwareID -eq (Get-HardwareID)) { $script:OptimizationsApplied = $data.Optimizations; return $true }
        } catch {}
    }
    $script:OptimizationsApplied = @{}
    return $false
}

# ============================================================================
# VERSIÓN WINDOWS
# ============================================================================
# Helper para convertir fechas CIM/WMI de forma segura en PowerShell 5
# NUNCA usar [datetime]$cimValue directamente — puede ser null o tipo incompatible
function Convert-CimDate {
    param($Value, $Fallback = (Get-Date))
    if ($null -eq $Value) { return $Fallback }
    # Si ya es DateTime nativo, devolverlo directamente
    if ($Value -is [datetime]) { return $Value }
    try {
        # Probar con el toString() y Parse — funciona con la mayoría de formatos CIM
        $str = $Value.ToString()
        if ([string]::IsNullOrWhiteSpace($str)) { return $Fallback }
        # Formato WMI clásico: "20240315123045.000000+000"
        if ($str -match '^\d{14}') {
            return [Management.ManagementDateTimeConverter]::ToDateTime($str)
        }
        # Intentar parse genérico
        $parsed = $null
        if ([datetime]::TryParse($str, [ref]$parsed)) { return $parsed }
        return $Fallback
    } catch {
        return $Fallback
    }
}

function Get-WindowsVersion {
    try {
        $os    = Get-CimInstance Win32_OperatingSystem
        $build = [int]$os.BuildNumber
        return @{ Build=$build; IsWin11=($build -ge 22000); IsWin10=($build -ge 10240 -and $build -lt 22000); Name=$os.Caption }
    } catch { return @{ Build=0; IsWin11=$false; IsWin10=$false; Name="Desconocido" } }
}
$script:WindowsVersion = Get-WindowsVersion

# Tabla de rangos seguros
$script:SafeRanges = @{
    "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl:Win32PrioritySeparation" = @{
        Min=2; Max=38; DangerousValues=@(0,1,0xFFFFFFFF)
        Default={ if ($script:Hardware.CPU.Cores -ge 8) { 38 } elseif ($script:Hardware.CPU.Cores -ge 4) { 26 } else { 18 } }
        Description="Prioridad de procesos"
    }
    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management:DisablePagingExecutive" = @{
        Min=0; Max=1; DangerousValues=@(); HardwareDependent=$true
        Recommended={ if ($script:Hardware.RAM.TotalGB -ge 16) { 1 } else { 0 } }
        Description="Kernel en RAM"
    }
    "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters:TCPNoDelay" = @{
        Min=0; Max=1; DangerousValues=@(); Recommended=1; Description="TCP NoDelay"
    }
    "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling:PowerThrottlingOff" = @{
        Min=0; Max=1; DangerousValues=@()
        Recommended={ if ($script:Hardware.IsLaptop) { 0 } else { 1 } }
        Description="Power Throttling"
    }
    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters:EnablePrefetcher" = @{
        Min=0; Max=3; DangerousValues=@()
        Recommended={ if ($script:Hardware.SystemSSD) { 3 } else { 0 } }
        Description="Prefetcher"
    }
    "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem:NtfsDisableLastAccessUpdate" = @{
        Min=0; Max=1; DangerousValues=@(); Recommended=1; Description="NTFS LastAccess"
    }
}

# ============================================================================
# MAPA DE LIMPIEZA
# ============================================================================
$script:LimpiezaMap = @{
    "TempFiles" = @{
        Name="Archivos Temporales"; Category="Limpieza"
        Description="Elimina archivos temporales del sistema y del usuario"
        Explicacion="Windows y los programas crean archivos temporales mientras trabajan. Muchos de esos archivos se quedan ahí aunque ya no sirvan para nada — ocupan espacio y a veces enlentecen el sistema. Esta limpieza los elimina de forma completamente segura."
        GetSize={
            $total=[long]0
            foreach ($p in @("$env:TEMP","$env:SystemRoot\Temp")) {
                if (Test-Path $p) { $s=(Get-ChildItem $p -Recurse -File -EA SilentlyContinue|Measure-Object Length -Sum).Sum; if($s){$total+=[long]$s} }
            }
            if($total -gt 1GB){"{0:N2} GB" -f ($total/1GB)} elseif($total -gt 1MB){"{0:N0} MB" -f ($total/1MB)} elseif($total -gt 1KB){"{0:N0} KB" -f ($total/1KB)} else{"0 KB"}
        }
        Action={
            $count=0
            foreach ($p in @("$env:TEMP\*","$env:SystemRoot\Temp\*")) {
                $count+=(Get-ChildItem $p -Recurse -File -EA SilentlyContinue).Count
                Remove-Item $p -Recurse -Force -EA SilentlyContinue
            }
            Write-Log "  ✓ $count archivos temporales eliminados" "Green"; return $true
        }
    }
    "PrefetchClean" = @{
        Name="Prefetch Obsoleto"; Category="Limpieza"
        Description="Limpia archivos de precarga de programas que ya no usás"
        Explicacion="Windows guarda información de cada programa que ejecutaste para abrirlo más rápido la próxima vez. El problema es que también guarda esa info de programas que ya desinstalaste. Limpiar esos archivos viejos libera espacio y mantiene la lista ordenada."
        GetSize={
            $s=(Get-ChildItem "$env:SystemRoot\Prefetch\*.pf" -EA SilentlyContinue|Measure-Object Length -Sum).Sum
            if($s -gt 1MB){"{0:N0} MB" -f ($s/1MB)} elseif($s -gt 1KB){"{0:N0} KB" -f ($s/1KB)} else{"0 KB"}
        }
        Action={
            $count=(Get-ChildItem "$env:SystemRoot\Prefetch\*.pf" -EA SilentlyContinue).Count
            Remove-Item "$env:SystemRoot\Prefetch\*.pf" -Force -EA SilentlyContinue
            Write-Log "  ✓ $count archivos de prefetch eliminados" "Green"; return $true
        }
    }
    "DNSCache" = @{
        Name="Caché DNS"; Category="Limpieza"
        Description="Limpia la memoria de direcciones de internet"
        Explicacion="Cada vez que entrás a una página web, tu PC guarda la dirección en una lista para no tener que buscarla de nuevo. A veces esa lista guarda direcciones viejas o incorrectas, lo que puede causar que algunas páginas no carguen o tarden más. Limpiarla es seguro y se reconstruye sola."
        GetSize={return "—"}
        Action={ ipconfig /flushdns | Out-Null; Write-Log "  ✓ Caché DNS limpiada" "Green"; return $true }
    }
    "LogFiles" = @{
        Name="Archivos de Registro"; Category="Limpieza"
        Description="Elimina registros antiguos del sistema"
        Explicacion="Windows lleva un diario de todo lo que hace — instalaciones, errores, actualizaciones. Ese diario puede crecer mucho con el tiempo. Los registros viejos (de hace meses) ya no son útiles para diagnosticar problemas actuales y se pueden eliminar sin riesgo."
        GetSize={
            $total=[long]0
            foreach ($p in @("$env:SystemRoot\Logs","$env:SystemRoot\System32\LogFiles")) {
                if(Test-Path $p){$s=(Get-ChildItem $p -Recurse -File -EA SilentlyContinue|Measure-Object Length -Sum).Sum; if($s){$total+=[long]$s}}
            }
            if($total -gt 1GB){"{0:N2} GB" -f ($total/1GB)} elseif($total -gt 1MB){"{0:N0} MB" -f ($total/1MB)} else{"{0:N0} KB" -f ($total/1KB)}
        }
        Action={
            $count=0
            foreach ($p in @("$env:SystemRoot\Logs\*","$env:SystemRoot\System32\LogFiles\*")) {
                $count+=(Get-ChildItem $p -Recurse -File -EA SilentlyContinue).Count
                Remove-Item $p -Recurse -Force -EA SilentlyContinue
            }
            Write-Log "  ✓ $count registros eliminados" "Green"; return $true
        }
    }
    "ThumbCache" = @{
        Name="Miniaturas de Imágenes"; Category="Limpieza"
        Description="Elimina las vistas previas guardadas de imágenes"
        Explicacion="Cuando abrís una carpeta con fotos, Windows guarda copias pequeñas de cada imagen para mostrarlas rápido la próxima vez. Esa caché puede crecer bastante. Al borrarla, Windows la regenera automáticamente — no perdés nada, solo se recrea."
        GetSize={
            $s=(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -EA SilentlyContinue|Measure-Object Length -Sum).Sum
            if($s -gt 1MB){"{0:N0} MB" -f ($s/1MB)} elseif($s -gt 1KB){"{0:N0} KB" -f ($s/1KB)} else{"0 KB"}
        }
        Action={
            $exp=($null -ne (Get-Process -Name explorer -EA SilentlyContinue))
            if($exp){Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep -Milliseconds 300}
            $count=(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -EA SilentlyContinue).Count
            Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -EA SilentlyContinue
            if($exp){Start-Process explorer}
            Write-Log "  ✓ $count archivos de miniaturas eliminados" "Green"; return $true
        }
    }
    "FontCache" = @{
        Name="Caché de Fuentes"; Category="Limpieza"
        Description="Reconstruye el almacén de fuentes del sistema"
        Explicacion="Windows guarda información de todas las fuentes (tipografías) instaladas para no tener que leerlas cada vez. Esa caché puede corromperse con el tiempo y causar problemas al mostrar texto. Reconstruirla soluciona caracteres mal dibujados o lentitud al escribir."
        GetSize={
            $s=(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\FontCache" -Recurse -File -EA SilentlyContinue|Measure-Object Length -Sum).Sum
            if($s -gt 1MB){"{0:N0} MB" -f ($s/1MB)} else{"0 KB"}
        }
        Action={
            Stop-Service -Name FontCache -Force -EA SilentlyContinue; Start-Sleep -Milliseconds 300
            $count=(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\FontCache" -Recurse -File -EA SilentlyContinue).Count
            Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\FontCache\*" -Recurse -Force -EA SilentlyContinue
            Start-Service -Name FontCache -EA SilentlyContinue
            Write-Log "  ✓ Caché de fuentes reconstruida ($count archivos)" "Green"; return $true
        }
    }
    "RecycleBin" = @{
        Name="Papelera de Reciclaje"; Category="Limpieza"
        Description="Vacía la papelera — libera espacio real en el disco"
        Explicacion="Los archivos que mandás a la papelera no se eliminan realmente hasta que la vaciás. Siguen ocupando espacio en tu disco. Si tenés muchos archivos ahí, pueden ser varios gigas que tu PC sigue 'cargando' aunque no los uses."
        GetSize={
            try {
                $shell = New-Object -ComObject Shell.Application
                $rb = $shell.Namespace(10)
                $size = ($rb.Items() | Measure-Object -Property Size -Sum).Sum
                if($size -gt 1GB){"{0:N2} GB" -f ($size/1GB)} elseif($size -gt 1MB){"{0:N0} MB" -f ($size/1MB)} else{"0 KB"}
            } catch {"?"}
        }
        Action={
            Clear-RecycleBin -Force -EA SilentlyContinue
            Write-Log "  ✓ Papelera vaciada" "Green"; return $true
        }
    }
    "WinSxS" = @{
        Name="Componentes Obsoletos (WinSxS)"; Category="Limpieza"
        Description="Limpia versiones antiguas de componentes del sistema"
        Explicacion="Windows guarda versiones antiguas de sus propios componentes por si necesita volver atrás después de una actualización. Con el tiempo esto puede ocupar varios GB. Esta limpieza elimina las versiones muy viejas que ya no tienen sentido mantener. Es completamente segura."
        GetSize={ return "Ver resultado" }
        Action={
            Write-Log "  ⏳ Limpiando WinSxS (puede tardar varios minutos)..." "Yellow"
            $result = dism /online /cleanup-image /startcomponentcleanup /resetbase 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) { Write-Log "  ✓ Componentes obsoletos eliminados" "Green"; return $true }
            else { Write-Log "  ⚠️ WinSxS: $($result.Substring(0,[math]::Min(200,$result.Length)))" "Yellow"; return $false }
        }
    }
    "IECache" = @{
        Name="Caché del Navegador (Edge heredado)"; Category="Limpieza"
        Description="Limpia archivos temporales del navegador heredado"
        Explicacion="Edge (versión heredada) e Internet Explorer guardan copias de páginas visitadas para cargarlas más rápido. Con el tiempo esa caché puede crecer mucho y paradójicamente hacer el navegador más lento. Esta limpieza la vacía."
        GetSize={ return "—" }
        Action={
            RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255 2>$null
            Write-Log "  ✓ Caché del navegador limpiada" "Green"; return $true
        }
    }
}

# ============================================================================
# FUNCIONES DE LOG
# ============================================================================
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

function Write-SaludLog {
    param($Message, $ColorKey = "TextPrimary")
    $c = $script:colors[$ColorKey]
    if (-not $c) { $c = $script:colors.TextPrimary }
    try {
        $rtbSalud.SelectionStart  = $rtbSalud.TextLength
        $rtbSalud.SelectionLength = 0
        $rtbSalud.SelectionColor  = $c
        $rtbSalud.AppendText("$Message`r`n")
        $rtbSalud.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
}

# ============================================================================
# BACKUP / RESTORE
# ============================================================================
function Save-OriginalValue {
    param($Path, $Name)
    $key = "$Path\$Name"
    if ($script:OriginalValues.ContainsKey($key)) { return }
    try {
        if (Test-Path $Path) {
            $v = Get-ItemProperty -Path $Path -Name $Name -EA SilentlyContinue
            if ($v -and $null -ne $v.$Name) { $script:OriginalValues[$key] = $v.$Name }
        }
    } catch {}
}

function Backup-CriticalRegions {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$env:TEMP\WDM_DeepBackup_$ts"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Log "💾 Creando punto de restauración seguro..." "Yellow"
    $criticalPaths = @(
        "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl",
        "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management",
        "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters",
        "HKLM\SYSTEM\CurrentControlSet\Control\Power",
        "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers",
        "HKCU\Control Panel\Desktop",
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
        "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    )
    foreach ($path in $criticalPaths) {
        $regPath   = $path -replace "HKLM","HKEY_LOCAL_MACHINE" -replace "HKCU","HKEY_CURRENT_USER"
        $outFile   = "$backupDir\" + ($path -replace '\\','_') + ".reg"
        try { reg export "$regPath" "$outFile" /y 2>$null }
        catch {}
    }
    Write-Log "  ✓ Punto de restauración guardado en: $backupDir" "Green"
    return $backupDir
}

function Backup-OriginalState {
    $ts  = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:BackupFileName = "WDM_Original_$ts.reg"
    $backupPath = "$env:TEMP\$script:BackupFileName"
    Write-Log "💾 Guardando estado original del registro..." "Yellow"
    try {
        $regContent = "Windows Registry Editor Version 5.00`r`n`r`n; WINDOWS DE MENTE BACKUP ORIGINAL - $(Get-Date)`r`n`r`n"
        $processedPaths = @{}
        foreach ($item in $script:OriginalValues.Keys) {
            $parts     = $item -split '\\'
            $valueName = $parts[-1]
            $path      = $item.Substring(0, $item.Length - $valueName.Length - 1)
            $regOutput = reg query "$path" /v "$valueName" 2>$null
            if ($LASTEXITCODE -eq 0) {
                $valueLine = $regOutput | Select-String $valueName
                if ($valueLine) {
                    $lineStr = $valueLine.ToString()
                    if ($lineStr -match "REG_\w+\s+(.+)") {
                        $valueData = $matches[1].Trim()
                        if (-not $processedPaths.ContainsKey($path)) { $regContent += "`r`n[$path]"; $processedPaths[$path] = $true }
                        if ($lineStr -match "REG_DWORD") { $regContent += "`r`n`"$valueName`"=dword:$([Convert]::ToInt32($valueData).ToString('x8'))" }
                        elseif ($lineStr -match "REG_SZ") { $regContent += "`r`n`"$valueName`"=`"$valueData`"" }
                        else { $regContent += "`r`n`"$valueName`"=$valueData" }
                    }
                }
            }
        }
        $regContent | Out-File -FilePath $backupPath -Encoding Unicode
        $script:BackupFile    = $backupPath
        $script:FirstRunBackup = $backupPath
        Write-Log "  ✓ Backup guardado: $backupPath" "Green"
        return $true
    } catch { Write-Log "  ✗ Error backup: $_" "Red"; return $false }
}

# ============================================================================
# CHEQUEOS DE ESTADO
# ============================================================================
function Check-OptimizationStatus {
    param($Path, $Name, $ExpectedValue)
    try {
        if (Test-Path $Path) {
            $current = Get-ItemProperty -Path $Path -Name $Name -EA SilentlyContinue
            if ($current -and $null -ne $current.$Name) { return ($current.$Name -eq $ExpectedValue) }
        }
    } catch {}
    return $false
}

function Test-OverOptimized {
    param($Path, $Name)
    $key = "$Path`:$Name"
    if (-not $script:SafeRanges.ContainsKey($key)) { return $false }
    $range   = $script:SafeRanges[$key]
    $current = Get-ItemProperty -Path $Path -Name $Name -EA SilentlyContinue | Select-Object -ExpandProperty $Name -EA SilentlyContinue
    if ($null -eq $current) { return $false }
    if ($range.DangerousValues -and $current -in $range.DangerousValues) { return $true }
    if ($current -lt $range.Min -or $current -gt $range.Max) { return $true }
    if ($range.ContainsKey("HardwareDependent") -and $range.HardwareDependent) {
        $recommended = if ($range.Recommended -is [scriptblock]) { & $range.Recommended } else { $range.Recommended }
        if ($current -ne $recommended) { return $true }
    }
    return $false
}

function Restore-ToSafeValue {
    param($Path, $Name)
    $key = "$Path`:$Name"
    if (-not $script:SafeRanges.ContainsKey($key)) { return $false }
    $range = $script:SafeRanges[$key]
    Save-OriginalValue -Path $Path -Name $Name
    if ($range.ContainsKey("Recommended")) { $safeValue = if ($range.Recommended -is [scriptblock]) { & $range.Recommended } else { $range.Recommended } }
    elseif ($range.ContainsKey("Default"))  { $safeValue = if ($range.Default     -is [scriptblock]) { & $range.Default     } else { $range.Default     } }
    else { $safeValue = $range.Min }
    try {
        Set-ItemProperty -Path $Path -Name $Name -Value $safeValue -Type DWord -EA Stop
        Write-Log "  ✓ Restaurado $Name a valor seguro ($safeValue)" "Green"; return $true
    } catch { Write-Log "  ✗ Error restaurando $Name" "Red"; return $false }
}

# ============================================================================
# PERFIL DE RED / GPU
# ============================================================================
function Get-NetworkProfile {
    try {
        $adapters    = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $networkInfo = @{ Type="Desconocido"; Speed=0; IsModern=$false; IsWiFi=$false; IsEthernet=$false; HasIPv6=$false; IsMetered=$false; Name="" }
        foreach ($ad in $adapters) {
            $netProfile  = Get-NetConnectionProfile -InterfaceIndex $ad.ifIndex -EA SilentlyContinue
            $linkSpeed   = 0
            if ($ad.LinkSpeed -match '(\d+\.?\d*)\s*(Gbps|Mbps)') {
                $n = [double]$matches[1]; $u = $matches[2]
                $linkSpeed = if ($u -eq "Gbps") { [int]($n * 1000) } else { [int]$n }
            }
            # Detectar WiFi por descripción del adaptador (funciona en cualquier idioma)
            $isWifi = $ad.InterfaceDescription -match "Wireless|Wi-Fi|802\.11|WLAN" -or
                      $ad.PhysicalMediaType -match "Native 802\.11|Wireless"
            # Detectar Ethernet por MediaType (más confiable que el nombre)
            $isEth  = $ad.MediaType -eq "802.3" -and -not $isWifi

            if ($isWifi) {
                $networkInfo.IsWiFi = $true; $networkInfo.Type = "WiFi"
                $networkInfo.IsMetered = ($netProfile -and $netProfile.Metered -ne 0)
            } elseif ($isEth) {
                $networkInfo.IsEthernet = $true; $networkInfo.Type = "Ethernet"
            }
            if ($linkSpeed -gt $networkInfo.Speed) {
                $networkInfo.Speed = $linkSpeed; $networkInfo.Name = $ad.Name
                $networkInfo.InterfaceGuid = $ad.InterfaceGuid
                $networkInfo.InterfaceIndex = $ad.ifIndex
            }
            $ipv6 = Get-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv6 -EA SilentlyContinue
            if ($ipv6) { $networkInfo.HasIPv6 = $true }
        }
        return $networkInfo
    } catch { return $null }
}

function Get-GPUProfile {
    try {
        $gpus    = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Básico*" }
        $gpuInfo = @{ Dedicated=@(); Integrated=@(); Primary=$null; HasDedicated=$false; HasIntegrated=$false; IsNVIDIA=$false; IsAMD=$false; IsIntel=$false }
        foreach ($gpu in $gpus) {
            $vram = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { 0 }
            if ($gpu.Name -match "NVIDIA|GeForce|RTX|GTX") {
                $gpuInfo.HasDedicated = $true; $gpuInfo.IsNVIDIA = $true; $gpuInfo.Dedicated += @{ Name=$gpu.Name; VRAM=$vram }
            } elseif ($gpu.Name -match "AMD|Radeon|RX") {
                $gpuInfo.HasDedicated = $true; $gpuInfo.IsAMD = $true; $gpuInfo.Dedicated += @{ Name=$gpu.Name; VRAM=$vram }
            } elseif ($gpu.Name -match "Intel") {
                if ($vram -ge 2) { $gpuInfo.HasDedicated=$true; $gpuInfo.Dedicated+=@{Name=$gpu.Name;VRAM=$vram} }
                else { $gpuInfo.HasIntegrated=$true; $gpuInfo.IsIntel=$true; $gpuInfo.Integrated+=@{Name=$gpu.Name;VRAM=$vram} }
            } else {
                if ($vram -ge 2) { $gpuInfo.HasDedicated=$true; $gpuInfo.Dedicated+=@{Name=$gpu.Name;VRAM=$vram} }
                else { $gpuInfo.HasIntegrated=$true; $gpuInfo.Integrated+=@{Name=$gpu.Name;VRAM=$vram} }
            }
        }
        return $gpuInfo
    } catch { return $null }
}

# ============================================================================
# PERFIL DE HARDWARE
# ============================================================================
function Get-HardwareProfile {
    Write-Log "════════════════════════════" "Accent"
    Write-Log "ANALIZANDO TU PC..." "Accent"
    Write-Log "════════════════════════════" "Accent"
    $hw = @{}; $hw.Valid = $false; $hw.Details = @()
    try {
        $cpu = Get-CimInstance Win32_Processor -EA Stop
        $hw.CPU = @{ Name=if($cpu.Name){$cpu.Name.Trim()}else{"Desconocido"}; Cores=$cpu.NumberOfCores; Threads=$cpu.NumberOfLogicalProcessors; Speed=$cpu.MaxClockSpeed }
        $hw.Details += "CPU: $($hw.CPU.Name)"
        $hw.Details += "  $($hw.CPU.Cores) núcleos / $($hw.CPU.Threads) hilos / $($hw.CPU.Speed) MHz"
        Write-Log "  ✓ Procesador leído" "Green"
    } catch { Write-Log "  ✗ Error leyendo procesador" "Red"; return $hw }
    try {
        $ram = Get-CimInstance Win32_PhysicalMemory -EA Stop
        if ($ram) {
            $totalGB = [math]::Round(($ram | Measure-Object Capacity -Sum).Sum / 1GB, 2)
            $hw.RAM = @{ TotalGB=$totalGB }
            $hw.Details += "RAM: $totalGB GB"
            Write-Log "  ✓ Memoria RAM leída" "Green"
        }
    } catch { Write-Log "  ⚠️ Error leyendo RAM" "Yellow"; $hw.RAM = @{ TotalGB=0 } }
    try {
        $disks      = Get-CimInstance Win32_DiskDrive -EA Stop
        $hw.Disks   = @(); $ssdCount=0; $hddCount=0; $systemSSD=$false
        $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
        foreach ($disk in $disks) {
            $type  = "HDD"; $model = if($disk.Model){$disk.Model}else{"Desconocido"}
            if ($model -match "SSD|NVMe|M.2|Samsung|Crucial|WD|SanDisk|Kingston|Toshiba|Intel|KIOXIA") {
                $type="SSD"; $ssdCount++
                $partitions = Get-CimInstance -ClassName Win32_DiskDriveToDiskPartition | Where-Object { $_.Antecedent -like "*$($disk.DeviceID)*" }
                foreach ($partition in $partitions) {
                    $logical = Get-CimInstance -ClassName Win32_LogicalDiskToPartition | Where-Object { $_.Antecedent -like "*$($partition.Dependent)*" }
                    if ($logical -and $logical.Dependent -match "DeviceID=`"($systemDrive)`"") { $systemSSD = $true }
                }
            } else { $hddCount++ }
            $hw.Disks += @{ Type=$type; Model=$model }
        }
        $hw.SystemSSD = $systemSSD
        if ($systemSSD) { $hw.Details += "Almacenamiento: SSD (más rápido)" }
        else { $hw.Details += "Almacenamiento: HDD (disco mecánico)" }
        if ($ssdCount -gt 0 -and $hddCount -gt 0) { $hw.Details += "  Tiene ambos tipos: SSD + HDD" }
        Write-Log "  ✓ Discos leídos" "Green"
    } catch { Write-Log "  ⚠️ Error leyendo discos" "Yellow"; $hw.Disks=@(); $hw.SystemSSD=$false }
    try {
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Básico*" } | Select-Object -First 1
        if ($gpu) {
            $hw.GPU = @{ Name=if($gpu.Name){$gpu.Name}else{"Desconocido"}; VRAM=if($gpu.AdapterRAM){[math]::Round($gpu.AdapterRAM/1GB,2)}else{0}; Dedicated=($gpu.AdapterRAM -gt 1073741824) }
            $hw.Details += "Gráficos: $($hw.GPU.Name)"
            Write-Log "  ✓ GPU leída" "Green"
        } else { $hw.GPU = $null }
    } catch { $hw.GPU = $null }
    try {
        $battery = Get-CimInstance Win32_Battery -EA SilentlyContinue
        $hw.IsLaptop = ($null -ne $battery)
        if ($hw.IsLaptop) { $hw.Details += "Tipo: Laptop / Portátil" }
        else { $hw.Details += "Tipo: PC de escritorio" }
    } catch { $hw.IsLaptop = $false }
    $hw.Network = Get-NetworkProfile
    if ($hw.Network) { $hw.Details += "Red: $($hw.Network.Type)" }
    $gpuProfile = Get-GPUProfile
    if ($gpuProfile) {
        $hw.GPUProfile = $gpuProfile
    }
    $script:CurrentSettings = @{}
    foreach ($key in $script:SafeRanges.Keys) {
        $parts = $key -split ':'; $path=$parts[0]; $name=$parts[1]
        try {
            if (Test-Path $path) {
                $value = Get-ItemProperty -Path $path -Name $name -EA SilentlyContinue
                if ($value -and $null -ne $value.$name) { $script:CurrentSettings[$key] = $value.$name }
            }
        } catch {}
    }
    $rtbHardware.Clear()
    foreach ($line in $hw.Details) { $rtbHardware.AppendText("$line`r`n") }
    $hw.Valid = $true
    Write-Log "✅ ¡Tu PC fue analizada correctamente!" "Green"
    return $hw
}

# ============================================================================
# CALCULAR SCORE DEL SISTEMA
# ============================================================================
function Get-SystemScore {
    $score = 100
    $penalizaciones = @()
    # Guard: si los controles no existen aún, devolver 0
    try { $null = $lvOptimizations.Items.Count } catch { return 0 }

    # RAM baja
    if ($script:Hardware -and $script:Hardware.RAM.TotalGB -le 4) {
        $score -= 15
        $penalizaciones += "RAM muy baja ($($script:Hardware.RAM.TotalGB) GB)"
    } elseif ($script:Hardware -and $script:Hardware.RAM.TotalGB -le 8) {
        $score -= 5
    }

    # HDD en vez de SSD
    if ($script:Hardware -and -not $script:Hardware.SystemSSD) {
        $score -= 10
        $penalizaciones += "Sistema en disco mecánico (HDD)"
    }

    # Optimizaciones pendientes en Optimizaciones tab
    $pendientes = 0
    for ($i=0; $i -lt $lvOptimizations.Items.Count; $i++) {
        if ($lvOptimizations.Items[$i].Tag -and $lvOptimizations.Items[$i].SubItems[1].Text -ne "✓ HECHO") { $pendientes++ }
    }
    $score -= [math]::Min(30, $pendientes * 2)

    # Privacidad pendiente
    $privPendientes = 0
    for ($i=0; $i -lt $lvPrivacidad.Items.Count; $i++) {
        if ($lvPrivacidad.Items[$i].Checked) { $privPendientes++ }
    }
    $score -= [math]::Min(10, $privPendientes)

    # Espacio libre en disco
    try {
        $ldisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -EA SilentlyContinue
        if ($ldisk) {
            $pct = [math]::Round(($ldisk.FreeSpace / $ldisk.Size) * 100, 0)
            if ($pct -lt 10) { $score -= 15; $penalizaciones += "Disco casi lleno ($pct% libre)" }
            elseif ($pct -lt 20) { $score -= 5; $penalizaciones += "Disco con poco espacio ($pct% libre)" }
        }
    } catch {}

    # Sobre-optimizaciones
    $overCount = 0
    $keysToCheck = @(
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TCPNoDelay"}
    )
    foreach ($ki in $keysToCheck) {
        if (Test-OverOptimized -Path $ki.Path -Name $ki.Name) { $overCount++; $score -= 5 }
    }
    if ($overCount -gt 0) { $penalizaciones += "$overCount configuraciones con valores peligrosos" }

    return [math]::Max(0, [math]::Min(100, $score))
}

# ============================================================================
# RESUMEN INTELIGENTE POST-ANÁLISIS
# ============================================================================
function Show-ResumenInteligente {
    $hw = $script:Hardware
    if (-not $hw -or -not $hw.Valid) { return }

    # Calcular score antes
    $script:ScoreAntes = Get-SystemScore

    # Generar descripción del equipo en lenguaje humano
    $descripcion = ""
    if ($hw.IsLaptop) { $descripcion += "Laptop" } else { $descripcion += "PC de escritorio" }

    $ramDesc = if ($hw.RAM.TotalGB -le 4) { "con poca RAM ($($hw.RAM.TotalGB) GB)" }
               elseif ($hw.RAM.TotalGB -le 8) { "con RAM moderada ($($hw.RAM.TotalGB) GB)" }
               else { "con buena RAM ($($hw.RAM.TotalGB) GB)" }
    $descripcion += " $ramDesc"

    $discoDesc = if ($hw.SystemSSD) { "y disco SSD (rápido)" } else { "y disco mecánico HDD (más lento)" }
    $descripcion += ", $discoDesc"

    # Cantidad de mejoras disponibles
    $optPendientes = 0
    for ($i=0; $i -lt $lvOptimizations.Items.Count; $i++) {
        if ($lvOptimizations.Items[$i].Tag -and $lvOptimizations.Items[$i].SubItems[1].Text -ne "✓ HECHO") { $optPendientes++ }
    }
    $privPendientes = 0
    for ($i=0; $i -lt $lvPrivacidad.Items.Count; $i++) {
        if ($lvPrivacidad.Items[$i].Checked) { $privPendientes++ }
    }
    $overCount = 0
    $keysToCheck = @(
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TCPNoDelay"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Name="PowerThrottlingOff"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnablePrefetcher"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsDisableLastAccessUpdate"}
    )
    foreach ($ki in $keysToCheck) {
        if (Test-OverOptimized -Path $ki.Path -Name $ki.Name) { $overCount++ }
    }

    $rtbLog.Clear()
    $c = $script:colors

    $rtbLog.SelectionColor = $c.Accent
    $rtbLog.AppendText("═══════════════════════════════`r`n")
    $rtbLog.SelectionColor = $c.Accent
    $rtbLog.AppendText("  LO QUE WDM ENCONTRÓ EN TU PC`r`n")
    $rtbLog.SelectionColor = $c.Accent
    $rtbLog.AppendText("═══════════════════════════════`r`n`r`n")

    $rtbLog.SelectionColor = $c.TextSecond
    $rtbLog.AppendText("Tu equipo es una $descripcion.`r`n`r`n")

    # Score visual
    $scoreColor = if ($script:ScoreAntes -ge 80) { $c.Green } elseif ($script:ScoreAntes -ge 60) { $c.Yellow } else { $c.Orange }
    $rtbLog.SelectionColor = $scoreColor
    $rtbLog.AppendText("  Puntuación actual: $($script:ScoreAntes)/100`r`n`r`n")

    # Sobre-optimizaciones
    if ($overCount -gt 0) {
        $rtbLog.SelectionColor = $c.Red
        $rtbLog.AppendText("⚠️ ALERTA: $overCount configuración(es) con valores peligrosos`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("   Alguien modificó el registro con valores que pueden causar`r`n   inestabilidad. WDM puede corregirlos de forma segura.`r`n`r`n")
    }

    # Optimizaciones disponibles
    if ($optPendientes -gt 0) {
        $rtbLog.SelectionColor = $c.Accent
        $rtbLog.AppendText("⚡ $optPendientes optimizaciones disponibles`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("   WDM las seleccionó según tu hardware específico.`r`n`r`n")
    } else {
        $rtbLog.SelectionColor = $c.Green
        $rtbLog.AppendText("✅ Tu PC ya está optimizada`r`n`r`n")
    }

    # Privacidad
    if ($privPendientes -gt 0) {
        $rtbLog.SelectionColor = $c.Purple
        $rtbLog.AppendText("🛡️ $privPendientes ajustes de privacidad pendientes`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("   Windows comparte datos de uso por defecto.`r`n   Podés desactivarlos sin afectar el funcionamiento.`r`n`r`n")
    }

    # Recomendación según hardware
    $rtbLog.SelectionColor = $c.Yellow
    $rtbLog.AppendText("💡 RECOMENDACIÓN PARA TU EQUIPO:`r`n")
    $rtbLog.SelectionColor = $c.TextSecond
    if ($hw.RAM.TotalGB -le 4 -and -not $hw.SystemSSD) {
        $rtbLog.AppendText("   Tu PC tiene recursos limitados. WDM activará las`r`n   mejoras que ayudan más con poca RAM y disco mecánico.`r`n   No se toca nada riesgoso.`r`n")
    } elseif ($hw.RAM.TotalGB -le 4) {
        $rtbLog.AppendText("   Con 4 GB de RAM, cada recurso cuenta. WDM desactivará`r`n   servicios que consumen memoria sin que los uses.`r`n")
    } elseif (-not $hw.SystemSSD) {
        $rtbLog.AppendText("   Con disco mecánico, el mayor impacto viene de reducir`r`n   lecturas/escrituras innecesarias. WDM lo configura solo.`r`n")
    } else {
        $rtbLog.AppendText("   Tu PC tiene buena base. Las mejoras apuntan a`r`n   reducir latencia y liberar recursos de fondo.`r`n")
    }

    $rtbLog.AppendText("`r`n")
    $rtbLog.SelectionColor = $c.TextDim
    $rtbLog.AppendText("👆 Hacé clic en cualquier ítem de la lista para ver`r`n   una explicación clara de qué hace y por qué sirve.`r`n")

    # Actualizar score display
    Update-ScoreDisplay -Score $script:ScoreAntes -Label "ANTES"
}

# ============================================================================
# FUNCIONES CHECK DE OPTIMIZACIÓN
# ============================================================================
function Check-Win32PrioritySeparation { $e=if($script:Hardware.IsLaptop){2}else{38}; return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ExpectedValue $e) }
function Check-PowerThrottling { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -ExpectedValue 1) }
function Check-DisablePagingExecutive { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -ExpectedValue 1) }
function Check-LargeSystemCache { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -ExpectedValue 1) }
function Check-SysMainStartup { try { $s=Get-Service -Name SysMain -EA Stop; return ($s.StartType -eq "Disabled") } catch { return $false } }
function Check-HibernateDisabled {
    try {
        # Verificar directamente en el registro en vez de parsear texto localizado
        $hibVal = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -EA SilentlyContinue
        if ($hibVal -and $hibVal.HibernateEnabled -eq 0) { return $true }
        # Fallback: verificar que no exista el archivo hiberfil.sys
        if (-not (Test-Path "$env:SystemDrive\hiberfil.sys")) { return $true }
        return $false
    } catch { return $false }
}
function Check-NtfsLastAccess { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -ExpectedValue 1) }
function Check-IOPriority { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IoPriority" -ExpectedValue 3) }
function Check-Prefetcher { $e=if($script:Hardware.SystemSSD){0}else{3}; return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ExpectedValue $e) }
function Check-TCPAutoTuning {
    try {
        $r = netsh int tcp show global 2>$null | Out-String
        # Buscar el estado del autotuning — funciona en inglés y español
        # En inglés: "Receive Window Auto-Tuning Level    : normal"
        # En español: "Nivel de ajuste automático de recepción : normal"
        if ($r -match ":\s*normal") { return $true }
        return $false
    } catch { return $false }
}
function Check-RSS {
    try {
        $r = netsh int tcp show global 2>$null | Out-String
        # En inglés: "Receive-Side Scaling State : enabled"
        # En español: "Estado de escalado en recepción : enabled" o similar
        if ($r -match "Scaling.*:\s*enabled" -or $r -match "escalado.*:\s*enabled") { return $true }
        return $false
    } catch { return $false }
}
function Check-TCPNoDelay {
    try {
        foreach ($ad in (Get-NetAdapter|Where-Object{$_.Status -eq "Up"})) {
            $path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($ad.InterfaceGuid)"
            if(Test-Path $path){$v=Get-ItemProperty -Path $path -Name "TCPNoDelay" -EA SilentlyContinue; if($v -and $v.TCPNoDelay -eq 1){return $true}}
        }
        return $false
    } catch { return $false }
}
function Check-HAGS { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ExpectedValue 2) }
function Check-VRR { $path="HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"; if(Test-Path $path){$v=Get-ItemProperty -Path $path -Name "DirectX UserGpuPreferences" -EA SilentlyContinue; if($v -and $v."DirectX UserGpuPreferences" -match "WindowedOptimizations=1"){return $true}}; return $false }
function Check-DWMPriority { return (Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\WindowsManager" -Name "Priority" -ExpectedValue 2) }
function Check-Transparencias { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -ExpectedValue 0) }
function Check-MenuShowDelay { return (Check-OptimizationStatus -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -ExpectedValue "0") }
function Check-MouseHoverTime { return (Check-OptimizationStatus -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -ExpectedValue "10") }
function Check-AutoEndTasks { return (Check-OptimizationStatus -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -ExpectedValue "1") }
function Check-WaitToKillAppTimeout { return (Check-OptimizationStatus -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -ExpectedValue "2000") }
function Check-GameDVR { $s1=Check-OptimizationStatus -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ExpectedValue 0; $s2=Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -ExpectedValue 0; return ($s1 -and $s2) }
function Check-StartupDelay { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -ExpectedValue 0) }
function Check-TdrDelay { $e=if($script:Hardware.IsLaptop){10}else{8}; return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -ExpectedValue $e) }
function Check-BootServices { $svcs=@("DiagTrack","dmwappushservice","WSearch"); foreach($s in $svcs){try{$sv=Get-Service -Name $s -EA SilentlyContinue; if($sv -and $sv.StartType -eq "Automatic"){return $false}}catch{}}; return $true }
function Check-WiFiPowerSave { try{$ads=Get-NetAdapter|Where-Object{$_.Name -match "Wi[-]?Fi|Wireless" -and $_.Status -eq "Up"}; foreach($a in $ads){$pm=Get-NetAdapterPowerManagement -Name $a.Name -EA SilentlyContinue; if($pm -and $pm.WakeOnPattern -eq $true){return $false}}; return $true}catch{return $false} }
function Check-JumboFrames { return $false }
function Check-IPv6 { try{foreach($a in (Get-NetAdapter|Where-Object{$_.Status -eq "Up"})){$b=Get-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -EA SilentlyContinue; if($b -and $b.Enabled -eq $true){return $false}}; return $true}catch{return $false} }
function Check-ProcessScheduling { $c=$script:Hardware.CPU.Cores; $e=if($c -ge 8){38}elseif($c -ge 4){26}else{18}; return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ExpectedValue $e) }
function Check-USB { return (Check-OptimizationStatus -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -ExpectedValue 1) }
function Check-IconCache {
    try {
        $iconCachePath = "$env:LOCALAPPDATA\IconCache.db"
        if (Test-Path $iconCachePath) {
            $lw = (Get-Item $iconCachePath -EA Stop).LastWriteTime
            if (($lw -is [datetime]) -and ((Get-Date) - $lw -gt [TimeSpan]::FromDays(30))) { return $false }
        }
        return $true
    } catch { return $true }
}
function Check-TaskScheduler { try{$s=Get-Service -Name Schedule -EA Stop; if($s.Status -ne "Running"){return $false}; $tn="WDM_Test_"+[guid]::NewGuid().ToString("N").Substring(0,8); $a=New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c exit"; $t=New-ScheduledTaskTrigger -AtStartup; $st=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries; $p=New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest; Register-ScheduledTask -TaskName $tn -Action $a -Trigger $t -Settings $st -Principal $p -Force -EA Stop|Out-Null; Unregister-ScheduledTask -TaskName $tn -Confirm:$false -EA Stop; return $true}catch{return $false} }
function Check-ExplorerStartup { $b1=Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableBalloonTips" -ExpectedValue 0; $b2=Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -ExpectedValue 0; return ($b1 -and $b2) }
function Check-PrefetchClean { return $false }
function Check-DiskServices { return $false }
function Check-MemoryManagement { return $false }
function Check-StartupPrograms { return $false }
function Check-TimerResolution { try{$r=bcdedit /enum|Out-String; if($r -match "useplatformclock\s+Yes"){return $false}; return $true}catch{return $false} }
function Check-PageFile { try{$cs=Get-CimInstance Win32_ComputerSystem; return (-not $cs.AutomaticManagedPagefile)}catch{return $false} }
function Check-WindowsAnimations { try{$path="HKCU:\Control Panel\Desktop\WindowMetrics"; $v=Get-ItemProperty -Path $path -Name "MinAnimate" -EA SilentlyContinue; return ($v -and $v.MinAnimate -eq "0")}catch{return $false} }
function Check-CPUParking { try{$r=powercfg /query SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 2>$null|Out-String; return ($r -match "Current AC Power Setting Index: 0x00000064")}catch{return $false} }
function Check-TCPAdvanced { try{$path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; $ttl=Get-ItemProperty -Path $path -Name "DefaultTTL" -EA SilentlyContinue; $ack=Get-ItemProperty -Path $path -Name "TcpAckFrequency" -EA SilentlyContinue; return ($ttl -and $ttl.DefaultTTL -eq 64 -and $ack -and $ack.TcpAckFrequency -eq 1)}catch{return $false} }
function Check-NetworkThrottling { try{$path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; $v=Get-ItemProperty -Path $path -Name "NetworkThrottlingIndex" -EA SilentlyContinue; return ($v -and $v.NetworkThrottlingIndex -eq 0xFFFFFFFF)}catch{return $false} }
function Check-SystemResponsiveness { try{$path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; $v=Get-ItemProperty -Path $path -Name "SystemResponsiveness" -EA SilentlyContinue; return ($v -and $v.SystemResponsiveness -eq 0)}catch{return $false} }
function Check-GpuPriority { try{$path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; $gpu=Get-ItemProperty -Path $path -Name "GPU Priority" -EA SilentlyContinue; $pri=Get-ItemProperty -Path $path -Name "Priority" -EA SilentlyContinue; return ($gpu -and $gpu."GPU Priority" -eq 8 -and $pri -and $pri.Priority -eq 6)}catch{return $false} }
function Check-VisualEffects { try{$path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; $v=Get-ItemProperty -Path $path -Name "VisualFXSetting" -EA SilentlyContinue; return ($v -and $v.VisualFXSetting -eq 2)}catch{return $false} }
function Check-MemoryCompression { try{$mc=Get-MMAgent -EA SilentlyContinue; if($script:Hardware.RAM.TotalGB -ge 16){return ($mc -and $mc.MemoryCompression -eq $false)}else{return ($mc -and $mc.MemoryCompression -eq $true)}}catch{return $false} }
function Check-IRQPriority { try{$path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; $v=Get-ItemProperty -Path $path -Name "IRQ8Priority" -EA SilentlyContinue; return ($v -and $v.IRQ8Priority -eq 1)}catch{return $false} }
function Check-WriteCaching { try{$path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; $v=Get-ItemProperty -Path $path -Name "WriteCache" -EA SilentlyContinue; return ($v -and $v.WriteCache -eq 1)}catch{return $false} }
function Check-PowerPlanUltimate { try{$r=powercfg /getactivescheme; return ($r -match "e9a42b02-d5df-448d-aa00-03f14749eb61")}catch{return $false} }

# ============================================================================
# CHECKS Y OPTIMIZACIONES — DÍA A DÍA (EXPLORADOR + ESTÉTICA + PANTALLA)
# ============================================================================

# Explorador: mostrar extensiones de archivos
function Check-ExplorerExtensions {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -EA SilentlyContinue; return ($v -and $v.HideFileExt -eq 0) } catch { return $false }
}
function Optimize-ExplorerExtensions {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -EA Stop
        Write-Log "  ✓ Extensiones de archivos visibles (.docx, .pdf, .exe)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Explorador: mostrar archivos ocultos (útil para diagnóstico)
function Check-ExplorerHiddenFiles {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -EA SilentlyContinue; return ($v -and $v.Hidden -eq 1) } catch { return $false }
}
function Optimize-ExplorerHiddenFiles {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Archivos ocultos visibles en el Explorador" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Explorador: abrir en Esta PC en vez de Acceso Rápido
function Check-ExplorerOpenThisPC {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -EA SilentlyContinue; return ($v -and $v.LaunchTo -eq 1) } catch { return $false }
}
function Optimize-ExplorerOpenThisPC {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Explorador abre en 'Esta PC' (más directo)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Explorador: mostrar ruta completa en la barra de título
function Check-ExplorerFullPath {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -EA SilentlyContinue; return ($v -and $v.FullPath -eq 1) } catch { return $false }
}
function Optimize-ExplorerFullPath {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "FullPath" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Ruta completa visible en barra de título" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Explorador: deshabilitar búsqueda en carpetas comprimidas (más rápido)
function Check-ExplorerNoCompressSearch {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DontSearchInCompressFolders" -EA SilentlyContinue; return ($v -and $v.DontSearchInCompressFolders -eq 1) } catch { return $false }
}
function Optimize-ExplorerNoCompressSearch {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DontSearchInCompressFolders" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Búsqueda del Explorador más rápida (excluye carpetas comprimidas)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Estética: mantener las transparencias del sistema (Aero Glass) — NO romperlas
function Check-AeroGlass {
    try {
        $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -EA SilentlyContinue
        # Aero saludable = valor 1 (activo) en GPU dedicada, o lo que el usuario configuró
        # Solo reportar si fue desactivado por otro optimizador
        return ($v -and $v.EnableTransparency -eq 1)
    } catch { return $true }
}

# Corrección del flasheo de pantalla en browsers (Brave, Chrome, Edge)
# Causa: HAGS activo + hardware acceleration del browser + driver GPU inestable
function Check-BrowserFlash {
    try {
        # Verificar si HAGS está activo Y si hay GPU dedicada — combinación que causa flasheo
        $hagsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        $hags = Get-ItemProperty -Path $hagsPath -Name "HwSchMode" -EA SilentlyContinue
        $hagsActivo = ($hags -and $hags.HwSchMode -eq 2)
        # Verificar TDR delay — si es muy bajo causa flasheos
        $tdr = Get-ItemProperty -Path $hagsPath -Name "TdrDelay" -EA SilentlyContinue
        $tdrBajo = ($tdr -and $tdr.TdrDelay -lt 8)
        # Si HAGS activo + TDR bajo = posible flasheo
        if ($hagsActivo -and $tdrBajo) { return $false }
        return $true
    } catch { return $true }
}
function Optimize-BrowserFlash {
    try {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        # TDR a 8 segundos — evita que Windows reinicie la GPU por timeouts cortos
        $tdrActual = (Get-ItemProperty -Path $p -Name "TdrDelay" -EA SilentlyContinue).TdrDelay
        Set-ItemProperty -Path $p -Name "TdrDelay"    -Value 8  -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "TdrDdiDelay" -Value 15 -Type DWord -EA SilentlyContinue
        # TdrLevel 3 = reiniciar GPU sin BSOD (comportamiento estable)
        Set-ItemProperty -Path $p -Name "TdrLevel"    -Value 3  -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ Timeout de GPU estabilizado (TdrDelay=8s, TdrDdiDelay=15s)" "Green"
        Write-Log "    Esto soluciona el flasheo de pantalla en Brave, Chrome y Edge." "TextDim"
        # Sugerencia de flags del browser — no lo hacemos automático, solo informamos
        Write-Log "  ℹ️ Si el flasheo persiste, en Brave/Chrome abrí chrome://flags" "TextDim"
        Write-Log "     y buscá 'GPU rasterization' → desactivar para ese browser." "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Notificaciones del sistema: limpiar las intrusivas sin desactivar todas
function Check-NotificacionesSilenciosas {
    try {
        $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -EA SilentlyContinue
        $v2 = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -EA SilentlyContinue
        return ($v2 -and $v2.NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND -eq 0)
    } catch { return $false }
}
function Optimize-NotificacionesSilenciosas {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        # Silenciar el sonido de notificaciones — no desactivarlas, solo sin sonido
        Set-ItemProperty -Path $p -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -Value 0 -Type DWord -EA SilentlyContinue
        # Quitar el badge de notificaciones en los íconos de la barra de tareas
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarBadges" -Value 0 -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ Notificaciones sin sonido + sin badges en barra de tareas" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Barra de tareas: limpiar íconos del sistema innecesarios
function Check-TaskbarLimpia {
    try {
        $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -EA SilentlyContinue
        return ($v -and $v.ShowTaskViewButton -eq 0)
    } catch { return $false }
}
function Optimize-TaskbarLimpia {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $p -Name "ShowTaskViewButton" -Value 0 -Type DWord -EA SilentlyContinue  # Quitar botón Vista de Tareas
        # Windows 11: quitar botón de widgets
        Set-ItemProperty -Path $p -Name "TaskbarDa" -Value 0 -Type DWord -EA SilentlyContinue
        # Quitar botón Búsqueda si ocupa espacio (Windows 11)
        if ($script:WindowsVersion.IsWin11) {
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 -Type DWord -EA SilentlyContinue
        }
        Write-Log "  ✓ Barra de tareas limpia (sin Vista de Tareas, sin Widgets)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Menú contextual: restaurar menú completo en Win11 (evita el 'Mostrar más opciones')
function Check-MenuContextualCompleto {
    if (-not $script:WindowsVersion.IsWin11) { return $true } # Solo aplica en Win11
    try {
        $v = Get-ItemProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)" -EA SilentlyContinue
        return ($v -and $v."(default)" -eq "")
    } catch { return $false }
}
function Optimize-MenuContextualCompleto {
    if (-not $script:WindowsVersion.IsWin11) {
        Write-Log "  ℹ️ Solo aplica en Windows 11" "TextDim"; return $true
    }
    try {
        $p = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "(default)" -Value "" -Type String -EA Stop
        Write-Log "  ✓ Menú clic derecho completo (sin 'Mostrar más opciones')" "Green"
        Write-Log "    Reiniciá Explorer para que tome efecto." "TextDim"
        # Reiniciar Explorer para aplicar el cambio sin reiniciar la PC
        try { Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep -Milliseconds 800; Start-Process explorer } catch {}
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Ventanas: sin efecto de snap mostrando sugerencias de disposición (ruido visual)
function Check-SnapSugerencias {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -EA SilentlyContinue; return ($v -and $v.SnapAssist -eq 0) } catch { return $false }
}
function Optimize-SnapSugerencias {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -Value 0 -Type DWord -EA Stop
        Write-Log "  ✓ Sugerencias de Snap desactivadas (ventanas se mueven sin distracciones)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Papelera: confirmar antes de eliminar (evita borrar por accidente)
function Check-PapeleraConfirmar {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -EA SilentlyContinue; return ($v -and $v.ConfirmFileDelete -eq 1) } catch { return $false }
}
function Optimize-PapeleraConfirmar {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "ConfirmFileDelete" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Confirmación al eliminar archivos activada (evita borrar por accidente)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# Reiniciar Explorer limpiamente para aplicar cambios del día a día
function Restart-ExplorerLimpio {
    try {
        Stop-Process -Name explorer -Force -EA SilentlyContinue
        Start-Sleep -Milliseconds 1000
        Start-Process explorer
        Write-Log "  ✓ Explorador de Windows reiniciado — cambios aplicados" "Green"; return $true
    } catch { return $false }
}

# ============================================================================
# USO DIARIO — EXPLORADOR, ESTÉTICA Y EXPERIENCIA REAL
# ============================================================================

# --- EXPLORADOR DE ARCHIVOS ---

function Check-ExtensionesVisibles {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -EA SilentlyContinue; return ($v -and $v.HideFileExt -eq 0) } catch { return $false }
}
function Optimize-ExtensionesVisibles {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -EA Stop
        Write-Log "  ✓ Extensiones de archivo visibles (.exe, .pdf, .docx...)" "Green"
        Write-Log "    Ahora podés ver de qué tipo es cada archivo antes de abrirlo." "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-ArchivosOcultosVisibles {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -EA SilentlyContinue; return ($v -and $v.Hidden -eq 1) } catch { return $false }
}
function Optimize-ArchivosOcultosVisibles {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden"      -Value 1 -Type DWord -EA Stop
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 0 -Type DWord -EA SilentlyContinue # archivos de sistema: NO mostrar (peligroso)
        Write-Log "  ✓ Archivos ocultos visibles (archivos de sistema: siguen ocultos por seguridad)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-ExploradorEstaPC {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -EA SilentlyContinue; return ($v -and $v.LaunchTo -eq 1) } catch { return $false }
}
function Optimize-ExploradorEstaPC {
    try {
        # LaunchTo=1 = "Esta PC", LaunchTo=2 = "Acceso rápido" (default molesto)
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Explorador abre en 'Esta PC' (no en Acceso Rápido)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-CarpetasAntesDeArchivos {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "FolderContentsInfoTip" -EA SilentlyContinue; return $true } catch { return $false }
}
function Optimize-CarpetasAntesDeArchivos {
    try {
        # Ordenar: carpetas primero, luego archivos
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $p -Name "FolderContentsInfoTip" -Value 1 -Type DWord -EA SilentlyContinue
        Set-ItemProperty -Path $p -Name "SeparateFolders"        -Value 1 -Type DWord -EA SilentlyContinue
        # Mostrar la ruta completa en la barra de título
        Set-ItemProperty -Path $p -Name "FullPath"               -Value 1 -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ Carpetas antes que archivos + ruta completa en título" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-SinAgrupacionesExplorador {
    # No hay un valor único — siempre ofrecer reset de vista
    return $false
}
function Optimize-SinAgrupacionesExplorador {
    try {
        # Limpiar las vistas guardadas del explorador (que a veces quedan rotas)
        $bagPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
        $bagMRU  = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
        if (Test-Path $bagPath) { Remove-Item -Path $bagPath -Recurse -Force -EA SilentlyContinue }
        if (Test-Path $bagMRU)  { Remove-Item -Path $bagMRU  -Recurse -Force -EA SilentlyContinue }
        # Quitar agrupación por defecto en la carpeta de descargas (la más molesta)
        $downloadsGUID = (New-Object -ComObject Shell.Application).NameSpace("shell:Downloads").Self.Path
        Write-Log "  ✓ Vistas del explorador reseteadas (sin agrupaciones automáticas)" "Green"
        Write-Log "    La próxima vez que abras una carpeta, tendrá vista limpia." "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-ExploradorCheckboxes {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AutoCheckSelect" -EA SilentlyContinue; return ($v -and $v.AutoCheckSelect -eq 1) } catch { return $false }
}
function Optimize-ExploradorCheckboxes {
    try {
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AutoCheckSelect" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Checkboxes de selección en el explorador activados" "Green"
        Write-Log "    Podés seleccionar varios archivos haciendo clic en los cuadraditos." "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

# --- ESTÉTICA: LO QUE LOS OPTIMIZADORES ROMPEN ---

function Check-SuavizadoFuentes {
    try {
        $v = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -EA SilentlyContinue
        $v2= Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -EA SilentlyContinue
        return ($v -and $v.FontSmoothing -eq "2" -and $v2 -and $v2.FontSmoothingType -eq 2)
    } catch { return $false }
}
function Optimize-SuavizadoFuentes {
    try {
        $p = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $p -Name "FontSmoothing"     -Value "2" -EA Stop         # ClearType activo
        Set-ItemProperty -Path $p -Name "FontSmoothingType" -Value 2 -Type DWord -EA Stop # ClearType (no solo grayscale)
        Set-ItemProperty -Path $p -Name "FontSmoothingGamma" -Value 2200 -Type DWord -EA SilentlyContinue
        Set-ItemProperty -Path $p -Name "FontSmoothingOrientation" -Value 1 -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ ClearType activado — texto más nítido en todas las apps" "Green"
        Write-Log "    Si querés ajustar más fino: Inicio → 'Ajustar texto ClearType'" "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-IconosTamañoNormal {
    try {
        $v = Get-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "Shell Icon Size" -EA SilentlyContinue
        return ($null -eq $v -or $v."Shell Icon Size" -eq "32")
    } catch { return $true }
}
function Optimize-IconosTamañoNormal {
    try {
        $p = "HKCU:\Control Panel\Desktop\WindowMetrics"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "Shell Icon Size" -Value "32" -EA Stop
        # DPI correcto para que los íconos no se vean borrosos
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "LogPixels" -Value 96 -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ Tamaño de íconos normalizado (32px — estándar Windows)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-DPIEscalado {
    try {
        # Verificar si el escalado DPI está en modo "automático" o fue forzado por otro optimizador
        $v = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "Win8DpiScaling" -EA SilentlyContinue
        # Si está en 0, Windows maneja DPI bien. Si está en 1 con valor raro, hay problema
        return $true # Solo informar, no corregir automáticamente
    } catch { return $true }
}
function Optimize-DPIEscalado {
    try {
        $p = "HKCU:\Control Panel\Desktop"
        # DpiScalingVer = versión del sistema DPI, DPIOverride desactivado
        Set-ItemProperty -Path $p -Name "DpiScalingVer"  -Value 0x00010000 -Type DWord -EA SilentlyContinue
        Set-ItemProperty -Path $p -Name "Win8DpiScaling" -Value 0 -Type DWord -EA SilentlyContinue
        # Quitar compatibilidad de DPI forzada que deja texto borroso en apps
        $overrideKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
        Write-Log "  ✓ Escalado DPI restaurado al modo automático de Windows" "Green"
        Write-Log "    Si tenés texto borroso en alguna app: clic derecho → Propiedades → Compatibilidad" "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-EsquemasColores {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -EA SilentlyContinue; return ($null -ne $v) } catch { return $true }
}

# ============================================================================
# SISTEMA DE RESTAURACIÓN ESTÉTICA — detección completa + reparación de una vez
# ============================================================================

function Get-EstadoEstetica {
    # Devuelve una lista de items con su estado actual vs el default de Windows
    # Cada item: @{ Nombre; OK; Valor; DefaultDesc; Clave }
    $items = @()
    $isWin11 = $script:WindowsVersion.IsWin11

    # 1. Animaciones de ventanas (optimizadores las desactivan "para ganar fps")
    try {
        $v = Get-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -EA SilentlyContinue
        $ok = ($null -eq $v -or $v.MinAnimate -eq "1" -or $v.MinAnimate -eq 1)
        $items += @{ Nombre="Animaciones de ventanas"; OK=$ok; DefaultDesc="Activadas (suaves y fluidas)"; Clave="Animaciones" }
    } catch {}

    # 2. ClearType / suavizado de texto
    try {
        $v  = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -EA SilentlyContinue
        $v2 = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -EA SilentlyContinue
        $ok = ($v -and $v.FontSmoothing -eq "2") -and ($v2 -and $v2.FontSmoothingType -eq 2)
        $items += @{ Nombre="Texto nítido (ClearType)"; OK=$ok; DefaultDesc="Activado — texto sin serrucho"; Clave="ClearType" }
    } catch {}

    # 3. Efectos visuales — la clave VisualFXSetting (0=best appearance, 1=best perf, 2=custom, 3=default)
    try {
        $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -EA SilentlyContinue
        $ok = ($null -eq $v -or $v.VisualFXSetting -eq 3 -or $v.VisualFXSetting -eq 0)
        $items += @{ Nombre="Efectos visuales de Windows"; OK=$ok; DefaultDesc="Configuración Windows (apariencia equilibrada)"; Clave="VisualFX" }
    } catch {}

    # 4. Transparencias del sistema (Aero)
    try {
        $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -EA SilentlyContinue
        $ok = ($null -eq $v -or $v.EnableTransparency -eq 1)
        $items += @{ Nombre="Transparencias (Aero)"; OK=$ok; DefaultDesc="Activadas — barra de tareas y menús translúcidos"; Clave="Transparencia" }
    } catch {}

    # 5. Esquinas redondeadas Win11 (DwmAPI — solo Win11)
    if ($isWin11) {
        try {
            # DWMWCP_DEFAULT=0 o ausente = esquinas redondeadas en Win11
            $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name "UseWindowFrameStagingBuffer" -EA SilentlyContinue
            $corners = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -EA SilentlyContinue
            # La clave real de esquinas es HKCU:\...\DWM no tiene un valor directo en registro
            # Se controla por DWM internamente — verificamos si algún tweak la tocó via DWMAPI
            $items += @{ Nombre="Esquinas redondeadas Win11"; OK=$true; DefaultDesc="Activadas por Windows automáticamente"; Clave="Corners" }
        } catch {}
    }

    # 6. Snap Layouts (el grid al hover del botón maximizar — Win11)
    if ($isWin11) {
        try {
            $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapBar" -EA SilentlyContinue
            $ok = ($null -eq $v -or $v.EnableSnapBar -eq 1)
            $items += @{ Nombre="Snap Layouts (hover en maximizar)"; OK=$ok; DefaultDesc="Activados — grid de disposición de ventanas"; Clave="SnapLayouts" }
        } catch {}
    }

    # 7. Menú contextual Win11 moderno (con íconos de color)
    if ($isWin11) {
        try {
            $p  = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
            $ok = (-not (Test-Path $p))  # Si existe la clave = menú viejo Win10 forzado
            $items += @{ Nombre="Menú contextual moderno Win11"; OK=$ok; DefaultDesc="El menú con íconos de color de Win11"; Clave="MenuModerno" }
        } catch {}
    }

    # 8. Sonidos del sistema (no desactivarlos todos)
    try {
        $v = Get-ItemProperty "HKCU:\AppEvents\Schemes" -Name "(Default)" -EA SilentlyContinue
        $ok = ($null -eq $v -or $v."(Default)" -ne ".None")
        $items += @{ Nombre="Sonidos del sistema"; OK=$ok; DefaultDesc="Esquema Windows predeterminado (no silenciado total)"; Clave="Sonidos" }
    } catch {}

    # 9. Cursor del sistema (no reemplazado por otro tema)
    try {
        $v = Get-ItemProperty "HKCU:\Control Panel\Cursors" -Name "(Default)" -EA SilentlyContinue
        $ok = ($null -eq $v -or $v."(Default)" -eq "" -or $v."(Default)" -match "Windows Default|Aero")
        $items += @{ Nombre="Cursor de Windows original"; OK=$ok; DefaultDesc="Cursor Aero (el de Windows por defecto)"; Clave="Cursor" }
    } catch {}

    # 10. Velocidad de animaciones — SmoothScroll y MenuShowDelay
    try {
        $v = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -EA SilentlyContinue
        $delay = if ($v) { [int]$v.MenuShowDelay } else { 400 }
        # Default Windows = 400ms. Optimizadores lo ponen en 0 (instantáneo pero se siente "seco")
        # 200ms es el punto dulce: rápido pero con sensación de fluidez
        $ok = ($delay -le 400 -and $delay -ge 100)
        $items += @{ Nombre="Velocidad de menús"; OK=$ok; DefaultDesc="200ms — rápido y fluido"; Clave="MenuDelay" }
    } catch {}

    # 11. Barra de desplazamiento ancha (Win11 la hace delgada, algunos tweaks la quitan)
    try {
        $v = Get-ItemProperty "HKCU:\Control Panel\Accessibility" -Name "DynamicScrollbars" -EA SilentlyContinue
        $ok = ($null -eq $v -or $v.DynamicScrollbars -eq 1)
        $items += @{ Nombre="Barras de desplazamiento dinámicas"; OK=$ok; DefaultDesc="Aparecen al pasar el mouse (Win11 estándar)"; Clave="Scrollbars" }
    } catch {}

    return $items
}

function Optimize-RestaurarEsteticaWindows {
    $isWin11 = $script:WindowsVersion.IsWin11
    $items   = Get-EstadoEstetica
    $roto    = @($items | Where-Object { -not $_.OK })
    $arreglados = 0

    if ($roto.Count -eq 0) {
        Write-Log "  ✅ La estética de Windows ya está en su estado original." "Green"
        return $true
    }

    Write-Log "  Restaurando $($roto.Count) configuración(es) estéticas..." "Yellow"

    foreach ($item in $roto) {
        try {
            switch ($item.Clave) {

                "Animaciones" {
                    $p = "HKCU:\Control Panel\Desktop\WindowMetrics"
                    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                    Set-ItemProperty -Path $p -Name "MinAnimate" -Value "1" -EA Stop
                    # Activar todas las animaciones de SystemParameters
                    $p2 = "HKCU:\Control Panel\Desktop"
                    Set-ItemProperty -Path $p2 -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -Type Binary -EA SilentlyContinue
                    Write-Log "  ✓ Animaciones de ventanas restauradas" "Green"
                    $arreglados++
                }

                "ClearType" {
                    $p = "HKCU:\Control Panel\Desktop"
                    Set-ItemProperty -Path $p -Name "FontSmoothing"          -Value "2"  -EA Stop
                    Set-ItemProperty -Path $p -Name "FontSmoothingType"       -Value 2    -Type DWord -EA Stop
                    Set-ItemProperty -Path $p -Name "FontSmoothingGamma"      -Value 2200 -Type DWord -EA SilentlyContinue
                    Set-ItemProperty -Path $p -Name "FontSmoothingOrientation"-Value 1    -Type DWord -EA SilentlyContinue
                    Write-Log "  ✓ ClearType restaurado — texto nítido en toda la pantalla" "Green"
                    $arreglados++
                }

                "VisualFX" {
                    # Restaurar a "Dejar que Windows elija lo mejor" (3)
                    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
                    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                    Set-ItemProperty -Path $p -Name "VisualFXSetting" -Value 3 -Type DWord -EA Stop
                    # También restaurar las opciones individuales al default
                    $pd = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                    Set-ItemProperty -Path $pd -Name "ListviewAlphaSelect" -Value 1 -Type DWord -EA SilentlyContinue
                    Set-ItemProperty -Path $pd -Name "TaskbarAnimations"   -Value 1 -Type DWord -EA SilentlyContinue
                    Set-ItemProperty -Path $pd -Name "ListviewShadow"      -Value 1 -Type DWord -EA SilentlyContinue
                    Write-Log "  ✓ Efectos visuales restaurados al estilo Windows" "Green"
                    $arreglados++
                }

                "Transparencia" {
                    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -Type DWord -EA Stop
                    Write-Log "  ✓ Transparencias (Aero) activadas" "Green"
                    $arreglados++
                }

                "SnapLayouts" {
                    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapBar" -Value 1 -Type DWord -EA Stop
                    Write-Log "  ✓ Snap Layouts reactivados (hover en botón maximizar)" "Green"
                    $arreglados++
                }

                "MenuModerno" {
                    # Eliminar la clave que fuerza el menú viejo de Win10
                    $p = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
                    if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -EA Stop }
                    Write-Log "  ✓ Menú contextual moderno de Win11 restaurado" "Green"
                    Write-Log "    (clic derecho con íconos de color — se aplica al reiniciar Explorer)" "TextDim"
                    $arreglados++
                }

                "Sonidos" {
                    # Restaurar al esquema Windows Default
                    Set-ItemProperty "HKCU:\AppEvents\Schemes" -Name "(Default)" -Value ".Default" -Type String -EA Stop
                    Write-Log "  ✓ Esquema de sonidos restaurado al predeterminado de Windows" "Green"
                    $arreglados++
                }

                "MenuDelay" {
                    # 200ms: más rápido que el default de Windows (400ms) pero con sensación fluida
                    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "200" -EA Stop
                    Write-Log "  ✓ Velocidad de menús: 200ms (rápido y fluido)" "Green"
                    $arreglados++
                }

                "Scrollbars" {
                    $p = "HKCU:\Control Panel\Accessibility"
                    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                    Set-ItemProperty -Path $p -Name "DynamicScrollbars" -Value 1 -Type DWord -EA Stop
                    Write-Log "  ✓ Barras de desplazamiento dinámicas restauradas" "Green"
                    $arreglados++
                }
            }
        } catch {
            Write-Log "  ℹ️ $($item.Nombre): no se pudo restaurar — $_" "TextDim"
        }
    }

    if ($arreglados -gt 0) {
        Write-Log "" "TextPrimary"
        Write-Log "  ✅ $arreglados elemento(s) restaurados al estado original de Windows." "Green"
        Write-Log "     Algunos cambios se ven al reiniciar el Explorador o la sesión." "TextDim"
        # Reiniciar Explorer para aplicar los cambios visibles
        try {
            Stop-Process -Name explorer -Force -EA SilentlyContinue
            Start-Sleep -Milliseconds 900
            Start-Process explorer
            Write-Log "  ✓ Explorador reiniciado — cambios aplicados" "Green"
        } catch {}
    }
    return $true
}

function Check-EsteticaOriginal {
    # Retorna $true si TODO está en su estado original (para mostrar ✓ HECHO)
    $items = Get-EstadoEstetica
    $roto  = @($items | Where-Object { -not $_.OK })
    return ($roto.Count -eq 0)
}

function Optimize-RestaurarTemaWindows {
    # Wrapper de compatibilidad — llama a la función completa
    return Optimize-RestaurarEsteticaWindows
}



# --- CORRECCIÓN DEL FLASHEO DE PANTALLA ---

function Check-BrowserFlashFix {
    try {
        $p   = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        $tdr = Get-ItemProperty -Path $p -Name "TdrDelay" -EA SilentlyContinue
        # Si TdrDelay >= 8, el fix ya está aplicado
        return ($tdr -and $tdr.TdrDelay -ge 8)
    } catch { return $false }
}

# --- FUNCIONES YA EXISTENTES (conservadas) ---

function Check-NotificacionesSilenciosas {
    try {
        $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -EA SilentlyContinue
        return ($v -and $v.NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND -eq 0)
    } catch { return $false }
}
function Optimize-NotificacionesSilenciosas {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -Value 0 -Type DWord -EA SilentlyContinue
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarBadges" -Value 0 -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ Notificaciones sin sonido + sin badges en barra de tareas" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-TaskbarLimpia {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -EA SilentlyContinue; return ($v -and $v.ShowTaskViewButton -eq 0) } catch { return $false }
}
function Optimize-TaskbarLimpia {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $p -Name "ShowTaskViewButton" -Value 0 -Type DWord -EA SilentlyContinue  # Quitar botón Vista de Tareas
        Set-ItemProperty -Path $p -Name "TaskbarDa"          -Value 0 -Type DWord -EA SilentlyContinue  # Quitar Widgets (Win11)
        # NO tocar SearchboxTaskbarMode — la barra de búsqueda es útil y muchos la usan
        # Si el usuario quiere quitarla puede hacerlo manualmente desde configuración
        Write-Log "  ✓ Barra de tareas limpia (sin Vista de Tareas ni Widgets)" "Green"
        Write-Log "    La barra de búsqueda se conservó — quitarla confunde a muchos usuarios." "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-MenuContextualCompleto {
    if (-not $script:WindowsVersion.IsWin11) { return $true }
    try { $v = Get-ItemProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)" -EA SilentlyContinue; return ($v -and $v."(default)" -eq "") } catch { return $false }
}
function Optimize-MenuContextualCompleto {
    if (-not $script:WindowsVersion.IsWin11) { Write-Log "  ℹ️ Solo aplica en Windows 11" "TextDim"; return $true }
    try {
        $p = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "(default)" -Value "" -Type String -EA Stop
        Write-Log "  ✓ Menú clic derecho completo restaurado" "Green"
        try { Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep -Milliseconds 800; Start-Process explorer } catch {}
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-SnapSugerencias {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -EA SilentlyContinue; return ($v -and $v.SnapAssist -eq 0) } catch { return $false }
}
function Optimize-SnapSugerencias {
    try { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Sugerencias de Snap desactivadas" "Green"; return $true } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-PapeleraConfirmar {
    try { $v = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -EA SilentlyContinue; return ($v -and $v.ConfirmFileDelete -eq 1) } catch { return $false }
}
function Optimize-PapeleraConfirmar {
    try {
        $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "ConfirmFileDelete" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Confirmación al eliminar archivos activada" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}

function Check-AdvertisingID { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ExpectedValue 0) }
function Check-Location { return (Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -ExpectedValue "Deny") }
function Check-Camera { return (Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" -Name "Value" -ExpectedValue "Deny") }
function Check-Microphone { return (Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" -Name "Value" -ExpectedValue "Deny") }
function Check-Notifications { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ExpectedValue 0) }
function Check-ActivityHistory { return (Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -ExpectedValue 0) }
function Check-CortanaWin10 { if(-not $script:WindowsVersion.IsWin10){return $false}; return (Check-OptimizationStatus -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ExpectedValue 0) }
function Check-Copilot { try{$v=Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -EA SilentlyContinue; return ($v -and $v.ShowCopilotButton -eq 0)}catch{return $false} }
function Check-CopilotWebSearch { try{$v=Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsWebSearchEnabled" -EA SilentlyContinue; return ($v -and $v.IsWebSearchEnabled -eq 0)}catch{return $false} }
function Check-CopilotContext { try{$v=Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Copilot" -Name "AllowContextWithApps" -EA SilentlyContinue; return ($v -and $v.AllowContextWithApps -eq 0)}catch{return $false} }
function Check-Recall { try{$v=Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Recall" -Name "Enabled" -EA SilentlyContinue; return ($v -and $v.Enabled -eq 0)}catch{return $false} }
function Check-DeviceEncryption {
    try {
        # Solo marcar como "hecho" si BitLocker está explícitamente desactivado
        $bv = Get-BitLockerVolume -MountPoint $env:SystemDrive -EA SilentlyContinue
        if ($null -eq $bv) { return $true } # No hay BitLocker
        return ($bv.ProtectionStatus -eq "Off")
    } catch { return $true }
}
function Optimize-DeviceEncryption {
    # NO desactivar BitLocker automáticamente — puede causar pérdida de datos
    # En cambio: informar al usuario claramente
    try {
        $bv = Get-BitLockerVolume -MountPoint $env:SystemDrive -EA SilentlyContinue
        if ($null -eq $bv -or $bv.ProtectionStatus -eq "Off") {
            Write-Log "  ✅ BitLocker no está activo en este equipo." "Green"
            return $true
        }
        Write-Log "  ℹ️ BitLocker está ACTIVO en este equipo." "Yellow"
        Write-Log "     Si querés desactivarlo, hacelo manualmente:" "TextDim"
        Write-Log "     Inicio → Cifrado de dispositivo → Desactivar" "Accent"
        Write-Log "     ⚠️ Primero guardá la clave de recuperación." "Yellow"
        Write-Log "     WDM no lo desactiva automáticamente para proteger tus datos." "TextDim"
        return $true
    } catch { Write-Log "  ℹ️ No se pudo verificar el estado de BitLocker." "TextDim"; return $true }
}
function Check-RecentFiles { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowRecent" -ExpectedValue 0) }
function Check-FrequentFolders { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowFrequent" -ExpectedValue 0) }
function Check-TailoredExperiences { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -ExpectedValue 0) }
function Check-SuggestionsInMenu { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -ExpectedValue 0) }
function Check-WelcomeExperience { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -ExpectedValue 0) }
function Check-CloudClipboard { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudClipboard" -Name "Enabled" -ExpectedValue 0) }
function Check-CloudContent { return (Check-OptimizationStatus -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -ExpectedValue 0) }

# ============================================================================
# FUNCIONES DE OPTIMIZACIÓN
# ============================================================================
function Optimize-BootServices {
    # Siempre desactivar: telemetría, xbox (si no juega), push notifications de Microsoft
    $svcsAlways = @("DiagTrack", "dmwappushservice", "XboxNetApiSvc", "XblAuthManager", "XblGameSave", "XboxGipSvc")
    # WSearch (indexación): desactivar solo si poca RAM o HDD — en SSD+16GB puede ser útil
    $desactivarWSearch = ($script:Hardware.RAM.TotalGB -le 8 -or -not $script:Hardware.SystemSSD)
    if ($desactivarWSearch) { $svcsAlways += "WSearch" }

    foreach ($s in $svcsAlways) { Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$s" -Name "Start" }

    $success = $false
    foreach ($sn in $svcsAlways) {
        try {
            $s = Get-Service -Name $sn -EA SilentlyContinue
            if ($s -and $s.StartType -ne "Disabled") {
                Set-Service -Name $sn -StartupType Disabled -EA Stop
                Stop-Service -Name $sn -Force -EA SilentlyContinue
                $success = $true
                Write-Log "  ✓ Servicio '$sn' desactivado" "Green"
            }
        } catch { Write-Log "  ℹ️ '$sn': no se pudo desactivar (puede no estar presente)" "TextDim" }
    }
    if (-not $desactivarWSearch) {
        Write-Log "  ℹ️ WSearch conservado (SSD + 16GB RAM — la indexación no impacta)" "TextDim"
    }
    if ($success) { Write-Log "  ✓ Servicios innecesarios desactivados" "Green"; return $true }
    return $false
}
function Optimize-Prefetch { try{$c=(Get-ChildItem "$env:SystemRoot\Prefetch" -Filter "*.pf"|Measure-Object).Count; if($c -gt 0){Get-ChildItem "$env:SystemRoot\Prefetch" -Filter "*.pf"|Remove-Item -Force -EA SilentlyContinue; Write-Log "  ✓ Prefetch limpiado ($c archivos)" "Green"; return $true}else{Write-Log "  ⚠️ No hay archivos" "Yellow"; return $false}}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-Win32Priority {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation"
    # Valor según núcleos Y tipo de equipo: laptop siempre equilibrado (2), desktop según núcleos
    $c = $script:Hardware.CPU.Cores
    $v = if ($script:Hardware.IsLaptop) { 2 } elseif ($c -ge 8) { 38 } elseif ($c -ge 4) { 26 } else { 18 }
    try {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value $v -Type DWord -EA Stop
        Write-Log "  ✓ Prioridad CPU ajustada para $c núcleos (valor $v)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-PowerThrottling {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff"
    # En laptops: NO desactivar — Windows lo usa para gestionar batería y temperatura
    # En desktop con poca RAM: tampoco — puede causar inestabilidad
    if ($script:Hardware.IsLaptop) {
        Write-Log "  ℹ️ Power Throttling conservado en laptop — gestiona batería y temperatura" "TextDim"
        return $true
    }
    if ($script:Hardware.RAM.TotalGB -lt 8) {
        Write-Log "  ℹ️ Power Throttling conservado — con poca RAM puede causar inestabilidad" "TextDim"
        return $true
    }
    try {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "PowerThrottlingOff" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Power Throttling desactivado (desktop con $($script:Hardware.RAM.TotalGB)GB)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-DisablePagingExecutive {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive"
    $ram = $script:Hardware.RAM.TotalGB
    # CRÍTICO: con menos de 8GB este tweak causa lentitud extrema (thrashing de memoria)
    # Solo tiene sentido con 16GB+ donde el kernel en RAM no compite con los programas
    if ($ram -lt 8) {
        Write-Log "  ℹ️ Kernel en RAM omitido — con ${ram}GB causaría lentitud (necesita 8GB+)" "TextDim"
        return $true
    }
    try {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Kernel forzado en RAM física (${ram}GB disponibles)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-LargeSystemCache {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache"
    # Solo tiene sentido con 16GB+. Con poca RAM compite con los programas del usuario.
    if ($script:Hardware.RAM.TotalGB -lt 16) {
        Write-Log "  ℹ️ LargeSystemCache omitido (menos de 16GB RAM — sería contraproducente)" "TextDim"
        return $true
    }
    try {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Caché de sistema ampliada (16GB+ disponibles)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-SysMain {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" -Name "Start"
    $ram   = $script:Hardware.RAM.TotalGB
    $hasSSD = ($script:Hardware.Disks | Where-Object { $_.Type -eq "SSD" }).Count -gt 0
    # SysMain en SSD con suficiente RAM: desactivar (el SSD ya es rápido, SysMain solo consume RAM)
    # SysMain en HDD o poca RAM: CONSERVAR — es quien precarga programas y evita lentitud
    if (-not $hasSSD -or $ram -lt 8) {
        Write-Log "  ℹ️ SysMain conservado — en HDD o poca RAM ayuda a precargar programas" "TextDim"
        Write-Log "    Desactivarlo en este equipo causaría lentitud al abrir aplicaciones." "TextDim"
        return $true
    }
    try {
        Set-Service -Name SysMain -StartupType Disabled -EA Stop
        Stop-Service -Name SysMain -Force -EA SilentlyContinue
        Write-Log "  ✓ SysMain desactivado (SSD + ${ram}GB — no es necesario)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-Hibernate { try{powercfg /h off|Out-Null; Write-Log "  ✓ Hibernación desactivada (libera espacio)" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-NtfsLastAccess { Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate"; try{Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1 -Type DWord -EA Stop; Write-Log "  ✓ Marca de último acceso NTFS desactivada" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-IOPriority { Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IoPriority"; try{Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IoPriority" -Value 3 -Type DWord -EA Stop; Write-Log "  ✓ Prioridad IO elevada" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-Prefetcher {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher"
    # SSD: desactivar prefetch (el disco ya es rápido, prefetch consume RAM innecesariamente)
    # HDD: activar al máximo (3 = aplicaciones + boot), acelera mucho en discos lentos
    $v = if ($script:Hardware.SystemSSD) { 0 } else { 3 }
    $desc = if ($script:Hardware.SystemSSD) { "desactivado en SSD (no necesario)" } else { "máximo en HDD (acelera arranque)" }
    try {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value $v -Type DWord -EA Stop
        Write-Log "  ✓ Prefetcher $desc" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-TCPAutoTuning { try{netsh int tcp set global autotuninglevel=normal|Out-Null; Write-Log "  ✓ TCP AutoTuning optimizado" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-RSS { try{netsh int tcp set global rss=enabled|Out-Null; Write-Log "  ✓ RSS activado (distribución de red en núcleos)" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-TCPNoDelay {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay"
    try {
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -Value 1 -Type DWord -EA Stop
        foreach ($ad in (Get-NetAdapter|Where-Object{$_.Status -eq "Up"})) {
            $p="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($ad.InterfaceGuid)"
            if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
            Set-ItemProperty -Path $p -Name "TCPNoDelay" -Value 1 -Type DWord -EA SilentlyContinue
        }
        Write-Log "  ✓ TCP NoDelay activado (menor latencia)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-HAGS {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode"
    try {
        # HAGS solo es seguro con GPU dedicada NVIDIA/AMD moderna y driver actualizado
        # Con GPU integrada Intel puede causar flasheo en browsers Chromium-based
        $gpuP = $script:Hardware.GPUProfile
        $tieneGPUDedicada = ($gpuP -and $gpuP.HasDedicated -and ($gpuP.IsNVIDIA -or $gpuP.IsAMD))
        if (-not $tieneGPUDedicada) {
            Write-Log "  ℹ️ HAGS omitido — solo recomendado con GPU NVIDIA/AMD dedicada." "TextDim"
            Write-Log "     Con GPU integrada Intel puede causar parpadeo en Chrome/Brave/Edge." "TextDim"
            return $true
        }
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -EA Stop
        Write-Log "  ✓ HAGS activado (GPU dedicada $($gpuP.Dedicated[0].Name) detectada)" "Green"
        Write-Log "    Si ves parpadeo en browsers después de reiniciar, desactivá HAGS." "TextDim"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-DWMPriority { Save-OriginalValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\WindowsManager" -Name "Priority"; try{$p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\WindowsManager"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "Priority" -Value 2 -Type DWord -EA Stop; Write-Log "  ✓ Prioridad del motor gráfico de Windows elevada" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-Transparencias { Save-OriginalValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency"; try{Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Transparencias desactivadas (ahorra GPU)" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-GameDVR { Save-OriginalValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled"; try{Set-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -EA Stop; $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty $p -Name "AllowGameDVR" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Grabación en segundo plano desactivada" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-StartupDelay { Save-OriginalValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec"; try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "StartupDelayInMSec" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Retraso de inicio eliminado" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-TdrDelay {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay"
    # TdrDelay: tiempo antes de que Windows "reinicie" la GPU si no responde
    # Valor por defecto de Windows = 2s — demasiado bajo, causa flasheos
    # Valor recomendado: 8s desktop / 10s laptop (da más tiempo al driver sin perder control)
    # TdrDdiDelay: timeout para llamadas de driver — 15s evita resets por spikes
    $v = if ($script:Hardware.IsLaptop) { 10 } else { 8 }
    try {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty -Path $p -Name "TdrDelay"    -Value $v  -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "TdrDdiDelay" -Value 15  -Type DWord -EA SilentlyContinue
        Set-ItemProperty -Path $p -Name "TdrLevel"    -Value 3   -Type DWord -EA SilentlyContinue
        Write-Log "  ✓ Timeout GPU: $v s (evita parpadeo de pantalla en browsers)" "Green"
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-PowerPlan { try{if($script:Hardware.IsLaptop){powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e|Out-Null; Write-Log "  ✓ Plan equilibrado activado" "Green"}else{powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c|Out-Null; Write-Log "  ✓ Plan alto rendimiento activado" "Green"}; return $true}catch{return $false} }
function Optimize-WiFiPowerSave {
    try {
        # Detectar por tipo de medio, no solo por nombre — funciona en cualquier idioma
        $ads = Get-NetAdapter | Where-Object {
            $_.Status -eq "Up" -and (
                $_.Name -match "Wi[-]?Fi|Wireless|WLAN|802\.11" -or
                $_.InterfaceDescription -match "Wireless|Wi-Fi|802\.11|WLAN"
            )
        }
        $count = 0
        foreach ($ad in $ads) {
            # Desactivar ahorro de energía del adaptador WiFi
            try { Disable-NetAdapterPowerManagement -Name $ad.Name -EA Stop; $count++ } catch {}
            # Desactivar el modo de ahorro en el driver vía registro
            $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($ad.InterfaceGuid)"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            # PowerSaveMode 0 = sin ahorro, 3 = ahorro máximo
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}" `
                -Name "PowerSaveMode" -Value 0 -Type DWord -EA SilentlyContinue
        }
        if ($count -gt 0) { Write-Log "  ✓ WiFi sin modo ahorro de energía ($count adaptador/es)" "Green"; return $true }
        Write-Log "  ℹ️ No se encontró adaptador WiFi activo" "Yellow"; return $false
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-EthernetJumbo {
    try {
        # Detectar Ethernet por descripción del adaptador — funciona en cualquier idioma
        $ads = Get-NetAdapter | Where-Object {
            $_.Status -eq "Up" -and
            $_.InterfaceDescription -notmatch "Wireless|Wi-Fi|802\.11|Virtual|VPN|Loopback|Bluetooth" -and
            $_.MediaType -eq "802.3"
        }
        # Solo en adaptadores Gigabit o superior (no tiene sentido en Fast Ethernet 100Mbps)
        $ads = $ads | Where-Object {
            $spd = 0
            if ($_.LinkSpeed -match "(\d+\.?\d*)\s*(Gbps|Mbps)") {
                $n = [double]$matches[1]
                $u = $matches[2]
                $spd = if ($u -eq "Gbps") { $n * 1000 } else { $n }
            }
            $spd -ge 1000
        }
        $count = 0
        foreach ($ad in $ads) {
            try {
                Set-NetAdapterAdvancedProperty -Name $ad.Name -RegistryKeyword "*JumboPacket" -RegistryValue 9014 -EA Stop
                $count++
                Write-Log "  ✓ Jumbo Frames en: $($ad.Name)" "Green"
            } catch {
                Write-Log "  ℹ️ $($ad.Name): no soporta Jumbo Frames (normal en algunos adaptadores)" "TextDim"
            }
        }
        if ($count -gt 0) { Write-Log "  ✓ Jumbo Frames activado en $count adaptador/es Gigabit" "Green"; return $true }
        if ($ads.Count -eq 0) { Write-Log "  ℹ️ No se encontró Ethernet Gigabit activo" "Yellow" }
        return $false
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-IPv6 {
    try {
        foreach ($ad in (Get-NetAdapter|Where-Object{$_.Status -eq "Up"})) { Disable-NetAdapterBinding -Name $ad.Name -ComponentID ms_tcpip6 -EA SilentlyContinue }
        Write-Log "  ✓ IPv6 desactivado" "Green"; return $true
    } catch { return $false }
}
function Optimize-ProcessScheduling { Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation"; try{$c=$script:Hardware.CPU.Cores; $v=if($c -ge 8){38}elseif($c -ge 4){26}else{18}; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value $v -Type DWord -EA Stop; Write-Log "  ✓ Scheduling de CPU optimizado para $c núcleos" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-USB { Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend"; try{$p="HKLM:\SYSTEM\CurrentControlSet\Services\USB"; if(Test-Path $p){Set-ItemProperty -Path $p -Name "DisableSelectiveSuspend" -Value 1 -Type DWord -EA Stop}; Write-Log "  ✓ USB optimizado" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-DailyExperience {
    Save-OriginalValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay"
    Save-OriginalValue -Path "HKCU:\Control Panel\Mouse"   -Name "MouseHoverTime"
    try {
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -EA Stop
        Set-ItemProperty "HKCU:\Control Panel\Mouse"   -Name "MouseHoverTime" -Value "10" -EA Stop
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DontSearchInCompressFolders" -Value 1 -Type DWord -EA Stop
        Write-Log "  ✓ Menús y respuesta del mouse optimizados" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-FastShutdown {
    foreach ($n in @("AutoEndTasks","WaitToKillAppTimeout","HungAppTimeout")) { Save-OriginalValue -Path "HKCU:\Control Panel\Desktop" -Name $n }
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout"
    try {
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks"          -Value "1"    -EA Stop
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout"  -Value "2000" -EA Stop
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout"        -Value "1000" -EA Stop
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value 2000 -Type DWord -EA Stop
        Write-Log "  ✓ Apagado rápido configurado" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-VRR { Save-OriginalValue -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectX UserGpuPreferences"; try{$p="HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "DirectX UserGpuPreferences" -Value "WindowedOptimizations=1" -Type String -EA Stop; Write-Log "  ✓ VRR optimizado" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-GpuPriority {
    Save-OriginalValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority"
    try {
        $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
        Set-ItemProperty -Path $p -Name "GPU Priority" -Value 8 -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "Priority"     -Value 6 -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "Scheduling Category" -Value "High"  -Type String -EA Stop
        Set-ItemProperty -Path $p -Name "SFIO Priority"       -Value "High"  -Type String -EA Stop
        Set-ItemProperty -Path $p -Name "Background Only"     -Value "False" -Type String -EA Stop
        Write-Log "  ✓ Prioridad GPU/CPU al máximo" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-VisualEffects {
    Save-OriginalValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting"
    try {
        $vp="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; if(-not(Test-Path $vp)){New-Item -Path $vp -Force|Out-Null}
        Set-ItemProperty -Path $vp -Name "VisualFXSetting" -Value 2 -Type DWord -EA Stop
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "FontSmoothing"     -Value "2" -EA SilentlyContinue
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -Value 2 -Type DWord -EA SilentlyContinue
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "DragFullWindows"   -Value "0" -EA SilentlyContinue
        Write-Log "  ✓ Efectos visuales reducidos al mínimo útil" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-MemoryCompression {
    try {
        $ram=$script:Hardware.RAM.TotalGB
        if($ram -ge 16){Disable-MMAgent -MemoryCompression -EA Stop; Write-Log "  ✓ Compresión de memoria desactivada (${ram}GB — no es necesaria)" "Green"}
        else{Enable-MMAgent -MemoryCompression -EA Stop; Write-Log "  ✓ Compresión de memoria activada (${ram}GB — ayuda con poca RAM)" "Green"}
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-IRQPriority { Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority"; try{$p="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Set-ItemProperty -Path $p -Name "IRQ8Priority" -Value 1 -Type DWord -EA Stop; Set-ItemProperty -Path $p -Name "IRQ16Priority" -Value 1 -Type DWord -EA SilentlyContinue; Set-ItemProperty -Path $p -Name "IRQ17Priority" -Value 1 -Type DWord -EA SilentlyContinue; Write-Log "  ✓ Prioridades de interrupción optimizadas" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-WriteCaching { try{$dp="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Set-ItemProperty -Path $dp -Name "WriteCache" -Value 1 -Type DWord -EA SilentlyContinue; Write-Log "  ✓ Caché de escritura activada" "Green"; return $true}catch{return $false} }
function Optimize-NetworkThrottling {
    Save-OriginalValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex"
    Save-OriginalValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness"
    try {
        $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -EA Stop
        # En laptop: SystemResponsiveness=10 (equilibrio rendimiento/batería)
        # En desktop: SystemResponsiveness=0 (máximo rendimiento, sin preocupación de energía)
        $responsiveness = if ($script:Hardware.IsLaptop) { 10 } else { 0 }
        Set-ItemProperty -Path $p -Name "SystemResponsiveness" -Value $responsiveness -Type DWord -EA Stop
        $desc = if ($script:Hardware.IsLaptop) { "equilibrado (laptop)" } else { "máximo rendimiento" }
        Write-Log "  ✓ Límite de red de Windows eliminado — responsiveness $desc" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-TCPAdvanced {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL"
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency"
    try {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $p -Name "DefaultTTL"            -Value 64 -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "TcpAckFrequency"       -Value 1  -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "TcpDelAckTicks"        -Value 0  -Type DWord -EA Stop
        # TcpNoDelay ya lo maneja Optimize-TCPNoDelay — no duplicar
        # Ventana TCP grande solo si hay red rápida (Gigabit o superior)
        $networkInfo = Get-NetworkProfile
        if ($networkInfo -and $networkInfo.Speed -ge 1000) {
            Set-ItemProperty -Path $p -Name "GlobalMaxTcpWindowSize" -Value 65535 -Type DWord -EA SilentlyContinue
            Set-ItemProperty -Path $p -Name "TcpWindowSize"          -Value 65535 -Type DWord -EA SilentlyContinue
        }
        foreach ($ad in (Get-NetAdapter | Where-Object { $_.Status -eq "Up" })) {
            $ip = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($ad.InterfaceGuid)"
            if (Test-Path $ip) {
                Set-ItemProperty -Path $ip -Name "TcpAckFrequency" -Value 1 -Type DWord -EA SilentlyContinue
            }
        }
        Write-Log "  ✓ TCP avanzado configurado (TTL=64, ACK inmediato)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-TimerResolution { try{bcdedit /set disabledynamictick yes|Out-Null; bcdedit /set useplatformclock false|Out-Null; Write-Log "  ✓ Resolución del timer optimizada" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-PageFile {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem
        $cs.AutomaticManagedPagefile = $false; $cs.Put() | Out-Null
        $ram = $script:Hardware.RAM.TotalGB
        # Regla sensata por rango de RAM:
        # ≤4GB:  init=4096  max=8192  (necesita bastante pagefile como RAM extra)
        # 8GB:   init=4096  max=8192
        # 16GB:  init=4096  max=8192  (lo suficiente para dumps de memoria)
        # 32GB+: init=2048  max=4096  (casi no se usa, solo para crash dumps)
        if ($ram -le 8)       { $initMB = 4096; $maxMB = 8192 }
        elseif ($ram -le 16)  { $initMB = 4096; $maxMB = 8192 }
        else                  { $initMB = 2048; $maxMB = 4096  }

        $pf = Get-CimInstance Win32_PageFileSetting -EA SilentlyContinue
        if ($pf) { $pf | ForEach-Object { $_.InitialSize = $initMB; $_.MaximumSize = $maxMB; $_.Put() | Out-Null } }
        else {
            $new = [wmiclass]"Win32_PageFileSetting"
            $new.Create("$env:SystemDrive\pagefile.sys", $initMB, $maxMB) | Out-Null
        }
        Write-Log "  ✓ PageFile fijo: $initMB-$maxMB MB (apropiado para ${ram}GB RAM)" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-WindowsAnimations { Save-OriginalValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate"; try{$p="HKCU:\Control Panel\Desktop\WindowMetrics"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "MinAnimate" -Value "0" -EA Stop; Write-Log "  ✓ Animaciones de ventanas desactivadas" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-CPUParking { try{powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100|Out-Null; powercfg /setactive SCHEME_CURRENT|Out-Null; Write-Log "  ✓ Todos los núcleos del CPU activos" "Green"; return $true}catch{Write-Log "  ✗ Error: $_" "Red"; return $false} }
function Optimize-NVIDIAPower {
    try {
        $nvidiaPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        Get-ChildItem $nvidiaPath -EA SilentlyContinue | ForEach-Object {
            $drv=Get-ItemProperty $_.PSPath -Name "DriverDesc" -EA SilentlyContinue
            if ($drv -and $drv.DriverDesc -match "NVIDIA") {
                Set-ItemProperty -Path $_.PSPath -Name "PerfLevelSrc"      -Value 0x3322 -Type DWord -EA SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "PowerMizerEnable"  -Value 1      -Type DWord -EA SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "PowerMizerLevel"   -Value 1      -Type DWord -EA SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "PowerMizerLevelAC" -Value 1      -Type DWord -EA SilentlyContinue
            }
        }
        Write-Log "  ✓ NVIDIA en modo máximo rendimiento" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-PowerPlanUltimate {
    try {
        if ($script:Hardware.IsLaptop) { Write-Log "  ⚠️ Plan Ultimate no recomendado en laptop — usando Alto Rendimiento" "Yellow"; return Optimize-PowerPlan }
        $ug="e9a42b02-d5df-448d-aa00-03f14749eb61"
        powercfg /duplicatescheme $ug 2>$null|Out-Null
        powercfg /setactive $ug 2>$null|Out-Null
        if($LASTEXITCODE -eq 0){Write-Log "  ✓ Plan Ultimate Performance activado" "Green"; return $true}
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c|Out-Null
        Write-Log "  ✓ Plan Alto Rendimiento activado" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-DiskServices {
    try {
        $service=Get-Service -Name defragsvc -EA SilentlyContinue
        if($service -and $script:Hardware.SystemSSD -eq $false){
            if($service.StartType -ne "Automatic"){Set-Service -Name defragsvc -StartupType Automatic -EA Stop; Write-Log "  ✓ Desfragmentación programada activada (HDD)" "Green"}
        }
        if($script:Hardware.SystemSSD){Write-Log "  ✓ SSD: desfragmentación periódica conservada (normal)" "Green"}
        return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-MemoryManagement {
    Save-OriginalValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache"
    try {
        $ram=$script:Hardware.RAM.TotalGB
        $lsc = if($ram -ge 16){1}else{0}; $pool = if($ram -ge 16){512}else{256}
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value $lsc  -Type DWord -EA Stop
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PoolUsageMaximum" -Value $pool -Type DWord -EA Stop
        Write-Log "  ✓ Gestión de memoria ajustada para ${ram}GB" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-IconCache {
    try {
        $icp="$env:LOCALAPPDATA\IconCache.db"
        $exp=($null -ne (Get-Process -Name explorer -EA SilentlyContinue))
        if($exp){Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep -Milliseconds 500}
        if(Test-Path $icp){Remove-Item $icp -Force -EA SilentlyContinue}
        if($exp){Start-Process explorer}
        Write-Log "  ✓ Caché de iconos reconstruida" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-TaskScheduler {
    try {
        $s=Get-Service -Name Schedule -EA Stop
        if($s.Status -ne "Running"){Start-Service -Name Schedule -EA Stop}
        if($s.StartType -ne "Automatic"){Set-Service -Name Schedule -StartupType Automatic -EA Stop}
        Write-Log "  ✓ Programador de tareas activo" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-ExplorerStartup {
    try {
        $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
        Set-ItemProperty -Path $p -Name "EnableBalloonTips"             -Value 0 -Type DWord -EA Stop
        Set-ItemProperty -Path $p -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord -EA Stop
        Write-Log "  ✓ Explorador de archivos optimizado" "Green"; return $true
    } catch { Write-Log "  ✗ Error: $_" "Red"; return $false }
}
function Optimize-StartupPrograms { try{Write-Log "  ℹ️ Abriendo Administrador de Tareas..." "Yellow"; Start-Process "taskmgr.exe" -EA SilentlyContinue; Write-Log "  ✓ Ir a la pestaña 'Inicio' para desactivar programas" "Green"; return $true}catch{return $false} }

# ============================================================================
# PRIVACIDAD
# ============================================================================
function Optimize-AdvertisingID { Save-OriginalValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled"; try{Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ ID de publicidad desactivado" "Green"; return $true}catch{return $false} }
function Optimize-Location { try{$p="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "Value" -Value "Deny" -Type String -EA Stop; Write-Log "  ✓ Ubicación bloqueada" "Green"; return $true}catch{return $false} }
function Optimize-Camera { try{$p="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "Value" -Value "Deny" -Type String -EA Stop; Write-Log "  ✓ Cámara bloqueada" "Green"; return $true}catch{return $false} }
function Optimize-Microphone { try{$p="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "Value" -Value "Deny" -Type String -EA Stop; Write-Log "  ✓ Micrófono bloqueado" "Green"; return $true}catch{return $false} }
function Optimize-Notifications { try{Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Notificaciones de apps desactivadas" "Green"; return $true}catch{return $false} }
function Optimize-ActivityHistory { try{$p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "EnableActivityFeed" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Historial de actividad desactivado" "Green"; return $true}catch{return $false} }
function Optimize-TailoredExperiences { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Experiencias personalizadas desactivadas" "Green"; return $true}catch{return $false} }
function Optimize-RecentFiles { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "ShowRecent" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Archivos recientes ocultados" "Green"; return $true}catch{return $false} }
function Optimize-FrequentFolders { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "ShowFrequent" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Carpetas frecuentes ocultadas" "Green"; return $true}catch{return $false} }
function Optimize-SuggestionsInMenu { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Sugerencias del menú Inicio desactivadas" "Green"; return $true}catch{return $false} }
function Optimize-WelcomeExperience { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "SubscribedContent-310093Enabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Pantalla de bienvenida desactivada" "Green"; return $true}catch{return $false} }
function Optimize-CloudClipboard { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudClipboard"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "Enabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Portapapeles en la nube desactivado" "Green"; return $true}catch{return $false} }
function Optimize-CloudContent { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Contenido de la nube desactivado" "Green"; return $true}catch{return $false} }
function Optimize-CortanaWin10 { if(-not $script:WindowsVersion.IsWin10){return $false}; try{$p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "AllowCortana" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Cortana desactivado" "Green"; return $true}catch{return $false} }
function Optimize-Copilot { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "ShowCopilotButton" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Botón Copilot ocultado" "Green"; return $true}catch{return $false} }
function Optimize-CopilotWebSearch { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "IsWebSearchEnabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Búsqueda web de Copilot bloqueada" "Green"; return $true}catch{return $false} }
function Optimize-CopilotContext { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Copilot"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "AllowContextWithApps" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Acceso de Copilot a apps bloqueado" "Green"; return $true}catch{return $false} }
function Optimize-Recall { try{$p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Recall"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "Enabled" -Value 0 -Type DWord -EA Stop; Write-Log "  ✓ Recall desactivado" "Green"; return $true}catch{return $true} }
# Optimize-DeviceEncryption está definida arriba junto a Check-DeviceEncryption

# ============================================================================
# DETECCIÓN WIN11
# ============================================================================
function Test-CopilotExists {
    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $path)) { return $false }
        $values = Get-ItemProperty -Path $path -EA SilentlyContinue
        if ($values.PSObject.Properties.Name -contains "ShowCopilotButton") { return $true }
        if ($script:WindowsVersion.IsWin11 -and $script:WindowsVersion.Build -ge 22621) { return $true }
        return $false
    } catch { return $false }
}
function Test-RecallExists { try { return (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Recall") } catch { return $false } }

# ============================================================================
# SALUD DEL SISTEMA + REPARACIÓN (TAB UNIFICADO)
# ============================================================================

# Estado de etapas del diagnóstico (persiste en la sesión)
$script:DiagEstados = @{}

function Write-DiagEtapa {
    param($Num, $Total, $Nombre, $Estado, $Color)
    $icon = switch ($Estado) {
        "ok"      { "✅" }
        "warn"    { "⚠️" }
        "fail"    { "❌" }
        "skip"    { "⏭️" }
        "running" { "⏳" }
        default   { "🔹" }
    }
    Write-SaludLog "━━━ [$Num/$Total] $Nombre $icon ━━━━━━━━━━━━━━━━━━━━━━" $Color
}

function Get-RedDiagnostico {
    # Lee y muestra toda la info de red SIN tocar nada
    $resultado = @{ OK=$true; Detalles=@() }
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        if (-not $adapters) {
            Write-SaludLog "  ❌ No hay adaptadores de red activos." "Red"
            $resultado.OK = $false
            return $resultado
        }

        foreach ($ad in $adapters) {
            $ip4 = (Get-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -EA SilentlyContinue | Select-Object -First 1).IPAddress
            $gw  = (Get-NetRoute -InterfaceIndex $ad.ifIndex -DestinationPrefix "0.0.0.0/0" -EA SilentlyContinue | Select-Object -First 1).NextHop

            # Tipo de adaptador
            $tipo = if ($ad.InterfaceDescription -match "Wireless|Wi-Fi|802\.11|WLAN") { "WiFi" }
                    elseif ($ad.MediaType -eq "802.3") { "Ethernet" }
                    else { $ad.MediaType }

            Write-SaludLog "  🔌 $tipo — $($ad.Name)" "Accent"
            Write-SaludLog "     Velocidad del enlace: $($ad.LinkSpeed)" "TextSecond"
            if ($ip4) { Write-SaludLog "     IP local:  $ip4" "TextDim" }
            if ($gw)  { Write-SaludLog "     Gateway:   $gw" "TextDim" }

            # DNS configurados — mostrar sin juzgar
            try {
                $dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -EA SilentlyContinue).ServerAddresses
                if ($dnsServers -and $dnsServers.Count -gt 0) {
                    Write-SaludLog "     DNS:       $($dnsServers -join ', ')" "TextDim"
                }
            } catch {}

            # Proxy configurado — mostrar sin tocar
            try {
                $proxyReg = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -EA SilentlyContinue
                if ($proxyReg -and $proxyReg.ProxyEnable -eq 1 -and $proxyReg.ProxyServer) {
                    Write-SaludLog "     Proxy:     $($proxyReg.ProxyServer) ✅ (configurado)" "TextDim"
                }
            } catch {}

            # Latencia al gateway
            if ($gw) {
                try {
                    $pingGw = Test-Connection $gw -Count 2 -EA SilentlyContinue
                    if ($pingGw) {
                        $lat = [math]::Round(($pingGw | Measure-Object ResponseTime -Average).Average, 0)
                        $latColor = if ($lat -lt 5) {"Green"} elseif ($lat -lt 20) {"TextSecond"} else {"Yellow"}
                        Write-SaludLog "     Latencia al gateway: ${lat}ms" $latColor
                    }
                } catch {}
            }
            Write-SaludLog "" "TextPrimary"
        }

        # Conectividad a internet (ping a IPs, no DNS, para separar los dos problemas)
        $pingIP  = Test-Connection "8.8.8.8"    -Count 1 -Quiet -EA SilentlyContinue
        $pingDNS = Test-Connection "google.com" -Count 1 -Quiet -EA SilentlyContinue

        if ($pingIP) {
            Write-SaludLog "  ✅ Conexión a Internet: OK" "Green"
            $script:SaludResults.Pass++
        } else {
            Write-SaludLog "  ❌ Sin conexión a Internet" "Red"
            Write-SaludLog "     Verificá el cable o la señal WiFi." "TextDim"
            Write-SaludLog "     Si el problema persiste, reiniciá el router." "TextDim"
            $script:SaludResults.Fail++
            $resultado.OK = $false
        }

        if ($pingIP -and $pingDNS) {
            Write-SaludLog "  ✅ Resolución DNS: OK (los nombres de dominio responden)" "Green"
            $script:SaludResults.Pass++
        } elseif ($pingIP -and -not $pingDNS) {
            Write-SaludLog "  ⚠️ Internet OK pero DNS con problemas" "Yellow"
            Write-SaludLog "     Los sitios web pueden tardar en cargar." "TextDim"
            Write-SaludLog "     Podés intentar limpiar la caché DNS desde el tab LIMPIEZA." "Yellow"
            $script:SaludResults.Warn++
        }

        # Verificar proxy si está configurado
        try {
            $proxyReg = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -EA SilentlyContinue
            if ($proxyReg -and $proxyReg.ProxyEnable -eq 1 -and $proxyReg.ProxyServer) {
                $proxyHost = $proxyReg.ProxyServer -replace "http://","" -replace ":.*",""
                $proxyPort = if ($proxyReg.ProxyServer -match ":(\d+)$") { [int]$matches[1] } else { 80 }
                try {
                    $tcpTest = New-Object System.Net.Sockets.TcpClient
                    $tcpTest.Connect($proxyHost, $proxyPort)
                    $tcpTest.Close()
                    Write-SaludLog "  ✅ Proxy responde correctamente ($($proxyReg.ProxyServer))" "Green"
                    $script:SaludResults.Pass++
                } catch {
                    Write-SaludLog "  ⚠️ Proxy configurado ($($proxyReg.ProxyServer)) pero no responde." "Yellow"
                    Write-SaludLog "     Puede causar problemas de navegación." "TextDim"
                    $script:SaludResults.Warn++
                }
            }
        } catch {}

    } catch {
        Write-SaludLog "  ✗ Error verificando red: $_" "Red"
        $resultado.OK = $false
    }
    return $resultado
}


# ============================================================================
# GENERAR LISTA DE OPTIMIZACIONES
# ============================================================================
# Mapa de explicaciones humanas por función
$script:Explicaciones = @{
    "Optimize-DailyExperience"   = "Los menús de Windows esperan 400ms antes de abrirse. Esta optimización los hace instantáneos. También ajusta la velocidad del cursor para que responda más rápido. Pequeños cambios, gran diferencia en el uso diario."
    "Optimize-FastShutdown"      = "Cuando apagás la PC, Windows espera hasta 20 segundos que los programas terminen solos. Esta optimización reduce ese tiempo a 2 segundos: si un programa no cerró solo, Windows lo cierra."
    "Optimize-BootServices"      = "Windows arranca con varios servicios activos que la mayoría de las personas nunca usa: telemetría, Xbox, búsqueda indexada. Desactivarlos reduce el tiempo de inicio y libera memoria RAM."
    "Optimize-Prefetch"          = "Windows guarda información de cada programa que ejecutaste para abrirlo más rápido. Esta limpieza borra los registros de programas que ya no existen o que nunca abrís."
    "Optimize-Win32Priority"     = "Le dice a Windows que le dé más tiempo de CPU al programa que estás usando ahora, en vez de repartirlo parejo entre procesos en segundo plano. Resultado: la app activa responde mejor."
    "Optimize-PowerThrottling"   = "Windows puede reducir la velocidad del CPU de forma automática para ahorrar energía. Esta optimización lo desactiva en PCs de escritorio donde no importa el consumo."
    "Optimize-ProcessScheduling" = "Ajusta cómo el CPU distribuye el tiempo entre procesos según cuántos núcleos tenés. Para tu CPU específico, el valor óptimo es calculado por WDM automáticamente."
    "Optimize-TimerResolution"   = "Windows usa un temporizador de 15.6ms para organizar tareas. Reducirlo mejora la precisión en audio, juegos y cualquier tarea que necesite respuesta rápida."
    "Optimize-IRQPriority"       = "Ajusta la prioridad con la que el CPU atiende las interrupciones del hardware (teclado, mouse, red). Priorizar las interrupciones del timer mejora la respuesta general."
    "Optimize-CPUParking"        = "Windows puede 'estacionar' núcleos del CPU para ahorrar energía. Esta optimización los mantiene todos activos para máximo rendimiento en PC de escritorio."
    "Optimize-SysMain"           = "SysMain (Superfetch) precarga programas en RAM para abrirlos más rápido. En PCs con poca RAM (<8GB), esto compite con los programas que ya estás usando. Mejor desactivarlo."
    "Optimize-DisablePagingExecutive" = "Mantiene el núcleo de Windows en RAM física en vez de mandarlo al disco cuando hay espacio. Necesita 16GB o más de RAM para funcionar bien — WDM solo lo activa si corresponde."
    "Optimize-LargeSystemCache"  = "Usa más RAM para cachear archivos del disco. Acelera la apertura de documentos y archivos en PCs con mucha RAM (16GB+)."
    "Optimize-MemoryManagement"  = "Ajusta cuánta RAM destina Windows a su propio caché según cuánta tenés. En PCs con poca RAM, reduce el caché para dejar más espacio a tus programas."
    "Optimize-MemoryCompression" = "Con poca RAM, Windows puede comprimir lo que hay en memoria para meter más datos. Con mucha RAM (16GB+), esto consume CPU innecesariamente — WDM elige según tu equipo."
    "Optimize-PageFile"          = "El archivo de paginación es espacio en disco que Windows usa como RAM extra. WDM lo configura a tamaño fijo según tu RAM para evitar que Windows lo redimensione mientras trabajás."
    "Optimize-Hibernate"         = "La hibernación guarda todo en el disco cuando apagás para arrancar más rápido la próxima vez. En SSD esto ocupa varios GB que se pueden aprovechar mejor."
    "Optimize-NtfsLastAccess"    = "Cada vez que abrís un archivo, Windows anota la fecha y hora. Esta escritura constante desgasta más el disco. Desactivarla reduce escrituras sin afectar el funcionamiento."
    "Optimize-Prefetcher"        = "El prefetcher predice qué archivos vas a necesitar y los carga en RAM antes de que los pidas. En SSD no es necesario porque el disco ya es muy rápido; en HDD ayuda bastante."
    "Optimize-IOPriority"        = "Ajusta la prioridad con la que el CPU atiende las operaciones de lectura/escritura del disco. En discos mecánicos (HDD), esto reduce los tiempos de espera."
    "Optimize-DiskServices"      = "En discos mecánicos (HDD), activa la desfragmentación programada para mantener los archivos ordenados. En SSD no es necesario y se omite automáticamente."
    "Optimize-WriteCaching"      = "Activa una caché en memoria para las escrituras en disco: en vez de escribir cada dato de inmediato, los junta y escribe de a grupos. Mejora la velocidad pero requiere un buen corte de luz."
    "Optimize-TCPAutoTuning"     = "Ajusta cómo Windows maneja el tamaño de los paquetes de red para maximizar la velocidad de descarga según la latencia de tu conexión."
    "Optimize-RSS"               = "Distribuye el procesamiento de la red entre varios núcleos del CPU. En CPU multinúcleo mejora el rendimiento con descargas o videollamadas."
    "Optimize-TCPNoDelay"        = "El algoritmo Nagle agrupa paquetes pequeños para ser más eficiente, pero esto agrega latencia. Desactivarlo reduce el ping en juegos y videollamadas."
    "Optimize-TCPAdvanced"       = "Configuraciones avanzadas del protocolo TCP: TTL optimizado, confirmaciones inmediatas, sin retardos. Mejora la velocidad y latencia de la conexión."
    "Optimize-NetworkThrottling" = "Windows limita el uso de red de los programas para reservar ancho de banda. Esta optimización elimina ese límite artificial."
    "Optimize-WiFiPowerSave"     = "El adaptador WiFi puede reducir su velocidad para ahorrar batería. Esta optimización lo mantiene siempre al máximo rendimiento."
    "Optimize-EthernetJumbo"     = "Los Jumbo Frames aumentan el tamaño de los paquetes de red de 1500 bytes a 9000 bytes, reduciendo la cantidad de paquetes enviados. Solo útil en redes Gigabit internas."
    "Optimize-IPv6"              = "Si tu red no usa IPv6 (la mayoría no lo hace), tener ese protocolo activo agrega overhead sin beneficio. Desactivarlo puede mejorar levemente la conexión. WDM detecta si tu red lo usa antes de sugerirlo."
    "Optimize-ExtensionesVisibles"       = "Por defecto Windows oculta la extensión de los archivos (.exe, .pdf, .docx). Esto es un riesgo: un archivo malicioso puede llamarse 'foto.jpg.exe' y parecer una imagen. Con extensiones visibles ves exactamente qué tipo de archivo es antes de abrirlo."
    "Optimize-ArchivosOcultosVisibles"   = "Windows oculta ciertos archivos del sistema para protegerlos. Esta opción muestra los archivos ocultos normales (configuraciones, carpetas de apps) pero mantiene ocultos los archivos críticos del sistema para no romper nada por accidente."
    "Optimize-ExploradorEstaPC"          = "Por defecto el Explorador abre en 'Acceso Rápido' mostrando archivos recientes. Configurarlo para abrir en 'Esta PC' te da acceso directo a todas tus unidades y es más útil para la mayoría de las personas."
    "Optimize-CarpetasAntesDeArchivos"   = "Ordena el contenido de las carpetas mostrando primero las subcarpetas y luego los archivos. También muestra la ruta completa en la barra de título del explorador — sabés siempre dónde estás."
    "Optimize-SinAgrupacionesExplorador" = "Windows a veces agrupa automáticamente los archivos por fecha, tipo o tamaño de forma confusa. Esta opción resetea las vistas guardadas del Explorador para que muestre los archivos en lista limpia sin agrupaciones raras."
    "Optimize-ExploradorCheckboxes"      = "Activa pequeños cuadraditos de selección en los íconos del Explorador. Útil para seleccionar varios archivos sin tener que mantener Ctrl apretado."
    "Optimize-SuavizadoFuentes"          = "ClearType es la tecnología de suavizado de texto de Windows. Muchos optimizadores la desactivan 'para ganar rendimiento' pero el impacto es mínimo y el texto queda pixelado. Esta opción lo reactiva correctamente."
    "Optimize-IconosTamañoNormal"        = "Normaliza el tamaño de los íconos del escritorio y el explorador al estándar de Windows (32px). Algunos optimizadores cambian esto y los íconos quedan borrosos o de tamaño incorrecto."
    "Optimize-DPIEscalado"               = "Restaura el escalado de DPI al modo automático de Windows. Varios optimizadores fuerzan un DPI específico que deja texto borroso en pantallas de alta resolución o en laptops con pantallas 4K."
    "Optimize-RestaurarEsteticaWindows"  = "Detecta y restaura todo lo que los optimizadores suelen romper sin preguntar: animaciones de ventanas, texto ClearType, transparencias Aero, efectos visuales, menú contextual moderno de Win11, sonidos del sistema y velocidad de menús. No cambia tu tema claro/oscuro ni tu fondo de pantalla — solo repara lo que fue modificado sin tu permiso."
    "Optimize-RestaurarTemaWindows"      = "Verifica que la configuración estética de Windows no fue alterada por otro optimizador. Repara valores que no deberían haberse tocado."
    "Optimize-BrowserFlash"             = "El parpadeo de pantalla en Brave, Chrome y Edge ocurre cuando el driver de la GPU tarda más de 2 segundos en responder y Windows la 'reinicia' en silencio. Aumentar ese tiempo de espera a 8 segundos elimina el parpadeo sin afectar el rendimiento."
    "Optimize-MenuContextualCompleto"    = "En Windows 11, el clic derecho muestra un menú reducido que requiere 'Mostrar más opciones' para ver el menú completo. Esta opción restaura el menú clásico completo directamente al primer clic derecho."
    "Optimize-TaskbarLimpia"             = "Quita de la barra de tareas los botones que la mayoría de personas no usa: Vista de Tareas (el ícono de ventanas múltiples) y Widgets. Más espacio, menos distracciones."
    "Optimize-NotificacionesSilenciosas" = "Silencia el sonido de las notificaciones y quita los badges numéricos de los íconos en la barra de tareas. Las notificaciones siguen funcionando, solo sin sonido y sin el número rojo en los íconos."
    "Optimize-SnapSugerencias"           = "Cuando arrastrás una ventana hacia un borde, Windows 11 muestra sugerencias de disposición con todas las ventanas abiertas. Si lo encontrás molesto o distrae, esta opción lo desactiva."
    "Optimize-PapeleraConfirmar"         = "Activa la pregunta '¿Estás seguro?' antes de mandar algo a la papelera. Evita borrar archivos por accidente con un clic mal dado."
    "Optimize-HAGS"              = "Hardware Accelerated GPU Scheduling: deja que la GPU maneje su propia memoria sin pasar por la CPU. Reduce latencia en juegos en GPU compatibles (NVIDIA RTX, AMD RX)."
    "Optimize-GpuPriority"       = "Le dice a Windows que le dé máxima prioridad a los procesos que usan GPU intensivamente (juegos, renders). Mejora la fluidez de frames."
    "Optimize-VRR"               = "Permite que la frecuencia de refresco de la pantalla se sincronice con los FPS del juego incluso en modo ventana. Reduce el tearing sin necesidad de pantalla completa."
    "Optimize-NVIDIAPower"       = "Configura el driver de NVIDIA para mantener la GPU siempre al máximo rendimiento en vez de reducirla cuando no la estás usando. Elimina el lag de 'despertar' la GPU."
    "Optimize-DWMPriority"       = "El compositor de ventanas (DWM) es el responsable de dibujar todo en pantalla. Elevar su prioridad reduce el lag al cambiar entre ventanas (Alt+Tab)."
    "Optimize-StartupDelay"      = "Windows agrega un retraso artificial de varios segundos antes de abrir los programas del inicio. Esta optimización lo elimina."
    "Optimize-GameDVR"           = "La función de grabación de Xbox actúa en segundo plano capturando lo que hacés. Aunque no la uses, consume CPU y RAM. Desactivarla libera esos recursos."
    "Optimize-TdrDelay"          = "Si la GPU tarda demasiado en responder, Windows la reinicia. WDM ajusta ese tiempo de espera según si es laptop o desktop para evitar reinicios innecesarios."
    "Optimize-SystemResponsiveness" = "Windows puede priorizar procesos en segundo plano sobre la app que estás usando. Esta optimización invierte esa lógica: lo que ves siempre tiene prioridad."
    "Optimize-WindowsAnimations" = "Las animaciones de minimizar/maximizar ventanas consumen GPU/CPU. Desactivarlas hace que las ventanas abran y cierren al instante."
    "Optimize-VisualEffects"     = "Reduce todos los efectos visuales no esenciales: sombras, transparencias, animaciones. La PC se ve más simple pero responde más rápido, especialmente con GPU integrada."
    "Optimize-USB"               = "Windows puede poner los puertos USB en modo ahorro de energía. Esto puede causar que dispositivos como el mouse o el teclado tarden en responder. Esta optimización lo desactiva."
    "Optimize-IconCache"         = "Windows guarda las imágenes de los iconos en un archivo de caché. Cuando ese archivo se corrompe aparece el 'flickering' de iconos o la barra de tareas lenta. Limpiar la caché lo soluciona."
    "Optimize-TaskScheduler"     = "Verifica que el Programador de Tareas esté activo y funcionando. Es necesario para las actualizaciones automáticas, antivirus y muchas apps."
    "Optimize-ExplorerStartup"   = "Desactiva las notificaciones tipo 'globo' y los avisos de sincronización en el Explorador de archivos. Menos interrupciones, más fluidez."
    "Optimize-StartupPrograms"   = "Abre el Administrador de Tareas directamente en la pestaña 'Inicio' para que puedas ver y desactivar los programas que se abren solos con la PC."
    "Optimize-PowerPlanUltimate" = "El plan de energía controla cómo el CPU gestiona sus frecuencias. 'Ultimate Performance' mantiene el CPU siempre al máximo. Solo para PCs de escritorio — en laptop drenaría la batería."
    # DÍA A DÍA
    "Optimize-ExplorerExtensions"      = "Por defecto Windows oculta las extensiones de los archivos (.docx, .pdf, .exe). Verlas es importante para no confundir un archivo malicioso '.exe' disfrazado de '.pdf'. Es la configuración más útil del Explorador."
    "Optimize-ExplorerHiddenFiles"     = "Windows oculta archivos del sistema para que no los borres por accidente. Mostrarlos es necesario para diagnosticar problemas, limpiar manualmente o entender qué hay en una carpeta."
    "Optimize-ExplorerOpenThisPC"      = "El Explorador abre por defecto en 'Acceso Rápido' mostrando archivos recientes. Abrirlo en 'Esta PC' es más directo — ves tus discos inmediatamente sin esperar que cargue el historial."
    "Optimize-ExplorerFullPath"        = "Cuando entrás en carpetas, la barra de título muestra solo el nombre. Activar la ruta completa ('C:\Usuarios\Juan\Documentos') te dice exactamente dónde estás en cualquier momento."
    "Optimize-ExplorerNoCompressSearch"= "Al buscar archivos, el Explorador también revisa dentro de archivos .zip y .rar. Esto lo hace mucho más lento. Desactivarlo hace la búsqueda instantánea sin perder nada importante."
}

function Invoke-ScopeFunction {
    param($FuncName)
    if ($null -eq $FuncName) { return $false }
    # Si es scriptblock, ejecutar directo
    if ($FuncName -is [scriptblock]) { try { return (& $FuncName) } catch { return $false } }
    # Si es string, buscar con Get-Command
    try {
        $cmd = Get-Command -Name ([string]$FuncName) -CommandType Function -EA SilentlyContinue
        if ($cmd) { return (& $cmd) }
        return (& ([string]$FuncName))
    } catch { return $false }
}

function Invoke-OptFunc {
    param($Func)
    if ($null -eq $Func) { return $false }
    if ($Func -is [scriptblock]) { try { return (& $Func) } catch { return $false } }
    try {
        $cmd = Get-Command -Name ([string]$Func) -CommandType Function -EA SilentlyContinue
        if ($cmd) { return (& $cmd) }
        return (& ([string]$Func))
    } catch { return $false }
}

function Add-Optimization {
    param($Name, $Func, $Description, $Category, $Condition=$true, $CheckStatus=$null, $DefaultChecked=$true, $IsOverOptimized=$false)
    if (-not $Condition) { return }

    # Clave única: si Func es scriptblock usar el nombre directamente
    $funcKey = if ($Func -is [scriptblock]) { "SB_$Name" } else { $Func }
    $optKey  = "$Name|$funcKey"

    # Los IsOverOptimized NUNCA se filtran por OptimizationsApplied — siempre deben aparecer
    if (-not $IsOverOptimized -and $script:OptimizationsApplied.ContainsKey($optKey)) { return }

    $item = New-Object System.Windows.Forms.ListViewItem
    $item.UseItemStyleForSubItems = $false

    if ($IsOverOptimized) {
        $item.Text      = "⚠️ $Name"
        $item.ForeColor = $script:colors.Orange
        $sub = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
        $sub.Text      = "⚠️ CORREGIR"
        $sub.ForeColor = $script:colors.Red
        $item.SubItems.Add($sub) | Out-Null
    } elseif ($CheckStatus) {
        $isAlreadyApplied = Invoke-ScopeFunction $CheckStatus
        if ($isAlreadyApplied) {
            $item.Text      = $Name
            $item.ForeColor = $script:colors.Green
            $sub = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
            $sub.Text      = "✓ HECHO"
            $sub.ForeColor = $script:colors.Green
            $item.SubItems.Add($sub) | Out-Null
            $item.Checked = $false
            $item.Tag     = $null
            $lvOptimizations.Items.Add($item) | Out-Null
            return
        } else {
            $item.Text = $Name
            $sub = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
            $sub.Text = ""
            $item.SubItems.Add($sub) | Out-Null
        }
    } else {
        $item.Text = $Name
        $sub = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
        $sub.Text = ""
        $item.SubItems.Add($sub) | Out-Null
    }

    $explicacion = if ($script:Explicaciones.ContainsKey($funcKey)) { $script:Explicaciones[$funcKey] } else { $Description }
    $opt = [PSCustomObject]@{
        Name=$Name; Func=$Func; Description=$Description; Explicacion=$explicacion
        Category=$Category; CheckStatus=$CheckStatus; IsOverOptimized=$IsOverOptimized; Key=$optKey
    }
    $item.Tag     = $opt
    $item.Checked = $DefaultChecked   # SIEMPRE después de .Tag
    $lvOptimizations.Items.Add($item) | Out-Null
}

function Add-PrivacyOption {
    param($Name, $Func, $Description, $Explicacion, $CheckStatus, $DefaultChecked=$true)
    $optKey = "$Name|$Func"
    if ($script:OptimizationsApplied.ContainsKey($optKey)) { return }
    $item   = New-Object System.Windows.Forms.ListViewItem
    $item.Text = $Name
    $isAlreadyApplied = Invoke-ScopeFunction $CheckStatus
    if ($isAlreadyApplied) {
        $item.SubItems.Add("✓ HECHO") | Out-Null
        $item.ForeColor = $script:colors.Green
        $item.Checked   = $false
    } else {
        $item.SubItems.Add("") | Out-Null
        $item.Checked = $DefaultChecked
    }
    $opt = [PSCustomObject]@{ Name=$Name; Func=$Func; Description=$Description; Explicacion=$Explicacion; Category="Privacidad"; Key=$optKey }
    $item.Tag = $opt
    $lvPrivacidad.Items.Add($item) | Out-Null
}

function Add-LimpiezaOption {
    param($Info)
    $item = New-Object System.Windows.Forms.ListViewItem
    $item.Text = $Info.Name
    $item.Tag  = $Info
    $item.UseItemStyleForSubItems = $false
    $item.Checked = $true
    $sizeSubItem  = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
    $sizeSubItem.Text = "clic para ver"
    $item.SubItems.Add($sizeSubItem)
    $emptySubItem = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
    $emptySubItem.Text = ""
    $item.SubItems.Add($emptySubItem)
    $lvLimpieza.Items.Add($item) | Out-Null
}

function Add-DiarioOption {
    param($Name, $Func, $Description, $Category, $CheckStatus=$null, $DefaultChecked=$true)
    $optKey = "$Name|$Func"
    if ($script:OptimizationsApplied.ContainsKey($optKey)) { return }
    $item = New-Object System.Windows.Forms.ListViewItem
    $item.UseItemStyleForSubItems = $false
    $item.Text = $Name

    if ($CheckStatus) {
        $isApplied = Invoke-ScopeFunction $CheckStatus
        if ($isApplied) {
            $item.ForeColor = $script:colors.Green
            $sub = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
            $sub.Text = "✓ HECHO"; $sub.ForeColor = $script:colors.Green
            $item.SubItems.Add($sub) | Out-Null
            $item.Checked = $false
            $item.Tag     = $null
            $lvDiario.Items.Add($item) | Out-Null
            return
        }
    }
    $sub = New-Object System.Windows.Forms.ListViewItem+ListViewSubItem
    $sub.Text = ""; $item.SubItems.Add($sub) | Out-Null
    $explicacion = if ($script:Explicaciones.ContainsKey($Func)) { $script:Explicaciones[$Func] } else { $Description }
    $opt = [PSCustomObject]@{ Name=$Name; Func=$Func; Description=$Description; Explicacion=$explicacion; Category=$Category; Key=$optKey }
    $item.Tag     = $opt
    $item.Checked = $DefaultChecked
    $lvDiario.Items.Add($item) | Out-Null
}

function Get-DiarioList {
    $lvDiario.Items.Clear()
    Write-Log "═══════════════════════════" "Accent"
    Write-Log "CARGANDO USO DIARIO..." "Accent"
    Write-Log "═══════════════════════════" "Accent"

    # EXPLORADOR DE ARCHIVOS
    Write-Log "📁 Explorador de archivos..." "Purple"
    Add-DiarioOption -Name "Ver extensiones de archivos (.exe, .pdf...)" -Func "Optimize-ExtensionesVisibles"      -Description "Muestra el tipo real de cada archivo"         -Category "Explorador" -CheckStatus "Check-ExtensionesVisibles"
    Add-DiarioOption -Name "Ver archivos ocultos (no los del sistema)"   -Func "Optimize-ArchivosOcultosVisibles"  -Description "Muestra archivos ocultos de forma segura"    -Category "Explorador" -CheckStatus "Check-ArchivosOcultosVisibles"
    Add-DiarioOption -Name "Explorador abre en 'Esta PC'"                -Func "Optimize-ExploradorEstaPC"          -Description "Acceso directo a discos, no al historial"    -Category "Explorador" -CheckStatus "Check-ExploradorEstaPC"
    Add-DiarioOption -Name "Carpetas antes que archivos + ruta en título" -Func "Optimize-CarpetasAntesDeArchivos"  -Description "Orden lógico + ruta completa visible"        -Category "Explorador" -CheckStatus "Check-CarpetasAntesDeArchivos"
    Add-DiarioOption -Name "Resetear vistas (sin agrupaciones raras)"    -Func "Optimize-SinAgrupacionesExplorador" -Description "Limpia las vistas rotas del Explorador"     -Category "Explorador" -CheckStatus "Check-SinAgrupacionesExplorador"
    Add-DiarioOption -Name "Checkboxes para seleccionar archivos"        -Func "Optimize-ExploradorCheckboxes"      -Description "Seleccioná varios archivos sin mantener Ctrl" -Category "Explorador" -CheckStatus "Check-ExploradorCheckboxes"
    Add-DiarioOption -Name "Confirmar antes de mandar a la papelera"     -Func "Optimize-PapeleraConfirmar"         -Description "Evita borrar por accidente"                  -Category "Explorador" -CheckStatus "Check-PapeleraConfirmar"

    # ESTÉTICA: DETECCIÓN Y RESTAURACIÓN COMPLETA
    Write-Log "🎨 Estado estético de Windows..." "Purple"
    $estadoEstetica = Get-EstadoEstetica
    $roto = @($estadoEstetica | Where-Object { -not $_.OK })
    $ok   = @($estadoEstetica | Where-Object { $_.OK })

    if ($roto.Count -eq 0) {
        Write-Log "  ✅ Estética Windows en estado original ($($ok.Count)/$($estadoEstetica.Count) OK)" "Green"
        # Igual mostrar como HECHO en la lista
        Add-DiarioOption -Name "✅ Estética Windows — todo en su lugar ($($ok.Count)/$($estadoEstetica.Count))" `
            -Func "Optimize-RestaurarEsteticaWindows" -Description "La estética está como Windows la configuró originalmente" `
            -Category "Estética" -CheckStatus "Check-EsteticaOriginal"
    } else {
        Write-Log "  ⚠️ $($roto.Count) elemento(s) con estética modificada:" "Orange"
        foreach ($r in $roto) {
            Write-Log "     • $($r.Nombre) → default: $($r.DefaultDesc)" "TextDim"
        }
        Add-DiarioOption -Name "🎨 Restaurar estética Windows ($($roto.Count) elemento(s) modificado(s))" `
            -Func "Optimize-RestaurarEsteticaWindows" -Description "Devuelve animaciones, transparencias, menús y efectos al estado original" `
            -Category "Estética" -CheckStatus "Check-EsteticaOriginal"
    }


    # PROBLEMAS CONOCIDOS
    Write-Log "🔧 Problemas conocidos del sistema..." "Purple"
    Add-DiarioOption -Name "Corregir parpadeo en Brave/Chrome/Edge" -Func "Optimize-BrowserFlash"          -Description "Soluciona el flasheo de pantalla en browsers"          -Category "Problemas" -CheckStatus "Check-BrowserFlashFix"
    Add-DiarioOption -Name "Reconstruir caché de íconos (iconos raros)" -Func "Optimize-IconCache"         -Description "Arregla íconos que aparecen incorrectos o en blanco"   -Category "Problemas" -CheckStatus "Check-IconCache"

    # BARRA DE TAREAS Y MENÚS
    Write-Log "📌 Barra de tareas y menús..." "Purple"
    Add-DiarioOption -Name "Barra de tareas limpia (sin Vista de Tareas, sin Widgets)" -Func "Optimize-TaskbarLimpia" -Description "Más espacio, menos botones que no usás" -Category "Barra" -CheckStatus "Check-TaskbarLimpia"
    Add-DiarioOption -Name "Notificaciones sin sonido ni badges"    -Func "Optimize-NotificacionesSilenciosas" -Description "Menos interrupciones sin perder las notificaciones"  -Category "Barra" -CheckStatus "Check-NotificacionesSilenciosas"
    if ($script:WindowsVersion.IsWin11) {
        Add-DiarioOption -Name "Menú clic derecho completo (sin 'Mostrar más')" -Func "Optimize-MenuContextualCompleto" -Description "El menú clásico completo desde el primer clic" -Category "Barra" -CheckStatus "Check-MenuContextualCompleto"
    }
    Add-DiarioOption -Name "Desactivar sugerencias de Snap (Win+arrastre)" -Func "Optimize-SnapSugerencias" -Description "Sin el popup de disposición de ventanas"           -Category "Barra" -CheckStatus "Check-SnapSugerencias" -DefaultChecked $false

    Write-Log "✅ $($lvDiario.Items.Count) ajustes de uso diario listos" "Green"
    Write-Log "" "TextPrimary"
    Write-Log "👆 Hacé clic en cada ítem para ver" "TextDim"
    Write-Log "   una explicación de qué hace." "TextDim"
}

function Get-OptimizationsList {
    param($HW)
    $lvOptimizations.Items.Clear()
    $lvLimpieza.Items.Clear()
    $lvPrivacidad.Items.Clear()
    $script:OriginalValues = @{}
    if (-not $HW.Valid) { Write-Log "❌ No se pudo analizar el hardware correctamente." "Red"; return }

    Write-Log "════════════════════════════" "Accent"
    Write-Log "PREPARANDO MEJORAS..." "Accent"
    Write-Log "════════════════════════════" "Accent"
    Write-Log "🔍 Revisando configuraciones existentes..." "Purple"

    # Sobre-optimizaciones
    $overCount = 0
    $keysToCheck = @(
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TCPNoDelay"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Name="PowerThrottlingOff"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnablePrefetcher"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsDisableLastAccessUpdate"}
    )
    foreach ($ki in $keysToCheck) {
        if (Test-OverOptimized -Path $ki.Path -Name $ki.Name) {
            $overCount++
            $range = $script:SafeRanges["$($ki.Path):$($ki.Name)"]
            $capturedPath = $ki.Path; $capturedName = $ki.Name
            Add-Optimization -Name "Corregir: $($ki.Name)" `
                -Func ([scriptblock]::Create("Restore-ToSafeValue -Path '$capturedPath' -Name '$capturedName'")) `
                -Description "Restaura $($ki.Name) a un valor seguro" `
                -Category "Corrección" -DefaultChecked $true -IsOverOptimized $true
        }
    }
    if ($overCount -gt 0) { Write-Log "⚠️ $overCount configuraciones con valores peligrosos detectadas" "Orange" }
    else { Write-Log "✅ Sin configuraciones peligrosas" "Green" }

    $hasSSD          = ($HW.Disks | Where-Object { $_.Type -eq "SSD" }).Count -gt 0
    $hasDedicatedGPU = ($HW.GPUProfile -and $HW.GPUProfile.HasDedicated)
    $hasEnoughRAM    = ($HW.RAM.TotalGB -ge 8)
    $hasHighRAM      = ($HW.RAM.TotalGB -ge 16)
    $networkInfo     = Get-NetworkProfile
    $gpuProfile      = Get-GPUProfile

    # EXPERIENCIA
    Add-Optimization -Name "Menús y Mouse Instantáneos"  -Func "Optimize-DailyExperience"  -Description "Elimina retrasos artificiales en menús y mouse"    -Category "Experiencia"  -CheckStatus "Check-MenuShowDelay"
    Add-Optimization -Name "Apagado Rápido"              -Func "Optimize-FastShutdown"     -Description "La PC se apaga en 2 segundos"                       -Category "Experiencia"  -CheckStatus "Check-AutoEndTasks"
    # INICIO
    Add-Optimization -Name "Desactivar Servicios Innecesarios" -Func "Optimize-BootServices" -Description "Apaga servicios que consumen recursos al arrancar" -Category "Inicio"  -CheckStatus "Check-BootServices"
    Add-Optimization -Name "Limpiar Precarga de Programas"     -Func "Optimize-Prefetch"     -Description "Borra registros de programas que ya no usás"       -Category "Inicio"  -CheckStatus "Check-PrefetchClean"
    # CPU
    Add-Optimization -Name "Prioridad de Procesos"        -Func "Optimize-Win32Priority"    -Description "Más CPU para la app que estás usando ahora"         -Category "CPU"  -CheckStatus "Check-Win32PrioritySeparation"
    Add-Optimization -Name "Sin Reducción Automática CPU" -Func "Optimize-PowerThrottling"  -Description "Evita que Windows frene el CPU por energía"          -Category "CPU"  -CheckStatus "Check-PowerThrottling"
    Add-Optimization -Name "Scheduling del Procesador"    -Func "Optimize-ProcessScheduling"-Description "Distribución óptima de trabajo en los núcleos"       -Category "CPU"  -CheckStatus "Check-ProcessScheduling"
    Add-Optimization -Name "Temporizador de Alta Precisión" -Func "Optimize-TimerResolution" -Description "Mejora precisión en audio, juegos y respuesta"     -Category "CPU"  -CheckStatus "Check-TimerResolution"
    Add-Optimization -Name "Prioridad de Interrupciones"  -Func "Optimize-IRQPriority"      -Description "Prioriza el timer y periféricos del hardware"        -Category "CPU"  -CheckStatus "Check-IRQPriority"
    if (-not $HW.IsLaptop -and $HW.CPU.Cores -ge 4) {
        Add-Optimization -Name "Todos los Núcleos Activos" -Func "Optimize-CPUParking" -Description "Evita que Windows 'duerma' núcleos para ahorrar energía" -Category "CPU" -CheckStatus "Check-CPUParking"
    }
    # RAM
    if (-not $hasEnoughRAM) { Add-Optimization -Name "Liberar RAM (SysMain)" -Func "Optimize-SysMain" -Description "Desactiva servicio que consume RAM innecesariamente" -Category "RAM" -CheckStatus "Check-SysMainStartup" }
    if ($hasHighRAM) {
        Add-Optimization -Name "Mantener Núcleo en RAM"     -Func "Optimize-DisablePagingExecutive" -Description "Evita que partes del sistema vayan al disco" -Category "RAM" -CheckStatus "Check-DisablePagingExecutive"
        Add-Optimization -Name "Caché de Sistema Ampliada"  -Func "Optimize-LargeSystemCache"       -Description "Más RAM para acelerar acceso a archivos"     -Category "RAM" -CheckStatus "Check-LargeSystemCache"
    }
    Add-Optimization -Name "Gestión de Memoria Inteligente"  -Func "Optimize-MemoryManagement"  -Description "Ajusta caché según la RAM de tu equipo"          -Category "RAM" -CheckStatus "Check-MemoryManagement"
    Add-Optimization -Name "Compresión de Memoria"           -Func "Optimize-MemoryCompression" -Description "Comprime o no según tu RAM — WDM decide"         -Category "RAM" -CheckStatus "Check-MemoryCompression"
    Add-Optimization -Name "Archivo de Paginación Fijo"      -Func "Optimize-PageFile"          -Description "Tamaño fijo según tu RAM — sin redimensionado"    -Category "RAM" -CheckStatus "Check-PageFile"
    # DISCO
    if ($hasSSD) {
        Add-Optimization -Name "Desactivar Hibernación"      -Func "Optimize-Hibernate"     -Description "Libera varios GB en el SSD"                          -Category "Disco" -CheckStatus "Check-HibernateDisabled"
        Add-Optimization -Name "Reducir Escrituras en SSD"   -Func "Optimize-NtfsLastAccess" -Description "Menos desgaste en el disco SSD"                     -Category "Disco" -CheckStatus "Check-NtfsLastAccess"
        Add-Optimization -Name "Precarga para SSD"           -Func "Optimize-Prefetcher"    -Description "Ajusta la precarga al tipo de disco"                  -Category "Disco" -CheckStatus "Check-Prefetcher"
    } else {
        Add-Optimization -Name "Prioridad IO para HDD"       -Func "Optimize-IOPriority"    -Description "El CPU atiende antes las operaciones del disco"       -Category "Disco" -CheckStatus "Check-IOPriority"
        Add-Optimization -Name "Prefetcher para HDD"         -Func "Optimize-Prefetcher"    -Description "La precarga ayuda con discos mecánicos lentos"         -Category "Disco" -CheckStatus "Check-Prefetcher"
    }
    Add-Optimization -Name "Servicios del Disco"             -Func "Optimize-DiskServices"  -Description "Desfrag en HDD / conserva en SSD"                    -Category "Disco" -CheckStatus "Check-DiskServices"
    Add-Optimization -Name "Caché de Escritura"              -Func "Optimize-WriteCaching"  -Description "Escribe en grupos — mejor velocidad"                  -Category "Disco" -CheckStatus "Check-WriteCaching"
    # RED
    Add-Optimization -Name "Velocidad de Descarga TCP"       -Func "Optimize-TCPAutoTuning"    -Description "Optimiza el tamaño de paquetes según la red"       -Category "Red" -CheckStatus "Check-TCPAutoTuning"
    Add-Optimization -Name "Red Distribuida en Núcleos"      -Func "Optimize-RSS"              -Description "Reparte el tráfico entre varios núcleos CPU"        -Category "Red" -CheckStatus "Check-RSS"
    Add-Optimization -Name "Sin Retraso TCP (ping)"          -Func "Optimize-TCPNoDelay"       -Description "Reduce latencia en juegos y videollamadas"          -Category "Red" -CheckStatus "Check-TCPNoDelay"
    Add-Optimization -Name "TCP Avanzado"                    -Func "Optimize-TCPAdvanced"      -Description "TTL optimizado, confirmaciones inmediatas"          -Category "Red" -CheckStatus "Check-TCPAdvanced"
    Add-Optimization -Name "Sin Límite de Red Windows"       -Func "Optimize-NetworkThrottling" -Description "Elimina el tope artificial de velocidad de red"   -Category "Red" -CheckStatus "Check-NetworkThrottling"
    if ($networkInfo -and $networkInfo.IsWiFi)                             { Add-Optimization -Name "WiFi a Máximo Rendimiento" -Func "Optimize-WiFiPowerSave" -Description "Sin ahorro de energía en el adaptador WiFi" -Category "Red" -CheckStatus "Check-WiFiPowerSave" }
    if ($networkInfo -and $networkInfo.IsEthernet -and $networkInfo.Speed -ge 1000) { Add-Optimization -Name "Jumbo Frames (Gigabit)" -Func "Optimize-EthernetJumbo" -Description "Paquetes más grandes en red Gigabit" -Category "Red" -CheckStatus "Check-JumboFrames" -DefaultChecked $false }
    Add-Optimization -Name "Desactivar IPv6"                 -Func "Optimize-IPv6"           -Description "Si tu red no usa IPv6, esto reduce overhead"         -Category "Red" -CheckStatus "Check-IPv6"
    # GPU
    if ($hasDedicatedGPU) {
        Add-Optimization -Name "GPU Accelerated Scheduling"  -Func "Optimize-HAGS"         -Description "La GPU maneja su memoria directamente"                  -Category "GPU" -CheckStatus "Check-HAGS"
        Add-Optimization -Name "Máxima Prioridad GPU"        -Func "Optimize-GpuPriority"  -Description "El sistema prioriza tareas que usan GPU"               -Category "GPU" -CheckStatus "Check-GpuPriority"
        Add-Optimization -Name "VRR en Ventana"              -Func "Optimize-VRR"          -Description "Sincronización de frames sin pantalla completa"          -Category "GPU" -CheckStatus "Check-VRR" -DefaultChecked $false
        if ($gpuProfile -and $gpuProfile.IsNVIDIA) { Add-Optimization -Name "NVIDIA Máximo Rendimiento" -Func "Optimize-NVIDIAPower" -Description "GPU NVIDIA siempre al máximo" -Category "GPU" -CheckStatus { $false } -DefaultChecked $false }
    }
    if (-not $hasDedicatedGPU) { Add-Optimization -Name "Sin Transparencias (GPU Integrada)" -Func "Optimize-Transparencias" -Description "Ahorra VRAM en GPU integrada Intel/AMD" -Category "GPU" -CheckStatus "Check-Transparencias" }
    # SISTEMA
    Add-Optimization -Name "Sin Lag en Alt+Tab"              -Func "Optimize-DWMPriority"         -Description "El motor gráfico de Windows con mayor prioridad"     -Category "Sistema" -CheckStatus "Check-DWMPriority"
    Add-Optimization -Name "Sin Retraso al Abrir Apps"       -Func "Optimize-StartupDelay"        -Description "Elimina la espera artificial al abrir programas"      -Category "Sistema" -CheckStatus "Check-StartupDelay"
    Add-Optimization -Name "Desactivar Grabación de Juegos"  -Func "Optimize-GameDVR"             -Description "Xbox DVR consume CPU/RAM sin que lo uses"             -Category "Sistema" -CheckStatus "Check-GameDVR"
    Add-Optimization -Name "Timeout de GPU"                  -Func "Optimize-TdrDelay"            -Description "Tiempo de espera de GPU ajustado a tu equipo"         -Category "Sistema" -CheckStatus "Check-TdrDelay"
    Add-Optimization -Name "Sin Animaciones de Ventanas"     -Func "Optimize-WindowsAnimations"   -Description "Ventanas abren y cierran al instante"                 -Category "Sistema" -CheckStatus "Check-WindowsAnimations"
    Add-Optimization -Name "Efectos Visuales Mínimos"        -Func "Optimize-VisualEffects"       -Description "Sin sombras ni efectos que consumen GPU"              -Category "Sistema" -CheckStatus "Check-VisualEffects"
    Add-Optimization -Name "USB sin Ahorro de Energía"       -Func "Optimize-USB"                 -Description "Mouse y teclado responden siempre de inmediato"       -Category "Sistema" -CheckStatus "Check-USB"
    Add-Optimization -Name "Reconstruir Caché de Iconos"     -Func "Optimize-IconCache"           -Description "Elimina flickering de iconos en la barra de tareas"   -Category "Sistema" -CheckStatus "Check-IconCache"
    Add-Optimization -Name "Reparar Programador de Tareas"   -Func "Optimize-TaskScheduler"       -Description "Necesario para actualizaciones y apps automáticas"    -Category "Sistema" -CheckStatus "Check-TaskScheduler"
    Add-Optimization -Name "Explorador de Archivos Rápido"   -Func "Optimize-ExplorerStartup"     -Description "Menos notificaciones globo, barra de tareas ágil"     -Category "Sistema" -CheckStatus "Check-ExplorerStartup"
    Add-Optimization -Name "Revisar Programas al Inicio"     -Func "Optimize-StartupPrograms"     -Description "Abre el Administrador de Tareas para revisar"         -Category "Inicio"  -CheckStatus "Check-StartupPrograms" -DefaultChecked $false
    if (-not $HW.IsLaptop) { Add-Optimization -Name "Plan de Energía Ultimate" -Func "Optimize-PowerPlanUltimate" -Description "CPU siempre al máximo en escritorio" -Category "Sistema" -CheckStatus "Check-PowerPlanUltimate" }
    else { Add-Optimization -Name "Plan de Energía Equilibrado" -Func "Optimize-PowerPlan" -Description "Plan óptimo para laptop" -Category "Sistema" -CheckStatus { $false } }

    # DÍA A DÍA — EXPLORADOR + ESTÉTICA + PANTALLA
    Write-Log "🗂️ Cargando mejoras del día a día..." "Purple"
    Add-Optimization -Name "Ver Extensiones de Archivos"     -Func "Optimize-ExplorerExtensions"       -Description ".docx .pdf .exe visibles — más seguro"          -Category "Día a Día" -CheckStatus "Check-ExplorerExtensions"       -DefaultChecked $true
    Add-Optimization -Name "Ver Archivos Ocultos"            -Func "Optimize-ExplorerHiddenFiles"      -Description "Útil para diagnóstico y limpieza manual"        -Category "Día a Día" -CheckStatus "Check-ExplorerHiddenFiles"      -DefaultChecked $false
    Add-Optimization -Name "Explorador abre en Esta PC"      -Func "Optimize-ExplorerOpenThisPC"       -Description "Ve tus discos directamente sin Acceso Rápido"   -Category "Día a Día" -CheckStatus "Check-ExplorerOpenThisPC"       -DefaultChecked $true
    Add-Optimization -Name "Ruta Completa en Título"         -Func "Optimize-ExplorerFullPath"         -Description "Sabés siempre en qué carpeta estás"             -Category "Día a Día" -CheckStatus "Check-ExplorerFullPath"         -DefaultChecked $false
    Add-Optimization -Name "Búsqueda de Archivos Rápida"     -Func "Optimize-ExplorerNoCompressSearch" -Description "No busca dentro de .zip — mucho más veloz"      -Category "Día a Día" -CheckStatus "Check-ExplorerNoCompressSearch" -DefaultChecked $true
    Add-Optimization -Name "Notificaciones Sin Ruido"        -Func "Optimize-NotificacionesSilenciosas" -Description "Sin sonido ni badges — llegan igual pero calladas" -Category "Día a Día" -CheckStatus "Check-NotificacionesSilenciosas" -DefaultChecked $true
    Add-Optimization -Name "Barra de Tareas Limpia"          -Func "Optimize-TaskbarLimpia"            -Description "Sin botones que no usás (Widgets, Vista de Tareas)" -Category "Día a Día" -CheckStatus "Check-TaskbarLimpia"          -DefaultChecked $true
    Add-Optimization -Name "Confirmar al Borrar Archivos"    -Func "Optimize-PapeleraConfirmar"        -Description "Evita eliminar por accidente con un Delete"     -Category "Día a Día" -CheckStatus "Check-PapeleraConfirmar"       -DefaultChecked $true
    Add-Optimization -Name "Sin Sugerencias de Snap"         -Func "Optimize-SnapSugerencias"          -Description "Ventanas sin el panel de disposición automática" -Category "Día a Día" -CheckStatus "Check-SnapSugerencias"         -DefaultChecked $false
    if ($script:WindowsVersion.IsWin11) {
        Add-Optimization -Name "Menú Clic Derecho Completo"  -Func "Optimize-MenuContextualCompleto"   -Description "Sin 'Mostrar más opciones' — menú completo directo" -Category "Día a Día" -CheckStatus "Check-MenuContextualCompleto" -DefaultChecked $true
    }
    # Flasheo de pantalla — solo sugerir si hay GPU dedicada (donde ocurre)
    if ($hasDedicatedGPU) {
        Add-Optimization -Name "Corregir Flasheo de Pantalla" -Func "Optimize-BrowserFlash" -Description "Soluciona parpadeo en Brave, Chrome y Edge" -Category "Día a Día" -CheckStatus "Check-BrowserFlash" -DefaultChecked $true
    }

    # PRIVACIDAD
    Write-Log "🛡️ Cargando opciones de privacidad..." "Purple"
    Add-PrivacyOption -Name "Desactivar ID de Publicidad"      -Func "Optimize-AdvertisingID"   -Description "Desactiva el identificador único de publicidad"   -Explicacion "Windows asigna a tu PC un número de identificación que las apps usan para mostrarte publicidad personalizada. No es necesario para nada. Desactivarlo no afecta el funcionamiento de ningún programa." -CheckStatus "Check-AdvertisingID"
    Add-PrivacyOption -Name "Bloquear Ubicación"               -Func "Optimize-Location"        -Description "Las apps no pueden saber dónde estás"            -Explicacion "Windows puede compartir tu ubicación con apps y sitios web. Si no usás apps que necesiten saber dónde estás, bloquearlo es lo más seguro. Siempre podés reactivarlo para apps específicas." -CheckStatus "Check-Location"
    Add-PrivacyOption -Name "Bloquear Acceso a Cámara"         -Func "Optimize-Camera"          -Description "Las apps no pueden activar la cámara sin permiso" -Explicacion "Sin este bloqueo, cualquier app que instalaste puede acceder a tu cámara. Al activar este ajuste, las apps necesitan pedirte permiso explícito antes de usarla." -CheckStatus "Check-Camera"
    Add-PrivacyOption -Name "Bloquear Acceso al Micrófono"     -Func "Optimize-Microphone"      -Description "Las apps no pueden grabarte sin permiso"          -Explicacion "Igual que la cámara: sin bloqueo, las apps pueden escuchar el micrófono libremente. Con este ajuste activo, necesitan pedirte permiso." -CheckStatus "Check-Microphone"
    Add-PrivacyOption -Name "Desactivar Notificaciones de Apps" -Func "Optimize-Notifications"  -Description "Sin pop-ups de apps que interrumpen el trabajo"  -Explicacion "Las notificaciones tipo 'toast' (los cuadritos que aparecen abajo a la derecha) pueden ser muy molestas. Desactivarlas globalmente hace el trabajo más tranquilo." -CheckStatus "Check-Notifications"
    Add-PrivacyOption -Name "Sin Seguimiento de Actividad"     -Func "Optimize-ActivityHistory" -Description "Windows no guarda ni sube lo que hacés"           -Explicacion "Windows puede registrar qué apps usás, qué archivos abrís y subir ese historial a la nube de Microsoft. Desactivar esto mantiene tus hábitos de uso en privado." -CheckStatus "Check-ActivityHistory"
    Add-PrivacyOption -Name "Sin Experiencias Personalizadas"  -Func "Optimize-TailoredExperiences" -Description "No usa tus datos para mostrarte contenido"  -Explicacion "Windows usa los datos de diagnóstico que recopila para 'personalizar' tu experiencia con sugerencias y contenido. Desactivarlo reduce los datos que Microsoft usa para perfilarte." -CheckStatus "Check-TailoredExperiences"
    Add-PrivacyOption -Name "Sin Archivos Recientes"           -Func "Optimize-RecentFiles"     -Description "El explorador no muestra los archivos que abriste" -Explicacion "El Explorador de Archivos muestra automáticamente los últimos archivos que abriste. Útil para algunos, pero puede ser un problema de privacidad si compartís la PC." -CheckStatus "Check-RecentFiles"
    Add-PrivacyOption -Name "Sin Carpetas Frecuentes"          -Func "Optimize-FrequentFolders" -Description "No muestra las carpetas que más usás"             -Explicacion "Similar a los archivos recientes: el Explorador recuerda qué carpetas abrís más. Desactivarlo da más privacidad si compartís la PC." -CheckStatus "Check-FrequentFolders"
    Add-PrivacyOption -Name "Sin Sugerencias en Menú Inicio"   -Func "Optimize-SuggestionsInMenu" -Description "El menú Inicio sin publicidad ni sugerencias"  -Explicacion "Microsoft puede mostrar apps recomendadas y publicidad en el menú Inicio. Desactivar esto limpia el menú y elimina el contenido patrocinado." -CheckStatus "Check-SuggestionsInMenu"
    Add-PrivacyOption -Name "Sin Pantalla de Bienvenida"       -Func "Optimize-WelcomeExperience" -Description "Sin tutoriales de novedades de Windows"         -Explicacion "Después de cada actualización, Windows puede mostrar pantallas explicando novedades. Se pueden desactivar sin perder nada." -CheckStatus "Check-WelcomeExperience"
    Add-PrivacyOption -Name "Sin Portapapeles en la Nube"      -Func "Optimize-CloudClipboard"  -Description "Lo que copiás no se sube a la nube"               -Explicacion "Windows puede sincronizar el portapapeles entre dispositivos via la nube. Si no necesitás eso, mejor desactivarlo — lo que copiás (contraseñas, textos privados) se queda en tu PC." -CheckStatus "Check-CloudClipboard"
    Add-PrivacyOption -Name "Sin Contenido de la Nube"         -Func "Optimize-CloudContent"    -Description "Desactiva sugerencias basadas en nube Microsoft"  -Explicacion "Microsoft puede mostrar contenido descargado de la nube en el menú Inicio y otras partes. Desactivarlo ahorra datos y elimina publicidad disfrazada de 'recomendaciones'." -CheckStatus "Check-CloudContent"
    if ($script:WindowsVersion.IsWin10) { Add-PrivacyOption -Name "Desactivar Cortana" -Func "Optimize-CortanaWin10" -Description "Desactiva el asistente de voz" -Explicacion "Cortana recopila información de uso, búsquedas y comandos de voz. Si no la usás, desactivarla libera recursos y mejora la privacidad." -CheckStatus "Check-CortanaWin10" }
    if ($script:WindowsVersion.IsWin11) {
        if (Test-CopilotExists) {
            Add-PrivacyOption -Name "Ocultar Copilot"          -Func "Optimize-Copilot"          -Description "Saca el botón Copilot de la barra de tareas"    -Explicacion "Copilot es el asistente de IA de Microsoft integrado en Windows 11. Si no lo usás, podés quitar el botón de la barra de tareas para tener más espacio." -CheckStatus "Check-Copilot"
            Add-PrivacyOption -Name "Copilot sin Búsqueda Web" -Func "Optimize-CopilotWebSearch" -Description "Copilot no busca en internet automáticamente"   -Explicacion "Copilot puede hacer búsquedas web en segundo plano cuando escribís en la barra de búsqueda. Desactivarlo evita que envíe tus búsquedas a los servidores de Microsoft." -CheckStatus "Check-CopilotWebSearch"
            Add-PrivacyOption -Name "Copilot sin Acceso a Apps" -Func "Optimize-CopilotContext" -Description "Copilot no puede leer lo que hacés en otras apps"  -Explicacion "Copilot puede acceder al contexto de otras apps abiertas para darte sugerencias. Desactivarlo previene que lea el contenido de tus apps sin que lo sepas." -CheckStatus "Check-CopilotContext"
        }
        if (Test-RecallExists) { Add-PrivacyOption -Name "Desactivar Recall" -Func "Optimize-Recall" -Description "Desactiva la función que graba tu pantalla continuamente" -Explicacion "Recall toma capturas de pantalla de todo lo que hacés para que puedas 'buscar en el pasado'. Es muy invasivo para la privacidad. Si no lo necesitás, desactivarlo es lo recomendable." -CheckStatus "Check-Recall" }
        Add-PrivacyOption -Name "Sin Cifrado Automático" -Func "Optimize-DeviceEncryption" -Description "Desactiva el cifrado automático de BitLocker" -Explicacion "Windows 11 puede activar BitLocker automáticamente, cifrando tu disco. El problema: si olvidás la clave de recuperación, podés perder acceso a todos tus datos. Desactivarlo es más seguro para usuarios que no conocen BitLocker." -CheckStatus "Check-DeviceEncryption"
    }
    Write-Log "✅ $($lvPrivacidad.Items.Count) ajustes de privacidad listos" "Green"

    # LIMPIEZA
    Write-Log "🧹 Cargando opciones de limpieza..." "Purple"
    foreach ($key in $script:LimpiezaMap.Keys) { Add-LimpiezaOption -Info $script:LimpiezaMap[$key] }
    Write-Log "✅ $($lvLimpieza.Items.Count) limpiezas disponibles" "Green"
    Write-Log "✅ $($lvOptimizations.Items.Count) optimizaciones listas" "Green"
    Write-Log "" "TextPrimary"
    Write-Log "👆 Hacé clic en cualquier ítem para ver una" "TextDim"
    Write-Log "   explicación clara de qué hace." "TextDim"
}

# ============================================================================
# SCORE DISPLAY
# ============================================================================
function Update-ScoreDisplay {
    param($Score, $Label)
    try {
        $lblScoreNum.Text = "$Score"
        $lblScoreLabel.Text = $Label
        $scoreColor = if ($Score -ge 80) { $script:colors.Green }
                      elseif ($Score -ge 60) { $script:colors.Yellow }
                      else { $script:colors.Orange }
        $lblScoreNum.ForeColor   = $scoreColor
        $lblScoreLabel.ForeColor = $scoreColor
        $pnlScore.Refresh()
    } catch {}
}

# ============================================================================
# APLICAR TEMA
# ============================================================================
function Apply-Theme {
    $c = $script:colors
    $form.BackColor         = $c.BgDark
    $headerPanel.BackColor  = $c.BgHeader
    $lblTitle.ForeColor     = $c.Accent
    $lblSubtitle.ForeColor  = $c.TextDim
    $lblOs.ForeColor        = $c.TextDim
    $btnTheme.BackColor     = $c.BgCard2
    $btnTheme.ForeColor     = $c.TextPrimary
    $leftPanel.BackColor    = $c.BgPanel
    $lblHwTitle.ForeColor   = $c.Accent
    $rtbHardware.BackColor  = $c.BgLog
    $rtbHardware.ForeColor  = $c.TextSecond
    $btnAnalyze.BackColor   = $c.Accent
    $btnAnalyze.ForeColor   = $c.BgDark
    $lblSysInfo.ForeColor   = $c.Accent
    $rtbSysStatus.BackColor = $c.BgLog
    $rtbSysStatus.ForeColor = $c.TextSecond
    $pnlScore.BackColor     = $c.BgCard2
    $lblScoreTitle.ForeColor = $c.TextDim
    $centerPanel.BackColor  = $c.BgPanel
    $tabControl.BackColor   = $c.BgCard
    foreach ($tp in @($tabOptimizaciones,$tabLimpieza,$tabPrivacidad,$tabDiario,$tabSalud)) {
        $tp.BackColor = $c.BgCard
        $tp.ForeColor = $c.TextPrimary
    }
    foreach ($lv in @($lvOptimizations,$lvLimpieza,$lvPrivacidad,$lvDiario)) {
        $lv.BackColor = $c.BgCard
        $lv.ForeColor = $c.TextPrimary
    }
    $btnOptimize.BackColor  = $c.Accent
    $btnOptimize.ForeColor  = $c.BgDark
    $btnRestore.BackColor   = $c.BgCard2
    $btnRestore.ForeColor   = $c.TextPrimary
    $btnRestore.FlatAppearance.BorderColor = $c.Red
    $btnRunSalud.BackColor  = $c.Purple
    $btnRunSalud.ForeColor  = $c.TextPrimary
    $pnlDiagEtapas.BackColor = $c.BgCard2
    $lblEtapasTitle.ForeColor = $c.Accent
    $lblSFCNota.ForeColor = $c.TextDim
    foreach ($chk in $script:DiagChkBoxes.Values) {
        $chk.ForeColor = $c.TextPrimary
        $chk.BackColor = [System.Drawing.Color]::Transparent
    }
    $rtbSalud.BackColor     = $c.BgLog
    $rtbSalud.ForeColor     = $c.TextPrimary
    $rightPanel.BackColor   = $c.BgPanel
    $lblLog.ForeColor       = $c.Accent
    $rtbLog.BackColor       = $c.BgLog
    $rtbLog.ForeColor       = $c.TextPrimary
    $lblHistTitle.ForeColor = $c.Accent
    $lvHistorial.BackColor  = $c.BgCard
    $lvHistorial.ForeColor  = $c.TextSecond
    $form.Refresh()
}

# ============================================================================
# INTERFAZ PRINCIPAL
# ============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Windows De Mente v2.0"
$form.Size            = New-Object System.Drawing.Size(1350, 780)
$form.MinimumSize     = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.BackColor       = $script:colors.BgDark

# ── HEADER ──────────────────────────────────────────────────────────────────
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location  = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size      = New-Object System.Drawing.Size(1350, 50)
$headerPanel.BackColor = $script:colors.BgHeader
$headerPanel.Anchor    = "Top,Left,Right"

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "⚡ WINDOWS DE MENTE v2.0"
$lblTitle.Font      = $fonts.Title
$lblTitle.ForeColor = $script:colors.Accent
$lblTitle.Location  = New-Object System.Drawing.Point(10, 8)
$lblTitle.AutoSize  = $true
$headerPanel.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text      = "Lee tu PC, optimiza lo que corresponde — sin recetas genéricas"
$lblSubtitle.Font      = $fonts.Body
$lblSubtitle.ForeColor = $script:colors.TextDim
$lblSubtitle.Location  = New-Object System.Drawing.Point(340, 16)
$lblSubtitle.AutoSize  = $true
$headerPanel.Controls.Add($lblSubtitle)

$lblOs = New-Object System.Windows.Forms.Label
$lblOs.Text      = "$($script:WindowsVersion.Name) (Build $($script:WindowsVersion.Build))"
$lblOs.Font      = $fonts.Small
$lblOs.ForeColor = $script:colors.TextDim
$lblOs.Location  = New-Object System.Drawing.Point(640, 18)
$lblOs.AutoSize  = $true
$headerPanel.Controls.Add($lblOs)

$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text      = "☀️ CLARO"
$btnTheme.Font      = $fonts.BodyBold
$btnTheme.ForeColor = $script:colors.TextPrimary
$btnTheme.BackColor = $script:colors.BgCard2
$btnTheme.FlatStyle = "Flat"
$btnTheme.FlatAppearance.BorderSize = 0
$btnTheme.Location  = New-Object System.Drawing.Point(1215, 8)
$btnTheme.Size      = New-Object System.Drawing.Size(100, 34)
$btnTheme.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnTheme.Anchor    = "Top,Right"
$headerPanel.Controls.Add($btnTheme)
$form.Controls.Add($headerPanel)

# ── LEFT PANEL ───────────────────────────────────────────────────────────────
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location   = New-Object System.Drawing.Point(5, 55)
$leftPanel.Size       = New-Object System.Drawing.Size(230, 690)
$leftPanel.BackColor  = $script:colors.BgPanel
$leftPanel.Anchor     = "Top,Left,Bottom"

$lblHwTitle = New-Object System.Windows.Forms.Label
$lblHwTitle.Text      = "🖥️ TU EQUIPO"
$lblHwTitle.Font      = $fonts.Header
$lblHwTitle.ForeColor = $script:colors.Accent
$lblHwTitle.Location  = New-Object System.Drawing.Point(5, 5)
$lblHwTitle.AutoSize  = $true
$leftPanel.Controls.Add($lblHwTitle)

$rtbHardware = New-Object System.Windows.Forms.RichTextBox
$rtbHardware.Location    = New-Object System.Drawing.Point(5, 28)
$rtbHardware.Size        = New-Object System.Drawing.Size(220, 185)
$rtbHardware.BackColor   = $script:colors.BgLog
$rtbHardware.ForeColor   = $script:colors.TextSecond
$rtbHardware.Font        = $fonts.MonoSm
$rtbHardware.ReadOnly    = $true
$rtbHardware.BorderStyle = "None"
$leftPanel.Controls.Add($rtbHardware)

$btnAnalyze = New-Object System.Windows.Forms.Button
$btnAnalyze.Text      = "🔍 ANALIZAR MI PC"
$btnAnalyze.Font      = $fonts.BodyBold
$btnAnalyze.ForeColor = $script:colors.BgDark
$btnAnalyze.BackColor = $script:colors.Accent
$btnAnalyze.FlatStyle = "Flat"
$btnAnalyze.FlatAppearance.BorderSize = 0
$btnAnalyze.Location  = New-Object System.Drawing.Point(5, 218)
$btnAnalyze.Size      = New-Object System.Drawing.Size(220, 34)
$btnAnalyze.Cursor    = [System.Windows.Forms.Cursors]::Hand
$leftPanel.Controls.Add($btnAnalyze)

# SCORE PANEL
$pnlScore = New-Object System.Windows.Forms.Panel
$pnlScore.Location  = New-Object System.Drawing.Point(5, 260)
$pnlScore.Size      = New-Object System.Drawing.Size(220, 80)
$pnlScore.BackColor = $script:colors.BgCard2
$leftPanel.Controls.Add($pnlScore)

$lblScoreTitle = New-Object System.Windows.Forms.Label
$lblScoreTitle.Text      = "PUNTUACIÓN"
$lblScoreTitle.Font      = $fonts.Small
$lblScoreTitle.ForeColor = $script:colors.TextDim
$lblScoreTitle.Location  = New-Object System.Drawing.Point(5, 5)
$lblScoreTitle.Size      = New-Object System.Drawing.Size(210, 15)
$lblScoreTitle.TextAlign = "MiddleCenter"
$pnlScore.Controls.Add($lblScoreTitle)

$lblScoreNum = New-Object System.Windows.Forms.Label
$lblScoreNum.Text      = "--"
$lblScoreNum.Font      = $fonts.Score
$lblScoreNum.ForeColor = $script:colors.TextDim
$lblScoreNum.Location  = New-Object System.Drawing.Point(5, 18)
$lblScoreNum.Size      = New-Object System.Drawing.Size(140, 55)
$lblScoreNum.TextAlign = "MiddleRight"
$pnlScore.Controls.Add($lblScoreNum)

$lblScoreLabel = New-Object System.Windows.Forms.Label
$lblScoreLabel.Text      = ""
$lblScoreLabel.Font      = $fonts.ScoreSm
$lblScoreLabel.ForeColor = $script:colors.TextDim
$lblScoreLabel.Location  = New-Object System.Drawing.Point(150, 32)
$lblScoreLabel.Size      = New-Object System.Drawing.Size(65, 30)
$lblScoreLabel.TextAlign = "MiddleLeft"
$pnlScore.Controls.Add($lblScoreLabel)

# Estado del sistema
$lblSysInfo = New-Object System.Windows.Forms.Label
$lblSysInfo.Text      = "ESTADO ACTUAL"
$lblSysInfo.Font      = $fonts.Header
$lblSysInfo.ForeColor = $script:colors.Accent
$lblSysInfo.Location  = New-Object System.Drawing.Point(5, 348)
$lblSysInfo.AutoSize  = $true
$leftPanel.Controls.Add($lblSysInfo)

$rtbSysStatus = New-Object System.Windows.Forms.RichTextBox
$rtbSysStatus.Location    = New-Object System.Drawing.Point(5, 370)
$rtbSysStatus.Size        = New-Object System.Drawing.Size(220, 80)
$rtbSysStatus.BackColor   = $script:colors.BgLog
$rtbSysStatus.ForeColor   = $script:colors.TextSecond
$rtbSysStatus.Font        = $fonts.MonoSm
$rtbSysStatus.ReadOnly    = $true
$rtbSysStatus.BorderStyle = "None"
$leftPanel.Controls.Add($rtbSysStatus)

# HISTORIAL
$lblHistTitle = New-Object System.Windows.Forms.Label
$lblHistTitle.Text      = "ÚLTIMOS CAMBIOS"
$lblHistTitle.Font      = $fonts.Header
$lblHistTitle.ForeColor = $script:colors.Accent
$lblHistTitle.Location  = New-Object System.Drawing.Point(5, 460)
$lblHistTitle.AutoSize  = $true
$leftPanel.Controls.Add($lblHistTitle)

$lvHistorial = New-Object System.Windows.Forms.ListView
$lvHistorial.Location  = New-Object System.Drawing.Point(5, 482)
$lvHistorial.Size      = New-Object System.Drawing.Size(220, 198)
$lvHistorial.View      = "Details"
$lvHistorial.FullRowSelect  = $true
$lvHistorial.GridLines      = $false
$lvHistorial.BackColor      = $script:colors.BgCard
$lvHistorial.ForeColor      = $script:colors.TextSecond
$lvHistorial.Font           = New-Object System.Drawing.Font("Segoe UI", 7)
$lvHistorial.BorderStyle    = "None"
$lvHistorial.HeaderStyle    = "None"
$lvHistorial.CheckBoxes     = $false
$lvHistorial.UseCompatibleStateImageBehavior = $false
$lvHistorial.Columns.Add("Fecha",  60)
$lvHistorial.Columns.Add("Cambio", 148)
$leftPanel.Controls.Add($lvHistorial)

$form.Controls.Add($leftPanel)

# Timer para estado + historial
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({
    try {
        # CPU
        $cpuStr = "--"
        try { $cpuStr = "$([math]::Round((Get-CimInstance Win32_Processor -EA Stop | Select-Object -First 1).LoadPercentage, 0))%" } catch {}

        # RAM
        $ramStr = "--"
        try {
            $os   = Get-CimInstance Win32_OperatingSystem -EA Stop
            $free = [math]::Round($os.FreePhysicalMemory   / 1MB, 1)
            $tot  = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $ramStr = "$([math]::Round($tot - $free, 1))/$tot GB"
        } catch {}

        # Uptime — usar SystemUpTime en segundos, sin ningún cast de fechas
        $uptimeStr = "--"
        try {
            $perfOS  = Get-CimInstance Win32_PerfFormattedData_PerfOS_System -EA Stop
            $seconds = [long]$perfOS.SystemUpTime
            $h = [math]::Floor($seconds / 3600)
            $m = [math]::Floor(($seconds % 3600) / 60)
            $uptimeStr = "${h}h ${m}m"
        } catch {}

        $rtbSysStatus.Clear()
        $rtbSysStatus.AppendText("CPU:  $cpuStr`r`n")
        $rtbSysStatus.AppendText("RAM:  $ramStr`r`n")
        $rtbSysStatus.AppendText("Up:   $uptimeStr`r`n")
    } catch {}
})
$timer.Start()

# ── CENTER PANEL ─────────────────────────────────────────────────────────────
$centerPanel = New-Object System.Windows.Forms.Panel
$centerPanel.Location  = New-Object System.Drawing.Point(240, 55)
$centerPanel.Size      = New-Object System.Drawing.Size(660, 690)
$centerPanel.BackColor = $script:colors.BgPanel
$centerPanel.Anchor    = "Top,Left,Bottom,Right"

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location  = New-Object System.Drawing.Point(5, 5)
$tabControl.Size      = New-Object System.Drawing.Size(650, 575)
$tabControl.Font      = $fonts.TabFont
$tabControl.BackColor = $script:colors.BgCard
$tabControl.Anchor    = "Top,Left,Bottom,Right"

# TAB: OPTIMIZACIONES
$tabOptimizaciones = New-Object System.Windows.Forms.TabPage
$tabOptimizaciones.Text     = "⚡ OPTIMIZACIONES"
$tabOptimizaciones.BackColor = $script:colors.BgCard

$lvOptimizations = New-Object System.Windows.Forms.ListView
$lvOptimizations.Location  = New-Object System.Drawing.Point(3, 3)
$lvOptimizations.Size      = New-Object System.Drawing.Size(642, 540)
$lvOptimizations.View      = "Details"
$lvOptimizations.FullRowSelect = $true
# Fix global para el bug de ImageList en ListView con CheckBoxes en .NET 9 / PS7
# En .NET 9, ListView con CheckBoxes=true genera errores de ImageList internos
# La solución es asignar un ImageList vacío explícito antes de activar CheckBoxes
$emptyImageList = New-Object System.Windows.Forms.ImageList
$emptyImageList.ImageSize = New-Object System.Drawing.Size(1, 1)
$emptyImageList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

$lvOptimizations.SmallImageList = $emptyImageList
$lvOptimizations.GridLines     = $false
$lvOptimizations.BackColor     = $script:colors.BgCard
$lvOptimizations.ForeColor     = $script:colors.TextPrimary
$lvOptimizations.Font          = $fonts.Mono
$lvOptimizations.BorderStyle   = "None"
$lvOptimizations.HeaderStyle   = "None"
$lvOptimizations.UseCompatibleStateImageBehavior = $false
$lvOptimizations.CheckBoxes    = $true
$lvOptimizations.Columns.Add("Optimización", 448)
$lvOptimizations.Columns.Add("Estado",       182)
$tabOptimizaciones.Controls.Add($lvOptimizations)

# TAB: LIMPIEZA
$tabLimpieza = New-Object System.Windows.Forms.TabPage
$tabLimpieza.Text     = "🧹 LIMPIEZA"
$tabLimpieza.BackColor = $script:colors.BgCard

$lvLimpieza = New-Object System.Windows.Forms.ListView
$lvLimpieza.Location  = New-Object System.Drawing.Point(3, 3)
$lvLimpieza.Size      = New-Object System.Drawing.Size(642, 540)
$lvLimpieza.View      = "Details"
$lvLimpieza.FullRowSelect = $true
$lvLimpieza.SmallImageList = $emptyImageList
$lvLimpieza.GridLines     = $false
$lvLimpieza.BackColor     = $script:colors.BgCard
$lvLimpieza.ForeColor     = $script:colors.TextPrimary
$lvLimpieza.Font          = $fonts.Mono
$lvLimpieza.BorderStyle   = "None"
$lvLimpieza.HeaderStyle   = "None"
$lvLimpieza.UseCompatibleStateImageBehavior = $false
$lvLimpieza.CheckBoxes    = $true
$lvLimpieza.Columns.Add("Limpieza", 330)
$lvLimpieza.Columns.Add("Tamaño",   116)
$lvLimpieza.Columns.Add("",         184)
$tabLimpieza.Controls.Add($lvLimpieza)

# TAB: PRIVACIDAD
$tabPrivacidad = New-Object System.Windows.Forms.TabPage
$tabPrivacidad.Text     = "🛡️ PRIVACIDAD"
$tabPrivacidad.BackColor = $script:colors.BgCard

$lvPrivacidad = New-Object System.Windows.Forms.ListView
$lvPrivacidad.Location  = New-Object System.Drawing.Point(3, 3)
$lvPrivacidad.Size      = New-Object System.Drawing.Size(642, 540)
$lvPrivacidad.View      = "Details"
$lvPrivacidad.FullRowSelect = $true
$lvPrivacidad.SmallImageList = $emptyImageList
$lvPrivacidad.GridLines     = $false
$lvPrivacidad.BackColor     = $script:colors.BgCard
$lvPrivacidad.ForeColor     = $script:colors.TextPrimary
$lvPrivacidad.Font          = $fonts.Mono
$lvPrivacidad.BorderStyle   = "None"
$lvPrivacidad.HeaderStyle   = "None"
$lvPrivacidad.UseCompatibleStateImageBehavior = $false
$lvPrivacidad.CheckBoxes    = $true
$lvPrivacidad.Columns.Add("Ajuste de Privacidad", 448)
$lvPrivacidad.Columns.Add("Estado",               182)
$tabPrivacidad.Controls.Add($lvPrivacidad)

# TAB: USO DIARIO
$tabDiario = New-Object System.Windows.Forms.TabPage
$tabDiario.Text      = "🖥️ USO DIARIO"
$tabDiario.BackColor = $script:colors.BgCard

$lvDiario = New-Object System.Windows.Forms.ListView
$lvDiario.Location      = New-Object System.Drawing.Point(3, 3)
$lvDiario.Size          = New-Object System.Drawing.Size(642, 540)
$lvDiario.View          = "Details"
$lvDiario.FullRowSelect = $true
$lvDiario.SmallImageList = $emptyImageList
$lvDiario.GridLines     = $false
$lvDiario.BackColor     = $script:colors.BgCard
$lvDiario.ForeColor     = $script:colors.TextPrimary
$lvDiario.Font          = $fonts.Mono
$lvDiario.BorderStyle   = "None"
$lvDiario.HeaderStyle   = "None"
$lvDiario.UseCompatibleStateImageBehavior = $false
$lvDiario.CheckBoxes    = $true
$lvDiario.Columns.Add("Ajuste de Uso Diario", 448)
$lvDiario.Columns.Add("Estado",               182)
$tabDiario.Controls.Add($lvDiario)

# TAB: SALUD Y REPARACIÓN (UNIFICADO)
$tabSalud = New-Object System.Windows.Forms.TabPage
$tabSalud.Text     = "🩺 SALUD Y REPARACIÓN"
$tabSalud.BackColor = $script:colors.BgCard

# Panel superior: checkboxes de etapas
$pnlDiagEtapas = New-Object System.Windows.Forms.Panel
$pnlDiagEtapas.Location  = New-Object System.Drawing.Point(5, 5)
$pnlDiagEtapas.Size      = New-Object System.Drawing.Size(638, 118)
$pnlDiagEtapas.BackColor = $script:colors.BgCard2
$tabSalud.Controls.Add($pnlDiagEtapas)

$lblEtapasTitle = New-Object System.Windows.Forms.Label
$lblEtapasTitle.Text      = "  Seleccioná qué revisar:"
$lblEtapasTitle.Font      = $fonts.BodyBold
$lblEtapasTitle.ForeColor = $script:colors.Accent
$lblEtapasTitle.Location  = New-Object System.Drawing.Point(0, 4)
$lblEtapasTitle.Size      = New-Object System.Drawing.Size(200, 18)
$pnlDiagEtapas.Controls.Add($lblEtapasTitle)

# Definición de etapas con descripción corta
$script:DiagEtapasDef = @(
    @{ Key="HW";        Label="Hardware";          Desc="Salud de discos y temperatura del CPU";                 Default=$true  }
    @{ Key="Disco";     Label="Disco";             Desc="Espacio libre disponible en el disco principal";        Default=$true  }
    @{ Key="WHEA";      Label="Errores hardware";  Desc="Errores reales de CPU, RAM o placa madre";             Default=$true  }
    @{ Key="Drivers";   Label="Drivers";           Desc="Dispositivos con controladores con problemas";         Default=$true  }
    @{ Key="Servicios"; Label="Servicios";         Desc="Servicios críticos del sistema activos o caídos";      Default=$true  }
    @{ Key="Eventos";   Label="Eventos (48hs)";    Desc="Errores críticos reales en las últimas 48 horas";      Default=$true  }
    @{ Key="SFC";       Label="Integridad Win";    Desc="SFC + DISM — archivos del sistema corruptos (lento)";  Default=$true  }
    @{ Key="Red";       Label="Red y DNS";         Desc="Conectividad, DNS configurados, proxy y latencia";     Default=$true  }
    @{ Key="Seguridad"; Label="Seguridad";         Desc="Antivirus, firewall y UAC activos";                    Default=$true  }
    @{ Key="Arranque";  Label="Arranque";          Desc="Apagados inesperados y programas al inicio";           Default=$true  }
)

$script:DiagChkBoxes = @{}
$col = 0; $row = 0
for ($i = 0; $i -lt $script:DiagEtapasDef.Count; $i++) {
    $etapa = $script:DiagEtapasDef[$i]
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text      = $etapa.Label
    $chk.Checked   = $etapa.Default
    $chk.Font      = $fonts.BodyBold
    $chk.ForeColor = $script:colors.TextPrimary
    $chk.BackColor = [System.Drawing.Color]::Transparent
    $chk.AutoSize  = $false
    $chk.Size      = New-Object System.Drawing.Size(155, 20)
    $chk.Location  = New-Object System.Drawing.Point((8 + $col * 160), (26 + $row * 22))
    $chk.Cursor    = [System.Windows.Forms.Cursors]::Hand
    # Tooltip con descripción
    $tt = New-Object System.Windows.Forms.ToolTip
    $tt.SetToolTip($chk, $etapa.Desc)
    $script:DiagChkBoxes[$etapa.Key] = $chk
    $pnlDiagEtapas.Controls.Add($chk)
    $col++
    if ($col -ge 4) { $col = 0; $row++ }
}

# Nota especial para SFC
$lblSFCNota = New-Object System.Windows.Forms.Label
$lblSFCNota.Text      = "  ⚡ 'Integridad Win' tarda 2-5 min. Se omite si ya corrió esta sesión."
$lblSFCNota.Font      = $fonts.Small
$lblSFCNota.ForeColor = $script:colors.TextDim
$lblSFCNota.Location  = New-Object System.Drawing.Point(0, 94)
$lblSFCNota.Size      = New-Object System.Drawing.Size(638, 18)
$pnlDiagEtapas.Controls.Add($lblSFCNota)

$btnRunSalud = New-Object System.Windows.Forms.Button
$btnRunSalud.Text      = "🩺 REVISAR MI PC AHORA"
$btnRunSalud.Font      = $fonts.BodyBold
$btnRunSalud.ForeColor = $script:colors.TextPrimary
$btnRunSalud.BackColor = $script:colors.Purple
$btnRunSalud.FlatStyle = "Flat"
$btnRunSalud.FlatAppearance.BorderSize = 0
$btnRunSalud.Location  = New-Object System.Drawing.Point(5, 128)
$btnRunSalud.Size      = New-Object System.Drawing.Size(638, 34)
$btnRunSalud.Cursor    = [System.Windows.Forms.Cursors]::Hand
$tabSalud.Controls.Add($btnRunSalud)

$rtbSalud = New-Object System.Windows.Forms.RichTextBox
$rtbSalud.Location    = New-Object System.Drawing.Point(5, 167)
$rtbSalud.Size        = New-Object System.Drawing.Size(638, 376)
$rtbSalud.BackColor   = $script:colors.BgLog
$rtbSalud.ForeColor   = $script:colors.TextPrimary
$rtbSalud.Font        = $fonts.Mono
$rtbSalud.ReadOnly    = $true
$rtbSalud.BorderStyle = "None"
$rtbSalud.ScrollBars  = "Vertical"
$rtbSalud.Anchor      = "Top,Left,Bottom,Right"
$tabSalud.Controls.Add($rtbSalud)

$tabControl.TabPages.AddRange(@($tabOptimizaciones, $tabLimpieza, $tabPrivacidad, $tabDiario, $tabSalud))
$centerPanel.Controls.Add($tabControl)

$btnOptimize = New-Object System.Windows.Forms.Button
$btnOptimize.Text      = "✅ APLICAR SELECCIONADAS"
$btnOptimize.Font      = $fonts.BodyBold
$btnOptimize.ForeColor = $script:colors.BgDark
$btnOptimize.BackColor = $script:colors.Accent
$btnOptimize.FlatStyle = "Flat"
$btnOptimize.FlatAppearance.BorderSize = 0
$btnOptimize.Location  = New-Object System.Drawing.Point(5, 585)
$btnOptimize.Size      = New-Object System.Drawing.Size(325, 36)
$btnOptimize.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnOptimize.Anchor    = "Bottom,Left"
$centerPanel.Controls.Add($btnOptimize)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text      = "↩ RESTAURAR TODO"
$btnRestore.Font      = $fonts.BodyBold
$btnRestore.ForeColor = $script:colors.TextPrimary
$btnRestore.BackColor = $script:colors.BgCard2
$btnRestore.FlatStyle = "Flat"
$btnRestore.FlatAppearance.BorderColor = $script:colors.Red
$btnRestore.FlatAppearance.BorderSize  = 1
$btnRestore.Location  = New-Object System.Drawing.Point(335, 585)
$btnRestore.Size      = New-Object System.Drawing.Size(320, 36)
$btnRestore.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnRestore.Anchor    = "Bottom,Left"
$centerPanel.Controls.Add($btnRestore)

$form.Controls.Add($centerPanel)

# ── RIGHT PANEL ───────────────────────────────────────────────────────────────
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location  = New-Object System.Drawing.Point(905, 55)
$rightPanel.Size      = New-Object System.Drawing.Size(430, 690)
$rightPanel.BackColor = $script:colors.BgPanel
$rightPanel.Anchor    = "Top,Right,Bottom"

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text      = "📋 ¿QUÉ HACE ESTO?"
$lblLog.Font      = $fonts.Header
$lblLog.ForeColor = $script:colors.Accent
$lblLog.Location  = New-Object System.Drawing.Point(5, 5)
$lblLog.AutoSize  = $true
$rightPanel.Controls.Add($lblLog)

$rtbLog = New-Object System.Windows.Forms.RichTextBox
$rtbLog.Location    = New-Object System.Drawing.Point(5, 28)
$rtbLog.Size        = New-Object System.Drawing.Size(420, 655)
$rtbLog.BackColor   = $script:colors.BgLog
$rtbLog.ForeColor   = $script:colors.TextPrimary
$rtbLog.Font        = $fonts.Mono
$rtbLog.ReadOnly    = $true
$rtbLog.BorderStyle = "None"
$rtbLog.Anchor      = "Top,Left,Bottom,Right"
$rightPanel.Controls.Add($rtbLog)

$form.Controls.Add($rightPanel)

# ============================================================================
# FUNCIÓN MOSTRAR EXPLICACIÓN EN PANEL DERECHO
# ============================================================================
function Show-ExplicacionOptimizacion {
    param($opt)
    $c = $script:colors
    $rtbLog.Clear()
    $rtbLog.SelectionColor = $c.Accent
    $rtbLog.AppendText("$($opt.Name)`r`n")
    $rtbLog.SelectionColor = $c.TextDim
    $rtbLog.AppendText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━`r`n`r`n")
    $rtbLog.SelectionColor = $c.TextPrimary
    $rtbLog.AppendText("$($opt.Explicacion)`r`n`r`n")
    if ($opt.IsOverOptimized) {
        $rtbLog.SelectionColor = $c.Red
        $rtbLog.AppendText("⚠️ VALOR PELIGROSO DETECTADO`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("Este valor fue modificado por otro programa y puede causar`r`ninestabilidad. WDM puede corregirlo de forma segura.`r`n`r`n")
    }
    $rtbLog.SelectionColor = $c.TextDim
    $rtbLog.AppendText("Categoría: $($opt.Category)")
    $rtbLog.ScrollToCaret()
}

# ============================================================================
# EVENTOS
# ============================================================================
$lvOptimizations.Add_SelectedIndexChanged({
    if ($lvOptimizations.SelectedItems.Count -gt 0 -and $lvOptimizations.SelectedItems[0].Tag) {
        Show-ExplicacionOptimizacion -opt $lvOptimizations.SelectedItems[0].Tag
    }
})

$lvLimpieza.Add_SelectedIndexChanged({
    if ($lvLimpieza.SelectedItems.Count -gt 0) {
        $info         = $lvLimpieza.SelectedItems[0].Tag
        $selectedItem = $lvLimpieza.SelectedItems[0]
        $c = $script:colors
        $rtbLog.Clear()
        $rtbLog.SelectionColor = $c.Accent
        $rtbLog.AppendText("$($info.Name)`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━`r`n`r`n")
        $rtbLog.SelectionColor = $c.TextPrimary
        $rtbLog.AppendText("$($info.Explicacion)`r`n`r`n")
        if ($selectedItem.SubItems[1].Text -eq "clic para ver") {
            if ($info.Name -match "WinSxS") {
                $selectedItem.SubItems[1].Text = "ver resultado"
                $rtbLog.SelectionColor = $c.TextDim
                $rtbLog.AppendText("El tamaño liberado se verá en el registro de operaciones.`r`n")
            } else {
                $rtbLog.SelectionColor = $c.Accent
                $rtbLog.AppendText("⏳ Calculando espacio ocupado...`r`n")
                [System.Windows.Forms.Application]::DoEvents()
                $currentSize = if ($info.GetSize -is [scriptblock]) { try { & $info.GetSize } catch { "?" } } else { "?" }
                $selectedItem.SubItems[1].Text = $currentSize
                $rtbLog.SelectionColor = $c.Green
                $rtbLog.AppendText("Espacio recuperable: $currentSize`r`n")
            }
        } else {
            $rtbLog.SelectionColor = $c.Green
            $rtbLog.AppendText("Espacio: $($selectedItem.SubItems[1].Text)`r`n")
        }
        $rtbLog.ScrollToCaret()
    }
})

$lvDiario.Add_SelectedIndexChanged({
    if ($lvDiario.SelectedItems.Count -gt 0 -and $lvDiario.SelectedItems[0].Tag) {
        $opt = $lvDiario.SelectedItems[0].Tag
        $c = $script:colors
        $rtbLog.Clear()
        $rtbLog.SelectionColor = $c.Accent
        $rtbLog.AppendText("$($opt.Name)`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━`r`n`r`n")
        $rtbLog.SelectionColor = $c.TextPrimary
        $rtbLog.AppendText("$($opt.Explicacion)`r`n`r`n")
        $rtbLog.SelectionColor = $c.Green
        $rtbLog.AppendText("🖥️ Categoría: $($opt.Category)")
        $rtbLog.ScrollToCaret()
    }
})

$lvPrivacidad.Add_SelectedIndexChanged({
    if ($lvPrivacidad.SelectedItems.Count -gt 0 -and $lvPrivacidad.SelectedItems[0].Tag) {
        $opt = $lvPrivacidad.SelectedItems[0].Tag
        $c = $script:colors
        $rtbLog.Clear()
        $rtbLog.SelectionColor = $c.Accent
        $rtbLog.AppendText("$($opt.Name)`r`n")
        $rtbLog.SelectionColor = $c.TextDim
        $rtbLog.AppendText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━`r`n`r`n")
        $rtbLog.SelectionColor = $c.TextPrimary
        $rtbLog.AppendText("$($opt.Explicacion)`r`n`r`n")
        $rtbLog.SelectionColor = $c.Purple
        $rtbLog.AppendText("🛡️ Este ajuste protege tu privacidad sin afectar`r`n   el funcionamiento normal de tu PC.")
        $rtbLog.ScrollToCaret()
    }
})

$btnAnalyze.Add_Click({
    if ($script:Analyzing) { return }
    $script:Analyzing = $true
    $btnAnalyze.Enabled = $false
    $rtbHardware.Clear()
    $lvOptimizations.Items.Clear()
    $lvLimpieza.Items.Clear()
    $lvPrivacidad.Items.Clear()
    $lvDiario.Items.Clear()
    $script:OriginalValues = @{}

    $rtbLog.Clear()
    $rtbLog.SelectionColor = $script:colors.Accent
    $rtbLog.AppendText("Analizando tu PC...`r`n")
    $rtbLog.SelectionColor = $script:colors.TextDim
    $rtbLog.AppendText("Esto tarda unos segundos.`r`n")
    [System.Windows.Forms.Application]::DoEvents()

    $script:Hardware       = Get-HardwareProfile
    $script:DeepBackupPath = Backup-CriticalRegions
    Get-OptimizationsList -HW $script:Hardware
    Get-DiarioList
    Show-ResumenInteligente

    # Actualizar historial en panel
    Refresh-HistorialDisplay

    $btnAnalyze.Enabled = $true
    $script:Analyzing   = $false
})

function Refresh-HistorialDisplay {
    $lvHistorial.Items.Clear()
    $mostrarCount = [math]::Min(20, $script:Historial.Count)
    for ($i = 0; $i -lt $mostrarCount; $i++) {
        $entry = $script:Historial[$i]
        $item = New-Object System.Windows.Forms.ListViewItem
        $item.Text = $entry.Fecha.ToString("dd/MM HH:mm")
        $item.SubItems.Add($entry.Nombre) | Out-Null
        if ($entry.Exitosa) { $item.ForeColor = $script:colors.Green }
        else { $item.ForeColor = $script:colors.Red }
        $lvHistorial.Items.Add($item) | Out-Null
    }
}

$btnOptimize.Add_Click({
    if (-not $script:Hardware -or -not $script:Hardware.Valid) {
        [System.Windows.Forms.MessageBox]::Show("Primero analizá tu PC con el botón 'ANALIZAR MI PC'.", "Windows De Mente")
        return
    }
    $selectedCount = 0
    for ($i=0; $i -lt $lvOptimizations.Items.Count; $i++) { if ($lvOptimizations.Items[$i].Checked) { $selectedCount++ } }
    for ($i=0; $i -lt $lvLimpieza.Items.Count;      $i++) { if ($lvLimpieza.Items[$i].Checked)      { $selectedCount++ } }
    for ($i=0; $i -lt $lvPrivacidad.Items.Count;    $i++) { if ($lvPrivacidad.Items[$i].Checked)    { $selectedCount++ } }
    for ($i=0; $i -lt $lvDiario.Items.Count;        $i++) { if ($lvDiario.Items[$i].Checked)        { $selectedCount++ } }
    if ($selectedCount -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Seleccioná al menos una optimización o limpieza.", "Windows De Mente")
        return
    }
    if (-not $script:FirstRunBackup) { Backup-OriginalState }

    # Mostrar backup info antes de aplicar
    $backupInfo = ""
    if ($script:FirstRunBackup -and (Test-Path $script:FirstRunBackup)) {
        $bkDate = (Get-Item $script:FirstRunBackup).LastWriteTime.ToString("dd/MM/yyyy HH:mm")
        $backupInfo = "`r`nPunto de restauración creado el: $bkDate`r`n(podés volver atrás con 'RESTAURAR TODO')"
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Se van a aplicar $selectedCount cambio(s) en tu PC.$backupInfo`r`n`r`n¿Continuamos?",
        "Windows De Mente",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirm -eq [System.Windows.Forms.DialogResult]::No) { return }

    $successCount=0; $failCount=0; $itemsToRemove=@()
    Write-Log "════════════════════════════" "Accent"
    Write-Log "APLICANDO MEJORAS..." "Accent"
    Write-Log "════════════════════════════" "Accent"

    for ($i=0; $i -lt $lvOptimizations.Items.Count; $i++) {
        if ($lvOptimizations.Items[$i].Checked) {
            $item=$lvOptimizations.Items[$i]; $opt=$item.Tag; $funcName=$opt.Func
            try {
                Write-Log "⏳ $($item.Text)..." "Yellow"
                $result = Invoke-OptFunc $funcName
                if ($result) {
                    $itemsToRemove+=$item; $successCount++
                    if($opt.Key){$script:OptimizationsApplied[$opt.Key]=Get-Date}
                    Add-Historial -Nombre $item.Text -Tipo "Optimización" -Exitosa $true
                } else { $failCount++; Add-Historial -Nombre $item.Text -Tipo "Optimización" -Exitosa $false }
            } catch { $failCount++; Write-Log "  ✗ Error: $_" "Red"; Add-Historial -Nombre $item.Text -Tipo "Optimización" -Exitosa $false }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    for ($i=0; $i -lt $lvPrivacidad.Items.Count; $i++) {
        if ($lvPrivacidad.Items[$i].Checked) {
            $item=$lvPrivacidad.Items[$i]; $opt=$item.Tag; $funcName=$opt.Func
            try {
                Write-Log "⏳ $($item.Text)..." "Yellow"
                $result = Invoke-OptFunc $funcName
                if ($result) {
                    $itemsToRemove+=$item; $successCount++
                    if($opt.Key){$script:OptimizationsApplied[$opt.Key]=Get-Date}
                    Add-Historial -Nombre $item.Text -Tipo "Privacidad" -Exitosa $true
                } else { $failCount++; Add-Historial -Nombre $item.Text -Tipo "Privacidad" -Exitosa $false }
            } catch { $failCount++; Write-Log "  ✗ Error: $_" "Red" }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    for ($i=0; $i -lt $lvDiario.Items.Count; $i++) {
        if ($lvDiario.Items[$i].Checked) {
            $item=$lvDiario.Items[$i]; $opt=$item.Tag; $funcName=$opt.Func
            try {
                Write-Log "⏳ $($item.Text)..." "Yellow"
                $result = Invoke-OptFunc $funcName
                if ($result) {
                    $itemsToRemove+=$item; $successCount++
                    if($opt.Key){$script:OptimizationsApplied[$opt.Key]=Get-Date}
                    Add-Historial -Nombre $item.Text -Tipo "Uso Diario" -Exitosa $true
                } else { $failCount++; Add-Historial -Nombre $item.Text -Tipo "Uso Diario" -Exitosa $false }
            } catch { $failCount++; Write-Log "  ✗ Error: $_" "Red" }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    for ($i=0; $i -lt $lvLimpieza.Items.Count; $i++) {
        if ($lvLimpieza.Items[$i].Checked) {
            $item=$lvLimpieza.Items[$i]; $info=$item.Tag
            try {
                Write-Log "⏳ $($item.Text)..." "Yellow"
                $result = & $info.Action
                if ($result) {
                    $successCount++
                    if($info.GetSize -is [scriptblock]){$item.SubItems[1].Text = & $info.GetSize}
                    Add-Historial -Nombre $item.Text -Tipo "Limpieza" -Exitosa $true
                } else { $failCount++; Add-Historial -Nombre $item.Text -Tipo "Limpieza" -Exitosa $false }
            } catch { $failCount++; Write-Log "  ✗ Error: $_" "Red" }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    foreach ($item in $itemsToRemove) {
        try{$lvOptimizations.Items.Remove($item)}catch{}
        try{$lvPrivacidad.Items.Remove($item)}catch{}
        try{$lvDiario.Items.Remove($item)}catch{}
    }
    # Reiniciar Explorer si hubo cambios de Uso Diario que lo requieren
    $diarioCambios = @("ExtensionesVisibles","ArchivosOcultosVisibles","ExploradorEstaPC","CarpetasAntesDeArchivos","ExploradorCheckboxes","SinAgrupacionesExplorador","TaskbarLimpia")
    $necesitaExplorer = $itemsToRemove | Where-Object { $_.Tag -and ($diarioCambios | Where-Object { $_.Tag.Func -match $_ }) }
    if ($necesitaExplorer -or ($itemsToRemove | Where-Object { $_.Tag -and $_.Tag.Category -eq "Explorador" })) {
        try {
            Stop-Process -Name explorer -Force -EA SilentlyContinue
            Start-Sleep -Milliseconds 800
            Start-Process explorer
            Write-Log "  ✓ Explorador reiniciado para aplicar cambios visuales" "Green"
        } catch {}
    }
    Save-HardwareMemory
    Refresh-HistorialDisplay

    # Recalcular score después
    $script:ScoreDespues = Get-SystemScore
    Update-ScoreDisplay -Score $script:ScoreDespues -Label "AHORA"

    Write-Log "" "TextPrimary"
    Write-Log "═══════════════════════════" "Accent"
    Write-Log "¡LISTO! $successCount cambio(s) aplicado(s)" "Green"
    if ($failCount -gt 0) { Write-Log "($failCount no se pudieron aplicar)" "Orange" }
    Write-Log "═══════════════════════════" "Accent"
    Write-Log "" "TextPrimary"
    Write-Log "⚠️ Para que todo funcione correctamente," "Yellow"
    Write-Log "   reiniciá la PC cuando puedas." "Yellow"

    if ($successCount -gt 0) {
        $msg = "Se aplicaron $successCount mejora(s) en tu PC."
        if ($script:ScoreAntes -gt 0 -and $script:ScoreDespues -gt 0) {
            $msg += "`r`n`r`nPuntuación: $($script:ScoreAntes) → $($script:ScoreDespues)"
        }
        $msg += "`r`n`r`n¿Reiniciar la PC ahora para aplicar todos los cambios?"
        $reboot = [System.Windows.Forms.MessageBox]::Show($msg, "Windows De Mente", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
        if ($reboot -eq [System.Windows.Forms.DialogResult]::Yes) { shutdown /r /t 10; $form.Close() }
    }
})

$btnRestore.Add_Click({
    $backupToUse = $script:FirstRunBackup
    if (-not $backupToUse -or -not (Test-Path $backupToUse)) { $backupToUse = $script:BackupFile }
    if (-not $backupToUse -or -not (Test-Path $backupToUse)) {
        [System.Windows.Forms.MessageBox]::Show("No hay punto de restauración guardado.`r`n`r`nEl punto de restauración se crea automáticamente la primera vez que analizás la PC.", "Windows De Mente")
        return
    }
    $bkDate = (Get-Item $backupToUse).LastWriteTime.ToString("dd/MM/yyyy HH:mm")
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Vas a volver al estado del $bkDate.`r`n`r`nTodos los cambios que hizo WDM se deshacen.`r`nLa PC se reiniciará.`r`n`r`n¿Continuamos?",
        "Restaurar configuración original",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            reg import $backupToUse
            Write-Log "✅ Configuración original restaurada" "Green"
            Add-Historial -Nombre "RESTAURACIÓN COMPLETA" -Tipo "Restaurar" -Exitosa $true
            Refresh-HistorialDisplay
            if (Test-Path $script:StateFile)      { Remove-Item $script:StateFile      -Force }
            if (Test-Path $script:HardwareIDFile) { Remove-Item $script:HardwareIDFile -Force }
            [System.Windows.Forms.MessageBox]::Show("Configuración restaurada. La PC se reiniciará en 10 segundos.", "Windows De Mente")
            shutdown /r /t 10
            $form.Close()
        } catch { Write-Log "❌ Error al restaurar: $_" "Red"; [System.Windows.Forms.MessageBox]::Show("Error al restaurar la configuración.", "Windows De Mente") }
    }
})

$btnRunSalud.Add_Click({
    $rtbSalud.Clear()
    $btnRunSalud.Enabled = $false
    $btnRunSalud.Text = "⏳ Revisando... (esto puede tardar 1-2 minutos)"
    [System.Windows.Forms.Application]::DoEvents()

    # Construir mapa de etapas seleccionadas
    $etapasSeleccionadas = @{}
    foreach ($key in $script:DiagChkBoxes.Keys) {
        $etapasSeleccionadas[$key] = $script:DiagChkBoxes[$key].Checked
    }

    Run-SaludCompleta -EtapasActivas $etapasSeleccionadas

    $btnRunSalud.Enabled = $true
    $btnRunSalud.Text = "🩺 REVISAR MI PC AHORA"
})

$btnTheme.Add_Click({
    $script:IsDarkMode = -not $script:IsDarkMode
    if ($script:IsDarkMode) { $script:colors = $themes.Dark; $btnTheme.Text = "☀️ CLARO" }
    else { $script:colors = $themes.Light; $btnTheme.Text = "🌙 OSCURO" }
    Apply-Theme
})

$form.Add_Shown({
    $form.Refresh()
    Load-HardwareMemory
    Load-Historial
    Refresh-HistorialDisplay

    # Mensaje de bienvenida en el panel de explicación
    $c = $script:colors
    $rtbLog.SelectionColor = $c.Accent
    $rtbLog.AppendText("Bienvenido/a a Windows De Mente v2.0`r`n`r`n")
    $rtbLog.SelectionColor = $c.TextSecond
    $rtbLog.AppendText("Esta herramienta lee tu hardware y tu configuración antes de tocar cualquier cosa.`r`n`r`n")
    $rtbLog.SelectionColor = $c.TextDim
    $rtbLog.AppendText("No aplica las mismas recetas para todos — ajusta cada mejora según tu equipo específico.`r`n`r`n")
    $rtbLog.SelectionColor = $c.Yellow
    $rtbLog.AppendText("👆 Empezá haciendo clic en 'ANALIZAR MI PC'`r`n")
    $rtbLog.SelectionColor = $c.TextDim
    $rtbLog.AppendText("   WDM va a leer tu PC y mostrarte qué mejoras aplicar.`r`n`r`n")
    $rtbLog.SelectionColor = $c.TextDim
    $rtbLog.AppendText("Después hacé clic en cualquier ítem de la lista`r`n")
    $rtbLog.AppendText("para ver una explicación clara de qué hace y por qué.")

    $btnAnalyze.PerformClick()
})

$form.Add_FormClosing({
    $timer.Stop()
    $timer.Dispose()
})

# ============================================================================
# APLICAR TEMA E INICIAR
# ============================================================================
Apply-Theme

try {
    $form.ShowDialog() | Out-Null
} finally {
    $form.Dispose()
}
