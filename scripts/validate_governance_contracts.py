#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # Python 3.10 local fallback; CI uses tomllib when available.
    tomllib = None

REQUIRED_ARTIFACT_FIELDS = {
    "artifact_id", "canonical_path", "accountable_owner", "contributors",
    "mutable_fields", "lifecycle", "applicability",
    "validation_command",
}
FORBIDDEN_ARTIFACT_FIELDS = {
    "checker", "evidence_location", "persistent_outputs", "ephemeral_outputs",
}
REQUIRED_GATE_FIELDS = {
    "gate_id", "applicability", "excludes_if", "risk_level", "machine_check",
    "evidence_contract", "result_levels", "exception_owner", "exception_scope",
    "exception_expiry", "evidence_command",
}
REQUIRED_EXCHANGE_FIELDS = {
    "exchange_id", "producer", "consumers", "source_artifacts",
    "applicability", "lifecycle", "required_fields",
}
FORBIDDEN_EXCHANGE_FIELDS = {
    "canonical_path", "path", "evidence_location", "persistent_outputs",
}
REQUIRED_INTENT_FIELDS = {
    "intent_id", "source_locations", "classification", "canonical_statement",
    "applicability", "accountable_owner", "authority_location", "enforcement",
    "regression_case", "superseded_locations", "decision_status",
}
ALLOWED_SCOPE_TYPES = {"markdown-table-columns", "markdown-sections", "append-record", "yaml-step-ids", "json-document"}
DEFINITION_PROCESS_TERMS = re.compile(
    r"\b(?:P0\.1|P0\.2|Followup-[A-Z])\b|历史迁移|迁移期|migration history|retired behavior|one-off incident",
    re.I,
)
DELIVERY_INSTANCE_TERMS = re.compile(r"\b(?:current\s+)?MVP\b|\bP[0-4](?:\.\d+)*\b|\bFollowup-[A-Z]\b", re.I)
CONCRETE_INSTANCE_ID = re.compile(r"(?<!G-)\b(?:TC|SWC-FLOW|FE|BE|DB|AI|OPS|P\d+)-[A-Z0-9][A-Z0-9-]*\b")
STANDARD_ARTIFACT_OWNER_CLAIM = re.compile(
    r"[^.\n]{1,100}(?:owns|拥有)[^.\n]{0,160}"
    r"(?:roadmap|development status|requirements?|user stor(?:y|ies)|acceptance criteria|test cases?|spec|traceability|report)",
    re.I,
)
SKILL_CONTRACT_OWNER_ASSIGNMENT = re.compile(
    r"\baccountable owners?\s*(?:\bis\b|\bare\b|:)|\bis accountable\b|\bowned by\b|\bowns\b[^\n]{0,120}`[A-Z][A-Z0-9_-]+`",
    re.I,
)
REQUIRED_NATIVE_AGENT_FIELDS = {"name", "description", "developer_instructions"}
READ_ONLY_NATIVE_AGENTS = {
    "evidence_reviewer",
    "product_object_governance_check",
    "software_architecture_governance_check",
}
ALLOWED_GOVERNANCE_STATUSES = {"candidate"}
RETIRED_RUNTIME_PATH_PATTERNS = (
    "scripts/project_agent_runner.py",
    "scripts/run_governance_ab.py",
    "codex/agents/*.md",
    "codex/templates/agent_runner_packet.template.md",
    "codex/templates/pm_orchestrator_brief.template.md",
    ".agents/skills/*/SPEC.md",
    "docs/process/governance/ab_corpus.json",
)
ACTIVE_BASELINE_FILES = (
    ".gitignore",
    "AGENTS.md",
    ".github/workflows/ci.yml",
    "docs/process/workflow.md",
    "docs/process/skill_quality_standard.md",
    "scripts/check_governance_write_scope.py",
    "scripts/validate_agent_skills.py",
    "scripts/validate_governance_contracts.py",
    "tests/test_validate_governance_contracts.py",
)
ACTIVE_BASELINE_DIRECTORIES = (
    ".codex",
    ".agents/skills",
    "codex/templates",
    "docs/process/governance",
)


