#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_PATH = "codex/templates/swc_allocation.template.md"
SWC_CATALOG_PATH = "docs/architecture/swc_catalog.md"
SWC_ARCHITECTURE_PATH = "docs/architecture/software_component_architecture.md"

IMPLEMENTATION_PREFIXES = (
    "lib/",
    "backend/src/main/java/",
    "backend/src/main/resources/db/migration/",
)
IMPLEMENTATION_FILES = {
    "docs/architecture/openapi/speakeasy-api.yaml",
}
IMPLEMENTATION_EXCLUDED_PREFIXES = (
    "test/",
    "integration_test/",
    "backend/src/test/",
    "lib/generated/api/",
)
SCENARIO_PRACTICE_PREFIXES = (
    "lib/features/interview/",
    "lib/application/scene/",
    "lib/application/practice_runtime/",
    "lib/features/scenario/",
)
SCENARIO_PRACTICE_FILES = {
    "lib/services/audio_service.dart",
    "lib/services/voice_chat_service.dart",
    "lib/services/voice_turn_orchestrator.dart",
    "lib/services/api_client.dart",
    "lib/services/app_session.dart",
    "lib/application/session/session_stats_coordinator.dart",
    "lib/services/stats_service.dart",
    "lib/models/learning_stats_model.dart",
}
SCENARIO_REQUIRED_SWCS = {
    "FE-SCENARIO-PRACTICE",
    "FE-PRACTICE-RUNTIME",
}
SCENARIO_REQUIRED_FLOW = "SWC-FLOW-SCENARIO-PRACTICE-RUNTIME"

VALID_CHANGE_MODES = {
    "brownfield-update",
    "behavior-preserving-refactor",
    "greenfield-with-no-existing-implementation",
}
BROWNFIELD_CHANGE_MODES = {
    "brownfield-update",
    "behavior-preserving-refactor",
}

ALLOCATION_RE = re.compile(r"^docs/product/increments/([^/]+)/swc_allocation\.md$")
TRACEABILITY_RE = re.compile(r"^docs/product/increments/([^/]+)/traceability\.md$")
SECTION_RE_TEMPLATE = r"(?ms)^## {heading}\s*\n(.*?)(?=^## |\Z)"
SWC_ID_RE = re.compile(r"(?<![A-Z0-9-])(?:FE|BE|DB|AI|OPS)-[A-Z0-9][A-Z0-9-]*\b")
FLOW_ID_RE = re.compile(r"\bSWC-FLOW-[A-Z0-9-]+\b")

REQUIRED_TEMPLATE_SECTIONS = (
    "## Scope",
    "## Existing Implementation Baseline",
    "## Delta From Existing Baseline",
    "## Baseline References",
    "## System Responsibility Allocation",
    "## Requirement Allocation Matrix",
    "## SWC Data Flows",
    "## Reuse And Forbidden Boundaries",
    "## Verification",
)

MODERN_MATRIX_COLUMNS = (
    "Traceability Row ID",
    "Increment ID",
    "WP ID",
    "FR",
    "Spec",
    "AC",
    "FE SWC",
    "BE SWC",
    "API/OpenAPI",
    "Domain Entity",
    "DB Table/Migration",
    "Provider/AI Boundary",
    "TC",
    "Notes",
)

# Compatibility for allocations created during the earlier Story/Slice migration.
MODERN_PARENT_CHAIN_MATRIX_COLUMNS = (
    "User Story ID",
    "Vertical Slice ID",
    "Increment ID",
    "WP ID",
    "FR",
    "Spec",
    "AC",
    "FE SWC",
    "BE SWC",
    "API/OpenAPI",
    "Domain Entity",
    "DB Table/Migration",
    "Provider/AI Boundary",
    "TC",
    "Notes",
)

LEGACY_MATRIX_COLUMNS = (
    "Stage Scope ID",
    "FR",
    "Spec",
    "AC",
    "FE SWC",
    "BE SWC",
    "API/OpenAPI",
    "Domain Entity",
    "DB Table/Migration",
    "Provider/AI Boundary",
    "TC",
    "Notes",
)

