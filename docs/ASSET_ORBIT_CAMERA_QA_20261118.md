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
