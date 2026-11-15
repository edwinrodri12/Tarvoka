# TARVOKA — Balance fase 03: valor real del ejército y capacidad de remontada

Fecha: 15 de noviembre de 2026. **Solo investigación reproducible en Godot 4.3; no cambia estadísticas, facciones, IA, habilidades, UI, mapas, saves ni APK.**

## Decisión a investigar
El precio de una unidad, el dinero disponible y las ciudades no cuentan toda la historia. Para detectar si una captura temprana crea una ventaja imposible de remontar, comparar partidas equivalentes por mapa, visibilidad, jugador iniciador y límite de órdenes, y medir la riqueza junto a la fuerza militar que sobrevive.

## Métricas y cautelas
- **Caja:** créditos disponibles en cada bando. Su déficit puede deberse a **compras** y no a desventaja.
- **Valor militar aproximado:** sumatorio de `coste_del_rol × (HP actual / HP máximo)` para cada unidad viva. Una unidad dañada vale menos en esta aproximación, pero esto **no** representa DPS, capacidad de capturar, distancia al objetivo ni reemplazo exacto.
- **Material total aproximado:** **caja + valor militar**. No suma nuevamente la munición y combustible: sus inventarios de compra ya están implícitos en el precio de la unidad. No es un KPI de justicia ni un ELO.
- **Munición y combustible:** % de llenado ponderado por la capacidad de las unidades vivas. Se reportan separados del material total. No cuenta munición gastada por unidades destruidas y no capta distancia a depósito.
- **Ingreso urbano:** créditos por turno propio por ciudades controladas; el motor solo paga al inicio del turno correspondiente.
- **Recuperación de ingresos:** una facción colocada artificialmente en desventaja económica alcanza la misma renta del rival o mayor durante alguna ronda completa.
- **Reversión del material:** la facción con ciudad inicial menos primero queda por debajo en el material medido y posteriormente lo iguala o supera. No es necesariamente victoria, ni implica recuperación de posición.
- **Resultados de partida:** victoria, derrota o aún abierta al cortar; los empates no se infieren de un límite de fases.

## Experimento A/B controlado, no cambio al juego
`tests/test_balance_phase03_recovery.gd` ejecuta **48 partidas con IA real**, conservando misma formación inicial, precios, mapas, equipo, clima claro y reglas:
- Dos escenarios oficiales: **Bosque de las Dos Rutas** (ID 1) y **Costa de las Dos Bahías** (ID 3), priorizados por desbalances descriptivos detectados en fase 02.
- Visibilidad con/sin niebla.
- Bando que comienza azul/rojo.
- Apertura sin limitación o con **tres órdenes**.
- Tres tratamientos reproducibles: **control normal**, una **ciudad neutral próxima al iniciador atribuida desde el principio** o una próxima al jugador que responde.
- Máximo **24 medias fases** (~12 turnos de cada bando; puede finalizar antes por eliminación). Sin victoria por relés: se aísla combate/economía y no se mezclan condiciones de puntuación.
- Se rastrean compras, roles comprados, recuperaciones, cambios de dueño de ciudades, acciones, recargas, caja, material, valor del ejército, rentas y efectivos supervivientes.
- Verificaciones: paridad de dinero y valor de fuerzas antes de la partida, diferencia de renta deliberada de exactamente 250 en tratamientos, gasto legal por acción, pago correcto por turno, persistencia JSON en límites de turno y economía válida.

**Importante:** la ciudad extra es un **handicap experimental** colocado en el estado inicial de una sesión de diagnóstico, NO una nueva regla de juego ni una opción publicable. Ayuda a separar la ventaja de territorio de la iniciativa de turno.

## Qué se aceptará como hallazgo
- Comparar **grupos emparejados**, no buscar un número global de victorias ni declarar un mapa “injusto” porque un grupo limitado muestre un gran desequilibrio.
- Si la costa produce mayor diferencia en material total que el bosque, priorizar allí estudios de capturas, rutas, compras y composición. **Efectivo sin invertir no equivale a ejército.**
- Si los tratamientos de una ciudad aumentan material pero el desventajado recupera rentas habitualmente, existe margen de remontada; si no, podría haber riesgo de bola de nieve. Un grupo corto de IA determinista no demuestra comportamiento humano.
- **No tocar los bonos de ocho facciones**, ni precio de unidades cuyo apoyo especial no funciona, hasta probar contrajuego y coste total con su mecánica efectiva.
- **No usar los tiers del catálogo como mejoras**: son actos de introducción, no un sistema de mejoras implementado.
- No extrapolar de partidas de dos bandos al futuro multijugador de ocho.

## Próxima fase
Si las diferencias de material revelan riesgo real, añadir mapas alternativos y composiciones militares controladas, simular partidas hasta victoria o estancamiento, medir calidad de ingresos, uso real de cada unidad y rango de coste/efecto. La calidad visual 3D se sigue desarrollando independientemente.
