# TARVOKA · Revisión visual sin instalar APK

**Estado:** flujo implementado en `.github/workflows/tarvoka-ui-gallery.yml`. Usa **Godot 4.3 oficial**, un servidor gráfico virtual Xvfb y renderizado OpenGL llvmpipe. No genera ilustraciones nuevas: captura el juego en ejecución. No requiere teléfono físico ni modificar una partida guardada.

## Qué obtienes

Un artefacto descargable llamado **`tarvoka-ui-visual-review`**, que contiene:

- `index.html`: galería navegable offline y adaptable a móvil o PC.
- Diez PNG de la escena real de Godot: Inicio (vertical/horizontal), preparación de Escaramuza, selección de las ocho facciones (vertical/horizontal), batalla (HUD compacto/expandido), Centro de mando y resultados (vertical/horizontal).
- `manifest.json`: nombre, tamaño y comprobaciones básicas de contenido por captura.
- `godot.log`: registro de la captura; útil para depurar avisos de renderizado.

Los tamaños actuales de revisión son **412 × 915** para Android vertical y **1280 × 720** para horizontal. Las capturas de Resultados utilizan una **victoria simulada en la instancia de QA exclusivamente**: no representan una partida jugada o guardada.

## Para verlo sin instalar nada

1. Abre el repositorio GitHub **edwinrodri12/Tarvoka**, pestaña **Actions**.
2. Selecciona el workflow **TARVOKA visual gallery (no APK)**.
3. Se ejecuta automáticamente al modificar los scripts de UI y archivos relevantes, y también puedes pulsar **Run workflow** manualmente.
4. En la ejecución finalizada descarga el artefacto `tarvoka-ui-visual-review` desde **Artifacts**.
5. Descomprime el ZIP, abre `index.html` o cualquiera de los PNG, y compara las pantallas. Si una miniatura es demasiado pequeña, pulsa la imagen para verla en resolución original.

Los errores de script, capturas vacías, dimensiones incorrectas y controles esenciales recortados hacen fallar la ejecución. El flujo sube los archivos incluso si detecta un error, para poder investigar qué ocurrió.

## Defectos descubiertos y corregidos con esta herramienta

- En vertical, «Volver», la elección del rival y los retratos de la selección quedaban parcialmente fuera de pantalla. Se apilan encabezado y bandos.
- Los accesos rápidos superiores de la batalla tapaban el panel de comandantes; ahora están en su propia fila.
- En la barra inferior, cinco/seis botones no cabían y «Fin turno» se cortaba. Las acciones se organizan en dos filas conservando los mismos controladores y permisos.
- Tras rotar el teléfono, la cámara enfocaba solo la fuerza inicial en mapas pequeños y recortaba casi la mitad del terreno. Para mapas de hasta 12 × 10 se recupera el encuadre del mapa completo; los mapas grandes preservan su enfoque táctico.

## Limitaciones

Esta herramienta es **revisión visual previa**, no un sustituto de la QA en un dispositivo Android: no comprueba gestos multitáctiles, densidad física del panel, notch, rendimiento real, consumo, arrastre de unidades o sistema de archivos del móvil. Solo analiza las pantallas que renderiza, no todas las posibilidades del combate.

Para pruebas funcionales más rápidas existe además `.github/workflows/tarvoka-ui-smoke.yml` con seis pruebas Godot. Mantener el arte original en las capturas es obligatorio.
