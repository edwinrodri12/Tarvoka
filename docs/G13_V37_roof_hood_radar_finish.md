# TARVOKA G13 V37 — remates de cabina, capó y radar plegable

**Estado:** modelado 3D nativo añadido a ambas ramas del modelo y a los controles del Estudio 3D. Aún falta verificar el renderizado real y su publicación web; esta revisión NO aprueba la unidad como modelo final.

## Objetivo de arte

Cerrar las uniones superiores de la cabina y la cubierta del motor de la V36; dotar al radar abatible de dos rigidizadores fijos en su base táctica sin obstruir el mecanismo, sin introducir nuevas armas ni alterar el sistema de colores aprobado.

## Geometría real

- **Techo de cabina:** `G13_V37_SculptedRoofShoulders`. Dos molduras macizas con sección hexagonal de seis puntos, extruidas desde Z=-1,080 hasta -0,275 sobre ambos hombros. Su X interior |0,563| deja libre la escotilla del LOD13 (termina en |0,520|); penetran las juntas originales V11 y mantienen el perfil exterior del vehículo. 40 triángulos en una malla `ArrayMesh`.
- **Cubierta del motor:** `G13_V37_EngineHoodStiffeners`. Dos nervaduras cortas longitudinales y un travesaño de borde anterior, empotrados ligeramente sobre el capó original (superficie nominal Y=1,120), usando un único `MultiMeshInstance3D` de tres cajas. Se evita el grupo de respiraderos hero V2 y la zona central de la base del radar.
- **Soporte del radar LOD8:** `G13_V37_FixedRadarCradleGussets`. Dos cartelas triangulares cerradas, moldeadas en una única malla de 16 triángulos, desde Y=1,108 hasta Y=1,199, a cada lado del apoyo existente V30, con penetración de la cubierta del motor. Están ancladas a `G13_Casco4x4`, no al pivote `G13_RadarAzimut`. De este modo el plegado V29 sigue libre en su rig, sin añadir animaciones.
- El LOD13 no tiene radar plegable V29/V30: únicamente obtiene techo y capó, sin inventar un soporte de plegado allí.

## Conservación de los sistemas existentes

- Colores de ocho facciones idénticos a V32; no se aplica esmalte a ópticas, parabrisas, bocas de cañón ni disco de radar.
- Dos cañones automáticos originales, ninguna geometría de lanzamisiles, sin modificaciones en daño, puntería, economía ni reglas tácticas.
- No se sustituyen nodos de las ruedas, la torreta, los cañones o el radar.
- LOD13: dos nuevos nodos de dibujo; LOD8: tres. Materiales metálicos mates sin iluminación dinámica adicional.
- Se valida la jerarquía y se crean las piezas solamente si V36 está presente; en LOD8 se valida también V30.

## Integración

- `scripts/ui/G13RoofRadarFinishV37.gd`: geometría procedural 3D, verificaciones previas y `show_finish(root, enabled)`.
- `scripts/ui/UnitModels3D.gd`: instalación después de V36 en las dos ramas de la G13, LOD13 y LOD8.
- `scripts/ui/BastionStudioAdapter.gd`: selección V37 y botones de comparación con V36 en el mismo modelo, cámara y facción.

## Próxima prioridad

V38: inspección visual de la silueta general, tornillería exterior y transiciones entre los nuevos paneles del techo y la zaga. Priorizar defectos visibles del modelo y conservar las piezas ya aprobadas; no declarar la G13 finalizada ni atribuirle rendimiento Android sin una revisión real.
