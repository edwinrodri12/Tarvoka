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

- [ ] Validate touch/mouse dedup regression on Godot CI and real Android device; verify tap selects exactly once and desktop mouse still selects. Do not merge without green checks.

- [ ] Validate decisive-attack victory UI regression in Godot headless CI; then review stacked PRs for integration.

- [ ] Confirm CI on typed-blocked-array test fix, inspect any next failing test and fix before integration. Previous PR #17 run 42699713939 was CANCELLED after Godot script type error; do not count as passing.

- [x] Confirm PR #18 typed-array fix via Godot 4.3 CI: run 42709626139 SUCCESS on commit 5e60d2e, all seven suites.
- [ ] Verify newer BattleSession invalid-start-faction regression via GitHub Actions; review and consolidate stacked PRs into main only after latest green checks.

- [ ] Verify BasicAI.gd headless regression tests on its own PR and resolve any Godot 4.3 errors.
- [ ] Connect BasicAI step loop to the enemy turn with a bounded action count, then test full human-vs-AI battle.
- [ ] Consolidate stacked draft PRs #5-#18 after reviewing their green checks; do not treat branch code as integrated into main.

- [ ] Verify bounded AI-turn UI regression on Godot CI, then manually exercise a full human-vs-AI battle.
- [ ] Add save/load state and first Android export after CI is green; physical-device touch verification remains required.

- [ ] Verify optimized AI and water-wall regression in Godot CI; diagnose remaining touch-board timeouts from job logs if still present.

- [ ] Verify SaveCodec JSON round-trip CI and integrate file persistence via user:// after green tests.

- [ ] Verify SaveStore Godot CI; inspect failure logs and correct issues before merging. Then wire save/load buttons into touch board.

- [ ] Verify save/load UI integration on Godot CI and physical Android; diagnose recurrent cancelled CI before merging stacked PRs.

- [ ] Verify Godot CI on 2026-11-10 AI action-count type fix; inspect touch-board test and downstream AI/save tests before merging stacked PRs.

2026-11-10: Verify CI fast-fail branch, inspect any timed-out suite logs, fix root cause, then validate full test set before Android export.
