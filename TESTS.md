# Tests
- Existing tests/test_rules.gd: movement terrain, occupied cells, boundaries. Assertions not yet executed in this run.
- New .github/workflows/godot-rules.yml downloads official Godot 4.3 stable and invokes headless tests on PR/push/manual dispatch.
- Local Godot binary: NO DISPONIBLE (checked 2026-11-09).
- Android compilation/device: NO EJECUTADO; SDK/device not available.
- Manual: godot --headless --path . --script res://tests/test_rules.gd

- PASÓ (GitHub Actions, 2026-11-09): run 42584227883, job 129050054138, Godot 4.3 binary download and `tests/test_rules.gd` headless step both concluded SUCCESS on PR #5 head a01a1d8.
- NO EJECUTADO: full v1.1 game tests, Android APK build, physical-device testing.
- Local Godot binary remains unavailable; CI success is remote and limited to existing scaffold tests.

- Combat test: tests/test_combat.gd covers damage, terrain cover, defeat, survival, and invalid attacker. Status: NO EJECUTADO until GitHub Actions reports result on combat PR.

- Turn tests: tests/test_turns.gd checks faction reset, action ownership, duplicate action, dead units, immutability and winner. NO EJECUTADO pending CI evidence.

- GitHub Actions run 42606343996: SUCCESS for PR #7 head 29865b0 (turn and prior suites); scoped to that commit.
- Battle action integration test: tests/test_battle_actions.gd — NO EJECUTADO pending new CI run.

- New duplicate-ID and missing-ID battle regressions: NO EJECUTADO; await GitHub Actions on new branch.
- Off-board attack regressions (left/right/top/bottom): NO EJECUTADO pending Godot CI on proposed branch.

2026-11-09: Prior PR #10 head 4a2d0de GitHub Actions run 42632584537 PASÓ (success). New tests/test_move_actions.gd added to workflow; NO EJECUTADO/awaiting CI on new branch. Android APK/device NO EJECUTADO.

2026-11-09: Added 4 terrain-integrity assertions (unknown tile, non-string tile, short row, impassable origin) to tests/test_rules.gd. PASÓ: GitHub file writes. NO EJECUTADO: Godot 4 test on new branch, Android build/device. Existing prior-run CI success does not validate this commit.

2026-11-09 BattleSession: tests/test_battle_session.gd added (move, faction switching, consumed action, attack, victory, input immutability). NOT EXECUTED locally: Godot binary unavailable. CI pending; Android/device NOT EXECUTED.

2026-11-09: Added tests/test_touch_board.gd for tap selection, legal movement, action consumption and turn ownership. CI workflow updated. Status: NO EJECUTADO / pending CI; Godot binary not available in current connector environment. APK/device: NO EJECUTADO.

2026-11-09: PR #14 head abd1dd0 workflow run 42671606319: FALLÓ (GitHub Actions conclusion=failure; job listing returned no jobs, so cause unknown). New touch-selection guard regression added: tapped spent unit stays unselected; tapping same friendly unit twice deselects. NO EJECUTADO locally (Godot binary unavailable); awaiting CI. Android APK/device NO EJECUTADO.

2026-11-09: Added ProjectSettings regression assertion to tests/test_touch_board.gd for input_devices/pointing/emulate_mouse_from_touch=false. PASÓ: GitHub file write. NO EJECUTADO: Godot CI and Android device; PR #15 workflow 42679543043 was cancelled.

2026-11-09: Added decisive-attack victory feedback regression to tests/test_touch_board.gd. NO EJECUTADO (Godot CI pending); Android APK/device NO EJECUTADO. Earlier PR #16 run 42689788182 CANCELLED, not passed.

2026-11-09 PR #17 run 42699713939: FALLÓ (GDScript runtime error at tests/test_rules.gd:23: untyped [] does not match Array[Vector2i]); run ended CANCELLED after 10-minute job timeout. Fixed four invalid-terrain assertions to use `var no_blocked: Array[Vector2i] = []` in isolated branch. New Godot CI: NO EJECUTADO/awaiting result. APK/device: NO EJECUTADO.

2026-11-09 18:02 EST: PASÓ — GitHub Actions run 42709626139 on PR #18 commit 5e60d2e; job 129475405608 completed SUCCESS. All seven steps passed: rules, combat, turns, battle actions, movement actions, battle session, touch board. Subsequent initial-faction fallback test is NOT YET VERIFIED by this run. Android APK/device: NO EJECUTADO.

