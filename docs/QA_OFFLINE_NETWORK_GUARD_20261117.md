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

## Incremento 2026-11-17: construcción dinámica
- El guard también rechaza `ClassDB.instantiate("HTTPClient")` y `ClassDB.instantiate(&"PacketPeerUDP")`, con espacios opcionales, para los tipos enumerados en la prueba.
- Dos auto-pruebas positivas adicionales comprueban ambas formas. La prueba anterior de `Vector2.new()` continúa como control negativo.
- Commit de código: `f03c7ea8f41e893d0b88f474a4d43820f9296e08`.
- Estado del nuevo commit: Godot/CI NO CONFIRMADO; Android NO EJECUTADO EN DISPOSITIVO. Revisar logs antes de integrar.
- Limitación: no analiza instanciación con nombres de clase construidos dinámicamente ni demuestra ausencia de tráfico de red en ejecución.
