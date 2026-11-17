# QA — Android export network permissions (2026-11-17)

## Increment
Added `tests/test_android_network_permissions.py` to flag **explicitly enabled** network-related permissions in `export_presets.cfg`. This is independent of the runtime constructor guard in PR #518 and does not change production settings.

## Reproduce
From repository root: `python3 tests/test_android_network_permissions.py`.
Expected exit code 0 with `PASS: no explicitly enabled network permissions in export_presets.cfg`. A preset with `permissions/internet=true` or `permissions/access_network_state=1` must fail. The test contains four self-checks for case, false, comments and positive values.

## Evidence and limitations
- Source committed: `648f52c4fdb9757d6cd961940d358a9b25ec060c`.
- Python execution: NO EJECUTADO at commit time; CI integration: PENDIENTE.
- Godot 4.3/Android CI: NO CONFIRMADO for this change.
- Android physical: NO EJECUTADO EN DISPOSITIVO.
- **Important:** An absent permission flag does not prove the final APK manifest has no network permissions. Export templates, plugins and manifest merging can alter the result. Audit the generated APK's `AndroidManifest.xml` using Android SDK `apkanalyzer manifest permissions` or `aapt dump permissions` and record the exact build SHA.
- No claims of runtime network silence or device performance are made.

## Next
Run this Python check in CI and inspect the exported APK manifest. Keep PR as draft until appropriate checks pass; do not distribute an APK for this incremental test.
