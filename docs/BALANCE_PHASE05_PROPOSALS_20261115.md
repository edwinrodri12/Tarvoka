# TARVOKA — Propuestas de identidad táctica y compra IA (experimento v0.5)

**Estado:** rama experimental de Godot 4.3, **no integrado** al motor activo ni a partidas guardadas. No modifica los ocho bonos de facción v0.1, poderes de comandante, veterancia, costes, estadísticas base, interfaz o APK. Se creó tras la auditoría fase 04, que identificó redundancia entre Guardia, Asaltante e Ingeniero y una compra improductiva de helicóptero de transporte con crédito insuficiente para armamento aéreo.

## Tres propuestas a ensayar

### P1 — Asaltante: combate urbano real

Al atacar **una unidad TERRESTRE situada sobre una ciudad**, el Asaltante anula **exclusivamente la bonificación defensiva de +1 que da la ciudad**. Bosque, montaña, defensa propia de la unidad, flanqueo, altura y demás atributos continúan iguales. No afecta a aeronaves, barcos, terreno sin ciudad, disparos del rival ni al contraataque del Asaltante cuando es defensor. No mejora su ataque base de 5, vida de 9, movimiento 3, munición 6 ni coste 250.

**Implementación del ensayo:** `BalanceProposalV05.urban_assault_attack` llama a `BattleSession.attack` con una copia temporal de ataque +1 **solo cuando el objetivo terrestre ocupa una ciudad** y devuelve un estado con el ataque original restaurado. Es el equivalente exacto a ignorar la cobertura urbana +1 con el actual `BattleActions._strike`, sin alterar el código de producción. Comparar daño, contraataque, gasto de munición, neutralidad del estado original y guardado v1 frente al ataque real de base.

**Riesgo a estudiar:** si el bonus de un punto proporciona un incentivo excesivo a asaltar ciudades cuando el atacante puede mover y atacar el mismo turno, o elimina demasiado fácilmente a la infantería defensora. La cobertura forestal o montañosa aún ofrece un margen táctico.

### P2 — Ingeniero: reparaciones limitadas y pagadas

- **Alcance:** a **una casilla ortogonal** de una unidad terrestre mecánica aliada (APC, IFV, tanque, artillería autopropulsada, cohetes, antiaéreo, SAM, guerra electrónica o camión logístico).
- **Restauración:** máximo **2 HP** por acción, nunca por encima del HP máximo. No revive unidades destruidas. No repara infantería, aeronaves o barcos; tampoco se repara a sí mismo.
- **Costo:** **85 % del valor de reposición de los HP recuperados**, mínimo **20 créditos**; p.ej. tanque 750 créditos/14 HP, 2 HP ⇒ ~92 créditos. El descuento está sujeto a la necesidad de fabricar y mantener Ingenieros y consumir su orden activa, por lo que no hay curación gratuita.
- **Frecuencia:** una acción del Ingeniero por turno propio; mover y después reparar está permitido, pero no se puede volver a mover, reparar o atacar tras hacerlo. Consume una orden de apertura si corresponde.
- **Seguridad:** requiere economía moderna válida, dueño actual, créditos suficientes, distancias y objetivos legales; rechaza unidades enemigas, muertas, fuera de alcance o al máximo de salud.
- **Compatibilidad:** modifica **solo** HP existente, créditos y `acted`; ningún campo persistente o versión de guardado.

**Riesgo a estudiar:** puede prolongar innecesariamente partidas si reparar blindados es demasiado asequible. Futuros tests A/B deben medir turnos hasta la victoria, carga económica total (incluido costo del Ingeniero y turnos gastados), rotación logística y vulnerabilidad del Ingeniero al frente.

### P3 — IA: valorar utilidad implementada, no comprar por completar una lista

