# TARVOKA — Documento rector de diseño
**Versión:** 1.0 · **Fecha:** 2026-11-10 · **Estado:** Aprobado como dirección de diseño; funcionalidades aún sujetas a implementación y validación.

## 0. Propósito y alcance
TARVOKA es un videojuego **original** de estrategia militar por turnos para Android, diseñado primero para funcionar offline, con controles táctiles cómodos, gran legibilidad y rendimiento en dispositivos de gama media. El análisis de críticas históricas de la saga Advance Wars es una fuente de **problemas de diseño a evitar**, no un modelo para copiar sistemas concretos, personajes, mapas, interfaces, gráficos, música, diálogos ni terminología distintiva.

**No equivalencia:** Estar en este documento NO significa que una funcionalidad exista en la APK. Cada cambio debe pasar por prototipo, pruebas de reglas, UX, balance y, cuando corresponda, prueba física.

**Estados de diseño**
- **[BASE]** Principios obligatorios y reglas de calidad desde el MVP, aprobados para la dirección del proyecto.
- **[PLAN]** Capacidad planeada; implementar por fases, con requisitos y evidencia.
- **[EXP]** Hipótesis de diseño: se prototipa y mide antes de decidir si se conserva.
- **[FUTURO]** Expansión posterior al juego offline estable; no es promesa del MVP.

## 1. Identidad y pilares
1. **[BASE] Inteligencia honesta:** IA que toma decisiones por objetivos con la misma información legal que el jugador; la dificultad debe mejorar el razonamiento, no regalar visión invisible.
2. **[BASE] Reglas transparentes:** claridad sobre alcance, coste, resultado previsto, peligro y condiciones de victoria. Decidir, no adivinar.
3. **[BASE] Accesibilidad con profundidad:** pocas reglas iniciales; múltiples decisiones estratégicas y estilos de juego. Tutorial opcional/contextual.
4. **[BASE] Ritmo y respeto al tiempo:** guardar y reanudar, acelerar/omitir presentaciones, evitar turnos muertos y repeticiones forzadas.
5. **[BASE] Equilibrio y contrajuego:** ninguna unidad/comandante debe carecer sistemáticamente de uso ni dominar sin respuesta; evitar estrategias únicas.
6. **[BASE] Identidad original:** mundo ficticio, facciones, unidades, sistemas territoriales, personajes, arte y audio propios; revisión de marcas USPTO/WIPO y PI antes de comercializar.
7. **[BASE] Offline primero:** partida completa sin cuenta, suscripciones ni conexión de red; evitar micromanejo y consumo innecesario de recursos del móvil.

## 2. Lo ya observado, separado de las metas
- **Verificado en pruebas automatizadas:** reglas 10×8, movimiento, combate, turnos, lógica de victoria, IA básica y persistencia del prototipo; CI Godot 4.3 documentado en TESTS.md.
- **Confirmado en teléfono por el usuario (2026-11-10):** APK abre, selección/movimiento táctil observables; después del hotfix de Android funcionan los tres botones inferiores, y al terminar turno la IA actúa y devuelve el control.
- **Sin confirmar en dispositivo:** batalla completa con victoria/derrota, integridad de guardar y cargar una partida tras cerrar/reabrir, rendimiento en múltiples equipos y orientación, nuevos elementos de este diseño.
- **Prototipo actual NO equivale a juego comercial:** unidades ilustrativas, mapa simple, IA básica, UI provisional.

## 3. Principios de combate, información y justicia
### 3.1 IA [BASE → PLAN]
- Evaluar objetivos de misión, amenazas, captura y defensa, relevancia económica, cobertura, supervivencia y capacidad de contraataque.
- **Prioridades visibles en pruebas:** defender una instalación en riesgo, explotar una captura viable, proteger unidades de alto valor, replegarse si una ofensiva es irracional, cambiar de frente si se estanca.
- Dificultad **Recluta / Soldado / Veterano / Estratega** [PLAN]: ajustar horizonte/heurísticas tácticas y coordinación, no información prohibida ni bonificaciones opacas.
- Presupuesto computacional por turno, comportamiento determinista en pruebas, límite temporal razonable en Android y fallback seguro si la IA no encuentra un plan.
- Evitar explotación de comportamientos repetitivos; testear mediante escenarios con ambas facciones.

