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
