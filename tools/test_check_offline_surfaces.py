"""Regression tests for TARVOKA offline network-surface audit."""
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_offline_surfaces import scan


class OfflineSurfaceTests(unittest.TestCase):
    def test_detects_runtime_network_classes(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Net.gd").write_text(
                "extends Node\nvar request = HTTPRequest.new()\n"
                "var socket = PacketPeerUDP.new()\n", encoding="utf-8")
            self.assertEqual(len(scan(root)), 2)

    def test_ignores_comments_and_generated_directories(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Safe.gd").write_text(
                "# HTTPRequest.new()\n; HTTPClient\nextends Node\n", encoding="utf-8")
            (root / ".godot").mkdir()
            (root / ".godot" / "Generated.gd").write_text(
                "HTTPRequest.new()\n", encoding="utf-8")
            self.assertEqual(scan(root), [])

    def test_detects_scene_http_request_node(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Main.tscn").write_text(
                '[node name="Net" type="HTTPRequest"]\n', encoding="utf-8")
            self.assertEqual(len(scan(root)), 1)

    def test_no_false_positive_for_plain_scene(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Main.tscn").write_text(
                '[node name="Root" type="Node3D"]\n', encoding="utf-8")
            self.assertEqual(scan(root), [])


    def test_detects_webrtc_upnp_and_tls_without_substring_false_positives(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Network.gd").write_text(
                "var a = WebRTCPeerConnection.new()\n"
                "var b = WebRTCDataChannel\n"
                "var c = UPNP.new()\n"
                "var d = PacketPeerDTLS.new()\n"
                "var e = StreamPeerTLS.new()\n"
                "var f = MultiplayerPeerExtension\n"
                "var safe = MyUPNPWrapper\n",
                encoding="utf-8",
            )
            findings = scan(root)
            self.assertEqual(len(findings), 6)
            self.assertFalse(any("MyUPNPWrapper" in item for item in findings))

    def test_flags_shell_execution_and_browser_bridge_escape_hatches(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Escape.gd").write_text(
                'OS.execute("curl", ["https://example.invalid"])\n'
                'var browser = JavaScriptBridge\n'
                'var safe = OS.execute_not_a_call\n'
                '# OS.execute("ignored", [])\n',
                encoding="utf-8",
            )
            findings = scan(root)
            self.assertEqual(len(findings), 2)
            self.assertTrue(any("OS.execute" in item for item in findings))
            self.assertTrue(any("JavaScriptBridge" in item for item in findings))

    def test_does_not_follow_symlinked_source_outside_checkout(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder) / "repo"
            root.mkdir()
            outside = Path(folder) / "external.gd"
            outside.write_text("var client = HTTPRequest.new()\n", encoding="utf-8")
            (root / "External.gd").symlink_to(outside)
            (root / "Safe.gd").write_text("extends Node\n", encoding="utf-8")
            self.assertEqual(scan(root), [])

    def test_does_not_follow_symlinked_source_inside_checkout(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "Real.gd").write_text("var client = HTTPRequest.new()\n", encoding="utf-8")
            (root / "Alias.gd").symlink_to(root / "Real.gd")
            findings = scan(root)
            self.assertEqual(len(findings), 1)
            self.assertIn("Real.gd", findings[0])

if __name__ == "__main__":
    unittest.main()
