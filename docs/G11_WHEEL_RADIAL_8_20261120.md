# G11 tactical roadwheel radial optimization — 2026-11-20

## Scope
Only the near-LOD twelve-wheel MultiMesh in `scripts/ui/G11MobileLOD.gd` changes: `CylinderMesh.radial_segments` from 10 to 8. Wheel radius 0.16, width 0.075, positions, materials, eight faction palettes, far-LOD culling, launchers and tactical rules are unchanged. Reversible by restoring 10.

## Geometry expectation (not a measured benchmark)
An isolated cylinder has fewer radial side faces at 8 than at 10 segments; the theoretical side-face reduction is 20% for this wheel primitive. The effect on full G11 triangle count, draw calls, FPS, battery and image quality is **unmeasured**. The earlier 46,818 triangle scene baseline belongs to a different branch and cannot be treated as a direct before/after comparison.

## Reproducible QA
Run from repository root with Godot 4.3 after importing the project:
```sh
godot --headless --path . --script res://tests/test_g11_wheel_radial_8.gd
```
Expected: 8 factions × 2 LODs; near LOD retains 12 wheels at 8 radial segments, far LOD omits batch; dimensions preserved. Run existing `tests/test_g11_mobile_lod.gd` and general Godot CI. Compare matched native renders from identical camera angles and lighting before merging. Android physical test: NOT EXECUTED. Visual review: PENDING.

## Isolation
Independent of open draft #641 (rocket tubes), #622 (census) and #203 (terrain). Do not merge without Godot CI and visual QA. No APK generated, no changes to balance, AI, saves or combat.
