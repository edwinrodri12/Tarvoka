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

## V1.11 — superficies y contexto marino del visor

Proyección triplanar del grano metálico en LOD13; ajuste de rejillas de ventilación y detalles de cubierta trasera. El mismo visor incorpora una superficie de agua aislada para el destructor, cámara de superficie y vista inferior con agua oculta. Al cambiar de unidad o edificio, se oculta el agua; el hundimiento vuelve a la vista de superficie. Pruebas ampliadas de aislamiento, cámara y proyección, conservando 27 capturas previstas. Las pruebas V1.10 y exportación V1.9 aún estaban en cola al desarrollar esta revisión. No se afirma validación ni despliegue de V1.11.

Seguimiento V1.11: la vista inferior oculta temporalmente las mallas de suelo preexistentes, registra solo las que estaban visibles y las restaura al salir de la inspección o cambiar de unidad/edificio. Regresión con una malla de suelo de prueba añadida al SubViewport original.

## V1.12 — geometría de aristas, iluminación y reconciliación

V1.11 validada en Godot (45755947399, 27 PNG, artefacto 15088536511), compilación del visor compartido aprobada (45755947504, artefacto 15088538767), APK y reglas aprobados; 24/25 checks, único fallo G13 V11 anterior. Revisión visual de todas las capturas: casco y hundimiento completos; algunas carcasas suavizadas en exceso. V1.12 separa normales por panel longitudinal y tapas para obtener aristas definidas conservando volumen cerrado. Añade luz de inspección direccional opcional con sombras, aislada del resto de unidades. 29 PNG previstos. Reconciliación de 33 commits de main (bd44a74a9c124362882f3c865465eea994198102): cambios disjuntos en UnitModels3D y Pages, sin sustituir los nuevos desarrollos. Pendiente QA del resultado reconciliado.

## V1.13 — petición de mayor identidad y acabado tipo Bastión

Se amplía la pintura integrada del casco de dos a cuatro caras longitudinales (84 a 168 vértices, sin aumentar geometría ni superponer mallas). Se añaden cinco superficies de esmalte en el techo del puente, tapas de servicio y bordes posteriores, manteniendo acero neutro y los ocho tonos oficiales. LOD13 añade mapa de normales satinado procedural compartido y dos tapas de servicio biseladas con juntas/remaches; LOD8 no recibe nuevas mallas ni texturas. QA prevista: 18 variantes, 90 estados, 38 PNG incluyendo las ocho facciones y neutral con cámara fija. Etiquetas del visor actualizadas. Pendiente validar Godot, inspección comparativa con Bastión, publicación y dispositivo físico. No se cambian mecánicas ni otros modelos. La revisión de publicación #712 continúa separada y debe reconciliar su versión antes de fusionarse.
