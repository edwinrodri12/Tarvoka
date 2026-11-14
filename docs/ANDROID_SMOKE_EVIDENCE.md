# Android smoke evidence capture (P0 QA)

Problem: CI export success does not demonstrate launch, orientation, or visual state on a real phone. Collect reproducible, non-destructive evidence without reinstalling an APK or touching saved games.

Run on a trusted machine with one authorized Android device and the installed TARVOKA package:

```bash
bash tools/android_smoke_capture.sh /tmp/tarvoka-smoke
```

The script checks the package ID from `export_presets.cfg`, launches via Android's launcher intent, captures a PNG, display dimensions/density, activity state, package metadata and the last 400 logcat lines. It does not install, uninstall, clear data, change permissions or attempt to test save integrity. Exit 2 = **NO EJECUTADO EN DISPOSITIVO** (missing adb, zero/multiple authorized devices, or app absent); exit 1 = **FALLÓ** capture; exit 0 = **PASÓ** collection only. Inspect `launch.png` and `activity.txt` manually: a screenshot can show an error or wrong orientation even when capture succeeded.

Adversarial cases: multiple phones must not silently select a device; absent APK must not be treated as app crash; empty screenshot must fail. Never upload logcat/package files publicly without inspecting for private information.

**2026-11-13 QA:** Bash syntax `bash -n` PASÓ locally; actual device execution **NO EJECUTADO EN DISPOSITIVO**; CI Godot/Android **NO EJECUTADO for this PR** until Actions reports results. No FPS, save/load, touch, gameplay, battery, or visual-commercial claim. This tool is independent of pending terrain/tank/HQ draft branches and does not modify battle logic.
