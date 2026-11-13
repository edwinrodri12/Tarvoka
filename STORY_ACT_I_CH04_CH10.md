# TARVOKA — ACTO I / GUIONES DE MISIÓN 04–10

**Obra:** *La Red de Meridian*. **Estado:** guiones jugables de diseño (v0.1), no mapas Godot conectados. **Fecha:** 2026-11-12.  
**Continuidad:** [C01 Escudo compartido](STORY_CHAPTER_01.md) → [C02 Dos minutos de silencio](STORY_CHAPTER_02.md) → [C03 Nudo Siete](STORY_CHAPTER_03.md).  
**Facciones / retratos:** usar exclusivamente nombres, colores, emblemas y comandantes oficiales aprobados. Cuando se lee «COMANDANCIA» es un rol de guion temporal, **no renombrar** al personaje aprobado.  
**Progresión:** según [CAMPAIGN_UNIT_PROGRESSION.md](CAMPAIGN_UNIT_PROGRESSION.md), sólo nuevas familias G04 (C04), G16 (C06), M01 (C07), G06 (C08), G11 (C09); C05 aporta nivel/perfil urbano de G01 y C10 prueba combinada. Mantener munición/combustible por unidad, captura sólo por infantería.

## Estructura de drama a lo largo de C04–C10

- **Hecho conocido en C03:** se produjo una interceptación militar equivocada seguida de desastre industrial en Nudo Siete; ninguno de los personajes controla todas las pruebas.
- **Versión Escarlata:** un convoy de emergencia desapareció cerca del corredor durante un apagón. Ve un movimiento azul y presume un ataque deliberado.
- **Versión Verde:** su población queda sin agua/energía y dos ejércitos les piden usar el mismo puente. Lo que creen una disputa fronteriza es una decisión de supervivencia.
- **Versión Solar:** algunos certificados de mantenimiento de una subestación fueron modificados sin sincronizarse. Su gobierno teme parecer responsable y demora compartir documentos.
- **Versión Turquesa:** un cierre de seguridad del puerto interrumpe medicamentos y alimentos, generando una presión civil real.
- **Versión Ámbar:** mandos exigen una intervención preventiva; los soldados descubren que obedecer una orden puede romper una tregua que ni siquiera se ha firmado.
- **C09–C10:** la defensa fronteriza y una operación de recuperación del Pacto Escarlata convergen sobre un acceso disputado. El **primer disparo oficial** no es un villano revelado: es una autorización unilateral tomada a partir de pruebas incompletas.

No hay traición gratuita, tecnología futurista ficticia ni conspiración perfecta. Cada misión revela **una verdad parcial** desde un bando que actúa por intereses comprensibles.

---

## 04 — CONVOY PERDIDO

**Control:** Pacto Escarlata · **Clase nueva:** G04 Rompedor · **Dominio:** tierra, reconocimiento de convoy y combate antiblindaje limitado.  
**Conflicto:** un convoy de rescatistas enviado hacia Nudo Siete dejó de emitir. Un alto mando ordena asumir que la Alianza Norte ha iniciado hostilidades, pero el comandante de Escarlata se niega a declarar guerra sin recuperar a sus soldados.

### Apertura / briefing
- **COMANDANCIA ESCARLATA:** «Me pidieron una lista de culpables. Tengo una lista de desaparecidos».
- **JEFE DE OPERACIONES:** «Los vehículos azules cruzaron el valle treinta minutos después del apagón».
- **ESCARLATA:** «Eso demuestra que estaban allí. No demuestra por qué».
- **OPERACIONES:** «El consejo quiere una respuesta antes del amanecer».
- **ESCARLATA:** «Entonces tendremos que encontrar el convoy antes que el consejo encuentre una excusa».

