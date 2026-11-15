# BattleSession exchange contract — 2026-11-15

Scope: isolated headless regression against the real BattleSession.attack API on main, not the draft mountain/flanking implementation.

Run: `godot --headless --path . --script res://tests/test_session_exchange_contract.gd` (Godot 4.3).

Acceptance:
- A surviving defender yields the same damage, retaliation and HP as the deterministic BattleActions preview.
- Attack consumes the acting unit's action; replay is rejected.
- Caller state remains unchanged after the attack.
- A lethal opening hit prevents retaliation, declares faction 0 victorious and rejects further attacks/end-turn.
- The pre-attack state remains unchanged.

Evidence: file creation verified in GitHub commit b643d5c2. Godot execution, Android export, physical Android, AI, save/load and UI validation: **NO EJECUTADO** in this run. CI must execute this new test before merging. This does not validate PR #334's mountain-specific modifiers or PR #203's visual terrain.
