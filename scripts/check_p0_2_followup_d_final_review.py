#!/usr/bin/env python3
"""Validate P0.2 Followup-D S011 final review closure."""

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

S011_ANCHOR = "2026-06-07-p02-followup-d-s011-final-review"
S011_REVIEW_ANCHOR = "2026-06-07-p02-followup-d-s011-final-review-independent-review"
S011_REPORT_ID = "P02-FOLLOWUP-D-S011-FINAL-REVIEW-20260607"
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
    Path("scripts/check_p0_2_followup_d_traceability.py"),
    Path("scripts/check_p0_2_followup_d_final_review.py"),
    Path("scripts/check_release_readiness.sh"),
]

TC_EXPECTATIONS = {
    "TC-P02-FUD-020": [
        "scripts/check_p0_2_followup_d_final_review.py",
        "python3 scripts/check_p0_2_followup_d_final_review.py",
        "python3 scripts/validate_governance_contracts.py",
        "git diff --check",
        "passed",
        S011_ANCHOR,
    ],
    "TC-P02-FUD-021": [
        "docs/reports/quality_report.md",
        "docs/release/release_checklist.md",
        "Product engineer and software engineer independent review recorded with blocker/no-blocker finding",
        "passed",
        S011_REVIEW_ANCHOR,
    ],
}

TRACEABILITY_TERMS = [
    "P02-FUD-TR-011",
    "TC-P02-FUD-020/021 passed",
    "scripts/check_p0_2_followup_d_final_review.py",
    "python3 scripts/validate_governance_contracts.py",
    "git diff --check",
    "strict release readiness failed as expected",
    "external release evidence remains blocked",
    "paid AI external evidence remains blocked",
    "Product Base merge is not approved",
    "Followup-D is not release-ready",
    S011_ANCHOR,
    S011_REVIEW_ANCHOR,
]

REPORT_TERMS = {
    TEST_REPORT: [
        S011_REPORT_ID,
        "TC-P02-FUD-020",
        "TC-P02-FUD-021",
        "python3 scripts/check_p0_2_followup_d_final_review.py",
        "python3 scripts/validate_governance_contracts.py",
        "git diff --check",
        "strict release readiness failed as expected",
        "Product engineer and software engineer independent review recorded with blocker/no-blocker finding",
        "Followup-D is not release-ready",
        "Product Base merge is not approved",
    ],
    IMPLEMENTATION_REPORT: [
        S011_REPORT_ID,
        "P02-FUD-FR-011",
        "P02-FUD-SPEC-011",
        "AC-P02-FUD-011",
        "TC-P02-FUD-020",
        "TC-P02-FUD-021",
        "scripts/check_p0_2_followup_d_final_review.py",
        "release_checklist.md",
        "quality_report.md",
        "No production backend, Flutter or API shape changed",
        "Followup-D is not release-ready",
    ],
    QUALITY_REPORT: [
        S011_REPORT_ID,
        "Independent Review",
        "Product engineer review",
        "Software engineer review",
        "No local S011 blocker",
        "strict release readiness failed as expected",
        "Followup-D is not release-ready",
        "Product Base merge is not approved",
    ],
    DEVELOPMENT_STATUS: [
        S011_REPORT_ID,
        "TC-P02-FUD-020/021 passed",
        "Followup-D is not release-ready",
        "Product Base merge is not approved",
    ],
}

RELEASE_CHECKLIST_TERMS = [
    "Status: local S001-S011 final review passed / blocked until Product Base merge approval and external release evidence",
    "TC-P02-FUD-020",
    "TC-P02-FUD-021",
    S011_REPORT_ID,
    "Followup-D is not release-ready",
    "Product Base merge is not approved",
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
        raise SystemExit(f"Missing required Followup-D S011 file: {path}")
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
        if "planned" in row.lower():
            raise SystemExit(f"{tc_id} row in {TEST_CASES} still contains planned state")

    if "AC-P02-FUD-011 | TC-P02-FUD-020 | TC-P02-FUD-021 | Passed locally" not in text:
        raise SystemExit("AC-P02-FUD-011 coverage row is not marked passed locally")
    if "FUD-FIX-011" not in text or "TC-P02-FUD-020..021 passed locally" not in text:
        raise SystemExit("FUD-FIX-011 fixture routing is not marked passed locally")


def validate_traceability() -> None:
    text = read(TRACEABILITY)
    for term in TRACEABILITY_TERMS:
        if term not in text:
            raise SystemExit(f"Missing traceability final-review term {term!r} in {TRACEABILITY}")

    row = next((line for line in text.splitlines() if line.startswith("| P02-FUD-TR-011 |")), None)
    if row is None:
        raise SystemExit(f"Missing P02-FUD-TR-011 row in {TRACEABILITY}")
    if "Planned" in row or "Not started" in row:
        raise SystemExit("P02-FUD-TR-011 row still contains planned/not-started status")


def validate_reports() -> None:
    for path, terms in REPORT_TERMS.items():
        require_terms(path, terms)

    combined = "\n".join(
        read(path) for path in [TEST_REPORT, IMPLEMENTATION_REPORT, QUALITY_REPORT, DEVELOPMENT_STATUS]
    )
    for claim in FORBIDDEN_RELEASE_CLAIMS:
        if claim in combined:
            raise SystemExit(f"Forbidden release/completion claim found: {claim}")


def validate_release_docs() -> None:
    require_terms(RELEASE_CHECKLIST, RELEASE_CHECKLIST_TERMS)
    release_text = read(RELEASE_CHECKLIST)
    for blocker in [
        "Commercial release external evidence remains blocked",
        "Paid AI external evidence remains blocked",
        "Strict `scripts/check_release_readiness.sh` remains blocked",
    ]:
        if blocker not in release_text:
            raise SystemExit(f"Release checklist must preserve blocker: {blocker}")

    rollback_text = read(ROLLBACK_PLAN)
    if "P0.2 Followup-D Goal Autopilot Release Gate Change" not in rollback_text:
        raise SystemExit("Rollback plan must preserve Followup-D rollback entry")
    if "scripts/check_p0_2_followup_d_final_review.py" not in rollback_text:
        raise SystemExit("Rollback plan must include the S011 final review checker")


def main() -> int:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            raise SystemExit(f"Missing required Followup-D S011 file: {path}")

    require_terms(DEFINITION, ["P02-FUD-S011", "S011"])
    require_terms(REQUIREMENTS, ["P02-FUD-FR-011", "S011"])
    require_terms(SPEC, ["P02-FUD-SPEC-011", "PMDecisionPending"])
    require_terms(ACCEPTANCE, ["AC-P02-FUD-011", "paid AI external evidence is missing"])
    require_terms(TEST_REPORT, [S010_REPORT_ID])

    validate_test_cases()
    validate_traceability()
    validate_reports()
    validate_release_docs()

    print("P0.2 Followup-D S011 final review gate passed with release/Product Base blockers preserved")
    return 0


if __name__ == "__main__":
    sys.exit(main())
