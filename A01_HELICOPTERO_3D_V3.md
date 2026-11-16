# TARVOKA — A01 Helicóptero de ataque · V3 de silueta y rotores

**Estatus:** implementación real Godot 4.3 en PR #444, no integrada a main hasta superar regresiones. Revisión basada en 11 PNG auténticos de la escultura V2 (GitHub Actions A01 run 43813296914, artifact `tarvoka-a01-v2-360-review`).

## Observaciones confirmadas en la inspección real de V2
- Las cuatro palas del rotor principal se ven como planchas rectangulares de grosor uniforme; el extremo no se afina y la silueta carece de barrido.
- El rotor posterior queda visualmente como una cruz sin alojamiento; falta el soporte protector.
- Las dos alas portaarmas parecen cajas de color de facción, sin estrechamiento ni refuerzo de su raíz.
- El fuselaje y la cabina V2 están cerrados, ofrecen una base consistente y se mantienen.

## Sustituciones físicas realizadas (V3)
Archivo: `scripts/ui/AttackHelicopterRotorV3.gd`.
- Mantiene los cuatro pivotes originales animables y **oculta sus ocho piezas rectangulares anteriores**, sustituyéndolas por palas selladas con superficies de espesor real, ancho variable y punta aerodinámica, bisagra de paso, plato cíclico y cuatro bielas.
- Rotor de cola: conserva el pivote original, reemplaza cuatro palas rectas por perfiles cerrados delgados y suma un aro fijo de 24 segmentos y tres soportes metálicos que no giran con él.
- Alas: oculta las cajas V1, crea dos perfiles cerrados trapezoidales con riostras y nervaduras enraizadas; reduce el color de facción a una franja superior, sin convertir cada ala completa en un bloque saturado. Mantiene los soportes y armamento V1 de ocho tubos.
- Modelos de casco/cabina V2, rampa de movimiento y cañón original se conservan. Se mantiene una comparación V1/V3 reversible sin mallas fantasma.
- **Ningún cambio táctico**: la nueva escultura sólo aparece en el Estudio 3D con `art_level >= 13`. El LOD de Android en batalla no recibe estos objetos ni sus costes de dibujo.

## Verificación solicitada
- `tests/test_attack_helicopter_v3.gd`: ocho facciones, sustitución (nunca superposición), grosores, articulaciones, reversibilidad de piezas y animación del rotor.
- `tests/test_attack_helicopter_v3_capture.gd`: ocho ángulos 360° y tres acercamientos específicos a rotor, ala y cola. Produce `tarvoka-a01-v3-360-review`.
- `.github/workflows/a01-helicopter-qa.yml`: ejecuta V1, V2 y V3 y captura con Godot/Mesa virtual.

## Próxima revisión
Inspeccionar 11 PNG V3; seguir sobre los acabados del motor, proporciones frontales, geometría de la cabina y traspaso de material entre ala y fuselaje. No declarar acabado comercial sin revisión visual y pruebas de integración.
