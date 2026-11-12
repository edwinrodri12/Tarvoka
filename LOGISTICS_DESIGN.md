# TARVOKA — Reglas de munición, combustible y suministros (prototipo v0.2)

Estado: módulo funcional de prueba para batallas modernas, sujeto a CI y balance humano. **Las ocho facciones mantienen intacto su balance v0.1.**

## Recursos tácticos
Cada unidad de las 32 clases del catálogo tiene capacidad máxima de munición y combustible definida en `scripts/core/Logistics.gd`. Las cifras son puntos abstractos de juego, no litros ni proyectiles reales. Soldados a pie tienen combustible 0 (no lo consumen). Unidades de reconocimiento/soporte sin armas tienen munición 0 (no pueden disparar).

- **Disparo válido:** consume 1 punto de munición y agota la acción. Sin munición no se habilitan ataques en el motor ni en la interfaz.
- **Movimiento:** consume tantos puntos de combustible como la distancia ponderada del terreno, nunca más de la capacidad de movimiento por turno. El movimiento y ataque siguen siendo acciones independientes; una unidad puede moverse y atacar en el mismo turno.
- **Mantenimiento por turno:** aeronaves y navíos fuera de sus bases apropiadas gastan 1 punto al terminar su propio turno; submarinos gastan 2. Si ya estaban a 0 al finalizar un turno, pierden 2 HP. Al permanecer sobre base aérea/drones o astillero propio no hay desgaste de combustible. Vehículos terrestres gastan solo por desplazamiento.
- **Sin suministros:** con munición 0 no dispara; con combustible 0 un vehículo no se mueve. Una unidad aérea/naval sin combustible puede perder vida en turnos posteriores. La reserva no se regenera gratis ni por terminar el turno.

## Recarga desde base y en campaña
**Instalaciones:** los puntos de suministro sobre una misma casilla deben pertenecer a la facción:
- Terrestre: taller/cuartel, fábrica de blindados, centro de artillería (no en una ciudad de ingresos).
- Aéreo: aeródromo o centro de drones.
- Naval: astillero.

**Camión logístico:** transporte terrestre sin armamento. Capacidad persistente 16 puntos de munición y 36 puntos de combustible. Puede atender **una unidad terrestre adyacente por turno**, siempre que tenga reservas. Se descuenta el inventario transferido, la acción del receptor y la del camión. Solo se repone el inventario del propio camión desde una instalación terrestre aliada. No abastece barcos ni aeronaves en vuelo.

**Precio en créditos de juego:** las recargas directas en base y la reposición del inventario del camión cuestan 12 por munición, 4 por combustible y 20 créditos como mínimo. Las transferencias desde un camión en el campo **no cobran otra vez**: el suministro ya fue pagado al fabricar o recargar su inventario; se descuenta su carga y se consumen acciones del camión y del receptor. Si faltan créditos en la base o inventario en el camión, se ofrece **reabastecimiento parcial** según las reservas disponibles. Si el vehículo está a 0 de combustible, se prioriza recuperarlo; en los demás casos se prioriza munición. El botón muestra los recursos y su coste antes de ejecutar; una entrega desde el camión puede realizarse incluso con cero créditos si tiene existencias.

**Riesgo/contrajuego:** camiones pueden ser destruidos, necesitan protección; ocupar temporalmente una base para recargar impide usar su casilla de producción simultáneamente en la misma capa.

## Interfaz e IA
Al seleccionar una unidad propia el panel muestra munición X/Y, combustible X/Y, existencias del camión y la cotización de recarga si está disponible. Marcadores **M** y **F** ámbar/rojos identifican reservas bajas o agotadas solo para unidades propias: no se revelan reservas ocultas del oponente. El enemigo usa el mismo cálculo de existencias, créditos y acciones. Una IA puede reabastecer unidades críticas, pero no fabricar recursos virtuales ni consultar posiciones enemigas ocultas.

## Guardado y compatibilidad
La estructura JSON v1 preserva campos optativos `ammo` y `fuel`, y para camiones `supply_ammo`, `supply_fuel`, `supply_used`. Se validan rangos y tipos, y se rechazan cargas parciales o falsificaciones de otros roles. Las partidas clásicas sin suministros mantienen su comportamiento anterior. Partidas modernas anteriores a esta versión pueden carecer de inventario de camión; su stock inicial se interpreta de forma compatible con la versión anterior.

## QA y límites conocidos
Pruebas en `tests/test_logistics.gd` y `tests/test_logistics_advanced.gd`, más partidas de IA, Godot headless y exportación Android ARM64. No se debe declarar finalizado el sistema sin resultados CI correctos y pruebas Android físicas.

Sistemas pendientes por separado: destrucción/consumo definitivo de drones FPV, munición merodeadora y USV después de atacar; diferenciación de tipos de munición y ataque; despliegue/transporte de combustible; abastecimiento de unidades cargadas en transportes; inteligencia del retorno preventivo a base y cálculo de rutas; balance de las reservas y costes en partidas largas.


## Fase siguiente — drones consumibles y regreso preventivo (v0.3)