El agente experimental no reemplaza todavía a `BasicAI`. Decide *para un edificio concreto*, revalidando los mismos `Economy.can_purchase`, `SupplyStrategy.can_spend_on_recruitment`, límites por fase y visibilidad real por niebla. Efectos deseados:

- **Fábrica:** comprar Guardia como opción segura; Asaltante si hay enemigo **observado** defendiendo una ciudad cercana; Ingeniero solo cuando haya blindado propio dañado cerca del productor y esta reparación experimental esté disponible; camión cuando exista demanda de suministro.
- **Blindados:** preferir tanque o IFV frente a amenaza de tanque; Rompedor conserva prioridad situacional contra Baluarte, su objetivo antiblindaje ya programado.
- **Artillería:** respetar presencia de amenaza aérea observada. No comprar guerra electrónica únicamente por existir en el catálogo si el sistema de interferencia sigue sin existir.
- **Drones:** conservar FPV y reconocimiento, pero no confundir un consumible barato con una plataforma reutilizable.
- **Base aérea:** ante amenaza aérea, priorizar caza; sin amenazas, helicóptero de ataque. Con **500 créditos**, cuando solo alcanza para helicóptero **de transporte sin función de carga**, **reservar** dinero en vez de adquirir una unidad sin misión efectiva.
- **Astillero:** seleccionar patrullero y otros buques realmente armados; diferir buque de desembarco hasta tener carga/desembarco funcional.
- **Transparencia:** quien juega manualmente conserva la libertad de comprar cualquier unidad legal, incluso las experimentales; se ajusta la lógica de elección de IA, nunca se ocultan unidades de la interfaz ni se cambian precios.

**Limitación de la IA propuesta:** elige una compra para **una instalación específica**; no es aún un reemplazo completo del planificador de operaciones. No puede probar por sí solo variedad de estrategia ni eficacia en partidas con 8 jugadores.

## Pruebas y decisión

`tests/test_balance_phase05_proposals.gd` compara ataque urbano base/propuesta en ambos bandos y coberturas, reparaciones válidas e inválidas y decisiones AI baseline/propuestas con fábricas y crédito controlado; valida que un resultado no manipule las estadísticas originales y que los nuevos estados se puedan serializar como partidas existentes. La suite se ejecuta bajo `.github/workflows/balance-phase05-proposals.yml`.

**No fijar las tres habilidades como definitivas por obtener PASS técnico.** Para promover una propuesta al juego: identificar una ventaja diferencial razonable en situaciones correspondientes y nula fuera de ellas, mantener previsión y daño real idénticos, verificar una partida larga con IA en mapa costero y bosque, comprobar que las respuestas del enemigo son claras y que las ocho facciones reciben exactamente la misma mecánica básica, luego revisar ergonomía de Android y las reglas de guardado.

## Resultados reproducibles verificados — 15/11/2026

