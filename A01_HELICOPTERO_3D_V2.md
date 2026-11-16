# TARVOKA — Helicóptero de ataque A01 · escultura 3D V2

**Estado:** diseño real incorporado en la rama de trabajo de PR #444. Aún no está aprobado ni publicado; requiere pruebas Godot y revisión visual humana.

## Reemplazo real de mallas
- `scripts/ui/AttackHelicopterCabinV2.gd` reemplaza visualmente, no recubre de adornos, el casco original y el cristal monolítico de V1 con dos `ArrayMesh` cerrados (12 segmentos, tapas delantera/trasera).
- Cabina en tándem con cristal translúcido PBR, costillas estructurales y marcos longitudinales verdaderos. Dos asientos con respaldo y pantalla de instrumentos; puertas laterales, manijas, estribos y remaches. Aclaración: es todavía un primer pase artístico, no un cockpit final.
- Nuevo volumen del fuselaje, registros y rejillas de motor, tapas de transmisión y panel superior coloreado por facción.
- `set_enabled` permite desactivar el conjunto V2 y recuperar inmediatamente el casco/cristal V1 sin crear mallas duplicadas, útil para comparación visual.
- No altera rotores, armas, patines ni animaciones del A01 V1. Mantiene ocho facciones.

## Integración
- `Models.build("attack_heli", faction, true, 14)` crea el A01 detallado V2 para el Estudio 3D.
- Con `art_level<=10`, `Models.build` conserva la versión ligera previa del campo de batalla. No cambia las reglas de combate, estadísticas, economía, turnos ni IA.
- `BastionStudioAdapter.gd`: nuevas vistas para cabina, laterales, motores y techo, más comparación reversibles V1/V2.
- `.github/workflows/tarvoka-3d-pages.yml` copia los archivos A01 desde main a la publicación del Estudio, preservando los edificios y las versiones del Bastión/G11. Se activa tras integración a main.
- URL prevista del estudio, **no afirmación de publicación**: https://edwinrodri12.github.io/Tarvoka/

## Validaciones
- `tests/test_attack_helicopter_v1.gd`: ocho variantes, rotores, armas, animaciones, LOD viejo.
- `tests/test_attack_helicopter_v2.gd`: mallas cerradas, cristal, estructura de cabina, pintura, alternancia V1/V2 y animaciones restaurables.
- `tests/test_attack_helicopter_v2_capture.gd`: ocho cámaras alrededor del modelo y tres primeros planos en Godot, exportados como once PNG reales para inspección.
- La CI emplea Godot oficial 4.3 con renderizador OpenGL virtual Mesa/Xvfb en lugar del renderizador nulo, que da falsos errores al destruir mallas 3D.

## Siguiente etapa
Revisar manualmente los once ángulos. Corregir piezas flotantes, contornos de cabina, forma de las palas y la lectura del rotor de cola antes de trabajar daños físicos y efectos de clima. No declarar terminado el helicóptero todavía.
