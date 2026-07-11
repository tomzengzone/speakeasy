from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts.validate_capability_registry import validate_registry


VALID_REGISTRY = """# Test Registry

## CAP-A - Alpha

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-A` | `alpha` | Alpha | Test | Product Manager | Active v2 | A | B | Result A | `CAP-B` | `A` | old-a |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-A` | `CAP-A-01` | Alpha one | A1 | B1 | Input A | Output A | `FR-A` | Active v2 |
| `CAP-A` | `CAP-A-02` | Alpha two | A2 | B2 | Input A2 | Output A2 | `FR-A` | Active v2 |

## CAP-B - Beta

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-B` | `beta` | Beta | Test | Product Manager | Active v2 | B | A | Result B | `CAP-A` | `B` | old-b |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-B` | `CAP-B-01` | Beta one | B1 | A1 | Input B | Output B | `FR-B` | Active v2 |

## Legacy Mapping

| V1 slug | V2 mapping | Migration note |
| --- | --- | --- |
| `old-a` | `CAP-A` | Migrated to alpha. |
| `old-platform` | Architecture/SWC/Domain support for `CAP-*` | Historical technical support. |
"""


class CapabilityRegistryValidatorTest(unittest.TestCase):
    def validate_text(self, text: str):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "feature_registry.md"
            path.write_text(text, encoding="utf-8")
            return validate_registry(path)

    def test_valid_registry_passes(self):
        errors, warnings, counts = self.validate_text(VALID_REGISTRY)

        self.assertEqual([], errors)
        self.assertEqual([], warnings)
        self.assertEqual(2, counts["capabilities"])
        self.assertEqual(3, counts["sub_capabilities"])
        self.assertEqual(2, counts["legacy_mappings"])

    def test_header_drift_fails(self):
        errors, _, _ = self.validate_text(VALID_REGISTRY.replace("| Owner |", "| Decision owner |", 1))

        self.assertTrue(any("header mismatch" in error for error in errors))

    def test_duplicate_identity_and_unknown_references_fail(self):
        broken = VALID_REGISTRY.replace("| `CAP-B` | `beta`", "| `CAP-A` | `beta`", 1)
        broken = broken.replace("## CAP-B - Beta", "## CAP-A - Beta", 1)
        broken = broken.replace("| `CAP-A` | `CAP-A-01`", "| `CAP-Z` | `CAP-Z-01`", 1)
        broken = broken.replace("| `old-a` | `CAP-A`", "| `old-a` | `CAP-Z`", 1)
        errors, _, _ = self.validate_text(broken)

        self.assertTrue(any("duplicate Capability ID: CAP-A" in error for error in errors))
        self.assertTrue(any("unknown parent Capability ID: CAP-Z" in error for error in errors))
        self.assertTrue(any("unknown Legacy Mapping Capability ID: CAP-Z" in error for error in errors))

    def test_all_unique_fields_are_enforced(self):
        replacements = {
            "Capability slug": ("| `CAP-B` | `beta`", "| `CAP-B` | `alpha`", "duplicate Capability slug: alpha"),
            "Downstream prefix": ("| `B` | old-b |", "| `A` | old-b |", "duplicate Downstream document prefix: A"),
            "Sub-capability ID": ("`CAP-B-01`", "`CAP-A-01`", "duplicate Sub-capability ID: CAP-A-01"),
            "V1 slug": ("| `old-platform` |", "| `old-a` |", "duplicate V1 slug: old-a"),
        }
        for label, (old, new, expected) in replacements.items():
            with self.subTest(label=label):
                errors, _, _ = self.validate_text(VALID_REGISTRY.replace(old, new, 1))
                self.assertTrue(any(expected in error for error in errors), errors)

    def test_relationship_status_and_prefix_contracts_are_enforced(self):
        cases = {
            "unknown adjacency": ("| `CAP-B` | `A` |", "| `CAP-Z` | `A` |", "unknown adjacent Capability ID: CAP-Z"),
            "malformed adjacency": ("| `CAP-B` | `A` |", "| cap-b | `A` |", "invalid Adjacent capabilities syntax"),
            "parent mismatch": ("`CAP-A-01`", "`CAP-B-02`", "does not match parent CAP-A"),
            "capability status": ("| Active v2 | A |", "| Retired | A |", "unsupported Capability lifecycle status"),
            "sub status": ("| `FR-A` | Active v2 |", "| `FR-A` | Retired |", "unsupported Sub-capability status"),
            "FR prefix": ("| `FR-A` | Active v2 |", "| `FR-Z` | Active v2 |", "does not match FR-A"),
        }
        for label, (old, new, expected) in cases.items():
            with self.subTest(label=label):
                errors, _, _ = self.validate_text(VALID_REGISTRY.replace(old, new, 1))
                self.assertTrue(any(expected in error for error in errors), errors)

    def test_legacy_mapping_requires_complete_known_target_syntax(self):
        cases = {
            "unknown target": ("| `old-a` | `CAP-A` |", "| `old-a` | `CAP-Z` |", "unknown Legacy Mapping Capability ID: CAP-Z"),
            "malformed target": ("| `old-a` | `CAP-A` |", "| `old-a` | `CAP-A`, CAP_UNKNOWN |", "invalid Legacy Mapping target syntax"),
            "unknown support target": ("Architecture/SWC/Domain support for `CAP-*`", "mystery support target", "invalid Legacy Mapping target syntax"),
        }
        for label, (old, new, expected) in cases.items():
            with self.subTest(label=label):
                errors, _, _ = self.validate_text(VALID_REGISTRY.replace(old, new, 1))
                self.assertTrue(any(expected in error for error in errors), errors)

    def test_interrupted_or_duplicate_table_section_fails(self):
        interrupted = VALID_REGISTRY.replace(
            "| `CAP-A` | `CAP-A-02` | Alpha two",
            "\n| `CAP-A` | `CAP-A-02` | Alpha two",
            1,
        )
        errors, _, _ = self.validate_text(interrupted)
        self.assertTrue(any("resume after an interruption" in error for error in errors), errors)

        duplicated = VALID_REGISTRY + "\n## Legacy Mapping\n"
        errors, _, _ = self.validate_text(duplicated)
        self.assertTrue(any("duplicate section ## Legacy Mapping" in error for error in errors), errors)

    def test_read_errors_become_validation_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            invalid_utf8 = Path(directory) / "invalid.md"
            invalid_utf8.write_bytes(b"\xff\xfe")
            errors, _, _ = validate_registry(invalid_utf8)
            self.assertTrue(any("cannot read registry as UTF-8 text" in error for error in errors), errors)

            errors, _, _ = validate_registry(Path(directory))
            self.assertTrue(any("cannot read registry as UTF-8 text" in error for error in errors), errors)

    def test_asymmetric_adjacency_is_warning_only(self):
        registry = VALID_REGISTRY.replace("| `CAP-A` | `B` |", "| none | `B` |", 1)
        errors, warnings, _ = self.validate_text(registry)

        self.assertEqual([], errors)
        self.assertEqual(
            ["asymmetric adjacency requires touched-boundary review: CAP-A -> CAP-B"], warnings
        )

    def test_escaped_pipe_in_text_cell_is_supported(self):
        registry = VALID_REGISTRY.replace("| Alpha | Test |", r"| Alpha \| One | Test |", 1)
        registry = registry.replace("## CAP-A - Alpha", "## CAP-A - Alpha | One", 1)
        errors, _, _ = self.validate_text(registry)

        self.assertEqual([], errors)

    def test_duplicate_adjacency_reference_fails(self):
        registry = VALID_REGISTRY.replace(
            "| `CAP-B` | `A` | old-a |", "| `CAP-B`; `CAP-B` | `A` | old-a |", 1
        )
        errors, _, _ = self.validate_text(registry)

        self.assertTrue(any("duplicate Adjacent capability reference: CAP-B" in error for error in errors), errors)

    def test_unknown_schema_table_section_fails_closed(self):
        registry = VALID_REGISTRY + """

## V2 Successor Mapping

| Retired ID | Successor ID |
| --- | --- |
| `CAP-A` | `CAP-B` |
"""
        errors, _, _ = self.validate_text(registry)

        self.assertTrue(any("unsupported Markdown table section: ## V2 Successor Mapping" in error for error in errors), errors)

    def test_chapter_heading_and_parent_nesting_are_enforced(self):
        heading_mismatch = VALID_REGISTRY.replace("## CAP-A - Alpha", "## CAP-A - Wrong name", 1)
        errors, _, _ = self.validate_text(heading_mismatch)
        self.assertTrue(any("heading does not match Capability row ID/name" in error for error in errors), errors)

        wrong_parent = VALID_REGISTRY.replace(
            "| `CAP-A` | `CAP-A-02` | Alpha two",
            "| `CAP-B` | `CAP-A-02` | Alpha two",
            1,
        )
        errors, _, _ = self.validate_text(wrong_parent)
        self.assertTrue(any("does not match chapter CAP-A" in error for error in errors), errors)

    def test_chapter_subsection_contract_and_flat_tables_fail_closed(self):
        missing_subsection = VALID_REGISTRY.replace("### Level-1 Sub-capabilities", "### Children", 1)
        errors, _, _ = self.validate_text(missing_subsection)
        self.assertTrue(any("subsection order mismatch" in error for error in errors), errors)
        self.assertTrue(any("is missing ### Level-1 Sub-capabilities" in error for error in errors), errors)

        flat_marker = VALID_REGISTRY.replace("## CAP-A - Alpha", "## V2 Capability Table", 1)
        errors, _, _ = self.validate_text(flat_marker)
        self.assertTrue(any("legacy flat Capability/Sub-capability table sections are not allowed" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
