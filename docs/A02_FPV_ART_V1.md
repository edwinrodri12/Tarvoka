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
