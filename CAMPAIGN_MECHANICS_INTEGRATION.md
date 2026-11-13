# TARVOKA — Contrato de integración total de mecánicas en la campaña de 50 capítulos

**Fecha de auditoría:** 2026-11-12. **Estado:** matriz técnica y narrativa que dirige implementación; no implica 50 misiones jugables. **Alcance:** contrastado con `scripts/core`, `scripts/ui`, `tests` y diseños de Acto I en GitHub. La campaña usa **el mismo motor** que escaramuza y más adelante online. **Los modos libres nunca se bloquean con progreso de historia**.

## 1. Regla de alcance: sistema REAL vs gancho de misión por construir

No confundir `clase comprable`, `arma efectiva`, `habilidad activa` y `objetivo narrativo`. Las siguientes capas YA tienen implementación con código en `main`, aunque su funcionamiento final en Android requiere pruebas de dispositivo y vínculo de campaña:

| Elemento en el motor actual | Fuente de verdad | Cómo debe aparecer en la historia |
|---|---|---|
| Turnos, movimiento, ataque, **ataque tras mover**, alcance mínimo/máximo y contrafuego por rol | `BattleSession`, `BattleActions`, `MoveActions`, `UnitRoles`, `CombatDoctrine`, `TacticalHints` | Maniobras C01/C04, artillería C09/C16, defensa C24 y guerra combinada C49; el atacante no recibe bonus arbitrario por iniciar |
| Defensa por bosque, montaña/altura, ciudad y flanqueo (sin beneficios secretos de facción) | `TerrainTactics`, `Rules` | C05 evacuación urbana, C08/C16 pasos montañosos, C24 retirada, C47 detener ofensiva |
| Niebla, línea de visión, exploración y **último contacto desactualizado** sin atacar a enemigos invisibles | `Visibility`, `BasicAI`, `TacticalHints` | C02/17/31 investigación, C27 convoy perdido, C35 registros, C40 pruebas |
| Captura, ingresos de ciudades, precios y plantas/fábricas/arsenales/aeródromos/astilleros | `UrbanEconomy`, `ModernArsenal` | C11/12 puentes y granjas, C14 industria, C20 puerto, C21 contratos, C42 alimentos |
| Munición y combustible por unidad, consumo y recarga **pagada**, stock finito del camión | `Logistics`, `SupplyNavigation`, `SupplyStrategy` | C06 abastecimiento, C13 refinería, C19 alimentos, C24 retirada, C42/43 logística |
| Tres dominios tierra/aire/mar, límites de movimiento y objetivos legales, drones desechables | `Domains`, `ModernArsenal`, `BattleActions` | C07 naval, C15 desembarco, C17 reconocimiento, C22/26 dron de un uso, C25/32 aire, C44 barcos |
| Relés con captura al terminar turno y puntuación equitativa por ronda; primer turno limitado cuando aplica | `RelayControl`, `OpeningBalance` | C17/31/48 nodos de comunicación, C10/49 despliegue; **no usar relés como sustituto secreto** de otros objetivos |
| IA de escaramuza con niebla y economía observadas, producción y gestión de suministros | `BasicAI` | IA adversaria de cada capítulo con objetivos de misión adicionales que aún deben implementarse |
| Mapas 10×8, 24×18, 40×30; generador offline con semillas; terrenos válidos | `Scenarios`, `Rules` | mapas de tutorial pequeños y mapas amplios para misiones combinadas; semilla sólo para variantes autorizadas |
| Guardado/versiones, autosave, victoria/derrota del combate | `SaveCodec`, `SaveStore`, `BattleSession`, `TouchBoard` | guardar batalla + flags narrativas en fichero de campaña aislado; reanudar y repetir sin duplicar desbloqueos |
| Isometría, desplazamiento, pinch-zoom, minimapa, iconos/sprites, VFX, HUD con zonas y estadísticas de enemigo visible | `IsoRenderer`, `IsoProjection`, `TouchBoard`, `Main`, `BattleMinimap`, `BattleVFX`, `VisualStyle` | TODAS las misiones usan cámara/HUD del mismo tablero; diálogo en capa encima sin romper hitboxes y sin filtrar niebla |

