#!/usr/bin/env python3
"""CLI-level regressions for the exported APK offline-permission gate."""
import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from subprocess import CompletedProcess, TimeoutExpired
import audit_apk_network_permissions as audit


class AuditCliTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.apk = Path(self.temp.name) / "test.apk"
        self.apk.write_bytes(b"placeholder: subprocess mocked")

    def invoke(self, output, returncode=0):
        result = CompletedProcess(["aapt"], returncode, output, "aapt error")
        with patch.object(audit.shutil, "which", return_value="/fake/aapt"), \
             patch.object(audit.subprocess, "run", return_value=result), \
             contextlib.redirect_stderr(io.StringIO()), \
             contextlib.redirect_stdout(io.StringIO()):
            return audit.main(["audit", str(self.apk)])

    def test_valid_offline_manifest_passes(self):
        self.assertEqual(0, self.invoke("package: name='org.tarvoka.game'\nuses-permission: name='android.permission.CAMERA'"))

    def test_internet_permission_fails(self):
        self.assertEqual(1, self.invoke("package: name='org.tarvoka.game'\nuses-permission: name='android.permission.INTERNET'"))

    def test_unparseable_manifest_fails_closed(self):
        self.assertEqual(2, self.invoke("package: name='org.tarvoka.game'\nuses-permission: name=android.permission.INTERNET"))

    def test_aapt_failure_fails_closed(self):
        self.assertEqual(2, self.invoke("", returncode=1))

    def test_missing_aapt_fails_closed(self):
        with patch.object(audit.shutil, "which", return_value=None), \
             contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(2, audit.main(["audit", str(self.apk)]))

    def test_timeout_fails_closed(self):
        with patch.object(audit.shutil, "which", return_value="/fake/aapt"), \
             patch.object(audit.subprocess, "run", side_effect=TimeoutExpired("aapt", 30)), \
             contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(2, audit.main(["audit", str(self.apk)]))

    def test_missing_apk_fails_closed(self):
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(2, audit.main(["audit", str(self.apk) + ".missing"]))


if __name__ == "__main__":
    unittest.main()
