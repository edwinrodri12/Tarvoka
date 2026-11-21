# Android landscape configuration regression (2026-11-21)

Scope: independent headless contract test for existing `project.godot` settings. This does not alter gameplay, assets, UI or Android export.

Run after importing the project with Godot 4.3:

```sh
godot --headless --path . --script res://tests/test_android_landscape_contract.gd
```

Expected: exit code 0 and `PASS ANDROID LANDSCAPE CONTRACT`. A wrong orientation, non-landscape logical viewport, changed stretch mode/aspect, mobile renderer or disabled ETC2/ASTC import exits nonzero. Do not mistake this configuration test for a physical-device UX test.

QA: Godot execution **NO EJECUTADO** at authoring; Android device **NO EJECUTADO EN DISPOSITIVO**; touch legibility and real layout **PENDIENTE DE REVISIÓN VISUAL**.

Next: integrate into an existing CI workflow after verifying the test in Godot 4.3, then perform landscape/rotation and UI clipping checks on mid-range Android. No APK distributed.
