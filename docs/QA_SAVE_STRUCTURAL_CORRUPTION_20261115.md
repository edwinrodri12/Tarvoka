# Structural save corruption — QA contract (2026-11-15)

Scope: isolated Godot 4.3 headless regression against SaveCodec v1; no gameplay, faction, economy or visual changes.

Run: `godot --headless --path . --script res://tests/test_save_structural_corruption.gd`

Expected: 14 malformed JSON snapshots (missing top-level keys, wrong collection types, null unit/terrain row, malformed positions, truncated terrain, duplicate unit ID) are rejected without crashing or changing the original in-memory state. A valid snapshot must still round-trip.

CI: `.github/workflows/save-structural-corruption.yml` runs this test on PR changes and on manual dispatch. **Test file committed does not imply PASÓ**; inspect workflow result at the exact head SHA. If a null terrain row triggers an engine exception instead of an empty result, fix Rules.valid_terrain separately before merging.

Regression boundaries: general IA, victory, Android export and real device are NOT EXECUTED by this focused workflow. Keep draft until CI is green. No APK is generated.

Next autonomous task: inspect Godot logs, fix any failing malformed case without weakening the validator, then run existing SaveCodec, IA and victory suites.
