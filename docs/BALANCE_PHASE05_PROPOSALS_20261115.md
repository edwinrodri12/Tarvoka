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
