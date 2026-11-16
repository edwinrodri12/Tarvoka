# TARVOKA · Cuartel de Infantería V4 · Fachadas reales de 360° (Godot 4.3)

## Objetivo
Continuar con el diseño 3D, especialmente la fachada posterior, costados y techos, **sin cambiar las reglas de juego** y conservando las 3 evoluciones arquitectónicas:
- **N1**: barraca compacta de una planta.
- **N2**: cuartel en L de dos plantas, ala y una torre.
- **N3**: complejo en U, central de tres plantas, dos alas dobles y dos torres.

## Cambio estructural respecto a V3
Las fachadas traseras de V1 eran paredes sólidas con escasas señales de actividad militar. La V4 **oculta el sólido original y lo reemplaza** por paños de hormigón modulados alrededor de **huecos reales de ventanas**, en los que se colocan marcos y cristales translúcidos. No se añaden simples planos opacos pegados encima de muros llenos. La sustitución afecta a:
- Todas las fachadas posteriores **de todos los módulos** del nivel elegido.
- Las dos caras laterales **exteriores**, elegidas expresamente para no abrir agujeros en uniones entre las alas de L/U.
- Las marcas de facción sobre los remates de la fachada exterior.
- Juntas pequeñas sobre paneles supervivientes de cubierta y equipamiento real en los niveles superiores.
- Un tablero pequeño de instrucción en el campo de entrenamiento, sin invadir el edificio ni sus pistas.

Hay tantas filas de ventanas como plantas tenga realmente cada módulo: una, dos o tres. El nivel 3 no reutiliza una única fachada plana escalada. Las cristaleras, paños inferiores, dinteles y pilastras se ensamblan de forma separada. Los materiales de hormigón y metal proceden de la V3 PBR nativa.

## Daños visuales
- **Operativo**: ventanas completas, emblemas y ventilación de cubierta.
- **Leve**: el primer cristal de cada módulo está parcialmente roto; el panel de techo dañado **sigue ausente**.
- **Medio**: algunos cristales faltan; no se reconstruyen paneles de techo retirados en V1/V3 ni se añaden equipos de cubierta.
- **Crítico**: no se sustituyen muros derruidos por fachadas intactas; solo marcas de rotura en los restos existentes.
- **Destruido**: V4 aporta cero mallas; las ruinas de V1/V2/V3 permanecen sin ningún edificio operativo reconstruido.

## Estudio 3D
El cuarto edificio pasa a **Cuartel de Infantería V4 · fachadas reales 360°**. Se agrega un control reversible `V4 · ventanas traseras y laterales reales (comparar V3)` sobre las opciones V2 y V3. Al apagarlo se reconstruye automáticamente V3 con sus paredes originales. Se añaden **tres cámaras nativas**: trasera (auténtica, sin rotar cámara y modelo al mismo tiempo), lateral izquierda y lateral derecha. Las cuatro cámaras anteriores permanecen.

## QA y límites
`tests/test_infantry_barracks_v4_gpu.gd` comprueba en Godot 4.3 nativo **120 combinaciones**: 8 facciones × 3 niveles × 5 daños. Inspecciona `MeshInstance3D.visible` de los muros originales, cuenta huecos reales, compara ventanas y daños, impide aperturas entre las alas y revisa 18 capturas GPU. También vuelve a abrir el Cuartel General, la Base Aérea y la Base Naval para detectar regresiones en el Estudio.

**Este prototipo es arte 3D, no una mecánica nueva:** no altera capturas de ciudades, producción de infantería, economía, salud de unidades, FPS Android ni guardados. Publicación en Pages y entrada al APK son tareas independientes. V4 no debe considerarse aprobada antes del resultado positivo de Godot y de una inspección de sus capturas reales.

## Siguiente prioridad cuando termine V4
Revisar la legibilidad de los huecos y materiales al tamaño de visualización Android y las posibles intersecciones de las esquinas de las alas. Afinar el acabado final en función de las capturas reales, no por suposiciones.
