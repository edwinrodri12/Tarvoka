# TARVOKA — Helicóptero A01, Estudio 3D V9 · interfaz Android horizontal

**Estado:** revisión de interfaz, PR #457. Geometría y mecánicas de combate V1–V8 intactas.

## Problema confirmado por revisión del código
El Estudio Web genera el visor y el panel en `UnitArtStudioWeb.gd` y decide HBox/VBox **sólo en la construcción inicial** (ancho ≥770). En una pantalla horizontal de ~960×540, el panel lateral conserva una lista técnica muy extensa que desplaza los botones del A01 hacia abajo, dificultando el acceso a la inspección sin desplazamiento constante. La cámara ortográfica empleaba `preview_frame_height` independiente de la relación de aspecto visible, por lo que el rotor o la cola podían quedar cortados en un canvas estrecho.

## V9 aplicada a `scripts/ui/BastionStudioAdapter.gd`
- Barra `A01V9_AccesoHorizontalAndroid` insertada inmediatamente después del selector de modelos. Disponible sólo para `attack_heli` en formato apaisado corto (≥770 px de ancho; ≤740 alto; relación ≥1,3).
- Seis acciones de un toque: helicóptero completo, alas/motores, patines/soportes, disparo real animado, comparación V7/V8 y giro de 45°.
- Botón de expandir/plegar la lista técnica (V2–V8). Por defecto en horizontal sólo se muestra la barra compacta; en portrait o escritorio se mantiene el listado completo anterior.
- Actualización real al girar la pantalla mediante la señal `Viewport.size_changed`. Se reorganiza únicamente el `HBoxContainer`/`VBoxContainer`; el `SubViewport`, `Camera3D` y modelo 3D **siguen siendo las mismas instancias**; no se duplican cientos de mallas ni se pierden animaciones.
- Encuadre ortográfico adaptado al área real del visor, con límite para diámetro de rotor y longitud de cola. Sin modificar la cámara de G11, el Bastión, otros edificios ni el juego Android.
- El botón `Helicóptero completo` restaura yaw=35°, tilt=17°, zoom=1.0.

## Validación de experiencia real
`tests/test_attack_helicopter_v9_studio.gd` carga el mismo `scenes/UnitArtStudioWeb.tscn` combinado utilizado por GitHub Pages y comprueba:
1. Aspecto real 960×540 con A01 V8, barra rápida visible, técnicos plegados y cámara ortográfica.
2. Apertura/cierre de controles detallados, disparo real y comparación V7/V8.
3. Rotación a 540×960 y vuelta a 960×540 sin reconstruir el helicóptero ni cambiar de modelo.
4. Cambio a Bastión y desaparición de los controles exclusivos A01.
5. Cuatro capturas reales desde la ventana Godot, almacenadas por el flujo `a01-v9-studio-qa.yml`.

Se monta la misma escena de la rama de Estudio `feat/infantry-barracks-v1-three-distinct-levels-20261116` y se sobreponen los **81 scripts `scripts/ui/` correspondientes a main**; no se fabrica una escena nueva que ocultaría errores reales. La validación depende del resultado de GitHub Actions y no equivale a una prueba física en un teléfono Android.

**Próxima prioridad:** inspeccionar PNG en 960×540 y portrait, ajustar cualquier botón demasiado comprimido o cámara mal encuadrada; integrar tras pruebas aprobadas y publicar GitHub Pages.
