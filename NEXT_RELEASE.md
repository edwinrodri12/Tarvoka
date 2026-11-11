# TARVOKA — Próxima entrega agrupada para Android
**Estado:** preparación interna · **Fecha:** 2026-11-10 · No es una APK publicada al usuario.
**Política acordada:** no ofrecer ni descargar APK por cada PR; compilar mediante CI para asegurar que el proyecto sigue exportando correctamente. Entregar un APK agrupado cuando se necesite una validación real del conjunto o el usuario lo solicite.

## Cambios incluidos desde el gameplay anterior
- PR #45–#47: interfaz horizontal adaptable, resultado VICTORIA/DERROTA y aviso de error de autoguardado.
- PR #48–#51: recuperación desde respaldo validado, confirmación de movimiento/ataque, resumen enemigo y prueba real de victoria/derrota.
- PR #53: IA con prioridad de eliminaciones y persecución que rodea terrenos impasables.
- PR #54: tres campos originales (abierto, bosque y puentes) con aspectos/costos de movimiento distintos, selector antes de Nueva partida.
- PR #55: caché de información táctica; evita repetición de cálculo de rutas con pantalla inactiva.
- PR #56: siluetas aliadas circulares y enemigas cuadradas, HP numérico y bajas/supervivientes.
- PR #57: bloqueo de guardados malformados y victorias incoherentes.
- PR #58–#59: 12 batallas simuladas IA×IA, modo Entrenamiento vs Simétrico, elección de fuerza inicial transparente.
- PR #52: integrado en main, comprueba biblioteca nativa ARM64 y registra huella pública de certificado en pipeline. La firma de depuración sigue siendo efímera.

## Verificaciones automáticas
Cada PR integrado tuvo su Godot 4.3 headless SUCCESS y Android debug APK export SUCCESS. TESTS.md contiene IDs y alcance. Las 12 simulaciones terminan sin deadlocks; Entrenamiento azul 6–0, Simétrico 3–3. Esto no demuestra funcionamiento del nuevo conjunto en hardware Android, ni balance competitivo general.

