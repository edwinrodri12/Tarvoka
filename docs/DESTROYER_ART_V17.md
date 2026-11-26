# Destructor naval TARVOKA — V1.7

Arte ficticio nativo; sin cambios de estadísticas, navegación táctica ni reglas de hundimiento. Incluye casco, puente, módulos, sensores, popa, materiales opacos, animaciones reversibles y daño D0–D4. El hundimiento desplaza únicamente la geometría del modelo, no la posición de batalla. Visor compartido: selector de unidad y controles de facción/LOD/daño/animaciones, enlace `?unidad=destroyer`. QA prevista: 18 combinaciones, 90 estados de daño, 19 capturas nativas y una captura del mismo visor. Pendientes resultados de CI, revisión de renders y rendimiento real en Android; no fusionar hasta validar.

## V1.8 — revisión a partir de renders nativos

V1.1, V1.2 y V1.3 finalizaron QA nativo correctamente. Run V1.3 45685425805, artefacto 15057905853, ocho PNG inspeccionados. Se observaron silueta simplificada, estela rectangular y placas de color sobresalientes. V1.8 elimina la malla rectangular de estela, alarga ligeramente la proa y popa, ajusta el esmalte y añade remates longitudinales, registros y barandillas LOD13. Las nuevas cámaras se acercan al modelo y añaden dos detalles. QA prevista: 18 variantes, 90 estados, 21 PNG nativos y un PNG del visor unificado. Las revisiones V1.4–V1.8 y el visor aún requieren confirmación; no fusionar por anticipado.

Se añadió además un detalle de cubierta deformable, inclinación de puente alrededor de su base, descenso visual completo y efectos transitorios separados de daño persistente. El visor exige reparación explícita para volver a animar un modelo crítico o destruido. Pendiente validar estos cambios en motor.

## V1.9 — auditoría real V1.8 y correcciones

Run 45689956602: 18 variantes, 21 PNG y 90 estados aprobados. Run 45689956712: exportación web falló por dos miembros heredados duplicados (naval_controls y naval_damage_picker). Se aíslan todos los nombres nuevos de destructor del adaptador de base naval. En las 21 capturas V1.8 se observa z-fighting de esmalte en popa, daño poco visible y apariencia simplificada. V1.9 integra color de facción en los vértices del casco único, elimina la segunda envolvente y placas superpuestas; aumenta legibilidad de daños y efectos opacos/emisivos, agrega dos encuadres de daño. 23 capturas previstas. El fallo G13 V11 en el run 45689956774 sigue abierto; no se modifica su modelo ni sus pruebas. Pendiente CI nativa/Web y revisión visual V1.9.

Seguimiento V1.9: animación periódica y reversible de humo/fuego; comprobación de precisión de color de 8 bits; regresión explícita de independencia de los controles de la base naval y el destructor. El mismo fallo G13 V11 se reprodujo en run 45688129493 anterior a V1.8.

## V1.10 — revisión de capturas V1.9

V1.9 QA nativa aprobada (run 45754404385, artefacto 15086149679, 23 PNG revisados). Se añade grano metálico procedural compartido con mipmaps en LOD13, detalles de servicio de popa y ventilación, marcas visibles en pasillos y quemaduras D3. Se amplía QA a 27 imágenes, con cuatro etapas de hundimiento sobre una superficie de agua opaca y cámara fija. V1.10 aún requiere ejecución de Godot y exportación web; no se afirma validación ni publicación. El G13 no se altera.
