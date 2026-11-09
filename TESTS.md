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
