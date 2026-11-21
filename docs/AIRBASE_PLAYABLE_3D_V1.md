# TARVOKA — Base Aérea: integración 3D nativa inicial

## Por qué este edificio
El tipo `airbase` ya existe como productor de aeronaves en el sistema moderno. El arte de Base Aérea había alcanzado el acabado V16 en una rama de diseño, pero su casilla en la batalla principal seguía siendo un cubo genérico. Esta integración reutiliza **la versión V4 del modelo táctico 3D nativo** del historial artístico, sin agregar edificios de reabastecimiento, astilleros adicionales ni cambiar el catálogo del juego.

## Alcance
- Cada `airbase` real del mapa moderno dibuja **una MeshInstance3D con cuatro superficies** (acabado móvil, no un icono 2D).
- La geometría de hangar, torre, calle de rodaje, helipuerto y franjas de facción se ajusta a casillas de 2.40 m con escala 0.159.
- Soporta 8 colores oficiales, neutral gris, niveles visuales N1–N3 y daños decorativos D0–D4; la economía aún no evoluciona ni recibe daño por ataques.
- Niebla de guerra: no dibuja edificios inexplorados; si están explorados pero ocultos muestra versión neutra N1/D0.
- Mantiene intactas las reglas de producción `UrbanEconomy`, propiedad, recursos, turnos, rescates, reabastecimiento y fábricas existentes.
- El diseño HERO acabado V16 continúa disponible en la línea artística del **Estudio TARVOKA compartido**; la optimización V4 es la representación táctica Android. No afirmar que se exportó el V16 HERO a la batalla.

## Validación
`tests/test_airbase_live_battle_v1.gd` recorre las dos bases reales, 120 variantes de colores/niveles/daño, estado neutral, niebla de guerra y economía sin mutaciones. El workflow `airbase-live-battle-v1-qa.yml` ejecuta Godot 4.3 GL Compatibility en Mesa (Linux), que **no certifica FPS de un teléfono Android**.

## Próximas fases
Comprobar la lectura de señales y las texturas PBR V16 a diferentes zooms en el visor compartido, revisar modelo HERO al acercar y ejecutar FPS en Android físico, siempre sin tocar producción ni costos.
