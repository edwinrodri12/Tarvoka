#!/usr/bin/env python3
"""Audit network permissions in an exported TARVOKA APK.

Usage: python3 tests/audit_apk_network_permissions.py build/TARVOKA-debug.apk
Requires Android SDK aapt on PATH. Fails closed if unavailable.
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

FORBIDDEN = {
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.CHANGE_NETWORK_STATE",
    "android.permission.ACCESS_WIFI_STATE",
    "android.permission.CHANGE_WIFI_STATE",
}
PERMISSION_LINE = re.compile(r"^\s*uses-permission(?:-sdk-(?:[0-9]+|m))?:\s+name='([^'\r\n]+)'\s*$", re.MULTILINE)

PERMISSION_PREFIX = re.compile(r"^\s*uses-permission(?:-sdk-[A-Za-z0-9_-]+)?:", re.MULTILINE)

PACKAGE_LINE = re.compile(r"^\s*package:\s+(?:name=)?(?:\x27[^\x27\r\n]+\x27|[A-Za-z_][A-Za-z0-9_.]*)\s*$", re.MULTILINE)


def forbidden_permissions(dump: str) -> set[str]:
    return set(PERMISSION_LINE.findall(dump)) & FORBIDDEN



def audit_dump(dump: str) -> set[str]:
    """Validate aapt output before deciding whether the manifest is offline-safe."""
    if not PACKAGE_LINE.search(dump):
        raise ValueError("aapt output lacks APK package metadata")
    declared = PERMISSION_PREFIX.findall(dump)
    parsed = PERMISSION_LINE.findall(dump)
    if len(declared) != len(parsed):
        raise ValueError("unparseable permission declaration in aapt output")
    return set(parsed) & FORBIDDEN


def self_test() -> None:
    assert forbidden_permissions("uses-permission: name='android.permission.INTERNET'") == {"android.permission.INTERNET"}
    assert forbidden_permissions("uses-permission-sdk-23: name='android.permission.ACCESS_NETWORK_STATE'") == {"android.permission.ACCESS_NETWORK_STATE"}
    assert forbidden_permissions("uses-permission: name='android.permission.CAMERA'") == set()
    assert forbidden_permissions("package: name='android.permission.INTERNET'") == set()
    assert PACKAGE_LINE.search("package: name='com.example.tarvoka'")
    assert PACKAGE_LINE.search("package: com.example.tarvoka")
    assert not PACKAGE_LINE.search("package: ")
    assert not PACKAGE_LINE.search("garbled output")
    assert forbidden_permissions("uses-permission: name=\'android.permission.INTERNET\'\nuses-permission: name=\'android.permission.CAMERA\'") == {"android.permission.INTERNET"}
    assert forbidden_permissions("uses-permission: name=\'android.permission.INTERNET_EXTRA\'") == set()
    assert len(PERMISSION_PREFIX.findall("uses-permission: name=android.permission.INTERNET")) == 1
    assert len(PERMISSION_PREFIX.findall("  uses-permission-sdk-23: name=android.permission.INTERNET")) == 1
    assert len(PERMISSION_PREFIX.findall("  uses-permission-sdk-m: name=android.permission.INTERNET")) == 1
    assert len(PERMISSION_LINE.findall("uses-permission: name=android.permission.INTERNET")) == 0
    valid = "package: name='com.example.tarvoka'\nuses-permission: name='android.permission.CAMERA'"
    assert audit_dump(valid) == set()
    blocked = "package: name='com.example.tarvoka'\nuses-permission-sdk-m: name='android.permission.INTERNET'"
    assert audit_dump(blocked) == {"android.permission.INTERNET"}
    # SDK-numbered declarations must be audited; unknown SDK suffixes fail closed.
    assert audit_dump("package: name='com.example.tarvoka'\nuses-permission-sdk-33: name='android.permission.INTERNET'") == {"android.permission.INTERNET"}
    for malformed_sdk in (
        "uses-permission-sdk-x: name='android.permission.INTERNET'",
        "uses-permission-sdk-33: name='android.permission.INTERNET' trailing",
        "uses-permission-sdk-33: name=android.permission.INTERNET",
    ):
        try:
            audit_dump("package: name='com.example.tarvoka'\n" + malformed_sdk)
        except ValueError:
            pass
        else:
            raise AssertionError(f"Malformed SDK permission accepted: {malformed_sdk!r}")
    for malformed in (
        "uses-permission: name='android.permission.CAMERA'",
        "package: name='com.example.tarvoka'\nuses-permission: name=android.permission.INTERNET",
        "package: name='com.example.tarvoka'\nuses-permission-sdk-m: name=",
    ):
        try:
            audit_dump(malformed)
        except ValueError:
            pass
        else:
            raise AssertionError(f"Malformed manifest was accepted: {malformed!r}")


def main(argv: list[str]) -> int:
    self_test()
    if len(argv) == 2 and argv[1] == "--self-test":
        print("PASS: APK manifest parser self-tests")
        return 0
    if len(argv) != 2:
        print("Usage: audit_apk_network_permissions.py PATH_TO_APK", file=sys.stderr)
        return 2
    apk = Path(argv[1])
    if not apk.is_file():
        print(f"FAIL: APK not found: {apk}", file=sys.stderr)
        return 2
    tool = shutil.which("aapt")
    if tool is None:
        print("FAIL: Android SDK aapt unavailable; manifest NOT verified", file=sys.stderr)
        return 2
    try:
        result = subprocess.run([tool, "dump", "permissions", str(apk)], capture_output=True,
                                text=True, timeout=30, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"FAIL: cannot inspect APK manifest: {exc}", file=sys.stderr)
        return 2
    if result.returncode:
        print(f"FAIL: aapt returned {result.returncode}: {result.stderr.strip()}", file=sys.stderr)
        return 2
    try:
        violations = audit_dump(result.stdout)
    except ValueError as exc:
        print(f"FAIL: {exc}; manifest NOT verified", file=sys.stderr)
        return 2
    if violations:
        print("FAIL: forbidden APK network permissions: " + ", ".join(sorted(violations)), file=sys.stderr)
        return 1
    print("PASS: no forbidden Android network permissions in exported APK manifest")
    print("LIMITATION: manifest audit does not prove runtime offline behavior")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