**Precisiones técnicas críticas comprobadas:**
- `ModernArsenal` incluye **32 identificadores de catálogo** (cinco `UnitRoles` históricos + 27 modernos) con estadísticas, costes y sitios de producción. El catálogo **propuesto** de **24 familias con 3 niveles** NO está implementado como árbol de investigación; la tabla de `CombatDoctrine.tier()` es una clasificación de doctrina, **no un nivel de mejora comprado**. La veteranía declara bonificaciones cero; **no prometer XP** hoy.
- Algunos perfiles del catálogo dicen expresamente `reparar requiere sistema adicional`, `carga pendiente`, `sigilo pendiente` y `sonar` por hacer. La función `G15` de guerra electrónica existe como perfil, pero el **jamming activo** y especializaciones no están operativos; tampoco se afirma un **buque logístico M09** jugable.
- `UrbanEconomy.can_capture` permite actualmente `line, scout, assault, engineer` y **omite `piercer` (Rompedor)**, aunque el diseño aprobado dispone que toda infantería capture. Esto es un **desajuste real** que debe corregirse y probarse, no narrarlo como si funcionase.
- La interfaz sólo maneja dos bandos activos (0/1), pese a mostrar la identidad visual de ocho facciones. Los capítulos alternan perspectivas; una coalición debe representarse con un único bando de combate o implementar el soporte multijugador de facciones **sin inventarlo**.
- `CampaignMission.gd` recién integrado ya ofrece un núcleo probado para C01 (objetivos y eventos con checkpoint independiente), pero **NO** está conectado al menú, al final de turno de `TouchBoard` ni a diálogos de pantalla. Los capítulos C02–C50 sólo tienen diseño, no objetivos ejecutables.
- El arte de 32 siluetas/sprites visible en prototipo **no equivale** a 24 modelos 3D definitivos. Ni las ocho ilustraciones oficiales de comandante ni todos los retratos están importados; la galería utiliza sustitutos cuando faltan. Mantener los diseños aprobados.

## 2. Regla de incorporación: 3 capas por capítulo

1. **Narrativa:** cada elemento sirve al argumento (las ciudades importan porque abastecen poblaciones; combustible porque alguien paga por transportarlo; los relés porque conectan Meridian).
2. **Jugabilidad real:** se reutilizan transiciones y cálculos del motor; ningún diálogo concede munición, HP, visión, créditos o poder de comandante que no exista en reglas.
3. **Control de calidad:** episodio declara objetivo de misión, variación de mapa, facción/nivel, condiciones, eventos, guardado, límites de unidades y contrajuego; las pruebas comparan que el resultado coincida con las reglas.

## 3. Matriz completa de los 50 capítulos

En la columna «mecánicas» se anotan sistemas existentes a aprovechar. La columna «ganchos faltantes» identifica implementaciones **aún necesarias** para transformar la idea en partida jugable. La historia vinculante y más detallada está en `CAMPAIGN_STORY_50.md` y los guiones del Acto I.

