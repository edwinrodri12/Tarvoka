# TARVOKA — Reparación de campaña y escaramuza moderna (Ingeniero, fase 1)

**Estado:** prototipo de jugabilidad real, separado de los cambios numéricos especulativos de la auditoría PR #308. No modifica precio, fuerza, defensa, alcance, experiencia ni veterania del arsenal existente. Requiere CI completa y validación táctil en Android físico antes de integrar.

## Propósito de balance

El Ingeniero cuesta **250 créditos**, igual que el Asaltante, aunque tiene menor movilidad (2 vs 3), HP (7 vs 9) y ataque (2 vs 5). Antes no disponía de su mecánica diferenciadora. Esta PR le permite **convertir créditos y una acción en conservación de unidades blindadas**, sin ser superior al Asaltante para capturar bajo fuego ni ganar combates directos.

## Regla implementada

| Parámetro | Valor y restricción |
|---|---|
| Quién | Unidad de rol `engineer` viva, propia y con acción disponible. |
| En qué modo | Escaramuza con economía **moderna**; clásica y guardados anteriores conservan sus reglas. |
| Objetivos | Un blindado/vehículo terrestre aliado adyacente (distancia Manhattan = 1), de entre `bulwark`, `apc`, `ifv`, `tank`, `spg`, `mlrs`, `mobile_aa`, `sam`, `ew`, `logistics`. |
| Exclusiones | Nunca al Ingeniero, infantería, aeronaves, barcos, enemigo, objetivos lejanos, muertos o ya curados. No repara estructuras. |
| HP | **Hasta 3 HP** en una sola acción; sin sobrepasar el máximo nominal del rol. |
| Precio | **35 créditos por HP**, exactamente los HP restaurados: 1=35, 2=70, 3=105. No hay cargo mínimo extra ni subsidio oculto. |
| Fondos insuficientes | Con 70 créditos puede recuperar 2 HP; con 35 recupera 1; con menos de 35 no puede realizar la acción. Nunca hay deuda. |
| Acción y turnos | Termina la acción del Ingeniero, impide mover o reparar otra vez, cuenta como orden de apertura. No consume la del vehículo reparado. |
| Mundo y guardado | La orden altera solo HP del aliado, créditos del dueño y bandera `acted/moved` ya existentes; **sin campos nuevos en el save**. |
| Interfaz | Botones de reparación en panel extendido y HUD horizontal móvil; selector de objetivos con HP recuperables, saldo gastado y HP final; no existe reparación por pulsar solo el botón. |
| IA | Evalúa reparación de 2–3 HP únicamente cuando el valor estimado del chasis preservado supera el gasto por al menos 25 créditos, después de ataques y reabastecimientos urgentes; mismo coste y validación que jugador. |

### Comparación económica reproducible

Precio nominal por HP nuevo, sin considerar inmovilización, una fábrica disponible o peligros de la posición:

- **Tanque G09:** 750/14 ≈ 53.6 créditos por HP de un vehículo nuevo. Reparar 3 HP cuesta 105 (equivalente proporcional ~161). Un Ingeniero de 250 tiene valor si puede sostener blindados caros durante varios turnos, pero ocupa una posición y gasta acciones que podrían dedicarse a capturas.
- **Artillería autopropulsada G10:** 650/8 ≈ 81.25 por HP; reparar 3 HP a 105 es materialmente más barato que reemplazar el segmento perdido, a cambio de exponer Ingeniero y artillería a fuego enemigo.
- **Baluarte:** 350/12 ≈ 29.2 por HP; reparar 3 HP cuesta 105, más que los ~87.5 de su valor proporcional de compra. La IA **no** reparará rutinariamente un Baluarte para evitar derroche; el jugador puede decidir que mantener la posición es más valioso.
- **Asaltante 250:** sigue siendo mejor en combate, movilidad y asalto urbano; no puede reparar. El Ingeniero no obtiene su ventaja gratis y carece de fuego poderoso.

Estos cálculos son comparaciones parciales, no certificación de balance: deben probarse partidas completas con distintos mapas, rutas, daño, suministro, ingresos y concentración de artillería. La reparación repetida no debe generar ejércitos inmortales, y 35 créditos por HP será revisable si aparece un abuso.

## Invariantes y QA

- El catálogo de 32 unidades sigue conservando sus atributos y costos. Los límites `MAX_UNITS=256`, `MAX_SITES=16` y 2 jugadores tácticos siguen vigentes.
- Se usa `EngineerRepair.quote` tanto para UI como para IA; `BattleSession.repair` revalida y aplica. No se puede gastar dinero por una selección/cancelación.
- `tests/test_engineer_repair.gd`: recuperación parcial, topes, distancia, bandos, HP cero, saldo, turnos, serialización y preferencias económicas de IA, niebla.
- `tests/test_engineer_repair_ui.gd`: menú real con varios objetivos, controles móvil/desktop, precio visible, cancelar no cambia la partida, ejecutar una sola vez, bloqueo en turno rival.
- CI aislada: `.github/workflows/engineer-repair.yml`, junto con regresiones de Godot existentes, CI Android ARM64 y pruebas de usuario futuras.
- **No probado todavía:** FPS, accesibilidad táctil en distintos Android, impacto en el equilibrio de jugadores expertos, sinergia con todas las mejoras II/III, simulación de 8 jugadores. Mantener PR como borrador hasta su validación.

## Siguientes experimentos (sin tocar valores de producción)

1. Torneo IA A/B con Ingeniero habilitado vs precio alternativo 200/225/250; alternar lado inicial y medir frecuencia de reparaciones efectivas por 250 gastados en Ingeniero.
2. Ajustar el diferencial vs Asaltante solo si resulta demasiado potente/débil, sin regalar alcance, ataque ni curación.
3. Rompedor: contrastar bonus antitanque +1/+2 en bosques, ciudades, montañas y defensa con contraataque en un experimento independiente.
4. Economías con 1/2/3 ciudades: recuperar un vehículo en lugar de fabricar otro debe ser una decisión competitiva, pero no una respuesta dominante.
5. Diseño de mejoras del Ingeniero de nivel II/III: ampliar a 4 HP requeriría costo de adquisición y contrapartida (por ejemplo más créditos por HP), nunca poder gratis ni curar todas las unidades.

**No confundir:** el desbloqueo T1 de campaña es la introducción del rol, no una mejora estadística. Los niveles tecnológicos II/III de las 24 familias todavía no están implementados.
