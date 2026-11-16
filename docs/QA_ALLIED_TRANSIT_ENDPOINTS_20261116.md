# Allied transit endpoint regression — 2026-11-16

Scope: Godot 4.3, pure `Rules.reachable` contract; no gameplay rule changes.

Positive: a unit at (0,0) can cross a friendly occupied tile at (1,0), reach (1,1) for cost 2 and (2,1) for cost 3, but cannot end on (1,0).

Adversarial: enemies at (0,1) and (2,0) block paths. If (1,0) is also in blocked, the unit is sealed at its origin despite its presence in transit_only. Inputs remain unmodified.

Command: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`

Expected marker: `PASS: allied transit and endpoint isolation`.

Status: source committed; Godot 4.3 **NO EJECUTADO** on this commit, Android physical **NO EJECUTADO EN DISPOSITIVO**. The standalone test is now wired to `.github/workflows/allied-transit-endpoints.yml` on this PR branch, with official Godot 4.3, 90-second timeout, strict unexpected-error detection, and exactly one PASS marker. **CI result remains NO EJECUTADO / pending verification**; wiring is not proof of a passing test. Before merging, inspect the new Actions run, run the full tactical regression suite, and verify no overlapping PR has equivalent coverage.

## Extended corridor coverage (2026-11-16)

Two consecutive allied tiles at (1,0) and (2,0) form the only route from (0,0) to (3,0), while enemy-occupied cells block detours. Assert that (3,0) is reachable at cost 3 with movement budget 3, neither allied tile is a legal endpoint, and budget 2 cannot reach (3,0). Also assert input allied positions remain unchanged. This specifically guards against incorrectly filtering allied transit tiles *before* route expansion and against free transit through allies.

Commit: `2dac21e9583cfd60bc553040e36b2f7467430fd0`. Godot 4.3 **NO EJECUTADO** for this extension; Android **NO EJECUTADO EN DISPOSITIVO**. CI and broader AI/save/victory regressions must be checked before merge. No changes to production movement logic.

## Extensión: ruta ortogonal sin atajos (2026-11-16)
Se añadió una prueba con un aliado al este y un enemigo al sur del origen. Con presupuesto 1, la casilla diagonal sureste no es alcanzable; con presupuesto 2 se alcanza exactamente con coste 2 atravesando al aliado, pero su casilla no puede seleccionarse como destino. También se comprueba la inmutabilidad de las listas de ocupación. Commit de código: `be78f8bf`.

Evidencia anterior: workflow *Allied transit endpoint regression*, run [43945909381](https://github.com/edwinrodri12/Tarvoka/actions/runs/43945909381), SUCCESS sobre `d2b6a63a` (no cubre la extensión). La nueva regresión queda **NO EJECUTADA** hasta confirmar un run del commit nuevo. Android físico: **NO EJECUTADO EN DISPOSITIVO**. No fusionar sin comprobar CI y regresiones completas.

## Motorized road transit regression (2026-11-16)

On a 10×8 plain map, road tiles (1,0) and (2,0) form a two-tile corridor, with an ally on (1,0) and an enemy at (0,1). A motorized ground unit starting (0,0) with movement budget 1 must reach (2,0) at displayed cost 1 (two half-point road entries), but cannot finish on the allied (1,0). A non-motorized ground unit with the same budget cannot reach (2,0). The test also asserts terrain and occupancy inputs remain unchanged. This verifies an existing road-mobility rule without altering production movement or balance.

Code commit: `cfe23b6a831523eb97338705a1afcdac5ad4f2fd`. Godot 4.3 CI for this commit: **NO EJECUTADO / pending verification**; Android: **NO EJECUTADO EN DISPOSITIVO**. Run `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`, then full movement/AI/save/victory suites before integration. No merge authorized by this documentation.
