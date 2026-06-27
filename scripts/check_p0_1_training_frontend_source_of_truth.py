#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FORBIDDEN_PATHS = [
    "lib/features/interview/interview_training_agent.dart",
    "lib/features/interview/interview_training_contract.dart",
    "lib/features/interview/interview_training_backend_adapter.dart",
    "lib/features/interview/interview_training_loop_page.dart",
    "lib/features/interview/interview_training_session_view.dart",
    "lib/features/training/training_agent.dart",
]

FORBIDDEN_PATTERNS = {
    "InterviewTraining": "Training bounded context must not use interview-prefixed types",
    "interview_training": "Training bounded context must not use interview-prefixed file, key or fixture names",
    "TrainingAgent": "frontend must not own Training planner/session source-of-truth",
    "TrainingAttemptResult": "attempt/planner signal belongs to backend Training service",
    "TrainingAttemptOutcome": "attempt/planner outcome belongs to backend Training service",
    "TrainingActionChainStep": "action-chain content belongs to backend reviewed mapping",
    "p01TrainingSceneIds": "scenario allowlist belongs to backend official scenario catalog",
    "p01TrainingScenarioVersionId": "scenario version belongs to backend content versioning",
    "pending_local_write": "frontend must not expose local evidence write as production evidence",
    "backendAdapter == null": "backend-disabled mode must block entry, not run local fallback",
    "backendAdapter != null": "backend adapter must be required for the Training loop page",
    "backendAdapter: AppConfig.enableBackendTraining": "feature flag must gate entry, not switch to local fallback",
    "I worked on a small project that improved our workflow.": "frontend must not submit canned turns",
    "ASR unavailable. Use text fallback to keep the loop moving.": "frontend must not synthesize ASR feedback",
}

SCAN_DIRS = [
    ROOT / "lib",
    ROOT / "test" / "features" / "training",
    ROOT / "integration_test",
]

SCAN_FILES = [
    ROOT / "scripts" / "check_ai_eval_cases.dart",
]


def main() -> int:
    errors: list[str] = []
    for relative_path in FORBIDDEN_PATHS:
        path = ROOT / relative_path
        if path.exists():
            errors.append(f"forbidden file still exists: {relative_path}")

    for directory in SCAN_DIRS:
        for path in directory.rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            relative = path.relative_to(ROOT)
            for pattern, reason in FORBIDDEN_PATTERNS.items():
                if pattern in text:
                    errors.append(f"{relative}: found {pattern!r} - {reason}")

    for path in SCAN_FILES:
        text = path.read_text(encoding="utf-8")
        relative = path.relative_to(ROOT)
        for pattern, reason in FORBIDDEN_PATTERNS.items():
            if pattern in text:
                errors.append(f"{relative}: found {pattern!r} - {reason}")

    if errors:
        print("P0.1 frontend Training source-of-truth check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("P0.1 frontend Training source-of-truth check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
