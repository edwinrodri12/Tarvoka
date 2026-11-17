# TARVOKA · G13 V16 — optimización real de llamadas de dibujo

**Estado:** rama de validación nativa Godot 4.3. El G13 sigue siendo un modelo artístico del Estudio 3D, no una unidad nueva integrada en el combate.

## Qué cambia

La versión 15 dejó 143 nodos/objetos de dibujo contabilizados por el antiguo perfilador, incluidos nodos no visibles. En V16 se agrupan **44 piezas geométricamente idénticas** en **17 MultiMeshInstance3D reales**, distribuidos según el pivote de sus padres. Esto sustituye 44 objetos visibles por 17, con una reducción **esperada de 27 objetos dibujables** por vehículo en LOD13. El valor observado se reportará solo después de CI.

Los grupos abarcan guardabarros, molduras, seis ranuras de ventilación, pares de faros, luces traseras, escapes, insignias, marcas de facción, cubiertas de cañón, cuatro varillas del radar y pares de mecanismos de la torreta. Cada grupo replica exactamente la primitiva, material PBR, textura de rugosidad, pintura, posición, rotación y escala de los originales. Las luces mantienen la emisión V15 sin crear fuentes `Light3D`.

Los **nombres y mallas históricos siguen presentes pero se ocultan**, para conservar el árbol de nodos que leen las pruebas y animaciones anteriores. La API `TarvokaG13StaticBatchV16.set_legacy_comparison(root,true)` vuelve a mostrar la geometría V15 para comparar su aspecto sin alterar poses, y con `false` activa de nuevo los lotes de la V16. Toda esta capa es exclusiva del nivel 13: **Android LOD8 sigue exactamente igual**.

## Cómo se comprueba

- `tests/test_g13_static_batch_v16.gd`: 8 facciones, 44 originales, 17 lotes, **27 objetos visibles menos**, mismo número de triángulos realmente visibles, mismos materiales/transformaciones, jerarquía de pivotes, ataque a tierra/aire, radar, reversibilidad e idempotencia.
- `tests/test_g13_v16_visible_profile.gd`: CPU de construcción y de 12 poses, geometría y objetos realmente visibles antes/después. Datos de Godot 4.3 en Linux con OpenGL software; **no mide FPS en un Android real**.
- `tests/test_g13_v16_visual_capture.gd`: **35 capturas de Godot** de las 8 facciones, ángulos, ataques y detalles, más una pareja desde la misma cámara con mallas V15 vs MultiMesh V16. Calcula el error cromático medio por píxel; fallará si la diferencia es perceptible (umbral MAE 0.018).

## Integración

`UnitModels3D.gd` aplica esta mejora después de V15 solamente para detalle 13. Se publica en el **mismo Estudio 3D** por la canalización existente de GitHub Pages; no se crea otro visor. La mejora no modifica alcance, vida, nivel, munición, clima, reglas ni valor estratégico.

**Siguiente evaluación:** revisar las imágenes y el perfil JSON real. Para FPS y consumo de GPU en Android aún es necesario ejecutar un benchmark en el dispositivo físico.
