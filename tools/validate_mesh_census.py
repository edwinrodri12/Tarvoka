#!/usr/bin/env python3
"""Validate a TARVOKA mesh census JSON independently of Godot.

Usage: python3 tools/validate_mesh_census.py report.json
       python3 tools/validate_mesh_census.py --self-test
Exit codes: 0 valid, 2 invalid report/input.
This is a structural check, NOT a frame-rate or device benchmark.
"""
import json
import pathlib
import sys


COUNTS = ("triangles", "instances", "mesh_nodes", "surfaces", "largest_mesh_triangles")


def validate(report):
    if not isinstance(report, dict):
        return "report must be an object"
    for key in COUNTS:
        value = report.get(key)
        if type(value) is not int or value < 0:
            return f"{key} must be a non-negative integer"
    if report["mesh_nodes"] > report["instances"]:
        return "mesh_nodes exceeds instances"
    if report["largest_mesh_triangles"] > report["triangles"]:
        return "largest mesh exceeds total triangles"
    if report["instances"] == 0 and (report["triangles"] or report["mesh_nodes"] or report["surfaces"]):
        return "geometry declared without instances"
    path = report.get("largest_mesh_path")
    if not isinstance(path, str):
        return "largest_mesh_path must be a string"
    if report["largest_mesh_triangles"] > 0 and not path.strip():
        return "largest mesh has no path"
    if report["largest_mesh_triangles"] == 0 and path:
        return "zero-sized largest mesh has a path"
    warnings = report.get("warnings")
    if not isinstance(warnings, list) or any(not isinstance(w, str) for w in warnings):
        return "warnings must be a list of strings"
    return None


def self_test():
    good = dict(triangles=12, instances=1, mesh_nodes=1, surfaces=1,
                largest_mesh_triangles=12, largest_mesh_path="Vehicle/Hull", warnings=[])
    assert validate(good) is None
    for patch in ({"triangles": -1}, {"triangles": True}, {"mesh_nodes": 2},
                  {"largest_mesh_triangles": 13}, {"largest_mesh_path": ""},
                  {"warnings": [3]}, {"instances": 0}, {"surfaces": "1"}):
        bad = dict(good, **patch)
        assert validate(bad) is not None, patch
    empty = dict.fromkeys(COUNTS, 0)
    empty.update(largest_mesh_path="", warnings=[])
    assert validate(empty) is None
    print("PASS: 10 structural cases")


def main(argv):
    if len(argv) == 2 and argv[1] == "--self-test":
        self_test()
        return 0
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    try:
        report = json.loads(pathlib.Path(argv[1]).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"INVALID: cannot read JSON: {exc}", file=sys.stderr)
        return 2
    error = validate(report)
    if error:
        print(f"INVALID: {error}", file=sys.stderr)
        return 2
    print("PASS: mesh census report structure")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
