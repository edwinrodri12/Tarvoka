# TARVOKA · G13 V29 · radar telescópico abatible (modelo artístico)

## Motivo del rediseño

V28 dio una base anclada físicamente a la cubierta y separó el blindaje de la torreta. No basta para el **barrido de los dos autocañones**: sus volúmenes atraviesan algunas posiciones del antiguo radar. La V29 introduce un mecanismo visible, **sin cambiar el combate** ni añadir un lanzamisiles.

## Diseño del movimiento 3D

La V29 reutiliza tres elementos existentes del G13 táctico LOD8: `G13_RadarMast` (malla blindada de 96 triángulos), `G13_TiltedRadarDish` y `G13_RadarReceiver`. No aparece ningún `MeshInstance3D` nuevo. El pivote original `G13_RadarAzimut` mantiene el barrido de orientación Y.

- **Reposo:** mástil elevado V28, plato a 68° respecto a la horizontal local, búsqueda independiente de la torreta.
- **Al girar hacia atrás:** se inicia el repliegue a 40° desde el frente y se completa a 80°, de modo que la elevación del arma no obligue a atravesar el radar.
- **Mástil telescópico:** los mismos vértices del mástil se compactan en altura al 22% (sin aumentar polígonos) y el conjunto se inclina 35° hacia la parte posterior.
- **Plato de búsqueda:** cambia su ángulo local de 68° a −35°, prácticamente horizontal cuando el pivote se inclina; el receptor desciende con el conjunto.
- **Pie anclado:** en cada fotograma se calcula la posición real del pie después del giro y de la compresión, trasladando el pivote original para mantener el contacto con la cubierta posterior en `(0, 1.095, 1.135)`.
- **Reapertura:** cuando la torreta se aleja del sector trasero, la geometría retorna suavemente a la posición elevada original. Las animaciones de 7°/42° de cañones y las ráfagas existentes se mantienen.

Este mecanismo se aplica únicamente a `aa_mobile` con `art_level=8` si están las marcas V28/V29. El modelo detallado V24 LOD13 nunca recibe este repliegue.

## Pruebas de diseño

La escena de auditoría `tests/test_g13_folding_radar_v29.gd` genera **24 capturas reales de Godot 4.3**, ocho facciones y ejemplos de disparo hacia atrás a tierra y aire. Barre el eje de los cañones en incrementos de 5° en ambos dominios; utiliza las líneas centrales de los cilindros de cañón y boca de fuego, descontando sus radios, frente al segmento del mástil y el disco espacial del radar.

Debe observarse separación estrictamente positiva, base dentro de 2 mm del punto fijo y ausencia de nuevos nodos de dibujo. Son comprobaciones **geométricas de las piezas visuales**, no físicas de colisión de proyectiles ni un benchmark FPS en un teléfono.

## Estado del G13

V29 sigue siendo un **prototipo artístico visual**. No crea IDs de unidades ni habilita daño, misiles, experiencia, ventajas, selección de objetivos, parámetros de alcance o reabastecimiento. El enlace público del estudio solo se considera actualizado cuando termine satisfactoriamente la exportación Godot Web desde la rama principal.
