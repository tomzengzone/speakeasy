#!/usr/bin/env python3
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "backend/src/main/java/com/speakeasy/api/TrainingController.java",
    "backend/src/main/java/com/speakeasy/training/TrainingService.java",
    "backend/src/main/java/com/speakeasy/training/TrainingPlannerService.java",
    "backend/src/main/resources/db/migration/V202606030001__p0_1_training_source_of_truth.sql",
    "lib/features/training/training_contract.dart",
    "lib/features/training/training_backend_adapter.dart",
    "lib/features/training/training_session_loop_page.dart",
    "lib/pages/home_page.dart",
    "backend/src/test/java/com/speakeasy/TrainingSessionControllerTest.java",
    "backend/src/test/java/com/speakeasy/TrainingTurnIdempotencyTest.java",
    "backend/src/test/java/com/speakeasy/TrainingSessionAuthorizationTest.java",
    "backend/src/test/java/com/speakeasy/TrainingEvidenceRuleTraceTest.java",
    "backend/src/test/java/com/speakeasy/TrainingAccountDeletionRetentionTest.java",
    "backend/src/test/java/com/speakeasy/TrainingContentVersioningTest.java",
    "backend/src/test/java/com/speakeasy/TrainingMediaAiPipelineTest.java",
    "backend/src/test/java/com/speakeasy/TrainingPlannerReplayTest.java",
    "backend/src/test/java/com/speakeasy/TrainingObservabilityTest.java",
    "test/features/training/training_content_mapping_test.dart",
    "test/features/training/training_backend_pipeline_test.dart",
    "test/features/training/training_planner_replay_test.dart",
    "test/features/training/training_entry_test.dart",
    "test/features/training/training_backend_only_loop_test.dart",
    "scripts/check_p0_1_training_frontend_source_of_truth.py",
]

FORBIDDEN_FILES = [
    "lib/features/interview/interview_training_contract.dart",
    "lib/features/interview/interview_training_backend_adapter.dart",
    "lib/features/interview/interview_training_loop_page.dart",
    "lib/features/interview/interview_training_session_view.dart",
    "test/features/interview/interview_training_entry_test.dart",
    "test/features/interview/interview_training_backend_only_loop_test.dart",
    "lib/features/training/training_agent.dart",
]

TC_IDS = [f"TC-P01-{index:03d}" for index in range(21, 32)]
TR_IDS = [f"P01-TR-{index:03d}" for index in range(13, 19)]
GAP_IDS = [f"P01-GAP-{index:03d}" for index in range(9, 15)]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def table_row(text: str, row_id: str) -> str:
    for line in text.splitlines():
        if line.startswith(f"| {row_id} "):
            return line
    return ""


def main() -> int:
    failures: list[str] = []

    for file_path in REQUIRED_FILES:
        require((ROOT / file_path).exists(), f"missing required file: {file_path}", failures)

    for file_path in FORBIDDEN_FILES:
        require(not (ROOT / file_path).exists(), f"forbidden legacy/agent file exists: {file_path}", failures)

    test_cases = read("docs/product/increments/p0-1-expression-automation-training/test_cases.md")
    traceability = read("docs/product/increments/p0-1-expression-automation-training/traceability.md")
    test_report = read("docs/reports/test_report.md")
    implementation_report = read("docs/reports/implementation_report.md")
    quality_report = read("docs/reports/quality_report.md")
    release_checklist = read("docs/release/release_checklist.md")
    api_contract = read("docs/architecture/api_contract.md")

    for tc_id in TC_IDS:
        row = table_row(test_cases, tc_id)
        require(row, f"missing test_cases row: {tc_id}", failures)
        require(
            re.search(r"local executed\s*/\s*passed", row, re.IGNORECASE) is not None,
            f"{tc_id} is not marked local executed / passed",
            failures,
        )
        require(tc_id in test_report, f"{tc_id} missing from test_report", failures)

    for tr_id in TR_IDS:
        row = table_row(traceability, tr_id)
        require(row, f"missing traceability row: {tr_id}", failures)
        require("Implemented" in row and "local executed / passed" in row, f"{tr_id} is not implemented/passed", failures)

    for gap_id in GAP_IDS:
        row = table_row(traceability, gap_id)
        require(row, f"missing gap row: {gap_id}", failures)
        require("Closed" in row, f"{gap_id} is not closed", failures)

    for marker in [
        "P01-FR-012",
        "P01-FR-013",
        "P01-FR-014",
        "P01-FR-015",
        "P01-FR-016",
        "P01-FR-017",
        "P0.1 Training Product Base/Production Hardening Gate",
        "backend-only",
        "local draft, not Product Base",
        "lib/features/training",
    ]:
        joined_docs = "\n".join([implementation_report, quality_report, release_checklist, api_contract])
        require(marker in joined_docs, f"missing rollout marker in reports/contracts: {marker}", failures)

    forbidden_frontend_fallback = ROOT / "lib/features/training/training_agent.dart"
    require(
        not forbidden_frontend_fallback.exists(),
        "frontend local Training state-machine fallback still exists",
        failures,
    )

    if failures:
        print("P0.1 training rollout readiness check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("P0.1 training rollout readiness check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
