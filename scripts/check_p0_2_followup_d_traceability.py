#!/usr/bin/env python3
"""Validate P0.2 Followup-D S010 contract/traceability/release drift closure."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(".")
INCREMENT = Path("docs/product/increments/p0-2-followup-d-release-gate-hardening")
DEFINITION = INCREMENT / "definition.md"
REQUIREMENTS = INCREMENT / "requirements.md"
SPEC = INCREMENT / "spec.md"
ACCEPTANCE = INCREMENT / "acceptance.md"
TEST_CASES = INCREMENT / "test_cases.md"
TRACEABILITY = INCREMENT / "traceability.md"
TEST_REPORT = Path("docs/reports/test_report.md")
IMPLEMENTATION_REPORT = Path("docs/reports/implementation_report.md")
QUALITY_REPORT = Path("docs/reports/quality_report.md")
DEVELOPMENT_STATUS = Path("docs/product/development_status.md")
RELEASE_CHECKLIST = Path("docs/release/release_checklist.md")
ROLLBACK_PLAN = Path("docs/release/rollback_plan.md")
OPENAPI_SPEC = Path("docs/architecture/openapi/speakeasy-api.yaml")
DART_DRIFT_MANIFEST = Path("docs/architecture/openapi/dart-client-drift-manifest.json")
DART_HASH_MARKER = Path("lib/generated/api/.openapi-sha256")
DART_API_REGISTRY = Path("lib/generated/api/speakeasy_api.dart")

S010_ANCHOR = "2026-06-07-p02-followup-d-s010-drift-gates"
S010_REVIEW_ANCHOR = "2026-06-07-p02-followup-d-s010-drift-gates-independent-review"
S010_REPORT_ID = "P02-FOLLOWUP-D-S010-DRIFT-GATES-20260607"

REQUIRED_FILES = [
    DEFINITION,
    REQUIREMENTS,
    SPEC,
    ACCEPTANCE,
    TEST_CASES,
    TRACEABILITY,
    TEST_REPORT,
    IMPLEMENTATION_REPORT,
    QUALITY_REPORT,
    DEVELOPMENT_STATUS,
    RELEASE_CHECKLIST,
    ROLLBACK_PLAN,
    OPENAPI_SPEC,
    DART_DRIFT_MANIFEST,
    DART_HASH_MARKER,
    DART_API_REGISTRY,
    Path("scripts/check_p0_2_followup_d_traceability.py"),
    Path("scripts/check_release_readiness.sh"),
    Path("package.json"),
]

TC_EXPECTATIONS = {
    "TC-P02-FUD-018": [
        "scripts/check_p0_2_followup_d_traceability.py",
        "python3 scripts/check_p0_2_followup_d_traceability.py",
        "passed",
        S010_ANCHOR,
    ],
    "TC-P02-FUD-019": [
        "docs/architecture/openapi/speakeasy-api.yaml",
        "docs/release/release_checklist.md",
        "docs/release/rollback_plan.md",
        "npm run check:api-contract",
        "npm run check:dart-client-drift",
        "scripts/check_release_readiness.sh --env-only",
        "bash -n scripts/check_release_readiness.sh",
        "passed",
        S010_ANCHOR,
    ],
}

TRACEABILITY_TERMS = [
    "P02-FUD-TR-010",
    "TC-P02-FUD-018/019 passed",
    "scripts/check_p0_2_followup_d_traceability.py",
    "npm run check:api-contract",
    "npm run check:dart-client-drift",
    "scripts/check_release_readiness.sh --env-only",
    "strict release readiness failed as expected",
    "docs/release/release_checklist.md",
    "docs/release/rollback_plan.md",
    S010_ANCHOR,
    S010_REVIEW_ANCHOR,
]

REPORT_TERMS = {
    TEST_REPORT: [
        S010_REPORT_ID,
        "TC-P02-FUD-018",
        "TC-P02-FUD-019",
        "python3 scripts/check_p0_2_followup_d_traceability.py",
        "npm run check:api-contract",
        "npm run check:dart-client-drift",
        "scripts/check_release_readiness.sh --env-only",
        "strict release readiness failed as expected",
        "S011",
        "Followup-D is not release-ready",
        "Product Base merge is not approved",
    ],
    IMPLEMENTATION_REPORT: [
        S010_REPORT_ID,
        "P02-FUD-FR-010",
        "AC-P02-FUD-010",
        "TC-P02-FUD-018",
        "TC-P02-FUD-019",
        "scripts/check_p0_2_followup_d_traceability.py",
        "release_checklist.md",
        "rollback_plan.md",
        "No production backend, Flutter or API shape changed",
        "Followup-D is not release-ready",
    ],
    QUALITY_REPORT: [
        S010_REPORT_ID,
        "S010",
        "Independent Review",
        "TC-P02-FUD-018",
        "TC-P02-FUD-019",
        "No blocker",
        "strict release readiness failed as expected",
        "Followup-D is not release-ready",
        "Product Base merge is not approved",
    ],
    DEVELOPMENT_STATUS: [
        S010_REPORT_ID,
        "TC-P02-FUD-018/019 passed",
        "S011",
        "Followup-D is not release-ready",
        "Product Base merge is not approved",
    ],
}

RELEASE_CHECKLIST_TERMS = [
    "2026-06-07 P0.2 Followup-D Release Gate Hardening",
    "TC-P02-FUD-018",
    "TC-P02-FUD-019",
    S010_REPORT_ID,
    "Followup-D is not release-ready",
    "Product Base merge is not approved",
]

ROLLBACK_TERMS = [
    "P0.2 Followup-D Goal Autopilot Release Gate Change",
    "feature flag",
    "kill switch",
    "goal_autopilot_metric_events",
    "Preserve audit logs",
]

FORBIDDEN_RELEASE_CLAIMS = [
    "Followup-D is release-ready",
    "Followup-D release approved",
    "Followup-D is complete",
    "Followup-D completed",
    "Product Base merge approved",
    "commercial release approved",
    "paid AI external evidence closed",
]


def read(path: Path) -> str:
    full_path = ROOT / path
    if not full_path.exists():
        raise SystemExit(f"Missing required Followup-D S010 file: {path}")
    return full_path.read_text(encoding="utf-8")


def require_terms(path: Path, terms: list[str]) -> None:
    text = read(path)
    for term in terms:
        if term not in text:
            raise SystemExit(f"Missing required term {term!r} in {path}")


def tc_row(text: str, tc_id: str) -> str:
    rows = [line for line in text.splitlines() if line.startswith(f"| {tc_id} |")]
    if len(rows) != 1:
        raise SystemExit(f"Expected exactly one {tc_id} row in {TEST_CASES}, found {len(rows)}")
    return rows[0]


def validate_test_cases() -> None:
    text = read(TEST_CASES)
    for tc_id, terms in TC_EXPECTATIONS.items():
        row = tc_row(text, tc_id)
        for term in terms:
            if term not in row:
                raise SystemExit(f"{tc_id} row in {TEST_CASES} is missing {term!r}")

    if "AC-P02-FUD-010 | TC-P02-FUD-018 | TC-P02-FUD-019 | Passed locally" not in text:
        raise SystemExit("AC-P02-FUD-010 coverage row is not marked passed locally")
    if "FUD-FIX-010" not in text or "TC-P02-FUD-018..019 passed locally" not in text:
        raise SystemExit("FUD-FIX-010 fixture routing is not marked passed locally")
    if "S011 implementation remains planned" not in text and "S011 final review" not in text:
        raise SystemExit("S010 test cases must preserve S011 planned or final-review state")


def validate_traceability() -> None:
    text = read(TRACEABILITY)
    for term in TRACEABILITY_TERMS:
        if term not in text:
            raise SystemExit(f"Missing traceability closure term {term!r} in {TRACEABILITY}")

    row = next((line for line in text.splitlines() if line.startswith("| P02-FUD-TR-010 |")), None)
    if row is None:
        raise SystemExit(f"Missing P02-FUD-TR-010 row in {TRACEABILITY}")
    if "Planned" in row or "Not started" in row:
        raise SystemExit("P02-FUD-TR-010 row still contains planned/not-started status")
    if "S011" not in text or "release approval and Product Base merge blocked" not in text:
        raise SystemExit("Traceability must keep S011 and release/Product Base blockers explicit")


def validate_reports() -> None:
    for path, terms in REPORT_TERMS.items():
        require_terms(path, terms)

    combined = "\n".join(read(path) for path in [TEST_REPORT, IMPLEMENTATION_REPORT, QUALITY_REPORT, DEVELOPMENT_STATUS])
    for claim in FORBIDDEN_RELEASE_CLAIMS:
        if claim in combined:
            raise SystemExit(f"Forbidden release/completion claim found: {claim}")


def validate_release_docs() -> None:
    require_terms(RELEASE_CHECKLIST, RELEASE_CHECKLIST_TERMS)
    require_terms(ROLLBACK_PLAN, ROLLBACK_TERMS)

    release_text = read(RELEASE_CHECKLIST)
    allowed_statuses = [
        "Status: local S001-S010 passed / blocked until S011 final Product Base/release review and external release evidence",
        "Status: local S001-S011 final review passed / blocked until Product Base merge approval and external release evidence",
    ]
    if not any(status in release_text for status in allowed_statuses):
        raise SystemExit("Release checklist must preserve S010 or S011 Followup-D status")
    if "S011 final Product Base/release review" not in release_text:
        raise SystemExit("Release checklist must preserve the S011 final review blocker")
    if "external release evidence" not in release_text:
        raise SystemExit("Release checklist must preserve external evidence blockers")


def validate_openapi_contract_refs() -> None:
    package_json = read(Path("package.json"))
    for script_name in ["check:api-contract", "check:dart-client-drift"]:
        if script_name not in package_json:
            raise SystemExit(f"package.json is missing {script_name}")

    hash_marker = read(DART_HASH_MARKER).strip()
    manifest = read(DART_DRIFT_MANIFEST)
    if hash_marker and hash_marker not in manifest:
        raise SystemExit("Generated Dart hash marker is not represented in dart-client-drift-manifest.json")


def main() -> int:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            raise SystemExit(f"Missing required Followup-D S010 file: {path}")

    validate_test_cases()
    validate_traceability()
    validate_reports()
    validate_release_docs()
    validate_openapi_contract_refs()

    print("P0.2 Followup-D S010 traceability/release drift gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
