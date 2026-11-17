# TARVOKA G13 V36 — proporciones, uniones de guardabarros y zaga

**Estado:** geometría 3D nativa creada e integrada en código y en el menú del Studio 3D. La inspección de render real, publicación del Web viewer y aprobación final continúan pendientes; no se declara terminada la G13.

## Criterio artístico

La V36 no modifica el tamaño del vehículo ni acumula accesorios sobrepuestos: resuelve tres uniones perceptibles en el modelo V35 sin deformar ni recolorear las piezas aprobadas.

1. **4 soldaduras/soportes curvos a guardabarros.** Un `ArrayMesh` cerrado de cuatro arcos cortos recorre los 4 pasos de rueda, conectando el casco lateral en X≈0,675 con los guardabarros V33. En sección cruza desde X=0,661 hasta 0,719 y radio 0,405–0,436 m; solapa físicamente tanto el casco como el aro V33. Se mantiene el radio original de los neumáticos y su animación.
2. **2 carenados laterales traseros.** Piezas cónicas cerradas y facetadas con cuatro estaciones, de Z=1,065 a 1,286; se estrechan progresivamente desde X=0,721 a X=0,604. El último perfil entra en el protector de esquina V34. Evitan el brusco escalón entre el final del arco trasero y el parachoques.
3. **2 colgadores de escape.** Un par de escuadras metálicas enlaza realmente el parachoques V34 con los tubos abiertos V35. Las escuadras penetran ambas superficies para eliminar el aspecto flotante de sus soportes; no se sustituyen ni obstruyen las aberturas de escape.

## Inventario de geometría

- 1 `MeshInstance3D` de cuatro arcos soldados: 272 triángulos en total, no cuatro meshes separados.
- 1 `MeshInstance3D` de dos carenados cerrados: 56 triángulos.
- 1 `MultiMeshInstance3D` de dos escuadras de escape: malla cubo compartida, 24 triángulos instanciados.
- **3 nodos de dibujo añadidos**, sin shaders nuevos ni partículas.
- Son detalles estáticos del casco; las ruedas, la torreta y el radar mantienen sus padres de animación.
- Ocho facciones sin cambio de color ni estadísticas. Dos cañones automáticos; cero misiles.

## Integración

- `scripts/ui/G13ProportionFinishV36.gd`: creación procedural y `show_finish(root, enabled)`, permite comparar la misma escena con V35.
- `scripts/ui/UnitModels3D.gd`: V36 después de V35 para LOD13 y LOD8 del rol visual `aa_mobile`.
- `scripts/ui/BastionStudioAdapter.gd`: selector V36 y botones **Uniones de arcos y zaga** / **Comparar con V35**.

## Próxima prioridad de diseño

V37: inspeccionar y perfeccionar el remate de cabina y capó posterior, el soporte del radar plegado y el reparto visual de los colores de facción. Mantener arte 3D nativo, sin nuevas armas ni aprobación definitiva antes de una revisión visual en el visor.
