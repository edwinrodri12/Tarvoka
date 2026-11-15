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
