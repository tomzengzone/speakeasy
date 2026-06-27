#!/usr/bin/env python3
"""Validate TC-COM-AI-004 DashScope provider evidence readiness."""

from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / "tests/commercial/ai_provider_sandbox_matrix.md"

REQUIRED_SCENARIOS = (
    "AI-QWEN-VALID",
    "AI-QWEN-FALLBACK",
    "AI-ASR-VALID",
    "AI-ASR-REJECT",
    "AI-TTS-GENERATE",
    "AI-TTS-CACHE",
    "AI-PROVIDER-ERROR",
)

REQUIRED_EVIDENCE_FIELDS = (
    "backend request id",
    "latency",
    "error code",
    "cost estimate",
    "format compatibility",
    "fallback",
    "independent reviewer",
)

EXTERNAL_EVIDENCE_KEYS = (
    "DASHSCOPE_AI_SANDBOX_EVIDENCE_REF",
)


def main(argv: list[str]) -> int:
    strict_external = "--strict-external" in argv
    errors: list[str] = []
    release_blockers: list[str] = []

    try:
        matrix_text = MATRIX.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing AI provider evidence matrix: {MATRIX.relative_to(ROOT)}")
        matrix_text = ""

    for scenario in REQUIRED_SCENARIOS:
        if scenario not in matrix_text:
            errors.append(f"missing AI provider matrix scenario: {scenario}")

    for field in REQUIRED_EVIDENCE_FIELDS:
        if field not in matrix_text:
            errors.append(f"missing AI provider evidence field: {field}")

    if "python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external" not in matrix_text:
        errors.append("AI provider matrix must document the strict external gate command")

    for key in EXTERNAL_EVIDENCE_KEYS:
        value = os.environ.get(key, "").strip()
        if not value:
            release_blockers.append(f"{key} is required to close TC-COM-AI-004")

    if release_blockers and strict_external:
        errors.extend(release_blockers)

    if errors:
        print("AI provider sandbox evidence check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("AI provider sandbox evidence check passed")
    if release_blockers:
        print("release blockers:")
        for blocker in release_blockers:
            print(f"- {blocker}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
