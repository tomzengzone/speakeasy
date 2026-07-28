#!/usr/bin/env python3
"""Validate the forward-only Story/Slice governance cutover and authority graph."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = Path("docs/process/governance")

RETIRED_ARTIFACTS = {
    "PRODUCT_BASE_REQUIREMENTS", "PRODUCT_BASE_SPEC", "PRODUCT_BASE_ACCEPTANCE",
    "PRODUCT_BASE_TRACEABILITY", "PRODUCT_BASELINE", "INCREMENT_REQUIREMENTS",
    "INCREMENT_SPEC", "INCREMENT_ACCEPTANCE", "INCREMENT_TEST_CASES",
    "INCREMENT_TRACEABILITY", "INCREMENT_SWC_ALLOCATION",
    "SPEC_AC_RETIREMENT_MANIFEST", "SPEC_AC_RETIREMENT_SCHEMA",
    "SPEC_AC_RETIREMENT_VALIDATOR", "SPEC_AC_RETIREMENT_VALIDATOR_TEST",
}
RETIRED_GATES = {"G-SPEC", "G-AC-TC"}
RETIRED_ACTORS = {"product-spec-authority", "acceptance-authority"}
RETIRED_METHODS = {"feature-spec-generate", "acceptance-criteria-generate"}
PLANNING_INPUTS = {"STAGE_SCOPE", "INCREMENT_DEFINITION", "PRODUCT_ROADMAP"}
ENGINEERING_LINEAGE_DOCS = (
    "docs/architecture/system_overview.md",
    "docs/architecture/module_boundary.md",
    "docs/architecture/software_component_architecture.md",
    "docs/architecture/swc_catalog.md",
    "docs/architecture/api_contract.md",
    "docs/architecture/openapi/speakeasy-api.yaml",
    "docs/architecture/data_flow.md",
    "docs/domain/domain_schema.md",
    "docs/domain/entity_relationship.md",
    "docs/domain/training_model.md",
    "docs/ai_runtime/prompt_contract.md",
    "docs/ai_runtime/llm_output_schema.md",
    "docs/ai_runtime/fallback_strategy.md",
    "docs/ai_runtime/ai_eval_cases.md",
    "docs/ai_runtime/dialogue_state_machine.md",
    "docs/ux/screen_spec.md",
)
CAPABILITY_ID = re.compile(r"^CAP-[A-Z][A-Z0-9-]*$")
STORY_SECTION = re.compile(r"^##\s+\d+\..*?[（(](CAP-[A-Z][A-Z0-9-]*)\s*/")
STORY_ID = re.compile(r"^(US|VS)-([A-Z][A-Z0-9-]*)-\d{3}$")


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _repo_path(root: Path, value: str) -> Path:
    return root / value.replace("\\", "/")


def _expand_canonical_path(root: Path, canonical: str) -> list[Path]:
    if not canonical:
        return []
    fields = re.findall(r"\{[a-z_]+\}", canonical)
    pattern = canonical
    for field in fields:
        pattern = pattern.replace(field, "*")
    if fields:
        return sorted(path for path in root.glob(pattern) if path.is_file())
    path = _repo_path(root, canonical)
    return [path] if path.is_file() else []


def _linked_resources(skill_md: Path) -> list[Path]:
    text = skill_md.read_text(encoding="utf-8")
    result: list[Path] = []
    for raw in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
        target = raw.split("#", 1)[0].strip()
        if not target or "://" in target or target.startswith("/"):
            continue
        path = (skill_md.parent / target).resolve()
        if path.is_file() and skill_md.parent.resolve() in path.parents:
            result.append(path)
    return result


def collect_current_definition_paths(
    root: Path = ROOT,
    *,
    index: dict | None = None,
    artifacts: dict[str, dict] | None = None,
) -> list[Path]:
    """Return reusable current-state definitions and directly linked Skill resources."""
    root = root.resolve()
    contract = root / GOVERNANCE
    index = index or _json(contract / "index.json")
    artifacts = artifacts or _load_artifacts(root, index)
    files: set[Path] = set()

    for relative in (
        "AGENTS.md", ".codex/config.toml", "docs/process/workflow.md",
        "docs/process/definition_of_done.md", "docs/process/skill_quality_standard.md",
    ):
        path = root / relative
        if path.is_file():
            files.add(path)

    actors = _json(contract / index["actor_registry"])
    for row in actors.get("actors", []):
        definition = row.get("definition")
        if definition:
            path = _repo_path(root, definition)
            if path.is_file():
                files.add(path)

    methods = sorted({item.get("method_skill") for item in artifacts.values() if item.get("method_skill")})
    for method in methods:
        skill_md = root / ".agents" / "skills" / method / "SKILL.md"
        if skill_md.is_file():
            files.add(skill_md)
            files.update(_linked_resources(skill_md))

    return sorted(files, key=lambda path: path.relative_to(root).as_posix())


def collect_candidate_authority_graph(root: Path = ROOT) -> list[Path]:
    """Return the deterministic file set that constitutes candidate authority."""
    root = root.resolve()
    contract = root / GOVERNANCE
    index_path = contract / "index.json"
    index = _json(index_path)
    files: set[Path] = {index_path}

    for key in ("policy", "actor_registry", "exchange_registry", "intent_registry", "exception_registry"):
        value = index.get(key)
        if value:
            files.add(contract / value)
    for route_map in (index.get("artifact_routes", {}), index.get("gate_routes", {})):
        files.update(contract / value for value in route_map.values())

    artifacts: dict[str, dict] = {}
    for shard in sorted(set(index.get("artifact_routes", {}).values())):
        data = _json(contract / shard)
        defaults = data.get("defaults", {})
        for row in data.get("artifacts", []):
            item = {**defaults, **row}
            artifacts[item["artifact_id"]] = item
            canonical = str(item.get("canonical_path", ""))
            files.update(_expand_canonical_path(root, canonical))

    files.update(collect_current_definition_paths(root, index=index, artifacts=artifacts))

    return sorted(files, key=lambda path: path.relative_to(root).as_posix())


def _load_artifacts(root: Path, index: dict) -> dict[str, dict]:
    contract = root / GOVERNANCE
    artifacts: dict[str, dict] = {}
    for shard in sorted(set(index.get("artifact_routes", {}).values())):
        data = _json(contract / shard)
        defaults = data.get("defaults", {})
        for row in data.get("artifacts", []):
            item = {**defaults, **row}
            artifacts[item["artifact_id"]] = item
    return artifacts


def validate_adr(root: Path) -> list[str]:
    path = root / "docs/architecture/adr/0007-story-slice-led-delivery.md"
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    errors: list[str] = []
    required = (
        "Functional Requirement when present", "source_fr_id", "source_contract_id",
        "source_vs_id", "Derived canonical traceability", "forward-only",
        "no-migration", "PR-002", "historical-reference-only",
        "不建立 project-local Hook",
    )
    for marker in required:
        if marker not in text:
            errors.append(f"ADR 0007 missing current-decision marker: {marker}")
    return errors


def validate_story_map(root: Path) -> list[str]:
    errors: list[str] = []
    try:
        index = _json(root / GOVERNANCE / "index.json")
        artifacts = _load_artifacts(root, index)
        story_template = str(artifacts["STORY_MAP"]["canonical_path"])
        index_canonical = str(artifacts["STORY_MAP_INDEX"]["canonical_path"])
    except (OSError, json.JSONDecodeError, KeyError) as exc:
        return [f"cannot resolve Story Map contracts: {exc}"]

    token = "{capability_prefix}"
    if story_template.count(token) != 1:
        return ["STORY_MAP canonical_path must contain exactly one {capability_prefix} placeholder"]
    if "{" in index_canonical:
        errors.append("STORY_MAP_INDEX canonical_path must be a single navigation document")

    path = _repo_path(root, index_canonical)
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    head = "\n".join(text.splitlines()[:70])
    for marker in (
        "STORY_MAP_INDEX", "导航", "approved User Story",
        "approved Child Vertical Slice", "Functional Requirement ID when present",
    ):
        if marker not in head:
            errors.append(f"Story Map index header missing marker: {marker}")
    forbidden = (
        "docs/product/user_stories.md", "docs/product/base/", "Increment Requirements",
        "-> Spec ID", "-> AC ID", "G-SPEC", "G-AC-TC",
    )
    for marker in forbidden:
        if marker in head:
            errors.append(f"Story Map index header contains retired active source/delivery marker: {marker}")
    if "planning-only" not in head and "只组织交付" not in head:
        errors.append("Story Map index must classify Stage/Increment as planning-only")
    if re.search(r"^###\s+(?:US|VS)-|^\|\s*`(?:US|VS)-", text, re.M):
        errors.append("STORY_MAP_INDEX must not contain Story/VS rows")

    registry = root / "docs/product/feature_registry.md"
    prefixes: set[str] = set()
    if registry.is_file():
        for line in registry.read_text(encoding="utf-8").splitlines():
            if not line.startswith("|"):
                continue
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            if len(cells) != 12:
                continue
            capability = cells[0].strip("`")
            prefix = cells[10].strip("`")
            if CAPABILITY_ID.fullmatch(capability) and prefix == capability.removeprefix("CAP-"):
                prefixes.add(prefix)
    if not prefixes:
        errors.append("Capability Registry exposes no Story Map shard prefixes")

    expected = {
        story_template.replace(token, prefix).replace("\\", "/") for prefix in prefixes
    }
    discovered_paths = _expand_canonical_path(root, story_template)
    discovered = {path.relative_to(root).as_posix() for path in discovered_paths}
    listed = {
        f"docs/product/{relative}"
        for relative in re.findall(
            r"\]\((?:\./|docs/product/)?(user_stories/user_story_CAP_[A-Z0-9-]+\.md)\)",
            text,
        )
    }
    for missing in sorted(expected - discovered):
        errors.append(f"expected Story Map shard is missing: {missing}")
    for unindexed in sorted(discovered - listed):
        errors.append(f"Story Map shard is absent from STORY_MAP_INDEX navigation: {unindexed}")
    for stale in sorted(listed - expected):
        errors.append(f"STORY_MAP_INDEX lists an unexpected Story Map shard: {stale}")

    seen_story_ids: dict[str, Path] = {}
    for shard in discovered_paths:
        shard_text = shard.read_text(encoding="utf-8")
        sections = [
            match for line in shard_text.splitlines()
            if (match := STORY_SECTION.match(line))
        ]
        prefix = shard.stem.removeprefix("user_story_CAP_")
        expected_capability = f"CAP-{prefix}"
        if len(sections) != 1 or sections[0].group(1) != expected_capability:
            errors.append(
                f"{shard.relative_to(root)} must contain exactly its {expected_capability} section"
            )
        for number, line in enumerate(shard_text.splitlines(), 1):
            if not re.match(r"^\|\s*`(?:US|VS)-", line):
                continue
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            if len(cells) != 5:
                errors.append(f"{shard.relative_to(root)}:{number} Story/VS row must have 5 columns")
                continue
            story_id = cells[0].strip("`")
            match = STORY_ID.fullmatch(story_id)
            primary = cells[3].strip("`")
            if not match or match.group(2) != prefix:
                errors.append(
                    f"{shard.relative_to(root)}:{number} {story_id} does not match shard prefix {prefix}"
                )
            if primary != expected_capability:
                errors.append(
                    f"{shard.relative_to(root)}:{number} primary {primary} "
                    f"does not match {expected_capability}"
                )
            if story_id in seen_story_ids:
                errors.append(
                    f"duplicate Story/VS ID {story_id} across "
                    f"{seen_story_ids[story_id].relative_to(root)} and {shard.relative_to(root)}"
                )
            else:
                seen_story_ids[story_id] = shard
    return errors


def validate_cutover(root: Path = ROOT, *, check_adr: bool = True, check_story_map: bool = True) -> tuple[list[str], dict]:
    root = root.resolve()
    errors: list[str] = []
    contract = root / GOVERNANCE
    try:
        index = _json(contract / "index.json")
        artifacts = _load_artifacts(root, index)
    except (OSError, json.JSONDecodeError, KeyError) as exc:
        return [f"cannot load governance graph: {exc}"], {}

    if index.get("status") != "candidate":
        errors.append("candidate content must keep governance index status=candidate")
    routes = set(index.get("artifact_routes", {}))
    gates = set(index.get("gate_routes", {}))
    for required in (
        "STORY_MAP", "STORY_MAP_INDEX", "FUNCTIONAL_REQUIREMENT_CATALOG",
        "TEST_CASE_CATALOG", "TRACEABILITY",
    ):
        if required not in routes:
            errors.append(f"missing active Artifact route: {required}")
    for retired in sorted(routes & RETIRED_ARTIFACTS):
        errors.append(f"retired Artifact remains routed: {retired}")
    for retired in sorted(gates & RETIRED_GATES):
        errors.append(f"retired Gate remains routed: {retired}")

    actors = _json(contract / index["actor_registry"]).get("actors", [])
    actor_ids = {row.get("actor_id") for row in actors}
    for retired in sorted(actor_ids & RETIRED_ACTORS):
        errors.append(f"retired actor remains registered: {retired}")
    methods = {row.get("method_skill") for row in artifacts.values() if row.get("method_skill")}
    for retired in sorted(methods & RETIRED_METHODS):
        errors.append(f"retired method remains active: {retired}")
    for retired in sorted(RETIRED_METHODS):
        if (root / ".agents" / "skills" / retired / "SKILL.md").exists():
            errors.append(f"retired Skill remains discoverable: {retired}")

    for aid, row in artifacts.items():
        dependencies = set(row.get("required_direct_inputs", [])) | set(row.get("conditional_inputs", []))
        for retired in sorted(dependencies & RETIRED_ARTIFACTS):
            errors.append(f"Artifact {aid} depends on retired Artifact {retired}")
        if aid not in {"STAGE_SCOPE", "INCREMENT_DEFINITION", "PRODUCT_ROADMAP", "DEVELOPMENT_STATUS"}:
            for planning in sorted(dependencies & PLANNING_INPUTS):
                errors.append(f"Artifact {aid} uses planning-only {planning} as upstream")

    product = artifacts.get("FUNCTIONAL_REQUIREMENT_CATALOG", {})
    if product.get("required_direct_inputs") or product.get("conditional_inputs") != ["STORY_MAP"]:
        errors.append("FUNCTIONAL_REQUIREMENT_CATALOG must use STORY_MAP only when FRs exist")
    ai_eval = artifacts.get("AI_EVAL_CASES", {})
    if ai_eval.get("required_direct_inputs") != ["PROMPT_CONTRACT", "LLM_OUTPUT_SCHEMA"] or ai_eval.get("conditional_inputs") != ["TEST_CASE_CATALOG"]:
        errors.append("AI_EVAL_CASES inputs must be Prompt/Schema plus conditional TEST_CASE_CATALOG")

    active_text_paths = collect_current_definition_paths(root, index=index, artifacts=artifacts)
    negative_context = re.compile(
        r"historical|retired|denylist|forbidden|不得|不进入|不作为|不能|do not|must not|not (?:current|active|an? )",
        re.I,
    )
    authority_claim = re.compile(
        r"(?:canonical path|accountable owner|lifecycle|direct inputs?)\s*(?:is|are|:)",
        re.I,
    )
    for path in active_text_paths:
        if not path.is_file() or path.suffix.lower() not in {".md", ".toml"}:
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for marker in ("docs/product/base/", "docs/product/increments/", "feature-spec-generate", "acceptance-criteria-generate"):
                if marker in line and not negative_context.search(line):
                    errors.append(
                        f"{path.relative_to(root)}:{line_number} contains retired positive runtime pointer: {marker}"
                    )
            if authority_claim.search(line) and not (
                negative_context.search(line)
                or "Governance Contract" in line
                or "GOVERNANCE_INDEX" in line
                or "Derived operational pointer" in line
            ):
                errors.append(
                    f"{path.relative_to(root)}:{line_number} may restate Governance Contract authority"
                )

    forbidden_runtime = (
        ".codex/hooks", "scripts/runtime_governance_resolver.py",
        "scripts/governance_preflight.py", "docs/process/governance/context_bundle",
    )
    for relative in forbidden_runtime:
        if (root / relative).exists():
            errors.append(f"project-local runtime governance mechanism exists: {relative}")

    if check_adr:
        errors.extend(validate_adr(root))
    if check_story_map:
        errors.extend(validate_story_map(root))

    for relative in ENGINEERING_LINEAGE_DOCS:
        path = root / relative
        if not path.is_file():
            errors.append(f"surviving Engineering Artifact is missing: {relative}")
        elif "PR-003 current lineage" not in path.read_text(encoding="utf-8")[:1800]:
            errors.append(f"{relative} lacks the PR-003 current-lineage marker")

    graph = collect_candidate_authority_graph(root)
    metrics = {
        "authority_graph_files": len(graph),
        "artifact_routes": len(routes),
        "gate_routes": len(gates),
    }
    return errors, metrics


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--check-adr", action="store_true")
    parser.add_argument("--check-story-map", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    selected = args.check_adr or args.check_story_map
    errors, metrics = validate_cutover(
        args.root, check_adr=args.check_adr if selected else True,
        check_story_map=args.check_story_map if selected else True,
    )
    if args.json:
        print(json.dumps({"errors": errors, "metrics": metrics}, ensure_ascii=False, indent=2))
    else:
        print("Story/Slice cutover validation")
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Authority graph files: {metrics.get('authority_graph_files', 0)}")
        print(f"Result: {'failed' if errors else 'passed'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
