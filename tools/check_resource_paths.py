#!/usr/bin/env python3
"""Offline TARVOKA Godot external-resource path audit (stdlib only).

Checks ext_resource path="res://..." in .tscn/.tres files. This is a
static integrity check, not a Godot parser or Android performance test.
"""
import argparse
import pathlib
import re
import sys

RESOURCE = re.compile(r'^\s*\[ext_resource\b[^\]]*\bpath="(res://[^"]+)"', re.MULTILINE)


def audit(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    root = root.resolve()
    for scene in sorted((*root.rglob("*.tscn"), *root.rglob("*.tres"))):
        if ".git" in scene.relative_to(root).parts:
            continue
        try:
            source = scene.read_text(encoding="utf-8-sig")
        except (OSError, UnicodeError) as exc:
            errors.append(f"{scene.relative_to(root)}: unreadable: {exc}")
            continue
        for match in RESOURCE.finditer(source):
            raw = match.group(1)[6:]
            parts = pathlib.PurePosixPath(raw).parts
            if not raw or any(part in ("..", ".") for part in parts) or "\\" in raw:
                errors.append(f"{scene.relative_to(root)}: invalid resource path {match.group(1)}")
                continue
            target = root.joinpath(*parts)
            if not target.is_file() or not target.resolve().is_relative_to(root):
                errors.append(f"{scene.relative_to(root)}: missing resource {match.group(1)}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", nargs="?", default=".", type=pathlib.Path)
    args = parser.parse_args()
    if not (args.project / "project.godot").is_file():
        print("ERROR: project.godot not found", file=sys.stderr)
        return 2
    errors = audit(args.project)
    for error in errors:
        print("FAIL:", error)
    print(f"Resource path audit: {'FAIL' if errors else 'PASS'} ({len(errors)} errors)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