def load_json(path: Path, errors: list[str]) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path}: invalid JSON: {exc}")
        return {}


def load_toml(path: Path, errors: list[str]) -> dict:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        errors.append(f"{path}: unreadable TOML: {exc}")
        return {}
    if tomllib is not None:
        try:
            return tomllib.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, tomllib.TOMLDecodeError) as exc:
            errors.append(f"{path}: invalid TOML: {exc}")
            return {}

    text = raw.decode("utf-8", errors="replace")
    result: dict = {}
    agents: dict = {}
    if re.search(r"^\[agents\]\s*$", text, re.MULTILINE):
        for key in ("max_threads", "max_depth"):
            match = re.search(rf"^{key}\s*=\s*(\d+)\s*$", text, re.MULTILINE)
            if match:
                agents[key] = int(match.group(1))
        result["agents"] = agents
    for match in re.finditer(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"\n]*)"\s*$', text, re.MULTILINE):
        result[match.group(1)] = match.group(2)
    for match in re.finditer(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"""(.*?)"""\s*$', text, re.MULTILINE | re.DOTALL):
        result[match.group(1)] = match.group(2)
    return result


def _relative_files(root: Path, relative_dir: str) -> set[str]:
    directory = root / relative_dir
    if not directory.exists():
        return set()
    return {
        path.relative_to(root).as_posix()
        for path in directory.rglob("*")
        if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc"
    }


def _git_tree_paths(root: Path, revision: str) -> set[str] | None:
    result = subprocess.run(
        ["git", "ls-tree", "-r", "--name-only", revision],
        cwd=root,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if result.returncode != 0:
        return None
    return {line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()}


def _git_file_text(root: Path, revision: str, relative_path: str) -> str | None:
    result = subprocess.run(
        ["git", "show", f"{revision}:{relative_path}"],
        cwd=root,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    return result.stdout if result.returncode == 0 else None


def _git_changed_paths(root: Path, old_revision: str, new_revision: str) -> set[str] | None:
    result = subprocess.run(
        ["git", "diff", "--name-only", old_revision, new_revision],
        cwd=root,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if result.returncode != 0:
        return None
    return {line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()}


def _git_dirty_baseline_paths(root: Path) -> list[str] | None:
    scopes = [*ACTIVE_BASELINE_FILES, *ACTIVE_BASELINE_DIRECTORIES]
    result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=all", "--", *scopes],
        cwd=root,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if result.returncode != 0:
        return None
    return [line.rstrip() for line in result.stdout.splitlines() if line.strip()]


def _governance_status_at(root: Path, revision: str) -> object | None:
    raw = _git_file_text(root, revision, "docs/process/governance/index.json")
    if raw is None:
        return None
    try:
        return json.loads(raw).get("status")
    except json.JSONDecodeError:
        return None


def _matches_retired_runtime_path(path: str) -> bool:
    normalized = path.replace("\\", "/")
    return any(fnmatch.fnmatchcase(normalized, pattern) for pattern in RETIRED_RUNTIME_PATH_PATTERNS)


def validate_governance_activation(root: Path, status: object) -> list[str]:
    errors: list[str] = []
    if status not in ALLOWED_GOVERNANCE_STATUSES:
        return [f"unsupported governance status: {status}"]

    for pattern in RETIRED_RUNTIME_PATH_PATTERNS:
        for path in root.glob(pattern):
            if path.is_file():
                errors.append(f"retired runtime interface exists: {path.relative_to(root).as_posix()}")

    # Local validation intentionally accepts an approved dirty candidate worktree.
    # Clean checkout, branch/base relationship, SHA stability, exact-CI evidence and
    # protected-ref activation belong to verify_exact_commit_ci.py after commit creation.
    head_paths = _git_tree_paths(root, "HEAD") or set()
    tracked_caches = sorted(
        path for path in head_paths if path.endswith(".pyc") or "/__pycache__/" in f"/{path}"
    )
    if tracked_caches:
        errors.append("candidate baseline contains tracked cache files: " + ", ".join(tracked_caches))
    return errors


def validate_repository(root: Path) -> tuple[list[str], list[str], dict]:
    root = root.resolve()
    errors: list[str] = []
    warnings: list[str] = []
    contract_root = root / "docs/process/governance"
    index = load_json(contract_root / "index.json", errors)
    if errors:
        return errors, warnings, {}
    allowed_index = {"schema_version", "status", "policy", "actor_registry", "artifact_routes", "gate_routes", "intent_registry", "exception_registry", "exchange_registry"}
    if set(index) != allowed_index:
        errors.append("governance index must be routing-only")
    errors.extend(validate_governance_activation(root, index.get("status")))
    if index.get("status") == "candidate":
        warnings.append("governance status is candidate; active cutover still requires a committed baseline and exact-commit CI evidence")

    policy = load_json(contract_root / index.get("policy", ""), errors)
    if "Contract 只收窄权限" not in policy.get("permission_rule", ""):
        errors.append("policy must state that contracts cannot expand agent/tool permissions")
    if "Artifact 不声明 checker" not in policy.get("artifact_checker_rule", "") or "G-INDEPENDENT-CHECK" not in policy.get("artifact_checker_rule", ""):
        errors.append("policy must assign checker selection exclusively to G-INDEPENDENT-CHECK")
    if "Artifact 不声明 evidence_location" not in policy.get("gate_evidence_rule", "") or "默认验证结果保持 ephemeral" not in policy.get("gate_evidence_rule", ""):
        errors.append("policy must assign evidence requirements to Gates and keep results ephemeral by default")
    if "不使用空数组默认值" not in policy.get("artifact_input_rule", ""):
        errors.append("policy must require sparse explicit Artifact input contracts")
    if "G-ARTIFACT-VALIDATION" not in policy.get("artifact_validation_rule", "") or "ephemeral" not in policy.get("artifact_validation_rule", ""):
        errors.append("policy must let G-ARTIFACT-VALIDATION invoke intrinsic Artifact validators without persistent output")
    if "Artifact 不声明 persistent_outputs 或 ephemeral_outputs" not in policy.get("artifact_output_rule", ""):
        errors.append("policy must keep persistent and ephemeral output contracts outside Artifact definitions")

    actor_data = load_json(contract_root / index.get("actor_registry", ""), errors)
    actor_rows = actor_data.get("actors", [])
    actor_ids = [row.get("actor_id") for row in actor_rows]
    if len(actor_ids) != len(set(actor_ids)):
        errors.append("actor IDs must be unique")
    actors = set(actor_ids)
    read_only_actor_ids = {
        row.get("actor_id")
        for row in actor_rows
        if Path(str(row.get("definition", ""))).stem in READ_ONLY_NATIVE_AGENTS
    }
    for row in actor_rows:
        definition = row.get("definition")
        if definition and not (root / definition).exists():
            errors.append(f"actor {row.get('actor_id')} definition does not exist: {definition}")

    project_instructions = root / "AGENTS.md"
    if not project_instructions.exists():
        errors.append("root AGENTS.md is missing")
    codex_config = load_toml(root / ".codex/config.toml", errors)
    agent_limits = codex_config.get("agents", {})
    if agent_limits.get("max_depth") != 1:
        errors.append(".codex/config.toml agents.max_depth must be 1")
    max_threads = agent_limits.get("max_threads")
    if not isinstance(max_threads, int) or not 1 <= max_threads <= 8:
        errors.append(".codex/config.toml agents.max_threads must be between 1 and 8")

    native_agent_root = root / ".codex/agents"
    native_agent_paths = sorted(native_agent_root.glob("*.toml"))
    if not native_agent_paths:
        errors.append(".codex/agents contains no native specialist definitions")
    native_names: set[str] = set()
    for path in native_agent_paths:
        data = load_toml(path, errors)
        missing = REQUIRED_NATIVE_AGENT_FIELDS - set(data)
        if missing:
            errors.append(f"{path.relative_to(root)} missing native agent fields: {sorted(missing)}")
            continue
        name = data["name"]
        if name in native_names:
            errors.append(f"duplicate native agent name: {name}")
        native_names.add(name)
        if path.stem != name:
            errors.append(f"{path.relative_to(root)} filename must match native agent name {name}")
        if len(data["description"].strip()) < 40:
            errors.append(f"{path.relative_to(root)} description is too short for reliable routing")
        if len(data["developer_instructions"].encode("utf-8")) > 2400:
            errors.append(f"{path.relative_to(root)} developer_instructions exceed 2400 bytes")
        if name in READ_ONLY_NATIVE_AGENTS and data.get("sandbox_mode") != "read-only":
            errors.append(f"native review agent {name} must use read-only sandbox_mode")
    actor_native_definitions = {
        row.get("definition") for row in actor_rows
        if str(row.get("definition", "")).startswith(".codex/agents/")
    }
    expected_native_definitions = {path.relative_to(root).as_posix() for path in native_agent_paths}
    if actor_native_definitions != expected_native_definitions:
        errors.append("actor registry native agent definitions do not match .codex/agents")

    workflow_path = root / "docs/process/workflow.md"
    skill_standard_path = root / "docs/process/skill_quality_standard.md"
    from validate_story_slice_cutover import collect_candidate_authority_graph
    graph_paths = collect_candidate_authority_graph(root)
    reusable_definition_paths = [
        path for path in graph_paths
        if path in {project_instructions, workflow_path, skill_standard_path}
        or ".codex/agents" in path.as_posix()
        or ".agents/skills" in path.as_posix()
    ]
    for path in sorted(set(reusable_definition_paths)):
        if not path.exists():
            errors.append(f"reusable definition does not exist: {path.relative_to(root)}")
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if (
                DEFINITION_PROCESS_TERMS.search(line)
                or DELIVERY_INSTANCE_TERMS.search(line)
                or CONCRETE_INSTANCE_ID.search(line)
            ):
                errors.append(
                    f"{path.relative_to(root)}:{line_number}: reusable definition contains delivery-specific or concrete instance content"
                )
        if path.name == "SKILL.md":
            in_contract = False
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if line == "## Contract":
                    in_contract = True
                    continue
                if in_contract and line.startswith("## "):
                    break
                if in_contract and SKILL_CONTRACT_OWNER_ASSIGNMENT.search(line):
                    errors.append(
                        f"{path.relative_to(root)}:{line_number}: Skill Contract must resolve Artifact ownership from the governance contract"
                    )
    if skill_standard_path.exists() and STANDARD_ARTIFACT_OWNER_CLAIM.search(
        skill_standard_path.read_text(encoding="utf-8")
    ):
        errors.append("skill quality standard must not restate actor-to-Artifact ownership; use the Artifact contract")

    artifacts: dict[str, dict] = {}
    paths: dict[str, str] = {}
    artifact_routes = index.get("artifact_routes", {})
    artifact_shards: dict[str, str] = {}
    explicit_required_inputs: dict[str, list[str]] = {}
    explicit_conditional_inputs: dict[str, list[str]] = {}
    for shard in sorted(set(artifact_routes.values())):
        data = load_json(contract_root / shard, errors)
        defaults = data.get("defaults", {})
        for field in sorted(FORBIDDEN_ARTIFACT_FIELDS & set(defaults)):
            errors.append(f"artifact shard {shard} contains forbidden Artifact field {field}")
        if "required_direct_inputs" in defaults or "conditional_inputs" in defaults:
            errors.append(f"artifact shard {shard} must not default input arrays")
        for raw in data.get("artifacts", []):
            raw_id = raw.get("artifact_id")
            for field in sorted(FORBIDDEN_ARTIFACT_FIELDS & set(raw)):
                errors.append(f"artifact {raw_id} contains forbidden Artifact field {field}")
            item = {**defaults, **raw}
            aid = item.get("artifact_id")
            missing = REQUIRED_ARTIFACT_FIELDS - set(item)
            if missing:
                errors.append(f"artifact {aid} missing fields: {sorted(missing)}")
                continue
            if aid in artifacts:
                errors.append(f"duplicate artifact ID: {aid}")
            artifacts[aid] = item
            artifact_shards[aid] = shard
            path = item["canonical_path"]
            if path in paths:
                errors.append(f"duplicate canonical path: {path} ({paths[path]}, {aid})")
            paths[path] = aid
    if set(artifact_routes) != set(artifacts):
        errors.append("artifact ID-to-shard routes do not match loaded artifacts")
    for aid, shard in artifact_routes.items():
        if aid in artifact_shards and artifact_shards[aid] != shard:
            errors.append(f"artifact {aid} route points to {shard}, actual shard is {artifact_shards[aid]}")
    for aid, item in artifacts.items():
        if artifact_routes.get(aid) is None:
            errors.append(f"artifact {aid} has no explicit route")
        if item["accountable_owner"] not in actors:
            errors.append(f"artifact {aid} has unknown owner {item['accountable_owner']}")
        if item["accountable_owner"] in {p.name for p in (root / ".agents/skills").glob("*") if p.is_dir()}:
            errors.append(f"artifact {aid} uses a skill as accountable owner")
        method = item.get("method_skill")
        if method and not (root / ".agents/skills" / method / "SKILL.md").exists():
            errors.append(f"artifact {aid} has unknown method skill {method}")
        for field, registry in (
            ("required_direct_inputs", explicit_required_inputs),
            ("conditional_inputs", explicit_conditional_inputs),
        ):
            values = item.get(field)
            if values is not None:
                registry[aid] = values
                if (
                    not isinstance(values, list)
                    or not values
                    or any(not isinstance(value, str) or not value.strip() for value in values)
                    or len(values) != len(set(values))
                ):
                    errors.append(f"artifact {aid} {field} must be a non-empty unique string list")
        for contributor in item["contributors"]:
            if contributor not in actors:
                errors.append(f"artifact {aid} has unknown contributor {contributor}")
                continue
            scope = item["mutable_fields"].get(contributor)
            if not isinstance(scope, dict) or scope.get("type") not in ALLOWED_SCOPE_TYPES:
                errors.append(f"artifact {aid} contributor {contributor} has non-executable mutable scope")
            elif scope.get("type") == "markdown-sections" and not scope.get("headings"):
                errors.append(f"artifact {aid} contributor {contributor} markdown-sections scope needs headings")
            elif scope.get("type") == "markdown-table-columns" and not (scope.get("columns") or scope.get("table_heading")):
                errors.append(f"artifact {aid} contributor {contributor} table scope needs columns or table_heading")
            elif scope.get("type") == "append-record" and not (scope.get("record_schema") and scope.get("heading_level")):
                errors.append(f"artifact {aid} contributor {contributor} append-record scope needs record_schema and heading_level")
            elif scope.get("type") == "yaml-step-ids" and not (scope.get("job_id") and scope.get("step_ids")):
                errors.append(f"artifact {aid} contributor {contributor} yaml scope needs job_id and step_ids")
        required_inputs = item.get("required_direct_inputs", [])
        conditional_inputs = item.get("conditional_inputs", [])
        if not isinstance(required_inputs, list):
            required_inputs = []
        if not isinstance(conditional_inputs, list):
            conditional_inputs = []
        if set(required_inputs) & set(conditional_inputs):
            errors.append(f"artifact {aid} repeats an input as both required and conditional")
        for dependency in required_inputs + conditional_inputs:
            if dependency not in artifacts:
                errors.append(f"artifact {aid} references unknown input {dependency}")

    gates: dict[str, dict] = {}
    evidence_artifact_references: set[str] = set()
    gate_routes = index.get("gate_routes", {})
    for shard in sorted(set(gate_routes.values())):
        data = load_json(contract_root / shard, errors)
        if not data.get("short_circuit_rules"):
            errors.append(f"gate shard {shard} has no short-circuit rules")
        for gate in data.get("gates", []):
            gid = gate.get("gate_id")
            missing = REQUIRED_GATE_FIELDS - set(gate)
            if missing:
                errors.append(f"gate {gid} missing fields: {sorted(missing)}")
            if gid in gates:
                errors.append(f"duplicate gate ID: {gid}")
            gates[gid] = gate
            if gate.get("evidence_command") is None and gate.get("evidence_contract") is None and gate.get("risk_level") != "low":
                errors.append(f"gate {gid} has no executable or structured evidence")
            applicability = gate.get("applicability")
            if not isinstance(applicability, dict) or not applicability or not set(applicability) <= {"all", "any"}:
                errors.append(f"gate {gid} applicability must be structured")
            elif any(
                not isinstance(values, list)
                or not values
                or any(not isinstance(value, str) or "=" not in value for value in values)
                for values in applicability.values()
            ):
                errors.append(f"gate {gid} applicability clauses must be non-empty key=value lists")
            if gate.get("risk_level") not in {"low", "medium", "high"}:
                errors.append(f"gate {gid} has invalid risk level {gate.get('risk_level')}")
            result_levels = gate.get("result_levels")
            if (
                not isinstance(result_levels, list)
                or not result_levels
                or len(result_levels) != len(set(result_levels))
                or not set(result_levels) <= {"advisory", "block", "conditional", "pass"}
            ):
                errors.append(f"gate {gid} has invalid result levels")
            evidence_contract = gate.get("evidence_contract")
            if evidence_contract is not None:
                required_fields = evidence_contract.get("required_fields") if isinstance(evidence_contract, dict) else None
                if not isinstance(evidence_contract, dict) or not evidence_contract.get("evaluator"):
                    errors.append(f"gate {gid} evidence contract requires an evaluator")
                if (
                    not isinstance(required_fields, list)
                    or not required_fields
                    or any(not isinstance(value, str) or not value.strip() for value in required_fields)
                    or len(required_fields) != len(set(required_fields))
                ):
                    errors.append(f"gate {gid} evidence contract requires non-empty unique required_fields")
                evidence_artifact_id = evidence_contract.get("evidence_artifact_id")
                if evidence_artifact_id is not None:
                    evidence_artifact_references.add(evidence_artifact_id)
                    if evidence_artifact_id not in artifacts:
                        errors.append(f"gate {gid} references unknown evidence Artifact {evidence_artifact_id}")
                    elif not artifacts[evidence_artifact_id]["canonical_path"].startswith("docs/reports/"):
                        errors.append(f"gate {gid} evidence Artifact {evidence_artifact_id} is not a registered report")
                    if not evidence_contract.get("persistence"):
                        errors.append(f"gate {gid} evidence Artifact reference requires an explicit persistence policy")
                evidence_by_artifact = evidence_contract.get("evidence_artifact_by_artifact_id", {})
                if not isinstance(evidence_by_artifact, dict):
                    errors.append(f"gate {gid} evidence_artifact_by_artifact_id must be an object")
                else:
                    for source_artifact_id, target_artifact_id in evidence_by_artifact.items():
                        evidence_artifact_references.add(target_artifact_id)
                        if source_artifact_id not in artifacts:
                            errors.append(f"gate {gid} selects evidence for unknown Artifact {source_artifact_id}")
                        if target_artifact_id not in artifacts:
                            errors.append(f"gate {gid} references unknown evidence Artifact {target_artifact_id}")
                        elif not artifacts[target_artifact_id]["canonical_path"].startswith("docs/reports/"):
                            errors.append(f"gate {gid} evidence Artifact {target_artifact_id} is not a registered report")
    if set(gate_routes) != set(gates):
        errors.append("gate ID-to-shard routes do not match loaded gates")
    independent_gate = gates.get("G-INDEPENDENT-CHECK", {})
    checker_selector = independent_gate.get("evidence_contract", {}).get("checker_selector", {})
    checker_by_trigger = checker_selector.get("by_trigger", {})
    checker_by_artifact = checker_selector.get("by_artifact_id", {})
    expected_checker_triggers = set(independent_gate.get("applicability", {}).get("any", []))
    expected_checker_triggers = {value.removesuffix("=true") for value in expected_checker_triggers}
    if set(checker_by_trigger) != expected_checker_triggers:
        errors.append("G-INDEPENDENT-CHECK checker_by_trigger must cover every applicability trigger")
    for trigger, checker in checker_by_trigger.items():
        if checker not in read_only_actor_ids:
            errors.append(f"G-INDEPENDENT-CHECK trigger {trigger} uses non-checker actor {checker}")
    for artifact_id, checker in checker_by_artifact.items():
        if artifact_id not in artifacts:
            errors.append(f"G-INDEPENDENT-CHECK selects checker for unknown artifact {artifact_id}")
        if checker not in read_only_actor_ids:
            errors.append(f"G-INDEPENDENT-CHECK artifact {artifact_id} uses non-checker actor {checker}")
    for evidence_artifact_id in evidence_artifact_references:
        evidence_artifact = artifacts.get(evidence_artifact_id)
        if evidence_artifact and evidence_artifact["accountable_owner"] in read_only_actor_ids:
            errors.append(
                f"evidence Artifact {evidence_artifact_id} cannot be owned by read-only checker "
                f"{evidence_artifact['accountable_owner']}"
            )

    validation_gate = gates.get("G-ARTIFACT-VALIDATION", {})
    artifact_validation_commands = {
        artifact_id: artifact["validation_command"]
        for artifact_id, artifact in artifacts.items()
        if artifact.get("validation_command")
    }
    if artifact_validation_commands:
        if "Artifact.validation_command" not in str(validation_gate.get("machine_check", "")):
            errors.append("G-ARTIFACT-VALIDATION must resolve intrinsic Artifact.validation_command values")
        if validation_gate.get("evidence_command") != "artifact://impacted/validation_command":
            errors.append("G-ARTIFACT-VALIDATION must use the impacted Artifact validation command URI")
        if validation_gate.get("evidence_contract", {}).get("persistence") != "ephemeral":
            errors.append("G-ARTIFACT-VALIDATION results must remain ephemeral")

    exchange_data = load_json(contract_root / index.get("exchange_registry", ""), errors)
    exchange_rows = exchange_data.get("exchanges", [])
    exchange_ids: set[str] = set()
    for exchange in exchange_rows:
        exchange_id = exchange.get("exchange_id")
        missing = REQUIRED_EXCHANGE_FIELDS - set(exchange)
        if missing:
            errors.append(f"workflow exchange {exchange_id} missing fields: {sorted(missing)}")
            continue
        if exchange_id in exchange_ids:
            errors.append(f"duplicate workflow exchange ID: {exchange_id}")
        exchange_ids.add(exchange_id)
        forbidden = FORBIDDEN_EXCHANGE_FIELDS & set(exchange)
        if forbidden:
            errors.append(f"workflow exchange {exchange_id} contains persistence fields: {sorted(forbidden)}")
        if exchange["producer"] not in actors:
            errors.append(f"workflow exchange {exchange_id} has unknown producer {exchange['producer']}")
        consumers = exchange["consumers"]
        if (
            not isinstance(consumers, list)
            or not consumers
            or len(consumers) != len(set(consumers))
            or any(consumer not in actors for consumer in consumers)
        ):
            errors.append(f"workflow exchange {exchange_id} has invalid consumers")
        source_artifacts = exchange["source_artifacts"]
        if (
            not isinstance(source_artifacts, list)
            or not source_artifacts
            or len(source_artifacts) != len(set(source_artifacts))
            or any(artifact_id not in artifacts for artifact_id in source_artifacts)
        ):
            errors.append(f"workflow exchange {exchange_id} has invalid source Artifacts")
        required_fields = exchange["required_fields"]
        if (
            not isinstance(required_fields, list)
            or not required_fields
            or len(required_fields) != len(set(required_fields))
            or any(not isinstance(value, str) or not value.strip() for value in required_fields)
        ):
            errors.append(f"workflow exchange {exchange_id} has invalid required_fields")
        if exchange["lifecycle"] != "ephemeral":
            errors.append(f"workflow exchange {exchange_id} lifecycle must be ephemeral")
        if not isinstance(exchange["applicability"], str) or not exchange["applicability"].strip():
            errors.append(f"workflow exchange {exchange_id} requires applicability")

    exceptions = load_json(contract_root / index.get("exception_registry", ""), errors)
    exception_required = set(exceptions.get("entry_schema", {}).get("required", []))
    if not {"exception_id", "owner", "scope", "expires_at", "removal_evidence", "status"} <= exception_required:
        errors.append("exception registry schema is incomplete")
    valid_exception_statuses = set(exceptions.get("entry_schema", {}).get("status_values", []))
    exception_ids = set()
    for entry in exceptions.get("exceptions", []):
        if entry.get("exception_id") in exception_ids:
            errors.append(f"duplicate exception ID: {entry.get('exception_id')}")
        exception_ids.add(entry.get("exception_id"))
        missing = exception_required - set(entry)
        if missing:
            errors.append(f"exception {entry.get('exception_id')} missing fields: {sorted(missing)}")
        if entry.get("status") not in valid_exception_statuses:
            errors.append(f"exception {entry.get('exception_id')} has invalid status {entry.get('status')}")

    intents = load_json(contract_root / index.get("intent_registry", ""), errors)
    intent_ids = set()
    for intent in intents.get("intents", []):
        if intent.get("intent_id") in intent_ids:
            errors.append(f"duplicate intent ID: {intent.get('intent_id')}")
        intent_ids.add(intent.get("intent_id"))
        missing = REQUIRED_INTENT_FIELDS - set(intent)
        if missing:
            errors.append(f"intent {intent.get('intent_id')} missing fields: {sorted(missing)}")
        if not intent.get("source_locations"):
            errors.append(f"intent {intent.get('intent_id')} has no provenance")

    runtime_files = [project_instructions] + native_agent_paths + list((root / ".agents/skills").glob("*/SKILL.md"))
    token_proxy = {}
    duplicate_lines: Counter[str] = Counter()
    for path in runtime_files:
        text = path.read_text(encoding="utf-8")
        token_proxy[path.relative_to(root).as_posix()] = (len(text.encode("utf-8")) + 3) // 4
        for line in text.splitlines():
            normalized = re.sub(r"\s+", " ", line.strip().lower())
            if len(normalized) >= 40:
                duplicate_lines[normalized] += 1
    repeated = sum(1 for count in duplicate_lines.values() if count >= 3)
    if repeated:
        warnings.append(f"runtime substantive lines repeated in 3+ files: {repeated}")
    oversized = [path for path, count in token_proxy.items() if count > 1500]
    if oversized:
        warnings.append(f"runtime files above advisory 1500-token proxy: {len(oversized)}")
    metrics = {
        "governance_status": index.get("status"),
        "artifacts": len(artifacts),
        "actors": len(actors),
        "gates": len(gates),
        "workflow_exchanges": len(exchange_rows),
        "evidence_artifact_references": len(evidence_artifact_references),
        "artifact_validation_commands": len(artifact_validation_commands),
        "artifact_required_input_contracts": len(explicit_required_inputs),
        "artifact_conditional_input_contracts": len(explicit_conditional_inputs),
        "runtime_token_proxy": token_proxy,
    }
    return errors, warnings, metrics


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate modular agent/skill governance contracts.")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    errors, warnings, metrics = validate_repository(args.root.resolve())
    if args.json:
        print(json.dumps({"errors": errors, "warnings": warnings, "metrics": metrics}, ensure_ascii=False, indent=2))
    else:
        print("Governance contract validation")
        for warning in warnings:
            print(f"WARNING: {warning}")
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Result: {'failed' if errors else 'passed'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
