# TARVOKA — Costas y agua V5 (arte 3D)

Esta pasada trabaja la lectura visual de riberas, playas y lagos en el visor Godot WebGL, conservando V3.1 (pendientes, vegetación y caminos), materiales PBR y V4 (rocas/árboles). La escena de combate y sus reglas tácticas no se modifican.

- El módulo `TerrainStudioOrganicCoast3D.gd` muestrea la altura real del terreno, encuentra los bordes entre tierra y agua y dibuja una **ribera sinuosa** adaptada a cada casilla.
- Dos mallas agrupadas contienen franjas de arena húmeda y agua somera, con transición graduada al agua profunda: no hay cientos de instancias ni textura descargada.
- Los marcadores blancos repetitivos V4 se ocultan solo cuando V5 está activa; se reemplazan por reflejos suaves y más dispersos.
- El visor añade el control reversible **Costa V5: transición natural y agua suave**.
- La prueba GPU compara V4/V5 con misma cámara/luz y guarda `artifacts/tarvoka_terrain_v4_v5_coast_comparison.png`. También verifica piezas de geometría y que el modo anterior continúa disponible.

**Limitaciones comerciales:** La lógica de agua sigue siendo por casillas; es un tratamiento visual, no erosión topográfica continua a escala de mundo ni simulación física. Falta validar texturas y transparencia cerca del agua, ondas animadas, rendimiento Android y visión de las unidades.
