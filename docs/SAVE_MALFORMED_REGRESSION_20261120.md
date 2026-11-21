# Offline save corruption regression — 2026-11-20

Scope: independent, non-gameplay regression for `TarvokaSaveCodec` against malformed JSON. Based on current main `SaveCodec.gd` and `test_save_codec.gd`. No schema/version changes, no Android package.

Added `tests/test_save_malformed_regression.gd`: creates a valid 10x8 two-faction session, verifies exact JSON roundtrip, then rejects nine mutations (short/fractional/string coordinates, boolean HP, string attack, fractional unit faction, string turn faction, non-array units, non-array terrain). Finally confirms valid snapshot still decodes unchanged.

Run from repository root with Godot 4.3:
```
godot --headless --path . --script res://tests/test_save_malformed_regression.gd
```
Expected: exit 0 and `PASS save malformed regression: 9 corruptions rejected and baseline intact`.

Status at authoring: FILE COMMITTED; Godot binary unavailable locally, CI NOT EXECUTED, Android physical NO EJECUTADO EN DISPOSITIVO. This tests rejection only; it does not demonstrate actual persistence after process termination. Keep draft until Godot regression runs and save/load CI is green. No change to battle, balance, artwork, or other repositories.
