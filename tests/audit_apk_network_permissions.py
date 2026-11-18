#!/usr/bin/env python3
"""Audit network permissions in an exported TARVOKA APK.

Usage: python3 tests/audit_apk_network_permissions.py build/TARVOKA-debug.apk
Requires Android SDK aapt (or aapt2) on PATH. Fails closed if unavailable.
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
PERMISSION_LINE = re.compile(r"^\s*(?:uses-permission|uses-permission-sdk-23):\s+name='([^']+)'", re.MULTILINE)

PACKAGE_LINE = re.compile(r"^\s*package:\s+name='[^']+'", re.MULTILINE)


def forbidden_permissions(dump: str) -> set[str]:
    return set(PERMISSION_LINE.findall(dump)) & FORBIDDEN


def self_test() -> None:
    assert forbidden_permissions("uses-permission: name='android.permission.INTERNET'") == {"android.permission.INTERNET"}
    assert forbidden_permissions("uses-permission-sdk-23: name='android.permission.ACCESS_NETWORK_STATE'") == {"android.permission.ACCESS_NETWORK_STATE"}
    assert forbidden_permissions("uses-permission: name='android.permission.CAMERA'") == set()
    assert forbidden_permissions("package: name='android.permission.INTERNET'") == set()
    assert PACKAGE_LINE.search("package: name='com.example.tarvoka'")
    assert not PACKAGE_LINE.search("garbled output")


def main(argv: list[str]) -> int:
    self_test()
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
    if not PACKAGE_LINE.search(result.stdout):
        print("FAIL: aapt output lacks APK package metadata; manifest NOT verified", file=sys.stderr)
        return 2
    violations = forbidden_permissions(result.stdout)
    if violations:
        print("FAIL: forbidden APK network permissions: " + ", ".join(sorted(violations)), file=sys.stderr)
        return 1
    print("PASS: no forbidden Android network permissions in exported APK manifest")
    print("LIMITATION: manifest audit does not prove runtime offline behavior")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
