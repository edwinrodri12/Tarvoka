# TARVOKA — G13 V22 | Auditoría artística de 360° y bajos 3D

## Punto de partida: evidencia de imágenes nativas

Se inspeccionaron 16 capturas reales de Godot del G13 V21 (frontal, trasera, izquierda, derecha, cenital, inferior, ambas variantes de ataque, radar, cabina, chasis, los dos cañones y varias facciones). La torreta, las articulaciones V19, el blindaje V20 y las caras visibles V21 se muestran coherentes, con dos cañones automáticos y sin lanzamisiles.

**Problema localizado:** desde la vista inferior, un gran rectángulo del monocasco domina la silueta y oculta el trabajo del tren de rodaje V6: la protección del piso y la transmisión carecían de detalle tridimensional legible.

## Corrección física real en Godot 4.3

`scripts/ui/G13UnderbodyAuditV22.gd`, cargado desde `UnitModels3D.gd` después de V21, crea **12 objetos de renderizado real** en el mismo casco del G13, exclusivamente en LOD13:

- **Cuatro placas de protección bajo el piso**: mallas `ArrayMesh` cerradas de cuatro secciones octagonales (60 triángulos cada una), biseladas, separadas del eje de transmisión central, sin alcanzar los ejes y con costuras de mantenimiento visibles. No existe una nueva placa rectangular gigante.
- **Cuatro paquetes de muelles de suspensión**: perfiles cerrados de cuatro secciones por rueda, encajados por debajo de los topes V6 y por dentro de las caras interiores de los neumáticos.
- **Dos tapas de diferencial** de metal oscuro modeladas con cilindros de 16 segmentos, colocadas sobre los dos diferenciales preexistentes V6.
- **Un árbol longitudinal de transmisión** de sección circular que une las regiones de los dos diferenciales, por debajo del chasis.
- **16 cabezas de perno** visibles en las cuatro placas, agrupadas en un único `MultiMeshInstance3D` para no crear 16 llamadas gráficas independientes.

El sistema original de ejes, ruedas, diferenciales, amortiguadores V6, radar, dos bocas huecas, movimiento, ataques tierra/aire, ocho pinturas y reglas de juego se conserva. **LOD8 Android no añade polígonos ni nuevos modelos**. La unidad G13 sigue siendo un prototipo artístico; no se inserta por esta revisión en el catálogo de compra del juego.

## Pruebas de aprobación

- `tests/test_g13_360_underbody_v22.gd` valida las 8 facciones, 12 objetos físicos, 16 pernos, topología cerrada, holguras frente a las ruedas, ejes y suelo, siete poses y el LOD8 sin cambios.
- `tests/test_g13_v22_visual_capture.gd` genera **62 capturas auténticas Godot**: conserva las 56 de V21 y añade primeros planos de ambos ejes, transmisión, suelo y una comparación **V21/V22 desde idéntica cámara y pose**. El test mide un mínimo de píxeles realmente modificados; no acepta mallas nuevas que queden enterradas dentro del chasis.
- CI ejecuta el script en Godot 4.3, publica ZIP de PNG y habilita el despliegue del modelo en el mismo Estudio 3D de TARVOKA.

**No marcar finalizado hasta validar las pruebas y la publicación, y hasta que el usuario apruebe la apariencia artística.**
