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

## Resultados reales de Godot 4.3 — fase 03

**CI auditada:** [GitHub Actions #43697467718 — SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43697467718) (prueba original #43696957230 y segunda revisión #43697237582 también SUCCESS).

Se ejecutaron **48 partidas de IA**, con un límite de **24 medias fases**, de las cuales **46 estaban sin resolver** y **dos terminaron por eliminación** (ambas en la condición experimental de ciudad extra para quien responde en el mapa costero). Se registraron **8.984 acciones**, **1.787 compras**, **218 cambios de control de ciudad** y **184 reabastecimientos**. No es una muestra de tasas de victoria definitiva.

### Renta, materiales y ventaja de iniciativa

En las cifras siguientes, «brecha» es la diferencia media **absoluta** entre bandos al final, no necesariamente una ventaja para quien tenía la ciudad extra. «Ventaja firmada» es `material_del_bando_de_referencia - material_del_otro`, donde el bando de referencia es **el iniciador en partidas normales**, o **el dueño experimental de la ciudad adicional** en tratamientos. Un número positivo favorece a ese bando. Cada fila representa **ocho ejecuciones deterministas**, con dos bandos intercambiados; no son ocho situaciones independientes de jugadores humanos.

| Mapa / tratamiento | Brecha media de caja | Brecha media de material total | Ventaja firmada media de referencia | Brecha media final de ingreso por turno |
|---|---:|---:|---:|---:|
| Bosque / normal | 1.369 | **1.688** | +229 (iniciador) | 0 |
| Bosque / ciudad para iniciador | 2.305 | **2.318** | +1.800 (iniciador) | 63 |
| Bosque / ciudad para respondedor | 1.123 | **1.843** | +537 (respondedor) | 250 |
| Costa / normal | 2.975 | **3.784** | +1.651 (iniciador) | 500 |
| Costa / ciudad para iniciador | 3.684 | **4.127** | +4.127 (iniciador) | 688 |
| Costa / ciudad para respondedor | 2.446 | **4.241** | +4.241 (respondedor) | 500 |

El resultado sobre **costa** justifica analizar por qué la distribución urbana, el orden de compras/combates y las rutas tienden a separarse más que en bosque. **No demuestra por sí solo que el mapa deba rediseñarse o que el jugador iniciador gane**: después de 12 turnos propios la mayor parte de partidas seguían abiertas.

### Remontadas: distinguir un instante favorable del resultado sostenido

Las 16 sesiones **normales** no tienen una ciudad asignada en forma artificial y se excluyen de este denominador. En las **32 sesiones con un bando favorecido por una ciudad inicial**, el bando originalmente desfavorecido registró:

- **32/32**: al menos una ronda completa con ingresos iguales o superiores a los del favorecido.
- **26/32**: ingresos iguales o superiores durante **tres rondas completas consecutivas** en algún momento.
- **15/32**: ingresos iguales o superiores **al final de la sesión**.
- **10/32**: **alguna inversión de la ventaja de material** después de haber estado por debajo.
- **6/32**: **mayor o igual material total al final** del periodo observado.

Estos eventos se superponen; no son porcentajes de victorias ni confianza estadística. La recuperación de ingresos no implica recuperación de ejército o terreno; el desequilibrio puede reaparecer después de tres rondas favorables.

Desglose de recuperación del bando **sin ciudad adicional** al final:

| Tratamiento | Ingresos recuperados al final | Material total recuperado al final |
|---|---:|---:|
| Bosque, ciudad extra del iniciador | 7/8 | 2/8 |
| Bosque, ciudad extra del respondedor | 6/8 | 4/8 |
| Costa, ciudad extra del iniciador | **0/8** | **0/8** |
| Costa, ciudad extra del respondedor | **2/8** | **0/8** |

De nuevo: un juego sin ingresos igualados puede seguir teniendo contrajuego táctico; el ensayo no incluye poderes de comandantes activos, diplomacia, 8 jugadores, relés de victoria, ni playtests humanos.

### Distribución de compras de la IA: cobertura pendiente, no una orden de nerf

Principales compras entre los **1.787 reclutamientos**: `scout=365`, `piercer=272`, `assault=195`, `logistics=181`, `fpv=127`, `mobile_aa=118`, `engineer=110`. El tanque principal se adquirió **70** veces. No se compraron estas **11 clases** en este ensayo: `mlrs`, `ew`, `loitering`, `bomber`, `patrol`, `missile_boat`, `corvette`, `frigate`, `destroyer`, `submarine`, `landing_ship`.

**No concluir que once unidades son inútiles o costosas:** esta telemetría refleja heurísticas de compra de BasicAI, dos mapas 10×8, una composición inicial y un horizonte de 24 medias fases. Varias especializaciones, como interferencia EW y transportes, aún tienen acciones pendientes, y la IA puede estar infrautilizando el mar. El costo aislado o DPS por crédito de una unidad no representan todo su valor.

### Decisión de diseño tras esta evidencia

1. **Mantener la economía y los costos actuales**, pero estudiar el mapa costero, donde los desbalances de ingresos y material persisten más; rastrear la secuencia de capturas y posiciones a lo largo de rondas antes de cambiar ingresos.
2. **No compensar automáticamente al segundo jugador con créditos ni fijar todavía tres órdenes globalmente**; la iniciativa requiere experimentos separados con objetivos de victoria, ventanas temporales y distintos tipos de mapas.
3. **Próximo ensayo prioritario:** probar composición y compra de `scout` frente a `assault` y `piercer`, detectar sesgo de la IA hacia unidades baratas, y escenarios especializados navales/aéreos/antiblindaje donde el objetivo justifique sus instalaciones.
4. **Fase posterior:** partida completa o estancamiento, capacidades de remontada real, costo por HP efectivo, munición, combustible, reacción y poder de combate. Los niveles de mejoras siguen **sin implementación verificada**, y los ocho bonos de facción aprobados no se alteran hasta pruebas reales de habilidad y contrajuego.
