from __future__ import annotations

import importlib.util
import sys
import unittest
from io import StringIO
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/audit_phone_identity_subjects.py"
SPEC = importlib.util.spec_from_file_location("audit_phone_identity_subjects", SCRIPT)
assert SPEC is not None
audit = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules["audit_phone_identity_subjects"] = audit
SPEC.loader.exec_module(audit)


class PhoneIdentitySubjectAuditTest(unittest.TestCase):
    def test_audit_classifies_e164_default_region_and_unsupported_subjects(self) -> None:
        csv_data = StringIO(
            """auth_identity_id,user_id,provider,provider_subject,status
a1,u1,phone,+8613800138000,active
a2,u2,phone,13800138001,active
a3,u3,phone,+15550001001,active
a4,u4,apple,raw-token,active
a5,u5,phone,not-a-phone,active
"""
        )

        rows = audit.read_rows(csv_data)
        results = audit.audit_rows(rows, "CN", {"CN"})
        by_id = {result.row.auth_identity_id: result for result in results}

        self.assertEqual(len(results), 4)
        self.assertEqual(by_id["a1"].action, "already_e164")
        self.assertEqual(by_id["a2"].normalized_subject, "+8613800138001")
        self.assertEqual(by_id["a2"].action, "normalize_default_region")
        self.assertEqual(by_id["a3"].action, "unsupported_country")
        self.assertEqual(by_id["a5"].action, "invalid_format")

    def test_conflict_detection_blocks_multiple_users_for_same_normalized_subject(self) -> None:
        rows = [
            audit.PhoneIdentityRow("a1", "u1", "phone", "+8613800138000", "active"),
            audit.PhoneIdentityRow("a2", "u2", "phone", "13800138000", "active"),
        ]

        results = audit.audit_rows(rows, "CN", {"CN"})
        report = audit.render_markdown(results, "CN", {"CN"})

        self.assertEqual(audit.conflict_keys(results), {"+8613800138000"})
        self.assertEqual(audit.conflict_reason("+8613800138000", results), "cross_user_ownership_conflict")
        self.assertIn("rows in normalized-subject conflicts | 2", report)
        self.assertIn("Result: `blocked`", report)

    def test_conflict_detection_blocks_same_user_unique_key_duplicate(self) -> None:
        rows = [
            audit.PhoneIdentityRow("a1", "u1", "phone", "+8613800138000", "active"),
            audit.PhoneIdentityRow("a2", "u1", "phone", "13800138000", "active"),
        ]

        results = audit.audit_rows(rows, "CN", {"CN"})
        report = audit.render_markdown(results, "CN", {"CN"})

        self.assertEqual(audit.conflict_keys(results), {"+8613800138000"})
        self.assertEqual(audit.conflict_reason("+8613800138000", results), "same_user_unique_key_duplicate")
        self.assertIn("same_user_unique_key_duplicate", report)
        self.assertIn("Result: `blocked`", report)

    def test_missing_required_csv_columns_fails(self) -> None:
        with self.assertRaises(ValueError):
            audit.read_rows(StringIO("provider,provider_subject\nphone,+8613800138000\n"))


if __name__ == "__main__":
    unittest.main()
