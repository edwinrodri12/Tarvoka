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

## V11 — candidato de revisión y validación del visor

V10 verificada en 80 estados (45672543112, artefacto 15049803591); APK 45672543084, reglas 45672543209 y construcción Studio 45672542959 correctos. En D0 LOD8: 27 instancias / 2436 triángulos; LOD13: 34 / 5688. Máximo D3: LOD8 29 / 2636, LOD13 36 / 5888. El trabajo no mide FPS o RAM de teléfono. V11 conserva el arte V10 sin cambios: añade evidencia de entrada WebGL de solo lectura y prueba Chromium de las dos rutas A02/fpv, selector, opacidad y catálogo de animaciones. La marca de revisión de Studio identifica el código exacto. El despliegue público está reservado a main, no se declara publicado ni aprobado. Pendiente prueba de navegador V11, decisión artística y regresión independiente G13.

## V12 — acabado estilizado del humo para revisión

V11 nativa 45679598133 y APK 45679598443 correctas. La construcción WebGL V11 seguía ejecutándose al comenzar. V12 refina exclusivamente el efecto de presentación D2–D4 con tres volúmenes opacos superpuestos, tonalidad moderada y una malla compartida; LOD8 conserva segmentos y anillos previos, LOD13 mejora suavidad. D0 y geometría del cuerpo intactos. QA verifica solapamiento, reutilización, LOD y presupuesto. El informe de recursos se identifica V12. Prueba WebGL y publicación pendientes; no se afirma aprobación artística ni se cambian reglas.

## V13 — reparación de la integración editorial

V12 nativa 45680700033, APK 45680699952 y reglas 45680699891 correctas. Publicación 45680699971 falló al preparar los campamentos: el candidato estaba desfasado respecto de main y faltaba CampMedicalSculptV3.gd. Se integra main 71387f6b con sus archivos de campamento médico V3 y se conservan las siete rutas del A02; no se omite ninguna comprobación. Se añade un mensaje de error explícito con el archivo faltante y se fija la fuente de main a la revisión del evento. Sin cambios a arte V12 ni lógica. Pendiente nueva ejecución WebGL y publicación efectiva.

## V13.1 — compatibilidad con la revisión del ingeniero

QA nativa 45684237774, Android 45684238037 y cuatro campamentos 45684237874 correctas. Preparación de fuentes del Studio 45684237658 superada; exportación pendiente al sincronizar. Main 398650a5 incorpora tres commits adicionales del ingeniero; se aplican únicamente los cambios del A02 sobre esa revisión sin modificar su arte ni sus pruebas. El conflicto editorial se resuelve manteniendo ambos conjuntos de cambios. No se considera publicada ni aprobada esta unidad hasta verificar el navegador y el despliegue.

## V16 — refinamiento visual del deterioro (candidato)

Rama independiente desde e2532da3 para no cancelar las pruebas de V15. Los tres volúmenes decorativos de humo conservan una sola malla opaca y los presupuestos de detalle. Se ajustan la asimetría, anchura, inclinación y movimiento visual; D4 conserva visibles y estáticas las piezas de presentación, sin desapariciones abruptas. D0 conserva el modelo intacto. QA amplía la verificación de inclinaciones, estados inválidos, piezas visibles y restauración exacta. Los identificadores del visor y del manifiesto se actualizan a V16. Pendientes compilación Godot, comparación real de los renders, navegador, Android y publicación. Sin cambios a estadísticas, reglas, navegación ni otras unidades.

## V16.3 — inspección integrada

Auditoría pública 45902899868 confirmó V16 (commit bd44a74a), paquete íntegro y WebGL en ambas resoluciones. V16.3 incorporó cámaras frontal, posterior, laterales, superior e inferior y giro 360°, conservando foco al cambiar facción. QA 45903346923, 45903346947, 45903346982 y 45903347076 correctas; cinco capturas del Studio (15157765682). Integrada en main 01a6024e. Publicación de cámaras pendiente de comprobación independiente.

