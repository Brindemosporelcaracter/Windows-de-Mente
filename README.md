# 🧠 Windows de Mente v1.0 - Optimización Consciente de Windows

## 📖 ¿Qué es esto?
**Windows de Mente** no es otro "optimizador mágico" que promete milagros. Es una herramienta **consciente** que primero **analiza tu hardware específico** y solo después aplica ajustes **seguros y documentados**. 

La filosofía es simple: **"Guidance, not force"** (Guía, no fuerza). No forzamos configuraciones peligrosas; adaptamos Windows a TU hardware.

## ✨ Características

✔ Diagnóstico avanzado de:
- CPU (temperatura, throttling, DPC)
- Memoria (hard faults, commit, pool)
- Disco (cola, saturación, TRIM)
- Red (drivers, latencia, Nagle, AutoTuning)
- Servicios y tareas huérfanas
- Drivers sin firma o legacy
- Configuración de Windows
- Carga real del sistema (runtime)

✔ Generación automática de fixes según problemas detectados  
✔ Punto de restauración antes de optimizar  
✔ Confirmación manual antes de aplicar cambios  
✔ Reporte exportado a CSV  
✔ No desinstala software  
✔ No desactiva servicios críticos  
✔ No toca Defender agresivamente  
✔ No “debloatea” a lo loco  

---

## 🧩 Fases del Script

### 🟦 FASE 0 – Diagnóstico
Analiza:
- Hardware
- Errores críticos
- Rendimiento real
- Configuración del sistema
- Servicios, tareas y restos huérfanos

Genera un reporte detallado:

WindowsDeMente_Diagnostico_YYYYMMDD_HHMMSS.csv
### 🟨 FASE 1 – Generación de Fixes
A partir de los problemas reales detectados, genera comandos correctivos como:
- TRIM deshabilitado
- TCP mal configurado
- Timeout de boot alto
- AutoTuning apagado
- NTFS sucio

⚠️ No aplica nada automáticamente sin mostrarlo antes.

---

### 🟩 FASE 2 – Optimización
- Crea punto de restauración
- Muestra lista de cambios
- Pide confirmación
- Aplica solo fixes seguros
- Opción de reinicio

---

## 🖥 Requisitos

- Windows 10 / 11  
- PowerShell 5.0 o superior  
- Ejecutar como **Administrador**

---

## ▶️ Uso

1. Abrir PowerShell como administrador  
2. Copiar y pegar el script completo  
3. Ejecutar  
4. Esperar el diagnóstico  
5. Revisar resumen  
6. Confirmar optimización si se desea  

---

## ⚠️ Advertencia

Este script:
- ❌ No es magia  
- ❌ No convierte PCs viejas en gaming PCs  
- ❌ No reemplaza mantenimiento físico  

✔ Sirve para:
- Detectar cuellos de botella
- Corregir configuraciones erróneas
- Limpiar restos lógicos
- Mejorar estabilidad

---

## 🧠 Diferencia frente a “optimizers” comerciales

| Windows de Mente | Optimizers comerciales |
|------------------|------------------------|
| Analiza primero | Aplica tweaks a ciegas |
| No borra servicios críticos | Rompen Windows |
| Reporte transparente | Caja negra |
| Cambios reversibles | Cambios permanentes |
| Educativo | Marketing |
| Open Source | Cerrados |

---

## 📂 Archivos generados

- `WindowsDeMente_Diagnostico_*.csv`  
- `WindowsDeMente_Fixes_*.csv`

---

## 📜 Licencia

Uso libre bajo responsabilidad del usuario.  
Este proyecto tiene fines educativos y técnicos.

---

## 👨‍💻 Autor

**Windows de Mente**  Vic
Desarrollado como proyecto de optimización consciente de Windows.

---

## 🧪 Estado del proyecto

🟢 Estable (v1.0)  
🔧 En evolución  
📈 Futuras versiones:
- v1.1 (mejoras internas)
- más validaciones
- más detección de errores reales

---

⭐ Si te resulta útil, dejá una estrella en el repo  
🐞 Issues y sugerencias son bienvenidas