| Capítulo | Título | Facción narrativa | Mapa previsto | Familia nueva | Mecánicas reales a aprovechar | Ganchos de campaña aún pendientes |
|---|---|---|---|---|---|---|
| C01 | Escudo compartido | alianza norte | 10x8 | G01 | movement, attack, counterfire, capture, terrain, tactical_overlay, ai | campaign_screen, mission_turn_bridge |
| C02 | Dos minutos de silencio | orden onix | 10x8 | G03 | movement, fog, fog_contacts, enemy_inspect, ai | recon_objective, extraction_action, campaign_screen |
| C03 | Nudo Siete | sindicato violeta | 10x8 | G05 | movement, capture, city_income, terrain | repair_action, multiobjective, campaign_screen |
| C04 | Convoy perdido | pacto escarlata | 10x8 | G04 | movement, attack, counterfire, doctrine, terrain | escort_objective, inspection_action |
| C05 | Los primeros evacuados | union verde | 10x8 | — | movement, capture, height, terrain | evacuation_objective, civilian_markers |
| C06 | Informe incompleto | confederacion solar | 10x8 | G16 | movement, fuel, ammo, resupply, truck | delivery_action, mission_supply_stock |
| C07 | Un puerto cerrado | dominio turquesa | 10x8 | M01 | movement, naval, domains, fog | inspection_action, neutral_naval_contacts |
| C08 | La orden | legion ambar | 10x8 | G06 | movement, attack, counterfire, height, flank, terrain | hold_objective, choice_flags |
| C09 | Setenta y dos horas | alianza norte | 10x8 | G11 | movement, attack, range, ammo, tactical_overlay, terrain | defend_objective, choice_flags |
| C10 | El primer disparo oficial | pacto escarlata | 24x18 | — | movement, capture, initiative, attack, counterfire, terrain | capture_objective, choice_flags |
| C11 | Un puente para nadie | alianza norte | 24x18 | G07 | movement, capture, terrain, height, city_income | bridge_damage, objective_override |
| C12 | Las reservas del valle | union verde | 24x18 | — | movement, capture, city_income, terrain, fog | defend_objective |
| C13 | Suelo de ceniza | confederacion solar | 24x18 | — | movement, fuel, ammo, attack, resupply, doctrine | refinery_objective |
| C14 | Turno de noche | sindicato violeta | 24x18 | — | movement, capture, production, city_income, ammo | production_goal |
| C15 | Mar de separación | dominio turquesa | 24x18 | M07 | movement, naval, domains, capture, attack | transport_cargo, landing_action |
| C16 | Posiciones imposibles | legion ambar | 40x30 | — | movement, height, flank, range, seeded_map, terrain | hold_objective |
| C17 | Las voces del apagón | orden onix | 24x18 | A01 | movement, fog, fog_contacts, relays, ai | relay_intel_objective |
| C18 | No cruzar la línea | pacto escarlata | 24x18 | G13 | movement, air, domains, counterfire, terrain, capture | urban_objective |
| C19 | El invierno en ruta | union verde | 24x18 | — | movement, truck, fuel, resupply, ammo | escort_objective |
| C20 | El estrecho vacío | dominio turquesa | 40x30 | M03 | naval, domains, attack, counterfire, large_map, minimap, production | strait_objective |
| C21 | Una guerra rentable | sindicato violeta | 24x18 | G15 | movement, production, city_income, truck, fuel | ew_action, mission_economy_story |
| C22 | La ciudad que se negó | pacto escarlata | 24x18 | A02 | movement, capture, terrain, drone_consumable | surrender_objective |
| C23 | Agua por combustible | union verde | 24x18 | A06 | movement, fuel, resupply, truck, air | air_transport_cargo, evacuation_objective |
| C24 | El relevo no llegó | alianza norte | 24x18 | — | movement, terrain, range, ammo, flank | withdrawal_objective |
| C25 | Alas sobre las cenizas | confederacion solar | 24x18 | A05 | air, domains, ammo, fuel, range, counterfire | air_defense_objective |
| C26 | Los que no tienen bandera | orden onix | 24x18 | — | movement, fog, drone_consumable, enemy_inspect | humanitarian_objective |
| C27 | Silencio en cubierta | dominio turquesa | 40x30 | M09 | naval, domains, fog, fog_contacts, resupply, large_map | naval_supply_action, escort_objective |
| C28 | Dos órdenes contrarias | legion ambar | 24x18 | — | movement, height, terrain, opening | split_order_choice |
| C29 | Las cifras del enemigo | sindicato violeta | 40x30 | A04 | movement, fog, fog_contacts, drone_consumable | evidence_objective |
| C30 | La victoria que nos separó | alianza norte | 40x30 | — | movement, attack, counterfire, large_map, minimap, terrain | consequence_flags |
| C31 | Nueve minutos | orden onix | 24x18 | — | fog, relays, enemy_inspect, fog_contacts | timeline_reconstruction |
| C32 | El proyectil ausente | alianza norte | 24x18 | A07 | movement, air, domains, ammo, fuel, enemy_inspect | archive_objective |
| C33 | Piezas de otro origen | pacto escarlata | 40x30 | M06 | naval, domains, fog, enemy_inspect | sonar_detection, wreck_recovery |
| C34 | Certificados | confederacion solar | 24x18 | — | movement, terrain, production, city_income | maintenance_log_objective, repair_action |
| C35 | Una grabación auténtica | sindicato violeta | 24x18 | — | movement, fog, fog_contacts, enemy_inspect | broadcast_capture |
| C36 | La ruta de los testigos | union verde | 24x18 | — | movement, fog, air, domains | witness_escort |
| C37 | Puertos para una tregua | dominio turquesa | 40x30 | — | naval, domains, fog, relays, ai | aid_route_objective, sonar_detection |
| C38 | El enemigo al lado | alianza norte | 40x30 | A08 | air, domains, attack, counterfire, range, flank | temporary_alliance |
| C39 | Consecuencias de la verdad | legion ambar | 40x30 | M05 | naval, domains, attack, counterfire, large_map | mutiny_objective, coalition_naval_support |
| C40 | El expediente completo | orden onix | 40x30 | M08 | naval, domains, fog, relays, enemy_inspect | evidence_broadcast |
| C41 | Nadie da el primer paso | union verde | 24x18 | — | movement, terrain, capture, opening | negotiation_standoff |
| C42 | Cuentas pendientes | sindicato violeta | 24x18 | — | movement, production, city_income, fuel, resupply, truck | food_distribution |
| C43 | La marcha del regreso | legion ambar | 24x18 | — | movement, fuel, truck, terrain | extraction_objective, transport_cargo |
| C44 | Los últimos barcos | dominio turquesa | 40x30 | — | naval, domains, ammo, fuel, resupply | medical_convoy_escort |
| C45 | La fortaleza vacía | pacto escarlata | 24x18 | — | movement, capture, terrain, city_income | ceding_base_choice |
| C46 | El mapa de los ausentes | confederacion solar | 24x18 | — | movement, air, domains, fuel, drone_consumable | power_distribution |
| C47 | La última orden | alianza norte | 24x18 | — | movement, range, attack, counterfire, height, flank | stop_friendly_offensive |
| C48 | Siete puentes | orden onix | 40x30 | — | movement, capture, relays, terrain, fog | bridge_network_objectives |
| C49 | Meridian resiste | coalicion | 40x30 | — | movement, naval, air, domains, ammo, fuel, production, resupply, ai, large_map, minimap, opening | coalition_scenario, multiobjective |
| C50 | El precio de la paz | coalicion | 40x30 | — | movement, naval, air, domains, capture, city_income, relays, ai, large_map | branch_finale, ending_resolution |

