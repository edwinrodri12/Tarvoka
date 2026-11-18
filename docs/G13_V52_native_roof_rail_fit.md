# G13 V52 — cierre de hombros del techo con la cabina V51

**Entrega:** modelado tridimensional nativo de TARVOKA con Godot 4.3/GDScript, no imágenes conceptuales. La G13 sigue como prototipo artístico y no está registrada como unidad de batalla jugable.

## Diagnóstico basado en capturas reales

La ejecución #1544 produjo correctamente un artefacto de **11 capturas de V51 generadas por Godot**, incluidos LOD13 y LOD8. Su publicación fue bloqueada por la prueba de comparación de mallas históricas: el test buscaba techo V49 de 80 triángulos cuando seguía activa la cubierta V51 de 112 triángulos. La prueba ya restaura primero V50/V49, y después habilita V51 antes de verificar el acabado actual. Anteriormente se habían reparado dos errores sintácticos: la referencia inexistente `global_scale.y` en la rama de ciudades V39 y una declaración duplicada de `roof` en el capturador G13.

Las capturas mostraron otra deficiencia del visor: **«Ver techo» enseñaba los bajos**. Se corrigieron las inclinaciones de los botones; las nuevas capturas requieren +58° para techo y −55° para bajos.

## Geometría V52 implementada

`scripts/ui/G13RoofShoulderFitV52.gd` reemplaza en el mismo `MeshInstance3D` la malla de `G13_V37_SculptedRoofShoulders`, que antes era una pieza de perfil único por cada lado a lo largo de Z=−1.080..−0.275.

- **Dos perfiles longitudinales de acero, uno por costado**, con 4 estaciones cada uno y transición gradual de ancho y altura sobre el techo V51
- Extremo delantero ajustado a Z=−1.110 para asentarse sobre la nueva cubierta
- Extremo posterior en Z=−0.285, solapado con el comienzo de `G13_V38_RoofRearEndCaps`, evitando un borde suelto
- **88 triángulos reales** de una única malla cerrada y compartida por ambas partes, frente a 40 de la anterior
- Se mantienen el material V37, el nodo, el movimiento de la unidad, la paleta de las ocho facciones, el radar, los dos autocañones y las animaciones. **Cero nuevos nodos de dibujo**
- Comparación exacta con malla V51 original guardada en `tarvoka_g13_v52_original_and_fitted_shoulder_meshes`

## Integración y verificación

- `scripts/ui/UnitModels3D.gd`: aplica V52 después de V51 en LOD13 y LOD8
- `scripts/ui/BastionStudioAdapter.gd`: selector **G13 V52** con **Hombros del techo integrados** / **Comparar con V51**, y corrección de los presets **Ver techo** y **Ver bajos**
- `tests/test_g13_studio_web_v1.gd`: comprueba malla V52 de 88 triángulos, restauración de malla V37/51 de 40 triángulos, los dos LOD, el radar y las demás unidades aprobadas
- `tests/test_g13_v52_visual_capture.gd`: genera imágenes 1280×720 de ocho vistas hero (con inclinaciones corregidas), dos tácticas y una comparación V51/V52
- `.github/workflows/tarvoka-3d-pages.yml`: ofrece las once PNG como artefacto `tarvoka-g13-v52-native-360-design` sin relajar las demás barreras de publicación

## Límite de aprobación

Los cambios están guardados en el repositorio, pero hasta que el run V52 termine y sus capturas sean inspeccionadas, **no afirmar que la nueva geometría se ve bien en el sitio publicado**. La próxima etapa debe revisar los resultados renderizados en las cámaras ya corregidas y trabajar solo defectos visibles.
