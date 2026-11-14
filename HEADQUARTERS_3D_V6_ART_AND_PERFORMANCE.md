# TARVOKA — Cuartel General V6: escudos auténticos + prueba de 49 edificios

## Objetivo
Continuar el Cuartel General sobre V4/V5 sin alterar las reglas tácticas ni las unidades. Esta rama se apila sobre el PR V5 (#217), que a su vez depende de V4 (#194).

## Escudos oficiales
Se reutilizan *sin rediseño* los ocho escudos aprobados que ya existen en la rama principal:
- `assets/factions/official_first_four_atlas.webp`: Alianza Norte, Pacto Escarlata, Unión Verde, Confederación Solar.
- `assets/factions/official_last_four_atlas.webp`: Sindicato Violeta, Legión Ámbar, Dominio Turquesa, Orden Ónix.

Los atlas se copian **como blobs existentes de Git**, sin recomprimirlos. `HeadquartersEmblems3D.gd` corta la franja superior de cada atlas (160×160 por facción), cachea el material y el Mesh 3D, y monta el arte en el soporte de escudo V4 de la torre central. El soporte metálico permanece intacto. El escudo de ruinas conserva su arte correspondiente. No se inventan emblemas ni se crean nuevos personajes.

## Memoria y rendimiento de múltiples edificios
El prototipo V5 cambia entre dos subárboles, pero mantiene el detallado completo oculto. Para un **mapa táctico real con muchas instancias**, ahora existe `HeadquartersMapLOD3D.build_map_only(level,faction,condition)`, que **no construye ni retiene V4**. La geometría de mapa se cachea por nivel, facción y condición; instancias equivalentes comparten el mismo ArrayMesh y seis materiales.

`HeadquartersCityBatch3D.build_grid(7,7,15.5)` presenta 49 edificios con colores, niveles y daños mezclados. Agrupa las instancias que usan la misma malla con MultiMesh, en vez de crear cientos de nodos individuales. El visor 3D web añade una opción «Probar distrito de 49 edificios 3D», vista aérea a escala de mapa, FPS de **ese visor** y recuento de grupos geométricos.

## QA implementado
- `tests/test_headquarters_v6.gd` valida ocho texturas originales de 160×160, sus materiales vinculados al escudo 3D V4 y una versión destruida.
- Verifica que 25 construcciones ligeras de la misma variante comparten **exactamente el mismo recurso Mesh**, con un solo MeshInstance3D por edificio y ningún subárbol V4.
- Verifica 49 instancias y un número de grupos MultiMesh inferior al de edificios.
- En Godot 4.3 OpenGL captura `artifacts/tarvoka_hq_v6_official_shield.png` y `artifacts/tarvoka_hq_v6_49_buildings_map_scale.png`, y comprueba el regreso a la vista de tanque.
- El workflow del visor web ejecuta la prueba y archiva las capturas, además de conservar todos los QA existentes V1–V5.

## Advertencias necesarias
- **No es una medición de FPS Android:** el contador muestra FPS del navegador/Godot durante la ejecución; rendimiento Android real requiere un equipo con el juego corriendo.
- **No está integrada la fábrica de edificios al mapa táctico jugable:** el módulo de lotes es solo laboratorio de arte. La integración posterior debe tomar propietario/estado reales del motor y decidir cuándo usar V4 o la malla ligera según distancia/zoom.
- Los atlas originales son versiones de selección móvil, suficientes para el modelo en pantalla, no texturas maestras de marketing. Los escudos en la vista de mapa más lejana se identifican por color; la obra figurativa completa queda en el modelo V4.
- Ninguna de estas mejoras modifica economía, turnos, HP, reglas de captura, colisiones, IA, archivos de guardado ni tanque.
