# QA — offline network-constructor guard (2026-11-17)

## Scope
Independent P0-10 static regression. Scans runtime GDScript and scenes under `res://scripts` and `res://scenes` recursively for direct construction of seven networking client/server classes. It intentionally does not alter gameplay, AI, persistence, UI or Android export settings.

## Execute
```sh
godot --headless --path . --script res://tests/test_offline_network_guard.gd
```
Expected exit 0 and `PASS: offline runtime network-constructor guard`. Any detected constructor or unreadable runtime directory/file must exit 1.

## Limits and status
- GitHub source commit: 0c11b9e62115a74abee021e0c0478a4376bacaed (PASÓ: write).
- Godot headless: NO EJECUTADO.
- CI: NO CONFIRMADO.
- Android: NO EJECUTADO EN DISPOSITIVO.
- Static scan is not proof that the Android package makes zero network requests: dynamically loaded resources, plugins, native libraries, external shell calls and other API spellings require separate review.
- This is a reversible guard, not a new approved gameplay rule. If a future authorized online mode is implemented, explicitly scope this guard to offline builds rather than deleting the check.

## Follow-up
Wire the script into existing Godot CI after checking workflow ownership, run core rules/AI/save/victory regressions, inspect Android manifest permissions, and validate offline gameplay in airplane mode on a physical device. Do not merge without green checks.
