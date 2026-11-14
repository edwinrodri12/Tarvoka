"""Regression guard for TARVOKA Android debug signing policy.

Run: python3 -m unittest tests/test_android_signing_contract.py
This checks workflow configuration only; it does not verify an APK or device.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/android-debug-apk.yml"


class AndroidSigningContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = WORKFLOW.read_text(encoding="utf-8")

    def test_secrets_only_for_manual_main_builds(self):
        source = self.source
        for secret in (
            "TARVOKA_DEBUG_KEYSTORE_BASE64",
            "TARVOKA_DEBUG_STORE_PASSWORD",
            "TARVOKA_DEBUG_KEY_ALIAS",
        ):
            self.assertRegex(
                source,
                r"github\.event_name == 'workflow_dispatch'\s*&&\s*"
                r"github\.ref == 'refs/heads/main'\s*&&\s*secrets\." + secret,
            )
        self.assertIn('TARVOKA_SIGNING_MODE=ephemeral', source)
        self.assertIn('TARVOKA_SIGNING_MODE=persistent', source)

    def test_keystore_is_not_an_uploaded_artifact(self):
        source = self.source
        self.assertIn("actions/upload-artifact@v4", source)
        self.assertIn("path: build/TARVOKA-debug.apk", source)
        self.assertNotRegex(source, r"(?m)^\s*path:\s*.*(?:keystore|\.jks)\s*$")
        self.assertIn("rm -f /tmp/tarvoka-debug.keystore", source)

    def test_signing_and_arm64_are_verified(self):
        source = self.source
        self.assertIn("apksigner", source)
        self.assertIn("verify --verbose build/TARVOKA-debug.apk", source)
        self.assertIn("verify --print-certs build/TARVOKA-debug.apk", source)
        self.assertIn("arm64-v8a", source)
        self.assertIn("if-no-files-found: error", source)

    def test_pr_builds_and_manual_builds_are_distinct(self):
        source = self.source
        self.assertRegex(source, r"(?m)^\s*pull_request:\s*$")
        self.assertRegex(source, r"(?m)^\s*workflow_dispatch:\s*$")
        self.assertIn("if [ \"$GITHUB_EVENT_NAME\" = workflow_dispatch ]", source)
        self.assertIn("if [ \"$configured\" -ne 3 ]", source)


if __name__ == "__main__":
    unittest.main()