## Pruebas imprescindibles al entregar una APK consolidada
1. Instalar en móvil Android ARM64; la firma debug CI puede variar entre compilaciones y obligar a desinstalar (se perderían archivos user://).
2. Confirmar diseño horizontal, legibilidad de casillas, diferencias de terreno, cuadros de selección y HP/unidades por forma.
3. Elegir Bosque o Puentes y confirmar Nueva partida; observar agua bloqueada, costos de terreno y que las unidades no crucen zonas impasables.
4. Seleccionar una unidad, tocar destino una vez (solo previsualiza), tocar segunda vez o Confirmar orden (ejecuta), probar Cancelar selección sin gastar acción.
5. Probar Entrenamiento y Simétrico. En Simétrico, ambos bandos inician HP10/ATQ5; en entrenamiento X/Y HP8/ATQ4.
6. Terminar turno, verificar movimientos/ataques IA, informe del turno, estados de victoria/derrota y bloqueo de acciones posteriores.
7. Guardar manualmente y autoguardar, cerrar completamente aplicación, volver a abrir y comprobar posiciones/vidas/facción/terreno. **No declarar PASS antes del ensayo físico.**
8. Rotar dispositivo, revisar barras laterales/scroll y que los botones conserven áreas táctiles cómodas.
9. Registrar rendimiento percibido, congelamientos, temperatura y errores al cargar.
10. No describir la nueva firma como estable mientras las claves sigan siendo efímeras.

## Condiciones de salida
- PR y GitHub CI de la fuente consolidada en verde.
- Comprobación de certificado APK y arquitectura por pipeline; no confundir export exitosa con instalación real.
- Ninguna nueva fuente de pagos, anuncios o cuenta obligatoria.
- Reportar bugs de gameplay con commit/run y evidencia; corregirlos antes de declarar P0 cerrado.

## Cambios nuevos 2026-11-10 — niebla y reconocimiento
- PR #61–#65 integrados en main: visión por facción y exploración persistente, observación restringida de IA, modo Niebla y reconocimiento opcional, exploradores S/Z con visión5 frente a soldados3, casillas desconocidas oscuras y conocidas pero fuera de visión atenuadas, filtros de unidades ocultas para interfaz, ayudas y motor; IA tampoco conoce obstáculos de casillas no exploradas.
- La versión inicial usa distancia Manhattan; no simula sombras visuales de montañas/bosques ni posiciones enemigas recordadas.
- CI 42915400561/554, 42916085450/399, 42916908716/658, 42917319561/443, 42917859860/845 SUCCESS. 12 partidas fog automáticas sin bloqueos ni trampas observadas.
**Agregar al plan de pruebas físicas agrupadas:** iniciar niebla con ambos modos de fuerza; comprobar scouts S/Z (HP6/ATQ2/MOV4/visión5), limitar destinos a celdas visibles; confirmar que enemigo fuera de visión no se dibuja ni aparece en previews; acercarse y descubrir enemigo; retirarse y ver terreno atenuado sin enemigo visible; guardar, cerrar completamente y reanudar manteniendo casillas exploradas y modo elegido; alternar a partida clásica confirmada y comprobar que no queda niebla. Registrar capturas de comportamiento y FPS/legibilidad real. No afirmar visibilidad física verificada hasta recibir evidencia de teléfono. Sin APK por cada PR.

## Siguientes validaciones tras PR #66–#67
La nueva versión agrupada también incorpora montañas que ocultan casillas detrás de ellas y niebla totalmente opaca para terreno nunca explorado. Probar en mapa con montañas: esconder un enemigo detrás, comprobar que no aparece en el mapa ni en ataque/previa, trasladar explorador por otro lado y confirmar que aparece al estar a la vista; comprobar que la montaña en sí es visible. Revisar esquinas diagonales y terreno forestal (bosques no bloquean visión todavía). Godot 42918936432/42919298522 SUCCESS, Android 42918936216/42919298370 SUCCESS. No hay validación real de pantalla ni firma debug persistente todavía.

## 2026-11-10 — Aceptación agrupada adicional #68–#71
- Visión diagonal bloqueada coherentemente en ambos sentidos por montañas (#68); probar con exploradores en flancos opuestos.
- Avistamientos históricos no atacables con símbolo `?`, por bando, y eliminación al comprobar terreno vacío (#69); probar en pantalla pequeña sin confundir el símbolo con unidad enemiga real.
- IA se retira con vida críticamente baja solo hacia otros aliados bajo amenaza letal visible (#70); verificar que no huya indefinidamente ni bloquee el turno.
- IA investiga última posición observada sin conocer ubicación actual oculta (#71); probar con enemigo moviéndose tras perder visión.
- Test CI de 12 batallas detectó y corrigió un bloqueo de la primera versión de retirada (42935578821 FAIL, versión corregida Godot 42936080460 PASS). Códigos y compilaciones Android finales de los cuatro PR aprobados (ver TESTS.md).
- El usuario prefiere acumular mejoras antes de recibir APK; todavía **NO ENTREGADA NI VALIDADA EN TELÉFONO** esta ronda.

## 2026-11-10 — Novedad acumulada: victoria por relés (#72–#76)
El siguiente paquete de prueba incluye **Controlar relés y acumular señal** opcional en Nueva partida; predeterminado Eliminación clásica. Dos nodos situados en (4,2)/(5,5), marcar capturas al finalizar turno propio, +1 señal por relé propiedad por turno de esa facción, meta 5 puntos y victoria alternativa con enemigos supervivientes. UI incorpora marcadores, barra/etiqueta de puntos y reporte de capturas; la IA se dirige a relés según terreno conocido y visibilidad legal; sin revelar dueño de nodo fuera de visión.
**Validación Android solicitada para próximo paquete agrupado:** comprobar que elegir modo sin confirmar NO reinicie; jugar ambas condiciones de victoria; capturar/reconquistar relés; contrastar y leer iconos en mapa pequeño/con niebla; verificar señal Azul/Rojo, mensajes de fin de turno y pérdida, no recibir turno después de perder por puntuación, guardar manual/autosave, cerrar y reabrir y regresar a eliminación clásica sin objetivos residuales. Probar en mapa Puentes y Bosque. No se ha probado en Android físico en esta ronda; compilaciones CI aprobadas, IDs en TESTS.md. No enviar APK tras cada pequeño ajuste.

## 2026-11-11 — Interfaz y resultado de batalla consolidados (#81)
- Integrado en `main` por squash `f2db0ba6`: nuevo resumen táctico del ejército azul (unidades, unidades sin actuar y HP), visibilidad de contactos enemigos ajustada al estado de niebla; no revela enemigos ocultos.
- Los movimientos y ataques pendientes muestran resumen específico antes de confirmar, con costo de desplazamiento o daño previsto derivado de reglas autorizadas. Confirmar/Cancelar preceden a Terminar turno y a la leyenda en dispositivos pequeños.
- La pantalla de final de batalla conserva VICTORIA/DERROTA, distingue fondo verde/rojo y amplía pérdidas/supervivientes, HP restante de ambos ejércitos y puntaje de relés cuando aplique.
- CI verde sobre rama final de #81: Godot headless `42986650505`; Android debug export `42986650474`. **Prueba Android física: NO EJECUTADA.** No hay APK independiente entregada por este PR.
- Para la próxima APK agrupada, comprobar: botones en pantalla vertical y horizontal, vista previa sin consumo de acción hasta confirmar, daño coherente, resumen actualizado al mover/atacar, no revelar enemigos fuera de visión con niebla, reportes finales por eliminación y relés (incluyendo aliados y enemigos supervivientes), colores correctos de VICTORIA/DERROTA, cierre/recuperación y ausencia de acciones después del final. Un export CI correcto no equivale a instalación probada.

## 2026-11-11 — Mejora acumulada #83–#86
- IA puede priorizar **defensa puntual de relés propios vacíos** si un rival visible dispone de ruta legal de captura; conserva ataques letales y no usa unidades enemigas invisibles. Nuevo código #83, Godot/Android PASS.
- Panel de unidad amplía información del rol, costo real de terreno y cobertura de unidad; nunca promete bonus defensivo inexistente. Evita mostrar estadísticas de unidades enemigas ocultas (#84, CI PASS).
- Al preparar movimiento o ataque, Terminar turno queda deshabilitado hasta confirmar/cancelar; incluso llamada directa al handler no descarta órdenes (#85, CI PASS).
- Pipeline con capacidad opcional de firma de debug estable en `workflow_dispatch` en `main` tras configuración privada de tres secretos; PR sigue usando firma efímera (#86, CI fallback PASS). Ver `ANDROID_SIGNING.md`. No marcar firma persistente como activa.
- **QA próximo paquete Android:** verificar en móvil defensa IA sin estancarse ni revelar niebla, panel rol/terreno en landscape y portrait, acciones pendientes y terminos, guardado tras salida, resultados completos, rendimiento y contraste. Probar dos APK con firma estable solo cuando secretos estén configurados, **no desinstalar la APK con partidas sin estrategia de respaldo**.

## 2026-11-11 — Regla de turno corregida #92
La próxima APK agrupada incluirá **mover y atacar en el mismo turno** (sin movimientos ni ataques repetidos), alcances separados (soldados actuales ataque 1–1), selección persistente tras movimiento cuando existe enemigo visible atacable y capacidad equivalente de la IA. Para probar en móvil: seleccionar A, mover hasta quedar adyacente a X, confirmar movimiento, comprobar resaltado rojo y botón Confirmar ataque, atacar sin terminar turno, revisar HP; intentar segundo movimiento y segundo ataque; revisar variante niebla donde el enemigo aparece al mover; guardar tras mover y recuperar sin perder posibilidad de atacar. En modo clásico el resto del combate, los relés y guardados v1 siguen compatibles según CI. #92 Godot `43100988560` / Android `43100988685` SUCCESS; **QA Android físico pendiente**. Nuevo balance IA×IA cambió respecto al juego previo: no comparar cifras históricas sin aclarar la diferencia de reglas.

## 2026-11-11 — Próxima entrega acumulada también incluye #94–#95
- El resumen AZUL desglosa cuántas unidades **pueden mover** y cuántas **pueden atacar**, incluso después de un desplazamiento.
- La IA buscará un avance legal para rematar a un adversario **ya visible** en ese turno. Respeta mapa conocido, niebla y un solo movimiento por unidad. Si los bandos pierden contacto después de descubrir todo el mapa, continuará inspeccionando terreno conocido fuera de su campo visual para evitar estancamiento.
- Godot 4.3 final #94 `43109528938` PASS, Android `43109528977` PASS; #95 `43108759652`/`43108759673` PASS. **Sin APK individual**.
- QA físico: comprobar que los contadores cambian tras mover, atacar y al comenzar nuevo turno; la IA puede mover+rematar sin ventajas secretas; niebla oculta enemigos y al perderlos la IA patrulla; comprobar batalla/guardado después de cerrar y reabrir, pantalla vertical/horizontal, FPS y continuidad de partidas. La firma debug persistente requiere configuración privada, NO verificada.

## 2026-11-11 — Infraestructura táctica adicional #97
La IA contempla posiciones de tiro dentro de un **alcance mínimo/máximo propio** y calcula retiradas fuera de amenazas observadas de mayor distancia. No modifica todavía el conjunto de soldados de prueba (alcance 1–1) ni introduce artillería. Godot `43110595866` PASS, Android `43110595813` PASS; pruebas físicas y firma persistente siguen pendientes. La futura introducción de roles a distancia exigirá contramedidas, IA equilibrada y prueba de claridad visual/táctil.
