#!/usr/bin/env python3
"""Validate TC-COM-021 store submission evidence readiness."""

from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MATRIX = ROOT / "tests/commercial/store_submission_matrix.md"

REQUIRED_AREAS = (
    "App Store metadata",
    "Play Console metadata",
    "Subscription products",
    "Subscription terms",
    "Privacy labels / Data safety",
    "Privacy URL",
    "Support URL",
    "Reviewer account",
)

REQUIRED_EXTERNAL_REFS = (
    "STORE_METADATA_EVIDENCE_REF",
    "REVIEWER_ACCOUNT_REF",
    "PRIVACY_URL",
    "SUPPORT_URL",
)


def main(argv: list[str]) -> int:
    strict_external = "--strict-external" in argv
    errors: list[str] = []
    release_blockers: list[str] = []

    try:
        matrix_text = MATRIX.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing store submission matrix: {MATRIX.relative_to(ROOT)}")
        matrix_text = ""

    for area in REQUIRED_AREAS:
        if area not in matrix_text:
            errors.append(f"missing store submission matrix area: {area}")

    for key in REQUIRED_EXTERNAL_REFS:
        value = os.environ.get(key, "").strip()
        if not value:
            release_blockers.append(f"{key} is required to close TC-COM-021")
        elif key.endswith("_URL") and not value.startswith("https://"):
            errors.append(f"{key} must use https")

    if release_blockers and strict_external:
        errors.extend(release_blockers)

    if errors:
        print("store submission evidence check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("store submission evidence check passed")
    if release_blockers:
        print("release blockers:")
        for blocker in release_blockers:
            print(f"- {blocker}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