- **FPV, munición merodeadora y USV**: al realizar un ataque válido, infligen el daño habitual y la unidad atacante queda con 0 HP (consumida). No regresan, no reciben un segundo disparo ni se recargan tras el impacto. En un ataque inválido no se consumen. El motor recalcula la victoria si era la última unidad propia. No es lo mismo que el UCAV convencional, que sigue siendo reutilizable.
- **IA de regreso a suministro**: tras priorizar una amenaza inmediata y los ataques disponibles, unidades con munición/carga/combustible críticos consultan exclusivamente bases propias y topología previamente descubierta. Con el sistema de rutas ponderadas, se busca un destino de movimiento legal que reduzca el trayecto hasta una instalación compatible. No se emprende regreso cuando no hay combustible suficiente para cubrir **toda** la ruta ni cuando no hay crédito mínimo para una recarga en base. No se altera la visibilidad de la niebla de guerra ni se ignoran bloqueos. Los drones consumibles no regresan.
- **Pruebas de regresión**: `tests/test_consumables_supply_return.gd` verifica ataques consumibles, guardados después del sacrificio, victoria cuando cae la última unidad, UCAV reutilizable, regreso en varios turnos, falta de combustible, fondos y comportamiento con enemigos ocultos.

Límites todavía existentes: el regreso automático a camiones cercanos no forma parte de esta fase, solo a instalaciones propias; la IA no calcula una ruta de evacuación completa si la base está fuera del terreno ya explorado, ni detecta amenazas móviles invisibles en la ruta. Esta fase no introduce nuevas ventajas de facción ni modifica sus valores aprobados.


## Fase v0.4 — Abastecimiento móvil y efectos de batalla

- **Camión de asistencia:** la IA puede trasladar un camión con inventario real hacia una unidad terrestre aliada con munición o combustible críticos, sin transportar recursos virtuales. Selecciona un espacio libre adyacente y calcula rutas ponderadas; conserva 2 puntos de combustible de seguridad. En siguientes pasos de IA entrega con el sistema normal de `Logistics.resupply`: inventario, acciones y créditos mantienen sus reglas.
- **Restricción de conocimiento:** el convoy solo puede utilizar terreno conocido y movimientos actualmente visibles bajo niebla. No usa posiciones enemigas ocultas. Se detiene si no tiene stock, combustible suficiente o no existe un vecino accesible.
- **Visualización de combate:** los ataques válidos muestran temporalmente destello de impacto, trayectoria del disparo cuando el origen era visible y pulso de destrucción cuando desaparece el blanco; los drones de un uso incorporan onda en su punto de lanzamiento. Los efectos **no son unidades**, no afectan el cálculo de movimiento/combate, no tocan los guardados ni se muestran en casillas invisibles. Desaparecen a los 0.55 s.
- **Pruebas añadidas:** abastecimiento móvil, reserva mínima del camión, entrega sin cobrar dos veces, integridad de guardados, niebla de guerra, efecto visual transitorio y cuatro campañas IA de hasta 24 fases para detectar stocks fuera de rango, gasto de créditos negativo, compras sin inventario o deserialización incorrecta.

El comportamiento de los ocho bandos v0.1 permanece intacto. Las simulaciones solo miden integridad y acciones; no prueban todavía que el balance sea competitivo y divertido. La nueva animación es vectorial 2D de prototipo, no arte definitivo.


## Fase v0.5 — economía de desgaste, reservas y campañas prolongadas

**Diagnóstico:** las primeras cuatro partidas de estrés con relés finalizaron a las 5–10 fases por puntuación territorial, no porque ambos ejércitos se quedaran sin reservas. Esa es la causa metodológica de los 0 reabastecimientos observados en esa muestra; no demuestra que la IA sepa gestionar una campaña larga.

**Gestión logística de la IA:** `SupplyStrategy.assess` contabiliza solo tropas aliadas visibles para el propio bando, camiones disponibles, inventarios agotados y unidades críticas en cada dominio. Sin modificar el precio de ninguna unidad, preserva **96 créditos de juego** para rearmar cuando ya existen unidades escasas de recursos. No bloquea la adquisición del primer camión indispensable: si hay tropas terrestres varadas y no existe uno, la IA lo prioriza sobre otra infantería. Si existen cuatro unidades terrestres críticamente desabastecidas, puede priorizar un segundo camión mientras haya menos de dos. Las compras siguen requiriendo créditos, taller propio libre y una sola fabricación por instalación/turno.

**Pruebas separadas:** se conserva el test de victoria por relés para jugabilidad breve, pero `test_attrition_campaign.gd` usa partidas sin relés para medir agotamiento y logística sin victoria prematura. Contiene dos subpruebas: (1) naves desarmadas en un escenario de bajo presupuesto para registrar gasto de combustible, pérdida real de HP y prolongación de turnos; (2) combate moderno con economía activa, compras y control del inventario, sin objetivo de señal. `test_supply_strategy.gd` verifica que la IA compre un camión por demanda real, que el camión alcance a un aliado aislado en un turno posterior y reabastezca usando sus existencias prepagadas, así como la reserva de crédito, la ausencia de omnisciencia y el caso sin déficit.

**Balance:** la reserva y prioridad de compra son decisiones de la IA, no bonificaciones de facciones. No se ha cambiado el v0.1 de los ocho bandos. Estas pruebas son instrumentación y validación funcional; no sustituyen partidas humanas ni métricas de equidad competitiva. Las pruebas sin relés son un modo ya accesible desde la selección de objetivo de TARVOKA.