BASELINE_ITEMS = (
    "Existing user flow",
    "Existing code paths",
    "Existing SWCs",
    "Existing global Flow IDs",
    "Existing API/OpenAPI calls",
    "Existing domain/data ownership",
    "Existing tests/evidence",
    "Behavior that must not regress",
    "Known legacy/deprecated parts",
)

DELTA_ITEMS = (
    "Reused SWCs",
    "Reused Flow IDs",
    "Changed behavior",
    "Unchanged behavior",
    "New code allowed",
    "New code forbidden",
    "Existing code modified",
    "Migration/deprecation impact",
    "Regression proof required",
)

GENERIC_OWNERSHIP_VALUES = {
    "frontend",
    "front end",
    "fe",
    "backend",
    "back end",
    "be",
    "database",
    "db",
    "provider",
    "ai",
    "ops",
}

CODE_PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_/-])(?:"
    r"lib/[A-Za-z0-9_.-]+/[A-Za-z0-9_./*-]+|"
    r"backend/src/main/java/(?:[A-Za-z0-9_.-]+/){2,}[A-Za-z0-9_./*-]+|"
    r"backend/src/main/resources/db/migration/[A-Za-z0-9_./*-]+|"
    r"docs/architecture/openapi/[A-Za-z0-9_.-]+|"
    r"test/[A-Za-z0-9_./*-]+|"
    r"tests/[A-Za-z0-9_./*-]+|"
    r"integration_test/[A-Za-z0-9_./*-]+"
    r")"
)
TEST_EVIDENCE_RE = re.compile(r"(?:\b(?:MIG-)?TC-[A-Z0-9-]+|\btest/|\btests/|\bintegration_test/|\bbackend/src/test/)")


@dataclass(frozen=True)
class Finding:
    path: str
    message: str


def repo_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def run_git(args: list[str]) -> list[str]:
    completed = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        return []
    return [line.strip().replace("\\", "/") for line in completed.stdout.splitlines() if line.strip()]


