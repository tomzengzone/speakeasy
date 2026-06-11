#!/usr/bin/env python3
"""Validate P0.2 Followup-C S007 performance/coverage/traceability closure."""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(".")
INCREMENT = Path("docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces")
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
OPENAPI_SPEC = Path("docs/architecture/openapi/speakeasy-api.yaml")
DART_DRIFT_MANIFEST = Path("docs/architecture/openapi/dart-client-drift-manifest.json")
DART_HASH_MARKER = Path("lib/generated/api/.openapi-sha256")
DART_API_REGISTRY = Path("lib/generated/api/speakeasy_api.dart")

S007_ANCHOR = "2026-06-06-p02-followup-c-s007-quality-gates"
S007_REVIEW_ANCHOR = "2026-06-06-p02-followup-c-s007-final-independent-review"
S007_REPORT_ID = "P02-FOLLOWUP-C-S007-QUALITY-GATES-20260606"
S007_OPENAPI_CLEANUP_ID = "P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606"
S007_OPENAPI_SHA = "d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f"
XCB005_ANCHOR = "2026-06-11-p02-xcb005-goal-autopilot-fact-boundaries"
XCB005_REPORT_ID = "P02-XCB005-GOAL-AUTOPILOT-FACT-BOUNDARIES-20260611"

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
    OPENAPI_SPEC,
    DART_DRIFT_MANIFEST,
    DART_HASH_MARKER,
    DART_API_REGISTRY,
    Path("backend/src/test/java/com/speakeasy/goal/GoalProgressProjectionPerformanceTest.java"),
    Path("test/features/goal_autopilot/goal_progress_surface_performance_test.dart"),
    Path("scripts/check_p0_2_followup_c_traceability.py"),
    Path("scripts/check_p0_2_goal_autopilot_coverage.py"),
]

TC_EXPECTATIONS = {
    "TC-P02-FUC-020": [
        "GoalProgressProjectionPerformanceTest.java",
        "goal_progress_surface_performance_test.dart",
        "GoalProgressProjectionPerformanceTest",
        "flutter test test/features/goal_autopilot/goal_progress_surface_performance_test.dart",
        "passed",
        S007_ANCHOR,
    ],
    "TC-P02-FUC-021": [
        "scripts/check_p0_2_followup_c_traceability.py",
        "scripts/check_p0_2_goal_autopilot_coverage.py",
        "passed",
        S007_ANCHOR,
    ],
    "TC-P02-FUC-022": [
        "docs/reports/implementation_report.md",
        "docs/reports/test_report.md",
        "docs/reports/quality_report.md",
        "python3 scripts/project_agent_runner.py validate",
        "git diff --check",
        "passed",
        S007_REVIEW_ANCHOR,
    ],
    "TC-P02-FUC-023": [
        "GoalAutopilotControllerTest.java",
        "tcP02Xcb005CheckpointRejectsUntrustedAudioAndIgnoresScoreHintForConfidence",
        "GoalAutopilotTelemetryTest.java",
        "GoalAutopilotDataExportRetentionTest.java",
        "passed",
        XCB005_ANCHOR,
    ],
}

TRACEABILITY_TERMS = [
    "P02-FUC-TR-003",
    "P02-FUC-TR-007",
    "TC-P02-FUC-023",
    "P02-FUC-GAP-010",
    "validateCheckpointAudioRef",
    "TC-P02-FUC-020 passed",
    "TC-P02-FUC-021 passed",
    "TC-P02-FUC-022 passed",
    "GoalProgressProjectionPerformanceTest",
    "goal_progress_surface_performance_test.dart",
    "check_p0_2_followup_c_traceability.py",
    "check_p0_2_goal_autopilot_coverage.py",
    "FUC-FIX-007",
    "FUC-FIX-008",
    S007_ANCHOR,
    S007_REVIEW_ANCHOR,
    XCB005_ANCHOR,
]

