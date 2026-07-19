import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
import sys
sys.path.insert(0, str(SCRIPTS))

from check_governance_write_scope import (
    check_authorized_changes,
    check_paths,
    main as check_write_scope_main,
    parse_governance_metadata,
    validate_content_scope,
)
from validate_governance_contracts import load_toml, validate_repository
from validate_agent_skills import validate_skills


class GovernanceContractValidationTest(unittest.TestCase):
    def copy_governance_fixture(self, target: Path):
        for rel in ["docs/process/governance", ".codex", ".agents/skills", "codex/templates"]:
            shutil.copytree(ROOT / rel, target / rel)
        for rel in [
            ".gitignore",
            "AGENTS.md",
            ".github/workflows/ci.yml",
            "docs/process/workflow.md",
            "docs/process/skill_quality_standard.md",
            "scripts/check_governance_write_scope.py",
            "scripts/validate_agent_skills.py",
            "scripts/validate_governance_contracts.py",
            "tests/test_validate_governance_contracts.py",
        ]:
            destination = target / rel
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, destination)

    def test_repository_contracts_are_valid(self):
        errors, _warnings, metrics = validate_repository(ROOT)
        self.assertEqual([], errors)
        self.assertIn(metrics["governance_status"], {"candidate", "active"})
        self.assertEqual(69, metrics["artifacts"])
        self.assertEqual(14, metrics["gates"])
        self.assertEqual(6, metrics["workflow_exchanges"])
        self.assertEqual(4, metrics["evidence_artifact_references"])
        self.assertGreater(metrics["artifact_validation_commands"], 0)
        self.assertEqual(33, metrics["artifact_required_input_contracts"])
        self.assertEqual(7, metrics["artifact_conditional_input_contracts"])

    def test_invalid_governance_status_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "ready-ish"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("unsupported governance status" in error for error in errors))

    def test_active_status_requires_a_committed_governance_baseline(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("active governance requires a committed Git baseline" in error for error in errors))

    def test_candidate_status_accepts_a_clean_committed_baseline(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "candidate governance baseline"], **git_run)
            errors, _warnings, _metrics = validate_repository(target)
            self.assertEqual([], [error for error in errors if "candidate governance" in error])

    def test_candidate_status_rejects_tracked_cache_files(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            cache = target / "scripts/__pycache__/legacy.pyc"
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(b"cache")
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "add", "-f", cache.relative_to(target).as_posix()], **git_run)
            subprocess.run(["git", "commit", "-qm", "candidate governance baseline with cache"], **git_run)
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("candidate governance HEAD contains tracked cache files" in error for error in errors))

    def test_active_status_accepts_a_committed_baseline_without_retired_paths(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "candidate governance baseline"], **git_run)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            subprocess.run(["git", "add", index.relative_to(target).as_posix()], **git_run)
            subprocess.run(["git", "commit", "-qm", "activate governance baseline"], **git_run)
            errors, _warnings, _metrics = validate_repository(target)
            self.assertEqual([], [error for error in errors if "active governance" in error or "retired runtime" in error])

    def test_active_status_rejects_a_one_step_initial_activation(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "invalid initial activation"], **git_run)
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("committed candidate predecessor" in error for error in errors))

    def test_active_status_rejects_uncommitted_baseline_changes(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "candidate governance baseline"], **git_run)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            subprocess.run(["git", "add", index.relative_to(target).as_posix()], **git_run)
            subprocess.run(["git", "commit", "-qm", "activate governance baseline"], **git_run)
            workflow = target / "docs/process/workflow.md"
            workflow.write_text(workflow.read_text(encoding="utf-8") + "\nUncommitted change.\n", encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("worktree differs from HEAD" in error for error in errors))

    def test_active_status_rejects_an_uncommitted_status_flip(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "candidate governance baseline"], **git_run)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("status must be committed in HEAD" in error for error in errors))
            self.assertTrue(any("worktree differs from HEAD" in error for error in errors))

    def test_active_status_rejects_an_uncommitted_baseline_deletion(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "candidate governance baseline"], **git_run)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            subprocess.run(["git", "add", index.relative_to(target).as_posix()], **git_run)
            subprocess.run(["git", "commit", "-qm", "activate governance baseline"], **git_run)
            (target / ".codex/agents/backend.toml").unlink()
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("worktree differs from HEAD" in error for error in errors))

    def test_active_status_rejects_a_retired_interface_left_in_head(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            retired = target / "scripts/project_agent_runner.py"
            retired.write_text("# retired\n", encoding="utf-8")
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "commit", "-qm", "incomplete governance baseline"], **git_run)
            retired.unlink()
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("HEAD contains retired runtime interfaces" in error for error in errors))

    def test_active_status_rejects_tracked_cache_files(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["status"] = "active"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            cache = target / "scripts/__pycache__/legacy.pyc"
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(b"cache")
            git_run = {
                "cwd": target,
                "check": True,
                "stdout": subprocess.DEVNULL,
                "stderr": subprocess.DEVNULL,
            }
            subprocess.run(["git", "init", "-q"], **git_run)
            subprocess.run(["git", "config", "user.email", "governance-test@example.invalid"], **git_run)
            subprocess.run(["git", "config", "user.name", "Governance Test"], **git_run)
            subprocess.run(["git", "add", "."], **git_run)
            subprocess.run(["git", "add", "-f", cache.relative_to(target).as_posix()], **git_run)
            subprocess.run(["git", "commit", "-qm", "governance baseline with cache"], **git_run)
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("HEAD contains tracked cache files" in error for error in errors))

    def test_retired_runtime_interfaces_are_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            retired_paths = [
                "scripts/project_agent_runner.py",
                "scripts/run_governance_ab.py",
                "codex/agents/backend.md",
                "codex/templates/agent_runner_packet.template.md",
                "codex/templates/pm_orchestrator_brief.template.md",
                ".agents/skills/code-review-quality/SPEC.md",
                "docs/process/governance/ab_corpus.json",
            ]
            for relative in retired_paths:
                retired = target / relative
                retired.parent.mkdir(parents=True, exist_ok=True)
                retired.write_text("# retired\n", encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            for relative in retired_paths:
                self.assertTrue(any(f"retired runtime interface exists: {relative}" in error for error in errors))

    def test_artifact_defaults_have_no_checker_evidence_or_output_side_effects(self):
        for shard in (ROOT / "docs/process/governance/artifacts").glob("*.json"):
            data = json.loads(shard.read_text(encoding="utf-8"))
            defaults = data["defaults"]
            self.assertNotIn("checker", defaults, shard)
            self.assertNotIn("evidence_location", defaults, shard)
            self.assertNotIn("persistent_outputs", defaults, shard)
            self.assertNotIn("ephemeral_outputs", defaults, shard)
            self.assertNotIn("required_direct_inputs", defaults, shard)
            self.assertNotIn("conditional_inputs", defaults, shard)
            for artifact in data["artifacts"]:
                self.assertNotIn("persistent_outputs", artifact, artifact.get("artifact_id"))

    def test_artifact_side_effectful_defaults_are_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            engineering = target / "docs/process/governance/artifacts/engineering.json"
            data = json.loads(engineering.read_text(encoding="utf-8"))
            data["defaults"].update({
                "checker": "software-architecture-governance-check",
                "evidence_location": "docs/reports/quality_report.md",
                "persistent_outputs": ["$self"],
                "ephemeral_outputs": [],
                "required_direct_inputs": [],
                "conditional_inputs": [],
            })
            engineering.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            for field in ["checker", "evidence_location", "persistent_outputs", "ephemeral_outputs"]:
                self.assertTrue(any(f"forbidden Artifact field {field}" in error for error in errors))
            self.assertTrue(any("must not default input arrays" in error for error in errors))

    def test_artifact_rows_reject_legacy_checker_evidence_and_output_fields(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            engineering = target / "docs/process/governance/artifacts/engineering.json"
            data = json.loads(engineering.read_text(encoding="utf-8"))
            data["artifacts"][0].update({
                "checker": "software-architecture-governance-check",
                "evidence_location": "docs/reports/quality_report.md",
                "persistent_outputs": ["$self"],
                "ephemeral_outputs": ["legacy handoff"],
            })
            engineering.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            for field in ["checker", "evidence_location", "persistent_outputs", "ephemeral_outputs"]:
                self.assertTrue(any(f"forbidden Artifact field {field}" in error for error in errors))

    def test_independent_check_maps_every_trigger_to_a_read_only_checker(self):
        gates = json.loads((ROOT / "docs/process/governance/gates/core.json").read_text(encoding="utf-8"))["gates"]
        gate = next(item for item in gates if item["gate_id"] == "G-INDEPENDENT-CHECK")
        triggers = {value.removesuffix("=true") for value in gate["applicability"]["any"]}
        selector = gate["evidence_contract"]["checker_selector"]
        mapping = selector["by_trigger"]
        self.assertEqual(triggers, set(mapping))
        self.assertEqual(
            {"product-object-governance-check", "software-architecture-governance-check"},
            set(mapping.values()),
        )
        self.assertEqual(
            {
                "CAPABILITY_REGISTRY",
                "STORY_MAP",
                "CROSS_CUTTING_BOUNDARY_REGISTRY",
                "SWC_GOVERNANCE",
                "INCREMENT_SWC_ALLOCATION",
            },
            set(selector["by_artifact_id"]),
        )
        self.assertIn("ephemeral by default", gate["evidence_contract"]["persistence"])

    def test_artifact_validation_gate_resolves_intrinsic_commands_once(self):
        gates = json.loads((ROOT / "docs/process/governance/gates/core.json").read_text(encoding="utf-8"))["gates"]
        validation_gate = next(item for item in gates if item["gate_id"] == "G-ARTIFACT-VALIDATION")
        contract_gate = next(item for item in gates if item["gate_id"] == "G-CONTRACT")
        self.assertIn("Artifact.validation_command", validation_gate["machine_check"])
        self.assertEqual("artifact://impacted/validation_command", validation_gate["evidence_command"])
        self.assertEqual("ephemeral", validation_gate["evidence_contract"]["persistence"])
        self.assertIsNone(contract_gate["machine_check"])
        self.assertIsNone(contract_gate["evidence_command"])

    def test_unknown_gate_evidence_artifact_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            gates = target / "docs/process/governance/gates/core.json"
            data = json.loads(gates.read_text(encoding="utf-8"))
            test_gate = next(item for item in data["gates"] if item["gate_id"] == "G-TEST")
            test_gate["evidence_contract"]["evidence_artifact_id"] = "UNKNOWN_REPORT"
            gates.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("unknown evidence Artifact UNKNOWN_REPORT" in error for error in errors))

    def test_read_only_checker_cannot_own_evidence_artifact(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            governance = target / "docs/process/governance/artifacts/governance.json"
            data = json.loads(governance.read_text(encoding="utf-8"))
            report = next(item for item in data["artifacts"] if item["artifact_id"] == "QUALITY_REPORT")
            report["accountable_owner"] = "evidence-reviewer"
            governance.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("cannot be owned by read-only checker evidence-reviewer" in error for error in errors))

    def test_incomplete_gate_contract_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            gates = target / "docs/process/governance/gates/core.json"
            data = json.loads(gates.read_text(encoding="utf-8"))
            del data["gates"][0]["result_levels"]
            data["gates"][0]["evidence_contract"]["required_fields"] = []
            gates.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("missing fields" in error and "result_levels" in error for error in errors))
            self.assertTrue(any("requires non-empty unique required_fields" in error for error in errors))

    def test_invalid_workflow_exchange_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            exchanges = target / "docs/process/governance/exchanges.json"
            data = json.loads(exchanges.read_text(encoding="utf-8"))
            exchange = data["exchanges"][0]
            exchange["producer"] = "unknown-actor"
            exchange["source_artifacts"] = ["UNKNOWN_ARTIFACT"]
            exchange["lifecycle"] = "persistent"
            exchange["canonical_path"] = "docs/reports/handoff.md"
            exchanges.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("unknown producer unknown-actor" in error for error in errors))
            self.assertTrue(any("invalid source Artifacts" in error for error in errors))
            self.assertTrue(any("lifecycle must be ephemeral" in error for error in errors))
            self.assertTrue(any("contains persistence fields" in error for error in errors))

    def test_task_scenarios_keep_governance_applicable_and_document_light(self):
        gates = json.loads((ROOT / "docs/process/governance/gates/core.json").read_text(encoding="utf-8"))["gates"]

        def matches_clause(clause, facts):
            key, expected = clause.split("=", 1)
            expected_value = {"true": True, "false": False}.get(expected, expected)
            return facts.get(key) == expected_value

        def matches_gate(gate, facts):
            applicability = gate["applicability"]
            applies = all(matches_clause(value, facts) for value in applicability.get("all", []))
            if "any" in applicability:
                applies = applies and any(matches_clause(value, facts) for value in applicability["any"])
            excludes = gate.get("excludes_if") or {}
            excluded = False
            if "all" in excludes:
                excluded = all(matches_clause(value, facts) for value in excludes["all"])
            if "any" in excludes:
                excluded = excluded or any(matches_clause(value, facts) for value in excludes["any"])
            return applies and not excluded

        local_defaults = {
            "product_behavior_change": False,
            "api_change": False,
            "persistence_change": False,
            "ai_runtime_change": False,
            "release_change": False,
            "cross_layer_change": False,
            "provider_change": False,
            "reusable_module_change": False,
            "product_object_governance_change": False,
            "architecture_governance_change": False,
            "software_component_governance_change": False,
            "documentation_governance_change": False,
            "meta_governance_change": False,
        }
        scenarios = {
            "small-bugfix": ({**local_defaults, "implementation_change": True}, {"G-TEST", "G-ADVISORY-LOCAL-CHANGE"}),
            "ui-only": ({**local_defaults, "implementation_change": True}, {"G-TEST", "G-ADVISORY-LOCAL-CHANGE"}),
            "api-change": ({**local_defaults, "api_change": True, "contract_change": True, "swc_impact": True, "implementation_change": True, "artifact_change": True, "impacted_artifact_has_validation_command": True}, {"G-CONTRACT", "G-SWC", "G-TEST", "G-ARTIFACT-VALIDATION"}),
            "cross-layer": ({**local_defaults, "cross_layer_change": True, "swc_impact": True, "implementation_change": True}, {"G-SWC", "G-TEST"}),
            "governance": ({**local_defaults, "meta_governance_change": True, "artifact_change": True, "impacted_artifact_has_validation_command": True}, {"G-ARTIFACT-VALIDATION", "G-INDEPENDENT-CHECK"}),
            "release": ({**local_defaults, "release_change": True, "release_requested": True}, {"G-RELEASE"}),
            "read-only-review": ({**local_defaults, "operation": "read-only", "meta_governance_change": True}, {"G-INDEPENDENT-CHECK"}),
        }
        for name, (facts, expected) in scenarios.items():
            matched = {gate["gate_id"] for gate in gates if matches_gate(gate, facts)}
            self.assertEqual(expected, matched, name)
            durable_evidence = {
                gate["evidence_contract"]["evidence_artifact_id"]
                for gate in gates
                if gate["gate_id"] in matched
                and gate.get("evidence_contract")
                and str(gate["evidence_contract"].get("persistence", "")).startswith("required")
                and gate["evidence_contract"].get("evidence_artifact_id")
            }
            if name == "release":
                self.assertEqual({"IMPLEMENTATION_REPORT"}, durable_evidence)
            else:
                self.assertEqual(set(), durable_evidence, name)

    def test_stable_method_handoffs_are_consolidated_as_workflow_exchanges(self):
        data = json.loads((ROOT / "docs/process/governance/exchanges.json").read_text(encoding="utf-8"))
        exchanges = {item["exchange_id"]: item for item in data["exchanges"]}
        self.assertEqual(6, len(exchanges))
        self.assertEqual("ephemeral", exchanges["EX-REQUIREMENT-DOWNSTREAM"]["lifecycle"])
        self.assertIn("INCREMENT_REQUIREMENTS", exchanges["EX-REQUIREMENT-DOWNSTREAM"]["source_artifacts"])
        self.assertIn("test-case-development", exchanges["EX-AC-DOWNSTREAM"]["consumers"])
        for shard in (ROOT / "docs/process/governance/artifacts").glob("*.json"):
            artifact_data = json.loads(shard.read_text(encoding="utf-8"))
            for artifact in artifact_data["artifacts"]:
                self.assertNotIn("ephemeral_outputs", artifact, artifact["artifact_id"])

    def test_reusable_definitions_reject_delivery_instances(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            reference = target / ".agents/skills/capability-registry-develop/references/structural-change-gates.md"
            reference.write_text(reference.read_text(encoding="utf-8") + "\nCurrent MVP behavior.\n", encoding="utf-8")
            workflow = target / "docs/process/workflow.md"
            workflow.write_text(
                workflow.read_text(encoding="utf-8") + "\nSWC-FLOW-CONCRETE-EXAMPLE\n",
                encoding="utf-8",
            )
            errors, _warnings, _metrics = validate_repository(target)
            instance_errors = [error for error in errors if "concrete instance content" in error]
            self.assertGreaterEqual(len(instance_errors), 2)

    def test_performance_percentile_is_not_treated_as_delivery_priority(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            standard = target / "docs/process/skill_quality_standard.md"
            standard.write_text(
                standard.read_text(encoding="utf-8") + "\nContext SLO: P95 at or below the measured budget.\n",
                encoding="utf-8",
            )
            errors, _warnings, _metrics = validate_repository(target)
            self.assertEqual([], errors)

    def test_skill_standard_rejects_actor_artifact_owner_restatement(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            standard = target / "docs/process/skill_quality_standard.md"
            standard.write_text(
                standard.read_text(encoding="utf-8") + "\nRequirement Development owns acceptance criteria.\n",
                encoding="utf-8",
            )
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("must not restate actor-to-Artifact ownership" in error for error in errors))

    def test_skill_contract_rejects_artifact_owner_restatement(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            skill = target / ".agents/skills/acceptance-criteria-generate/SKILL.md"
            text = skill.read_text(encoding="utf-8")
            text = text.replace(
                "## Inputs",
                "- QA owns `TEST_REPORT`.\n\n## Inputs",
                1,
            )
            skill.write_text(text, encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("must resolve Artifact ownership" in error for error in errors))

    def test_method_skill_owner_boundaries_use_handoffs(self):
        acceptance = (ROOT / ".agents/skills/acceptance-criteria-generate/SKILL.md").read_text(encoding="utf-8")
        requirements = (ROOT / ".agents/skills/requirement-refine/SKILL.md").read_text(encoding="utf-8")
        test_case = (ROOT / ".agents/skills/test-case-generate/SKILL.md").read_text(encoding="utf-8")
        self.assertIn("ephemeral AC-to-traceability handoff", acceptance)
        self.assertIn("does not create or edit Story Map, Registry, Spec, AC, TC, or traceability artifacts", requirements)
        self.assertIn("Persist only the test library", test_case)

    def test_skill_validator_accepts_progressive_disclosure_layout(self):
        errors, warnings = validate_skills(ROOT)
        self.assertEqual([], errors)
        self.assertEqual([], [warning for warning in warnings if "governance status is candidate" not in warning])

    def test_skill_validator_rejects_parallel_spec_layer(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            spec = target / ".agents/skills/code-review-quality/SPEC.md"
            spec.write_text("# Parallel maintenance rules\n", encoding="utf-8")
            errors, _warnings = validate_skills(target)
            self.assertTrue(any("parallel maintenance layer" in error for error in errors))

    def test_skill_validator_requires_direct_conditional_reference_link(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            reference = target / ".agents/skills/code-review-quality/references/advanced.md"
            reference.parent.mkdir(parents=True, exist_ok=True)
            reference.write_text("# Advanced review\n", encoding="utf-8")
            errors, _warnings = validate_skills(target)
            self.assertTrue(any("not linked directly from SKILL.md" in error for error in errors))

            skill = target / ".agents/skills/code-review-quality/SKILL.md"
            skill.write_text(
                skill.read_text(encoding="utf-8") + "\nSee [advanced](references/advanced.md).\n",
                encoding="utf-8",
            )
            errors, _warnings = validate_skills(target)
            self.assertTrue(any("link must state when to read or load it" in error for error in errors))

    def test_skill_validator_does_not_require_rationalizations_or_external_links(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            skill = target / ".agents/skills/code-review-quality/SKILL.md"
            text = skill.read_text(encoding="utf-8").split("\n## Common Rationalizations", 1)[0] + "\n"
            skill.write_text(text, encoding="utf-8")
            errors, warnings = validate_skills(target)
            self.assertEqual([], errors)
            self.assertEqual([], [warning for warning in warnings if "governance status is candidate" not in warning])

    def test_scenario_practice_instance_lives_in_boundary_registry(self):
        workflow = (ROOT / "docs/process/workflow.md").read_text(encoding="utf-8")
        registry = (ROOT / "docs/process/cross_cutting_boundary_registry.md").read_text(encoding="utf-8")
        self.assertNotIn("SWC-FLOW-SCENARIO-PRACTICE-RUNTIME", workflow)
        self.assertIn("XCB-008", registry)
        self.assertIn("SWC-FLOW-SCENARIO-PRACTICE-RUNTIME", registry)

    def test_write_scope_accepts_owner_and_rejects_unrelated_actor(self):
        path = "docs/product/roadmap.md"
        self.assertEqual([], check_paths(ROOT, [path], "product-manager"))
        self.assertTrue(check_paths(ROOT, [path], "backend"))

    def test_write_scope_accepts_registered_template_path(self):
        self.assertEqual([], check_paths(ROOT, ["docs/product/increments/demo/spec.md"], "product-spec-authority"))

    def test_write_scope_accepts_one_level_skill_resources(self):
        paths = [
            ".agents/skills/capability-registry-develop/references/structural-change-gates.md",
            ".agents/skills/capability-registry-develop/assets/ready-gate-output.template.md",
            ".agents/skills/story-map-develop/scripts/validate_story_map.py",
        ]
        self.assertEqual([], check_paths(ROOT, paths, "documentation-governance", governed_only=True))

    def test_duplicate_owner_route_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            product = target / "docs/process/governance/artifacts/product.json"
            data = json.loads(product.read_text(encoding="utf-8"))
            data["artifacts"][1]["artifact_id"] = data["artifacts"][0]["artifact_id"]
            product.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("duplicate artifact ID" in error or "routes do not match" in error for error in errors))

    def test_missing_gate_evidence_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            gates = target / "docs/process/governance/gates/core.json"
            data = json.loads(gates.read_text(encoding="utf-8"))
            data["gates"][0]["evidence_contract"] = None
            data["gates"][0]["evidence_command"] = None
            gates.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("no executable or structured evidence" in error for error in errors))

    def test_wrong_route_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            index = target / "docs/process/governance/index.json"
            data = json.loads(index.read_text(encoding="utf-8"))
            data["artifact_routes"]["PRODUCT_VISION"] = "artifacts/engineering.json"
            index.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("actual shard" in error for error in errors))

    def test_invalid_exception_and_duplicate_intent_are_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            exceptions = target / "docs/process/governance/exceptions.json"
            data = json.loads(exceptions.read_text(encoding="utf-8"))
            data["exceptions"] = [{"exception_id":"E-1","target_id":"G-TEST","owner":"qa","scope":"x","reason":"x","created_at":"2026-07-12","expires_at":"2026-07-13","removal_evidence":"x","status":"bogus"}]
            exceptions.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            intents = target / "docs/process/governance/intents.json"
            intent_data = json.loads(intents.read_text(encoding="utf-8"))
            intent_data["intents"].append(dict(intent_data["intents"][0]))
            intents.write_text(json.dumps(intent_data, ensure_ascii=False), encoding="utf-8")
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("invalid status" in error for error in errors))
            self.assertTrue(any("duplicate intent ID" in error for error in errors))

    def test_contributor_requires_scope_reference(self):
        self.assertTrue(check_paths(ROOT, ["docs/reports/quality_report.md"], "ux-review"))
        self.assertEqual([], check_paths(ROOT, ["docs/reports/quality_report.md"], "ux-review", "quality-finding"))

    def test_governance_metadata_requires_actor_and_supports_multiple_scopes(self):
        actors, scopes = parse_governance_metadata(
            "Change summary\n\nGovernance-Actor: ux-review\n"
            "Governance-Actor: documentation-governance\n"
            "Governance-Scope: quality-finding\n"
            "Governance-Scope: markdown-sections\n"
        )
        self.assertEqual(["ux-review", "documentation-governance"], actors)
        self.assertEqual(["quality-finding", "markdown-sections"], scopes)
        with self.assertRaises(ValueError):
            parse_governance_metadata("Governance-Scope: quality-finding")

    def test_multi_actor_change_authorizes_each_path_independently(self):
        paths = [".codex/agents/frontend.toml", "scripts/validate_governance_contracts.py"]
        self.assertEqual(
            [],
            check_authorized_changes(
                ROOT,
                paths,
                ["documentation-governance", "product-object-governance-change"],
                [],
                "HEAD",
                governed_only=True,
            ),
        )
        self.assertTrue(check_authorized_changes(ROOT, paths, ["backend"], [], "HEAD", governed_only=True))

    def test_markdown_section_scope_rejects_changes_outside_declared_headings(self):
        scope = {"type": "markdown-sections", "headings": ["Allowed"]}
        before = "# Root\n\n## Allowed\nold\n\n### Nested\nold nested\n\n## Locked\nstable\n"
        allowed = "# Root\n\n## Allowed\nnew\n\n### Nested\nnew nested\n\n## Locked\nstable\n"
        rejected = "# Root\n\n## Allowed\nnew\n\n### Nested\nnew nested\n\n## Locked\nchanged\n"
        self.assertEqual([], validate_content_scope(before, allowed, scope))
        self.assertTrue(validate_content_scope(before, rejected, scope))

    def test_append_record_scope_requires_append_only_actor_marked_records(self):
        scope = {
            "type": "append-record",
            "heading_level": 2,
            "record_schema": "quality-finding",
            "actor_field": "Reviewer: UX Review",
        }
        before = "# Quality report\n"
        allowed = before + "\n## Finding\nReviewer: UX Review\nResult: pass\n"
        rejected = before + "\n## Finding\nResult: pass\n"
        self.assertEqual([], validate_content_scope(before, allowed, scope))
        self.assertTrue(validate_content_scope(before, rejected, scope))
        self.assertTrue(validate_content_scope("# Changed\n", allowed, scope))

    def test_table_column_scope_rejects_changes_to_locked_columns(self):
        scope = {"type": "markdown-table-columns", "columns": ["Status"]}
        before = "| ID | Status | Note |\n| --- | --- | --- |\n| A | todo | stable |\n"
        allowed = "| ID | Status | Note |\n| --- | --- | --- |\n| A | done | stable |\n"
        rejected = "| ID | Status | Note |\n| --- | --- | --- |\n| A | done | changed |\n"
        self.assertEqual([], validate_content_scope(before, allowed, scope))
        self.assertTrue(validate_content_scope(before, rejected, scope))

    def test_yaml_step_scope_rejects_changes_outside_declared_step_ids(self):
        scope = {"type": "yaml-step-ids", "job_id": "build", "step_ids": ["allowed"]}
        before = (
            "jobs:\n  build:\n    steps:\n"
            "      - name: Allowed\n        id: allowed\n        run: echo old\n"
            "      - name: Locked\n        id: locked\n        run: echo stable\n"
        )
        allowed = before.replace("echo old", "echo new")
        rejected = allowed.replace("echo stable", "echo changed")
        self.assertEqual([], validate_content_scope(before, allowed, scope))
        self.assertTrue(validate_content_scope(before, rejected, scope))

    def test_ci_write_scope_passes_event_metadata_and_base_ref(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn('--github-event-path "$GITHUB_EVENT_PATH"', workflow)
        self.assertIn('--base-ref "$BASE_REF"', workflow)

    def test_ci_checks_the_pull_request_head_commit_chain(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        head_checkout = workflow.index("github.event.pull_request.head.sha")
        governance_validation = workflow.index("id: governance-contracts")
        governance_scope = workflow.index("id: governance-write-scope")
        merge_checkout = workflow.index("ref: ${{ github.ref }}")
        integration_validation = workflow.index("name: Cross-cutting boundary check")
        self.assertLess(head_checkout, governance_validation)
        self.assertLess(governance_scope, merge_checkout)
        self.assertLess(merge_checkout, integration_validation)
        self.assertIn("|| github.sha", workflow)

    def test_unrelated_script_is_not_governed(self):
        self.assertTrue(check_paths(ROOT, ["scripts/check_p0_2_followup_d_traceability.py"], "product-object-governance-change"))

    def test_governed_only_skips_application_paths(self):
        self.assertEqual([], check_paths(ROOT, ["lib/main.dart", "backend/src/main/java/App.java"], None, governed_only=True))

    def test_unregistered_retired_path_deletion_is_allowed(self):
        self.assertEqual([], check_paths(ROOT, ["docs/process/retired_definition.md"], "codex-root"))
        self.assertEqual(0, check_write_scope_main(["--governed-only", "lib/main.dart"]))

    def test_governed_only_checks_ci_workflow_paths(self):
        self.assertEqual([], check_paths(ROOT, [".github/workflows/ci.yml"], None, governed_only=True))
        self.assertEqual([], check_paths(ROOT, [".codex/agents/backend.toml"], None, governed_only=True))
        self.assertEqual(1, check_write_scope_main(["--governed-only", ".github/workflows/ci.yml"]))

    def test_native_agent_definitions_are_minimal_and_registered(self):
        errors = []
        paths = sorted((ROOT / ".codex/agents").glob("*.toml"))
        self.assertEqual(16, len(paths))
        for path in paths:
            data = load_toml(path, errors)
            self.assertEqual(path.stem, data["name"])
            self.assertIn("description", data)
            self.assertIn("developer_instructions", data)
        self.assertEqual([], errors)

    def test_native_review_agents_are_read_only(self):
        errors = []
        for name in [
            "evidence_reviewer",
            "product_object_governance_check",
            "software_architecture_governance_check",
        ]:
            data = load_toml(ROOT / f".codex/agents/{name}.toml", errors)
            self.assertEqual("read-only", data["sandbox_mode"])
        self.assertEqual([], errors)

    def test_native_review_agent_write_access_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_governance_fixture(target)
            reviewer = target / ".codex/agents/evidence_reviewer.toml"
            reviewer.write_text(
                reviewer.read_text(encoding="utf-8").replace('sandbox_mode = "read-only"', 'sandbox_mode = "workspace-write"'),
                encoding="utf-8",
            )
            errors, _warnings, _metrics = validate_repository(target)
            self.assertTrue(any("must use read-only sandbox_mode" in error for error in errors))

    def test_root_instructions_define_fast_path_and_on_demand_governance(self):
        instructions = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("shortest safe path", instructions)
        self.assertIn("Load only a skill", instructions)
        self.assertIn("do not require new governance documents", instructions)


if __name__ == "__main__":
    unittest.main()
