#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INCREMENT = ROOT / "docs/product/increments/mvp-system-e2e-validation"
TEST_CASES = INCREMENT / "test_cases.md"
TRACEABILITY = INCREMENT / "traceability.md"

REQUIRED_TC_COLUMNS = [
    "TC ID",
    "Stage Scope ID",
    "FR",
    "Spec",
    "AC",
    "Traceability Row",
    "Gap",
    "测试层级",
    "自动化状态",
    "测试脚本路径",
    "执行命令",
    "结果状态",
    "证据报告",
]
REQUIRED_PRODUCT_BASE_AC = [f"AC-{index:03d}" for index in range(1, 14)]
REQUIRED_TRACEABILITY_ROWS = [f"MVP-E2E-TR-{index:03d}" for index in range(1, 5)]


def main() -> int:
    errors: list[str] = []
    test_cases_text = TEST_CASES.read_text(encoding="utf-8")
    traceability_text = TRACEABILITY.read_text(encoding="utf-8")

    coverage_rows = _parse_table_after_heading(
        test_cases_text,
        "## Product Base System Coverage Matrix",
    )
    covered_ac = {row.get("Product Base AC", "").strip() for row in coverage_rows}
    for ac_id in REQUIRED_PRODUCT_BASE_AC:
        if ac_id not in covered_ac:
            errors.append(f"missing Product Base coverage row: {ac_id}")

    tc_rows = [
        row
        for row in _parse_table_after_heading(test_cases_text, "## Test Cases")
        if row.get("TC ID", "").startswith("TC-MVP-E2E-")
    ]
    if len(tc_rows) != 10:
        errors.append(f"expected 10 TC-MVP-E2E rows, found {len(tc_rows)}")

    for row in tc_rows:
        tc_id = row.get("TC ID", "<unknown>")
        for column in REQUIRED_TC_COLUMNS:
            if column not in row:
                errors.append(f"{tc_id}: missing column {column}")
                continue
            if not row[column].strip():
                errors.append(f"{tc_id}: blank required column {column}")
        if not re.fullmatch(r"TC-MVP-E2E-\d{3}", tc_id):
            errors.append(f"{tc_id}: invalid TC ID format")
        if not row.get("Stage Scope ID", "").startswith("MVP-SI-"):
            errors.append(f"{tc_id}: Stage Scope ID must start with MVP-SI-")
        if not re.fullmatch(r"MVP-E2E-FR-\d{3}", row.get("FR", "")):
            errors.append(f"{tc_id}: invalid FR {row.get('FR', '')}")
        if not re.fullmatch(r"MVP-E2E-SPEC-\d{3}", row.get("Spec", "")):
            errors.append(f"{tc_id}: invalid Spec {row.get('Spec', '')}")
        if not re.fullmatch(r"AC-MVP-E2E-\d{3}", row.get("AC", "")):
            errors.append(f"{tc_id}: invalid AC {row.get('AC', '')}")
        if not re.fullmatch(r"MVP-E2E-TR-\d{3}", row.get("Traceability Row", "")):
            errors.append(
                f"{tc_id}: invalid Traceability Row {row.get('Traceability Row', '')}"
            )

        automation = row.get("自动化状态", "")
        result = row.get("结果状态", "")
        if "passed" in result and "automated" not in automation:
            errors.append(f"{tc_id}: passed result must be marked automated")
        if "accepted-exception" in result and "accepted-exception" not in automation:
            errors.append(f"{tc_id}: accepted exception result must be marked in automation")
        if "automated" in automation:
            _validate_automated_paths(tc_id, row.get("测试脚本路径", ""), errors)

    for row_id in REQUIRED_TRACEABILITY_ROWS:
        if row_id not in traceability_text:
            errors.append(f"missing traceability row: {row_id}")

    for ac_id in REQUIRED_PRODUCT_BASE_AC:
        if ac_id not in traceability_text:
            errors.append(f"missing Product Base AC in traceability: {ac_id}")

    if errors:
        print("MVP system E2E coverage audit failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "MVP system E2E coverage audit passed: "
        f"{len(tc_rows)} TC rows, {len(covered_ac)} Product Base AC rows, "
        f"{len(REQUIRED_TRACEABILITY_ROWS)} traceability rows."
    )
    return 0


def _parse_table_after_heading(text: str, heading: str) -> list[dict[str, str]]:
    lines = text.splitlines()
    try:
        start = lines.index(heading)
    except ValueError:
        raise SystemExit(f"heading not found: {heading}")

    table_lines: list[str] = []
    for line in lines[start + 1 :]:
        if not line.strip():
            if table_lines:
                break
            continue
        if not line.startswith("|"):
            if table_lines:
                break
            continue
        table_lines.append(line)

    if len(table_lines) < 2:
        raise SystemExit(f"table not found after heading: {heading}")

    headers = _split_row(table_lines[0])
    rows: list[dict[str, str]] = []
    for raw in table_lines[2:]:
        cells = _split_row(raw)
        if len(cells) < len(headers):
            cells.extend([""] * (len(headers) - len(cells)))
        rows.append(dict(zip(headers, cells)))
    return rows


def _split_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _validate_automated_paths(tc_id: str, raw_paths: str, errors: list[str]) -> None:
    path_candidates = [
        item.strip().strip("`")
        for part in raw_paths.split(";")
        for item in part.split(",")
        if item.strip()
    ]
    script_paths = [
        path
        for path in path_candidates
        if path.startswith("scripts/") or path.startswith("integration_test/")
    ]
    if not script_paths:
        errors.append(f"{tc_id}: automated TC must name a scripts/ or integration_test/ path")
        return
    for path in script_paths:
        if not (ROOT / path).exists():
            errors.append(f"{tc_id}: automated path does not exist: {path}")


if __name__ == "__main__":
    sys.exit(main())