## V17 — acabado satinado y transición de normales (candidato)

Suaviza únicamente las normales horizontales de paredes y biseles (42 % hacia la dirección radial) sin alterar vértices, silueta, triángulos, planos superior/inferior ni cierre. Ajuste moderado de rugosidad y reflectancia de pigmentos opacos. Pruebas de topología exacta, normales unitarias hacia afuera, diversidad angular, pigmento y acabado; conserva estados D0–D4 y controles. Identidad V17 en Studio y manifiesto. Pendientes compilación Godot, comparación visual y despliegue. Sin cambios de catálogo, juego ni otras unidades.

## V18 — revisión del acabado inferior (candidato separado)

V17 nativa 45906266524 y APK 45906266416 correctas; comparación visual de los 52 renders y 80 estados confirma suavizado discreto, inventario idéntico a V16. La V18 conserva la geometría de la carcasa inferior, diferencia su pigmento, recupera contraste de la insignia y añade dos relieves ornamentales cerrados e integrados, solo LOD13. LOD8 intacto en triángulos e instancias. D0 LOD13 previsto: 36 mallas/5808 triángulos; D4 máximo previsto 39/6672. Estos conteos son expectativas a comprobar en Godot, no mediciones. QA y manifiesto preparados; rama separada para preservar CI de V17. Sin cambios de reglas ni otras unidades.


## V18.1 — iluminación de inspección inferior (candidato)

La V17 se integró en main 8045d3e6 tras superar QA nativa, Android, reglas y WebGL. La publicación V16.3 45906128221 verificó la revisión 01a6024e y su paquete público. En capturas V17 se detecta iluminación inferior insuficiente para revisar el acabado. V18.1 añade únicamente una luz direccional blanca moderada, hija de la cámara del Studio y activa exclusivamente en la inspección inferior del A02; se desactiva al salir, cambiar de unidad o restablecer cámara. Pruebas verifican aislamiento y reutilización. No modifica el entorno compartido, geometría, materiales, animaciones ni juego. Rama separada para conservar CI V18. Pendiente validación Godot y comparación real de capturas.

## V19 — referencia artística Bastion (candidato)

El usuario solicita elevar el acabado de A02 al estándar visual del Bastion, no considerar la unidad terminada por pasar QA técnica. Comparación de capturas reales P06 15156604740 y A02 V18 15158576987: el A02 tiene superficies lisas y menor riqueza visual a corta distancia. Primera revisión: pigmentación ornamental opaca de múltiples tonos sobre la corona, textura UV compartida 128×128 con mipmaps, segmentación decorativa de color en las superficies anulares; sin añadir partes, modificar dimensiones, mecanismo, animaciones o reglas. Se preservan triángulos, contornos cerrados y colores oficiales. QA comprueba textura opaca, reutilización, UV, presupuesto y navegador. El Bastion es referencia de acabado, no de estructura. Pendientes renders Godot y evaluación artística; no FINAL.

## V20 — atlas ornamental de cuatro familias (candidato)

V19 proyectaba UV desde arriba, dejando paredes con coordenadas colapsadas. V20 separa las familias superior, inferior, lateral y extremos mediante un atlas opaco compartido de 256×256 con mipmaps; aplica motivos gráficos distintos a corona, casco y base, sin añadir geometría ni piezas funcionales. Comprobación matemática independiente de las 60 caras: 4 regiones ocupadas (6/6/36/12 triángulos), ningún cruce de zona, coordenadas locales 0.03125–0.96875 y área UV no degenerada (producto cruzado mínimo 0.008005). Esto no sustituye la compilación ni render real. Se conserva el presupuesto de V18. Rama independiente para no cancelar V19. Referencia global de calidad en docs/UNIT_ART_QUALITY_STANDARD.md. Pendientes renders, revisión y aprobación del usuario.
