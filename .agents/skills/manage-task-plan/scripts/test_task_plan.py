#!/usr/bin/env python3
"""Regression tests for task_plan.py."""

from __future__ import annotations

import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("task_plan.py")


def replace_section(path: Path, heading: str, content: str) -> None:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(rf"(?ms)(^## {re.escape(heading)}\s*\n).*?(?=^## |\Z)")
    updated, count = pattern.subn(rf"\1\n{content.strip()}\n\n", text, count=1)
    if count != 1:
        raise AssertionError(f"Missing section {heading} in {path}")
    path.write_text(updated, encoding="utf-8", newline="\n")


def replace_metadata(path: Path, key: str, value: str) -> None:
    text = path.read_text(encoding="utf-8")
    updated, count = re.subn(rf"(?m)^{re.escape(key)}:.*$", f"{key}: {value}", text, count=1)
    if count != 1:
        raise AssertionError(f"Missing metadata {key} in {path}")
    path.write_text(updated, encoding="utf-8", newline="\n")


class TaskPlanCliTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.workspace = Path(self.temp.name)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_cli(self, *args: str, expected: int = 0) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--workspace", str(self.workspace), *args],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(expected, result.returncode, msg=result.stdout + result.stderr)
        return result

    def init_task(self, task_id: str = "task-governance") -> Path:
        self.run_cli(
            "init",
            "--task-id",
            task_id,
            "--title",
            "Governance change",
            "--pr",
            "Define contract",
            "--pr",
            "Update validator",
        )
        return self.workspace / ".codex" / "task-plans" / task_id

    def fill_plan(self, task_dir: Path) -> None:
        plan = task_dir / "plan.md"
        values = {
            "Goal": "Deliver the approved governance change.",
            "Success Criteria": "- [ ] Contract and validator agree.\n- [ ] All checks pass.",
            "Scope": "In: the named governance contract. Out: product behavior.",
            "Constraints": "Execute one approved PR unit at a time.",
            "Cross-PR Dependencies": "PR-002 depends on the accepted PR-001 contract.",
            "Overall Verification": "`python scripts/validate_agent_skills.py` exits 0.",
            "Current Summary": "Plan drafted; no implementation started.",
        }
        for heading, content in values.items():
            replace_section(plan, heading, content)
        for pr_path in sorted((task_dir / "prs").glob("PR-*.md")):
            pr_id = pr_path.stem
            pr_values = {
                "Objective": f"Deliver {pr_id} as one reviewable result.",
                "Included Scope": "Only the paths named in this card.",
                "Excluded Scope": "No product behavior changes.",
                "Allowed Paths": f"`.tmp/{pr_id.lower()}.md`",
                "Acceptance Criteria": "- [ ] Target artifact is valid.",
                "Verification Commands": "`python -m unittest` exits 0.",
                "Governance and Review Requirements": "Manual opposing review required.",
                "Current State": "Not started.",
                "Blockers": "None.",
                "Next Action": f"Request approval for {pr_id}.",
            }
            for heading, content in pr_values.items():
                replace_section(pr_path, heading, content)
        replace_metadata(task_dir / "prs" / "PR-002.md", "depends_on", "PR-001")

    def submit_and_approve_plan(self, task_dir: Path) -> None:
        self.fill_plan(task_dir)
        self.run_cli("transition", task_dir.name, "--target", "task", "--to", "awaiting_approval")
        self.run_cli("approve-plan", task_dir.name)

    def add_evidence(self, task_dir: Path, pr_id: str) -> None:
        replace_section(task_dir / "prs" / f"{pr_id}.md", "Evidence", "`validator` exited 0.")
        replace_section(task_dir / "prs" / f"{pr_id}.md", "Next Action", "Wait for user acceptance.")

    def test_plan_and_pr_approval_gates(self) -> None:
        task_dir = self.init_task()
        self.run_cli("validate", task_dir.name)
        self.run_cli("approve-plan", task_dir.name, expected=2)
        self.run_cli(
            "transition", task_dir.name, "--target", "task", "--to", "awaiting_approval", expected=2
        )

        self.submit_and_approve_plan(task_dir)
        self.run_cli("approve-pr", task_dir.name, "PR-002", expected=2)
        self.run_cli("approve-pr", task_dir.name, "PR-001")
        self.run_cli("approve-pr", task_dir.name, "PR-002", expected=2)
        self.run_cli(
            "transition", task_dir.name, "--target", "PR-001", "--to", "awaiting_acceptance", expected=2
        )

        self.add_evidence(task_dir, "PR-001")
        self.run_cli("transition", task_dir.name, "--target", "PR-001", "--to", "awaiting_acceptance")
        self.run_cli("transition", task_dir.name, "--target", "PR-001", "--to", "completed")
        self.run_cli("approve-pr", task_dir.name, "PR-002")
        self.add_evidence(task_dir, "PR-002")
        self.run_cli("transition", task_dir.name, "--target", "PR-002", "--to", "awaiting_acceptance")
        self.run_cli("transition", task_dir.name, "--target", "PR-002", "--to", "completed")

        self.run_cli("transition", task_dir.name, "--target", "task", "--to", "completed", expected=2)
        replace_section(task_dir / "plan.md", "Overall Evidence", "All PR units accepted; validator exited 0.")
        self.run_cli("transition", task_dir.name, "--target", "task", "--to", "completed")
        self.run_cli("validate", task_dir.name)
        result = self.run_cli("resume", task_dir.name)
        self.assertIn("Approval gate: NONE", result.stdout)

    def test_revision_clears_approval(self) -> None:
        task_dir = self.init_task()
        self.submit_and_approve_plan(task_dir)
        self.run_cli("approve-pr", task_dir.name, "PR-001")
        self.run_cli("revise-pr", task_dir.name, "PR-001")
        text = (task_dir / "prs" / "PR-001.md").read_text(encoding="utf-8")
        self.assertIn("revision: 2", text)
        self.assertRegex(text, r"(?m)^approved_revision:\s*$")
        self.assertIn("status: planned", text)
        self.run_cli("validate", task_dir.name)

    def test_resume_requires_unambiguous_task(self) -> None:
        first = self.init_task("task-one")
        self.run_cli(
            "init",
            "--task-id",
            "task-two",
            "--title",
            "Second task",
            "--pr",
            "Only PR",
        )
        self.run_cli("resume", expected=2)
        result = self.run_cli("resume", first.name)
        self.assertIn("Approval gate: PLAN_DEVELOPMENT", result.stdout)


if __name__ == "__main__":
    unittest.main()
