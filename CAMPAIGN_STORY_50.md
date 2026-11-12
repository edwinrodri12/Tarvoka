# TARVOKA — Biblia narrativa y campaña de 50 capítulos

**Estado:** Dirección creativa aprobada por el usuario el 2026-11-12; este documento es el plan narrativo **[PLAN]**, no prueba de contenido implementado.  
**Premisa:** *La Red de Meridian*. **Formato:** 50 capítulos jugables, 5 actos × 10, ocho puntos de vista, tres familias de desenlace.  
**Relación con el diseño existente:** [GAME_DESIGN.md](GAME_DESIGN.md), [DESIGN_ROADMAP.md](DESIGN_ROADMAP.md), [LOGISTICS_DESIGN.md](LOGISTICS_DESIGN.md), [MILITARY_UNIT_CATALOG.md](MILITARY_UNIT_CATALOG.md).
**Progresión por capítulos (decisión 2026-11-12):** [CAMPAIGN_UNIT_PROGRESSION.md](CAMPAIGN_UNIT_PROGRESSION.md) especifica 32 clases desbloqueadas de forma progresiva (9/18/26/32 al finalizar cada uno de los cuatro primeros actos), conservando todas las clases para combates libres/online según disponibilidad técnica. El Acto V se dedica a dominarlas, no a nuevos tutoriales.

## 1. Decisión de producto y prioridades

TARVOKA cuenta con **tres modos principales**, ninguno subordinado al desbloqueo de la campaña:

1. **Batallas online** — propuesta de pilar de comunidad y competencia: duelos con igualdad de reglas, amistosas/privadas, reconexión, semilla de mapa compartida, partidas reanudables. **[PLAN/FUTURO]**: no presentarlo como multijugador operativo; exige sincronización, seguridad, recuperación y pruebas de red.
2. **Escaramuza contra IA con mapas aleatorios** — pilar de rejugabilidad offline: generador con semillas reproducibles, tamaño, biomas, costas, cantidad de jugadores, facciones, IA y reglas configurables. **[PLAN]**: desarrollo técnico temprano sobre el motor compartido, validando equilibrio de posiciones y rutas.
3. **Campaña narrativa de 50 capítulos** — pilar de diferenciación e identidad de propiedad intelectual: historia original con objetivos tácticos variados, progresión, personajes y tres finales. **[PLAN]**: producir por actos, sin retrasar el núcleo de escaramuza por crear todo el contenido.

**Priorización de experiencia comercial:** online y mapas contra IA poseen potencial de permanencia y rejugabilidad; la campaña crea conexión emocional, sirve de onboarding opcional y diferencia la marca. **Orden prudente de ingeniería:** estabilizar motor y IA offline → generación reproducible y escaramuza → prototipo de sincronización online sobre reglas deterministas → ampliar campaña y operar online. En paralelo se puede escribir contenido y probar una muestra narrativa. No prometer online antes de verificarlo.

**Invariantes:** no cambiar nombres, colores, retratos/emblemas ni balance de facciones **v0.1** aceptados; no sustituir munición/combustible por zonas abstractas. Cada unidad conserva los valores de munición/combustible propios y el abastecimiento real de bases/camiones de LOGISTICS_DESIGN.md. Las infraestructuras de Meridian dan contexto y objetivos tácticos, **no ventajas permanentes nuevas**.

## 2. Identidad narrativa — La Red de Meridian

**Logline:** ocho facciones dependen de una infraestructura continental creada para evitar guerras. Un desastre en el **Nudo Siete**, junto con ocultamientos parciales y decisiones defensivas incompatibles, convierte la red compartida en el motivo de la primera gran guerra en décadas. Jugando desde bandos opuestos, el jugador descubre que conquistar territorio es más sencillo que diseñar una paz sostenible.

**Tema:** *Una guerra puede comenzar sin que nadie la quiera, pero no puede terminar hasta que alguien acepte perder algo para detenerla.*

**Conflicto tangible:** ferrocarriles, puentes, hospitales, presas, puertos, tendidos eléctricos, estaciones de combustible, centros de comunicaciones y convoyes. Cada misión debe responder a una pregunta comprensible: *¿qué se salva, quién pierde y por qué importa este lugar?*

**Incidente de Nudo Siete (provisional como guion, no dato real):** una serie de fallos de comunicaciones durante un ejercicio conjunto provoca el derribo equivocado de un dron y una explosión secundaria de combustible en una conexión crítica de Meridian. La red cae por sectores y causan víctimas tanto entre militares como civiles. Informes falsamente completos ocultan piezas diferentes del mismo accidente. Ninguna facción creó deliberadamente una guerra total ni existe un villano omnisciente. Los actores que encubren, manipulan o aprovechan la crisis son responsables de elecciones concretas y pueden ser confrontados.

