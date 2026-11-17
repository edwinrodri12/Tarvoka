# TARVOKA · Ciudades civiles V14 — pasada de siluetas 3D a 360°

**Estado:** trabajo de arte en progreso. El modelo no se declara terminado ni aprobado.

## Foco artístico V14

- **Intacto / daño leve (D0–D1):** remate tridimensional de esquinas donde se unen tejados, fachadas frontales y patios posteriores; pequeñas superficies erosionadas solo en D1.
- **Daño moderado (D2):** piezas de cubiertas cerradas con inclinación real generadas por `SurfaceTool`, soportadas en los muros; bordes irregulares en las cuatro fachadas; barras expuestas y cornisas segmentadas.
- **Daño grave (D3):** pilares de esquina bajos, dentellones de paredes laterales y fragmentos de forjado que permiten observar desde atrás y desde arriba el vacío del interior. Sin cubiertas intactas.
- **Destrucción total (D4):** ruinas de baja altura, cumbreras de escombros y arranques de muros. Sin niveles altos ni torres ilusoriamente conservadas.
- **Ayuntamiento:** remate por fachada en D0–D1, cornisas divididas con apoyos en D2, frente y costados colapsados a distintas alturas en D3–D4, restos físicos del reloj en el terreno.

Toda esta geometría es nativa de Godot 4.3: `BoxMesh`, `CylinderMesh` y triángulos cerrados de `SurfaceTool` con `StandardMaterial3D`. Conserva las tres tipologías civiles, ocho facciones, cinco estados de destrucción y el mismo ensamblador táctico compartido V4. La capa V14 no altera ingresos, conquista, colocación ni jugabilidad.

## Visor V14

La escena `scenes/CivilianCityDesignStudioV14.tscn` es una vista MANUAL para revisar modelos reales de la rama de arte, con controles Norte/Sur/Este/Oeste, daño moderado (tejado), grave (muros) y destrucción total. La publicación externa se prepara por Pages separadamente en `/ciudades/`, sin fusionar estos diseños aún no aprobados a la versión jugable.

## Siguiente prioridad antes de considerar cierre de modelado

Revisar visualmente las transiciones de materiales y techos entre los niveles 1–3, y asegurar la identidad de los tres tipos de ciudad desde cámara táctica, manteniendo los cinco estados de destrucción. Se conservan los modelos y ediciones previos; no efectuar tests de gameplay, FPS o APK hasta la aprobación del diseño final.
