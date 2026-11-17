# TARVOKA · Helicóptero HAT-29 A01 · revisión artística V14.1

## Motivo
El acabado V14 identificaba la facción con demasiado esmalte vivo en todo el casco, nacelas, puertas y cola. El A01 necesita parecer una aeronave militar de metal, no un aparato completamente pintado de azul, rojo, verde o amarillo.

## Cambio real en Godot 4.3
- `scripts/ui/AttackHelicopterFactionV14.gd` conserva la paleta oficial de las ocho facciones, pero mezcla el tono sobre grafito naval. La intensidad del casco baja de 0,79 a 0,52; los paneles laterales, de 0,84 a 0,57; la cola, de 0,87 a 0,50. La banda de identificación conserva 0,83 para reconocerse.
- Los acentos de pintura secundaria en motores, alas y aleta dejan de dominar el aparato; predominan metal gris, cristales y zonas oscuras.
- Nuevo volumen nativo `A01V14_1_AccesosYJuntasTacticas`, unido al fuselaje del A01: marcos elevados de ambas puertas, bisagras, remaches modelados, registros de servicio en los motores y abrazaderas sobre la viga de cola. No son texturas ni fotografías.
- La capa es idempotente y solo se construye para el modelo hero del Estudio 3D. No se añade ninguna geometría al LOD10 de batalla.

## Conservación
No cambia ninguna animación de rotor, vuelo, cañón, doble misil, impacto de bala, impacto explosivo, cinco etapas de daño, caída, fragmentos, reparación o selección de facción. Tampoco cambia economía, IA, HP ni estadísticas.

## Validación
`tests/test_attack_helicopter_v14.gd` ahora exige el acabado atenuado exactamente para las ocho facciones, verifica piezas nuevas de geometría real y confirma que el modelo Android ligero sigue sin incorporarlas. El flujo `a01-v14-hat29-visual-qa.yml` ejecuta Godot nativo y genera 14 capturas de referencia. Integrar al visor principal únicamente después de comprobar la ejecución y la ausencia de regresiones.