REPORT_TERMS = {
    TEST_REPORT: [
        S007_REPORT_ID,
        "TC-P02-FUC-020",
        "TC-P02-FUC-021",
        "TC-P02-FUC-022",
        "GoalProgressProjectionPerformanceTest",
        "goal_progress_surface_performance_test.dart",
        "python3 scripts/check_p0_2_followup_c_traceability.py",
        "python3 scripts/check_p0_2_goal_autopilot_coverage.py",
        S007_OPENAPI_CLEANUP_ID,
        S007_OPENAPI_SHA,
        XCB005_REPORT_ID,
        "TC-P02-FUC-023",
        "tcP02Xcb005CheckpointRejectsUntrustedAudioAndIgnoresScoreHintForConfidence",
        "Followup-C is locally complete for S001-S007",
        "Followup-C is not release-ready",
        "Product Base merge is not approved",
    ],
    IMPLEMENTATION_REPORT: [
        S007_REPORT_ID,
        "P02-FUC-FR-007",
        "AC-P02-FUC-007",
        "TC-P02-FUC-020",
        "TC-P02-FUC-021",
        "TC-P02-FUC-022",
        "GoalProgressProjectionPerformanceTest.java",
        "goal_progress_surface_performance_test.dart",
        "check_p0_2_followup_c_traceability.py",
        S007_OPENAPI_CLEANUP_ID,
        S007_OPENAPI_SHA,
        XCB005_REPORT_ID,
        "TC-P02-FUC-023",
        "validateCheckpointAudioRef",
        "No production backend, Flutter or API code changed",
        "Followup-C is not release-ready",
    ],
    QUALITY_REPORT: [
        S007_REPORT_ID,
        "S007",
        "Independent Review",
        "TC-P02-FUC-020",
        "TC-P02-FUC-021",
        "TC-P02-FUC-022",
        "No blocker",
        S007_OPENAPI_CLEANUP_ID,
        S007_OPENAPI_SHA,
        XCB005_REPORT_ID,
        "TC-P02-FUC-023",
        "P02-FUC-GAP-010",
        "Followup-C is not release-ready",
        "Product Base merge is not approved",
    ],
    DEVELOPMENT_STATUS: [
        S007_REPORT_ID,
        "TC-P02-FUC-020/021/022 passed",
        S007_OPENAPI_CLEANUP_ID,
        S007_OPENAPI_SHA,
        "Followup-C is locally complete for S001-S007",
        "Followup-C is not release-ready",
        "Product Base merge is not approved",
    ],
}

FORBIDDEN_RELEASE_CLAIMS = [
    "Followup-C is release-ready",
    "Followup-C release approved",
    "Product Base merge approved",
    "Followup-D completed",
    "commercial release approved",
]


def read(path: Path) -> str:
    full_path = ROOT / path
    if not full_path.exists():
        raise SystemExit(f"Missing required Followup-C evidence file: {path}")
    return full_path.read_text(encoding="utf-8")


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

    for fixture_id in [f"FUC-FIX-{index:03d}" for index in range(0, 9)]:
        if fixture_id not in text:
            raise SystemExit(f"Missing fixture routing {fixture_id} in {TEST_CASES}")


def validate_traceability() -> None:
    text = read(TRACEABILITY)
    for term in TRACEABILITY_TERMS:
        if term not in text:
            raise SystemExit(f"Missing traceability closure term {term!r} in {TRACEABILITY}")

    row = next((line for line in text.splitlines() if line.startswith("| P02-FUC-TR-007 |")), None)
    if row is None:
        raise SystemExit(f"Missing P02-FUC-TR-007 row in {TRACEABILITY}")
    if "Planned" in row or "Not started" in row:
        raise SystemExit("P02-FUC-TR-007 row still contains planned/not-started status")


def validate_reports() -> None:
    for path, terms in REPORT_TERMS.items():
        text = read(path)
        for term in terms:
            if term not in text:
                raise SystemExit(f"Missing required term {term!r} in {path}")

    combined = "\n".join(read(path) for path in [TEST_REPORT, IMPLEMENTATION_REPORT, QUALITY_REPORT, DEVELOPMENT_STATUS])
    for claim in FORBIDDEN_RELEASE_CLAIMS:
        if claim in combined:
            raise SystemExit(f"Forbidden release/completion claim found: {claim}")


def validate_openapi_nullable_cleanup() -> None:
    spec = read(OPENAPI_SPEC)
    expected_eta_range = """eta_range:
          type: object
          nullable: true
          allOf:
          - $ref: '#/components/schemas/ProgressForecastEtaRange'"""
    if expected_eta_range not in spec:
        raise SystemExit("ProgressForecast.eta_range is not using the Redocly-clean nullable allOf shape")

    forbidden_ref_nullable = """eta_range:
          $ref: '#/components/schemas/ProgressForecastEtaRange'
          nullable: true"""
    if forbidden_ref_nullable in spec:
        raise SystemExit("ProgressForecast.eta_range still uses $ref with nullable sibling")

    manifest = json.loads(read(DART_DRIFT_MANIFEST))
    current_hash = manifest.get("openapi_sha256")
    if not current_hash:
        raise SystemExit(f"OpenAPI manifest is missing openapi_sha256 in {DART_DRIFT_MANIFEST}")

    marker_hash = read(DART_HASH_MARKER).strip()
    if marker_hash != current_hash:
        raise SystemExit(f"Generated Dart hash marker does not match manifest hash {current_hash}")
    if current_hash not in read(DART_API_REGISTRY):
        raise SystemExit(f"Generated Dart registry does not embed current OpenAPI hash {current_hash}")


def main() -> int:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            raise SystemExit(f"Missing required Followup-C S007 file: {path}")

    validate_test_cases()
    validate_traceability()
    validate_reports()
    validate_openapi_nullable_cleanup()

    print("P0.2 Followup-C S007 traceability gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
