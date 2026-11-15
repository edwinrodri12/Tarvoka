# TARVOKA Base Aérea V6 — acabado arquitectónico y comparación 3D

## Objetivo
Continuar el **desarrollo visual** del edificio (no el laboratorio de FPS). Esta revisión mantiene íntegros la base V1, el hangar V2, la pista alineada y los impactos V3, así como el humo/fuego y los LOD V4. El trabajo continúa siendo **geometría 3D real de Godot 4.3**, editable en `scripts/ui/AirbaseExteriorV6.gd`, no un concepto 2D.

### Acabados añadidos
- **Hangar:** fachada lateral panelizada, juntas de chapa, canalones y franja de identidad de facción. Las juntas de la cubierta siguen la curvatura sinusoidal de la bóveda existente y no vuelven a cerrar huecos destruidos.
- **Pista y pavimento:** flecha de rodaje, bordes reforzados, drenajes de seguridad y marca de acceso técnico. Las nuevas marcas permanecen alineadas con `Airbase3DV1.HANGAR_CENTER_X` y la línea V3 del umbral, sin crear otra pista.
- **Torre de control:** nervaduras, visera, cristal delantero y una baliza emisiva de bajo coste sin añadir luces dinámicas.
- **Patio técnico:** armarios, placas y señalización visible a zoom táctico.
- **Daño:** las roturas de la cubierta no se recubren con material intacto; la destrucción final recibe únicamente vigas y placas de ruina, sin reconstruir el edificio.

### Prueba en el estudio
En `Edificios 3D → Base Aérea · V4/V6` se añadió **«V6 · fachadas, cubierta, torre y pavimento (comparar V4)»**, activado por defecto. Desmárcalo para comparar exactamente el modelo V4, con la misma facción, nivel y estado de daño. Los controles existentes de abrir/cerrar el hangar, vista interior, lluvia/nieve, impacto de bala/explosión, calidad Android y escenarios de 8/32/64 edificios siguen disponibles.

En la vista de muchas bases el acabado V6 se añade solamente a las cuatro bases cercanas, mientras que las lejanas conservan el proxy LOD V4 real. Así el acabado no se duplica sobre modelos completos invisibles.

## QA
El nuevo test `tests/test_airbase_v6_exterior_visual_gpu.gd` recorre 40 combinaciones de facción × daño y los tres niveles, verifica el montaje sin duplicar, el portón original de veinte mallas, los cinco niveles de daño, clima nevado, LOD y el retorno al Cuartel General. La ejecución GPU de Godot genera capturas PNG **antes/después** y de hangar abierto, daños y nieve. El workflow es `.github/workflows/airbase-v6-exterior-visual-gpu.yml`.

**Estado:** el código de V6 está propuesto en GitHub. Sólo se podrá afirmar que el visor web está actualizado después de completar QA y desplegar la nueva fuente de la página; no es una APK ni se han modificado reglas de partida.
