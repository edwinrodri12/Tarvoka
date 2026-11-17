# TARVOKA — Director estratégico de IA, 12 niveles y 11 doctrinas (v3.2)

**17 de noviembre de 2026 | Rama de desarrollo aislada | PR borrador #533.**

## Objetivo solicitado

La IA debe actuar como un verdadero comandante: adaptarse a adversario, tamaño de mapa, terreno, economía, ciudades, bases, dominios terrestre/aéreo/naval, niebla, suministros y progresión de unidades; ofrecer muchos niveles de desafío **sin añadir visión, dinero, daño o acciones gratis**.

Esta versión introduce el **primer módulo jugable** para organizar las decisiones estratégicas. **No es aún una IA experta completa y no utiliza automáticamente todas las mecánicas futuras.** Una dificultad numéricamente mayor cambia heurísticas y capacidad de respuesta; no se afirma que su tasa de victorias aumente monótonamente sin torneos y pruebas con personas.

## Implementación real (núcleo, UI y guardados)

- `scripts/core/StrategicDirectorV32.gd`: director de decisiones **puro, determinista y local** que únicamente recibe el resultado de `Visibility.observed_state`; no ve soldados ocultos ni recursos rivales, y nunca altera los estados del combate.
- `BasicAI.step(state,options={})`: **opt-in**, conserva el comportamiento antiguo con `{}`. Activado cuando se especifica `ai_level` (1 a 12) o `ai_style` válido. Coordina reglas de **compra por instalación**, prioridades de **captura** y **retirada ante amenaza letal visible** (a partir de nivel 4, salvo anulación explícita de la opción).
- `TouchBoard`: recibe el perfil elegido, lo pasa en los turnos de IA y lo restaura al cargar partida/autoguardado.
- `SkirmishSetup`: selector real de nivel 1–12 y de doctrina entre 11 perfiles, con resumen.
- `Main`: confirma las opciones antes de reemplazar la batalla y transmite el perfil al crearla.
- `SaveCodec`: campo opcional `ai_config = {"level":1..12,"style":"..."}` en el **formato v1 existente**, sin cambiar versión. Solo se guarda cuando se eligió IA; partidas viejas no ganan campos nuevos. Se valida para rechazar campos extra, bonos falsos y valores fuera de rango.

### Los 12 niveles disponibles

| Nivel | Nombre | Diferencia de decisión implementada |
|---:|---|---|
| 1 | Recluta | Política equilibrada fija; defensa básica histórica |
| 2 | Cadete | Más peso en objetivos, sin análisis letal ampliado |
| 3 | Cabo | Primer ajuste económico; prioridad territorial creciente |
| 4 | Sargento | Retirada legal ante daño letal visible con cualquier HP; expansión si escasea infantería |
| 5 | Teniente | Más prioridad a objetivos y terreno; requiere medir juego real |
| 6 | Capitán | Reacciones a unidades visibles antiblindaje/antiaéreas; adapta doctrina |
| 7 | Mayor | Composición diversificada: evita repetir roles por inercia |
| 8 | Coronel | Prioridades más intensas sobre objetivos y contramedidas |
| 9 | General | Objetivos y adaptación más amplios; propone asedio cuando ya no queda expansión |
| 10 | Estratega | Refuerza la respuesta a amenazas; sin mejores estadísticas |
| 11 | Mariscal | Reserva un núcleo mayor para captura y alterna producción |
| 12 | Leyenda | Máxima ponderación de prioridades táctico-económicas actual; **no juega óptimamente por arte de magia** |

**Importante:** los pesos son iniciales y varias diferencias entre niveles son incrementales; requieren análisis de decisiones y torneos para comprobar que se sienten realmente distintos. No hay una búsqueda de 10 jugadas ni aprendizaje neuronal online implementado. La promesa futura de dificultad será **mejores decisiones**, nunca hacer trampa.

### Doctrinas estratégicas

`adaptive`, `balanced`, `expansion`, `fortress`, `blitz`, `combined_arms`, `recon`, `siege`, `air_control`, `naval_control`, `attrition`.

- **Adaptativa:** a niveles altos observa amenazas relevantes: defender instalaciones si hay presión, combinar armas contra blindados, contrarrestar aeronaves, usar flota si existe astillero, expandirse cuando faltan capturadores y planear asedios cuando se agotan ciudades neutrales.
- **Expansión:** reconoce ciudades como inversiones a largo plazo y mantiene infantería de captura.
- **Fortaleza:** prioriza infantería defensiva, blindaje y antiaéreos de manera legal.
- **Ofensiva rápida:** prefiere tropas móviles y drones de ataque cuando puede producirlos.
- **Armas combinadas:** mezcla infantería, blindados, artillería y reconocimiento; no compra antitanques indefinidamente.
- **Reconocimiento:** prefiere exploradores y drones ISR, pero no revela unidades ocultas.
- **Asedio:** prioriza artillería de alcance legal y protección de los flancos.
- **Dominio aéreo:** crea cazas/interceptores según instalaciones y recursos, no aviones gratis.
- **Dominio naval:** prioriza patrullas, escoltas y buques; sin astillero no puede producir flota.
- **Desgaste:** considera suministro y unidades defensivas en la composición.
- **Equilibrada:** composición más neutral cuando aún no hay evidencia para especializarse.

### Equipamiento y edificios realmente contemplados

