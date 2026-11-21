# G11 live geometry census — 2026-11-20

## Reproduced defect
GitHub Actions run 44742187143, job 136308344147 (commit d1cd31a4) returned `PRODUCTION_3D_CENSUS_PASS` for `res://scenes/G11AndroidStressLab.tscn` with **0 mesh nodes, 0 instances and 0 triangles**. The static PackedScene has only a scripted Node3D; `G11AndroidPerfLab._ready()` creates the ground and eight procedural G11 units. The previous auditor inspected an unattached PackedScene, so `_ready()` never ran. The prior PASS was a false positive, not an actual production geometry measurement.

## Correction
`tests/audit_production_scene.gd` now attaches the instantiated scene to the active SceneTree, waits for a process frame, then inspects live geometry. A zero-mesh result is an explicit error, not a successful production measurement. This remains a diagnostic, **not** an Android FPS measurement. Fixture smoke test should still report 12 triangles.

## Verification
- PASÓ: source correction committed to PR #622.
- NO EJECUTADO: Godot 4.3 headless on new commit; CI pending.
- NO EJECUTADO EN DISPOSITIVO: Android performance and touch.
- PENDIENTE DE REVISIÓN VISUAL: model geometry/materials.

## Next
Check CI log for a nonzero G11 live census, record `largest_mesh_path` and `largest_mesh_triangles`, then optimize that actual component with before/after comparisons. If Godot emits an engine error, fix the live-scene setup before using any reported counts. No changes to gameplay rules or assets in this patch.
