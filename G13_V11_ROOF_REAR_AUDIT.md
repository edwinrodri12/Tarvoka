# TARVOKA — G13 V11: juntas de techo y perfil posterior

## Desarrollo integrado

La unidad G13 conserva el diseño 4x4, torreta de doble cañón y radar independiente. Este avance continúa la V10.4 sin modificar la jugabilidad, las estadísticas ni el balance.

- `G13BodyFinishV11.gd`: cabina facetada cerrada, nuevo techo blindado, ventanas laterales tridimensionales y torreta de varias secciones, ya desarrollados en paralelo y conservados.
- `G13CabRearFinishV11.gd`: dos uniones sólidas entre techo y laterales de cabina, juntas longitudinales, nueva cubierta trasera de perfil inclinado, protecciones posteriores y junta superior de la puerta de servicio.
- `UnitModels3D.gd`: ejecuta ambas capas de acabado únicamente para la versión de alta calidad del G13 (art_level >= 13).
- `tests/test_g13_cab_rear_v11.gd`: comprueba que el techo y sus juntas realmente se crucen geométricamente, que las luces traseras y la puerta no queden tapadas, que los ocho colores sigan siendo distintos y que LOD8 y las animaciones permanezcan intactas.
- `tests/test_g13_v11_roof_rear_capture.gd`: genera 18 capturas 3D nativas en Godot 4.3 con ambas capas V11 presentes.

## Resultados verificables

- [Auditoría G13 V11, ejecución 43956668718: SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43956668718).
- Commit validado: `accbe5f94fe0a2164ed19ff478882c571af8a3fa`.
- Se ejecutaron los tests anteriores y los nuevos, se importó el proyecto y se renderizaron **18 imágenes PNG reales**.
- Artefacto GitHub: `g13-v11-closed-roof-rear-18-native-godot-frames` (ID `14271562905`).
- Las imágenes confirman el cambio de unión en el techo y el perfil superior de la parte trasera desde los mismos ángulos de la V10.4.

## Evaluación artística y límites

El cambio soluciona la transición de techo y suaviza el remate trasero; visualmente sigue siendo un diseño mecánico de polígonos visibles. Aún necesita revisión de los grandes paneles laterales, las proporciones generales y el acabado del frontal antes de la aprobación comercial.

**QA geométrica: aprobada. Aprobación artística definitiva: pendiente.** La publicación del visor web se comprueba en su propio workflow.

## Próxima prioridad

Dar cohesión a los paneles laterales y al frontal de la carrocería evitando grandes superficies rectangulares, sin invadir los cuatro pasos de rueda ni ocultar los elementos específicos de cada facción. Comparar las nuevas capturas con la V11 y preservar las armas aéreas/terrestres.
