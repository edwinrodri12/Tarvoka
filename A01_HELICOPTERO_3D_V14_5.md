# TARVOKA HAT-29 — A01 V14.5 — anclajes de transmisión y rotor principal

## Continuidad comprobada
La V14.4 ya fue fusionada y publicada con éxito en el mismo Estudio 3D de TARVOKA. Esta prioridad se limita a **detalles estructurales del rotor principal**, nunca a una nueva unidad ni a refabricar el rotor anterior.

## Geometría 3D nativa añadida
Nuevo script `scripts/ui/AttackHelicopterRotorMountV145.gd`:

**Soportes fijos de fuselaje**
- Grupo `A01V145_SoportesFijosMastil`, hijo directo del fuselaje V1, que no acompaña la rotación de las palas.
- Cuatro riostras diagonales y cuatro zapatas atornilladas alrededor del mástil V1 existente.
- Collar inferior y dos anillos discretos de cojinete que enmarcan el cilindro existente, sin duplicar la base del mástil ni sustituir el plato cíclico V3.

**Conexiones que giran con el rotor**
- Grupo `A01V145_HerrajesRotorGiratorio`, hijo del pivote `A01_RotorPrincipal` original, con una corona exterior y cuatro pequeños brazos de paso y pernos.
- Un seguro y una biela fina sobre cada uno de los cuatro pivotes `A01_AspaPortante_`.
- El rotor continúa recibiendo la misma transformación de `AttackHelicopterV1.pose` y los mismos efectos V13 de impacto, desprendimiento y reparación.

Todo el metal se mantiene en grafito y acero desaturado. **No se cambia la pintura de facción** (ocho ejércitos), los recursos PBR de la V14.3 ni el modo nocturno V14.4.

## Integración y límites
- `UnitModels3D.build("attack_heli",...,true,14)` aplica V14.5 después del arte V14.4, únicamente para el modelo de alta fidelidad (art_level ≥13). Las unidades de combate con nivel ≤10 conservan el modelo ligero original.
- El Estudio unificado añade dos vistas: **anclajes fijos del mástil** y **corona/bisagras del rotor**. Sin visores paralelos y sin cambiar los otros menús.
- La vista de anclajes usa una cámara verdaderamente lateral, por debajo del disco de palas, porque la cámara alta anterior escondía las nuevas riostras. Al volver a vista general o elegir otra inspección se recupera automáticamente la cámara normal.
- Al destruirse el helicóptero, el mismo nodo rotor V1 queda oculto y se llevan con él los nuevos herrajes móviles; los anclajes del fuselaje permanecen con la carrocería accidentada.

## Validación
- `tests/test_attack_helicopter_v14.gd` cubre 8 facciones, independencia giro/fijación, cuatro riostras, cuatro bisagras, idempotencia de instalación y daño/reparación.
- `tests/test_attack_helicopter_v9_studio.gd` garantiza que ambos botones enfocan el modelo real sin reemplazarlo, manteniendo las animaciones y la UI.
- `tests/test_attack_helicopter_v14_capture.gd` exige **35 PNG reales de Godot**: 31 existentes más cuatro nuevos acercamientos de transmisión, incluidos rotor quieto y rotor girando.
- `.github/workflows/tarvoka-3d-pages.yml` copia el nuevo script al exportador del Estudio; evita un preload ausente en Pages.

El avance no implica aprobación definitiva del modelado del helicóptero por parte del usuario.
