#!/usr/bin/env python3
"""Check P0.2 goal-autopilot requirements/code/test traceability evidence."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(".")

INCREMENT_ROWS = {
    "docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md": [
        "P02-DIAG-TR-001",
        "P02-DIAG-TR-002",
        "P02-DIAG-TR-003",
        "P02-DIAG-TR-004",
        "P02-DIAG-TR-005",
        "P02-DIAG-TR-006",
        "P02-DIAG-TR-007",
    ],
    "docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md": [
        "P02-PLAN-TR-001",
        "P02-PLAN-TR-002",
        "P02-PLAN-TR-003",
        "P02-PLAN-TR-004",
        "P02-PLAN-TR-005",
        "P02-PLAN-TR-006",
        "P02-PLAN-TR-007",
        "P02-PLAN-TR-008",
    ],
    "docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md": [
        "P02-AUTO-TR-001",
        "P02-AUTO-TR-002",
        "P02-AUTO-TR-003",
        "P02-AUTO-TR-004",
        "P02-AUTO-TR-005",
        "P02-AUTO-TR-006",
        "P02-AUTO-TR-007",
        "P02-AUTO-TR-008",
    ],
    "docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/traceability.md": [
        "P02-FUA-TR-000",
        "P02-FUA-TR-001",
        "P02-FUA-TR-002",
        "P02-FUA-TR-003",
        "P02-FUA-TR-004",
        "P02-FUA-TR-005",
        "P02-FUA-TR-006",
        "P02-FUA-TR-007",
        "P02-FUA-TR-008",
        "P02-FUA-TR-009",
        "P02-FUA-TR-010",
        "P02-FUA-TR-011",
    ],
}

TRACE_REQUIRED_TERMS = {
    "docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md": [
        "GoalAutopilot",
        "coverage",
        "local tests",
    ],
    "docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md": [
        "GoalAutopilot",
        "coverage",
        "local tests",
    ],
    "docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md": [
        "GoalAutopilot",
        "coverage",
        "local tests",
    ],
    "docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/traceability.md": [
        "P02-FUA-FR-001",
        "P02-FUA-SPEC-001",
        "AC-P02-FUA-001",
        "TC-P02-FUA-013",
        "P02-FUA-FR-009",
        "TC-P02-FUA-016",
        "TC-P02-FUA-017",
        "TC-P02-FUA-018",
        "TC-P02-FUA-019",
        "XCB-005",
        "Idempotency-Key",
        "validateTrustedAudioRef",
        "Implemented locally / release-gated",
        "GoalAutopilotPanel",
        "coverage",
    ],
}

REQUIRED_FILES = [
    "backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java",
    "backend/src/main/java/com/speakeasy/goal/GoalAutopilotGoalIdempotency.java",
    "backend/src/main/java/com/speakeasy/goal/GoalAutopilotGoalIdempotencyRepository.java",
    "backend/src/main/java/com/speakeasy/api/GoalAutopilotController.java",
    "backend/src/main/resources/db/migration/V202606040001__p0_2_goal_autopilot.sql",
    "backend/src/main/resources/db/migration/V202606110001__p0_2_xcb005_goal_autopilot_fact_boundaries.sql",
    "backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java",
    "backend/src/test/java/com/speakeasy/goal/GoalAutopilotDataExportRetentionTest.java",
    "backend/src/test/java/com/speakeasy/goal/GoalAutopilotTelemetryTest.java",
    "backend/src/test/java/com/speakeasy/GoalAutopilotPerformanceTest.java",
    "lib/features/goal_autopilot/goal_autopilot_adapter.dart",
    "lib/features/goal_autopilot/goal_autopilot_panel.dart",
    "test/features/goal_autopilot/goal_autopilot_adapter_test.dart",
    "scripts/check_p0_2_goal_autopilot_coverage.py",
]

REQUIRED_TERMS = {
    "docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/requirements.md": [
        "P02-FUA-FR-001",
        "P02-FUA-FR-008",
        "P02-FUA-FR-009",
        "No-goal Explore Mode",
        "P02-PG-003",
    ],
    "docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/spec.md": [
        "P02-FUA-SPEC-001",
        "P02-FUA-SPEC-008",
        "P02-FUA-SPEC-009",
        "ExplorePractice",
        "createDefaultGoal()",
        "GoalDiagnosticSampleInput",
    ],
    "docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/acceptance.md": [
        "AC-P02-FUA-001",
        "AC-P02-FUA-008",
        "AC-P02-FUA-009",
        "XCB-005",
        "Idempotency-Key",
        "Explore practice",
        "official_score_equivalence=false",
    ],
    "docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/test_cases.md": [
        "TC-P02-FUA-001",
        "TC-P02-FUA-013",
        "TC-P02-FUA-014",
        "TC-P02-FUA-016",
        "TC-P02-FUA-017",
        "TC-P02-FUA-018",
        "TC-P02-FUA-019",
        "Flutter production header propagation",
        "flutter test --coverage",
    ],
    "docs/reports/test_report.md": [
        "P02-GOAL-AUTOPILOT-LOCAL-IMPLEMENTATION-20260604",
        "P02-XCB005-GOAL-AUTOPILOT-FACT-BOUNDARIES-20260611",
        "No-goal Explore Mode",
        "TC-P02-FUA-014",
        "TC-P02-FUA-017",
        "TC-P02-FUA-018",
        "TC-P02-FUA-019",
        "TC-P02-FUC-023",
        "backend changed-code line 96.0%",
        "Flutter feature line 82.1%",
    ],
    "docs/reports/implementation_report.md": [
        "P02-GOAL-AUTOPILOT-LOCAL-IMPLEMENTATION-20260604",
        "P02-XCB005-GOAL-AUTOPILOT-FACT-BOUNDARIES-20260611",
        "Requirements -> code -> tests -> coverage traceability",
        "GoalAutopilotGoalIdempotency",
        "V202606110001__p0_2_xcb005_goal_autopilot_fact_boundaries.sql",
    ],
    "docs/reports/quality_report.md": [
        "P02 Goal Autopilot Local Implementation Independent Review",
        "P02 XCB005 Goal Autopilot Fact Boundaries Independent Review",
        "P02 Followup-A No-goal Explore Mode Requirement/Test Documentation Review",
        "P02-FUA-FR-009",
        "P02-FUA-TR-010",
        "P02-FUA-TR-011",
        "No coverage blocker remains",
    ],
    "docs/architecture/openapi/speakeasy-api.yaml": [
        "/goal-autopilot/goals",
        "Idempotency-Key",
        "x-idempotency-required",
        "/goal-autopilot/actions/next",
        "/goal-autopilot/checkpoints",
    ],
    "lib/features/goal_autopilot/goal_autopilot_adapter.dart": [
        "GoalDiagnosticSampleInput",
        "diagnostic_samples",
        "flutter_goal_sample_1",
        "goal-create",
        "Idempotency-Key",
    ],
    "lib/features/goal_autopilot/goal_autopilot_models.dart": [
        "sampleCount",
        "supportReasonCode",
        "goalCompletionClaimAllowed",
        "revision",
    ],
    "lib/features/goal_autopilot/goal_autopilot_panel.dart": [
        "widget.adapter.createGoal",
        "No active goal",
        "Explore practice",
        "Try a sample drill",
        "Diagnostic sample",
        "goal-diagnostic-sample-",
        "Edit goal",
        "Regenerate plan",
        "Product-internal progress only",
    ],
    "test/features/goal_autopilot/goal_autopilot_adapter_test.dart": [
        "Followup-A form renders editable goal intake and blocks invalid values",
        "Followup-A no active goal renders empty state without creating goal",
        "Followup-A Set a goal opens intake without default goal creation",
        "Followup-A Explore practice bypasses goal-autopilot facts and claims",
        "Followup-A submits user-entered GoalProfile payload without default goal path",
        "Followup-A fail-closes unsupported goals and exposes edit recovery only",
        "Followup-A exposes revision and blocks stale next action after edit",
    ],
}


def require_file(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        raise SystemExit(f"Missing required P0.2 evidence file: {path}")
    return file_path.read_text()


def main() -> int:
    for path in REQUIRED_FILES:
        if not (ROOT / path).exists():
            raise SystemExit(f"Missing required P0.2 implementation/test file: {path}")

    for path, ids in INCREMENT_ROWS.items():
        text = require_file(path)
        for trace_id in ids:
            if trace_id not in text:
                raise SystemExit(f"Missing traceability row {trace_id} in {path}")
        for required in TRACE_REQUIRED_TERMS[path]:
            if required not in text:
                raise SystemExit(f"Missing required evidence term {required!r} in {path}")

    for path, terms in REQUIRED_TERMS.items():
        text = require_file(path)
        for term in terms:
            if term not in text:
                raise SystemExit(f"Missing required term {term!r} in {path}")

    panel_text = require_file("lib/features/goal_autopilot/goal_autopilot_panel.dart")
    if "createDefaultGoal(" in panel_text:
        raise SystemExit("Followup-A production panel must not call createDefaultGoal()")

    print("P0.2 goal-autopilot traceability gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