2026-11-09: Existing predecessor PR #18 commit 42add271 run 42717331241 PASÓ (SUCCESS); scope: pre-AI suites only. New tests/test_basic_ai.gd covers attack priority, victory, deterministic movement, action exhaustion, immutability, invalid state. New CI step added; NO EJECUTADO pending GitHub Actions on new PR. Android APK/device: NO EJECUTADO.

2026-11-09 AI UI integration: added test_touch_board regression for automatic AI movement and return to human faction. Status: NO EJECUTADO until CI on new PR. Predecessor PR #19 run 42726224295: SUCCESS (Godot 4.3 headless, reported by GitHub Actions), scoped to predecessor commit bcec1a31. Android APK/device: NO EJECUTADO.

2026-11-09: PR #20 GitHub Actions run 42733717633 CANCELLED; rules/combat/turns/battle actions/movement/battle session PASÓ, touch board CANCELADO, AI tests SKIPPED. New water-wall AI regression and pathfinding optimization: NO EJECUTADO pending CI. Android: NO EJECUTADO.

2026-11-09: Added tests/test_save_codec.gd for JSON round-trip, independent state, invalid payload/version/coordinates/duplicate IDs. NO EJECUTADO pending GitHub Actions. No Android build/device verification.

2026-11-09 SaveStore: regression script tests file roundtrip, invalid state/path, corrupt and missing files. Status NO EJECUTADO at commit creation; PR #22 prior run 42741291627 CANCELLED. Android device test NO EJECUTADO.

2026-11-09: Added board save/load regression (round-trip, cleared selection, missing file preserves live state). NO EJECUTADO: new Godot CI. PR #23 head a7557e8 run 42746918719 CANCELLED, not a pass. Android APK/device NO EJECUTADO.

2026-11-10: PR #24 run 42753784281 CANCELLED after 10-minute timeout. Logs show six suites PASÓ; touch-board FAILED TO COMPILE due to TouchBoard.gd:123 `max_actions` type inference error; remaining AI and save tests SKIPPED. Dedicated fix uses explicit int type; validation NO EJECUTADO until new CI. Android APK/device NO EJECUTADO.

2026-11-10: CI test-suite timeout guard added (90s + 5s kill grace); PASÓ: workflow file updated in GitHub. NO EJECUTADO: GitHub Actions execution for this change, Godot locally, Android APK/device. Timeout is a diagnostic safeguard, not proof that gameplay passes.

2026-11-10: Added regression in tests/test_touch_board.gd for ignored human taps while AI faction 1 owns the turn. PASÓ: GitHub code/test writes. NO EJECUTADO: Godot CI on this commit, APK build, physical Android device.

2026-11-10: Extended touch board assertions for AI-turn taps on both factions and manual faction 1 selection. PASÓ: test source committed; NO EJECUTADO: Godot runtime, CI, Android APK/device.

2026-11-10: PR #28 SHA 6d2ea08d: GitHub Actions 42780308893 PASÓ. New saved-AI-turn resume test: NO EJECUTADO until new branch CI. Android APK/device: NO EJECUTADO.

2026-11-10: Added terminal-save load UI regression. NOT EXECUTED in Godot or Android as of commit creation.

2026-11-10: PASÓ GitHub Actions run 42796752187 for PR #30 commit 0e824fb8 (Godot 4 headless). Added faction-2 victory-load and terminal-action regression on successor branch: NO EJECUTADO pending CI. Android APK/device: NO EJECUTADO.

2026-11-10: PR #31 commit c7880700: PASÓ workflow 42804643073. AI entry guard regression added: NO EJECUTADO until CI. Android APK/device: NO EJECUTADO.

2026-11-10: Added touch-event regression: press alone does not select, release selects, drag release cannot move, second tap deselects. PASÓ: GitHub writes. NO EJECUTADO: Godot 4 runtime/CI for new branch; Android APK/device not available.

2026-11-10: Added multi-touch regression to tests/test_touch_board.gd: secondary finger press/release does not complete primary tap; primary release selects and subsequent tap deselects. PASÓ source commit; NO EJECUTADO Godot runtime and Android/device.

2026-11-10 PR #35: Added synthetic drag-out-and-return regression to tests/test_touch_board.gd. NO EJECUTADO in Godot CI or Android device at commit time; APK NO EJECUTADO.

2026-11-10: Added two synthetic off-board touch regressions (x=800 exclusive right edge and x=-1 left exterior on 800x640 board). PASÓ: source write if committed; Godot CI NO EJECUTADO pending new branch workflow; APK/device NO EJECUTADO.
