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

    def test_errors_include_exact_declaration_lines(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "sample.tscn").write_text(
                '[gd_scene format=3]\n'
                '[node name="Root" type="Node"]\n'
                '[ext_resource type="Script" path="res://missing.gd" id="1"]\n'
                '[ext_resource type="Script" id="2"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 2, errors)
            self.assertTrue(any("sample.tscn:3:" in e and "missing.gd" in e for e in errors), errors)
            self.assertTrue(any("sample.tscn:4:" in e and "missing path" in e for e in errors), errors)

    def test_generated_cache_and_git_metadata_are_excluded(self):
        # Imported Godot cache and Git internals are not source assets.
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            for directory in (".godot", ".git"):
                (root / directory).mkdir()
                (root / directory / "generated.tscn").write_text(
                    '[ext_resource type="Script" path="res://missing.gd" id="1"]\n'
                )
            (root / "actual.tscn").write_text(
                '[ext_resource type="Script" path="res://missing.gd" id="1"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("actual.tscn:1:", errors[0])

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


    def test_symlink_escape_is_rejected(self):
        # An external resource must not resolve outside the project tree.
        with tempfile.TemporaryDirectory() as project, tempfile.TemporaryDirectory() as outside:
            root = pathlib.Path(project)
            external = pathlib.Path(outside) / "secret.png"
            external.write_bytes(b"outside")
            (root / "assets").mkdir()
            try:
                (root / "assets" / "linked.png").symlink_to(external)
            except (NotImplementedError, OSError):
                self.skipTest("symlinks unavailable on this platform")
            (root / "sample.tscn").write_text(
                '[ext_resource type="Texture2D" path="res://assets/linked.png" id="1"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("missing resource", errors[0])

    def test_internal_symlink_is_valid_but_broken_symlink_fails(self):
        # An in-project alias is legal; a dangling alias is not.
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "assets").mkdir()
            (root / "assets" / "original.png").write_bytes(b"image")
            try:
                (root / "assets" / "alias.png").symlink_to("original.png")
                (root / "assets" / "broken.png").symlink_to("absent.png")
            except (NotImplementedError, OSError):
                self.skipTest("symlinks unavailable on this platform")
            (root / "sample.tscn").write_text(
                '[ext_resource type="Texture2D" path="res://assets/alias.png" id="1"]\n'
                '[ext_resource type="Texture2D" path="res://assets/broken.png" id="2"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("assets/broken.png", errors[0])

    def test_external_resources_reject_non_project_schemes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "sample.tscn").write_text(
                '[ext_resource type="Script" path="user://scripts/unsafe.gd" id="1"]\n'
                '[ext_resource type="Script" path="/tmp/unsafe.gd" id="2"]\n'
                '[ext_resource type="Script" path="res:/scripts/typo.gd" id="3"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 3, errors)
            self.assertTrue(all("invalid external resource path" in e for e in errors), errors)

    def test_external_resource_without_path_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "sample.tscn").write_text(
                '[ext_resource type="Script" id="1"]\n'
                '[ext_resource type="Script" path="res://missing.gd" id="2"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 2, errors)
            self.assertTrue(any("missing path attribute" in e for e in errors), errors)
            self.assertTrue(any("missing resource" in e for e in errors), errors)

    def test_duplicate_external_resource_ids_are_scoped_per_scene(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "assets").mkdir()
            (root / "assets" / "valid.png").write_bytes(b"ok")
            declaration = '[ext_resource type="Texture2D" path="res://assets/valid.png" id="same"]\n'
            (root / "first.tscn").write_text(declaration + declaration)
            (root / "second.tscn").write_text(declaration)
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("first.tscn:2: duplicate external resource id same", errors[0])

    def test_missing_and_empty_external_resource_ids_are_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "valid.gd").write_text("extends Node\n")
            (root / "sample.tscn").write_text(
                '[ext_resource type="Script" path="res://valid.gd"]\n'
                '[ext_resource type="Script" path="res://valid.gd" id=""]\n'
                '[ext_resource type="Script" path="res://valid.gd" id="valid"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 2, errors)
            self.assertTrue(any("sample.tscn:1: external resource missing id attribute" in e for e in errors), errors)
            self.assertTrue(any("sample.tscn:2: external resource missing id attribute" in e for e in errors), errors)

    def test_scene_symlink_outside_project_is_rejected(self):
        # The auditor must not inspect scenes outside the checkout.
        with tempfile.TemporaryDirectory() as project, tempfile.TemporaryDirectory() as outside:
            root = pathlib.Path(project)
            external = pathlib.Path(outside) / "private.tscn"
            external.write_text('[ext_resource path="res://missing.gd" id="1"]\n')
            try:
                (root / "linked.tscn").symlink_to(external)
            except (NotImplementedError, OSError):
                self.skipTest("symlinks unavailable on this platform")
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("linked.tscn: scene escapes project root", errors[0])
            self.assertNotIn("missing.gd", errors[0])

    def test_cyclic_scene_symlink_does_not_crash_audit(self):
        # A malicious or accidental symlink loop must produce a diagnostic.
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            try:
                (root / "cycle.tscn").symlink_to("cycle.tscn")
            except (NotImplementedError, OSError):
                self.skipTest("symlinks unavailable on this platform")
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("cycle.tscn: unresolvable scene symlink", errors[0])

    def test_cyclic_external_resource_symlink_is_reported_without_crash(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "assets").mkdir()
            try:
                (root / "assets" / "loop.png").symlink_to("loop.png")
            except (NotImplementedError, OSError):
                self.skipTest("symlinks unavailable on this platform")
            (root / "sample.tscn").write_text(
                '[ext_resource type="Texture2D" path="res://assets/loop.png" id="1"]\\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("sample.tscn:1: missing resource res://assets/loop.png", errors[0])

    def test_nul_in_external_resource_path_is_diagnostic_not_crash(self):
        # An actual NUL reaches pathlib and must not abort subsequent checks.
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "sample.tscn").write_text(
                ('[ext_resource type="Script" path="res://bad' + chr(0) + 'name.gd" id="1"]\n')
                + '[ext_resource type="Script" path="res://missing.gd" id="2"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 2, errors)
            self.assertTrue(any("sample.tscn:1:" in e and "missing resource" in e for e in errors), errors)
            self.assertTrue(any("sample.tscn:2:" in e and "missing resource" in e for e in errors), errors)

    def test_control_characters_in_resource_paths_are_invalid(self):
        # Reject non-printable path names before any filesystem access.
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "valid.gd").write_text("extends Node\n")
            (root / "sample.tscn").write_text(
                '[ext_resource type="Script" path="res://bad' + chr(0) + 'name.gd" id="1"]\n'
                + '[ext_resource type="Script" path="res://bad' + chr(9) + 'name.gd" id="2"]\n'
                + '[ext_resource type="Script" path="res://valid.gd" id="3"]\n'
            )
            errors = audit(root)
            self.assertEqual(len(errors), 2, errors)
            self.assertTrue(all("invalid resource path" in error for error in errors), errors)

    def test_unreadable_utf8_resource_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            root = pathlib.Path(temp)
            (root / "invalid.tres").write_bytes(bytes((0xff, 0xfe, 0x80)))
            errors = audit(root)
            self.assertEqual(len(errors), 1, errors)
            self.assertIn("unreadable", errors[0])


if __name__ == "__main__":
    unittest.main()
