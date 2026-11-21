# Android landscape configuration regression (2026-11-21)

Scope: independent Godot 4.3 headless contract for existing `project.godot` settings. No gameplay, art, Android export or user-facing layout changes.

Run after importing the project:

```sh
godot --headless --path . --audio-driver Dummy --script res://tests/test_android_landscape_contract.gd
```

Expected: exit code 0 and `PASS ANDROID LANDSCAPE CONTRACT`. The test validates six project settings (fixed landscape orientation, landscape logical viewport, expand aspect, canvas_items stretch, mobile GL compatibility and ETC2/ASTC compression). Six additional pure controls ensure that portrait/sensor orientation, portrait/square/zero-sized viewports are rejected and a different landscape resolution is accepted. No ProjectSettings values are modified by the controls.

## Evidence and limitations

- Previous head `ac29cbbf14f76e588fe6315f9f08517344198d7c`: landscape workflow **PASÓ** on [GitHub Actions run 44864143520](https://github.com/edwinrodri12/Tarvoka/actions/runs/44864143520); generic Godot rules and Android debug export also reported success for that commit.
- New negative controls in commit `adce0c6b79f827906d9e07b507896cfb132888b8`: **NO EJECUTADO** until its own CI result is inspected. The prior run does not validate this commit.
- Android physical: **NO EJECUTADO EN DISPOSITIVO**.
- HUD clipping, touch targets, safe areas and legibility: **PENDIENTE DE REVISIÓN VISUAL**.
- This does not measure FPS, battery, touch ergonomics, or prove an APK installs or upgrades safely.

CI: `.github/workflows/android-landscape-contract.yml` imports Godot 4.3, executes the regression, requires the PASS marker and publishes a diagnostic log. Review its next run and fix reproducible failures before merging. No APK distributed.

## 2026-11-21 — aspect ratio geometry regression

Added 13 pure checks in `tests/test_android_landscape_contract.gd`: for 16:9, 20:9, 4:3 and 21:9 physical landscape dimensions, compute the expected expanded logical canvas and assert that neither base logical dimension shrinks and that the resulting aspect matches the screen. A zero-width physical screen must return an invalid zero canvas. This tests the **mathematical contract only**, not actual Godot Control anchors, cutouts, safe areas, UI clipping or Android touch behavior.

Commit `9a04080dabb272117b83f7bd8ff0328f45ab9f0b`: **NO EJECUTADO** in Godot/CI at authoring time. Android physical: **NO EJECUTADO EN DISPOSITIVO**; visual HUD: **PENDIENTE DE REVISIÓN VISUAL**. Inspect the CI run for the new head SHA before declaring success. No gameplay rules changed.
