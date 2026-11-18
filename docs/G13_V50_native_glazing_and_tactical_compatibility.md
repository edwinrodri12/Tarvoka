# TARVOKA G13 — V50: cristales 3D y corrección del LOD táctico

**Estado:** modelado nativo en Godot 4.3, no imagen generada. La publicación V50 y su revisión artística requieren un run verde y las capturas reales.

## Fallo de publicación identificado y corregido

El run #1527 falló porque `G13SculptFinishV48.gd` exigía `BoxMesh` en cabina/torreta LOD8, aunque el módulo previo `G13TacticalArmorV26.gd` ya había convertido esos dos nodos a `ArrayMesh`. El error bloqueaba V48 y V49 tácticos, las dos imágenes LOD8 y el despliegue. Se cambió la precondición de V48 para reconocer las **mallas reales de V26**; mantiene la validación rígida de LOD13 y permite en LOD8 un techo `BoxMesh` o `ArrayMesh`.

## Modelado V50

`scripts/ui/G13GlazingFitV50.gd` sustituye solo recursos `Mesh` de nodos de vidrio existentes, sin nuevos nodos de dibujo:

- Dos parabrisas en ambos LOD: nuevas mallas cerradas de 3 anillos octagonales, **44 triángulos por panel**; bordes achaflanados en el volumen y la orientación/posición originales
- Dos ventanas laterales en LOD13: mallas cerradas de 8 vértices exteriores, **28 triángulos por panel**; las nuevas pendientes aproximan el vidrio a los laterales V49, de X=±0.567 a X=±0.520 conforme la altura crece de Y=1.151 a 1.275, sin mover pivotes ni ventanas
- Se preservan cristales PBR V47, color de facción, radar, dos autocañones, ruedas y animaciones
- Los recursos originales se guardan para comparar `V50 / V49` en una misma escena y cámara

`scripts/ui/UnitModels3D.gd` aplica V50 tras V49 en LOD13 y LOD8. `scripts/ui/BastionStudioAdapter.gd` expone los controles **Cristales integrados 3D** y **Comparar con V49**. `tests/test_g13_studio_web_v1.gd` comprueba cierre, reemplazo/reversión, nodos originales y los dos LOD. `tests/test_g13_v50_visual_capture.gd` y el workflow de Pages preparan ocho vistas reales LOD13, dos LOD8 y una comparación V49, en `tarvoka-g13-v50-native-360-design`.

## Evidencia y límite

La inspección de capturas reales de V49 confirma que la G13 detallada renderizaba, pero aún había costados de vidrio y cabina que merecían un acabado más integrado. **Las capturas no aprueban la V50 por anticipado**: revisar el artefacto de V50 al publicarse, detectar intersecciones y evitar seguir añadiendo accesorios que no mejoren la silueta. La G13 continúa como prototipo artístico, no unidad jugable.
