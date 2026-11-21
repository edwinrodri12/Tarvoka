#!/usr/bin/env python3
"""Offline regression tests for production 3D scene discovery."""
from pathlib import Path
from tempfile import TemporaryDirectory
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from find_3d_census_scenes import candidates


class DiscoveryTests(unittest.TestCase):
    def test_discovers_only_production_3d_scenes(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            for name, data in {
                "scenes/vehicle.tscn": '[gd_scene]\n[node name="Tank" type="Node3D"]\n',
                "scenes/menu.tscn": '[gd_scene]\n[node name="Menu" type="Control"]\n',
                "tests/fixture.tscn": '[gd_scene]\n[node name="Test" type="MeshInstance3D"]\n',
                ".godot/cache.tscn": '[gd_scene]\n[node name="Cache" type="Node3D"]\n',
                "scenes/broken.tscn": "not a scene",
            }.items():
                file = root / name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(data, encoding="utf-8")
            self.assertEqual(list(candidates(root)), ["scenes/vehicle.tscn"])

    def test_empty_directory_has_no_candidates(self):
        with TemporaryDirectory() as directory:
            self.assertEqual(list(candidates(Path(directory))), [])


if __name__ == "__main__":
    unittest.main()
