# TARVOKA — Aterrizaje de arte conceptual a la interfaz jugable (v0.10)

## Referencias reales consultadas (biblioteca Advanced wars)
- **Interfaz táctica de Tarvoka en español.png**: referencia para lectura de selección, órdenes y jerarquía del tablero.
- **Interfaz de Construcción Militar TARVOKA.png**: referencia para paneles de instalaciones, costos y acciones diferenciadas.
- **TARVOKA: Cambiar turno en batalla.png**: referencia para el énfasis de terminar turno, separar navegación de acciones irreversibles.
- **Tablero Visual de TARVOKA: Tácticas Avanzadas.png**: referencia para colores tácticos, capas y tarjetas técnicas.
- **Tarjeta APC-08 de Tarvoka.png**: referencia de ficha con datos de unidad agrupados en vez de párrafos sin jerarquía.

**Estado de recursos:** estos PNG están disponibles como referencias de diseño en la biblioteca, pero **no** se han confirmado como imágenes binarias bajo assets/ del repositorio. Este cambio NO afirma que estén incluidos o texturizados en la APK, NO reemplaza emblemas originales ni modelos 3D y NO inventa un paquete de sprites. Las piezas de chrome se crean nativamente con StyleBoxFlat para funcionar de inmediato en Godot 4.3.

## Lo que cambia en el juego
1. **GameUiTheme.gd y GameUiBackdrop.gd:** estilo central nativo (azul acero, superficies elevadas, tipografía de alto contraste, bordes, pestañas, controles táctiles, estados hover/pulsado/deshabilitado) y arte procedural original de cuadrícula cartográfica, líneas técnicas y círculos de radar en portada, centro de mando y escaramuza. Sin shaders costosos ni imágenes de franquicias. Se instala desde Main sobre los menús ya operativos.
2. **Main.gd, barra lateral de batalla:** la vista predeterminada pone primero estado táctico/recursos, accesos de comando, minimapa, inspección y acciones. Los accesos de campaña, galerías y controles de creación de partida continúan disponibles al desplazarse, pero no desplazan la lectura del combate. Tarjetas con márgenes y contornos; confirmar, finalizar turno y abrir mandos tienen roles visuales distintos.
3. **HomeMenu.gd:** portada responsiva con tarjetas, subtítulos y botones táctiles diferenciados. Multijugador sigue deshabilitado; la portada no inventa una sala online.
4. **CommandMenu.gd:** cabecera de operaciones, tarjeta de estado, pestañas y acciones prioritarias visualmente identificables. Persiste la misma fuente legal de datos/compra.
5. **SkirmishSetup.gd:** presets y ficha de resumen visual; **iniciar batalla** conserva la confirmación existente y no elimina guardados al simplemente explorar.
6. **HUD compacto Android:** se distinguen confirmar orden, finalizar turno y menú; conserva capturas, zoom/pinch y órdenes reales del motor.

## Validación y límites
- Nuevo test Godot res://tests/test_visual_chrome.gd y suite existente en GitHub Actions; export Android sin cambios en gameplay.
- Pendiente **screenshot y QA táctil en dispositivo físico** para verificar escalado real de fuente y paneles en 16:9, 20:9 y tablet.
- Pendiente importar los PNG originales aprobados a assets/ mediante un flujo de archivos binarios autorizado y manifiesto de procedencia. Un StyleBox aproximado no es la textura final de un concepto.
- El rediseño del contenido de campaña y de modelos 3D corresponde a sus flujos independientes; evitar conflictos de Main.gd antes de fusionar esas ramas.
