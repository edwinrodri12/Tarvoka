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

2026-11-09: Proposed board-boundary validation for adjacent attacks on 10x8 map. Four regression cases added; awaiting CI evidence. No APK.

2026-11-09: Added MoveActions.gd pure movement integration (terrain cost, occupancy, faction/turn guards, immutable state), tests/test_move_actions.gd and CI step. New test execution pending; no APK verified.

2026-11-09: On stacked terrain-grid-integrity branch, Rules.reachable now rejects malformed terrain values anywhere on the 10x8 board and impassable origins. Added four regression assertions. Godot execution NOT VERIFIED; no APK.

2026-11-09: Proposed BattleSession.gd two-faction coordinator on stacked branch automation/battle-session-20261109. Connects move, attack, end turn, victory with immutable state; GDScript tests added but not yet verified. No Android build.

2026-11-09: Proposed first interactive 10x8 touch board (scripts/ui/TouchBoard.gd) connected to BattleSession via scripts/ui/Main.gd. Includes tap selection, movement, attack, end-turn, faction colors and win indicator. Draft branch only; CI/Android NOT VERIFIED. Two-player local prototype, not AI.

2026-11-09: Draft touch selection guard: tapping the selected friendly unit deselects it; already-acted friendly units cannot be selected. Branch-only, headless CI not yet verified. Previous PR #14 workflow run 42671606319 concluded FAILURE; root cause not established because job list returned empty. No APK/device verification.

2026-11-09: Proposed Android touch event deduplication via project.godot input_devices/pointing/emulate_mouse_from_touch=false. Godot touch events remain supported, desktop mouse events remain supported; prevents synthetic mouse press from deselecting a unit immediately after touch selection. Awaiting CI; not device-verified. PR #15 run 42679543043 cancelled, not a test pass.

2026-11-09: Draft stacked UI change: show immediate winner message when the last enemy falls; pending Godot CI. No APK verified.

2026-11-09 CI diagnosis: PR #17 run 42699713939 log confirms Godot 4.3 SCRIPT ERROR in tests/test_rules.gd:23: untyped [] supplied to Rules.reachable fourth parameter Array[Vector2i]. Created isolated follow-up branch fixing test arguments. Await CI validation; main untouched; APK not built.
