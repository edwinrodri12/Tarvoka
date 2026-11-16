# TARVOKA · G13 — Escultura 3D V11 (cabina y torreta)

**Estado:** revisión artística implementada en Godot 4.3, pendiente de aprobación visual comercial y comprobación de dispositivo real. No está habilitada como unidad táctica en `BattleSession`.

## Qué cambia respecto de V10

- Cabina sellada reconstruida mediante **cinco anillos octagonales**, con mayor redondeo low-poly en hombros, costados y techo; la geometría está cerrada arriba y abajo.
- Casco de torreta retocado en cinco niveles, con una transición más clara entre base, hombros y techo. Las dos protecciones laterales ahora son cascos biselados, no bloques cuadrados.
- Techo de cabina reemplazado por **volumen 3D completamente cerrado** con aristas biseladas. Se conservan los pivotes y nombres de los bloques V1/V10 (invisibles dentro de la escultura) para no romper contratos históricos.
- Se agregan **dos ventanillas laterales de espesor 14 mm** con material óptico PBR, y los dos parabrisas delanteros se recolocan para seguir la inclinación del nuevo frente.
- La carrocería no supera el ancho original de la cabina (1,19 m sin escala de escena). Ninguna nueva pieza ocupa los pasos de ruedas de 4×4.
- Los acabados de facción, llantas/tacos, bajos, radar, doble cañón y poses visuales aire/tierra permanecen vigentes y no se duplican.

## Integración exacta

- `scripts/ui/G13BodyFinishV11.gd`: nuevo autor de geometría procedural, solo arte.
- `scripts/ui/UnitModels3D.gd`: aplica V11 después de V10 **únicamente** para `Models.build("aa_mobile", faction, true, 13)`. El rol LOD8 y las ocho facciones permanecen aislados.
- El visor nativo `scenes/G13InspectionStudio.tscn` y el estudio compartido usan `UnitModels3D`, así que mostrarán la escultura V11 sin crear un visor alternativo.
- `tests/test_g13_body_finish_v11.gd`: prueba geometría real, 8 colores, conservación de animaciones, de V10 y de LOD8, y reinstalación idempotente.
- `tests/test_g13_v11_finish_capture.gd`: crea **18 PNG renderizados realmente por Godot** (8 facciones, 7 ángulos, ataques aéreo/terrestre y acercamiento de rueda).
- `.github/workflows/g13-v8-final-art-audit.yml`: ahora valida V11 también en los pull requests y conserva las regresiones G13 anteriores.

## Aceptación pendiente

Revisar las capturas V11 sobre la V10, en particular el ajuste de los parabrisas inclinados, la visibilidad de ventanillas laterales bajo el alero, el techo posterior y la torreta durante barridos completos. No declarar el G13 visualmente finalizado hasta revisar estas vistas y medir rendimiento en un dispositivo Android.

**Sin cambios de balance:** este trabajo NO habilita ataques antiaéreos ni terrestres reales, no cambia daño, estadísticas, combustible, munición, alcance, economía, ni IA.
