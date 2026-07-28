from __future__ import annotations

import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_story_slice_delivery import discover_story_shards, validate_delivery  # noqa: E402


class StorySliceDeliveryValidationTest(unittest.TestCase):
    def fixture(self) -> tuple[tempfile.TemporaryDirectory, Path]:
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        for relative in (
            "docs/product/functional_requirements.md",
            "docs/quality/test_cases.md", "docs/quality/traceability.md",
            "docs/process/governance/index.json",
            "docs/process/governance/artifacts/engineering.json",
            "docs/process/governance/artifacts/product.json",
        ):
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)
        for source in discover_story_shards(ROOT):
            target = root / source.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        return temp, root

    def test_repository_catalogs_validate(self) -> None:
        errors, metrics = validate_delivery(ROOT)
        self.assertEqual([], errors)
        self.assertEqual(len(discover_story_shards(ROOT)), metrics["story_shards"])
        self.assertEqual(1, metrics["vertical_slices_with_frs"])
        self.assertEqual(1, metrics["fr_tc_coverage"])
        self.assertEqual(1, metrics["vs_tc_coverage"])

    def test_approved_implementing_vs_with_zero_frs_passes(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        fr_path = root / "docs/product/functional_requirements.md"
        fr_path.write_text(
            re.sub(
                r"\n## FR-TRAIN.*?(?=\n## 维护规则)",
                "",
                fr_path.read_text(encoding="utf-8"),
                flags=re.S,
            ),
            encoding="utf-8",
        )
        tc_path = root / "docs/quality/test_cases.md"
        tc_path.write_text(
            re.sub(
                r"## FR-TC.*?(?=## Contract-TC)",
                "## FR-TC\n\n当前没有 FR，因此没有 FR-TC。\n\n",
                tc_path.read_text(encoding="utf-8"),
                flags=re.S,
            ),
            encoding="utf-8",
        )
        (root / "docs/quality/traceability.md").write_text(
            """# Canonical Traceability

- Projection: `derived-read-only`

| Story | Vertical Slice | VS-TC |
| --- | --- | --- |
| `US-TRAIN-001` | `VS-TRAIN-001` | `TC-VS-TRAIN-001` |
""",
            encoding="utf-8",
        )
        errors, metrics = validate_delivery(root)
        self.assertEqual([], errors)
        self.assertEqual(0, metrics["functional_requirements"])
        self.assertEqual(0, metrics["vertical_slices_with_frs"])
        self.assertEqual(0, metrics["fr_tc_coverage"])

    def test_fr_rule_may_contain_multiple_independent_behaviors(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/product/functional_requirements.md"
        text = path.read_text(encoding="utf-8").replace(
            "- Rule: ",
            "- Rule: 系统必须记录一次独立审计事件；",
            1,
        )
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertEqual([], errors)

    def test_existing_fr_requires_rule_content(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/product/functional_requirements.md"
        text = re.sub(r"^- Rule:.*\n", "", path.read_text(encoding="utf-8"), count=1, flags=re.M)
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("FR-TRAIN-001 has no Rule content" in error for error in errors))

    def test_missing_story_shard_breaks_approved_vs_lineage(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        (root / "docs/product/user_stories/user_story_CAP_TRAIN.md").unlink()
        errors, _ = validate_delivery(root)
        self.assertTrue(any("missing or unapproved VS VS-TRAIN-001" in error for error in errors))

    def test_duplicate_id_across_story_shards_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        source = root / "docs/product/user_stories/user_story_CAP_TRAIN.md"
        duplicate = next(
            line for line in source.read_text(encoding="utf-8").splitlines()
            if line.startswith("| `US-TRAIN-001`")
        )
        target = root / "docs/product/user_stories/user_story_CAP_ACC.md"
        target.write_text(target.read_text(encoding="utf-8") + f"\n{duplicate}\n", encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("duplicate Story/Slice ID US-TRAIN-001" in error for error in errors))

    def test_story_shards_do_not_inherit_parent_across_files(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/product/user_stories/user_story_CAP_ACC.md"
        orphan = "| `VS-ACC-999` | orphan | `draft` | `CAP-ACC` | — |"
        text = path.read_text(encoding="utf-8").replace(
            "\n### US-ACC-001", f"\n{orphan}\n\n### US-ACC-001", 1,
        )
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("VS-ACC-999 has no parent User Story" in error for error in errors))

    def test_approved_vs_requires_approved_story_in_its_shard(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/product/user_stories/user_story_CAP_TRAIN.md"
        text = path.read_text(encoding="utf-8").replace(
            "| `approved` | `CAP-TRAIN` |", "| `draft` | `CAP-TRAIN` |", 1,
        )
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("VS-TRAIN-001 has no unique approved Story parent" in error for error in errors))

    def test_fr_requires_direct_approved_vs_lineage(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/product/functional_requirements.md"
        path.write_text(path.read_text(encoding="utf-8").replace("- source_vs_ids: `VS-TRAIN-001`", "- source_story_id: `US-TRAIN-001`"), encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("source_vs_ids" in error for error in errors))
        self.assertTrue(any("second-lineage" in error for error in errors))

    def test_vs_tc_rejects_a_second_fr_edge(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/test_cases.md"
        text = path.read_text(encoding="utf-8").replace(
            "- source_vs_id: `VS-TRAIN-001`", "- source_vs_id: `VS-TRAIN-001`\n- source_fr_id: `FR-TRAIN-001`",
        )
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("only direct edge source_vs_id" in error for error in errors))

    def test_existing_fr_requires_fr_tc(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/test_cases.md"
        path.write_text(
            re.sub(
                r"### TC-FR-TRAIN-001.*?(?=## Contract-TC)",
                "",
                path.read_text(encoding="utf-8"),
                flags=re.S,
            ),
            encoding="utf-8",
        )
        errors, _ = validate_delivery(root)
        self.assertTrue(any("FR-TRAIN-001 has no FR-TC" in error for error in errors))

    def test_traceability_cannot_drop_an_owning_id(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/traceability.md"
        path.write_text(path.read_text(encoding="utf-8").replace("`TC-FR-TRAIN-001`", "`MISSING-FR-TC`"), encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("missing IDs" in error or "lacks FR-TC branch" in error for error in errors))

    def test_tc_catalog_rejects_execution_status(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/test_cases.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "- layer: `widget`", "- layer: `widget`\n- execution_status: passed", 1,
            ),
            encoding="utf-8",
        )
        errors, _ = validate_delivery(root)
        self.assertTrue(any("execution-result" in error for error in errors))

    def test_tc_catalog_rejects_generic_result_field(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/test_cases.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "- layer: `widget`", "- layer: `widget`\n- result: passed", 1,
            ),
            encoding="utf-8",
        )
        errors, _ = validate_delivery(root)
        self.assertTrue(any("execution-result" in error for error in errors))

    def test_approved_story_id_is_required_in_projection(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/traceability.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace("`US-TRAIN-001`", "`US-TRAIN-999`"),
            encoding="utf-8",
        )
        errors, _ = validate_delivery(root)
        self.assertTrue(any("missing IDs" in error and "US-TRAIN-001" in error for error in errors))

    def test_contract_tc_requires_active_engineering_contract_id(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/test_cases.md"
        record = """
### TC-CONTRACT-INVALID-001 — invalid contract source

- type: `Contract-TC`
- source_contract_id: `NOT_A_CONTRACT`
- layer: `contract`
- scope: `invalid`
- selector: `invalid_contract`
- script_path: `tests/invalid_test.py`
- command: `python3 tests/invalid_test.py`
- Given: an invalid contract source.
- When: the case is validated.
- Then: validation blocks it.
- Boundary/negative: inactive IDs are rejected.

"""
        path.write_text(
            path.read_text(encoding="utf-8").replace("## VS-TC", record + "## VS-TC"),
            encoding="utf-8",
        )
        errors, _ = validate_delivery(root)
        self.assertTrue(any("active Engineering Contract Artifact ID" in error for error in errors))

    def test_governance_routes_cover_every_engineering_contract(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/process/governance/artifacts/product.json"
        path.write_text(
            path.read_text(encoding="utf-8").replace('"SYSTEM_OVERVIEW",', ""),
            encoding="utf-8",
        )
        errors, _ = validate_delivery(root)
        self.assertTrue(any("Engineering Contract inputs mismatch" in error for error in errors))

    def test_fr_branch_requires_story_vs_fr_tc_co_location(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/traceability.md"
        text = path.read_text(encoding="utf-8").replace("`US-TRAIN-001`", "`US-TRAIN-999`", 1)
        text += "\nProjection inventory still mentions `US-TRAIN-001`.\n"
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("co-located Story/VS/FR/FR-TC" in error for error in errors))

    def test_vs_branch_requires_vs_tc_co_location(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/quality/traceability.md"
        text = path.read_text(encoding="utf-8").replace(
            "| `VS-TRAIN-001` | `TC-VS-TRAIN-001` |",
            "| `VS-TRAIN-999` | `TC-VS-TRAIN-001` |",
            1,
        )
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_delivery(root)
        self.assertTrue(any("co-located VS/VS-TC" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
