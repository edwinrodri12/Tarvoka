# TARVOKA · Revisión visual sin instalar APK

**Estado:** flujo implementado en `.github/workflows/tarvoka-ui-gallery.yml`. Usa **Godot 4.3 oficial**, un servidor gráfico virtual Xvfb y renderizado OpenGL llvmpipe. No genera ilustraciones nuevas: captura el juego en ejecución. No requiere teléfono físico ni modificar una partida guardada.

## Qué obtienes

Un artefacto descargable llamado **`tarvoka-ui-visual-review`**, que contiene:

- `index.html`: galería navegable offline y adaptable a móvil o PC.
- Doce PNG reales **exclusivamente horizontales**: Inicio y Escaramuza (1280×720, 960×540), Facciones (ambos tamaños), batalla, Centro de mando, Ajustes, Resultados, Partidas guardadas y Arsenal.
- `manifest.json`: nombre, tamaño y comprobaciones básicas de contenido por captura.
- `godot.log`: registro de la captura; útil para depurar avisos de renderizado.

Las revisiones usan **1280×720** y **960×540**, siempre horizontales (16:9). Android se bloquea en esta orientación mediante `project.godot`; una captura vertical no es un objetivo de producto. Las capturas de Resultados utilizan una **victoria simulada en la instancia de QA exclusivamente**: no representan una partida jugada o guardada.

## Para verlo sin instalar nada

1. Abre el repositorio GitHub **edwinrodri12/Tarvoka**, pestaña **Actions**.
2. Selecciona el workflow **TARVOKA visual gallery (no APK)**.
3. Se ejecuta automáticamente al modificar los scripts de UI y archivos relevantes, y también puedes pulsar **Run workflow** manualmente.
4. En la ejecución finalizada descarga el artefacto `tarvoka-ui-visual-review` desde **Artifacts**.
5. Descomprime el ZIP, abre `index.html` o cualquiera de los PNG, y compara las pantallas. Si una miniatura es demasiado pequeña, pulsa la imagen para verla en resolución original.

Los errores de script, capturas vacías, dimensiones incorrectas y controles esenciales recortados hacen fallar la ejecución. El flujo sube los archivos incluso si detecta un error, para poder investigar qué ocurrió.

## Defectos descubiertos y corregidos con esta herramienta

- En versiones previas verticales, «Volver» y los retratos quedaban recortados; ya no son diseños objetivo porque el juego usa exclusivamente horizontal. La elección de facciones y comandantes se presenta en dos columnas.
- Los accesos rápidos superiores de la batalla tapaban el panel de comandantes; ahora están en su propia fila.
- En la barra inferior, cinco/seis botones no cabían y «Fin turno» se cortaba. Las acciones se organizan en dos filas conservando los mismos controladores y permisos.
- En pantallas horizontales compactas, la escala de controles y el mapa permanecen disponibles; el motor utiliza el canvas 1280×720 adaptable, con encuadre completo para mapas pequeños.

## Limitaciones

Esta herramienta es **revisión visual previa**, no un sustituto de la QA en un dispositivo Android: no comprueba gestos multitáctiles, densidad física del panel, notch, rendimiento real, consumo, arrastre de unidades o sistema de archivos del móvil. Solo analiza las pantallas que renderiza, no todas las posibilidades del combate.

Para pruebas funcionales más rápidas existe además `.github/workflows/tarvoka-ui-smoke.yml` con ocho pruebas Godot (incluida la orientación horizontal fija). Mantener el arte original en las capturas es obligatorio.
