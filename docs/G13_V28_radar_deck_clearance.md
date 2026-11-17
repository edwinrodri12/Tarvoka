# TARVOKA · G13 AA móvil · revisión V28 del soporte radar (LOD8)

Estado de este archivo: especificación geométrica de la revisión; **no equivale a una aprobación del vehículo entero ni de sus animaciones a 360°**.

## Objetivo visual

El radar independiente de V27 tenía un mástil cónico más alto, pero la base original quedaba demasiado próxima a la torreta blindada cuando esta giraba en diagonal. La revisión V28 crea un mástil cerrado con pie escalonado de 12 caras y alarga la cubierta trasera original. Las modificaciones son materiales/mallas y transforms de Godot; G13 sigue siendo un prototipo **art-only**, no una unidad de combate.

## Geometría del chasis

- Eje de radar anterior: `(0, 1.36, 0.89)`; posición V28: `(0, 1.36, 1.135)`, relativa al G13 4×4.
- Cubierta de motor posterior `G13_EngineCover`: la misma malla `BoxMesh`, con profundidad Z de `0.67` a `1.15`; centro `(0,1.03,0.70)`.
- Pie poligonal: radio `0.125`; queda sobre la cubierta y penetra `0.025` m bajo su superficie. Extremo posterior del pie: `z=1.260`; extremo posterior de la cubierta: `z=1.275`.
- La malla `G13_RadarMast` tiene 96 triángulos en una sola superficie. No hay nuevos nodos de dibujo, armas, sensores funcionales, luces ni reglas.
- El cabezal y el receptor de radar mantienen las proporciones del V27, sobre el mismo pivote Y independiente.

## Barrido horizontal del blindaje de la torreta

Esta prueba *no* es una prueba de disparo: considera solamente la coraza, anillo de giro y módulo óptico estático de la torreta, **excluyendo el recorrido de los cañones**.

- Centro del eje de torreta: `z=0.35`.
- Envolvente radial conservadora del blindaje y director óptico (V1/LOD8): aproximadamente `0.6263` m.
- Desplazamiento entre pivotes de torreta y radar V28: `1.135-0.35=0.785` m.
- Separación radial conservadora entre el pie y la envolvente de la torreta: `0.785-0.6263-0.125 ≈ 0.0337 m` (3.37 cm).
- El test Godot `tests/test_g13_radar_deck_mount_v28.gd` comprueba además la distancia de los elementos a la huella del mástil en pasos de 5 grados para cada una de las ocho facciones.

## Límites pendientes

**No aprobar el giro completo de las armas únicamente por el margen de coraza.** Los dos cañones siguen montados en un pivote de elevación y pueden apuntar hacia atrás; sus volúmenes de barrido son más largos que la coraza. Un diseño posterior debe comprobar su interacción con el radar, y si hay interferencia, resolverla mediante movimiento/repliegue mecánico o rediseño del soporte, sin añadir misiles ni modificar el armamento original.

No hay mediciones FPS de un teléfono Android físico. El modo detallado LOD13 V24 no recibe cambios V28. El visor compartido debe mostrar la diferencia V27/V28 con la misma cámara, pose y facción.

## Requisitos de aceptación

1. La prueba V28 y todas las regresiones G13 pasan en Godot 4.3.
2. 22 capturas reales de Godot más informe JSON, con cinco pares comparativos V27/V28 y ocho facciones.
3. Separación mínima de la **coraza** superior a 25 mm en el barrido completo de orientación.
4. El modelo no crea un `MeshInstance3D` ni un `MultiMeshInstance3D` nuevo.
5. La versión V27 y su cubierta se recuperan íntegramente desde el comparador reversible.
6. El visor web se vuelve a exportar y su publicación se confirma antes de decir que el V28 está visible en línea.
