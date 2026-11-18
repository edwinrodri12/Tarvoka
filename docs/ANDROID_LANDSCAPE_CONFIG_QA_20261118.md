# Android landscape configuration contract — 2026-11-18

## Scope
A standalone Python standard-library regression checks that `project.godot` keeps Android fixed landscape (orientation 0), a wide positive viewport, `canvas_items` stretching with `expand`, and the GLES compatibility mobile renderer. The suite contains negative fixtures for portrait, narrow viewport and missing renderer. No gameplay, graphics, APK signing or faction balance is changed.

## Reproduce
`python3 -m unittest discover -s tests -p 'test_android_landscape_config.py' -v`

CI: `.github/workflows/android-landscape-config.yml` runs on changes to project settings, test or workflow. This is a static contract, **not** proof that Android's real orientation, touch targets, safe areas or FPS are correct.

## Status
- Files and commits: registered on draft branch, not merged.
- Local Python suite: NO EJECUTADO at creation.
- GitHub Actions: NO CONFIRMADO for latest commit.
- Physical Android: NO EJECUTADO EN DISPOSITIVO.
- Visual QA: PENDIENTE DE REVISIÓN VISUAL.
- Independent from terrain #203, APK auditor #518, map tests #585/#586 and AI experiments.

## Next
Run CI and fix any failing assertion. Once green, inspect horizontal HUD at 16:9 and taller/wider Android aspect ratios on real hardware without claiming physical verification from static settings.
