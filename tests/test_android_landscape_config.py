"""Static Android landscape configuration contract (Python 3, no dependencies).

Run: python3 -m unittest discover -s tests -p test_android_landscape_config.py
This is not a physical-device orientation or touch usability test.
"""
import configparser
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


def validate_project_config(source: str) -> list[str]:
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.optionxform = str
    try:
        parser.read_string(source)
    except configparser.Error as exc:
        return [f"Malformed project.godot: {exc}"]

    expected = {
        ("display", "window/handheld/orientation"): "0",
        ("display", "window/stretch/mode"): '"canvas_items"',
        ("display", "window/stretch/aspect"): '"expand"',
        ("rendering", "renderer/rendering_method.mobile"): '"gl_compatibility"',
    }
    failures = []
    for (section, key), value in expected.items():
        actual = parser.get(section, key, fallback=None)
        if actual != value:
            failures.append(f"{section}/{key}: expected {value}, got {actual!r}")
    for key in ("window/size/viewport_width", "window/size/viewport_height"):
        raw = parser.get("display", key, fallback="")
        try:
            value = int(raw)
            if value <= 0:
                raise ValueError("nonpositive")
        except ValueError:
            failures.append(f"display/{key}: expected positive integer")
    if not failures:
        width = parser.getint("display", "window/size/viewport_width")
        height = parser.getint("display", "window/size/viewport_height")
        if width <= height:
            failures.append("viewport must be wider than tall")
    return failures


class AndroidLandscapeConfigTests(unittest.TestCase):
    def test_repository_project(self):
        self.assertEqual([], validate_project_config(
            (ROOT / "project.godot").read_text(encoding="utf-8")
        ))

    def test_reject_portrait(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertTrue(validate_project_config(
            project.replace("window/handheld/orientation=0", "window/handheld/orientation=1")
        ))

    def test_reject_tall_viewport(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertTrue(validate_project_config(
            project.replace("viewport_width=1280", "viewport_width=600")
        ))

    def test_reject_missing_mobile_renderer(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertTrue(validate_project_config(
            project.replace('renderer/rendering_method.mobile="gl_compatibility"', "")
        ))


if __name__ == "__main__":
    unittest.main()
