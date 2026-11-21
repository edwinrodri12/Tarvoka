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
