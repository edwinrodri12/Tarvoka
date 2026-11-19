# Cámara orbital aislada para inspección 3D — 2026-11-18

Archivo: `scripts/tools/AssetOrbitCamera.gd`.

## Uso reversible
Crear una escena de inspección independiente con un Node3D, adjuntar el script, colocar el modelo 3D como hermano y habilitar `input_enabled` en el inspector. Clic derecho y arrastrar: orbitar; rueda: acercar/alejar. También admite llamadas explícitas `orbit()`, `zoom()` y `set_inspection_target()` desde controles táctiles externos. La cámara se crea automáticamente como hija `InspectionCamera` si no existe. **No conectar esta herramienta al tablero táctico sin una revisión de eventos**.

## Comprobaciones reproducibles pendientes
1. Godot 4.3: abrir escena aislada, comprobar parseo y orientación hacia el objetivo.
2. Distancia inicial 8, límites 2–24: comprobar zoom extremo sin atravesar el objeto.
3. Orbitar repetidamente: pitch acotado a ±1.4 rad; yaw envuelto en ±PI.
4. Deshabilitar input: confirmar que no consume gestos tácticos del juego.
5. Cambiar target/radio: comprobar encuadre sin modificar escena del modelo.
6. En Android: **NO EJECUTADO EN DISPOSITIVO**; no se declara FPS, legibilidad ni soporte táctil final.
7. Integración visual con el visor web: **PENDIENTE DE REVISIÓN VISUAL**; esta utilidad es solo Godot, no altera el visor web.

## Alcance
Prototipo reversible para inspección y futura reutilización, no una función ya integrada al visor. Sin cambios a IA, reglas, facciones, guardados, exportación o escenas existentes. No se entrega APK.

## Incremento de escena aislada y smoke test (2026-11-18)
- `scenes/tools/AssetInspectionSmoke.tscn`: escena independiente con esfera original de referencia, luz direccional y `OrbitRig` habilitado para mouse. No se conecta a la UI táctica ni al visor web.
- `tests/test_asset_orbit_camera.gd`: prueba automatizada de carga de escena, creación de Camera3D, zoom mínimo/máximo, límites angulares y enfoque en otro objetivo.
- Ejecutar desde raíz del proyecto con Godot 4.3: `godot --headless --path . --script res://tests/test_asset_orbit_camera.gd`.
- **NO EJECUTADO** en Godot local al registrar el cambio. El CI general puede pasar sin ejecutar este script específico. **NO EJECUTADO EN DISPOSITIVO**. **PENDIENTE DE REVISIÓN VISUAL**.
- La escena es deliberadamente reversible y no contiene modelos finales de facciones; reemplazar la esfera solo tras confirmar controles y encuadre.

## CI aislado incorporado (2026-11-18)
- Workflow: `.github/workflows/asset-orbit-camera.yml`; se activa por PR/push al modificar escena, cámara, prueba o workflow; también admite ejecución manual.
- Descarga Godot 4.3 oficial en Ubuntu 22.04, ejecuta `tests/test_asset_orbit_camera.gd` con límite de 80 s y exige la marca `PASS: isolated asset orbit camera smoke` sin errores del motor.
- **PASÓ:** creación del workflow y commit en rama de PR #602. **NO CONFIRMADO:** resultado de Actions para este commit hasta revisar la ejecución. **NO EJECUTADO EN DISPOSITIVO**; **PENDIENTE DE REVISIÓN VISUAL**.
- Esta comprobación no demuestra calidad visual ni controles táctiles Android y no altera el juego.

## 2026-11-18 — encuadre de jerarquías reales
- `frame_asset(asset: Node3D) -> bool` recorre MeshInstance3D hijos, calcula ocho esquinas por malla con transformación global y encuadra el AABB combinado. Permite piezas rotadas o desplazadas sin alterar sus transformaciones. Devuelve false sin cambiar cámara si no hay mallas.
- Regresión añadida: pieza BoxMesh desplazada/rotada y jerarquía vacía.
- PASÓ: commits en rama PR #602. **NO CONFIRMADO:** Godot/CI de estos nuevos commits. **NO EJECUTADO EN DISPOSITIVO**; **PENDIENTE DE REVISIÓN VISUAL**. No modifica visor web ni escenas tácticas.


