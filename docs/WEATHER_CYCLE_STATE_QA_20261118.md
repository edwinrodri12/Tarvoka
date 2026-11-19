# Weather cycle state regression — 2026-11-18

Scope: isolated Godot 4.3 headless test, no production or balance changes.

Run: `godot --headless --path . --script res://tests/test_weather_cycle_state_contract.gd`

Assertions: legacy fixed-weather saves are preserved; each approved starting weather transitions only after four completed faction turns and resets its countdown; invalid cycle dictionaries and invalid weather never advance; the turn number stays unchanged. The source state is checked for mutation on the first transition.

Status: test source committed; Godot 4.3 headless **NO EJECUTADO**; Android physical **NO EJECUTADO EN DISPOSITIVO**. Do not claim a passing test or merge until Godot CI runs this exact file. This branch is independent of open terrain, AI and Android PRs.

## Extensión de regresión: pronóstico público

Se añadieron 12 escenarios (3 climas × contadores 1–4) para comprobar que `Weather.forecast` anuncia el clima siguiente correcto y el contador exacto, que `advance_after_turn` coincide con ese pronóstico al llegar a 1 y que ninguna operación modifica el estado de origen ni el turno. También se verifica que una partida legacy sin ciclo muestra pronóstico fijo sin siguiente clima. El CI previo del commit `770c1227` pasó en [run 44365359249](https://github.com/edwinrodri12/Tarvoka/actions/runs/44365359249), pero **no valida** esta extensión. Nuevo commit: CI pendiente; Android físico: NO EJECUTADO EN DISPOSITIVO.

## Regresión de tres ciclos completos (2026-11-18)

La suite ahora recorre 12 turnos de facción y exige tres transiciones completas CLEAR → RAIN → SNOW → CLEAR, con cuenta regresiva 4/3/2/1, conservación del número de turno e inmutabilidad del estado de entrada en cada paso. No cambia la lógica de producción. Commit `c2d3308e24f6a9192cba891f96fd77286bdef16c`. Estado: fuente registrada; ejecución del nuevo commit en CI **NO CONFIRMADA**; Android físico **NO EJECUTADO EN DISPOSITIVO**.
