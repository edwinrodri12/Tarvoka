# Weather cycle state regression — 2026-11-18

Scope: isolated Godot 4.3 headless test, no production or balance changes.

Run: `godot --headless --path . --script res://tests/test_weather_cycle_state_contract.gd`

Assertions: legacy fixed-weather saves are preserved; each approved starting weather transitions only after four completed faction turns and resets its countdown; invalid cycle dictionaries and invalid weather never advance; the turn number stays unchanged. The source state is checked for mutation on the first transition.

Status: test source committed; Godot 4.3 headless **NO EJECUTADO**; Android physical **NO EJECUTADO EN DISPOSITIVO**. Do not claim a passing test or merge until Godot CI runs this exact file. This branch is independent of open terrain, AI and Android PRs.
