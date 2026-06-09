#!/usr/bin/env python3
"""Validate P0.2 Followup-B S006 replay/performance/traceability closure."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(".")
INCREMENT = Path("docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory")
TEST_CASES = INCREMENT / "test_cases.md"
TRACEABILITY = INCREMENT / "traceability.md"
TEST_REPORT = Path("docs/reports/test_report.md")
IMPLEMENTATION_REPORT = Path("docs/reports/implementation_report.md")
QUALITY_REPORT = Path("docs/reports/quality_report.md")
DEVELOPMENT_STATUS = Path("docs/product/development_status.md")

S006_ANCHOR = "2026-06-05-p02-followup-b-s006-replay-performance-traceability"
S006_REPORT_ID = "P02-FOLLOWUP-B-S006-REPLAY-PERFORMANCE-TRACEABILITY-20260605"
XCB003_ANCHOR = "2026-06-09-p02-followup-b-xcb-003-reminder-eligibility-endpoint-closure"
XCB003_REPORT_ID = "P02-FOLLOWUP-B-XCB-003-REMINDER-ELIGIBILITY-ENDPOINT-20260609"

REQUIRED_FILES = [
    TEST_CASES,
    TRACEABILITY,
    TEST_REPORT,
    IMPLEMENTATION_REPORT,
    QUALITY_REPORT,
    DEVELOPMENT_STATUS,
    Path("backend/src/test/java/com/speakeasy/goal/GoalAutopilotReplayFixtureTest.java"),
    Path("backend/src/test/java/com/speakeasy/goal/GoalAutopilotControlPerformanceTest.java"),
    Path("scripts/check_p0_2_followup_b_traceability.py"),
    Path("scripts/check_p0_2_goal_autopilot_coverage.py"),
    Path("backend/src/main/java/com/speakeasy/api/GoalAutopilotController.java"),
    Path("backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java"),
    Path("backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java"),
    Path("backend/src/test/java/com/speakeasy/goal/GoalAutopilotRuntimeGateTest.java"),
    Path("docs/architecture/openapi/speakeasy-api.yaml"),
    Path("lib/generated/api/speakeasy_api.dart"),
]

TC_EXPECTATIONS = {
    "TC-P02-FUB-015": [
        "backend/src/test/java/com/speakeasy/goal/GoalAutopilotReplayFixtureTest.java",
        "GoalAutopilotReplayFixtureTest",
        "passed",
        S006_ANCHOR,
    ],
    "TC-P02-FUB-016": [
        "backend/src/test/java/com/speakeasy/goal/GoalAutopilotControlPerformanceTest.java",
        "GoalAutopilotControlPerformanceTest",
        "passed",
        S006_ANCHOR,
    ],
    "TC-P02-FUB-017": [
        "scripts/check_p0_2_followup_b_traceability.py",
        "scripts/check_p0_2_goal_autopilot_coverage.py",
        "passed",
        S006_ANCHOR,
    ],
    "TC-P02-FUB-018": [
        "GoalAutopilotControllerTest.java#tcP02Fub018ReminderEligibilityEndpointEvaluatesRequestBoundary",
        "GoalAutopilotControllerTest.java#tcP02Fub018ReminderEligibilityRecoveryRequiredDoesNotReturnEligible",
        "GoalAutopilotRuntimeGateTest.java#tcP02Fud002KillSwitchHidesExistingProjectionAndFailsClosed",
        "docs/architecture/openapi/speakeasy-api.yaml",
        "scripts/check_p0_2_followup_b_traceability.py",
        "passed",
        XCB003_ANCHOR,
    ],
}

TRACEABILITY_TERMS = [
    "P02-FUB-TR-008",
    "P02-FUB-TR-009",
    "TC-P02-FUB-015 passed",
    "TC-P02-FUB-016 passed",
    "TC-P02-FUB-017 passed",
    "GoalAutopilotReplayFixtureTest",
    "GoalAutopilotControlPerformanceTest",
    "check_p0_2_followup_b_traceability.py",
    "FUB-FIX-008",
    "FUB-FIX-009",
    S006_ANCHOR,
    "P02-FUB-TR-003",
    "P02-FUB-TR-004",
    "TC-P02-FUB-018 passed",
    "GoalAutopilotController#evaluateReminderEligibility",
    "GoalAutopilotService#evaluateReminderEligibility",
    "XCB-003",
    XCB003_ANCHOR,
]

REPORT_TERMS = {
    TEST_REPORT: [
        S006_REPORT_ID,
        "TC-P02-FUB-015",
        "TC-P02-FUB-016",
        "TC-P02-FUB-017",
        "GoalAutopilotReplayFixtureTest",
        "GoalAutopilotControlPerformanceTest",
        "python3 scripts/check_p0_2_followup_b_traceability.py",
        "python3 scripts/check_p0_2_goal_autopilot_coverage.py",
        "Followup-B is not release-ready",
        "Product Base merge is not approved",
        XCB003_REPORT_ID,
        "TC-P02-FUB-018",
        "POST /goal-autopilot/reminders/eligibility",
        "GoalAutopilotControllerTest",
        "GoalAutopilotRuntimeGateTest",
        "malformed `current_time` 422",
        "recovery-required stale-plan blocking",
        "XCB-003",
    ],
    IMPLEMENTATION_REPORT: [
        S006_REPORT_ID,
        "P02-FUB-FR-008",
        "AC-P02-FUB-008",
        "TC-P02-FUB-015",
        "TC-P02-FUB-016",
        "TC-P02-FUB-017",
        "GoalAutopilotReplayFixtureTest.java",
        "GoalAutopilotControlPerformanceTest.java",
        "check_p0_2_followup_b_traceability.py",
        "No production backend or Flutter code changed",
        "Followup-B is not release-ready",
        XCB003_REPORT_ID,
        "P02-FUB-FR-003",
        "AC-P02-FUB-003",
        "TC-P02-FUB-018",
        "GoalAutopilotController.java",
        "GoalAutopilotService.java",
        "speakeasy-api.yaml",
        "malformed `current_time` 422",
        "recovery-required stale-plan blocking",
        "XCB-003",
    ],
    QUALITY_REPORT: [
        S006_REPORT_ID,
        "S006",
        "Independent Review",
        "TC-P02-FUB-015",
        "TC-P02-FUB-016",
        "TC-P02-FUB-017",
        "No blocker",
        "Followup-B is not release-ready",
        "Product Base merge is not approved",
        XCB003_REPORT_ID,
        "TC-P02-FUB-018",
        "Independent Review",
        "POST /goal-autopilot/reminders/eligibility",
        "recovery-required eligibility",
        "malformed `current_time`",
        "XCB-003",
    ],
}

FORBIDDEN_RELEASE_CLAIMS = [
    "Followup-B is release-ready",
    "Followup-B release approved",
    "Product Base merge approved",
    "Followup-C/D completed",
]


def read(path: Path) -> str:
    full_path = ROOT / path
    if not full_path.exists():
        raise SystemExit(f"Missing required Followup-B evidence file: {path}")
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

    for fixture_id in [f"FUB-FIX-{index:03d}" for index in range(1, 10)]:
        if fixture_id not in text:
            raise SystemExit(f"Missing fixture routing {fixture_id} in {TEST_CASES}")


def validate_traceability() -> None:
    text = read(TRACEABILITY)
    for term in TRACEABILITY_TERMS:
        if term not in text:
            raise SystemExit(f"Missing traceability closure term {term!r} in {TRACEABILITY}")

    for trace_id in ["P02-FUB-TR-003", "P02-FUB-TR-004", "P02-FUB-TR-008", "P02-FUB-TR-009"]:
        row = next((line for line in text.splitlines() if line.startswith(f"| {trace_id} |")), None)
        if row is None:
            raise SystemExit(f"Missing {trace_id} row in {TRACEABILITY}")
        if "Planned" in row or "Not started" in row:
            raise SystemExit(f"{trace_id} row still contains planned/not-started status")


def validate_reports() -> None:
    for path, terms in REPORT_TERMS.items():
        require_terms(path, terms)

    combined = "\n".join(read(path) for path in [TEST_REPORT, IMPLEMENTATION_REPORT, QUALITY_REPORT, DEVELOPMENT_STATUS])
    for claim in FORBIDDEN_RELEASE_CLAIMS:
        if claim in combined:
            raise SystemExit(f"Forbidden release/completion claim found: {claim}")


def main() -> int:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            raise SystemExit(f"Missing required Followup-B S006 file: {path}")

    validate_test_cases()
    validate_traceability()
    validate_reports()

    print("P0.2 Followup-B S006 traceability gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
