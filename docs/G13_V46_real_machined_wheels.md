# TARVOKA G13 — V46: ruedas mecanizadas y relieve de neumáticos

**Tipo de entrega:** código **3D nativo de Godot 4.3** en el modelo original de TARVOKA, no ilustración. Etapa de mejora artística; no dar la G13 por finalizada sin una inspección visual real.

## Por qué esta prioridad

La referencia real del usuario muestra cuatro neumáticos con centros demasiado simples comparados con el acabado del carro blindado y la torreta. Se conserva la forma 4×4 y el sistema de rodamiento, pero se añade geometría mecánica que gira de verdad con las ruedas.

## Modelado V46

`scripts/ui/G13WheelMachiningV46.gd` aporta cuatro conjuntos de dibujo compartidos, todos `MultiMeshInstance3D`:

1. **Cuatro cubos de rueda de aleación:** cilindros de 20 lados, radio 0,145 m, altura 0,026 m, acero metálico ligeramente satinado. `G13_V46_MachinedArmoredHubCaps`.
2. **Cuatro anillos coloreados de la facción:** toros geométricos de radios 0,152–0,180 m, derivados del esmalte original `G13_TurretFaction_1` con aclarado moderado (4%). `G13_V46_FactionHubRings`.
3. **32 pernos mecánicos:** ocho por rueda, radio de montaje 0,113 m. `G13_V46_RotatingHubBolts`.
4. **48 relieves radiales de la goma:** doce por rueda a radio 0,266 m, material oscuro, parcialmente empotrados en la cara original del neumático. `G13_V46_RadialSidewallRelief`.

**Los cuatro componentes giran realmente:** se integró una llamada `WheelV46.pose(root, spin)` en `G13MobileAirDefenseV1._wheels_pose`, después del acabado V7 existente. Los cálculos reutilizan el ángulo de la rueda original, sin nuevos nodos de animación, colisiones, ruedas jugables ni controladores. En la pose de reposo y en `move` los 32 pernos y 48 relieves mantienen su distribución radial.

## Integración y límites

- `scripts/ui/UnitModels3D.gd`: `G13WheelV46.apply(model)` después de V45 en **LOD13 y LOD8**.
- `scripts/ui/BastionStudioAdapter.gd`: selector **G13 V46**, botones **Llantas mecanizadas 3D** y **Comparar con V45**. Conmutan los cuatro grupos sin alterar el modelo o el estado de las ocho facciones.
- `tests/test_g13_studio_web_v1.gd`: exige mallas reales en el visor, verifica los ocho pernos por rueda, mide que las transformaciones cambien al ejecutar **Rodaje 4×4**, y comprueba la reversibilidad y la versión LOD8.

Se conservan los dos cañones automáticos, elevación, barrido y plegado de radar, facciones, maniobrabilidad y economía.

## Estado de publicación

La ejecución de publicación del visor **#1502** de la V45 terminó con `success`; las nuevas versiones de V46 necesitan su propio trabajo de publicación. El hecho de guardar código en GitHub no confirma que el modelo actualizado ya se esté viendo en GitHub Pages. Se requiere un trabajo verde del workflow y capturas reales para aprobar el acabado visual.

## Siguiente prioridad

Comparar la V46 renderizada con G09, P06 y G11 desde la misma distancia de cámara. Si la calidad de ruedas es suficiente, centrar la siguiente revisión en **sombreado y materiales de cabina y torreta** y corregir solo problemas visibles, sin añadir ornamentos innecesarios.
