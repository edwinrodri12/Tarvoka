# TARVOKA · G14 V2 — cierre de carrocería y acabado 3D en revisión

**Estado:** V2 implementada en código; **NO final**, no fusionada a `main`, sin validación de APK Android hasta completar QA.

## Cambios materiales y geométricos

- Cabina V2 independiente generada con `SurfaceTool`: seis caras cerradas y 12 triángulos externos, sin paredes invisibles. Conserva la caja de blindaje interna V1 como subestructura, de modo que la cabina nunca queda hueca.
- Dos parabrisas y dos ventanas laterales con **geometría volumétrica sólida BoxMesh**, reflejos PBR, `clearcoat`, tonos azul petróleo y transparencia **desactivada**; evita que el visor muestre la carrocería al otro lado del vidrio.
- Techo, capó, salpicaderas, cierres, sellos, paneles de servicio traseros, rejillas y juntas mecánicas 3D añadidas sobre el chasis V1.
- Neumáticos: 8 pivotes de rueda con bloques de dibujo real. Cada pivote lleva un `MultiMesh` de 20 bloques en Android LOD8 o 40 en detalle de estudio LOD13, además de anillos metálicos; en alta calidad incorpora seis pernos por rueda.
- Colores de facción aplicados a capó, laterales y marcas de reconocimiento sin teñir todo el vehículo.
- Las ruedas V1 y los bloques V2 rotan conjuntamente; `restore_model_pose` restablece toda la geometría.
- El visor unificado de TARVOKA presenta botones **V2 mostrar** y **V1 comparar**, además de las animaciones existentes de los contenedores, radar y estabilizadores.

## Archivos

- Base: `scripts/ui/G14MobileSAMV1.gd`.
- Nueva escultura: `scripts/ui/G14MobileSAMExteriorV2.gd`.
- Factoría y animación de estudio: `scripts/ui/UnitModels3D.gd`.
- Selector, botones y visibilidad: `scripts/ui/BastionStudioAdapter.gd`.
- Nueva validación: `tests/test_g14_v2_native_3d.gd`.
- CI actualizado: `.github/workflows/g14-v1-native-sam-qa.yml`.

## Pruebas preparadas

Godot 4.3 debe confirmar:
1. Doce triángulos exteriores y normales orientadas hacia afuera; ningún agujero del casco.
2. Cuatro ventanas independientes y sólidas con transparencia desactivada y reflejos físicamente simulados.
3. Ocho pivotes de rueda, ocho conjuntos de dibujo de caucho, posiciones intactas y rotación reversible.
4. Carga del modelo en ocho facciones × LOD8 y LOD13.
5. Dieciséis **capturas reales desde Godot**: V1/V2 en cada facción para facilitar la inspección, no ilustraciones generadas.
6. La batería SAM jugable conserva coste 900, alcance 2–5, centro de producción y reglas de combate.

## Aprobación y siguiente prioridad

No declarar cerrada G14 hasta revisar imágenes generadas, asegurar que aparece en el visor publicado y revisar rendimiento Android. La V3 puede centrarse en biseles de los contenedores SAM, soportes hidráulicos del lanzador y escenas de destrucción física.
