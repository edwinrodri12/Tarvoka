"""Static regression: TARVOKA's Android release must not request network access.

Run: python3 -m unittest discover -s tests -p 'test_android_offline_permissions.py'
This tests source configuration, not a compiled manifest or physical device.
"""
import configparser
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class AndroidOfflinePermissions(unittest.TestCase):
    def test_export_preset_has_no_network_permission(self):
        cfg = configparser.ConfigParser(interpolation=None)
        cfg.optionxform = str
        cfg.read(ROOT / "export_presets.cfg", encoding="utf-8")
        self.assertEqual(cfg["preset.0"]["platform"].strip('"'), "Android")
        opts = cfg["preset.0.options"]
        # Explicitly enabled permission flags must not grant internet/network state.
        for key, value in opts.items():
            if key.startswith("permissions/") and any(
                word in key.lower() for word in ("internet", "network", "wifi")
            ):
                self.assertNotEqual(value.strip().lower(), "true", key)
        self.assertEqual(opts["package/unique_name"].strip('"'), "com.edwinrodri12.tarvoka")

    def test_no_network_client_in_runtime_scripts(self):
        scripts = ROOT / "scripts"
        self.assertTrue(scripts.is_dir(), "Expected Godot runtime scripts directory")
        forbidden = ("HTTPRequest.new(", "HTTPClient.new(", "WebSocketPeer.new(", "ENetMultiplayerPeer.new(")
        for path in scripts.rglob("*.gd"):
            source = path.read_text(encoding="utf-8")
            for token in forbidden:
                with self.subTest(file=str(path.relative_to(ROOT)), token=token):
                    self.assertNotIn(token, source)


if __name__ == "__main__":
    unittest.main()
