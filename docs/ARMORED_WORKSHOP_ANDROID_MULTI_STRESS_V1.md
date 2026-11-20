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