**Interpretación:** la matriz es intencionalmente exhaustiva en cobertura, no una promesa de que todos los sistemas ya estén activos **en campaña**. Cada fila es una **especificación por implementar**, excepto el núcleo C01 que tiene pruebas. Los tamaños de mapa son **propuestos**, no mapas diseñados/optimizados. `M09` es desbloqueo condicional; quitarlo si las pruebas navales no muestran utilidad.

## 4. Coherencia de ocho facciones y niveles

- Las ocho facciones mantienen emblemas, retratos oficiales y balance v0.1 aprobados. No inventar nueva novena facción ni villano todopoderoso; la crisis de Meridian es resultado de fallos y decisiones.
- **Protagonista narrativo ≠ ID físico de bando en motor:** cada misión debe traducir la facción elegida a lado local 0, y rivales/aliados según el guion a lado 1/0, sin transferir bonificaciones permanentes.
- Los 24 desbloqueos se producen dentro de **progreso campaña**, preservando roles/veteranía/variantes actuales hasta migración probada. Las clases absorbidas por el filtro de duplicados se muestran como perfiles/niveles, no como nueve unidades nuevas. Su disponibilidad está sujeta a base, dominio, coste y escenario.
- **Todos los capítulos** deben soportar movimiento por gesto, pinch zoom, cámaras y minimapa compatibles, datos de enemigos visibles, predicción de rango, indicación de cobertura/contrafuego, carteles legibles y guardado. El texto nunca debe ocultar ilegalmente un ataque en progreso.
- No permitir que un jugador de historia transfiera mejoras o recursos al online ni a la IA de escaramuzas; ambos modos conservan reglas y tecnología definidas en la partida, sin ventajas por haber completado 50 capítulos.

## 5. Dependencias técnicas explícitas: no simular sistemas ausentes

