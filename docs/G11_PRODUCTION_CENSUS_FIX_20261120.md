# G11 production census — 2026-11-20

## Reproduced CI failure

GitHub Actions run 44760894041, job 136372800030, failed in the production-scene step. Godot reported repeated `Invalid cast: could not convert value to 'PackedInt32Array'` in `MeshBudgetAudit.gd:56` for procedural surfaces without an index buffer. The smoke fixture passed but did not exercise this case.

The failing log also printed a **provisional and unreliable** census for `res://scenes/G11AndroidStressLab.tscn`: 145 mesh nodes, 409 instances, 409 surfaces, 12,674 triangles, and largest node `G11Mobile_Lote12Ruedas` at 1,440 triangles. Because runtime errors occurred, these are **not an accepted baseline**.

## Fix

Read surface arrays as Variant; use nonempty PackedInt32Array indices when available and PackedVector3Array vertex count for non-indexed surfaces. Do not cast null. No change to models, game rules, render budgets, or Android package.

## Acceptance

1. Re-run `tests/test_mesh_budget_audit.gd` and `tests/audit_production_scene.gd -- res://scenes/G11AndroidStressLab.tscn` with Godot 4.3; reject any `SCRIPT ERROR` or `ERROR`.
2. Confirm exactly one JSON report with nonzero mesh_nodes and triangles, and inspect `largest_mesh_path`.
3. Compare a valid baseline with a future geometric change on the same scene and commit before claiming optimization.
4. Android physical device: **NO EJECUTADO EN DISPOSITIVO**. Visual approval: **PENDIENTE DE REVISIÓN VISUAL**.

Do not merge PR #622 until CI passes. The previous report is diagnostic only.