**Godot 4.3:** [suite A/B #43734603282 — SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43734603282). Previa básica: [#43734333958 — SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43734333958). Una prueba intermedia falló por exigir que la IA comprara sin reservas en un escenario de niebla; el test se corrigió con presupuesto suficiente para conservar la regla auténtica de ahorro, no reduciendo el requisito de privacidad de información.

### P1: 40 muestras de ataque, sin mejorar estadísticas permanentes

- **30 ataques urbanos** (2 lados × 5 blancos × llanura/bosque/montaña); **24** infligieron +1 HP de daño y **6** no aumentaron daño por límites/mínimo de la fórmula actual. Nunca superó +1 ni redujo daño.
- **10 ataques fuera de ciudad** conservaron resultados y estado idénticos al juego actual.
- **10 ataques urbanos de otras cinco clases** (Guardia, Explorador, Rompedor, Ingeniero, Tanque) permanecieron idénticos; esto protege la exclusividad de la habilidad.
- Ambos lados tienen condiciones idénticas y la prueba pasó compatibilidad del guardado, recuperación del ataque base y gasto de munición. No es evaluación de captura de ciudades a largo plazo.

### P2: 40 comprobaciones de reparación y dos ciclos reales de turnos

- **20 acciones válidas** de reparación/situación, incluyendo ocho familias de vehículos terrestres por cada bando, ingeniero que ya se movió y vehículo con solo 1 HP faltante.
- **20 rechazos obligatorios**: dinero insuficiente, distancia, orden gastada, destrucción, salud máxima, enemigo, persona incorrecta, avión, economía clásica y partida finalizada (en ambos colores).
- En el tanque, **reparar 2 HP cuesta exactamente 92 créditos**, no los 750 de comprar uno nuevo. Se amortiza mediante exposición del Ingeniero, su coste original, estar adyacente y consumir la orden; si estos costes resultan insuficientes en partidas largas deberá revisarse.
- **Dos verificaciones de ciclos** (un ciclo por bando): prohibición de reparar dos veces en la misma fase, límite de apertura que consume una orden, posibilidad de reparación al comenzar el siguiente turno propio, límite estricto del HP máximo, persistencia del estado y pagos correctos entre turnos.

### P3: 60 comparaciones de compra real, controlando dinero y observación

- **60 decisiones A/B** (6 tipos de instalación × 5 presupuestos 200/500/700/1000/2500 × ambos colores): **30** propuestas difirieron del comportamiento base. Hubo **10 casos de reservar recursos**, sin producir una unidad, en situaciones donde los mejores roles no eran elegibles o no merecían el gasto.
- Con **500 créditos en la base aérea**, la IA actual compró el **helicóptero de transporte en ambos colores**; la propuesta **reservó créditos en ambos** en vez de comprar una unidad cuyo transporte de tropas aún no funciona.
- Con **700 créditos**, la alternativa compró helicóptero de ataque; con 1.000 y enemigo aéreo observado, compró caza. Se mantuvo selección simétrica para ambos colores.
- Una unidad blindada aliada herida cerca de la fábrica desencadenó la recomendación experimental de Ingeniero en ambos bandos, **solo porque también se implementó la reparación de ensayo**.
- **Dos pruebas de niebla con reserva económica suficiente**: cuando los aviones contrarios estaban ocultos, la recomendación fue helicóptero de ataque; al hacerlos visibles, pasó a caza. Modificar exclusivamente los créditos **ocultos** del otro jugador no cambió la recomendación.
- Estas 60 decisiones son ensayos de una sola fábrica, no una tasa de rendimiento de IA en batallas enteras.

### Dictamen y condiciones para una futura integración

**Aceptadas para una segunda ronda de simulación, NO aprobadas como reglas permanentes.** Los tres prototipos tienen una implementación aislada real y pruebas de consistencia simétricas. Para integrarlos al juego deberán incorporarse con las mismas comprobaciones a:

1. `BattleSession` y `BattleActions`/previsión del HUD: una habilidad urbana debe aparecer en el indicador de daño **antes** del ataque, sin mostrar información oculta.
2. Acciones de Ingeniero en UI Android y validación de guardado actual, incluida compatibilidad con `OpeningBalance`, niebla y desgaste.
3. `BasicAI` y selección de prioridades solo si partidas reales A/B en costa/bosque muestran mejora de **material total**, captura, contrajuego, costo neto de mantenimiento y duración, no solo menos compras inútiles.
4. Jugar pruebas de estrés con dos bandos primero; para ocho participantes todavía no existe el motor multibando jugable. Revisar potencial estrategia de reparar blindados sin fin y si la ventaja urbana desplaza excesivamente a la Guardia.
5. Guardar los bonos de facción v0.1, veterancia (bonos actualmente cero) y demás números intactos hasta disponer de evidencia de balance competitiva.

**La suite en verde NO implica que las habilidades estén ya disponibles en el APK, menú, IA del juego o multijugador.** Son alternativas de código reales, invocadas únicamente por el script experimental. No fusionar este PR todavía.
