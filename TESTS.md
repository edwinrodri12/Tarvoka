# Tests
- Added tests/test_rules.gd: boundary, terrain costs, impassable water, occupied cells.
- Godot execution: NO EJECUTADO (binary unavailable in current runtime).
- Android compilation and device test: NO EJECUTADO (SDK/device unavailable).
- Structural inspection of prior v1.1 ZIP: archive contains 23 entries.
Run with: godot --headless --path . --script res://tests/test_rules.gd

2026-11-09: Added assertions for zero budget (origin only), negative budget, missing map row, and short map row. GDScript: NO EJECUTADO (Godot unavailable in this run); no Android build or device test.