| Gancho no existente como regla de misión | Bloquea capítulos | Implementación correcta |
|---|---|---|
| Evaluador universal objetivo/composición de victoria | C01–C50 para experiencia completa | implementar sobre `BattleSession`, pero mantener lógica independiente de escaramuza y probar tras ataque/movimiento/turno |
| HUD de misión, mapa de campaña, diálogos y elecciones | C01–C50 | acoplar al `Main/TouchBoard` actual sin bloquear zoom y selección ni reutilizar guardado de escaramuza |
| Reparaciones técnicas, puentes temporales | C03/C34/C48 | acción de ingeniero con recursos, rango y contramedidas, no solo mensaje de diálogo |
| Evacuación, inspección, entrega, escolta y extracción | C02/04/05/06/19/36/43/44 | marcadores y operaciones de misión con estados validados, sin ataques a civiles |
| Transporte físico terrestre/aéreo/naval, desembarco | C11/C15/C23/C43 | capacidad de carga, embarque, desembarque y protección verificadas; nunca hacer que barco capture |
| Guerra electrónica, sigilo/sonar naval, logística naval M09 | C21/C27/C33/C37/C40 | implementar acciones limitadas, coste, temporizadores y visión justa, **sin crear poderes mágicos** |
| Coaliciones multiactor y habilidades de comandantes | C38/C49/C50 | adaptador narrativo de 2 bandos o sistema de alianzas, separando poderes de facción v0.1 de bonos no implementados |
| Árbol de tres niveles y veterania | episodios que introducen mejoras | habilitar compra/configuración con instalación y coste; veteranía es distinta y no concede ventaja competitiva externa |

## 6. Orden correcto para hacerlo realmente jugable

- **Fase 1: C01 real en Android.** Conectar `CampaignMission` a `TouchBoard`: comenzar ejercicio desde menú, pasar ataques y fin de turno al objetivo, mostrar 2 balizas, diálogos breves, victoria, progreso y checkpoint separado. Reusar misma cámara/sprites/HUD y demostrar sin regresión de IA libre.
- **Fase 2: Misiones de reconocimiento y reparación C02–C03.** Añadir objetivos «visitar/extracción» y «reparar/evacuar» con pruebas, después niebla y eventos; no inventar unidad ingeniero reparadora antes de su acción real.
- **Fase 3: C04–C10.** Integrar logística finita, artillería/alcance, altura, flanqueo, economía, puertos, decisiones con flags. Todas las clases son del motor compartido. El Acto I se prueba hasta cerrar su arco.
- **Fase 4: Actos II–V.** Secuenciar producción, aviación, mar, drones, relés, grandes mapas y finales; habilidades de transporte/sonar/EW solo después de implementar y probar por separado.
- **Fase 5: calidad transversal.** Script de validación de matriz C01–C50; guardado manual/autosave, 3 finales alcanzables, reanudación, compatibilidad, no filtrar niebla, sin bloqueo de arsenal en escaramuza, sin ventajas de facción alteradas y prueba física Android.

## 7. Pruebas de salida (bloqueantes)

1. La matriz contiene **exactamente 50** capítulos, números consecutivos, títulos de la biblia narrativa y **las ocho facciones**.
2. **24 desbloqueos de familias únicas**, con hitos acumulados 8/13/19/24 en actos I–IV, y M09 marcado condicional.
3. **Cobertura**: cada sistema en uso de campaña aparece en al menos una misión; las funciones visuales y de guardado son transversales a TODAS.
4. Desbloqueos narrativos jamás modifican compras/estadísticas de escaramuza online/IA; niveles sólo se activan al existir infraestructura compatible y tests.
5. Guardar/cargar C01 preserva objetivos/eventos, sin duplicar premios o corromper el autosave normal.
6. No fingir reparación, carga, EW ni sonar sin una operación determinista implementada y probada.
7. El mapa/objetivo y la IA no revelan contactos ocultos ni crean ventajas extra al actor que inicia combate.
8. Los tamaños 10×8/24×18/40×30 y dominios corresponden a mapas probados y sean jugables en Android sin UX forzada.

**Rutas oficiales de guiones:** `STORY_CHAPTER_01.md`, `STORY_CHAPTER_02.md`, `STORY_CHAPTER_03.md`, `STORY_ACT_I_CH04_CH10.md`; este archivo los complementa, no cambia canon sin revisión.