### 3.2 Niebla de guerra y reconocimiento [BASE → PLAN]
- La IA solo identifica y ataca objetivos en celdas legalmente visibles; no leer estado oculto para decidir ataques o capturas.
- La IA puede conservar **última posición conocida**, antigüedad del dato y explorar, pero no tratarla como posición verdadera.
- Visión regulada por unidades, terreno, instalaciones y efectos; mismo motor de visibilidad para humano/IA. El UI diferenciará visible / explorado / desconocido.
- Probar ocultación, pérdida de contacto y búsquedas sin trampas. Reconocimiento, sensores y niebla dinámica [EXP] solo tras validar coherencia.

### 3.3 Resultados predecibles y control del error [BASE → PLAN]
- Antes de comprometer una orden: casillas legales, coste de movimiento, enemigos alcanzables, estimación de daño/riesgo, objetivo de misión.
- Toque 1 selecciona, toque 2 **previsualiza** y una confirmación clara ejecuta acciones importantes [PLAN]; disponer de acción Cancelar.
- **Deshacer** [PLAN] movimientos aún no comprometidos, sin revelar información secreta ni permitir rerolls de resultado aleatorio; considerar que un movimiento que revela niebla queda comprometido.
- Autoguardado recuperable en comienzo/fin de turno y reanudación después de cerrar app [PLAN]; guardado versionado, atómico, rollback ante corrupción.
- Reinicio de escenario y puntos de control en misiones largas [PLAN]; no ocultar información esencial detrás de ensayo/error.

## 4. Diseño de estrategia y balance
### 4.1 Arsenal y roles [BASE → PLAN]
- Cada unidad tendrá rol útil, puntos fuertes, vulnerabilidades, coste/eficacia y **al menos una contramedida viable**. Testear coste de oportunidad y presencia en partidas.
- No suponer que una unidad más cara debe ser siempre la mejor; movilidad, terreno, apoyo, reconocimiento y capacidad de suministro cuentan.
- Evitar que producción masiva de unidades baratas, tanques pesados, artillería, vehículos aéreos o navales domine universalmente.
- Incorporación gradual de fuerzas terrestres, aéreas y navales únicamente cuando sus roles y sistemas de mapa estén validados.
- Unidades muy especializadas (antiaéreas, navales, artillería) tendrán oportunidades de utilidad, sin forzarles habilidades ajenas a su función solo por balance.
- Limitación de repertorio en primeras versiones: preferir pocas unidades diferenciadas a muchas redundantes.

### 4.2 Comandantes / habilidades [PLAN]
- Especializaciones originales con **efecto significativo pero limitado**, coste conocido, duración y respuesta enemiga.
- Evitar acciones extra de todo el ejército, invulnerabilidad o habilidades que cancelen contrajuego.
- Balancear combinaciones y habilidades considerando tanto 1v1 como campaña; ninguna ventaja invisible.
- Separar progresión narrativa de parámetros competitivos.

### 4.3 Economía, territorio y suministros [EXP]
- **Control territorial:** instalaciones/infraestructuras (p. ej. rutas, sensores, depósitos) otorgan valor táctico, no solo ingreso.
- **Suministros simplificados:** restricciones comprensibles y mayor valor posicional; no exigir reabastecer manualmente cada unidad cada turno.
- **Antibola de nieve:** testear capacidad de remontada y evitar ventajas económicas irreversibles tras un error pequeño; no regalar recursos al perdedor.
- Producir unidades, capturar estructuras y abastecer se agregará solo después de validar la batalla base.
- Descartar mecanismos si aumentan la microgestión sin añadir decisiones estratégicas.

### 4.4 Mapas justos y puntuación [BASE → PLAN]
- Controlar ventaja del primer jugador, valor inicial de cada posición, distancia a recursos y rutas, y facilidad para bloquear accesos.
- Playtests A/B intercambiando facción, inicio y disposición. Medir tasa de victorias, duración, y rutas dominantes.
- Puntuación de misión basada en objetivos, valor relativo de bajas, recursos comprometidos y ejecución; no recompensar explotar estadísticas o sacrificar tropas baratas.
- Desempate, estancamientos y rendición [PLAN]: ofrecer salidas claras sin forzar límites de turnos arbitrarios en todos los mapas.

