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
