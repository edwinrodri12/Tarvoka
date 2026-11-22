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

    def test_attribute_order_and_malformed_segments(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "assets").mkdir()
            (root / "assets" / "valid.png").write_bytes(b"ok")
            (root / "sample.tscn").write_text(
                '[ext_resource id="1" path="res://assets/valid.png" type="Texture2D"]\n'
                '[ext_resource id="2" path="res://assets/absent.png" type="Texture2D"]\n'
                '[ext_resource id="3" path="res://assets/../assets/valid.png"]\n'
                '[ext_resource id="4" path="res://assets//valid.png"]\n'
                '[ext_resource id="5" path="res://assets/./valid.png"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 4, errors)
            self.assertEqual(sum("missing resource" in e for e in errors), 1)
            self.assertEqual(sum("invalid resource path" in e for e in errors), 3)


if __name__ == "__main__":
    unittest.main()
