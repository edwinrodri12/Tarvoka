#!/usr/bin/env python3
"""Offline TARVOKA Godot external-resource path audit (stdlib only).

Checks ext_resource path="res://..." in .tscn/.tres files. This is a
static integrity check, not a Godot parser or Android performance test.
"""
import argparse
import pathlib
import re
import sys

# Godot does not require ext_resource attributes to appear in a fixed order.
RESOURCE_LINE = re.compile(r'^\s*\[ext_resource\b([^\]\n]*)\]', re.MULTILINE)
PATH_ATTRIBUTE = re.compile(r'(?:^|\s)path="([^"]*)"')
ID_ATTRIBUTE = re.compile(r'(?:^|\s)id="([^"]*)"')


def audit(root: pathlib.Path) -> list[str]:
    errors: list[str] = []
    root = root.resolve()
    for scene in sorted((*root.rglob("*.tscn"), *root.rglob("*.tres"))):
        if any(part in (".git", ".godot") for part in scene.relative_to(root).parts):
            continue
        # Do not read source scenes symlinked outside the project root.
        # External files must never influence an offline repository audit.
        if not scene.resolve().is_relative_to(root):
            errors.append(f"{scene.relative_to(root)}: scene escapes project root")
            continue
        try:
            source = scene.read_text(encoding="utf-8-sig")
        except (OSError, UnicodeError) as exc:
            errors.append(f"{scene.relative_to(root)}: unreadable: {exc}")
            continue
        seen_ids: set[str] = set()
        for declaration in RESOURCE_LINE.finditer(source):
            # Report the source line so artists can fix broken references quickly.
            location = f"{scene.relative_to(root)}:{source.count(chr(10), 0, declaration.start()) + 1}"
            attributes = declaration.group(1)
            resource_id = ID_ATTRIBUTE.search(attributes)
            if resource_id is None or not resource_id.group(1):
                errors.append(f"{location}: external resource missing id attribute")
            else:
                identifier = resource_id.group(1)
                if identifier in seen_ids:
                    errors.append(f"{location}: duplicate external resource id {identifier}")
                seen_ids.add(identifier)
            match = PATH_ATTRIBUTE.search(attributes)
            if match is None:
                errors.append(f"{location}: external resource missing path attribute")
                continue
            if not match.group(1).startswith("res://"):
                errors.append(f"{location}: invalid external resource path {match.group(1)}")
                continue
            raw = match.group(1)[6:]
            # Preserve raw segments: PurePosixPath normalizes "." and repeated
            # separators before validation, hiding malformed declarations.
            parts = raw.split("/")
            if not raw or any(part in ("", ".", "..") for part in parts) or "\\" in raw:
                errors.append(f"{location}: invalid resource path {match.group(1)}")
                continue
            target = root.joinpath(*parts)
            if not target.is_file() or not target.resolve().is_relative_to(root):
                errors.append(f"{location}: missing resource {match.group(1)}")
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
