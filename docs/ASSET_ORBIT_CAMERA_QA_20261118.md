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