**Misión táctica:** mapa terrestre 10×8 inicial o 24×18 para producción; salida occidental, dos rutas transitables hacia un vehículo inmovilizado cerca de un desfiladero. Una unidad G04 Rompedor y dos G01 Guardia. Vehículos blindados abandonados u hostiles **identificados** que bloquean ruta enseñan contramedida antiblindaje; no obligar a atacar Guardia de Alianza Norte si está etiquetada como neutral/contacto de seguridad.  
**Victoria:** inspeccionar dos puntos de último contacto, recuperar registro y escoltar convoy a extracción. **Derrota:** perder a todas las unidades capaces de completar objetivo o agotar plazo anunciado. **Objetivo opcional:** conseguir información sin destruir un puesto fronterizo neutral.  
**Regla:** «Rompedor» es infantería antiblindaje; puede capturar instalaciones como cualquier infantería si el mapa lo exige.  
**Evento 1:** hallar primer camión sin munición ni marcas de impacto. «OPERACIONES: Sin señales de emboscada. / ESCARLATA: Las malas noticias tardan. Ésta no es una prueba».  
**Evento 2:** segundo contacto revela un convoy desviado por apagón; uno de sus escoltas disparó por temor. «ESCARLATA: Un disparo asusta a otro, hasta que nadie recuerda quién protegía a quién».  
**Epílogo:** evidencia parcial permite evitar respuesta inmediata, pero otro puesto reporta tropas movilizadas; `c04_convoy_registrado`, opcional `c04_puesto_intacto`. Un mando político omite el matiz en el comunicado. Sin convertirlo en «ataque falso» deliberado.

## 05 — LOS PRIMEROS EVACUADOS

**Control:** Unión Verde · **Mejora (no familia nueva):** perfil urbano G01 / G02 heredado, enseñanza de cobertura y renuncia táctica.  
**Conflicto:** el mismo paso terrestre solicitado por dos ejércitos también es el único acceso para evacuados y ambulancias.

### Apertura / briefing
- **COMANDANCIA VERDE:** «¿Cuántos soldados vienen?».
- **OFICIAL CIVIL:** «No lo sabemos. Pero hay doscientas personas al otro lado».
- **VERDE:** «Entonces tenemos doscientas razones para mantener el puente abierto».
- **OFICIAL CIVIL:** «Las dos fronteras dicen que debe cerrarse».
- **VERDE:** «Las fronteras no tienen fiebre. La gente sí».

**Misión:** mantener el corredor y capturar dos puntos de paso con G01 (cobertura urbana opcional) y G03 reconocimiento, con rutas alternativas para que no exija una sola secuencia. Convoy civil representado como marcador/objetivo no atacable, no un blanco para el jugador. **Victoria:** escoltar dos grupos hasta salida y asegurar la carretera. **Derrota:** interrupción total del corredor por plazo visible o pérdida de todas las fuerzas propias.  
**Evento 1:** comunicaciones enemigas exigen abandonar paso. Decisión contextual A: preservar carretera por más turnos; B: usar ruta forestal con más movimiento y menor riesgo de encuentro. Ambos viables; cambian posiciones, bajas de recursos y diálogo, no impiden progresión.  
**Evento 2:** al abrir corredor, el ejército rival deja de avanzar durante un turno; no porque su IA haga trampa sino por evento de misión anunciado.  
**Epílogo:** `c05_evacuacion_completa` y `c05_corredor_conservado`; si el objetivo extra fracasa, el hospital recibe menos ayuda, pero capítulo avanza al cumplir objetivo principal.

## 06 — INFORME INCOMPLETO

**Control:** Confederación Solar · **Familia nueva:** G16 Vehículo logístico.  
**Conflicto:** la planta que abastecía a Nudo Siete había registrado advertencias de mantenimiento. Las capitales requieren combustibles, pero compartir los informes podría dejar al gobierno Solar como responsable de la catástrofe.

### Apertura / briefing
- **COMANDANCIA SOLAR:** «Nuestros camiones pueden llegar en seis horas».
- **INGENIERÍA:** «Si entregamos combustible, también tendremos que entregar los libros de mantenimiento».
- **SOLAR:** «¿Qué dicen los libros?».
- **INGENIERÍA:** «Que pedimos inspecciones. Y que algunas se aplazaron».
- **SOLAR:** «Salvar vidas primero. Después hablaremos de firmas».