## 5. Campaña, misiones y aprendizaje
- **[BASE] Objetivos transparentes** y condiciones de victoria/derrota visibles siempre.
- **[PLAN] Variedad de misiones:** ataque, defensa por turnos, rescate/evacuación, reconocimiento, captura de instalaciones, apertura de corredores, escolta, intercepción y control territorial.
- **[PLAN] Varias soluciones viables:** no diseñar misiones que solo admitan una secuencia exacta.
- **[BASE] Información suficiente:** los refuerzos y eventos previsibles deben anunciarse, evitando sorpresas arbitrarias imposibles de contrarrestar.
- **[PLAN] No bloquear completamente la campaña:** misiones alternativas/retorno a retos difíciles; escenarios cortos compatibles con sesiones móviles y guardado de largos.
- **[PLAN] Tutorial contextual y opcional**, sin bloquear permanentemente el multijugador local, desafíos o escaramuzas.
- **[PLAN] Modos separados:** campaña, escaramuza, desafíos y editor de mapas futuro; no retirar modos valiosos al añadir sistemas nuevos.
- **[PLAN] Narrativa de un mundo ficticio original**, tono coherente: estrategia militar accesible, consecuencias comprensibles, sin tratar el conflicto de forma frívola ni exigir violencia gráfica; escenas saltables y personajes no estereotipados.
- **[EXP] Campaña ramificada** y condiciones de victoria alternativas cuando se verifique que aumentan rejugabilidad.

## 6. Android: UX, legibilidad y rendimiento
- **[BASE] Diseño mobile-first:** tamaño mínimo de objetivos táctiles adecuado, texto escalable, panel de unidad visible, buen contraste y soporte de pantallas con diferentes relaciones de aspecto.
- **[PLAN] Diseño horizontal adaptativo** cuando se valide el uso real; el tablero debe ocupar la mayor parte posible sin perder los botones críticos, HUD ni accesibilidad.
- **[BASE] Separar entrada:** toque, arrastre, zoom/pinch, cámara; no emitir acciones dobles entre eventos ScreenTouch y mouse emulado. Estado de botones y tablero debe ser testable.
- **[PLAN] Superposiciones claras:** movimiento legal, alcance, amenaza, visibilidad, cobertura, daño probable y objetivos; alternables para evitar ruido visual.
- **[PLAN] Panel de unidad:** vida, movilidad restante, ataque, defensa, rol, estado, debilidades y datos de terreno.
- **[PLAN] Acción rápida para terminar turno, guardar, cargar, cancelar y configuración; confirmaciones solo cuando aporten seguridad real.**
- **[BASE] Accesibilidad:** identificación por símbolos + colores, texto/gráficos legibles, tamaño táctil escalable, animaciones reducibles, sonidos y música separados; evitar depender de un único color.
- **[BASE] Ritmo:** acelerar/saltar animaciones y diálogos, resumen de turno enemigo y feedback inmediato de victoria/derrota.
- **[BASE] Performance:** sin red para core offline, sin cálculos AI pesados en cada frame, pruebas de memoria, carga y temperatura en Android gama media.
- **[PLAN] Arte final solo tras consolidar mecánicas:** identidad militar estilizada y original, siluetas reconocibles, terreno distinguible, animaciones rápidas. No copiar sprites, UI, sonidos ni diseños.
- **[PLAN] Audio adaptable:** variación por tensión/combate y ajustes independientes; evitar bucles agotadores.

## 7. Multijugador y creación de contenido
### [PLAN] Escaramuza local en un dispositivo
- Pasar turno entre jugadores; guardar/cargar sin que una facción obtenga información oculta injusta.
- Reanudar partidas locales largas.
### [FUTURO] Online posterior al offline estable
- Por turnos asíncronos como prioridad, notificaciones opcionales y reanudación entre sesiones.
- Invitación de amigos/código, emparejamiento público, partidas clasificadas, control antiabandono, tiempo de turno y resolución de desconexiones.
- Editor de mapas, exportación, validación, biblioteca y compartición segura, repeticiones y análisis postpartida.
- No construir infraestructura ni incurrir en gastos sin autorización y pruebas de viabilidad.