| Instalación | Opciones evaluadas | Legalidad |
|---|---|---|
| Cuartel de infantería | Guardia, Rastreador, Asaltante, Ingeniero, Logística | `Economy.can_purchase` |
| Planta blindada | APC, VCI, tanque, Baluarte, Rompedor (productor actual) | `Economy.can_purchase` |
| Depósito de artillería | Lanzador, SPG, MLRS, G13, SAM, EW | `Economy.can_purchase`; EW sin efecto activo todavía |
| Centro de drones | ISR, FPV, munición merodeadora | Compra legal; consumo de municiones real |
| Base aérea | Helicóptero ataque, caza, UCAV, bombardero, helicóptero de transporte | Compra legal; transporte todavía sin carga |
| Astillero | Patrullero, lancha misilera, corbeta, fragata, submarino, destructor, USV y desembarco | Compra legal; sonar/desembarco pendientes |

**Importante:** el proyecto paralelo [v2.7](https://github.com/edwinrodri12/Tarvoka/pull/517) estudia mover el Rompedor al **Cuartel I**. Esta rama v3.2 parte del **código oficial**, que todavía lo produce en planta blindada. No mezclar dos cambios de balance sin un A/B posterior.

## Evoluciones y poderes: capacidad planificada, NO poder ejecutado

La especificación [CAMPAIGN_TECH_LEVELS_V1.md](../../CAMPAIGN_TECH_LEVELS_V1.md) define 24 familias, tres niveles tecnológicos y alternativas de nivel III. El estado actual del núcleo `BattleSession` expone `move`, `attack`, `purchase`, `resupply`, `end_turn`. **No expone aún acciones de investigación, cambio de chasis, poderes de comandante, construcción de campamentos o reconversión de ramas.**

El director v3.2 genera un `development_intent` **informativo** cuando una doctrina y una instalación propia sugieren una mejora, por ejemplo `armor_plant_level2`, `artillery_depot_level2`, `airbase_level2` o `shipyard_level2`. **Nunca descuenta fondos ni altera unidad o fábrica**, porque eso sería saltarse las reglas y producir un oponente tramposo.

### Próximas conexiones reales (por prioridad)

1. **Acciones de evolución legales** con coste total, edificio, turno, nivel I/II/III, prerequisitos, cooldown, ramas excluyentes y persistencia validada. Añadir al árbitro `Session` y a `SaveCodec` antes de darle acceso a la IA. **No** trasladar veteranía libremente entre niveles ni heredar progreso de campaña en partidas competitivas.
2. **Conocimiento de contramedidas completas**: G04 Rompedor vs G06/G09, drones vs blindados, antiaéreos G13/G14 vs aire, caza vs aeronaves, combate naval y suministros. El director debe comprobar disponibilidad, tiempos de viaje, niveles de fábrica, coste y visibilidad.
3. **Habilidades de comandantes y ocho facciones**: seleccionar por mapa/fase, calcular coste y oportunidad, respetar cargas y cooldown de habilidades. El selector actual es visual; no se puede afirmar que estos poderes ya cambien estadísticas.
4. **Campamentos únicos de especialistas**: médico, suministro, defensa y reconocimiento con constructores reales y casilla de ocupación, sin beneficios de área invisibles o acumulables.
5. **Objetivos persistentes multi-turno** y **secuenciación táctico-estratégica**: concentrar fuego, cortar refuerzos, flanquear, proteger infantería capturando ciudades, planificar ruta a HQ, dejar libre casilla del productor antes de comprar y rotar ejército según terreno.
6. **Niveles 1–12 calibrados**, no solo etiquetas: banco de pruebas multi-mapa, distintas facciones, objetivos, semillas y jugadores; verificar progresión de dificultad, variación de estilos, probabilidad de respuesta y latencia en Android.

## Reglas competitivas

- El motor de reglas es **el mismo para persona e IA**.
- La IA ve solo el estado que el jugador del mismo bando podría observar y no consulta el dinero enemigo.
- `ai_config` solo contiene nombre de estilo y nivel; no contiene multiplicadores de daño, vida, dinero, velocidad, niebla ni tiempo.
- Las compras pasan por `Session.purchase`, con precios y propiedad verificados.
- Una partida terminada por límite de investigación sin vencedor queda **censurada**, no empate ni victoria inventada.
- PR DRAFT hasta CI y test Android; las UI, la versión 1 del guardado y los seis tests de regresión deben pasar. El APK del lanzamiento oficial no cambia hasta integrar y verificar.

## Pruebas de esta fase

- `tests/test_ai_strategy_levels_v32.gd`: 12 perfiles, 11 doctrinas, seis productores, compras legales y detección sin omnisciencia.
- `tests/test_ai_game_ui_profile_v32.gd`: menú, selección, confirmación, propagación real a `TouchBoard`, serialización y rechazo de configuraciones manipuladas.
- Seis suites previas de `BasicAI` (autopartidas, niebla, combate, economía y multidominio).
- [PR #533](https://github.com/edwinrodri12/Tarvoka/pull/533): evidencia de ejecución en Actions cuando CI finalice.

**Meta futura:** la IA podrá jugar con todas las facciones, unidades, tecnologías y habilidades **cuando existan acciones legales y verificadas**; el nivel 12 no tendrá ventajas secretas respecto al nivel 1, solo mejores decisiones y mayor capacidad de planificación.
