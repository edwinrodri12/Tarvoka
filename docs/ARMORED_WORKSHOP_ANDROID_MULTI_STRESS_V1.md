# TARVOKA — Taller de Blindados, estrés de múltiples edificios 3D

## Qué verifica

Esta prueba utiliza modelos 3D reales del Taller de Blindados V2 Android en Godot **4.3** y el renderizador **GL Compatibility**. La geometría visual procede de `ArmoredWorkshopBattlePreview3D.gd`, con escala de 2,4 m por casilla, y conserva los materiales de las facciones, alturas N1–N3 y estados de daño D0–D4.

`tests/test_armored_workshop_android_multi_stress.gd` genera cuatro escenas:

| Caso | Talleres en pantalla | LOD |
| --- | ---: | --- |
| 12_tactical | 12 | TÁCTICO |
| 24_mixed | 24 | 12 TÁCTICO / 12 DISTANTE |
| 48_distant | 48 | DISTANTE |
| 48_tactical | 48 | TÁCTICO |

El caso mixto además realiza **dos cambios de LOD por edificio (48 transiciones)**, confirmando que el nodo raíz y la posición de cada taller son estables, y que las piezas físicas de los talleres no crean reglas de economía, suministro o combate.

Se comprueban estructuralmente los presupuestos de GPU del código: **hasta 11 `MultiMeshInstance3D` por taller y 115 cajas instanciadas** como máximo, con recursos compartidos. En las escenas de 48 talleres, el modo distante debe utilizar menos lotes que el táctico. Estos recuentos estructurales no equivalen directamente a llamadas de dibujo observadas porque Godot también realiza frustum culling, pases de sombras y agrupación interna.

## Instrumentación realmente medida

El script genera **cuatro PNG** y un `manifest.json` con el recuento real de llamadas de dibujo del `SubViewport` a partir de `RenderingServer.viewport_get_render_info`; además captura el tiempo de renderizado CPU y, cuando el controlador lo informa, GPU, durante cinco fotogramas por caso. Incluye tiempo de construcción de la escena y cantidad de píxeles visuales detectados.

**Importante:** GitHub Actions utiliza Ubuntu 22.04 + Mesa OpenGL por software, a 960 × 640 píxeles. Estas mediciones son comparaciones de regresión bajo condiciones de CI, **no FPS, batería, temperatura ni rendimiento físico en Android**. Un resultado `0` del medidor GPU en ese controlador significa ausencia de medición disponible, no costo cero.

## Decisiones de rendimiento

- Mantener materiales `StandardMaterial3D` cacheados y el `BoxMesh` compartido entre instancias de un mismo perfil.
- Preservar los AABB conservadores de cada `MultiMesh` para no ocultar fachadas completas en zoom o giro de cámara.
- Cambiar únicamente el modelo central mediante `ArmoredWorkshopBattleTile3D.set_preview_detail`, sin reconstruir casillas.
- La histéresis de pantalla debe retener el último LOD en el intervalo de **112–152 px** y mantener la versión HERO fuera de la vista de mapa.
- No añadir edificios de suministro redundantes ni tocar unidades logísticas, reglas o economía.

## Criterios para pruebas físicas pendientes

Antes de considerar el Taller comercialmente apto para Android: instalar un build de prueba en un dispositivo real con GPU móvil, reproducir las cuatro densidades de edificios, probar cambio de zoom repetido, mirar tiempos p50/p95, uso de memoria, calentamiento y si hay desaparición de fachadas. Comparar usando la misma resolución, carga de batalla, tipo de dispositivo y parámetros de iluminación. Ninguna prueba CI sustituye esta comprobación física.

**Estado:** código y QA disponibles en la rama artística/PR #629. El Taller continúa sin aprobación artística y no se fusiona al motor de batalla.

## Primera medición real del proceso de CI (Godot Mesa OpenGL)

