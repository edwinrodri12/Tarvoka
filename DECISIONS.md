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