**Misión:** un G16 con reservas finitas de munición/combustible, G01 escoltas y vehículos aliados bajo amenaza. **Objetivo:** distribuir suministros pagados/preexistentes a dos equipos de reparación y regresar a la base, eligiendo rutas seguras o cortas. Evitar «camión con suministro infinito»: usar el sistema `Logistics.gd` validado. **Derrota:** camión destruido o sin suministros antes de cumplir entregas; necesidad de reservar combustible para regreso anunciada.  
**Evento:** primera entrega comunica un certificado con fecha irregular. El jugador elige **copiar registro** (desvía un turno del convoy) o **priorizar segunda entrega** (conserva integridad material); decisión afecta `transparency`/ `meridian_integrity` con feedback.  
**Epílogo:** `c06_entregas_completadas`, opcional `c06_documentos_duplicados`. La duda política, no la falta de voluntad, produce un informe incompleto.

## 07 — UN PUERTO CERRADO

**Control:** Dominio Turquesa · **Familia nueva:** M01 Patrullero · **Dominio:** mar/litoral, enseñanza de agua/navegación y docks.  
**Conflicto:** Turquesa activa inspecciones navales para impedir paso de armas, sin advertir que otro corredor quedó inutilizado en Nudo Siete y ahora el puerto es la única vía para alimentos.

### Apertura / briefing
- **COMANDANCIA TURQUESA:** «Un barco puede traer ayuda o artillería. No podemos adivinar cuál».
- **CAPITANÍA:** «¿Entonces cerramos todo?».
- **TURQUESA:** «Inspeccionamos primero. La orden era proteger nuestra costa, no dejarla sin comida».

**Misión:** mapa costero de al menos una franja navegable continua con una entrada, dos embarcaciones patrulleras M01 y un puerto. **Victoria:** identificar dos embarcaciones e interceptar una amenaza **militar confirmada**, dejando cruzar convoy humanitario; versión no letal de intercepción si no hay combate. **Derrota:** perder control de puerto o patrullas. No añadir flota que ignore terreno naval ni navegación en tierra.  
**Evento:** alerta de escasez obliga elegir entre mantener inspección rigurosa con retardo y permitir convoy con escolta; elegir una cambia próxima disponibilidad económica / relaciones, no un bono permanente para online.  
**Epílogo:** `c07_convoy_humanitario`, `c07_puerto_controlado`. Un periódico extranjero lo presenta como «bloqueo», y esa descripción no es completamente falsa.

## 08 — LA ORDEN

**Control:** Legión Ámbar · **Familia nueva:** G06 Baluarte · **Dominio:** tierra, blindaje defensivo y antiblindaje.  
**Conflicto:** Ámbar recibe dos órdenes incompatibles: proteger un paso montañoso y permitir un movimiento «preventivo» hacia el valle, lo que pondría a fuerzas ajenas en posición de disparar por temor.

### Apertura / briefing
- **COMANDANCIA ÁMBAR:** «¿Quién firmó la segunda orden?».
- **OFICIAL:** «El mismo general que firmó la primera».
- **ÁMBAR:** «Entonces alguien debe explicarle que el terreno no ha cambiado de lugar».
- **OFICIAL:** «Dice que si no avanzamos, pareceremos débiles».
- **ÁMBAR:** «Si avanzamos sin saber contra quién, seremos peligrosos».

**Misión:** mantener dos accesos con G06 Baluarte y G01, enfrentando antiblindaje visible y caminos alternativos; enseñar que terreno elevado/bosque da defensa pero no impunidad. **Victoria:** sostener paso hasta fin de ronda objetivo, sin bloquear retirada; **derrota:** perder ambos accesos o ejército; sin refuerzos sorpresa.  
**Evento:** orden de avance agresivo llega en turno 3. Elegir A: desplazar una unidad al valle para mostrar fuerza (ganancia táctica, coste diplomático), o B: mantener cordón defensivo (objetivo de defensa más difícil, conserva confianza). Ambos estados se guardan y afectan diálogos, no una guerra inevitable si elige B.  
**Epílogo:** `c08_orden_ejecutada` o `c08_orden_contestada`. Un superior cuestiona su lealtad; una unidad subordinada sigue obedeciéndolo por haber sido protegido.