**Escala dramática:** (a) macro: fronteras, tratados, suministro continental; (b) meso: el puente, la base, el convoy y el puerto disputados; (c) micro: un comandante debe elegir a qué personas o aliados protege y qué orden se niega a ejecutar.

**Las tres revelaciones deben estar sembradas:** (1) la versión oficial de un ataque deliberado no encaja con la cronología; (2) existían fallas documentadas y actos de ocultamiento en **varios** bandos; (3) incluso revelada la verdad, terminar la guerra requiere un acuerdo real sobre control, acceso y reparación de Meridian.

## 3. Facciones oficiales: preservar arte y diseño v0.1

| Facción oficial | Color oficial | Interés dramático propuesto, NO ventaja de juego nueva |
|---|---|---|
| **Alianza Norte** | Azul | Proteger líneas industriales y su población; tensión entre apertura comercial y seguridad militar |
| **Pacto Escarlata** | Rojo | Evitar dependencia estratégica y una nueva invasión; postura defensiva interpretada como expansión |
| **Unión Verde** | Verde | Defender agua, alimentos, tierra fértil y corredores agrícolas vitales |
| **Confederación Solar** | Amarillo | Seguridad energética y acuerdos de intercambio que siente injustos |
| **Sindicato Violeta** | Morado | Fábricas, transporte ferroviario, centros de datos y continuidad de suministros |
| **Legión Ámbar** | Naranja | Autonomía territorial y corredores terrestres, con presión interna de mandos rivales |
| **Dominio Turquesa** | Turquesa | Puertos, rutas navales, comercio y distribución de alimentos |
| **Orden Ónix** | Negro | Inteligencia, comunicaciones y protección de secretos de seguridad; decidir cuándo revelar la verdad |

Estos **intereses son arcos dramáticos iniciales**, no una sustitución de las biografías o poderes aprobados. Usar los ocho retratos oficiales y mantener identidades/colores. Los nombres propios de comandantes se asignarán **después** de cotejar el material visual aprobado; los personajes alternativos de la investigación (Auriga, Vesper, etc.) **no reemplazan a las facciones oficiales**. Evitar introducir "novena facción" secreta como antagonista final.

**Relaciones que atraviesan la campaña:** la comandante de Alianza Norte y el general de Pacto Escarlata se acusan durante el primer acto, se ven obligados a cooperar más tarde; la comandante de Unión Verde negocia alimento y agua con Confederación Solar; el almirantazgo del Dominio Turquesa debe enfrentar el daño causado por un bloqueo; una estratega del Sindicato Violeta conoce contratos y redes de datos que complican la versión de Nudo Siete; Legión Ámbar enfrenta una fractura de mando; Orden Ónix tiene pruebas incompletas y miedo de publicarlas. Las relaciones deben cambiar **por acciones mostradas**, no por giros gratuitos.

## 4. Estructura: 50 capítulos jugables

Cada capítulo es una **misión táctica con briefing, batalla y debrief**, no solamente una escena de texto. Hay mapas creados para la campaña (reutilizan tilesets y sistemas) y algunos encuentros variantes. **Punto de vista** indica facción controlada; otras podrán apoyar según variables de campaña. El número es estable para guardados.

### Acto I — Las primeras 72 horas (1–10)
| # | Título | Control | Objetivo táctico y propósito narrativo |
|---:|---|---|---|
| 01 | Escudo compartido | Alianza Norte | Ejercicio de movimiento, ataque y captura; mostrar que cooperar es normal |
| 02 | Dos minutos de silencio | Orden Ónix | Explorar interrupción de comunicaciones; introducir niebla e información incompleta |
| 03 | Nudo Siete | Sindicato Violeta | Mantener salidas y reparar estaciones durante una emergencia, sin buscar exterminio |
| 04 | Convoy perdido | Pacto Escarlata | Recuperar equipos de reconocimiento sin disparar al vecino; mostrar otra versión de la crisis |
| 05 | Los primeros evacuados | Unión Verde | Abrir corredor de retirada, controlar pasos y proteger civiles abstraídos como objetivos |
| 06 | Informe incompleto | Confederación Solar | Escoltar suministros de emergencia; primer indicio de fallos en mantenimiento |
| 07 | Un puerto cerrado | Dominio Turquesa | Bloqueo defensivo limitado y navegación; ilustrar que la medida dañará a terceros |
| 08 | La orden | Legión Ámbar | Defender frontera con recursos escasos; un subordinado cuestiona reglas de intervención |
| 09 | Setenta y dos horas | Alianza Norte | Resistir incursiones alrededor de depósitos; primera batalla convencional amplia |
| 10 | El primer disparo oficial | Pacto Escarlata | Capturar una posición que ambos estados consideran propia; ruptura formal de la paz |

