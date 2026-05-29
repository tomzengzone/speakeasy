#!/usr/bin/env python3
"""Validate TC-COM-019 provider sandbox/internal evidence readiness."""

from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / "tests/commercial/provider_sandbox_matrix.md"

REQUIRED_PROVIDER_ROWS = (
    ("Apple sandbox", "Purchase active subscription"),
    ("Apple sandbox", "Restore active subscription"),
    ("Apple sandbox", "Refund / revoke"),
    ("Apple sandbox", "Expiry"),
    ("Apple sandbox", "Grace period"),
    ("Apple sandbox", "Account switch"),
    ("Google Play internal", "Purchase active subscription"),
    ("Google Play internal", "Restore active subscription"),
    ("Google Play internal", "Refund / revoke"),
    ("Google Play internal", "Expiry"),
    ("Google Play internal", "Grace period"),
    ("Google Play internal", "Account switch"),
)

EXTERNAL_EVIDENCE_KEYS = (
    "APPLE_SANDBOX_EVIDENCE_REF",
    "GOOGLE_PLAY_INTERNAL_EVIDENCE_REF",
)


def main(argv: list[str]) -> int:
    strict_external = "--strict-external" in argv
    errors: list[str] = []
    release_blockers: list[str] = []

    try:
        matrix_text = MATRIX.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing provider evidence matrix: {MATRIX.relative_to(ROOT)}")
        matrix_text = ""

    for provider, scenario in REQUIRED_PROVIDER_ROWS:
        if provider not in matrix_text or scenario not in matrix_text:
            errors.append(f"missing provider matrix row: {provider} / {scenario}")

    for key in EXTERNAL_EVIDENCE_KEYS:
        value = os.environ.get(key, "").strip()
        if not value:
            release_blockers.append(f"{key} is required to close TC-COM-019")

    if release_blockers and strict_external:
        errors.extend(release_blockers)

    if errors:
        print("provider sandbox evidence check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("provider sandbox evidence check passed")
    if release_blockers:
        print("release blockers:")
        for blocker in release_blockers:
            print(f"- {blocker}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
