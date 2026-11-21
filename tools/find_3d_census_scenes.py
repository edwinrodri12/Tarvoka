#!/usr/bin/env python3
"""Locate real Godot 3D scene candidates for the mesh census.

Standard library only. This is a discovery aid, NOT a triangle count.
Run: python3 tools/find_3d_census_scenes.py .
"""
from pathlib import Path
import argparse
import sys


def candidates(root: Path):
    for scene in sorted(root.rglob("*.tscn")):
        if any(part in {".git", ".godot", "tests", "addons"} for part in scene.relative_to(root).parts):
            continue
        try:
            data = scene.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        if "[node " not in data:
            continue
        if not any(token in data for token in (
            'type="Node3D"', 'type="MeshInstance3D"',
            'type="MultiMeshInstance3D"', 'type="CSGBox3D"',
            'type="CSGMesh3D"', 'type="CSGSphere3D"',
        )):
            continue
        yield scene.relative_to(root).as_posix()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not (root / "project.godot").is_file():
        parser.error("root must contain project.godot")
    paths = list(candidates(root))
    for path in paths:
        print("res://" + path)
    print(f"3D_SCENE_CANDIDATES={len(paths)}", file=sys.stderr)
    return 0 if paths else 1


if __name__ == "__main__":
    raise SystemExit(main())
