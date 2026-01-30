# 🧠 Windows de Mente v1.0 - Optimización Consciente de Windows

## 📖 ¿Qué es esto?
**Windows de Mente** no es otro "optimizador mágico" que promete milagros. Es una herramienta **consciente** que primero **analiza tu hardware específico** y solo después aplica ajustes **seguros y documentados**. 

La filosofía es simple: **"Guidance, not force"** (Guía, no fuerza). No forzamos configuraciones peligrosas; adaptamos Windows a TU hardware.

## 🚀 ¿Cómo empezar?

### Método 1: Ejecución directa (Recomendado para evitar errores)
```powershell
# 1. Abre PowerShell COMO ADMINISTRADOR
# 2. Copia todo el código del archivo .txt
# 3. Pega directamente en la ventana de PowerShell
# 4. Presiona Enter
```

### Método 2: Desde archivo
```powershell
# Guarda el código como WindowsDeMente.ps1
# Ejecuta en PowerShell como Administrador:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\WindowsDeMente.ps1
```

## ✨ ¿Qué hace diferente?

| Característica | Optimizadores Comerciales | Windows de Mente v1.0 |
|---------------|--------------------------|----------------------|
| **Enfoque** | "Aplica todo, reza después" | "Analiza primero, optimiza después" |
| **Tweaks peligrosos** | Los aplican ciegamente | Los **detecta y elimina** |
| **One-size-fits-all** | Mismo ajuste para todos | **Configuración por hardware** |
| **Transparencia** | Caja negra | **Te muestra qué y por qué** |
| **Backup** | Raramente | **Siempre crea backup** |
| **Reinicio forzado** | Frecuente | **Pregunta antes** |

## 🔍 Fases de Ejecución

### 📊 **FASE 0: Análisis Inicial**
```powershell
# Mide tu sistema ANTES de tocar nada:
• CPU Usage (%) 
• RAM Libre (MB)
• Disco Libre (GB) 
• Latencia de Red (ms)
```

### 🧩 **FASE 1: Categorización Inteligente**
Tu hardware determina la estrategia:
- **ENTUSIASTA** (≥8 núcleos, ≥16GB RAM, SSD)
- **EQUILIBRADO** (≥6 núcleos, ≥8GB RAM, SSD)
- **ESTÁNDAR** (≥4 núcleos, ≥4GB RAM)
- **LIVIANO** (configuraciones menores)

### ⚙️ **FASES 2-9: Optimización Contextual**
Cada fase se adapta a tu categoría:

1. **Power Plan**: Alto Rendimiento vs Equilibrado vs Ahorro
2. **Red**: TCP optimizado según tu conexión (Ethernet/Wi-Fi)
3. **CPU**: Prioridades ajustadas por núcleos disponibles
4. **Almacenamiento**: SSD (TRIM) vs HDD (Defrag programado)
5. **Servicios**: Solo demora los no críticos (WSearch, SysMain)
6. **Startup**: Mueve actualizadores a backup (no los elimina)
7. **UI**: Animaciones optimizadas para tu hardware
8. **Memoria Virtual**: Solo ajusta si RAM < 8GB
9. **Verificación**: Asegura Windows Update activo

## 🛡️ Características de Seguridad

### ✅ **Siempre hace backup:**
```powershell
# Registro modificado se guarda en:
HKCU/HKLM\Software\WindowsDeMente\Backup\

# Valores de inicio/apagado respaldados antes de modificar
```

### ✅ **No elimina, mueve:**
```powershell
# Entradas de startup sospechosas (updaters) se mueven a backup
# Puedes restaurarlas manualmente si necesitas
```

### ✅ **Modo de informe:**
```powershell
# Ejecuta primero con "N" para ver qué haría
# Sin cambios reales al sistema
```

### ✅ **Reinicio opcional:**
```powershell
# Pregunta antes de reiniciar
# Tienes 10 segundos para cancelar (Ctrl+C)
```

## 📈 Métricas y Logs

### 📊 **Comparativa Antes/Después:**
```
══════════════════════════════════════════════════════
Métricas antes:  CPU 12%, RAM libre 2048 MB
Métricas después: CPU 8%, RAM libre 2560 MB
Deltas: CPU -4% ; RAM +512 MB
══════════════════════════════════════════════════════
```

### 📝 **Logs detallados:**
```powershell
# Temporal: %TEMP%\WindowsDeMente_Logs\
# Escritorio: WindowsDeMente_Log_YYYYMMDD_HHMMSS.txt
```

## 🎯 ¿Por qué deberías notar mejoras?

