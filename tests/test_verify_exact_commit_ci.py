#!/usr/bin/env python3
from __future__ import annotations

import contextlib
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Optional

from scripts import verify_exact_commit_ci as verifier
from scripts.validate_story_slice_cutover import authority_graph_digest as cutover_graph_digest


ROOT = Path(__file__).resolve().parents[1]
BASELINE_BRANCH = "speakeasy-20260705"
CANDIDATE_BRANCH = "candidate/pr-003"


class ExactCommitCIWorkflowWiringTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")

    def test_pull_request_checks_the_merge_result(self) -> None:
        self.assertNotIn("github.event.pull_request.head.sha", self.workflow)
        self.assertIn(
            "CANDIDATE_SHA: ${{ github.event_name == 'workflow_dispatch' && inputs.candidate_sha || github.sha }}",
            self.workflow,
        )

    def test_dispatch_initializes_rejected_attestation_before_checkout(self) -> None:
        initialize = self.workflow.index("- name: Initialize rejected exact-commit attestation")
        checkout = self.workflow.index("- name: Checkout declared candidate")
        upload = self.workflow.index("- name: Upload exact-commit attestation")
        self.assertLess(initialize, checkout)
        self.assertLess(checkout, upload)
        self.assertIn('"result": "rejected"', self.workflow)
        self.assertIn("if-no-files-found: error", self.workflow)


class ExactCommitCISanitizationTest(unittest.TestCase):
    def test_remote_credentials_and_query_are_not_attested(self) -> None:
        sanitized = verifier._sanitize_remote_url(
            "https://ci-user:top-secret@example.invalid/org/repo.git?token=also-secret"
        )
        self.assertEqual("https://example.invalid/org/repo.git", sanitized)


class ExactCommitCIFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.temp = Path(self.temporary.name)
        self.remote = self.temp / "remote.git"
        self.root = self.temp / "work"
        self.state = self.temp / "state.json"
        self.attestation = self.temp / "attestation.json"

        self.run_git(self.temp, "init", "--bare", str(self.remote))
        self.run_git(self.temp, "init", str(self.root))
        self.run_git(self.root, "config", "user.email", "ci-fixture@example.invalid")
        self.run_git(self.root, "config", "user.name", "CI Fixture")
        self.run_git(self.root, "remote", "add", "origin", str(self.remote))
        self.write_authority_graph("baseline")
        self.run_git(self.root, "add", ".")
        self.run_git(self.root, "commit", "-m", "baseline")
        self.run_git(self.root, "branch", "-M", BASELINE_BRANCH)
        self.run_git(self.root, "push", "-u", "origin", BASELINE_BRANCH)
        self.base_sha = self.git_output(self.root, "rev-parse", "HEAD")

        self.run_git(self.root, "checkout", "-b", CANDIDATE_BRANCH)
        policy = self.root / "docs/process/governance/policy.json"
        policy.write_text('{"policy":"candidate"}\n', encoding="utf-8")
        self.run_git(self.root, "add", str(policy.relative_to(self.root)))
        self.run_git(self.root, "commit", "-m", "candidate")
        self.run_git(self.root, "push", "-u", "origin", CANDIDATE_BRANCH)
        self.candidate_sha = self.git_output(self.root, "rev-parse", "HEAD")

    def run_git(self, cwd: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *args],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=check,
        )

    def git_output(self, cwd: Path, *args: str) -> str:
        return self.run_git(cwd, *args).stdout.strip()

    def write_authority_graph(self, policy_value: str) -> None:
        governance = self.root / "docs/process/governance"
        (governance / "artifacts").mkdir(parents=True, exist_ok=True)
        (governance / "gates").mkdir(parents=True, exist_ok=True)
        index = {
            "schema_version": "1.0",
            "status": "candidate",
            "policy": "policy.json",
            "actor_registry": "actors.json",
            "exchange_registry": "exchanges.json",
            "artifact_routes": {"FIXTURE": "artifacts/core.json"},
            "gate_routes": {"G-FIXTURE": "gates/core.json"},
            "intent_registry": "intents.json",
            "exception_registry": "exceptions.json",
        }
        (governance / "index.json").write_text(json.dumps(index), encoding="utf-8")
        (governance / "policy.json").write_text(
            json.dumps({"policy": policy_value}), encoding="utf-8"
        )
        for name in ("actors.json", "exchanges.json", "intents.json", "exceptions.json"):
            (governance / name).write_text('{"items":[]}\n', encoding="utf-8")
        (governance / "artifacts/core.json").write_text(
            '{"artifacts":[{"artifact_id":"FIXTURE"}]}\n', encoding="utf-8"
        )
        (governance / "gates/core.json").write_text(
            '{"gates":[{"gate_id":"G-FIXTURE"}]}\n', encoding="utf-8"
        )

    def invoke(self, *args: str) -> tuple[int, str]:
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            result = verifier.main(list(args))
        return result, output.getvalue()

    def start_args(
        self,
        *,
        candidate_sha: Optional[str] = None,
        base_sha: Optional[str] = None,
        branch: str = CANDIDATE_BRANCH,
    ) -> list[str]:
        return [
            "start",
            "--root",
            str(self.root),
            "--state-file",
            str(self.state),
            "--candidate-sha",
            candidate_sha or self.candidate_sha,
            "--base-sha",
            base_sha or self.base_sha,
            "--candidate-branch",
            branch,
            "--remote",
            "origin",
            "--event-name",
            "workflow_dispatch",
            "--repository",
            "fixture/SpeakEasy",
            "--workflow-name",
            "CI",
            "--workflow-run-id",
            "1001",
            "--workflow-run-attempt",
            "1",
            "--required-check",
            "governance",
            "--required-check",
            "application",
        ]

    def start(self) -> None:
        result, output = self.invoke(*self.start_args())
        self.assertEqual(0, result, output)

    def checkpoint(self, name: str) -> tuple[int, str]:
        return self.invoke(
            "checkpoint",
            "--root",
            str(self.root),
            "--state-file",
            str(self.state),
            "--name",
            name,
        )

    def prepare_finalization(self) -> None:
        self.start()
        for name in ("after-governance", "after-application"):
            result, output = self.checkpoint(name)
            self.assertEqual(0, result, output)

    def finalize(self, *checks: str) -> tuple[int, str]:
        args = [
            "finalize",
            "--root",
            str(self.root),
            "--state-file",
            str(self.state),
            "--attestation-file",
            str(self.attestation),
        ]
        for check in checks:
            args.extend(("--check", check))
        return self.invoke(*args)

    def test_wrong_candidate_branch_is_rejected(self) -> None:
        result, output = self.invoke(*self.start_args(branch="candidate/wrong"))
        self.assertEqual(1, result)
        self.assertIn("must expose exactly one refs/heads/candidate/wrong", output)

    def test_wrong_checkout_head_is_rejected(self) -> None:
        self.run_git(self.root, "checkout", BASELINE_BRANCH)
        result, output = self.invoke(*self.start_args())
        self.assertEqual(1, result)
        self.assertIn("checkout HEAD does not match candidate SHA", output)

    def test_protected_baseline_drift_is_rejected(self) -> None:
        self.run_git(self.root, "checkout", BASELINE_BRANCH)
        marker = self.root / "baseline-drift.txt"
        marker.write_text("drift\n", encoding="utf-8")
        self.run_git(self.root, "add", marker.name)
        self.run_git(self.root, "commit", "-m", "baseline drift")
        self.run_git(self.root, "push", "origin", BASELINE_BRANCH)
        self.run_git(self.root, "checkout", CANDIDATE_BRANCH)
        result, output = self.invoke(*self.start_args())
        self.assertEqual(1, result)
        self.assertIn("protected baseline drift", output)

    def test_non_fast_forward_candidate_is_rejected(self) -> None:
        self.run_git(self.root, "checkout", "--orphan", "replacement-baseline")
        self.run_git(self.root, "rm", "-rf", ".")
        self.write_authority_graph("replacement")
        self.run_git(self.root, "add", ".")
        self.run_git(self.root, "commit", "-m", "replacement baseline")
        replacement_sha = self.git_output(self.root, "rev-parse", "HEAD")
        self.run_git(
            self.root,
            "push",
            "--force",
            "origin",
            f"HEAD:refs/heads/{BASELINE_BRANCH}",
        )
        self.run_git(self.root, "checkout", CANDIDATE_BRANCH)
        result, output = self.invoke(*self.start_args(base_sha=replacement_sha))
        self.assertEqual(1, result)
        self.assertIn("not a fast-forward descendant", output)

    def test_checkout_drift_is_rejected_at_checkpoint(self) -> None:
        self.start()
        self.run_git(self.root, "checkout", BASELINE_BRANCH)
        result, output = self.checkpoint("after-governance")
        self.assertEqual(1, result)
        self.assertIn("checkout HEAD drift", output)

    def test_missing_required_check_writes_rejected_attestation(self) -> None:
        self.prepare_finalization()
        result, output = self.finalize("governance=success")
        self.assertEqual(1, result)
        self.assertIn("missing=application", output)
        data = json.loads(self.attestation.read_text(encoding="utf-8"))
        self.assertEqual("rejected", data["result"])
        self.assertEqual("missing", data["required_checks"][1]["result"])

    def test_failed_required_check_writes_rejected_attestation(self) -> None:
        self.prepare_finalization()
        result, output = self.finalize("governance=success", "application=failure")
        self.assertEqual(1, result)
        self.assertIn("failed=application", output)
        data = json.loads(self.attestation.read_text(encoding="utf-8"))
        self.assertEqual("rejected", data["result"])

    def test_authority_graph_digest_drift_is_rejected(self) -> None:
        self.start()
        policy = self.root / "docs/process/governance/policy.json"
        policy.write_text('{"policy":"drift"}\n', encoding="utf-8")
        result, output = self.checkpoint("after-governance")
        self.assertEqual(1, result)
        self.assertIn("authority graph digest drift", output)

    def test_attestation_sha_mismatch_is_rejected(self) -> None:
        self.prepare_finalization()
        result, output = self.finalize("governance=success", "application=success")
        self.assertEqual(0, result, output)
        data = json.loads(self.attestation.read_text(encoding="utf-8"))
        data["candidate"]["sha"] = self.base_sha
        self.attestation.write_text(json.dumps(data), encoding="utf-8")
        result, output = self.invoke(
            "verify-attestation",
            "--attestation-file",
            str(self.attestation),
            "--candidate-sha",
            self.candidate_sha,
            "--base-sha",
            self.base_sha,
            "--require-pass",
        )
        self.assertEqual(1, result)
        self.assertIn("checkpoint SHA does not match", output)

    def test_valid_run_emits_bound_pass_attestation(self) -> None:
        self.prepare_finalization()
        result, output = self.finalize("governance=success", "application=success")
        self.assertEqual(0, result, output)
        data = json.loads(self.attestation.read_text(encoding="utf-8"))
        self.assertEqual("pass", data["result"])
        self.assertEqual(self.candidate_sha, data["candidate"]["sha"])
        self.assertEqual(self.base_sha, data["rollback_target"])
        self.assertEqual(verifier.BASELINE_REF, data["baseline"]["ref"])
        self.assertEqual("workflow_dispatch", data["event"]["name"])
        self.assertEqual(cutover_graph_digest(self.root), data["authority_graph"]["digest"])
        self.assertEqual(
            ["start", "after-governance", "after-application"],
            [item["name"] for item in data["checkpoints"]],
        )
        result, output = self.invoke(
            "verify-attestation",
            "--attestation-file",
            str(self.attestation),
            "--candidate-sha",
            self.candidate_sha,
            "--base-sha",
            self.base_sha,
            "--require-pass",
            "--root",
            str(self.root),
        )
        self.assertEqual(0, result, output)

    def test_activation_assertion_requires_separate_approval(self) -> None:
        self.prepare_finalization()
        result, output = self.finalize("governance=success", "application=success")
        self.assertEqual(0, result, output)
        self.run_git(
            self.root,
            "push",
            "origin",
            f"{self.candidate_sha}:refs/heads/{BASELINE_BRANCH}",
        )
        result, output = self.invoke(
            "assert-activation",
            "--root",
            str(self.root),
            "--attestation-file",
            str(self.attestation),
            "--remote",
            "origin",
            "--candidate-sha",
            self.candidate_sha,
            "--base-sha",
            self.base_sha,
        )
        self.assertEqual(1, result)
        self.assertIn("separate baseline-activation approval record is required", output)
        active_before = self.git_output(
            self.root, "ls-remote", "--refs", "origin", verifier.BASELINE_REF
        )
        result, output = self.invoke(
            "assert-activation",
            "--root",
            str(self.root),
            "--attestation-file",
            str(self.attestation),
            "--remote",
            "origin",
            "--candidate-sha",
            self.candidate_sha,
            "--base-sha",
            self.base_sha,
            "--approval-record",
            "fixture-approved-separately",
        )
        self.assertEqual(0, result, output)
        active_after = self.git_output(
            self.root, "ls-remote", "--refs", "origin", verifier.BASELINE_REF
        )
        self.assertEqual(active_before, active_after)


if __name__ == "__main__":
    unittest.main()
