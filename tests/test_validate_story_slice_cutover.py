from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_story_slice_cutover import (  # noqa: E402
    authority_graph_digest,
    collect_candidate_authority_graph,
    collect_current_definition_paths,
    validate_cutover,
)


class StorySliceCutoverValidationTest(unittest.TestCase):
    def fixture(self) -> tuple[tempfile.TemporaryDirectory, Path]:
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        required = set(collect_candidate_authority_graph(ROOT))
        required.update(
            ROOT / relative for relative in (
                "docs/architecture/adr/0007-story-slice-led-delivery.md",
                "docs/product/story_map.md",
            )
        )
        for source in required:
            target = root / source.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        return temp, root

    def test_repository_cutover_is_complete(self) -> None:
        errors, metrics = validate_cutover(ROOT)
        self.assertEqual([], errors)
        self.assertGreater(metrics["authority_graph_files"], 20)
        self.assertEqual(64, len(metrics["authority_graph_digest"]))

    def test_graph_is_route_derived_and_excludes_historical_state(self) -> None:
        graph = {path.relative_to(ROOT).as_posix() for path in collect_candidate_authority_graph(ROOT)}
        self.assertIn("docs/process/governance/index.json", graph)
        self.assertIn(".agents/skills/requirement-refine/SKILL.md", graph)
        self.assertIn(".codex/agents/backend.toml", graph)
        self.assertIn(
            ".agents/skills/capability-registry-develop/references/structural-change-gates.md",
            graph,
        )
        self.assertNotIn("docs/product/user_stories.md", graph)
        self.assertFalse(any(path.startswith(".codex/task-plans/") for path in graph))
        self.assertFalse(any("feature-spec-generate" in path for path in graph))

    def test_current_definitions_are_derived_from_actors_methods_and_direct_links(self) -> None:
        definitions = {
            path.relative_to(ROOT).as_posix()
            for path in collect_current_definition_paths(ROOT)
        }
        self.assertIn(".codex/agents/product_manager.toml", definitions)
        self.assertIn(".agents/skills/requirement-refine/SKILL.md", definitions)
        self.assertIn(
            ".agents/skills/capability-registry-develop/references/structural-change-gates.md",
            definitions,
        )
        self.assertNotIn("docs/product/user_stories.md", definitions)

    def test_digest_changes_for_active_definition(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        before = authority_graph_digest(root)
        path = root / ".agents/skills/requirement-refine/SKILL.md"
        path.write_text(path.read_text(encoding="utf-8") + "\n", encoding="utf-8")
        self.assertNotEqual(before, authority_graph_digest(root))

    def test_retired_route_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/process/governance/index.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        data["artifact_routes"]["PRODUCT_BASE_SPEC"] = "artifacts/product.json"
        path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("retired Artifact remains routed" in error for error in errors))

    def test_active_legacy_pointer_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/process/workflow.md"
        path.write_text(path.read_text(encoding="utf-8") + "\nUse docs/product/base/spec.md as source.\n", encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("retired positive runtime pointer" in error for error in errors))

    def test_authority_copy_in_skill_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / ".agents/skills/requirement-refine/SKILL.md"
        path.write_text(path.read_text(encoding="utf-8") + "\ncanonical path: docs/example.md\n", encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("restate Governance Contract authority" in error for error in errors))

    def test_authority_copy_in_native_agent_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / ".codex/agents/backend.toml"
        text = path.read_text(encoding="utf-8")
        before, closing = text.rsplit('"""', 1)
        path.write_text(before + "canonical path: docs/example.md\n" + '"""' + closing, encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("backend.toml" in error and "restate" in error for error in errors))

    def test_retired_pointer_in_direct_linked_resource_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / ".agents/skills/capability-registry-develop/references/structural-change-gates.md"
        path.write_text(
            path.read_text(encoding="utf-8") + "\nUse docs/product/base/spec.md as current source.\n",
            encoding="utf-8",
        )
        errors, _ = validate_cutover(root)
        self.assertTrue(any("structural-change-gates.md" in error and "retired positive" in error for error in errors))

    def test_adr_optional_fr_current_rule_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/architecture/adr/0007-story-slice-led-delivery.md"
        path.write_text(path.read_text(encoding="utf-8") + "\nFR 是可选。\n", encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("optional current policy" in error for error in errors))

    def test_story_map_legacy_source_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/product/story_map.md"
        text = path.read_text(encoding="utf-8").replace(
            "本文是 User Story", "来源：`docs/product/user_stories.md`。\n\n本文是 User Story", 1,
        )
        path.write_text(text, encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("Story Map header contains retired" in error for error in errors))

    def test_missing_engineering_lineage_marker_is_rejected(self) -> None:
        temp, root = self.fixture()
        self.addCleanup(temp.cleanup)
        path = root / "docs/architecture/system_overview.md"
        path.write_text(path.read_text(encoding="utf-8").replace("PR-003 current lineage", "old lineage", 1), encoding="utf-8")
        errors, _ = validate_cutover(root)
        self.assertTrue(any("system_overview.md lacks" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
