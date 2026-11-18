# TARVOKA — APK manifest network permission audit (2026-11-17)

## Increment
`tests/audit_apk_network_permissions.py` audits the **exported APK** via Android SDK `aapt dump permissions`. Unlike the preset-only test, it inspects the packaged manifest. It rejects INTERNET, ACCESS_NETWORK_STATE, CHANGE_NETWORK_STATE, ACCESS_WIFI_STATE and CHANGE_WIFI_STATE; a missing APK, missing aapt, aapt failure or timeout fails closed.

## Reproduction
After a successful Android debug export, with Android SDK build-tools `aapt` on PATH:

```sh
python3 tests/audit_apk_network_permissions.py build/TARVOKA-debug.apk
```

Expected success: `PASS: no forbidden Android network permissions in exported APK manifest` and exit 0. Network permission detected: exit 1. Unable to inspect: exit 2. The parser self-tests cover forbidden permissions, sdk-23 variants, allowed camera permission and unrelated package text. Do not confuse these self-tests with an actual exported APK inspection.

## Evidence and status
- Source committed in PR #518 branch `automation/offline-network-guard-20261117`.
- Godot 4.3/Android CI for this commit: NO CONFIRMADO.
- Exported APK manifest audit: NO EJECUTADO (requires build artifact and Android SDK aapt).
- Physical Android: NO EJECUTADO EN DISPOSITIVO.
- Runtime offline functionality: PENDIENTE; a clean manifest is necessary but not sufficient.

## Next
Run the audit against the actual Android CI debug APK and retain the build SHA and command output; then wire it to the existing Android export workflow only after confirming its artifact path. Keep PR draft until checks pass. No APK distribution or signing-key changes.
