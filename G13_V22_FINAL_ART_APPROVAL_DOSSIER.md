# G13 V22 — Dossier de aprobación artística 3D

**Fecha de revisión:** 17 de noviembre de 2026. **Estado:** CANDIDATO A APROBACIÓN DE ARTE; todavía no aprobado por el usuario ni incorporado como unidad comprable del modo batalla.

## Alcance y evidencia original

Revisión visual de la galería **62 imágenes PNG renderizadas por Godot 4.3**, no ilustraciones sintéticas. Se examinaron de forma expresa vistas frontal, trasera, izquierda/derecha, superior, inferior y perspectiva; recámaras y cañones durante elevación de 42° y ataque a tierra de 7°; ruedas de ambos ejes, suspensión, transmisión, protectores inferiores y los ocho acabados de facción.

**Conclusión artística:** La forma del G13 ya es coherente para el estilo 3D simplificado de TARVOKA. No observé una pieza sobresaliente, un lanzamisiles o un defecto de encaje de gravedad suficiente para justificar una V23 geométrica sin nuevas observaciones del usuario. Los dos cañones presentan bocas huecas, recámaras diferenciadas y una torreta con rodamientos y blindajes conectados a sus pivotes. La V22 corrige el aspecto excesivamente plano de los bajos.

**No equiparar con una validación de producción:** las capturas son de un renderizador de software de Godot; todavía no sustituyen el juicio visual del usuario ni una prueba de FPS y texturas en un teléfono Android real. Esta revisión no demuestra colisiones perfectas de todos los triángulos en cada fotograma ni certifica animaciones desde todos los ángulos; esos riesgos se mantienen en la lista de integración.

## Lista formal de control

| Criterio | Evidencia de aceptación |
| --- | --- |
| Identidad de armas | Exactamente **dos cañones automáticos** y radar separado; sin lanzamisiles ni módulos de cohetes |
| Facciones | Ocho variantes originales con insignias y pinturas distintas |
| Vehículo | Chasis **4x4**, cuatro neumáticos, carrocería y cabina originales |
| Torreta | Acople V19 de azimut y elevación; blindajes V20 y costados visibles V21 |
| Bajos | Placas, 4 resortes, dos diferenciales, transmisión y 16 pernos agrupados V22 |
| Poses | Idle, movimiento, radar, apuntado/ataque aéreo y apuntado/ataque terrestre |
| Rumbos | Ocho direcciones, de cardinales a diagonales |
| Compatibilidad | LOD13 de estudio completo y LOD8 Android sin detalles cosméticos nuevos |
| Permanencia | Todas las poses reversibles, sin crear nodos nuevos durante la animación |
| Imágenes | 62 capturas de la V22, con comparación V21/V22 de idéntica cámara y 1.582 muestras de píxeles alteradas |
| Alcance de aprobación | **Arte 3D**; no registra el G13 como unidad jugable ni fija estadísticas de combate |

`tests/test_g13_final_art_candidate_v22.gd` recorre 8 facciones × 8 rumbos × 7 poses = **448 ejecuciones de animaciones**, dos LOD, geometría no vacía, identificación de cañones, muestras de materiales y ausencia de accesorios no aprobados. Produce `g13-v22-final-readiness.json` en la ejecución de CI como prueba examinable; el resultado se considera válido solo si las aserciones de Godot pasan. Se mantiene la regresión anterior de 62 capturas de todos los ángulos.

## Decisión recomendada

Marcar **G13 V22 como candidato de arte final**, sin introducir más detalle por inercia. La decisión de declararlo *definitivo y aprobado* corresponde al usuario después de inspeccionar el mismo [Estudio 3D TARVOKA](https://edwinrodri12.github.io/Tarvoka/). Tras la aprobación, la siguiente fase —**separada**— sería definir la unidad de combate y su integración en Android, conservando los requisitos de rendimiento, alcance, defensa, munición y ataques tierra/aire establecidos para TARVOKA.

No reemplaza pruebas de batería, GPU, rendimiento real del dispositivo, colisiones físicas o balance de combate. No cambia el APK.
