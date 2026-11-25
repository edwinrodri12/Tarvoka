# Destructor naval TARVOKA — V1.7

Arte ficticio nativo; sin cambios de estadísticas, navegación táctica ni reglas de hundimiento. Incluye casco, puente, módulos, sensores, popa, materiales opacos, animaciones reversibles y daño D0–D4. El hundimiento desplaza únicamente la geometría del modelo, no la posición de batalla. Visor compartido: selector de unidad y controles de facción/LOD/daño/animaciones, enlace `?unidad=destroyer`. QA prevista: 18 combinaciones, 90 estados de daño, 19 capturas nativas y una captura del mismo visor. Pendientes resultados de CI, revisión de renders y rendimiento real en Android; no fusionar hasta validar.

## V1.8 — revisión a partir de renders nativos

V1.1, V1.2 y V1.3 finalizaron QA nativo correctamente. Run V1.3 45685425805, artefacto 15057905853, ocho PNG inspeccionados. Se observaron silueta simplificada, estela rectangular y placas de color sobresalientes. V1.8 elimina la malla rectangular de estela, alarga ligeramente la proa y popa, ajusta el esmalte y añade remates longitudinales, registros y barandillas LOD13. Las nuevas cámaras se acercan al modelo y añaden dos detalles. QA prevista: 18 variantes, 90 estados, 21 PNG nativos y un PNG del visor unificado. Las revisiones V1.4–V1.8 y el visor aún requieren confirmación; no fusionar por anticipado.

Se añadió además un detalle de cubierta deformable, inclinación de puente alrededor de su base, descenso visual completo y efectos transitorios separados de daño persistente. El visor exige reparación explícita para volver a animar un modelo crítico o destruido. Pendiente validar estos cambios en motor.
