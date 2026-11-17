# TARVOKA — IA v3.6.3: riesgo y recompensa por unidades, capturas y ofensiva

**17 de noviembre de 2026 | PR experimental | No integra main ni APK.**

## Diagnóstico real
[32 partidas v3.6.2 vs v3.5](https://github.com/edwinrodri12/Tarvoka/actions/runs/44173265163): **14–18 victorias**; **54–58 ciudades**; **34–12 retiradas**. v3.6.2 sufrió 100 bajas frente a 114 de v3.5 y conservó 88 unidades iniciales frente a 80, pero siguió perdiendo más batallas. El contrato de infantería herida falló en `test_ai_anticipation_critical_v362.gd:69`, porque las nueve primeras casillas cercanas no incluían una opción de escape segura. La ejecución de 32 partidas sí concluyó, pero un trabajo especializado marcó el workflow como fallido.

## Intervención v3.6.3

1. El pronóstico **solo con enemigos observados** sigue calculando riesgo de ataque individual letal y revalidando la única orden con `BattleSession.move`.
2. Para evitar falsos «sin salida», la búsqueda experimental evalúa hasta **16 destinos** (8 cercanos y 8 que alejan del peligro), manteniendo la búsqueda original de v3.6 **sin cambios** y un presupuesto estricto para móvil.
3. Nuevo `RiskRewardV363.gd` evalúa el valor aproximado de preservar un soldado, el **ingreso real de la ciudad** (100 créditos/turno en economía clásica, 250 moderna), capturar una instalación rival, perder avance hacia un objetivo y renunciar a presión frontal. Son **puntuaciones heurísticas** para decidir, no ingresos ni estadísticas inventados dentro del juego.
4. Una infantería relativamente reemplazable que YA está capturando una ciudad puede mantener la posición incluso ante un golpe futuro letal. Una unidad extremadamente herida o una artillería cara conserva su capacidad de rescate en una casilla legal.
5. El indicador `_ab_risk_reward_v363` está desactivado por defecto y **solo se activa en el ensayo A/B**, junto con flags experimentales anteriores. La producción y las acciones reales no cambian.
6. `tests/test_ai_risk_reward_v363.gd` verifica el coste de abandonar ciudad, un rescate críticamente herido, artillería, ausencia de ventajas ocultas y el funcionamiento del motor autoritativo. El contrato v3.6.2 heredado también debe pasar tras ampliar destinos.

## Medición exigida

Una nueva matriz **32 partidas** controla mapas 0/2, niebla, dificultad 10/12, ambos bandos e iniciativa. Emite `AB363_MATCH`, `AB363_SUMMARY`, `AB363_ALL` y un dictamen que no autoriza integrar el juego automáticamente.

**Criterios para ampliar**: no perder frente a v3.5 en victorias; no perder ciudades ni tropas iniciales; menos de 34 retiradas (v3.6.2); cero abandonos no letales y test completo en verde. Posteriormente requiere otras doctrinas, múltiples dominios, mapas grandes y Android físico.

Las partidas en CI determinan el resultado; este documento **no presenta hipótesis como resultados**.
