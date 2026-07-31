from __future__ import annotations

import runpy
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VALIDATE = runpy.run_path(
    ROOT / ".agents/skills/story-map-develop/scripts/validate_story_map.py",
    run_name="story_map_skill_validator",
)["validate"]


class StoryMapSkillValidationTest(unittest.TestCase):
    def fixture(self, vertical_slice_id: str, affected: str = "`CAP-Z`") -> tuple[Path, Path, tempfile.TemporaryDirectory]:
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        registry = root / "feature_registry.md"
        registry.write_text(
            "\n".join(
                (
                    "| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |",
                    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
                    "| `CAP-A` | `a` | A | type | Product Manager | Active | owns | excludes | outcome | — | `A` | none |",
                    "| `CAP-Z` | `z` | Z | type | Product Manager | Active | owns | excludes | outcome | — | `Z` | none |",
                )
            ),
            encoding="utf-8",
        )
        story_map = root / "user_story_CAP_A.md"
        story_map.write_text(
            "\n".join(
                (
                    "## 1. A（CAP-A / a）",
                    "| Id | description | Status | Primary Capability ID | Affected Capability IDs |",
                    "| --- | --- | --- | --- | --- |",
                    "| `US-A-001` | story | `draft` | `CAP-A` | `none` |",
                    f"| `{vertical_slice_id}` | slice | `draft` | `CAP-A` | {affected} |",
                )
            ),
            encoding="utf-8",
        )
        return story_map, registry, temp

    def test_accepts_story_grouped_slice_and_non_adjacent_registered_impact(self) -> None:
        story_map, registry, temp = self.fixture("VS-A-001-1")
        self.addCleanup(temp.cleanup)

        self.assertEqual([], VALIDATE([story_map], registry, {"CAP-A"}))

    def test_rejects_grouped_slice_that_does_not_match_parent_story_number(self) -> None:
        story_map, registry, temp = self.fixture("VS-A-002-1")
        self.addCleanup(temp.cleanup)

        errors = VALIDATE([story_map], registry, {"CAP-A"})

        self.assertTrue(any("does not match parent US-A-001" in error for error in errors))

    def test_rejects_simple_slice_id(self) -> None:
        story_map, registry, temp = self.fixture("VS-A-001")
        self.addCleanup(temp.cleanup)

        errors = VALIDATE([story_map], registry, {"CAP-A"})

        self.assertTrue(any("invalid Story/Slice ID VS-A-001" in error for error in errors))

    def test_rejects_non_contiguous_child_number(self) -> None:
        story_map, registry, temp = self.fixture("VS-A-001-2")
        self.addCleanup(temp.cleanup)

        errors = VALIDATE([story_map], registry, {"CAP-A"})

        self.assertTrue(any("expected contiguous value 1" in error for error in errors))

    def test_rejects_unknown_affected_capability(self) -> None:
        story_map, registry, temp = self.fixture("VS-A-001-1", "`CAP-X`")
        self.addCleanup(temp.cleanup)

        errors = VALIDATE([story_map], registry, {"CAP-A"})

        self.assertTrue(any("uses unknown capability CAP-X" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
