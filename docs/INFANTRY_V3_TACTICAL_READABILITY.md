# TARVOKA — Infantería V3: legibilidad táctica y facciones (20 de noviembre de 2026)

**Alcance:** mejora incremental sobre las seis esculturas nativas V2 de Godot 4.3, sin modificar reglas, captura, recursos, daños, ni agregar unidades jugables. El mismo visualizador web en `scenes/UnitArtStudioWeb.tscn` conserva los vehículos y edificios.

## Problema

La cámara de detalle mostraba correctamente los emblemas V2, pero en una vista lejana los paneles pequeños del modelo Android (LOD8) podían dejar de distinguir la facción. Además, cambiar el selector de facción no reconstruía el material de estos soldados; la acción del estudio base solamente repintaba G09.

## Implementación

- **LOD8 físico:** siete paneles opacos con los **ocho colores oficiales**, distribuidos en pecho, casco, mochila, las dos mangas y ambas rodillas. Es geometría `MeshInstance3D` real anclada al rig, no un sprite ni un filtro. LOD13 conserva el acabado orgánico completo y no crea las siete mallas tácticas adicionales.
- **Visor existente:** botones `LOD13 · detalle` y `LOD8 · vista táctica` dentro del panel de cámara para infantería. Recrean la geometría nativa dentro del **mismo SubViewport** y alteran la distancia ortográfica, sin abrir otra página ni insertar un segundo renderizador.
- **Selector de facción funcional:** reconstrucción del modelo de infantería con la nueva pintura preservando rol, versión V1/V2, daño visual, orientación y LOD seleccionado. Las ocho facciones se basan en `UnitModels3D.faction_paint_color()`.
- **Pruebas:** 96 combinaciones de geometría (6 modelos × 8 facciones × 2 LOD), siete paneles verificados por color y transparencia en cada LOD8, ausencia de piezas superfluas en LOD13, 26 imágenes nativas Godot incluidas seis vistas tácticas y una prueba adicional del selector real compartido.

## Restricciones

`infantry_urban`, `infantry_defense`, `infantry_antitank` e `infantry_engineer` siguen siendo **opciones de arte**, no clases tácticas ni desbloqueos. Las funciones de ataque, movimiento, niebla de guerra y economía no se alteran. Las imágenes de QA son comprobaciones del modelo real, no nuevos recursos de juego.

**Cierre condicionado:** confirmar CI Godot y Studio compartido antes de fusionar o afirmar que el sitio público contiene V3.
