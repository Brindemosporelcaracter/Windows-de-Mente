# WindowsDeMente 2.0

Optimizador y diagnosticador inteligente para Windows 10 y Windows 11.

WindowsDeMente no aplica tweaks masivos ni configuraciones a ciegas.
Primero analiza el sistema, interpreta su estado real y solo aplica optimizaciones cuando son necesarias.

El objetivo es mejorar la fluidez, estabilidad y salud del sistema sin romper configuraciones ni sacrificar compatibilidad.

---

## Filosofía del proyecto

La mayoría de los optimizadores de Windows funcionan aplicando decenas de tweaks sin entender el estado del sistema.

WindowsDeMente sigue un enfoque diferente:

Diagnóstico completo
↓
Detección de anomalías
↓
Optimización solo cuando es necesario

Esto evita optimizaciones innecesarias y reduce el riesgo de romper configuraciones del sistema.

---

## Qué hace WindowsDeMente

### Diagnóstico inteligente

Analiza múltiples aspectos del sistema antes de optimizar:

* Hardware (CPU, RAM, tipo de disco)
* Estado del sistema Windows
* Servicios en segundo plano
* Latencia de registro y WMI
* Estado del disco
* Errores recientes del sistema
* Configuración de red
* Estado del arranque (Boot Performance)

También filtra automáticamente el ruido del Event Log para mostrar solo errores relevantes.

---

### Optimización adaptativa

Las optimizaciones se aplican solo cuando el diagnóstico detecta un problema.

Algunos ejemplos:

* Ajuste dinámico de prioridad de CPU según número de cores
* Optimización de efectos visuales en sistemas con poca RAM
* Eliminación de Network Throttling
* Corrección de configuraciones incorrectas del sistema
* Ajuste adaptativo del Prefetcher según tipo de disco
* Reducción de escrituras innecesarias en NTFS
* Ajuste dinámico de SystemResponsiveness según hardware
* Aislamiento del proceso de Explorer cuando la RAM lo permite

---

### Reparación del sistema

Incluye herramientas integradas de Windows:

* SFC con barra de progreso real
* DISM con seguimiento de porcentaje
* Diagnóstico de corrupción del sistema
* Detección de errores recientes críticos

---

## En qué se diferencia de otros optimizadores

WindowsDeMente evita prácticas comunes que pueden degradar el sistema:

No desactiva servicios críticos
No elimina el pagefile
No rompe la indexación del sistema
No aplica tweaks obsoletos de Windows XP/7

Las optimizaciones están pensadas específicamente para Windows 10 y Windows 11 modernos.

---

## Requisitos

* Windows 10 o Windows 11
* PowerShell 5.1 o superior
* Permisos de administrador

---

## Cómo usarlo

1. Ejecutar PowerShell como Administrador
2. Ejecutar el script principal

El programa realizará primero un diagnóstico completo antes de permitir optimizaciones.

---

## Advertencia

Aunque WindowsDeMente intenta aplicar solo cambios seguros, siempre es recomendable crear un punto de restauración antes de realizar optimizaciones del sistema.

---

## Estado del proyecto

Versión actual: 2.0

La versión 2.0 introduce mejoras importantes en diagnóstico, optimización adaptativa y herramientas de reparación del sistema.

El proyecto continuará evolucionando con nuevas capacidades de diagnóstico y optimización inteligente.

---

## Autor

Proyecto desarrollado por Vic.
