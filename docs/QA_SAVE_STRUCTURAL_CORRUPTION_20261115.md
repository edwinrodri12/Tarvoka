# Structural save corruption — QA contract (2026-11-15)

Scope: isolated Godot 4.3 headless regression against SaveCodec v1; no gameplay, faction, economy or visual changes.

Run: `godot --headless --path . --script res://tests/test_save_structural_corruption.gd`

Expected: 18 malformed JSON snapshots (missing top-level keys, wrong collection types, null unit/terrain row, malformed positions, truncated/oversized terrain, unknown terrain tile, duplicate unit ID, non-object JSON roots `[]` and `null`) are rejected without crashing or changing the original in-memory state. A valid snapshot must still round-trip.

CI: `.github/workflows/save-structural-corruption.yml` runs this test on PR changes and on manual dispatch. **Test file committed does not imply PASÓ**; inspect workflow result at the exact head SHA. If a null terrain row triggers an engine exception instead of an empty result, fix Rules.valid_terrain separately before merging.

Regression boundaries: general IA, victory, Android export and real device are NOT EXECUTED by this focused workflow. Keep draft until CI is green. No APK is generated.

Next autonomous task: inspect Godot logs, fix any failing malformed case without weakening the validator, then run existing SaveCodec, IA and victory suites.

2026-11-15 follow-up: original 14-case workflow PASÓ at https://github.com/edwinrodri12/Tarvoka/actions/runs/43761878352; Android export PASÓ at run 43761878353; general rules CI FALLÓ at run 43761878270. The two additional cases (oversized terrain and unknown tile) are NOT YET VERIFIED at their new head SHA. No Android physical test.

2026-11-15 additional root-shape regression: added `[]` and `null` as syntactically valid but semantically invalid top-level JSON payloads. The previous 16-case workflow passed at https://github.com/edwinrodri12/Tarvoka/actions/runs/43767139157; Android export passed at run 43767139151; general Godot rules CI failed at run 43767139173. The expanded 18-case SHA requires its own CI result. Physical Android NOT EXECUTED.

2026-11-15: Expanded root-type rejection from `[]`/`null` to boolean `true`, number `42`, and JSON string `"orphan"` (21 cases total). Prior 18-case head 2a913d2 passed dedicated Godot 4.3 CI run 43772725923 and Android export run 43772725914; general rules run 43772725926 failed independently. New 21-case head remains UNVERIFIED until its own CI completes. Physical Android NOT EXECUTED.
