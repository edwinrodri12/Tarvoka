# G11 launcher tube radial LOD experiment — 2026-11-20

## Validated diagnostic baseline (not Android FPS)
GitHub Actions run [44770082616](https://github.com/edwinrodri12/Tarvoka/actions/runs/44770082616), commit `79ed85a6` on the separate draft PR #622, completed successfully under Godot 4.3 with an initialized G11AndroidStressLab scene:
- 8 G11 tactical models; 46,818 triangles, 409 instances, 145 mesh nodes, 409 surfaces.
- Largest reported mesh: `G11Mobile_Lote12Tubos`, 2,160 triangles.
- Warning: diagnostic threshold 12,000 exceeded. This threshold is not a device FPS budget.

## Reversible art-only experiment
Reduce the native tactical rocket-cylinder and rim radial segments from 10 to 8 in `G11MobileLOD.gd`. Preserve 12 rocket tubes, 12 near-camera rims, original positions, materials, launch rotation, faction paint, LOD8/LOD10 semantics, collision-free geometry and all combat rules. Do not alter hero sculpture or Android package. Regression `tests/test_g11_mobile_lod.gd` asserts the new radial configuration.

## Acceptance and rollback
1. Execute Godot 4.3 `--headless --path . --script res://tests/test_g11_mobile_lod.gd` and reject any engine errors.
2. Compare the same G11AndroidStressLab 8-unit, LOD10 census on this branch against 46,818 triangles from the prior QA branch. **Not yet measured after change**. A count from PR #622 is diagnostic evidence only; PR #622 is not merged into main.
3. Compare orthographic/oblique launcher mouth images for near/far LOD and all eight faction paints; revert to 10 radial segments if the reduction visibly damages silhouettes.
4. CI Godot and Android export must pass. Physical Android: **NO EJECUTADO EN DISPOSITIVO**. Visual: **PENDIENTE DE REVISIÓN VISUAL**. No FPS or battery claim.
5. Rollback: restore both calls to radial_segments=10 and remove the constant/test assertion. This experiment does not affect saved game rules.

## Parallel-work isolation
The independent QA PR #622 remains unmerged and must not be included or cherry-picked into this art PR. Terrain PR #203 remains separately staged. No changes to gameplay, save formats, or other repositories.