### 🚀 **Arranque más rápido:**
- Menos programas en startup
- Servicios no críticos en "delayed start"
- Fast Startup optimizado para tu almacenamiento

### ⚡ **Multitarea mejorada:**
- Prioridades CPU ajustadas a tus núcleos
- TCP optimizado para tu tipo de conexión
- Pagefile personalizado si RAM es limitada

### 💾 **SSD más duradero:**
- TRIM habilitado
- Desfragmentación deshabilitada
- Prefetch/Superfetch ajustados

## ⚠️ Lo que NO hace (y eso es bueno)

### ❌ **NO:**
- Elimina system32 ni archivos críticos
- Deshabilita servicios esenciales
- Cambia configuraciones sin backup
- Instala software adicional
- Modifica seguridad del sistema
- Aplica "tweaks" no documentados

### ✅ **SÍ:**
- Respeta las decisiones de Windows
- Mantiene todo reversible
- Explica cada cambio
- Se adapta a tu hardware

## 🔄 Restauración

### Si algo no funciona bien:
```powershell
# 1. Los backups están en:
%USERPROFILE%\Documents\WindowsDeMente_Backup_YYYYMMDD\

# 2. Los valores de registro movidos están en:
HKCU\Software\WindowsDeMente\Backup\
HKLM\Software\WindowsDeMente\Backup\

# 3. Siempre puedes restaurar punto de sistema de Windows
```

## 🤔 Preguntas Frecuentes

### **¿Es seguro?**
Totalmente. No aplica tweaks peligrosos como `DisablePagingExecutive` o `LargeSystemCache` que otros optimizadores aplican ciegamente.

### **¿Necesito reiniciar?**
Solo si aplicas cambios. Puedes ejecutar en modo informe primero.

### **¿Funciona en Windows 10/11?**
Sí, ambas versiones son compatibles.

### **¿Puedo deshacer cambios?**
Absolutamente. Todo tiene backup y el script es no-destructivo.

### **¿Por qué no hay interfaz gráfica?**
Para ser ligero, rápido y ejecutable directamente en PowerShell sin instalación.

## 💡 Filosofía del Proyecto

### **"Optimización consciente" significa:**
1. **Analizar** antes de actuar
2. **Entender** tu hardware específico
3. **Aplicar** solo lo necesario
4. **Documentar** cada cambio
5. **Permitir** reversión fácil

### **Contra los "optimizadores agresivos":**
```powershell
# Ellos aplican: DisablePagingExecutive, IoPageLockLimit, etc.
# Nosotros: Detectamos y ELIMINAMOS esos tweaks peligrosos
# Resultado: Mayor estabilidad, menos pantallazos azules
```

## 📞 Soporte y Contribución

### **Reportar problemas:**
```powershell
# Incluye el log de: %TEMP%\WindowsDeMente_Logs\
# Y tu categoría detectada: ENTUSIASTA/EQUILIBRADO/ESTÁNDAR/LIVIANO
```

### **Para desarrolladores:**
El código está estructurado en funciones claras:
- `Get-Metrics` → Medición
- `Log` → Registro
- `Get-CPUInfoDetallada` → Análisis
- Cada fase es modular y auto-contenida

## 🎁 Características Únicas

### **Marcador de boot:**
```powershell
# Crea: %TEMP%\WindowsDeMente_Logs\WDM_boot_marker_TIMESTAMP.txt
# Para que midas manualmente si el arranque mejoró
```

### **Detección inteligente de proxy:**
```powershell
# Ajusta TCP diferente si usas proxy corporativo
# No asume que todos tienen conexión directa
```

### **Optimización para laptops:**
```powershell
# Detecta si es portátil
# Ajusta power plan para AC/batería
# Considera restricciones térmicas
```

## 🏁 Comenzar Ahora

```powershell
# Copia, pega, y deja que analice tu sistema:
"Tu PC no es un número en una base de datos. Es único."
"Windows ya es bueno. Solo necesita configuración apropiada."
"Menos es más. Especialmente en optimización."
```

## ⚖️ Licencia y Uso

### **Uso personal:** Libre y gratuito
### **Uso corporativo:** Notificar al autor
### **Redistribución:** Atribución requerida

**Descargo de responsabilidad:** Este script se proporciona "tal cual". El autor no se responsabiliza por daños. Siempre ten backup de tus datos importantes.

---

**✨ Windows de Mente v1.0**  
*Porque tu PC merece optimización consciente, no agresiva.*  
*Confía en Windows. Sabe lo que hace.*sistemas. Si te sirve, úsala. Si no, ignórala. Un saludo para todos

*— Vic*
