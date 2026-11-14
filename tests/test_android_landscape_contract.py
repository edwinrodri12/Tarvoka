#!/usr/bin/env python3
"""Static Android/desktop presentation contract for TARVOKA (stdlib only).

This is a configuration regression guard, NOT device QA.
"""
from pathlib import Path
import configparser
import sys

ROOT = Path(__file__).resolve().parents[1]
config = configparser.ConfigParser(interpolation=None)
config.optionxform = str
config.read(ROOT / "project.godot", encoding="utf-8")

def require(section, key, expected):
    actual = config.get(section, key, fallback=None)
    if actual != expected:
        raise AssertionError(f"{section}/{key}: expected {expected!r}, got {actual!r}")

def main():
    require("display", "window/handheld/orientation", "0")
    width = config.getint("display", "window/size/viewport_width")
    height = config.getint("display", "window/size/viewport_height")
    if width <= height or width < 960 or height < 540:
        raise AssertionError(f"Landscape reference viewport too small: {width}x{height}")
    require("display", "window/stretch/mode", '"canvas_items"')
    require("display", "window/stretch/aspect", '"expand"')
    require("rendering", "renderer/rendering_method.mobile", '"gl_compatibility"')
    require("rendering", "textures/vram_compression/import_etc2_astc", "true")
    scene = config.get("application", "run/main_scene").strip('"')
    if not scene.startswith("res://") or not (ROOT / scene[6:]).is_file():
        raise AssertionError(f"Missing startup scene: {scene}")
    # Touch synthesis is deliberately enabled for the current button input path.
    # Changing this requires Android input regression, not just a config edit.
    require("input_devices", "pointing/emulate_mouse_from_touch", "true")
    print("PASS android landscape configuration contract (static; not physical QA)")

if __name__ == "__main__":
    try:
        main()
    except (AssertionError, ValueError, configparser.Error) as exc:
        print(f"FAIL android landscape contract: {exc}", file=sys.stderr)
        sys.exit(1)