### Acto II — Fronteras en llamas (11–20)
| # | Título | Control | Objetivo táctico y propósito narrativo |
|---:|---|---|---|
| 11 | Un puente para nadie | Alianza Norte | Capturar puente intacto o volarlo y aceptar consecuencias logísticas posteriores |
| 12 | Las reservas del valle | Unión Verde | Proteger agua y granjas de incursiones; ciudades con valor económico y humano |
| 13 | Suelo de ceniza | Confederación Solar | Recuperar refinería sin destruirla; combustible por unidad y defensa antiaérea |
| 14 | Turno de noche | Sindicato Violeta | Defender complejo industrial hasta terminar producción/evacuación |
| 15 | Mar de separación | Dominio Turquesa | Desembarco y escolta naval; entender dependencia continental del mar |
| 16 | Posiciones imposibles | Legión Ámbar | Mantener tres accesos montañosos; contraataque con artillería y terreno |
| 17 | Las voces del apagón | Orden Ónix | Recuperar repetidor y fragmentos de registros antes de una retirada |
| 18 | No cruzar la línea | Pacto Escarlata | Ganar control sin arrasar una ciudad neutral; retratar disciplina y tensión militar |
| 19 | El invierno en ruta | Unión Verde | Proteger tren/convoy de alimentos con salidas alternativas |
| 20 | El estrecho vacío | Dominio Turquesa | Batalla anfibia de gran escala; victoria militar provoca crisis de suministro |

### Acto III — La guerra que alimentamos (21–30)
| # | Título | Control | Objetivo táctico y propósito narrativo |
|---:|---|---|---|
| 21 | Una guerra rentable | Sindicato Violeta | Proteger transporte de equipos mientras se revelan contratos e incentivos contradictorios |
| 22 | La ciudad que se negó | Pacto Escarlata | Rodear y negociar rendición evitando daño colateral; elección con coste táctico |
| 23 | Agua por combustible | Unión Verde | Defender presa y negociar rescate técnico con Confederación Solar |
| 24 | El relevo no llegó | Alianza Norte | Retirada táctica y rescate de retaguardia; primera derrota que no equivale a game over |
| 25 | Alas sobre las cenizas | Confederación Solar | Defender corredores aéreos con munición escasa y reabastecimiento real |
| 26 | Los que no tienen bandera | Orden Ónix | Mantener un corredor humanitario entre dos fuerzas hostiles |
| 27 | Silencio en cubierta | Dominio Turquesa | Buscar un convoy desaparecido; niebla marítima y reconocimiento |
| 28 | Dos órdenes contrarias | Legión Ámbar | Elegir qué infraestructura retener al dividirse la cadena de mando |
| 29 | Las cifras del enemigo | Sindicato Violeta | Capturar servidor y proteger testigos; evidencia que contradice propaganda propia |
| 30 | La victoria que nos separó | Alianza Norte | Victoria táctica con ruptura de alianza: consecuencias visibles de decisiones previas |

### Acto IV — Expediente Nudo Siete (31–40)
| # | Título | Control | Objetivo táctico y propósito narrativo |
|---:|---|---|---|
| 31 | Nueve minutos | Orden Ónix | Reconstruir brechas de señal en posiciones de observación; primera gran confirmación |
| 32 | El proyectil ausente | Alianza Norte | Extraer archivo militar bajo amenaza; indicio de fuego propio no declarado |
| 33 | Piezas de otro origen | Pacto Escarlata | Recuperar dron/equipos de un campo minado; fallo técnico ocultado |
| 34 | Certificados | Confederación Solar | Defender archivo de mantenimiento de infraestructuras; responsabilidad de contratistas |
| 35 | Una grabación auténtica | Sindicato Violeta | Recuperar emisión original; el recorte propagandístico no fue una falsificación |
| 36 | La ruta de los testigos | Unión Verde | Escoltar trabajadores y familias; elegir entre ventaja militar y testimonio |
| 37 | Puertos para una tregua | Dominio Turquesa | Asegurar ruta marítima de ayuda sin abrir un nuevo frente |
| 38 | El enemigo al lado | Alianza Norte + Pacto Escarlata | Misión de cooperación temporal sobre un nodo en riesgo; confianza difícil |
| 39 | Consecuencias de la verdad | Legión Ámbar | Detener desobediencia interna y evitar escalada tras conocerse responsabilidades |
| 40 | El expediente completo | Orden Ónix | Conservar, transmitir o posponer pruebas; se revela accidente múltiple y encubrimientos |