## 09 — SETENTA Y DOS HORAS

**Control:** Alianza Norte · **Familia nueva:** G11 Lanzador · **Dominio:** tierra, rango mínimo/máximo y respuesta blindada.  
**Conflicto:** las noticias sobre el convoy perdido de Escarlata llegan sin el detalle de que no hubo emboscada. La Alianza Norte posiciona artillería cerca de depósitos para impedir un asalto que considera inminente.

### Apertura / briefing
- **COMANDANCIA NORTE:** «Hace tres días compartíamos mapas con ellos».
- **OFICIAL:** «Hoy no responden al canal común».
- **NORTE:** «Eso no los convierte en enemigos».
- **OFICIAL:** «Han acercado blindados».
- **NORTE:** «Entonces protejamos el depósito. Y dejemos una salida para retirar las armas».

**Misión:** defender depósitos con G01/G03/G06/G11, sin exigir unidades no desbloqueadas. Mostrar de forma explícita casillas de movimiento hasta la posición más lejana y desde allí cobertura de ataque real, sin confundir rango directo e indirecto. Lanzador G11 ataca a distancia mínima 2 y no dispara en contacto, no puede capturar. **Victoria:** proteger depósito hasta plazo anunciado y garantizar ruta de retirada. **Derrota:** perder depósito o las unidades requeridas.  
**Evento:** el oficial identifica el movimiento que en realidad era convoy de rescate C04. La comandante tiene opción de **no disparar preventivamente** y replegar (mayor peligro táctico, más confianza) o destruir equipo enemigo que amenaza el depósito (sin culpabilidad moral automática); ninguna opción es un crimen unilateral obligatorio.  
**Epílogo:** `c09_deposito_defendido`, `c09_fuego_preventivo`. Se muestra un resumen de bajas militares, no celebración de una matanza. La discrepancia de registros en Nudo Siete no se ha aclarado.

## 10 — EL PRIMER DISPARO OFICIAL

**Control:** Pacto Escarlata · **Nueva familia:** ninguna (examen combinado del acto). **Escenario:** disputa abierta sobre un cruce que ambos países consideran imprescindible para reabrir Meridian.  
**Conflicto:** un comunicado oficial de Norte declara zona de exclusión alrededor del depósito. Escarlata necesita el cruce para reabastecer a sus rescatistas. Ambas decisiones son comprensibles; ambas autoridades creen actuar defensivamente.

### Apertura / briefing
- **COMANDANCIA ESCARLATA:** «Necesitamos ese camino abierto».
- **OFICIAL:** «Norte dice que cruzarlo equivale a un ataque».
- **ESCARLATA:** «Hace setenta y dos horas nos invitaron a usarlo».
- **OFICIAL:** «La invitación venció cuando cerraron la Red».
- **ESCARLATA:** «La Red no se cierra desde una capital. Se apaga, y todos pagamos».

**Misión:** tomar un puesto de mando y sostener control al fin de ronda, con Guardia, Rastreador y Rompedor, protegiendo logística del avance. Alianza Norte controla posiciones fortificadas, un blindado y un Lanzador G11 **ya introducido al jugador en C09**. **Objetivos secundarios:** conservar puente e instalaciones para la población; replegar fuerzas dañadas a puntos protegidos. **Victoria:** control del paso durante una ronda completa; **derrota:** se pierde fuerza capaz de capturar o transporte logístico imprescindible. El jugador debe ver claramente por qué el fuego puede escalar y dónde hay alternativas.

**Evento 1 — último mensaje conjunto:** antes de iniciar hostilidades, la frecuencia del ejercicio C01 vuelve a sonar brevemente.
- **NORTE:** «Identifíquense. No hay autorización para cruzar».
- **ESCARLATA:** «Solicito apertura del corredor humanitario».
- **NORTE:** «No puedo verificar que sean sólo rescatistas».
- **ESCARLATA:** «Y yo no puedo esperar a que su gobierno decida creerme».

