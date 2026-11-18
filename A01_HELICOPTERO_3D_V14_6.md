# TARVOKA — HAT-29 A01 V14.6 — amortiguadores de vibración del rotor

## Prioridad
Refinar la mecánica 3D del **rotor principal**, sobre la V14.5 ya publicada. Mantener exactamente las ocho pinturas de facción de V14.3, los efectos y la destrucción V13/V14, los reflejos nocturnos V14.4 y los 4 soportes y corona V14.5.

## Escultura 3D nativa

`scripts/ui/AttackHelicopterRotorDampersV146.gd` añade dos conjuntos independientes, solo cuando se construye el modelo heroico `attack_heli` con arte ≥13:

- **Cuatro apoyos elastoméricos fijos:** bloques de goma mate y placas finas metálicas en las zapatas del mástil, debajo de las cuatro riostras existentes V14.5. Hijo de `A01_HelicopteroAtaque_V1`, sin rotar con las palas.
- **Cuatro amortiguadores hidráulicos de raíz:** cuerpo, vástago, fuelle protector y dos ojales; un conjunto por cada pivote real `A01_AspaPortante_0..3`. Se mueven **con** las palas originales, sin interpolaciones o velocidades duplicadas.
- **Cuatro bielas estabilizadoras del cabezal:** discretas varillas de acero gris, hijas del grupo `A01_RotorPrincipal`, sin sustituir la corona V10, la corona V14.5 ni el platillo cíclico V3.
- Superficies físicas `CylinderMesh`, `SphereMesh` y `BoxMesh` con aleación apagada y goma prácticamente no metálica (metal 0.02–0.03, rugosidad 0.91–0.93). Sin nuevas emisiones ni iluminación.

La geometría **no se genera** en el art_level táctico ≤10 de Android; se añade únicamente a `UnitModels3D.build(...,14)`. No hay cambios de lógica, estadísticas, armas, economía ni equilibrio.

## Estudio WebGL unificado
Se agregan en **Unidades → HAT-29 → Detalles** dos inspecciones reales en el mismo visor:
- `V14.6: amortiguadores de palas`: macro al cabezal y raíz de las cuatro palas.
- `V14.6: aisladores de mástil`: usa la cámara lateral por debajo del disco de palas, creada en V14.5.

No crea otra página, duplicado de modelo, control de zoom ni nuevas luces.

## Puertas de calidad
- Ocho facciones: piezas 3D presentes e idempotentes; vástagos cromados y fuelles mates, anclajes fijos frente a partes móviles, cuerpo de pintura inalterado.
- Etapas V13: al desprender el rotor desaparecen con él amortiguadores y bielas; al reparar vuelve a girar el mismo pivote.
- `tests/test_attack_helicopter_v9_studio.gd`: pruebas reales del mismo modelo 3D y las dos entradas del menú.
- `tests/test_attack_helicopter_v14_capture.gd`: **39 capturas reales Godot**, 35 anteriores + 4 tomas nuevas: amortiguador lateral, superior, aisladores y rotor animado.
- `tarvoka-3d-pages.yml`: empaqueta el archivo nuevo en el export web verdadero.

La V14.6 es un avance de modelado, no la aprobación artística definitiva del HAT-29.
