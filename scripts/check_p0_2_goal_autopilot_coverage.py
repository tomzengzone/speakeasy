#!/usr/bin/env python3
"""Validate P0.2 goal-autopilot changed-code coverage reports."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


MIN_COVERAGE = 80.0
BACKEND_CSV = Path("backend/target/site/jacoco/jacoco.csv")
FLUTTER_LCOV = Path("coverage/lcov.info")

BACKEND_CHANGED_CLASSES = {
    ("com.speakeasy.goal", None),
    ("com.speakeasy.api", "GoalAutopilotController"),
    ("com.speakeasy.ops", "AccountDeletionService"),
}

FLUTTER_CHANGED_FILES = {
    "lib/features/goal_autopilot/goal_autopilot_adapter.dart",
    "lib/features/goal_autopilot/goal_autopilot_models.dart",
    "lib/features/goal_autopilot/goal_autopilot_panel.dart",
}


def pct(covered: int, missed: int) -> float:
    total = covered + missed
    return 100.0 if total == 0 else covered * 100.0 / total


def backend_coverage() -> tuple[float, float]:
    if not BACKEND_CSV.exists():
        raise SystemExit(f"Missing backend coverage report: {BACKEND_CSV}")

    line_covered = line_missed = branch_covered = branch_missed = 0
    with BACKEND_CSV.open(newline="") as handle:
        for row in csv.DictReader(handle):
            package = row["PACKAGE"]
            klass = row["CLASS"]
            if not any(
                package == target_package and (target_class is None or klass == target_class)
                for target_package, target_class in BACKEND_CHANGED_CLASSES
            ):
                continue
            line_missed += int(row["LINE_MISSED"])
            line_covered += int(row["LINE_COVERED"])
            branch_missed += int(row["BRANCH_MISSED"])
            branch_covered += int(row["BRANCH_COVERED"])

    return pct(line_covered, line_missed), pct(branch_covered, branch_missed)


def flutter_line_coverage() -> float:
    if not FLUTTER_LCOV.exists():
        raise SystemExit(f"Missing Flutter coverage report: {FLUTTER_LCOV}")

    current_file: str | None = None
    total = covered = 0
    for line in FLUTTER_LCOV.read_text().splitlines():
        if line.startswith("SF:"):
            current_file = line[3:]
            continue
        if current_file not in FLUTTER_CHANGED_FILES or not line.startswith("DA:"):
            continue
        _, payload = line.split(":", 1)
        _, count = payload.split(",", 1)
        total += 1
        if int(count) > 0:
            covered += 1

    if total == 0:
        raise SystemExit("No Flutter P0.2 changed-file coverage entries found")
    return covered * 100.0 / total


def main() -> int:
    backend_line, backend_branch = backend_coverage()
    flutter_line = flutter_line_coverage()
    print(
        "P0.2 coverage: "
        f"backend line={backend_line:.1f}% branch={backend_branch:.1f}%; "
        f"flutter line={flutter_line:.1f}%"
    )
    if backend_line < MIN_COVERAGE or backend_branch < MIN_COVERAGE or flutter_line < MIN_COVERAGE:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
