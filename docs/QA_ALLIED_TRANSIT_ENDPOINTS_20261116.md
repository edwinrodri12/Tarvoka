# Allied transit endpoint regression — 2026-11-16

Scope: Godot 4.3, pure `Rules.reachable` contract; no gameplay rule changes.

Positive: a unit at (0,0) can cross a friendly occupied tile at (1,0), reach (1,1) for cost 2 and (2,1) for cost 3, but cannot end on (1,0).

Adversarial: enemies at (0,1) and (2,0) block paths. If (1,0) is also in blocked, the unit is sealed at its origin despite its presence in transit_only. Inputs remain unmodified.

Command: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`

Expected marker: `PASS: allied transit and endpoint isolation`.

Status: source committed; Godot 4.3 **NO EJECUTADO** on this commit, Android physical **NO EJECUTADO EN DISPOSITIVO**. This standalone test is not yet wired into the repository's existing CI suite. Before merging, add a CI invocation, run the new test and full tactical regression suite, and verify no overlapping PR has introduced equivalent coverage.
