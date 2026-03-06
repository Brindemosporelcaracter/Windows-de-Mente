# 🧠 Windows De Mente v2.0

> Optimizador gratuito para Windows que **lee tu hardware primero** y decide qué cambiar según lo que realmente tiene tu PC — no una receta genérica copiada de internet.

---

## ¿Por qué existe esto?

Todos los optimizadores de Windows hacen lo mismo: aplican 200 tweaks de una lista sin preguntar nada. El resultado es una PC con 4GB de RAM donde el Bloc de Notas tarda 2 minutos en abrir porque alguien desactivó SysMain "para ganar rendimiento".

**Windows De Mente es diferente:**

- Detecta tu CPU, RAM, GPU, tipo de disco y si es laptop o desktop
- Solo aplica lo que tiene sentido para tu hardware específico
- Te explica en lenguaje simple qué hace cada cambio y por qué
- Guarda un backup completo antes de tocar cualquier cosa
- Tiene un botón para deshacer todo si algo no te gusta

---

## ✨ Funcionalidades

### 🔍 Análisis de Hardware Real
Detecta automáticamente CPU (Intel/AMD/ARM), RAM total, tipo de disco (SSD/HDD/NVMe), GPU (NVIDIA/AMD/Intel), si es laptop o desktop, y versión exacta de Windows.

### ⚙️ Optimizaciones Condicionales
Más de 40 optimizaciones que solo se aplican cuando tienen sentido:
- `DisablePagingExecutive` → solo con 8GB+ de RAM (con menos causa lentitud extrema)
- `SysMain` → solo se desactiva en SSD con 8GB+ (en HDD es quien precarga tus programas)
- `HAGS` → solo con GPU dedicada NVIDIA/AMD (en GPU integrada Intel causa parpadeo)
- `PowerThrottling` → conservado en laptops (gestiona batería y temperatura)

### 📋 Cuatro tabs de acción

| Tab | Qué hace |
|-----|----------|
| ⚙️ **Optimizaciones** | CPU, RAM, disco, red, GPU — ajustado a tu hardware |
| 🧹 **Limpieza** | Archivos temporales, caché, logs — con tamaño real antes de borrar |
| 🛡️ **Privacidad** | Telemetría, publicidad, Copilot, Recall, historial de actividad |
| 🖥️ **Uso Diario** | Explorador, estética, barra de tareas, menús — lo que los optimizadores rompen |

### 🎨 Restauración Estética Inteligente
Detecta qué valores estéticos fueron modificados por otros programas y los restaura al estado original de Windows: animaciones, ClearType, transparencias Aero, Snap Layouts, menú contextual de Win11, velocidad de menús.

### 🏥 Tab de Salud del Sistema
10 verificaciones: espacio en disco, temperatura, actualizaciones pendientes, drivers, integridad del sistema (SFC), errores recientes, y más.

### 📊 Score de Optimización
Puntaje de 0 a 100 que refleja el estado real de tu sistema antes y después.

### 🔄 Backup y Restauración
Backup automático de todas las claves de registro antes de cualquier cambio. Restauración con un clic desde el tab de historial.

### 🔬 Diagnóstico de Red
Análisis completo de tu conexión: perfil de red, DNS activo, proxy, velocidad de adaptador, IPv6 — sin modificar nada, solo informar.

---

## 🖥️ Requisitos

| Requisito | Mínimo |
|-----------|--------|
| Windows | 10 (21H2+) o Windows 11 |
| PowerShell | 7.x (recomendado) o 5.1 |
| RAM | 2 GB |
| Permisos | Administrador |

---

## 🚀 Instalación y Uso

### Opción A — Ejecutable (recomendado)
1. Descargá `WindowsDeMente.exe` desde [Releases](../../releases)
2. Doble clic → aceptá el UAC → listo

### Opción B — Script directo
1. Descargá `WDM-V2.0.ps1`
2. Clic derecho → *Ejecutar con PowerShell* → aceptá UAC

### Opción C — Compilar vos mismo
1. Colocá `WDM-V2.0.ps1` y `COMPILAR-A-EXE.ps1` en la misma carpeta
2. Clic derecho en `COMPILAR-A-EXE.ps1` → *Ejecutar con PowerShell*
3. Esperar ~60 segundos → se genera `WindowsDeMente.exe`

> ⚠️ Algunos antivirus marcan el .exe como sospechoso (falso positivo conocido de PS2EXE). Es esperable — el código fuente está acá para verificarlo.

---

## 📸 Capturas

*(próximamente)*

---

## 🤔 Preguntas frecuentes

**¿Modifica archivos del sistema?**
No. Solo modifica claves de registro en `HKCU` y `HKLM`, y configura servicios de Windows. No toca archivos `.dll`, `.exe` ni nada del sistema operativo.

**¿Puedo deshacerlo todo?**
Sí. Antes de aplicar cualquier cambio, WDM guarda un backup completo. El tab de Historial tiene un botón "Restaurar todo" que revierte cada valor al estado anterior.

**¿Por qué necesita ser administrador?**
Algunas optimizaciones escriben en `HKLM` (registro del sistema) y configuran servicios de Windows, lo que requiere permisos elevados.

**¿Funciona en Windows 10?**
Sí. Las optimizaciones específicas de Windows 11 (menú contextual moderno, Snap Layouts, Widgets) se detectan automáticamente y solo aparecen si el sistema es Win11.

**¿Qué pasa si tengo 4GB de RAM?**
WDM detecta la RAM y omite los tweaks que serían contraproducentes: no desactiva SysMain, no fuerza el kernel en RAM física, y conserva PowerThrottling. La optimización se adapta a lo que realmente tiene tu PC.

---

## 🧱 Arquitectura

```
WDM-V2.0.ps1
├── Detección de Hardware (Get-HardwareProfile)
│   ├── CPU: vendor, núcleos, velocidad
│   ├── RAM: total GB, canales
│   ├── Disco: SSD/HDD/NVMe por volumen
│   ├── GPU: NVIDIA/AMD/Intel, VRAM
│   └── Tipo: laptop/desktop, versión Windows
│
├── Sistema de Optimizaciones Condicionales
│   ├── Add-Optimization (con condición, checkstatus, backup)
│   ├── Get-OptimizationsList (filtra según hardware)
│   └── 40+ funciones Optimize-* / Check-*
│
├── GUI (WinForms)
│   ├── Tab Optimizaciones
│   ├── Tab Limpieza
│   ├── Tab Privacidad
│   ├── Tab Uso Diario
│   ├── Tab Salud
│   ├── Tab Diagnóstico
│   └── Tab Historial
│
└── Sistema de Backup/Restore
    ├── Save-OriginalValue (por clave)
    ├── Backup-CriticalRegions (previo a todo)
    └── Restore-AllValues (reversión completa)
```

---

## 🙏 Filosofía

WDM nació de ver cómo optimizadores populares dejaban PCs peores que antes. La filosofía es simple:

1. **Primero entender, después actuar** — nada se aplica sin leer el hardware
2. **Educación, no magia** — cada cambio tiene una explicación en lenguaje simple
3. **Reversible siempre** — si algo sale mal, hay vuelta atrás
4. **Conservador con lo que no se entiende** — si un tweak puede dañar en algún caso, no se aplica

---

## 📄 Licencia

MIT — libre para usar, modificar y distribuir.

---

## 💬 Contribuciones

Issues y PRs bienvenidos. Si encontrás que un tweak causa problemas en algún hardware específico, abrí un issue con el modelo de CPU/RAM/disco y el síntoma — es exactamente el tipo de feedback que mejora la herramienta.
