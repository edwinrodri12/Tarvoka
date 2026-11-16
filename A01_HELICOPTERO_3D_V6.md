# TARVOKA — Helicóptero de ataque A01 / escultura 3D V6

**Estado:** trabajo real en Godot 4.3, rama de desarrollo PR #444; no publicado en el Estudio 3D hasta que sea revisado y fusionado.

## Evidencia de la V5 y prioridad elegida
Las 11 capturas reales V5 mostraban patines tubulares curvos, pero las articulaciones V5 seguían siendo esferas grandes, una banda rectangular de goma seguía atravesando todo el patín y faltaban mecanismos reconocibles en las uniones del tren. La prioridad V6 es corregir esas zonas **sin cambiar el casco V2, rotores V3, motores V4 ni el tren estructural V5**.

## Acabados mecánicos V6
`scripts/ui/AttackHelicopterLandingFinishV6.gd`
- Cuatro amortiguadores telescópicos físicos (dos por lado). Cada uno conserva su V5 soporte inclinado, incorpora un cilindro oscuro exterior, un pistón metálico, collar de retención, guardapolvo, pasadores superiores e inferiores y orejetas de unión.
- Las cuatro esferas de anclaje superior V5 y cuatro de codo inferior V5 quedan ocultas, reemplazadas por pasadores y orejetas. No se crea una doble capa de articulaciones.
- Abrazaderas circulares alineadas con los dos patines y cuatro protectores cortos de goma en cada costado, hechos de sólidos 3D; se oculta la tira larga rectangular de goma V5.
- Protectores terminales compactos en las puntas ascendentes de los patines y una diminuta marca de facción.
- Dos costuras elípticas segmentadas (16 tramos cada una) que siguen la superficie de las monturas ovaladas V5 de los motores, más pernos de fijación.
- Comparación V5/V6 reversible, igual que la comparación histórica V1/V6 ofrecida en el Estudio. No toca animaciones de rotores, cañón ni movimiento de unidad.
- Exclusivo `finish_enabled && art_level >= 13`. Se conserva el antiguo LOD del campo de batalla en Android y todas las estadísticas de combate.

## Inspección y criterios de aceptación
- `tests/test_attack_helicopter_v6.gd`: comprueba ocho facciones, 4 amortiguadores telescópicos, 8 pasadores, abrazaderas, protecciones, juntas ovaladas, reversibilidad y modelo táctico intacto.
- `tests/test_attack_helicopter_v6_capture.gd`: genera once imágenes reales Godot (ocho orbitales y tres macros: amortiguadores, abrazaderas, conexión motor).
- Workflow A01 QA V1–V6 y subida del artifact `tarvoka-a01-v6-360-review`.
- No declarar aprobado sin comprobar el resultado del CI ni evaluar capturas. El fallo de sprites HQ global permanece separado de los tests A01.

**Siguiente prioridad candidata:** inspección visual de 360°, alineación de las juntas con los sólidos de motor y escala de piezas frente al modelo completo. Después corregir exceso de detalle a tamaño de juego si fuese necesario.