**Evento 2 — el disparo oficial:** se dispara tras una orden validada y la acción táctica real, no mediante una cinemática inevitable que contradiga al jugador. Si el jugador completa misión sin disparar, un reporte de **otro sector** confirma que la guerra oficialmente ya comenzó, sin convertir la elección en inútil; su comandante consigue evitar víctimas en su sector. Variación de diálogo:
- **Con fuego:** «OFICIAL: El mundo se enterará de quién disparó. / ESCARLATA: Asegúrate de que también sepa por qué».
- **Sin fuego:** «OFICIAL: El primer disparo fue en otro sector. / ESCARLATA: Entonces al menos no empezó aquí».

**Epílogo del acto:** mapa estratégico de los ocho territorios, fallos de Meridian en cadena y movilización; narrador muestra una prueba incompleta de Nudo Siete conservada por Orden Ónix y Sindicato Violeta. El jugador sabe que las versiones oficiales se contradicen, pero aún no conoce la explicación completa. `c10_paso_controlado`, `c10_disparo_sector`, `c10_puente_intacto`. **Cierre de Acto I:** desbloquea Acto II con el capítulo 11 «Un puente para nadie» y recuento de decisiones, no bonus de combate.

---

## Contrato transversal para el motor de campaña

1. **Cada escenario declara su victoria/derrota propia**, no hereda «matar a todos los enemigos» del modo escaramuza. Si el combate elimina una facción antes de cumplirse el objetivo, el evaluador de misión debe resolver ese estado sin softlock; nunca adjudicar victoria por un criterio no anunciado.
2. **Eventos narrativos deterministas e idempotentes:** `event_id`, condición verificable, `seen` guardado, efectos separados; saltar diálogos no evita aplicar una decisión previamente confirmada.
3. **Decisiones con consecuencias legibles:** nunca introducir elección imposible de ganar. Las flags alteran diálogos, objetivos secundarios y preparación de capítulos posteriores; no bonificaciones permanentes en escaramuza ni online.
4. **Facciones limitadas por motor actual:** usar dos bandos en batalla física y alianzas/neutralidad narrativa hasta que el motor soporte múltiples participantes; no mostrar bandos enemigos como civiles ni obligar a atacar contactos neutrales.
5. **Escalado de mapas:** 10×8 es referencia de test para C04–C06; C07 necesita agua navegable; C09–C10 posiblemente 24×18. Verificar conectividad y rutas con `Rules.reachable` antes de publicar mapas. Ningún capítulo utiliza una unidad no introducida sin señalizar su aparición enemiga.
6. **Progresión de 24 familias:** Acto I termina con 8 familias acumuladas. C05 muestra kit urbano como **nivel de G01**, no «nueva familia G02». La falta de un módulo avanzado no impide completar el capítulo base.
7. **Continuidad con futuras revelaciones:** anomalía de relojes C01/02, alarma y mantenimiento C03/06, convoy C04/09 y primer choque C10 deben ser coherentes con el dossier C31–C40; no inventar una novena facción malvada.

## Registro de QA narrativo

| Prueba | Éxito requerido |
|---|---|
| C04 | Se puede rescatar el convoy con G04 sin eliminar a una fuerza neutral |
| C05 | Dos rutas factibles y evacuación sin atacar civiles |
| C06 | Suministros finitos, coste transparente, regreso factible |
| C07 | Patrulleros navegan únicamente agua, puerto/convoy con objetivos claros |
| C08 | Blindado G06 útil pero vulnerable a Rompedor y terreno |
| C09 | Rango real de G11 y área de amenaza coinciden con motor, no dispara adyacente |
| C10 | Puede completarse con y sin disparar; el «primer disparo» en algún sector es un hecho externo de la historia, no castigo a jugador |
| Acto I | Exactamente 8 familias aprendidas; cada bando conserva nombre, identidad y retratos; nunca se pierde una decisión al guardar |

**No declarar estas siete misiones terminadas** hasta programar objetivos, mapas, escenas, decisiones y validar CI + Android. Documento completo para implementación y revisión de personajes.
