# Android landscape configuration regression (2026-11-21)

Scope: independent headless contract test for existing `project.godot` settings. This does not alter gameplay, assets, UI or Android export.

Run after importing the project with Godot 4.3:

```sh
godot --headless --path . --script res://tests/test_android_landscape_contract.gd
```

Expected: exit code 0 and `PASS ANDROID LANDSCAPE CONTRACT`. A wrong orientation, non-landscape logical viewport, changed stretch mode/aspect, mobile renderer or disabled ETC2/ASTC import exits nonzero. Do not mistake this configuration test for a physical-device UX test.

QA: Godot execution **NO EJECUTADO** at authoring; Android device **NO EJECUTADO EN DISPOSITIVO**; touch legibility and real layout **PENDIENTE DE REVISIÓN VISUAL**.

Next: integrate into an existing CI workflow after verifying the test in Godot 4.3, then perform landscape/rotation and UI clipping checks on mid-range Android. No APK distributed.

## CI automatizado (2026-11-21)

`.github/workflows/android-landscape-contract.yml` ejecuta el test con Godot 4.3 estable en pull requests que alteren la configuración, la prueba o el workflow; también admite `workflow_dispatch`. Importa el proyecto, ejecuta la regresión con timeout, exige código de salida correcto y marcador PASS, y publica el log como artefacto. **Al escribir este documento la ejecución del workflow nuevo NO ESTÁ CONFIRMADA**. Esta prueba solo verifica configuración: orientación real, controles táctiles, recortes de HUD y rendimiento siguen **NO EJECUTADO EN DISPOSITIVO / PENDIENTE DE REVISIÓN VISUAL**.
