# Backlog
- [ ] Review and reconcile open movement PRs without overlapping changes.
- [ ] Import/reconcile the local v1.1 source archive (23 entries), preferably after repository is made private.
- [ ] Validate full battle loop: selection, movement, combat, turns, victory, AI and save/restore.
- [ ] Build Android APK and test on a physical mid-range device.

- [x] Confirm Godot headless CI on PR #5: run 42584227883 succeeded (2026-11-09).
- [ ] Re-run CI after merging/reconciling movement PRs; the current success applies only to PR #5.

- [ ] Integrate standalone combat resolution with unit state and turn controller after CI validation.

- [ ] Verify new turn tests in Godot CI; integrate turns with combat and scene input after green results.

- [ ] Validate BattleActions.gd on Godot CI, then integrate scene input and movement into battle state.

- [ ] Validate duplicate-ID battle guard in Godot CI; review before merging stacked PRs.
- [ ] Confirm CI for off-board attack rejection; integrate board input after validation.

2026-11-09: Verify movement action CI; connect movement and attack to a 10x8 Godot board/controller; add touch selection; then Android export and device tests.

- [ ] Run terrain-integrity regressions in Godot CI on the new stacked PR; then connect movement/attack to board input.

- [ ] Verify BattleSession headless CI and fix any failures; then connect touch board UI to BattleSession. No APK until verified export.

- [ ] Verify touch board GDScript test and fix CI failures; verify on-screen input in Godot and physical Android.
- [ ] Add AI turn, win/lose overlay and persistence after interactive prototype passes.

- [ ] Diagnose failed Godot workflow run 42671606319 on PR #14; verify all headless suites before merging stacked PRs.
- [ ] Verify spent-unit selection and tap-to-deselect regressions in Godot CI on new branch.