def git_index_path_exists(relative_path: str) -> bool:
    completed = subprocess.run(
        ["git", "cat-file", "-e", f":{relative_path}"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return completed.returncode == 0


def changed_paths(base_ref: str | None, include_worktree: bool) -> list[str]:
    names: set[str] = set()
    if base_ref and not re.fullmatch(r"0{40}", base_ref):
        names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT", f"{base_ref}...HEAD"]))
        if not names:
            names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT", base_ref, "HEAD"]))
    if include_worktree:
        names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT"]))
        names.update(run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMRT"]))
        names.update(run_git(["ls-files", "--others", "--exclude-standard"]))
    return sorted(name for name in names if (ROOT / name).exists() or git_index_path_exists(name))


def all_allocation_paths() -> list[str]:
    root = ROOT / "docs/product/increments"
    if not root.exists():
        return []
    return sorted(repo_path(path) for path in root.glob("*/swc_allocation.md"))


def read_text(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8", errors="replace")


def is_implementation_path(relative: str) -> bool:
    if any(relative.startswith(prefix) for prefix in IMPLEMENTATION_EXCLUDED_PREFIXES):
        return False
    return relative in IMPLEMENTATION_FILES or any(relative.startswith(prefix) for prefix in IMPLEMENTATION_PREFIXES)


def section(text: str, heading: str) -> str:
    pattern = re.compile(SECTION_RE_TEMPLATE.format(heading=re.escape(heading)))
    match = pattern.search(text)
    return match.group(1).strip() if match else ""


def markdown_table(section_text: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in section_text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|") or not stripped.endswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if cells and all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells):
            continue
        rows.append(cells)
    return rows


def table_lookup(section_text: str, key: str) -> str | None:
    for row in markdown_table(section_text):
        if len(row) >= 2 and row[0] == key:
            return row[1]
    return None


def clean_inline_markdown(value: str) -> str:
    return re.sub(r"[`*_]", "", value).strip()


def is_explicit_na(value: str | None) -> bool:
    if value is None:
        return False
    return clean_inline_markdown(value).lower().startswith("n/a -")


def has_real_value(value: str | None) -> bool:
    if value is None:
        return False
    stripped = value.strip()
    if not stripped:
        return False
    normalized = clean_inline_markdown(stripped).lower()
    placeholders = {"tbd", "todo", "pending", "unknown", "<todo>", "<tbd>", "n/a", "na", "not applicable"}
    return normalized not in placeholders


def extract_change_mode(text: str) -> str | None:
    match = re.search(r"(?mi)^-\s*Change mode:\s*(.+?)\s*$", text)
    if not match:
        return None
    return clean_inline_markdown(match.group(1)).lower()


def generic_allocation_value(value: str) -> bool:
    normalized = clean_inline_markdown(value).lower()
    if normalized in GENERIC_OWNERSHIP_VALUES:
        return True
    if "swc" in normalized and (re.search(r"\ball\b", normalized) or "referenced" in normalized):
        return True
    generic_swc = r"(?:frontend|front end|backend|back end|fe|be)\s+swcs?"
    return bool(re.search(rf"\b{generic_swc}\b", normalized) and not SWC_ID_RE.search(value))


def has_code_path_evidence(value: str | None) -> bool:
    return bool(value and CODE_PATH_RE.search(value))


def has_test_evidence(value: str | None) -> bool:
    return bool(value and TEST_EVIDENCE_RE.search(value))


def load_known_ids() -> tuple[set[str], set[str], list[Finding]]:
    findings: list[Finding] = []
    known_swcs: set[str] = set()
    known_flows: set[str] = set()
    for relative, regex, target in (
        (SWC_CATALOG_PATH, SWC_ID_RE, known_swcs),
        (SWC_ARCHITECTURE_PATH, FLOW_ID_RE, known_flows),
    ):
        path = ROOT / relative
        if not path.exists():
            findings.append(Finding(relative, "Required global SWC source-of-truth file is missing."))
            continue
        target.update(regex.findall(read_text(relative)))
    return known_swcs, known_flows, findings


def flow_is_known(flow_id: str, known_flows: set[str]) -> bool:
    return flow_id in known_flows or any(flow_id.startswith(f"{known}-") for known in known_flows)


def validate_template() -> list[Finding]:
    findings: list[Finding] = []
    if not (ROOT / TEMPLATE_PATH).exists():
        return [Finding(TEMPLATE_PATH, "SWC allocation template is missing.")]
    text = read_text(TEMPLATE_PATH)
    for required in REQUIRED_TEMPLATE_SECTIONS:
        if required not in text:
            findings.append(Finding(TEMPLATE_PATH, f"Template missing required section {required}."))
    for item in (*BASELINE_ITEMS, *DELTA_ITEMS):
        if item not in text:
            findings.append(Finding(TEMPLATE_PATH, f"Template missing required brownfield field: {item}."))
    if "Change mode:" not in text:
        findings.append(Finding(TEMPLATE_PATH, "Template must require Change mode in Scope."))
    rows = markdown_table(section(text, "Requirement Allocation Matrix"))
    headers = rows[0] if rows else []
    missing = [column for column in MODERN_MATRIX_COLUMNS if column not in headers]
    if missing:
        findings.append(Finding(TEMPLATE_PATH, f"Template Requirement Allocation Matrix missing direct-upstream columns: {', '.join(missing)}."))
    return findings


def validate_requirement_matrix(relative: str, text: str) -> list[Finding]:
    findings: list[Finding] = []
    rows = markdown_table(section(text, "Requirement Allocation Matrix"))
    if len(rows) < 2:
        return [Finding(relative, "Requirement Allocation Matrix must include headers and at least one allocation row.")]
    headers = rows[0]
    accepted_shapes = (MODERN_MATRIX_COLUMNS, MODERN_PARENT_CHAIN_MATRIX_COLUMNS, LEGACY_MATRIX_COLUMNS)
    if not any(all(column in headers for column in shape) for shape in accepted_shapes):
        missing = [column for column in MODERN_MATRIX_COLUMNS if column not in headers]
        findings.append(Finding(relative, f"Requirement Allocation Matrix missing direct-upstream columns: {', '.join(missing)}."))
        return findings
    fe_index = headers.index("FE SWC")
    be_index = headers.index("BE SWC")
    for row_number, row in enumerate(rows[1:], start=1):
        if len(row) < len(headers):
            findings.append(Finding(relative, f"Requirement Allocation Matrix row {row_number} has too few cells."))
            continue
        for label, index in (("FE SWC", fe_index), ("BE SWC", be_index)):
            value = row[index].strip()
            if not has_real_value(value):
                findings.append(Finding(relative, f"Requirement Allocation Matrix row {row_number} has empty {label}."))
                continue
            if is_explicit_na(value):
                continue
            if generic_allocation_value(value):
                findings.append(
                    Finding(relative, f"Requirement Allocation Matrix row {row_number} uses generic {label} value `{value}`; name concrete SWC IDs or explicit N/A reason.")
                )
            if not SWC_ID_RE.search(value):
                findings.append(
                    Finding(relative, f"Requirement Allocation Matrix row {row_number} {label} must name concrete SWC IDs or start with `N/A - <reason>`.")
                )
    return findings


def validate_brownfield_inheritance(relative: str, baseline: str, delta: str) -> list[Finding]:
    findings: list[Finding] = []
    baseline_values = {item: table_lookup(baseline, item) for item in BASELINE_ITEMS}
    delta_values = {item: table_lookup(delta, item) for item in DELTA_ITEMS}

    for item, value in (*baseline_values.items(), *delta_values.items()):
        if value and "n/a - greenfield" in clean_inline_markdown(value).lower():
            findings.append(Finding(relative, f"Brownfield/refactor allocation cannot use greenfield placeholder for `{item}`."))

    if not has_code_path_evidence(baseline_values.get("Existing code paths")):
        findings.append(Finding(relative, "Brownfield/refactor baseline must cite concrete existing code paths."))
    if not SWC_ID_RE.search(baseline_values.get("Existing SWCs") or ""):
        findings.append(Finding(relative, "Brownfield/refactor baseline must cite existing concrete SWC IDs."))
    if not FLOW_ID_RE.search(baseline_values.get("Existing global Flow IDs") or ""):
        findings.append(Finding(relative, "Brownfield/refactor baseline must cite existing global Flow IDs."))
    if is_explicit_na(baseline_values.get("Existing API/OpenAPI calls")):
        findings.append(Finding(relative, "Brownfield/refactor baseline must inherit existing API/OpenAPI or legacy API evidence, not mark it N/A."))
    if not has_test_evidence(baseline_values.get("Existing tests/evidence")):
        findings.append(Finding(relative, "Brownfield/refactor baseline must cite existing test paths or stable TC IDs."))
    if is_explicit_na(baseline_values.get("Behavior that must not regress")):
        findings.append(Finding(relative, "Brownfield/refactor baseline must name behavior that must not regress."))

    if not SWC_ID_RE.search(delta_values.get("Reused SWCs") or ""):
        findings.append(Finding(relative, "Brownfield/refactor delta must cite concrete reused SWC IDs."))
    if not FLOW_ID_RE.search(delta_values.get("Reused Flow IDs") or ""):
        findings.append(Finding(relative, "Brownfield/refactor delta must cite reused Flow IDs."))

    new_code_allowed = delta_values.get("New code allowed")
    if not has_code_path_evidence(new_code_allowed) and "no new code" not in clean_inline_markdown(new_code_allowed or "").lower():
        findings.append(Finding(relative, "Brownfield/refactor delta must cite allowed new code paths or explicitly say `N/A - no new code`."))
    existing_code_modified = delta_values.get("Existing code modified")
    if not has_code_path_evidence(existing_code_modified) and "no existing code" not in clean_inline_markdown(existing_code_modified or "").lower():
        findings.append(Finding(relative, "Brownfield/refactor delta must cite existing code paths allowed to change or explicitly say no existing code may change."))
    if is_explicit_na(delta_values.get("New code forbidden")):
        findings.append(Finding(relative, "Brownfield/refactor delta must name forbidden duplicate implementation boundaries."))
    if not has_test_evidence(delta_values.get("Regression proof required")):
        findings.append(Finding(relative, "Brownfield/refactor delta must cite regression TC IDs or test paths."))
    return findings


def validate_allocation(relative: str, known_swcs: set[str], known_flows: set[str]) -> list[Finding]:
    findings: list[Finding] = []
    text = read_text(relative)
    for required in REQUIRED_TEMPLATE_SECTIONS:
        if required not in text:
            findings.append(Finding(relative, f"Allocation missing required section {required}."))
    change_mode = extract_change_mode(text)
    if change_mode is None:
        findings.append(Finding(relative, "Scope must declare Change mode."))
    elif change_mode not in VALID_CHANGE_MODES:
        findings.append(Finding(relative, f"Scope has unsupported Change mode `{change_mode}`."))

    baseline = section(text, "Existing Implementation Baseline")
    for item in BASELINE_ITEMS:
        value = table_lookup(baseline, item)
        if not has_real_value(value):
            findings.append(Finding(relative, f"Existing Implementation Baseline missing filled value for `{item}`."))

    delta = section(text, "Delta From Existing Baseline")
    for item in DELTA_ITEMS:
        value = table_lookup(delta, item)
        if not has_real_value(value):
            findings.append(Finding(relative, f"Delta From Existing Baseline missing filled value for `{item}`."))

    referenced_swcs = set(SWC_ID_RE.findall(text))
    unknown_swcs = sorted(swc for swc in referenced_swcs if swc not in known_swcs)
    if unknown_swcs:
        findings.append(Finding(relative, f"References SWC IDs not present in {SWC_CATALOG_PATH}: {', '.join(unknown_swcs)}."))

    referenced_flows = set(FLOW_ID_RE.findall(text))
    unknown_flows = sorted(flow for flow in referenced_flows if not flow_is_known(flow, known_flows))
    if unknown_flows:
        findings.append(Finding(relative, f"References Flow IDs not present in {SWC_ARCHITECTURE_PATH}: {', '.join(unknown_flows)}."))

    if "Reused SWCs" in text and not SWC_ID_RE.search(table_lookup(delta, "Reused SWCs") or ""):
        findings.append(Finding(relative, "Delta must name concrete reused SWC IDs."))
    if "Reused Flow IDs" in text and not FLOW_ID_RE.search(table_lookup(delta, "Reused Flow IDs") or ""):
        findings.append(Finding(relative, "Delta must name reused Flow IDs or classify a local flow."))

    if change_mode in BROWNFIELD_CHANGE_MODES:
        findings.extend(validate_brownfield_inheritance(relative, baseline, delta))

    findings.extend(validate_requirement_matrix(relative, text))
    return findings


def path_candidates(relative: str) -> list[str]:
    path = Path(relative)
    candidates = [relative]
    parents = list(path.parents)
    for parent in parents:
        parent_text = parent.as_posix()
        if parent_text in {"", "."}:
            continue
        candidate = f"{parent_text}/"
        if is_broad_path_candidate(candidate):
            continue
        candidates.append(candidate)
    return sorted(set(candidates), key=len, reverse=True)


def is_broad_path_candidate(candidate: str) -> bool:
    parts = [part for part in candidate.strip("/").split("/") if part]
    if not parts:
        return True
    if parts[0] == "lib" and len(parts) < 3:
        return True
    if parts[0] == "backend" and len(parts) < 6:
        return True
    if parts[0] in {"test", "tests", "integration_test"} and len(parts) < 2:
        return True
    if parts[0] == "docs" and len(parts) < 3:
        return True
    return False


def path_is_covered(relative: str, allocation_texts: list[str]) -> bool:
    candidates = path_candidates(relative)
    return any(candidate in text for text in allocation_texts for candidate in candidates)


def allocation_path_coverage_texts(text: str) -> list[str]:
    baseline = section(text, "Existing Implementation Baseline")
    delta = section(text, "Delta From Existing Baseline")
    return [
        table_lookup(baseline, "Existing code paths") or "",
        table_lookup(delta, "New code allowed") or "",
        table_lookup(delta, "Existing code modified") or "",
    ]


def no_swc_impact_decision(paths: list[str]) -> bool:
    for relative in paths:
        if not TRACEABILITY_RE.match(relative):
            continue
        text = read_text(relative)
        has_decision = "N/A - no SWC impact" in text
        has_reason = re.search(r"(?:Reason|Rationale|原因)\s*[:：]", text, re.IGNORECASE)
        has_governance_pass = re.search(
            r"(?:Software Architecture Governance Check|SWC Governance Review|Architecture Governance Check|independent checker)\s*[:：-]\s*(?:pass|accepted|approved)",
            text,
            re.IGNORECASE,
        )
        if has_decision and has_reason and has_governance_pass:
            return True
    return False


def is_scenario_practice_path(relative: str) -> bool:
    return relative in SCENARIO_PRACTICE_FILES or any(relative.startswith(prefix) for prefix in SCENARIO_PRACTICE_PREFIXES)


def validate_changed_implementation(changed: list[str], allocation_paths: list[str]) -> list[Finding]:
    findings: list[Finding] = []
    implementation_paths = [path for path in changed if is_implementation_path(path)]
    if not implementation_paths:
        return findings
    if not allocation_paths:
        if no_swc_impact_decision(changed):
            return findings
        findings.append(
            Finding(
                "changed files",
                "Implementation-impacting changes require a changed increment swc_allocation.md or a structured `N/A - no SWC impact` traceability decision with governance pass.",
            )
        )
        return findings

    allocation_texts = [read_text(path) for path in allocation_paths]
    coverage_texts = [coverage for text in allocation_texts for coverage in allocation_path_coverage_texts(text)]
    for relative in implementation_paths:
        if not path_is_covered(relative, coverage_texts):
            findings.append(
                Finding(
                    relative,
                    "Changed implementation path is not covered by Existing Implementation Baseline, New code allowed, or Existing code modified in the changed SWC allocation.",
                )
            )

    scenario_changes = [path for path in implementation_paths if is_scenario_practice_path(path)]
    if scenario_changes:
        merged_text = "\n".join(allocation_texts)
        missing_swcs = sorted(swc for swc in SCENARIO_REQUIRED_SWCS if swc not in merged_text)
        if SCENARIO_REQUIRED_FLOW not in merged_text:
            findings.append(
                Finding(
                    "changed files",
                    f"Scenario-practice changes must reuse {SCENARIO_REQUIRED_FLOW}; changed paths: {', '.join(scenario_changes)}.",
                )
            )
        if missing_swcs:
            findings.append(
                Finding(
                    "changed files",
                    f"Scenario-practice changes must reference existing SWCs before new design: {', '.join(missing_swcs)}.",
                )
            )
    return findings


def print_findings(findings: list[Finding]) -> None:
    print("SWC allocation gate")
    if not findings:
        print("Result: passed")
        return
    print("Result: failed")
    for finding in findings:
        print(f"- {finding.path}: {finding.message}")


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Validate SWC allocation brownfield baseline and CI gate coverage.")
    parser.add_argument("--scope", choices=("changed", "all"), default="changed")
    parser.add_argument("--base-ref")
    parser.add_argument("--include-worktree", action="store_true", help="Include unstaged, staged, and untracked files.")
    args = parser.parse_args(argv)

    findings: list[Finding] = []
    findings.extend(validate_template())
    known_swcs, known_flows, source_findings = load_known_ids()
    findings.extend(source_findings)

    changed = changed_paths(args.base_ref, args.include_worktree) if args.scope == "changed" else []
    allocation_paths = (
        sorted(path for path in changed if ALLOCATION_RE.match(path))
        if args.scope == "changed"
        else all_allocation_paths()
    )
    for allocation in allocation_paths:
        findings.extend(validate_allocation(allocation, known_swcs, known_flows))
    if args.scope == "changed":
        findings.extend(validate_changed_implementation(changed, allocation_paths))

    print_findings(findings)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
