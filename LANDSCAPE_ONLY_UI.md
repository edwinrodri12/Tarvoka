# TARVOKA — Regla de interfaz horizontal (13 de noviembre de 2026)

**Decisión de dirección de producto aprobada:** TARVOKA es exclusivamente horizontal en Android. El juego, menús, selección de facciones, campaña, Centro de mando, Arsenal, Ajustes, guardados y resultados comparten esta orientación. Las artes de diseño aprobadas de referencia son ocho pantallas de 1280 × 720 (16:9) creadas para Figma. **No volver a producir menús verticales como versión de producto.**

## Configuración real del motor

`project.godot`:
- `display/window/handheld/orientation=0` = Landscape fijo en Godot 4.3. No se activa sensor/portrait.
- `viewport_width=1280`, `viewport_height=720`.
- `window/stretch/mode="canvas_items"` y `aspect="expand"`: admite pantallas horizontales de teléfono, tablet y distintos radios sin deformar la UI.

**No es solamente un cambio en las artes de Figma**: el proyecto y su compilación APK usan esta orientación.

## Implementación en escenas

- **Inicio:** logo oficial con planeta ficticio, ocho escudos originales, menú y campaña a dos columnas en cualquier pantalla horizontal. El cambio de diseño depende de la relación de aspecto, no simplemente de una cifra arbitraria de ancho.
- **Escaramuza:** columna izquierda de misión, semilla, mapa real y tipo de batalla; columna derecha de las dos facciones oficiales y reglas. Scroll independiente para ambas columnas. Inicio/Avanzado/Facciones permanece fijo.
- **Facciones:** lista de ocho facciones y dossier del comandante en dos columnas, con ambos emblemas y arte original. La interfaz no se apila por una pantalla horizontal compacta de 960 píxeles.
- **Guardados:** autoguardado y manual aparecen uno junto a otro, con sus rutas y validaciones originales; el jugador debe pulsar Cargar explícitamente. No se alteran los datos del combate.
- **Batalla / Centro de mando / Ajustes / Resultados / Arsenal:** conservan su funcionamiento actual y la navegación horizontal. El panel de resultados se ensancha en dispositivos horizontales de menor altura.
- **Compatibilidad de editor:** algunos módulos mantienen un reflujo defensivo al redimensionar una ventana de PC a formato vertical. No habilita orientación vertical en la APK.

## Revisión visual sin APK

El workflow `.github/workflows/tarvoka-ui-gallery.yml` renderiza ahora **doce capturas horizontales** en 1280×720 y 960×540. Incluye Inicio, Escaramuza, Facciones, Batalla, Centro de mando, Ajustes, Resultados, Guardados y Arsenal. El `manifest.json` declara `orientation=landscape`; la página de revisión rechaza un archivo vertical. Captura únicamente el render real de Godot (sin imágenes conceptuales como fondo).

`tests/test_landscape_only_ui.gd` verifica la configuración Android, las dos columnas, controles de facciones y compatibilidad de guardados. Se ejecuta en el smoke de GitHub.

**Pendientes de QA física:** notch/recorte de pantalla, gestos, rendimiento táctil, UI en 20:9 horizontal y densidades Android. Las capturas de Figma son dirección de arte, no sustituyen las capturas ejecutables de Godot.
