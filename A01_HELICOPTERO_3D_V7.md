# TARVOKA — A01 Helicóptero de ataque / etapa V7 de lectura táctica

**Estado:** diseños Godot 4.3 originales en rama de revisión PR #444, no publicados en el Estudio 3D público.

## Objetivo y contexto
Las once vistas Godot de V6 confirman amortiguadores, patines curvos y motores, pero los detalles de escala pequeña se pierden en una pantalla Android. La V7 optimiza la **lectura visual del modelo detallado** sin inflar mecánicas, estadísticas, ventaja de un jugador ni el LOD jugable actual.

## Cambios físicos reales V7
`scripts/ui/AttackHelicopterReadabilityV7.gd`
- Cuatro extremos de pala del rotor principal: bandas sólidas discretas, combinando reflejo metálico claro con una franja estrecha del color de facción. Van sujetos al mismo pivote V1/V3 que gira durante la animación.
- Cuatro marcas metálicas en las palas del rotor de cola, y cuatro marcadores de los cuadrantes del aro fijo.
- Dos escudos laterales compactos de volumen real (malla 3D) en las nacelas de motor V4, con emblema pintado de cada una de las ocho facciones.
- Dos distintivos físicos de facción junto a los lanzadores, siguiendo el soporte real de misiles, sin modificar bocas ni cargas.
- Aro metálico de contraste en la bocacha de la ametralladora, sujeto al pivote original del cañón.
- Dos marcas discretas en patines V6 como referencia secundaria.
- Comparación V6↔V7 real mediante `set_enabled()`, reversible sin mallas duplicadas.
- **Compatibilidad absoluta de la jugabilidad:** todo lo nuevo sólo se crea con `finish_enabled && art_level >= 13`, para la escultura completa del Estudio. El helicóptero Android táctico `art_level <=10` permanece igual; no hay nuevas fortalezas/debilidades ni cambios en combate.

## Evaluación de imágenes
`tests/test_attack_helicopter_v7_capture.gd` renderiza **15 imágenes auténticas**:
1. Ocho vistas orbitales V7 **a 320×180 píxeles**, sin ampliar artificialmente.
2. Cuatro vistas V6 a esa misma resolución, iluminación y cámaras, ocultando sólo la capa de acabado V7.
3. Tres acercamientos 960×720 del escudo de motor, lanzadores y extremos de las palas.

`tests/test_attack_helicopter_v7.gd` verifica identidad de las ocho facciones, rotación compartida por rotores, cañón, materiales, integridad del modelo de combate y alternancia V6/V7.

## Próxima validación
Comparar los PNG V6/V7 a resolución nativa y, si los elementos decorativos causan ruido o no son legibles, ajustar tamaño, ubicación y contraste. No considerar arte final sin inspección visual, Godot QA y pruebas de UI. Publicación Pages sólo después de revisión e integración de PR.