## 8. Riesgos históricos convertidos en reglas verificables
| ID | Problema que debemos prevenir | Requisito / medida |
|---|---|---|
| AW-01 | IA persigue enemigos en vez de objetivos | Escenarios objetivos: defensa/captura/retirada |
| AW-02 | IA hace trampas en niebla | Visibilidad compartida y pruebas de información oculta |
| AW-03 | Dificultad basada en ventajas arbitrarias | Ajustar búsqueda y coordinación; mostrar cualquier handicap |
| AW-04 | Misión larga sin recuperación | Autoguardado + reanudación + checkpoint |
| AW-05 | Guion con única solución | Playtests con 2+ estrategias |
| AW-06 | Combates estancados | Objetivos contestables y reglas de cierre |
| AW-07 | Unidades sin utilidad | Matriz de roles, counters y coste/valor |
| AW-08 | Una unidad/estrategia domina | Balance con telemetría anónima offline/local y simulaciones |
| AW-09 | Comandantes rotos o irrelevantes | Efectos acotados y escenarios de contrajuego |
| AW-10 | Ventaja excesiva del primer turno | Tests invertidos y compensaciones diseñadas |
| AW-11 | Bola de nieve económica | Simular escenarios de recuperación |
| AW-12 | Puntuación explotable | Métricas centradas en objetivos |
| AW-13 | Tutorial restrictivo | Tutorial contextual que no bloquee modos |
| AW-14 | Misiones repetitivas | Matriz de objetivos y ritmo de campaña |
| AW-15 | Refuerzos sorpresa sin señal | Preaviso/telegráfo y oportunidades de respuesta |
| AW-16 | Campaña difícil bloquea todo | Misiones alternativas/desafíos independientes |
| AW-17 | Acciones táctiles erróneas | Previsualizar, cancelar y filtrar eventos duplicados |
| AW-18 | Datos importantes escondidos | HUD + overlays de costo, daño y peligro |
| AW-19 | Turnos y animaciones lentas | Aceleración y resumen de turno |
| AW-20 | Estilo artístico poco legible | Dirección visual original y siluetas diferenciadas |
| AW-21 | Música repetitiva | Capas o pistas variadas y controles |
| AW-22 | Accesibilidad insuficiente | Escalado, símbolos, contrastes, opciones |
| AW-23 | Multijugador incompleto | Local guardable primero, online asíncrono después |
| AW-24 | Editor y mapas demasiado restringidos | Formato abierto/versionado, validación y compartir futuro |
| AW-25 | Cambios de secuela eliminan buenos modos | Modularidad y compatibilidad con partidas |
| AW-26 | Demasiadas funciones a la vez | Prototipos medidos, incorporación gradual |
| AW-27 | Historia superficial o tono contradictorio | Guía narrativa coherente, sin imponer diálogos |
| AW-28 | Juego móvil requiere estar siempre conectado | Core completamente offline; online opcional |
| AW-29 | Valor comercial confuso / contenido de poco valor | No micromecánicas monetizadas; expansiones sustanciales optativas |
| AW-30 | Confusión entre inspiración y copia | Revisión de originalidad y PI durante diseño |

## 9. Criterios de aceptación transversales
- Cada feature incluye: problema que resuelve, hipótesis, alcance máximo, casos de prueba de reglas y UX, métrica de éxito y condición para retirarla si perjudica la simplicidad.
- **Verificación técnica:** PASÓ / FALLÓ / NO EJECUTADO y diferencia entre CI headless, emulador y teléfono real.
- **Verificación de experiencia:** dos o más escenarios representativos, incluyendo una situación desfavorable, y evaluación de claridad/tiempo/frustración.
- **Equilibrio:** escenarios reproducibles con facciones invertidas y medición de decisiones o patrones dominantes antes de lanzar cambios.
- **Compatibilidad:** no romper saves sin migración, prueba de controles táctiles y funcionamiento offline.
- **Privacidad:** telemetría solo si se implementa justificadamente y con controles apropiados; para empezar, métricas de tests locales/offline.
- **Propiedad intelectual y monetización:** ninguna publicación, gasto o registro de marca sin autorización. TARVOKA es nombre candidato pendiente de búsqueda de marcas USPTO/WIPO y asesoría competente.

## 10. Gobierno del diseño
- `GAME_DESIGN.md` establece la dirección; `DESIGN_ROADMAP.md` ordena implementación; `DESIGN_QA.md` determina comprobaciones de calidad; `BACKLOG.md` rastrea tareas y `DECISIONS.md` registra decisiones.
- No modificar una mecánica cerrada mediante una ocurrencia aislada: abrir propuesta con alternativas, ventajas, riesgos y cambios requeridos, y guardar decisión.
- No crear PR encadenados sin integrar; cada cambio contra `main` debe ser pequeño, verificable y sin alterar otros proyectos.
- **No perder foco:** completar primero la experiencia de batalla y estabilidad Android. Economía, campañas grandes, nuevas facciones y online no bloquean el núcleo.
