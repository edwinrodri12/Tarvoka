#!/usr/bin/env python3
"""Static audit of explicitly enabled Android network permissions in Godot export presets.

This is not an APK manifest audit. Run against the built APK separately.
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

PRESET = Path("export_presets.cfg")
NETWORK_PERMISSIONS = {"internet", "access_network_state", "change_network_state",
                       "access_wifi_state", "change_wifi_state"}
ASSIGNMENT = re.compile(r"^\s*([^=;#]+?)\s*=\s*(.*?)\s*$")

def enabled_network_permissions(text: str) -> list[tuple[int, str]]:
    findings = []
    for number, line in enumerate(text.splitlines(), 1):
        match = ASSIGNMENT.match(line)
        if not match:
            continue
        key, value = match.groups()
        key = key.strip().lower()
        permission = key.rsplit("/", 1)[-1]
        if permission in NETWORK_PERMISSIONS and value.strip().lower() in {"true", "1"}:
            findings.append((number, key))
    return findings

def self_test() -> None:
    assert enabled_network_permissions('permissions/internet=true') == [(1, 'permissions/internet')]
    assert enabled_network_permissions('permissions/INTERNET = true') == [(1, 'permissions/internet')]
    assert enabled_network_permissions('permissions/internet=false\n# permissions/internet=true') == []
    assert enabled_network_permissions('permissions/internet=0\npermissions/access_network_state=1') == [(2, 'permissions/access_network_state')]

def main() -> int:
    self_test()
    if not PRESET.is_file():
        print(f"FAIL: missing {PRESET}", file=sys.stderr)
        return 1
    findings = enabled_network_permissions(PRESET.read_text(encoding="utf-8"))
    if findings:
        for line, permission in findings:
            print(f"FAIL: {PRESET}:{line} explicitly enables {permission}", file=sys.stderr)
        return 1
    print("PASS: no explicitly enabled network permissions in export_presets.cfg")
    print("LIMITATION: verify the generated AndroidManifest.xml independently")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
