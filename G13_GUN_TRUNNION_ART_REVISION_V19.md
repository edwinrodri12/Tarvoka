# G13 — Modelado 3D V19 | articulación de torreta y cañones

**Prioridad artística posterior a V18:** mejorar las uniones de los dos cañones automáticos con la torreta, desde las vistas superior, frontal y laterales, y durante ataques terrestres/aéreos.

## Geometría real añadida

- Dos **rodamientos huecos** con mallas `ArrayMesh`, 20 segmentos y cuatro superficies físicas (cara lateral, camisa exterior, camisa interior y cara interior), en `G13_TorretaAzimut`. Radios: interior 0,100 m, exterior 0,137 m; profundidad 0,087 m, adelantando la cara exterior por fuera del blindaje lateral; sin discos sólidos ni tapas falsas. Siguen el azimut original de la torreta.
- Dos **cubos móviles** de eje de cañón (radio 0,080 m) dentro de los rodamientos, en `G13_ElevacionCanones`, que siguen el ángulo de elevación del arma.
- Dos **refuerzos de recámara** biselados, malla cerrada de dos perfiles octagonales, que unen visualmente el bloque de cierre de V18 con el eje de elevación. Se integran en el mismo pivote de movimiento. No son lanzadores ni compartimentos externos.

Son seis piezas 3D nuevas, sin texturas que simulen geometría, sin fuentes de luz adicionales y sin cambiar los cañones huecos V12, retroceso V4, colores de las ocho facciones, radar, vehículo o reglas de juego. **Cero misiles/lanzadores, dos cañones**. Se aplica exclusivamente al detalle LOD13; el LOD8 Android no cambia.

## Comprobación

`tests/test_g13_gun_trunnion_v19.gd`: ocho facciones, verificación de la topología y hueco central real, radios/huelgos físicos, pivotes correctos (azimut fijo / elevación móvil), ataques aire y tierra, barrido de radar, idempotencia y LOD8 sin modificaciones.

`tests/test_g13_v19_visual_capture.gd`: 44 fotografías nativas desde Godot, incluidos acercamientos a ambos ejes, elevación alta/baja, una comparación V18/V19 de la unión con **cámara idéntica** y las inspecciones previas de carrocería, ruedas, radar, colores, cañones, noche y 360°.

El nuevo módulo se carga desde `UnitModels3D.gd`, se etiqueta en el mismo selector del Estudio 3D y se incluye en el disparador de GitHub Pages. Es un **modelo de arte**, aún no una unidad de combate registrada en TARVOKA. La aprobación final se decidirá al revisar las nuevas capturas/visor.
