#!/usr/bin/env python3
"""Validate paid AI external release evidence readiness."""

from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKLIST = ROOT / "tests/commercial/ai_external_release_evidence_checklist.md"

REQUIRED_REFS = (
    "DASHSCOPE_AI_SANDBOX_EVIDENCE_REF",
    "AI_MEDIA_STORAGE_EVIDENCE_REF",
    "AI_COST_DASHBOARD_EVIDENCE_REF",
    "AI_RETENTION_POLICY_EVIDENCE_REF",
)

REQUIRED_TRACEABILITY = (
    "COM-SI-013",
    "COM-SI-015",
    "COM-SI-016",
    "COM-SI-017",
    "AC-COM-AI-001",
    "AC-COM-AI-003",
    "AC-COM-AI-004",
    "AC-COM-AI-005",
    "TC-COM-AI-001",
    "TC-COM-AI-002",
    "TC-COM-AI-004",
    "TC-COM-AI-005",
    "TC-COM-AI-006",
    "TC-COM-AI-007",
    "COM-AI-TR-001",
    "COM-AI-TR-003",
    "COM-AI-TR-004",
    "COM-AI-TR-005",
)

REQUIRED_RESULT_FIELDS = (
    "Execution ID",
    "Evidence scope",
    "TC ID",
    "Scenario ID",
    "Executor",
    "Execution date",
    "Environment",
    "Commit / build tag",
    "Evidence ref",
    "Expected result",
    "Actual result",
    "Failure / blocker reason",
    "Reviewer",
    "Review result",
)

REQUIRED_SCENARIOS = (
    "AI-QWEN-VALID",
    "AI-QWEN-FALLBACK",
    "AI-ASR-VALID",
    "AI-ASR-REJECT",
    "AI-TTS-GENERATE",
    "AI-TTS-CACHE",
    "AI-PROVIDER-ERROR",
    "AI-STORAGE-CONFIG",
    "AI-STORAGE-UPLOAD",
    "AI-STORAGE-PROVIDER-ACCESS",
    "AI-STORAGE-EXPIRE",
    "AI-STORAGE-DELETE",
    "AI-STORAGE-REJECT",
    "AI-COST-SAMPLE-CALLS",
    "AI-COST-DASHBOARD-DIMENSIONS",
    "AI-COST-BUDGET-ALERTS",
    "AI-COST-RAW-CONTENT-GUARD",
    "AI-COST-PM-APPROVAL",
    "AI-RETENTION-POLICY-APPROVAL",
    "AI-RETENTION-AUDIO-DELETE",
    "AI-RETENTION-TRANSCRIPT-REDACT",
    "AI-RETENTION-TTS-OWNER-CACHE",
    "AI-RETENTION-METRIC-SANITIZE",
    "AI-RETENTION-RETRY-MANUAL",
)

REQUIRED_COMMANDS = (
    "python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external",
    "python3 scripts/check_ai_external_release_evidence.py --strict-external",
    "scripts/check_release_readiness.sh",
)

REQUIRED_SAFETY_PHRASES = (
    "不得包含 API key",
    "原始音频",
    "完整 signed URL",
    "完整转写",
    "完整 provider payload",
    "不得指向 `docs/`、`tests/`、`build/` 或本地 `file://` 路径",
)

LOCAL_REF_PREFIXES = ("docs/", "tests/", "build/", "./", "../", "file://")
PLACEHOLDER_REFS = {"pending", "todo", "tbd", "n/a", "na", "none", "null"}


def invalid_ref_reason(value: str) -> str | None:
    normalized = value.strip()
    lowered = normalized.lower()
    if lowered in PLACEHOLDER_REFS:
        return "must not be a placeholder"
    if lowered.startswith(LOCAL_REF_PREFIXES):
        return "must point to an external controlled evidence location, not a repo/local path"
    return None


def main(argv: list[str]) -> int:
    strict_external = "--strict-external" in argv
    errors: list[str] = []
    release_blockers: list[str] = []

    try:
        checklist_text = CHECKLIST.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing paid AI external evidence checklist: {CHECKLIST.relative_to(ROOT)}")
        checklist_text = ""

    for item in (
        *REQUIRED_REFS,
        *REQUIRED_TRACEABILITY,
        *REQUIRED_RESULT_FIELDS,
        *REQUIRED_SCENARIOS,
        *REQUIRED_COMMANDS,
        *REQUIRED_SAFETY_PHRASES,
    ):
        if item not in checklist_text:
            errors.append(f"missing required paid AI evidence checklist item: {item}")

    for key in REQUIRED_REFS:
        value = os.environ.get(key, "").strip()
        if not value:
            release_blockers.append(f"{key} is required before paid AI voice release")
            continue
        reason = invalid_ref_reason(value)
        if reason:
            errors.append(f"{key} {reason}")

    if release_blockers and strict_external:
        errors.extend(release_blockers)

    if errors:
        print("paid AI external evidence check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("paid AI external evidence check passed")
    if release_blockers:
        print("release blockers:")
        for blocker in release_blockers:
            print(f"- {blocker}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
