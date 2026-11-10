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

2026-11-09 18:02 EST: Verified PR #18 commit 5e60d2e GitHub Actions run 42709626139 SUCCESS: all seven Godot 4.3 headless suites, including touch board, passed (job 129475405608). This validates the stacked branch at that SHA, not main or Android. Added separate defensive initial-faction fallback in BattleSession and a regression test in subsequent commits; those newer commits await CI. main unchanged; no verified APK/device.

2026-11-09 19:xx EST: Proposed pure deterministic BasicAI.step(state) on isolated branch. Prioritizes adjacent legal attacks, otherwise chooses a legal move minimizing Manhattan distance to an enemy; returns immutable state and no-op when exhausted. Tests and CI step added. NOT verified in Godot yet; not connected to UI. Latest predecessor commit 42add271 GitHub Actions run 42717331241 SUCCESS (all existing suites), but does not validate new AI. No APK.

2026-11-09 20:xx EST: Draft AI opponent integration in TouchBoard.finish_turn: faction 1 executes at most unit-count deterministic BasicAI steps then returns to human faction 0, unless victory occurs. UI remains lightweight/offline. CI pending on new branch; Android APK/device NOT verified.

2026-11-09 21:xx EST: PR #20 CI run 42733717633 cancelled during touch board suite after preceding suites passed; new AI movement performance optimization proposed in dedicated stacked branch. Godot validation pending; no APK.

2026-11-09 21:xx EST: Added versioned JSON battle state codec in isolated stacked branch; handles Vector2i positions, validation and round-trip. No disk I/O or Android APK yet. New CI pending.

2026-11-09: Proposed SaveStore.gd for bounded offline user:// JSON file persistence with temp write and rollback; draft branch, no verified Godot execution or Android APK. PR #22 CI was cancelled; this change is unverified until CI succeeds.

2026-11-09 23:xx EST: Added save/load buttons and TouchBoard methods on stacked draft branch; keeps state unchanged on failed load, clears selection after successful load. Godot CI and Android unverified; PR #23 run 42746918719 CANCELLED.

2026-11-10: Diagnosed PR #24 run 42753784281: Godot 4.3 parse error at TouchBoard.gd:123 (`var max_actions := state.get(...).size()` cannot infer type). The test script then fails to instantiate the board and hangs until 10-minute cancellation. Explicitly typed AI action bound in dedicated stacked branch; awaiting CI on fix. Six earlier suites passed in that run; Android APK/device unverified.

2026-11-10: Added 90-second per-suite timeout to Godot CI on dedicated branch, so parse failures cannot silently stall an entire job. Execution pending; APK/device unverified.

2026-11-10: Input ownership guard proposed on stacked branch: TouchBoard ignores human taps while AI faction 1 is active. Not Godot-verified; APK/device not tested.

2026-11-10: Expanded headless input-ownership regression to test both human and computer unit taps during an AI turn, plus faction 1 selection in local two-player mode. GitHub commit written; Godot/Android execution pending.

2026-11-10: PR #28 head 6d2ea08d CI run 42780308893 SUCCESS (Godot 4 headless). New stacked branch resumes computer turn automatically when loading a save; regression added, awaiting CI. Android APK/device unverified.

2026-11-10: Added winner feedback when loading completed battles; Godot CI and Android verification pending.

2026-11-10: PR #30 head 0e824fb8 GitHub Actions run 42796752187 SUCCESS. Added follow-up regression for loading faction-2 victory and ensuring terminal battles reject input; awaiting CI. Android APK/device still unverified.

2026-11-10: Added defensive AI-turn entry guard on a stacked branch; CI pending. PR #31 head c7880700 passed Godot workflow run 42804643073. Android APK unverified.

2026-11-10: Proposed touchscreen drag rejection: process ScreenTouch on release only and ignore releases farther than 18 logical pixels from press; desktop mouse path unchanged. New headless regression added. Godot CI and physical Android NOT VERIFIED. Stacked on PR #32; main unchanged.

2026-11-10: Added primary-finger ownership for touchscreen gestures: a second finger cannot replace the press origin or complete a different finger's tap. Draft branch only; Godot CI and Android device unverified. No APK claimed.

2026-11-10: PR #35 proposes permanent cancellation when the primary finger drags beyond 18px then returns. CI/device not verified; no APK.

2026-11-10: Added touch-board boundary regression for taps at the exclusive right edge and outside the left edge. CI pending; Android device and APK not verified.
