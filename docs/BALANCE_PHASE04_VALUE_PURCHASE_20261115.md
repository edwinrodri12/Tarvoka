# TARVOKA — Auditoría de equilibrio, fase 04: valor por crédito, redundancias y compras de IA

**Fecha:** 15 de noviembre de 2026. **Estado:** experimento en rama independiente; no modifica las reglas competitivas, precios, valores de facción, comandantes, modelos 3D, motor o guardados.

## Preguntas comprobables
1. ¿La IA deja sin comprar clases porque no puede construirlas, porque son inaccesibles en sus mapas, o porque su lista fija de prioridades selecciona otras?
2. ¿Hay unidades que, con las **mecánicas actualmente implementadas**, sean estrictamente menos eficientes que otra en el mismo edificio productivo, mismo tipo de objetivos y misma función de captura?
3. ¿Cuál es el **intercambio económico inmediato** en duelos sobre llanura, bosque y altura, incluyendo el daño recibido por contraataque y el coste de un dron que se destruye al impactar?

## Cómo se midió
- `tests/test_balance_phase04_value_purchase.gd` consulta las **32 clases** con `Economy.producer_for`, `Economy.can_purchase` y una compra real `Session.purchase` en ambos bandos del mapa costero; requiere tener el dinero y el edificio disponible. Esta parte distingue **factibilidad** de **preferencia de la IA**.
- Prueba aislada de la **primera decisión de compra** de `BasicAI.step` en cada uno de los seis productores (`factory`, `armor_plant`, `artillery_depot`, `drone_center`, `airbase` y `shipyard`). Se usan mismos ejércitos, crédito suficiente, todas las unidades propias ya actuadas y solo un edificio de producción propio. El resto se neutraliza **solo en memoria de la prueba**, para que la política de límite de compras por turno no quede artificialmente consumida; el juego original no se altera.
- Comparación de dominancia **conservadora**: solo roles del **mismo dominio**, mismo conjunto de objetivos, mismo productor, mismo estatus de captura, misma tracción, mismo estilo de ataque y no consumibles. El candidato debe ser igual o mejor en HP, daño, defensa, movilidad, visión, rango, munición, combustible, reacción y precio, y no perder ninguna bonificación especial de `UnitRoles.role_bonus` contra ninguna clase. Es una **alerta de redundancia mecánica actual**, no un veredicto definitivo de diseño; una capacidad futura puede cambiar la conclusión.
- **32 emparejamientos concretos** (tierra, aire, mar, antiaéreos, artillería, drones de un solo uso) × tres coberturas × ambos colores de quien ataca. Contrasta `Attack.preview_exchange` con `Attack.attack` real; verifica daño, HP, munición, contraataque y autodestrucción de consumibles. Calcula **valor inmediato del daño** por fracción de HP sobre precio del objetivo y resta el coste del daño de respuesta o la pérdida total de un dron consumible. No supone que el duelista sobrevivirá a sucesivos turnos, capturará ciudades o encontrará oportunidades de disparo.

## Interpretación y límites
- Una unidad barata de captura y visión como el explorador puede ser preferida por la IA debido a una **prioridad programada**, no por una comparación económica de rol contra rol.
- Los ataques de artillería y misiles valorados en un intercambio NO miden la libertad de colocación, línea de visión, movimiento + ataque, consumos de combustible, defensa aérea, cobertura de objetivos ni valor de ciudad; no convertir «rentabilidad por disparo» en sentencia de balance.
- `CombatDoctrine.tier` representa **acto de presentación en campaña**, no una mejora de atributos ya implementada. Los ocho bonos de facción v0.1 quedan intactos.
- Las características previstas para Ingeniero, Asaltante, transporte, guerra electrónica, submarinos y otros roles no se deben presumir ya jugables: documentar primero qué hace efectivamente el código. No se publican ajustes sin experimentos A/B y partidas más representativas.
- Solo se usa el mapa costero 10×8 para la elegibilidad de todos los dominios. Probar mapas 24×18 y 40×30 y partidas largas queda para etapas posteriores.
- Los ejemplos de IA están **aislados artificialmente**: no constituyen una simulación de partidas completas ni prueban cuál opción es óptima para ganar.

