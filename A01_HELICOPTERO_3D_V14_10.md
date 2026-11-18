# TARVOKA — HAT-29 A01 V14.10: acabado de placas y contacto de pernos

## Prioridad completada en código
El análisis de las coordenadas reales de V14.9 detectó que los 32 pernos tenían su cara inferior 0.0015 unidades **por encima** de sus placas de montaje: un pequeño hueco visible con luz rasante. No hacía falta añadir más placas ni alterar los pivotes animados.

## Corrección sobre los mismos modelos
- Nuevo módulo `scripts/ui/AttackHelicopterRotorContactV1410.gd`, aplicado tras V14.9 únicamente al helicóptero hero de detalle `art_level >= 13`.
- Las **16 placas V14.9** se refinan **en sitio**: cada `BoxMesh` original se sustituye por un único `ArrayMesh` sólido, con bisel físico en el perímetro superior y normales verdaderas. No se duplican `MeshInstance3D`.
- Las **32 cabezas de perno originales** se bajan individualmente hasta que su base intersecta la cara superior de la placa 0.0015 unidades (en lugar de dejar una separación 0.0015).
- El mate grafito recibe acabado metálico controlado (metallic 0.55, roughness 0.52). Ni el esmalte ni el color de ninguna facción cambia.
- Se conservan `original_mesh`, `original_material` y `original_bolt_y` como referencias del propio objeto: `set_enabled(false)` muestra la geometría V14.9 y `set_enabled(true)` recupera el nuevo pulido, dentro del mismo rotor y sin reconstruir el helicóptero.

## Integración
- `UnitModels3D.gd`: añade V14.10 tras V14.9; Android battle `<=10` permanece intacto.
- `BastionStudioAdapter.gd`: **Unidades → Helicóptero HAT-29 → Detalles**, dos macros reales “V14.10: placas biseladas” y “V14.10: pernos asentados”, más botón “Comparar rotor V14.9 / V14.10”.
- `.github/workflows/tarvoka-3d-pages.yml`: módulo incluido en la colección de recursos y el ensamblaje WebGL unificado.
- `tests/test_attack_helicopter_v14.gd`: 8 facciones, 16 `ArrayMesh`, 32 contactos medibles, reversibilidad, idempotencia, ausencia del LOD Android y conservación de los daños V13.
- `tests/test_attack_helicopter_v9_studio.gd`: cámaras y comparador sin recrear unidad.
- `tests/test_attack_helicopter_v14_capture.gd`: **67 capturas previstas**, 63 anteriores + 4 nuevas (misma cámara V14.9/V14.10, placa de bieleta, cabeza de perno).

## Evidencia y estado
- GitHub Actions del helicóptero V14.9 había resultado verde y generó 63 imágenes reales.
- Un primer job de V14.10 ejecutó las pruebas nativas y registró un `PASS HAT29 V14.10`; falló después **únicamente** por una regla CI desactualizada que buscaba el texto `PASS HAT29 V14.9`. Se corrigió la regla en `a01-v14-hat29-visual-qa.yml`.
- La publicación del Estudio 3D unificado permanece separada de la QA específica HAT-29; los últimos fallos del export estaban relacionados con G13, no con los modelos A01. No se omiten ni desactivan sus validaciones.

**La validación final del acabado requiere revisar las nuevas capturas reales y que la exportación WebGL termine satisfactoriamente. La unidad todavía NO tiene aprobación artística definitiva.**