### Acto V — El precio de detenerse (41–50)
| # | Título | Control | Objetivo táctico y propósito narrativo |
|---:|---|---|---|
| 41 | Nadie da el primer paso | Unión Verde | Separar dos ejércitos y abrir negociación bajo fuego |
| 42 | Cuentas pendientes | Sindicato Violeta | Recuperar plantas para alimentar región en vez de ampliar ejército |
| 43 | La marcha del regreso | Legión Ámbar | Replegar fuerzas sin dejarlas aisladas; combustible, munición y retaguardia |
| 44 | Los últimos barcos | Dominio Turquesa | Mantener abierta ruta de comida y medicamentos mientras se acuerda tregua |
| 45 | La fortaleza vacía | Pacto Escarlata | Defender población y decidir entregar control de una base estratégica |
| 46 | El mapa de los ausentes | Confederación Solar | Asegurar energía para dos bandos rivales a costa de ventaja militar |
| 47 | La última orden | Alianza Norte | Detener ofensiva propia fuera de control, evitando una victoria destructiva |
| 48 | Siete puentes | Orden Ónix | Mantener conectados nodos y comunicaciones para que exista negociación |
| 49 | Meridian resiste | Coalición dinámica | Gran batalla terrestre/aérea/naval por varios objetivos; composición depende de alianzas |
| 50 | El precio de la paz | Coalición dinámica | Misión final con objetivos según variables; resolver gobierno, acceso y consecuencias de Meridian |

**Ritmo:** cada diez capítulos termina un arco fuerte. Los capítulos 10, 20, 30, 40 y 50 tienen cambios de estado mundial, recap y desbloqueo de archivos. No exigir que todos tengan el mismo tiempo de batalla; algunos cortos, otros grandes. No introducir diez tutoriales consecutivos: enseñar movimiento/captura en 01, niebla en 02, emergencia/ingenieros en 03, logística en 06/13, naval en 07, combate combinado hacia 09, aéreo en 13/25.

## 5. Cinco variables narrativas y tres finales

Variables persistentes **de campaña exclusivamente**, separadas de estadísticas de combate y del ranking online:

- `meridian_integrity`: infraestructura conservada, reparada o destruida.
- `coalition_trust`: acuerdos cumplidos, protección de aliados y testigos.
- `transparency`: pruebas recuperadas, mostradas o retenidas.
- `civilian_cost`: daños al abastecimiento y evacuaciones frustradas; no incentivar violencia contra civiles.
- `military_supremacy`: presión territorial y capacidad de imponer condiciones.

No se necesita árbol completo de 50 misiones × múltiples rutas. **La campaña converge** en capítulos troncales; las variables cambian posiciones iniciales, unidades aliadas, diálogos, objetivos secundarios, escenas y final. Las decisiones tienen costes legítimos y no una opción correcta obvia.

- **Armisticio**: infraestructura suficientemente íntegra, confianza y transparencia altas; autoridad de administración compartida reformada, rendición de cuentas, paz frágil.
- **Paz de Hierro**: supremacía militar alta y coalición de fuerza; detiene combates, pero red bajo control hegemónico y tensiones futuras.
- **Ocho Fronteras**: baja integridad/confianza y estados aislados; guerra termina por desgaste, militarización posterior.

Los umbrales exactos se calibran con playtests; **nunca revelar solo al final** una condición oculta sin feedback previo. Rejugar misiones terminadas no debe reescribir accidentalmente el estado principal de campaña: usar checkpoints/selección de ruta.

## 6. Narrativa jugable y accesibilidad

Estructura de capítulo: briefing de 20–40 s → tablero y objetivos visibles → 1–3 intervenciones contextuales durante batalla → debrief de 20–45 s → expediente opcional. Las escenas obligatorias son **saltables**, con registro de diálogos y opción de resumen. No bloquear partidas libres por historia. Todas las misiones muestran objetivos de victoria/derrota, refuerzos previsibles y razón estratégica de capturas/destrucciones. Permitir guardar/reanudar misiones largas sin perder ramas narrativas.