La ejecución [#44659704605](https://github.com/edwinrodri12/Tarvoka/actions/runs/44659704605) terminó **SUCCESS** y generó 4 PNG de estrés. Datos del `manifest.json` exportado, **antes** del pequeño aumento posterior de una franja de facción por bahía del perfil táctico:

| Escenario | Lotes MultiMesh | Cajas instanciadas | Llamadas de dibujo observadas |
| --- | ---: | ---: | ---: |
| 12 tácticos | 96 | 497 | 367 |
| 24 mixtos | 160 | 753 | 588 |
| 48 distantes | 271 | 1.196 | 1.032 |
| 48 tácticos | 371 | 1.808 | 1.414 |

A densidad idéntica de 48 edificios, DISTANTE ahorra **100 lotes (27 %)**, **612 cajas (34 %)** y **382 draw calls observadas (27 %)** respecto a TÁCTICO. Los 24 edificios del escenario mixto completaron 48 intercambios de detalle manteniendo sus posiciones.

El hardware de CI reportó (mediana aproximada de cinco muestras) tiempos de render CPU **8,3 ms DISTANTE vs 11,0 ms TÁCTICO** y tiempos de render GPU del controlador Mesa **15,2 ms vs 19,2 ms**. El caso inicial de 12 talleres devolvió 0 ms en el monitor, por lo que NO debe interpretarse como coste cero ni como medición comparable. Estas cifras **NO son estimaciones de FPS de Android**; el controlador Mesa software, la población en pantalla, sombras y el renderizador móvil difieren de un dispositivo real.

### Hallazgo visual y retoque posterior

En las cuatro capturas 960×640 la facción se reconoce mejor desde arriba en DISTANTE que en TÁCTICO. Se modificó la geometría móvil para dar **una franja de facción visible desde el techo por bahía también al perfil TÁCTICO**; reutiliza el mismo material y lote `faction`, por lo que el número de llamadas GPU agrupadas debe permanecer estable, aunque aumenta ligeramente el número de cajas instanciadas. La prueba de 270 variantes verifica explícitamente las marcas por bahía en techo.

Esta última corrección tiene que volver a pasar el workflow antes de aprobar los números posteriores. El Taller conserva `workshop_approved=false` y no se fusiona en el juego principal.

## Nueva medición tras reforzar el color de facción del techo

La validación definitiva [Actions #44660058307](https://github.com/edwinrodri12/Tarvoka/actions/runs/44660058307) terminó **SUCCESS** con 70 imágenes PNG (incluidas 4 de densidad múltiple), pruebas de 270 perfiles Android y 48 transiciones de detalle.

| Escenario | Lotes MultiMesh | Cajas instanciadas | Draw calls del viewport |
| --- | ---: | ---: | ---: |
| 12 TÁCTICO | 96 | 514 | 367 |
| 24 MIXTO | 160 | 768 | 588 |
| 48 DISTANTE | 271 | 1.196 | 1.032 |
| 48 TÁCTICO | 371 | 1.868 | 1.414 |

A la misma densidad de 48 talleres, la vista DISTANTE reduce **382 draw calls (≈27,0 %)**, **100 lotes (≈27,0 %)** y **672 cajas (≈36,0 %)** en relación con la TÁCTICA. La nueva franja de color del techo aumentó las cajas tácticas, pero **no agregó ni un solo lote GPU ni una llamada de dibujo** en las escenas comparadas. Las nuevas capturas muestran que el color de facción es más fácil de identificar desde el mapa en ambos perfiles.

Los tiempos reportados por el controlador software variaron considerablemente con la carga de CI: las medianas de la nueva ejecución fueron **18,7 vs 23,0 ms CPU** y **31,2 vs 38,2 ms GPU** entre los casos de 48 DISTANTE y 48 TÁCTICO, respectivamente. No extrapolar estos números a FPS de teléfono. El caso de 12 TÁCTICO siguió con monitor de tiempo en cero y debe quedar como medición ausente.

**Conclusión:** la geometría mantiene un costo escalable y no aparece un problema de render ni de visibilidad en los escenarios de prueba. La carga física Android (p50/p95, temperatura, RAM, GPU real) continúa pendiente. PR #629 permanece en borrador y las reglas jugables permanecen sin modificaciones.
