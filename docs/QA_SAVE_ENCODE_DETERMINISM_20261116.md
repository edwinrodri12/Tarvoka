# QA — deterministic save encoding (2026-11-16)

Scope: pure SaveCodec encoding, repeated roundtrip and snapshot isolation. Does not modify gameplay, save format or persisted files.

Run: `godot --headless --path . --script res://tests/test_save_encode_determinism.gd`

Acceptance: 20 identical encodes; state remains unchanged; decoded snapshots equal original and do not alias original units; stable encode-decode-encode. CI checks the PASS marker and exit code.

Status: **NO EJECUTADO** until Godot 4.3 workflow completes. Android physical: **NO EJECUTADO EN DISPOSITIVO**. Existing save corruption PR #416 remains independent. If this regression fails, diagnose serialization stability before changing the codec.

2026-11-16 extension: verify invalid negative-HP encoding fails closed without mutating the supplied dictionary, valid encoding still succeeds afterward, and two independently decoded snapshots cannot share nested unit/terrain data. These assertions run in the same 20-cycle test script; Godot and Android status remain unverified until new CI/device evidence.
