# TARVOKA Base Aérea V9 — inspección visual de 360° y cabina de control reconstruida

## Problemas encontrados en las capturas reales V8

La torre de control aún conservaba un `CristalPerimetral` de **2,00 × 0,90 × 1,86**: un bloque sólido de vidrio de la primera versión, que oscurecía el interior y parecía más un bloque opaco que una sala acristalada. También las `JuntaCurvaV6` estaban colocadas a **0,095** unidades sobre la superficie del tejado y las manchas del techo V8 a **0,16** unidades por encima. Eran detalles técnicamente distintos de la curvatura verdadera que podían aparentar estar flotando al acercarse.

## Soluciones aplicadas en Godot 4.3

1. **Cabina panorámica hueca:** la V9 oculta los volúmenes de vidrio macizos V1 en el modo V9 y construye cuatro caras reales de cristal de **0,028** unidades de espesor, con material transparente, acabado especular y `clearcoat`. Añade marcos metálicos ajustados a los bordes, suelo, mesa de control, tres pantallas y asiento interior. El volumen original no se elimina para poder desactivar V9 y compararlo exactamente con V8.
2. **Reparación de uniones:** se reposicionaron las juntas V6 a **0,018** sobre la curva, parcialmente empotradas en el techo. Las manchas V8 pasan a **0,022** sobre la superficie. Un único lote adicional V9 remata el borde delantero y trasero de **cada segmento existente**, sin puentear ningún hueco producido por daño.
3. **Daños:** vidrio frontal con tres fisuras discretas en daño medio; daño crítico no reconstruye ventanas ni interior intactos; destrucción total conserva el modelo arruinado sin cabina.
4. **Vistas de auditoría:** se añaden ocho perspectivas dentro del estudio, usando la cámara real de Godot, no imágenes estáticas: frontal isométrica, izquierda, posterior, derecha, cubierta superior, torre cercana, interior hangar, frontal bajo.
5. **Rendimiento estructural:** materiales compartidos, **una sola malla de remate** del techo por base detallada, sin luces adicionales ni nuevos sistemas de partículas. La V9 sólo afecta a las cuatro bases próximas en escenas LOD, no a los proxies lejanos.

## TARVOKA Studio 3D

En `Edificios 3D → Base Aérea · V9 · cabina y vistas 360°`, activa o desactiva **«V9 · cristal fino, cabina real y remates (comparar V8)»**. Usa el selector **«V9 · inspección desde todos los ángulos»** para cambiar entre ocho cámaras. Se mantienen los controles de nivel, ocho facciones, cinco daños, apertura del portón, impacto bala/explosivo, lluvia, nieve, versiones V6/V7/V8 y LOD.

**Importante:** V9 corresponde a geometría Godot 3D real; no modifica juego Android, turnos, armas ni economía.

## QA y aceptación

`tests/test_airbase_v9_closeup_360_gpu.gd` evalúa **40 combinaciones de facción/daño**, 3 niveles, 4 cristales delgados reales, desactivación del bloque de vidrio anterior, 20 piezas animadas de puertas, uniones de techo sin separación vertical, LOD cercano, nieve/lluvia reversible, alternancia con Cuartel General y **13 capturas reales** de Godot para comparar múltiples ángulos, nivel de daño y invierno.

La acción `.github/workflows/airbase-v9-closeup-360-gpu.yml` ejecuta estas comprobaciones en OpenGL, genera capturas y las almacena como artefacto. El despliegue web público sigue siendo una operación separada, y no se declaran FPS Android sin probarlos en un teléfono.