## Entrega y pasos de decisión
Esperar la auditoría real de CI de Godot 4.3. Si se detecta una dominancia estricta (p.ej. Guardia vs Asaltante), priorizar asignar una **identidad táctica implementada** a cada clase antes de rebajar mecánicamente precios o fuerza. Probar ataques contra distintas armaduras y cobertura; después estudiar si la IA puede reconocer momentos para introducir unidades navales y tecnológicas costosas, en vez de producir siempre el primer rol asequible.

## CI y hallazgos reales — Godot 4.3, 15/11/2026

**Auditoría verificada:** [GitHub Actions #43699143091 — SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43699143091). El ensayo anterior #43698957776 también fue exitoso; este último añade estudio de presupuestos y de observación aérea y deja las expectativas de orden de compra como métricas, no como asserts de comportamiento congelado.

### Producción y sesgo de la IA

- **64/64 compras individuales legales:** 32 roles × 2 bandos, en el mapa costero donde existen instalaciones de tierra, aire y mar. El costo y el débito coinciden con la economía autorizada; los dos bandos ofrecen las mismas 32 opciones. **No demuestra que las 32 sean elegidas por la IA durante partidas ni que sean igual de rentables**.
- **12 decisiones con crédito holgado:** un edificio controlado por vez, sin movimientos previos, en ambos colores; la compra inicial se replicó idénticamente en ambos bandos.
- **48 sondas de presupuesto:** seis instalaciones × cuatro disponibilidades (200, 500, 1000, 2500) × ambos colores. No hubo casos en que, en este escenario artificialmente aislado, `BasicAI.step` omitiera comprar pese a haber una alternativa legal; no extrapolar a partidas largas con límites de producción o reservas.
- **2 pruebas de reconocimiento:** en ambos bandos, cuando ve aeronaves enemigas la IA compra **SAM**, y cuando las aeronaves enemigas se retiran del estado observado compra **artillería autopropulsada**. Esto demuestra una reacción de prioridad al contrincante en esta situación controlada.
- Las prioridades modernas actuales están expresadas mediante arrays de roles ordenados en `BasicAI._produce_modern_reinforcements`. El modelo primero considera roles sin una unidad presente, luego los restantes, y revalida presupuesto, instalaciones y reservas. El patrón de consumo anterior puede explicarse parcialmente por este orden, no solo por HP, ataque o precio.

| Instalación (una disponible, presupuesto 10.000) | Primera elección de IA en ambos bandos | Con presupuesto más bajo |
|---|---|---|
| Fábrica | Asaltante | Con 200 créditos: explorador |
| Planta blindada | Rompedor | Con 500: rompedor |
| Depósito artillero (con enemigo aéreo visible) | SAM | Con 500: lanzador |
| Centro de drones | FPV | Con 200: FPV |
| Base aérea | Caza | **Con 500: helicóptero de transporte** |
| Astillero | Patrullero | Con 500: patrullero |

**Riesgo comprobable:** el helicóptero de transporte vale 500 créditos y tiene ataque 0, mientras que la operación de transporte de tropas todavía figura como pendiente en el catálogo. Su compra en el escenario de presupuesto bajo es legal pero tiene una utilidad efectiva muy limitada **hasta que esa mecánica se implemente**. La recomendación es revisar la prioridad de reclutamiento para funciones pendientes, no rebajar automáticamente su precio.

### Redundancias en el motor actual

La comparación conservadora de roles con mismo dominio, fabricante, objetivos, captura, estilo de ataque, tracción y bonificaciones de enfrentamiento reveló **tres candidatos a dominancia**:

1. **Guardia > Asaltante**. Guardia: 200 créditos, 10 HP; Asaltante: 250 créditos, 9 HP. Ataque 5, movimiento 3, visión 3, defensa 0, rango 1, munición 6, reacción 55 %, captura de ciudad y productor son iguales. El Asaltante **no posee todavía una ventaja urbana aplicada en su daño o movilidad**.
2. **Guardia > Ingeniero**. Guardia: 200 créditos, 10 HP, ataque 5, movimiento 3 y munición 6; Ingeniero: 250 créditos, 7 HP, ataque 2, movimiento 2 y munición 3. Ambas capturan y tienen fábrica como productor. La reparación/infraestructura especial del Ingeniero todavía no está implementada.
3. **Asaltante > Ingeniero**. Ambos cuestan 250, pero Asaltante posee mejores valores de HP, ataque, movimiento y reacción bajo las capacidades activas.

Estos son casos de **redundancia de las capacidades numéricas actuales**, no sentencias permanentes sobre su valor narrativo, uso humano o contenido 3D. Ajustes de rol deben priorizar habilidades **implementadas y probadas**, no solo descripciones. No se aprueba ningún buff/nerf en esta fase.

### Duelos y créditos por daño — 192 ejecuciones reales

Los 32 enfrentamientos seleccionados se ejecutaron con tres coberturas (llanura, bosque, montaña) y ambos bandos, comprobando que las acciones reales dan los mismos HP, contraataque, gasto de munición y consumo de drones que la vista previa. `net_hp_purchase_value` se calculó como la fracción de precio destruida del objetivo, menos la fracción de precio perdida por reacción; si el atacante es consumible, se resta **todo su precio**. Es una aproximación de **un solo disparo** sobre una unidad con HP completo, no beneficio a lo largo de toda una batalla.

| Encuentro (atacante → objetivo) | Daño inicial medio | Daño recibido medio | Valor monetario neto del intercambio |
|---|---:|---:|---:|
| Guardia → Asaltante | 3,67 | 2,33 | +55 |
| Asaltante → Guardia | 3,67 | 2,33 | +8 |
| Rompedor → Baluarte | 4,67 | 1,33 | +86 |
| Rompedor → Tanque | 1,33 | 5,00 | **−116** |
| Tanque → Rompedor | 6,67 | 0,67 | +214 |
| Explorador → Lanzador artillero | 3,67 | 0 | +210 |
| FPV → Tanque | 4,00 | 0 | +14 tras destruirse |
| Munición merodeadora → Tanque | 5,00 | 0 | **−82 tras destruirse** |
| Antiaéreo móvil → Caza | 5,00 | 2,00 | +445 |
| SAM → Caza | 7,00 | 1,00 | +665 |

**Lectura principal:** el Rompedor sí destaca contra Baluarte, pero **no recibe automáticamente una ventaja especializada contra el tanque** en las reglas reales; el tanque lo supera en duelo aislado. Eso puede ser una decisión de diseño o una brecha entre identidad anunciada («antiblindaje») y habilidad implementada. La munición merodeadora aporta mayor rango que FPV, así que un saldo por disparo negativo no demuestra que su costo sea incorrecto; la capacidad de disparar desde lejos es parte de su valor.

### Prioridades para la fase siguiente

1. Revisar **identidad táctica funcional** de Asaltante e Ingeniero, antes de tocar precios. En una rama de experimento A/B, simular una ventaja urbana específica del Asaltante y la habilidad de reparación del Ingeniero, siempre marcadas como propuestas no incorporadas.
2. Investigar el desempeño del Rompedor contra distintas **armaduras reales** y decidir si la descripción de contramedida debe precisar Baluarte o si necesita un bono antiblindaje razonable contra tanque/IFV. Medir supervivencia, HP y precio con tropas de apoyo, no solo un choque.
3. Ajustar criterios de compra de la IA para **evitar producir unidades sin sus habilidades fundamentales** cuando existe una alternativa táctica que sí funciona; testearlo sin sesgar la decisión hacia el primer jugador.
4. Continuar el estudio de la **economía costera**, donde las brechas de material e ingreso se amplifican, con partidas más largas y orígenes variados; contrastar cuándo la IA compra la primera unidad naval.
5. Conservar las ocho ventajas de facción aprobadas y el sistema de veterancia con **bonificaciones actualmente 0**. No presentar `tier` como mejora activa ni afirmar poderes funcionales no verificados.
