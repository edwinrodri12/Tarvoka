# TARVOKA G13 — V45: acabado de cabina y mecánica de autocañones

**Implementación 3D nativa, no imagen generada:** `scripts/ui/G13CabServiceFinishV45.gd` agrega seis grupos de malla auténticos a la escena original de Godot 4.3. La G13 sigue en desarrollo: no afirmar aprobación artística ni despliegue sin prueba real.

## Alcance

La prioridad del usuario es que G13 alcance el mismo nivel de acabado que las unidades 3D previamente aprobadas. Después de V44, esta revisión trabaja el aspecto visual de la cabina y del cuerpo central que se ve poco terminado, en lugar de seguir refinando solo bordes de rueda.

- **Cuatro puertas técnicas biseladas y cerradas:** `G13_V45_LowerFacetedServiceHatches`, 64 triángulos. Están unidas al costado original (`X=0.664` intersecta el casco `X=0.675`) y sobresalen a `X=0.722`. Quedan entre las ruedas, bajo la placa de facción V44. El frente llega hasta `Z=-0.070`, el panel posterior comienza en `Z=+0.055`.
- **16 elementos de herrajes:** `G13_V45_RecessedDoorFittings`, dos bisagras, un tirador y un seguro por puerta, como una sola familia `MultiMesh` en las cuatro puertas.
- **Cuatro postes de ventanilla:** `G13_V45_CabWindowProtectors`, anclados a los bordes originales del vidrio lateral V11, sin tapar el centro de las ventanas.
- **Dos remates del techo del parabrisas:** `G13_V45_ClosedArmoredWindshieldBrow`, malla con 32 triángulos. El extremo frontal `Z=-1.186..-1.068` queda delante del acceso de techo V2 y dentro de los perfiles externos V37.
- **Dos barras cortas en color de facción:** `G13_V45_FactionRoofRecognitionBars`, montadas sobre el remate superior. Derivan del esmalte de facción seleccionado, aclarado 3.5%. No se aplican a la superficie de las ventanas ni sustituyen el resto de colores V32/V44.
- **Diez aletas de enfriamiento auténticas:** `G13_V45_TwinReceiverCoolingFins`, cinco por receptor de cañón, como una sola malla instanciada con el **padre original de elevación** `G13_ElevacionCanones`. Giran cuando se apunta; no se introducen lanzamisiles.

## Ajuste retrospectivo V44 antes de esta fase

Para que el acabado visible de V44 no tenga el aspecto de parches flotantes, se corrigieron de forma localizada sus cotas nominales: el blindaje lateral baja hasta el casco, el color sobre los arcos solapa la geometría curva V42, los protectores pintados de la torreta se acercan al soporte original y las rejillas del motor se empotran en la tapa anterior. No se modificaron armas, posición de ruedas ni facciones.

## Integración

- `scripts/ui/G13CabServiceFinishV45.gd`: toda la geometría nativa nueva y conmutador `show_finish`.
- `scripts/ui/UnitModels3D.gd`: aplica V45 después de V44 tanto en **LOD13** como en **LOD8**.
- `scripts/ui/BastionStudioAdapter.gd`: selector V45 y controles **Cabina y puertas 3D / Comparar con V44** dentro del visor compartido.
- `tests/test_g13_studio_web_v1.gd`: verificaciones para los seis nodos de dibujo, el control de comparación, jerarquía de la elevación de los cañones y la versión táctica.
- `.github/workflows/tarvoka-3d-pages.yml`: diagnóstico explícito de la instrucción que falle al preparar las fuentes del Studio para identificar bloqueos de publicación sin saltarse los controles.

## Restricciones y estado

Se preservan radar, dos autocañones, inclinación de cañones, ocho facciones, mallas de otras unidades, reglas y economía. Las imágenes conceptuales anteriores **no** son modelos editables y no se usaron como prueba de implementación.

La presencia del código y las referencias puede comprobarse desde GitHub; hasta disponer de un run verde de GitHub Actions y del render 3D, **no afirmar que V45 esté visible en GitHub Pages**, ni que el nivel artístico ya sea equivalente al de los modelos aprobados.

La próxima prioridad es **revisar las vistas renderizadas de V45, detectar las superficies que aún se vean planas y afinar materiales, nervaduras y proporciones, no añadir componentes sin necesidad**.
