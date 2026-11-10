# Decisions
- Godot 4 + modular GDScript; offline-first Android strategy.
- Board 10x8; terrain-dependent movement, impassable cells.
- Keep TARVOKA independent and original; commercial name pending trademark clearance.
- Test engine rules headlessly in GitHub Actions with official Godot 4.3 Linux binary; no Android builds or deployment in CI yet.
- Avoid merging pending overlapping movement PRs before comparing their diffs and tests.

- Treat successful CI on a draft PR as evidence for that exact head commit only; never infer other PRs or Android work passed. Keep PR #5 draft until integration review.

- Combat calculations are deterministic, bounded by remaining HP, with minimum 1 damage for positive attacks; invalid dead-unit attacks are rejected. This is an initial ruleset, not final balancing.

- Turn state is a pure data transformation; faction owns actions, dead units cannot act, and victory requires exactly one surviving faction.

- Initial attack integration permits only orthogonally adjacent enemy units and consumes the attacker's action; damage is deterministic. Ranged attacks and counterattacks are future work.

- Reject battle actions when unit identifiers are duplicated, empty or missing to avoid targeting an ambiguous combatant.
- Reject attacks with either combatant outside the 10x8 battlefield, even when adjacent.

2026-11-09: Moving consumes the unit's single action for its turn in the initial playable prototype. No move-and-attack in one turn until explicitly redesigned. Living units cannot share cells.

- Reject the entire movement query if any terrain cell has an unknown or non-string type, or if the origin is impassable; avoid silently interpreting corrupted maps.

2026-11-09: BattleSession is a pure RefCounted rules coordinator for two factions (0/1), independent of scene nodes and offline-capable. Each unit has one action per turn; movement consumes that action. No post-victory actions.

2026-11-09: Use lightweight Control._draw() board and _gui_input() for initial Android touch prototype, no art assets or external dependencies. Each successful move/attack consumes the unit action according to BattleSession. Defer animations and gestures until core behavior is verified.

- UI selection is restricted to living, active-faction units with unused actions; tapping an already selected unit cancels selection. Keep rule enforcement in BattleSession as the source of truth.

2026-11-09: Disable Godot's touch-to-mouse emulation for TARVOKA because TouchBoard.gd handles InputEventScreenTouch and InputEventMouseButton independently; processing both can turn one physical tap into two board actions. Preserve direct mouse input for desktop debugging.

2026-11-09: Show a victory message immediately after a decisive attack; preserve immutable BattleSession as the winner authority and block further turn changes.

2026-11-09: Preserve Rules.reachable typed Array[Vector2i] contract. Regression tests must supply explicitly typed empty blocked-cell arrays rather than untyped [] literals. Keep this fix isolated and do not merge stacked PRs without green CI.

2026-11-09: Invalid first_faction on BattleSession.start normalizes to faction 0 rather than creating a permanently inactive match. Keep faction 0/1 invariant for offline two-player prototype; add headless regression.

2026-11-09: Initial offline AI is deterministic, pure, one legal action per call, prioritizes adjacent attacks, then legal moves toward nearest living enemy; caller remains responsible for ending AI turns. No randomness, network or scene dependencies. Avoid conflating a tested planner with a playable AI opponent until connected to UI.

2026-11-09: Faction 0 is the human player by default, faction 1 runs bounded deterministic BasicAI when human ends turn. ai_enabled=false preserves two-human local testing. Stop AI on victory; no further end-turn after a win.

2026-11-09: Optimize deterministic AI planning by computing Rules.reachable once per acting unit, then validating only the selected candidate with Session.move. Preserve authoritative legality and deterministic row-major tie-breaking.

- Save format v1: JSON with explicit [x,y] positions, fixed 10x8 terrain and strict validation. Decode rejects malformed/version-incompatible payloads; filesystem save/load deferred.

2026-11-09: Store saves in user://tarvoka_battle_v1.json, limit 256 KiB, reject non-user paths and invalid codec states; use temporary write and rollback of previous file on rename failure. No encryption or cloud dependency.

2026-11-09: Expose offline save/load via explicit UI buttons; delegate serialization and filesystem validation to SaveStore, clear stale selection after restore, preserve live state when loading fails.

2026-11-10: Explicitly annotate the bounded AI action count as `int` after casting units to `Array` to satisfy Godot 4.3 static inference. Keep original unit-count action cap and gameplay semantics unchanged.

2026-11-10: CI runs each Godot headless test with GNU timeout (TERM at 90s, KILL 5s later), preserving nonzero exit status to expose hangs rather than waiting for the 10-minute job deadline.
