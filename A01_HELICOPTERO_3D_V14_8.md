# TARVOKA HAT-29 — V14.8 | herrajes de raíz de pala

## Alcance y prioridad
La V14.7 se publicó correctamente. Esta fase da acabado estructural a **las cuatro uniones entre el cabezal y cada pala principal** sin crear otro sistema de giro.

## Arte nativo Godot 4.3
Nuevo `scripts/ui/AttackHelicopterBladeRootFinishV148.gd`:

- **Ocho orejas laterales de horquilla:** dos placas delgadas por cada uno de los cuatro pivotes `A01_AspaPortante_N` originales del V1/V3, alrededor de su antiguo bisel de pala.
- **Cuatro pasadores transversales completos:** cilindros de acero que atraviesan visualmente ambas placas sin sustituir la bisagra V3.
- **Ocho tuercas hexagonales:** una por extremo de cada pasador; geometría real de seis caras.
- **Ocho abrazaderas de pala con 16 tornillos de sujeción** en la zona de raíz, discretas para no engrosar ni acortar el perfil aerodinámico aprobado.

La geometría es hija de los **pivotes originales**, rota y desaparece en la destrucción con el rotor V1, y conserva la corona V10/V14.5, amortiguadores V14.6/V14.7 y el platillo V3. No hay animaciones nuevas, lógica de combate ni material de facción modificado.

## Integración y pruebas
- `UnitModels3D.build("attack_heli",faction,true,14)` instala V14.8 después de V14.7. Con el LOD10 Android no se aplica ni se genera ninguno de los herrajes.
- En el **mismo Estudio 3D**, menú HAT-29 → Detalles, se agregan dos cámaras macro: *Pasadores de articulación* y *Abrazaderas de las palas*.
- Ocho facciones con acabado intacto, cuatro verdaderas placas por parejas, cuatro pasadores, tuercas hexagonales, abrazaderas y tornillería, prueba de idempotencia y compatibilidad con animaciones.
- `tests/test_attack_helicopter_v14_capture.gd` exige **47 PNG auténticos de Godot**: 43 anteriores y cuatro tomas nuevas (articulación, abrazaderas, herrajes opuestos, giro).
- WebGL publica el script `AttackHelicopterBladeRootFinishV148.gd` con el resto del Estudio, sin visor separado.

Esta iteración es un avance visual; no declara el HAT-29 terminado o aprobado sin inspección.
