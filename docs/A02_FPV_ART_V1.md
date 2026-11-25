# A02 — Dron FPV · V1 EN DESARROLLO

Siguiente unidad del catálogo tras A01 FINAL. Escultura ficticia de cuatro rotores protegidos, corona de facción, visor y carcasa. Modelo visual nativo, no especificación física. No se cambian reglas ni estadísticas. Dos LOD, ocho facciones, animación visual de movimiento e impacto. Pendientes CI, refinamiento, daño y revisión del visor.

## V2 — revisión de silueta

V1 pasó la prueba nativa 45659746138 y APK; las capturas 15044940979 muestran una silueta demasiado redondeada y color uniforme. V2 cambia solo la escultura visual de carcasa, corona, parte inferior y uniones decorativas a volúmenes biselados cerrados; pigmento opaco gradual en la geometría existente de los protectores. No se modifican los rotores animados, estadísticas ni lógica. QA añade cierre, winding, colores y cuatro vistas. Pendientes CI y revisión; se mantiene en desarrollo.

## V3 — acabado de la escultura exterior

V2 validada en Godot (45662099742) y APK (45662099726). Inspección del artefacto 15045202607: nueva silueta correcta, frontal aún redondeado y protector de color excesivamente uniforme. V3 cambia la cara decorativa por dos volúmenes biselados opacos, incorpora pigmento tonal en la carcasa existente y modera la pintura de los protectores. Conserva ocho colores oficiales, animaciones y LOD. Añade verificación de cierre, solapamiento visual y quinto ángulo de inspección. No se cambia la lógica de juego. Pendiente QA V3 y publicación.

## V4 — normales y lectura de superficies

V3 aprobada en QA nativa 45662716883; 21 renders del artefacto 15046441455. V4 conserva exactamente las posiciones y triángulos de la escultura V3. Asigna normales exteriores por cara para separar ópticamente tapas, biseles y paredes; conserva winding horario y verifica el cierre por posiciones. Corona y distintivos comparten pigmento opaco por vértice, con el color oficial completo en la parte superior y transición sombreada en el borde; se aclara ligeramente el tono neutral inferior. QA comprueba normales unitarias y planas, pigmentos, siete vistas y 16 combinaciones. Solo arte ficticio, sin cambios de catálogo ni de mecánicas. CI y publicación pendientes.

## V5 — identidad gráfica de la escultura

V4 pasó QA nativa 45663568352 y compilación Android 45663568410. Se revisaron 23 capturas reales del artefacto 15046861780. V5 añade relieves ornamentales cerrados de la corona y parte posterior en los dos LOD, más dos acentos y una insignia inferior solo en LOD13. Se conservan la silueta, colores principales, lógica y animaciones previas. QA verifica presencia, cierre, solapamiento AABB y separación de LOD. Pendientes nuevas capturas, CI y publicación. Sin cambios a otros modelos ni mecánicas.

## V6 — coherencia de materiales y recursos visuales

Acabado tonal opaco en el frontal decorativo y su marco, carcasa gris ligeramente más clara y contraste neutro automático para la insignia superior según luminancia de la pintura oficial. Los cuatro protectores comparten una sola malla y material por instancia; se mantienen posiciones, topología y cantidad de triángulos. QA añade comprobación de recursos compartidos, contraste, pigmentos y opacidad. V5 aún estaba en CI al iniciar V6; ambas revisiones requieren validación. Sin cambios de armamento, mecanismos reales, animaciones, estadísticas ni otras unidades.

## V7 — animaciones de presentación

V6 QA nativa 45665256338, APK 45665256201 y reglas 45665256190 aprobadas. V7 añade una pose de suspensión puramente visual, suaviza los movimientos de presentación y la reacción a impacto, restablece exactamente la pose al inicio y final, incorpora controles en el catálogo del Studio compartido y cancela el tween al cambiar de unidad o facción. Pruebas de poses intermedias y restauración en 16 combinaciones. Sin cambios a geometría, mecánicas, armamento, navegación ni estadísticas. Pendiente CI y publicación V7.

## V8 — cinco estados de daño puramente visual

D0 restaura los materiales originales; D1–D4 aplican tonos de desgaste progresivos, D2–D4 muestran volúmenes de humo estilizados y D4 una pose de ruina. Controles en el mismo Studio, daño conservado al cambiar facción y al detener animación. No cambia HP ni reglas, ni representa mecánica física real. QA verifica 80 estados, materiales opacos, restauración, bloqueo de pose de presentación D4 y cinco capturas reales. V7 aún no tenía ejecuciones registradas al comenzar; V8 requiere CI y publicación.

## V9 — acabado del daño de presentación

Variación tonal de desgaste entre superficies ornamentales, preservación del color de facción en D1–D3, humo opaco estilizado con transición tonal y oscilación de presentación, caída D4 interpolada en el mismo Studio. Detener o cambiar de facción conserva el estado; D0 restaura todos los recursos originales. QA amplía verificación de la caída y restauración de cada material. V7/V8 todavía no mostraban ejecuciones al iniciar esta revisión; no se afirma validación ni publicación. Sin cambios a reglas o mecánicas reales.

## V10 — inventario de recursos de presentación

Se añade informe JSON de las 80 combinaciones de las ocho facciones, dos LOD y cinco estados visuales, con instancias visibles, triángulos y recursos únicos de malla y material. Se conserva la geometría y el presupuesto existente de triángulos; se verifica un máximo inicial de 40 instancias visibles. No se presentan estos conteos como FPS, memoria o batería medida en Android. Pendientes ejecución, sincronización segura con main y publicación. No se alteran mecánicas ni modelos de otras unidades.
