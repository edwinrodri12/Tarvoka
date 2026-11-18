# TARVOKA — G13 V38: uniones exteriores de la carrocería

**Estado:** modelado nativo de Godot 4.3 añadido en las dos ramas del modelo y disponible en los controles de TARVOKA Estudio 3D. La publicación del visor, la compilación y la inspección visual en ejecución no están verificadas. La G13 todavía no está finalizada.

## Cambio artístico V38

La fase V38 cierra discontinuidades entre las molduras V37, los hombros de cabina V33 y el blindaje lateral, evitando introducir piezas ornamentales aisladas.

- **2 remates traseros de techo:** un único `ArrayMesh` con dos piezas prismáticas cerradas de sección hexagonal, extruidas desde Z=-0.290 hasta -0.152. La sección inicial se aloja 15 mm dentro de la moldura V37, mientras la sección final desciende suavemente hasta el techo blindado. Sus 40 triángulos cubren ambos lados sin invadir la escotilla superior o las lunas.
- **2 uniones acorazadas laterales:** otro `ArrayMesh` de dos piezas cerradas de sección pentagonal (32 triángulos totales). Conectan el cierre de cabina anterior, Z=-0.338, con el comienzo del costado posterior, Z=-0.117. No sobrepasan X=0.688, de modo que respetan las placas de facción V32, la ventanilla y la barrida de la torreta.
- **12 fijaciones metálicas en una sola tanda:** ocho remaches sobre el blindaje lateral inclinado, con posición X dependiente de la altura para evitar que floten, y cuatro tornillos en el parachoques posterior V34. Un `CylinderMesh` de 8 segmentos, instanciado en una sola `MultiMeshInstance3D`.
- **Coste:** tres nodos de dibujo adicionales en ambos LOD. Se conservan los materiales anteriores; los nuevos colores neutros representan acero, no pintura de facción.

## Límites respetados

- El vehículo sigue teniendo **dos cañones automáticos**, sin misiles.
- No se alteran colisiones, `BattleSession`, estadísticas, animaciones de ruedas, torreta, disparos ni plegado del radar.
- Los ocho colores de facción se toman de V32 y no se recolorean.
- El nuevo módulo exige V37 y valida los nodos del techo, las uniones de cabina, los parachoques y el material de facción antes de crear geometría.
- Las figuras de triángulos son cálculos estáticos del diseño; no constituyen una prueba de renderizado.

## Implementación

- `scripts/ui/G13BodyJoineryV38.gd`: modelado 3D, validaciones y método `show_finish(root, enabled)`.
- `scripts/ui/UnitModels3D.gd`: integración de V38 después de V37 en las ramas LOD13 y LOD8 del rol visual `aa_mobile`.
- `scripts/ui/BastionStudioAdapter.gd`: botones **Uniones exteriores de blindaje** y **Comparar con V37** en el visor compartido. Mismo modelo, cámara, facción y animaciones.

## Siguiente prioridad — V39

Modelar finamente la superficie exterior: fijaciones de paneles en la zona delantera, sello inferior de la cabina y detalles técnicos posteriores, eliminando cualquier pieza redundante antes de la aprobación final. Primero revisar visualmente la V38 en el visor real si se dispone del render; no dar por superadas pruebas que no se han ejecutado.