## 2026-11-19 — Escena de inspección con encuadre automático
- `scripts/tools/AssetInspectionPreview.gd` conecta `SampleAsset` con `OrbitRig.frame_asset()` tras entrar en el árbol. Se mantiene aislada de la batalla y de la UI táctil.
- `scenes/tools/AssetInspectionSmoke.tscn` usa ese controlador: al sustituir `SampleAsset` por un modelo 3D, la cámara centra sus mallas automáticamente.
- `tests/test_asset_orbit_camera.gd` comprueba centro y distancia calculada desde el AABB de la esfera antes de probar el control manual.
- **Godot CI para este commit: NO CONFIRMADO. Android físico: NO EJECUTADO EN DISPOSITIVO. Revisión visual: PENDIENTE.**

## 2026-11-19 — Corrección de parseo en CI
- Run [44463098593](https://github.com/edwinrodri12/Tarvoka/actions/runs/44463098593): **FALLÓ** en Godot 4.3 headless. `AssetInspectionPreview.gd:5` no resolvía el tipo global `AssetOrbitCamera` al ejecutar directamente `--script tests/test_asset_orbit_camera.gd`; después falló el encuadre porque el controlador no cargó.
- Corrección: usar referencia de nodo inferida `@onready var orbit_rig = $OrbitRig` en la escena aislada. El script del nodo sigue siendo `AssetOrbitCamera.gd`, sin modificar controles del juego ni su comportamiento.
- Validación de la corrección: **NO CONFIRMADA** hasta recibir nuevo resultado del workflow. Android físico: **NO EJECUTADO EN DISPOSITIVO**. Revisión visual: **PENDIENTE**.

## 2026-11-19 — CI teardown de mallas
- Run [44469598701](https://github.com/edwinrodri12/Tarvoka/actions/runs/44469598701): **FALLÓ** pese a imprimir `PASS: isolated asset orbit camera smoke`; Godot 4.3 dummy renderer emitió `ERROR: Parameter "m" is null` en `mesh_get_surface_count` durante cierre de escena.
- Cambio acotado: tras `scene.queue_free()`, esperar dos `process_frame` antes de imprimir PASS y llamar `quit(0)` para dar tiempo a liberar recursos. Es una hipótesis de corrección de teardown, **no una prueba aprobada** hasta CI del commit nuevo.
- Si persiste, inspeccionar el orden de liberación de `MeshInstance3D` y evaluar ejecutar este smoke con renderizador OpenGL/Xvfb; no suprimir indiscriminadamente errores de Godot.
- Android físico: **NO EJECUTADO EN DISPOSITIVO**. Revisión visual: **PENDIENTE**. No se cambió el motor táctico ni la escena Android.

## CI 2026-11-19: renderizador virtual

El run [44476712293](https://github.com/edwinrodri12/Tarvoka/actions/runs/44476712293) imprimió `PASS: isolated asset orbit camera smoke`, pero también `ERROR: Parameter "m" is null` en `mesh_get_surface_count` del renderizador dummy (antes y después del PASS). Por tanto **FALLÓ CI**: las aserciones no justifican ignorar errores del motor.

Cambio reversible: el workflow ejecuta la escena bajo `xvfb-run` con Godot 4.3 y `--rendering-method gl_compatibility`, usando Mesa software en Linux, en vez de `--headless` (dummy). Mantiene `pipefail`, timeout y rechazo explícito de errores. Si falla por contexto gráfico, revisar logs y revertir o corregir el entorno; no marcar como PASÓ sin run verde. Esto **no es** prueba Android física ni aprobación visual del modelo.