**Motor compartido, sin duplicación:** un mismo sistema de turnos, alcance real de movimiento y ataque, economía, captura de ciudades/fábricas, producción, munición/combustible por unidad, camiones logísticos, niebla, terreno, clima y comandantes sirve en campaña/IA/online. Los episodios añaden `mission_id`, `map_seed_or_id`, `scenario_objectives`, `briefing`, `on_event_dialogue`, `campaign_flags` y `outcome_hooks`. No crear reglas ocultas que favorezcan al jugador en competitivo.

**Mapas aleatorios offline:** generar con `seed` fija y registrar versión del generador; validar conexión entre bases, alcanzabilidad de instalaciones, coste de ruta, distribución de recursos, proporción tierra/agua, simetría aproximada/compensaciones, acceso aéreo y naval. Simular IA contra sí misma desde ambos lados antes de aceptar configuraciones como competitivas. En escaramuza ofrecer repetir semilla y compartir código de mapa.

**Online:** mismos mapas por semilla/verificación de estado, órdenes autorizadas por turno, anti-trampas y reconstrucción determinista, tolerancia a desconexión y guardados; hacerlo viable tras offline estable. No asociar pagos a habilidades o ventajas. La campaña narrativa no modifica el balance multijugador.

## 7. Plan de producción y validación

1. **Biblia técnica mínima:** crear esquema versionado de capítulos, flags y contenido narrativo externo al motor, guardados compatibles y pruebas de objetivos; mapa estratégico/selección de capítulo en prototipo.
2. **Vertical slice:** capítulos 01–04 consecutivos para vínculo emocional y perspectiva, más prototipo independiente de 11 para decisión/consecuencia, sin spoiler público del acto IV. Probar que diálogos y objetivos se puedan saltar/comprender y que el sistema de munición/combustible real funcione.
3. **Pilar IA y mapas:** generador con semillas, pruebas de conectividad, balance, dificultad legal y modo escaramuza completo; no reservar contenido importante exclusivamente para campaña.
4. **Pilar online:** estudio y prototipo de autoridad/sincronización sobre motor determinista; salas privadas, reconexión, tiempos de turno y persistencia; extender a emparejamiento solo tras pruebas. Tratar coste de servidor como riesgo real.
5. **Campaña por entregas internas:** completar acto I, testear; actos II–III, testear; actos IV–V y 3 finales. El objetivo **50** queda fijado a nivel de dirección de contenido; estimar trabajo de mapas, localización, arte y QA antes de declarar lanzamiento.
6. **Validación de audiencia:** en pruebas medir finalización de C01–C03, comprensión de premisa, elección de jugar C04, interés en personajes, abandono por diálogos, partidas de escaramuza repetidas y disposición a jugar online. Los resultados deciden ritmo, no cambian automáticamente 50 capítulos ni balance v0.1.

**Definición de listo narrativo:** 50 misiones completables y reanudables, objetivos probados, diálogos legibles en Android, continuidad verificada entre facciones, variables/finales reproducibles, al menos tres resultados no bloqueados accidentalmente, sin alterar equilibrio competitivo. **Nada de lo aquí descrito debe anunciarse como programado o publicado** hasta pasar CI, QA y pruebas en dispositivo.

## 8. Referencias de investigación (inspiración de principios, nunca copia)

- Nintendo, *Advance Wars 1+2*: accesibilidad, variedad de misión y comandante — https://www.nintendo.com/us/store/products/advance-wars-1-plus-2-re-boot-camp-switch/
- Nintendo, *Fire Emblem: Three Houses*: perspectiva y relaciones — https://www.nintendo.com/au/news-and-articles/fire-emblem-three-houses-101/
- Chucklefish, *Wargroove 2: Pocket Edition*: estructura de campañas y adaptación móvil — https://chucklefish.org/blog/wargroove-is-marching-onto-mobile-with-wargroove-2-pocket-edition/
- 11 bit studios, *This War of Mine*: consecuencias humanas y viabilidad comercial — https://11bitstudios.com/this-war-of-mine-surpasses-7-million-copies-sold/
- Sensor Tower, *State of Gaming 2026*: el mercado de estrategia móvil no garantiza demanda de una IP nueva — https://sensortower.com/press/press-release-sensor-tower-state-of-gaming-gaming-drove-52-billion-downloads-82b-iap-revenue-on-mobile-and-12b-premium-revenue-on-steam

**Decisión de alcance:** *La Red de Meridian* es propiedad narrativa original de TARVOKA; las 50 sinopsis son material de planificación, no contenido ya implementado. Mantener independientes los sistemas de juego compartidos y las características exclusivas de campaña.
