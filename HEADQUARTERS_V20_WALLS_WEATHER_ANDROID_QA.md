# TARVOKA — Cuartel General V20 · Reparación estructural, clima web y benchmark Android real

## Hallazgos y corrección del visor publicado

**Causa concreta de la falla de lluvia/nieve:** en `scripts/ui/CombinedArtStudioWeb.gd`, las operaciones `HQClimateV17.apply`, `HQWayfindingV18.apply` y `HQFacadeV19.apply` estaban dentro de `assert(...)`. Godot elimina esas evaluaciones en exportación *release*, precisamente la modalidad WebGL que se publica en TARVOKA Studio 3D. La UI cambiaba la selección, pero la acción visual no se ejecutaba. V20 realiza cada operación fuera de las aserciones, guardando el booleano y comprobándolo por separado en debug. Ninguna función visual se apoya ahora en el efecto secundario de `assert`.

**Paredes aparentemente ausentes:** las galerías laterales originales terminaban en z=−1.73, mientras los miradores V12 y arcos reales estaban cerca de z=−3.117. En V20 se crean cuatro cierres estructurales 3D como geometría de `Headquarters3D._building()`:
- Dos muros continuos bajo miradores, de 2.30 × 2.86 × 1.34 metros, con cara frontal z=−3.06 **detrás** del vidrio que está en z≈−3.117. Su parte posterior se superpone a las galerías, evitando ranuras con visión al vacío.
- Dos encuentros estrechos entre alas y cuerpo central, fuera de la zona de ventanas originales. Todas las superficies son volúmenes 3D auténticos.
- No se colocan sobre el escudo oficial, acceso frontal ni el radar. En estado destruido sólo se generan las ruinas apropiadas.

**Clima visible a la distancia de estudio:** lluvia pasa a 132 trazos y nieve a 108 copos, con anchura/tamaño más legible a distancia normal. Se conservan dos *mesh batches* de precipitación, sin cientos de nodos, luces extras, partículas CPU, colisiones, movimientos de tropas ni cambios en reglas de clima. El recubrimiento universal sobre el edificio continúa siendo reversible y se aplica en WebGL release. La imagen horneada V15 de Android permanece seca; lluvia y nieve se representan alrededor de ella, no sobre sus píxeles prehorneados.

## Pruebas automatizadas

- `tests/test_hq_v20_walls_weather_release.gd`: valida cierre de paredes y su posición detrás de cristales en niveles 1/2/3; ausencia de muros en ruinas; detecta regresión de aserciones en GDScript y verifica efecto visual verdadero desde la cámara (diferencias de píxeles claros/lluvia/nieve, metadatos y material mojado/copos), retorno a despejado, V18/V19, LOD, ocho escudos y sprite V15.
- `.github/workflows/hq-v20-walls-weather-gpu.yml`: Godot 4.3 OpenGL CI, guarda capturas y falla si no existe evidencia.
- El exportador TARVOKA Studio 3D debe superar exportación WebGL *release* y GitHub Pages build/deploy antes de afirmar que el visor público contiene V20.

## Plan reproducible de medición física Android

El APK diagnóstico **TARVOKA HQ Benchmark** tiene paquete independiente `com.edwinrodri12.tarvoka.hqbenchmark`, sin interferir con una instalación TARVOKA normal, y utiliza un renderer Godot GL compatibility en un teléfono real. No se utiliza un simulador de juego para inventar números de FPS.

Mide en cuatro escenarios: 1 HQ V20 con geometría detallada y clima conmutable; 49, 100 y 144 HQ de distrito, usando `HeadquartersCityBatch3D` compartido (sin instanciar 144 HQ hero). Cada escenario cuenta con 5 s de estabilización + 20 s de muestras, durante 3 rondas. Cada muestra de tiempo real sale de `_process(delta)`; el resultado incluye FPS medio y promedio del 1 % de cuadros más lentos, peor frame time en ms, tiempo de proceso informativo, dispositivo y resolución.

El diagnóstico imprime `TARVOKA_HQ_PHYSICAL` en logcat y guarda en `user://tarvoka_hq_physical_benchmark.csv`. El botón **COPIAR RESULTADOS CSV** lo lleva al portapapeles para pegarlo en este chat. Requiere ejecutar la prueba físicamente; un build CI nunca constituye una medición del teléfono ni de la temperatura.

Workflow `.github/workflows/hq-v20-physical-android-apk.yml` firma APK de depuración ARM64 con clave desechable en PR, lo verifica con apksigner y produce artefacto instalable separado. No altera APK comercial.

**Criterios provisionales para una discusión de calidad**, no resultados: ≥45 FPS promedio y ≥30 FPS 1 %-low en cada distrito, sin congelamientos y sin degradación acusada entre primera y tercera rondas; objetivo aspiracional de 60 FPS en hardware de gama media-alta. Para lanzamiento falta probar variedad real de móviles de gama baja, sostenibilidad térmica, batería, niebla, unidades, IA y mapas completos 8 jugadores.

## Seguridad de integración

El trabajo V20 del cuartel está aislado en su rama 3D; no altera bases del tanque G09, terrenos V15b, economía, combate, guardados ni multijugador. El visor se publica cambiando únicamente la fuente HQ del workflow `tarvoka-3d-pages.yml` de `main`, protegiendo los subvisores independientes.
