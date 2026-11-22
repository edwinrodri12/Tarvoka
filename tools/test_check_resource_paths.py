"""Self-contained unit tests for check_resource_paths.py (Python stdlib)."""
import pathlib
import tempfile
import unittest
from check_resource_paths import audit


class ResourcePathAuditTests(unittest.TestCase):
    def test_existing_and_missing_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "project.godot").write_text("config_version=5\n")
            (root / "assets").mkdir()
            (root / "assets" / "valid.png").write_bytes(b"test")
            (root / "scenes").mkdir()
            (root / "scenes" / "sample.tscn").write_text(
                '[gd_scene format=3]\n'
                '[ext_resource type="Texture2D" path="res://assets/valid.png" id="1"]\n'
                '[ext_resource type="Script" path="res://scripts/missing.gd" id="2"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 1)
            self.assertIn("scripts/missing.gd", errors[0])

    def test_non_external_text_is_ignored(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "sample.tres").write_text('[resource]\nresource_name="res://not_a_path"\n')
            self.assertEqual(audit(root), [])


if __name__ == "__main__":
    unittest.main()
