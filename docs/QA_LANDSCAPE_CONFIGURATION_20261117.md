# TARVOKA — Landscape configuration regression (2026-11-17)

Independent headless guard for the Android landscape configuration. Run `godot --headless --path . --script res://tests/test_landscape_configuration.gd` on Godot 4.3. Expected marker: `PASS: TARVOKA landscape project configuration` and exit 0. Assertions check 1280×720-compatible landscape baseline, orientation=0, canvas_items/expand scaling, and touch emulation for native Buttons.

**Scope:** This is a configuration-only test. It does not establish actual Android orientation lock, UI legibility, touch target sizes, FPS, or safe-area compatibility. Run on physical midrange Android and inspect 16:9 and taller/wider landscape aspect ratios before release. Also run existing IA, save/load, victory and movement suites prior to merge.

**At creation:** GitHub commit confirmed; Godot 4.3 CI **NO EJECUTADO**; Android physical **NO EJECUTADO EN DISPOSITIVO**. No production gameplay or saved-game changes. Independent of draft movement and terrain PRs.
