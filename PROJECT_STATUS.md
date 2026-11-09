# TARVOKA — Project status
2026-11-09: Dedicated repository accessible; visibility PUBLIC. Main branch contains a minimal Godot 4 scaffold, not the full v1.1 game.
Proposed PR: add GitHub Actions workflow to execute tests/test_rules.gd using official Godot 4.3 headless binary. CI has now been observed running successfully (details below).
The local TARVOKA_autonomous_v1_1.zip archive is accessible (23 entries), but has NOT been imported into GitHub. Its rules/state/AI must be reconciled without overwriting pending movement PRs.
No verified Android APK or device test. No edits to EKANVORA or centro-operativo-atlanta.

2026-11-09 verification: GitHub Actions run 42584227883 completed SUCCESS on PR #5 head a01a1d812b187967babb4745a8b2a7d1ee9d8afd. Both Godot 4.3 download and GDScript rules-test steps completed successfully. This verifies only the minimal scaffold's movement test, not the full v1.1 game or Android. Repository remains PUBLIC; PR #5 is draft, main unchanged.

2026-11-09: Proposed standalone deterministic combat core (scripts/core/Combat.gd) and test suite. CI execution pending; no integration into battle UI yet. No APK verified.

2026-11-09: Added pure faction turn bookkeeping in scripts/core/Turns.gd and tests/test_turns.gd on dedicated branch. Functional execution not yet confirmed; no APK.

2026-11-09: Proposed pure adjacent attack integration (BattleActions.gd) using Combat and Turns, with immutable unit state and victory result. Awaiting CI verification. No Android build.

2026-11-09: Proposed duplicate/invalid unit ID guard for BattleActions; draft PR pending Godot CI validation. No APK.
