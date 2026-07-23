#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REGISTRY = ROOT / "docs" / "product" / "feature_registry.md"

CAPABILITY_TABLE_HEADING = "### Capability"
SUB_CAPABILITY_TABLE_HEADING = "### Level-1 Sub-capabilities"
LEGACY_HEADING = "## Legacy Mapping"

CAPABILITY_HEADERS = (
    "Capability ID",
    "Capability slug",
    "Capability name",
    "Business type",
    "Owner",
    "Lifecycle status",
    "Owns",
    "Does not own",
    "Primary user/business outcome",
    "Adjacent capabilities",
    "Downstream document prefix",
    "Legacy mapping",
)
SUB_CAPABILITY_HEADERS = (
    "Capability ID",
    "Sub-capability ID",
    "Sub-capability name",
    "Owns",
    "Does not own",
    "Entry / precondition",
    "Output / state",
    "Related FR prefix",
    "Status",
)
LEGACY_HEADERS = ("V1 slug", "V2 mapping", "Migration note")
ALLOWED_STANDALONE_TABLE_HEADINGS = {"## 术语表", LEGACY_HEADING}

CAPABILITY_ID_RE = re.compile(r"^CAP-[A-Z][A-Z0-9]*$")
SUB_CAPABILITY_ID_RE = re.compile(r"^CAP-[A-Z][A-Z0-9]*-\d{2}$")
CAPABILITY_SECTION_RE = re.compile(
    r"^## (?P<capability_id>CAP-[A-Z][A-Z0-9]*) - (?P<capability_name>.+)$"
)
SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
PREFIX_RE = re.compile(r"^[A-Z][A-Z0-9]*$")
SEPARATOR_RE = re.compile(r"^:?-{3,}:?$")
CODE_CAPABILITY_ID = r"`(CAP-[A-Z][A-Z0-9]*)`"
ADJACENCY_RE = re.compile(rf"^{CODE_CAPABILITY_ID}(?:;\s*{CODE_CAPABILITY_ID})*$")
LEGACY_CAPABILITY_LIST_RE = re.compile(rf"^{CODE_CAPABILITY_ID}(?:,\s*{CODE_CAPABILITY_ID})*$")
SUPPORT_MAPPING_RE = re.compile(
    r"^(?:Architecture/SWC/Domain|AI runtime / provider / ops) support for (?P<targets>.+)$"
)


def cells(line: str) -> list[str]:
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        return []
    parsed: list[str] = []
    current: list[str] = []
    body = stripped[1:-1]
    index = 0
    while index < len(body):
        char = body[index]
        if char == "\\" and index + 1 < len(body) and body[index + 1] == "|":
            current.append("|")
            index += 2
            continue
        if char == "|":
            parsed.append("".join(current).strip())
            current = []
        else:
            current.append(char)
        index += 1
    parsed.append("".join(current).strip())
    return parsed


def top_level_sections(lines: list[str]) -> list[tuple[int, int]]:
    headings = [index for index, line in enumerate(lines) if line.startswith("## ")]
    return [
        (heading_index, headings[position + 1] if position + 1 < len(headings) else len(lines))
        for position, heading_index in enumerate(headings)
    ]


def validate_table_sections(lines: list[str], errors: list[str]) -> None:
    for heading_index, section_end in top_level_sections(lines):
        heading = lines[heading_index].strip()
        has_table = any(
            lines[index].lstrip().startswith("|")
            for index in range(heading_index + 1, section_end)
        )
        if (
            has_table
            and heading not in ALLOWED_STANDALONE_TABLE_HEADINGS
            and not CAPABILITY_SECTION_RE.fullmatch(heading)
        ):
            errors.append(f"unsupported Markdown table section: {heading}")


def value(cell: str) -> str:
    stripped = cell.strip()
    match = re.fullmatch(r"`([^`]+)`", stripped)
    if match:
        return match.group(1).strip()
    return stripped


def parse_table_after_heading(
    lines: list[str],
    heading_index: int,
    section_end: int,
    expected_headers: tuple[str, ...],
    errors: list[str],
    label: str,
) -> list[dict[str, str]]:
    table_index = heading_index + 1
    while table_index < section_end and not lines[table_index].strip():
        table_index += 1
    if table_index >= section_end:
        errors.append(f"{label} has no table")
        return []

    actual_headers = tuple(cells(lines[table_index]))
    if actual_headers != expected_headers:
        errors.append(
            f"{label} header mismatch: expected {list(expected_headers)}, got {list(actual_headers)}"
        )
        return []

    separator_index = table_index + 1
    separators = cells(lines[separator_index]) if separator_index < len(lines) else []
    if len(separators) != len(expected_headers) or not all(SEPARATOR_RE.fullmatch(item) for item in separators):
        errors.append(f"{label} has an invalid Markdown separator row")
        return []

    rows: list[dict[str, str]] = []
    table_ended = False
    for row_index in range(separator_index + 1, section_end):
        raw = lines[row_index]
        if not raw.strip():
            if rows:
                table_ended = True
            continue
        line_number = row_index + 1
        if not raw.lstrip().startswith("|"):
            errors.append(f"{label}:{line_number} unexpected content inside canonical table section")
            continue
        if table_ended:
            errors.append(f"{label}:{line_number} table rows resume after an interruption")
        row_cells = cells(raw)
        if len(row_cells) != len(expected_headers):
            errors.append(f"{label}:{line_number} expected {len(expected_headers)} cells, got {len(row_cells)}")
            continue
        row = {header: value(cell) for header, cell in zip(expected_headers, row_cells)}
        row["__line__"] = str(line_number)
        rows.append(row)
    if not rows:
        errors.append(f"{label} has no data rows")
    return rows


def parse_unique_table_subsection(
    lines: list[str],
    section_start: int,
    section_end: int,
    heading: str,
    expected_headers: tuple[str, ...],
    errors: list[str],
    label: str,
) -> list[dict[str, str]]:
    indexes = [
        index
        for index in range(section_start + 1, section_end)
        if lines[index].strip() == heading
    ]
    if not indexes:
        errors.append(f"{label} is missing {heading}")
        return []
    if len(indexes) > 1:
        errors.append(f"{label} has duplicate subsection {heading}")
        return []
    heading_index = indexes[0]
    subsection_end = next(
        (
            index
            for index in range(heading_index + 1, section_end)
            if lines[index].startswith("### ")
        ),
        section_end,
    )
    return parse_table_after_heading(
        lines, heading_index, subsection_end, expected_headers, errors, f"{label} / {heading}"
    )


def parse_capability_sections(
    lines: list[str], errors: list[str]
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    capabilities: list[dict[str, str]] = []
    sub_capabilities: list[dict[str, str]] = []
    sections = [
        (start, end, CAPABILITY_SECTION_RE.fullmatch(lines[start].strip()))
        for start, end in top_level_sections(lines)
        if CAPABILITY_SECTION_RE.fullmatch(lines[start].strip())
    ]
    if not sections:
        errors.append("missing Capability chapters")
        return capabilities, sub_capabilities

    for section_start, section_end, match in sections:
        assert match is not None
        section_id = match.group("capability_id")
        section_name = match.group("capability_name").strip()
        label = f"Capability chapter {section_id}"
        subsection_headings = [
            lines[index].strip()
            for index in range(section_start + 1, section_end)
            if lines[index].startswith("### ")
        ]
        expected_subsections = [CAPABILITY_TABLE_HEADING, SUB_CAPABILITY_TABLE_HEADING]
        if subsection_headings != expected_subsections:
            errors.append(
                f"{label} subsection order mismatch: expected {expected_subsections}, got {subsection_headings}"
            )

        capability_rows = parse_unique_table_subsection(
            lines,
            section_start,
            section_end,
            CAPABILITY_TABLE_HEADING,
            CAPABILITY_HEADERS,
            errors,
            label,
        )
        child_rows = parse_unique_table_subsection(
            lines,
            section_start,
            section_end,
            SUB_CAPABILITY_TABLE_HEADING,
            SUB_CAPABILITY_HEADERS,
            errors,
            label,
        )
        if len(capability_rows) != 1:
            errors.append(f"{label} must contain exactly one Capability row")
        elif (
            capability_rows[0]["Capability ID"] != section_id
            or capability_rows[0]["Capability name"] != section_name
        ):
            errors.append(
                f"{label} heading does not match Capability row ID/name: "
                f"{capability_rows[0]['Capability ID']} / {capability_rows[0]['Capability name']}"
            )
        for row in capability_rows:
            row["__section_id__"] = section_id
        for row in child_rows:
            row["__section_id__"] = section_id
            if row["Capability ID"] != section_id:
                errors.append(
                    f"line {row['__line__']}: Sub-capability parent {row['Capability ID']} "
                    f"does not match chapter {section_id}"
                )
        capabilities.extend(capability_rows)
        sub_capabilities.extend(child_rows)
    return capabilities, sub_capabilities


def parse_legacy_table(lines: list[str], errors: list[str]) -> list[dict[str, str]]:
    indexes = [index for index, line in enumerate(lines) if line.strip() == LEGACY_HEADING]
    if not indexes:
        errors.append(f"missing section {LEGACY_HEADING}")
        return []
    if len(indexes) > 1:
        errors.append(f"duplicate section {LEGACY_HEADING}")
        return []
    heading_index = indexes[0]
    chapter_indexes = [
        index
        for index, line in enumerate(lines)
        if CAPABILITY_SECTION_RE.fullmatch(line.strip())
    ]
    if chapter_indexes and heading_index < max(chapter_indexes):
        errors.append(f"{LEGACY_HEADING} must appear after all Capability chapters")
    return parse_table_after_heading(
        lines, heading_index, len(lines), LEGACY_HEADERS, errors, LEGACY_HEADING
    )


def duplicate_values(rows: list[dict[str, str]], field: str) -> set[str]:
    seen: set[str] = set()
    duplicates: set[str] = set()
    for row in rows:
        current = row[field]
        if current in seen:
            duplicates.add(current)
        seen.add(current)
    return duplicates


def parse_adjacency(raw: str, line: str, errors: list[str]) -> set[str]:
    if raw == "none":
        return set()
    if CAPABILITY_ID_RE.fullmatch(raw):
        return {raw}
    if not ADJACENCY_RE.fullmatch(raw):
        errors.append(f"line {line}: invalid Adjacent capabilities syntax: {raw}")
        return set()
    refs = re.findall(CODE_CAPABILITY_ID, raw)
    duplicates = sorted({ref for ref in refs if refs.count(ref) > 1})
    for duplicate in duplicates:
        errors.append(f"line {line}: duplicate Adjacent capability reference: {duplicate}")
    return set(refs)


def parse_legacy_mapping(raw: str, line: str, errors: list[str]) -> set[str]:
    if CAPABILITY_ID_RE.fullmatch(raw):
        return {raw}
    targets = raw
    support_match = SUPPORT_MAPPING_RE.fullmatch(raw)
    if support_match:
        targets = support_match.group("targets")
        if targets == "`CAP-*`":
            return set()
    if not LEGACY_CAPABILITY_LIST_RE.fullmatch(targets):
        errors.append(f"line {line}: invalid Legacy Mapping target syntax: {raw}")
        return set()
    return set(re.findall(CODE_CAPABILITY_ID, targets))


def validate_registry(path: Path) -> tuple[list[str], list[str], dict[str, int]]:
    errors: list[str] = []
    warnings: list[str] = []
    counts = {"capabilities": 0, "sub_capabilities": 0, "legacy_mappings": 0}
    if not path.exists():
        return [f"registry file does not exist: {path}"], warnings, counts

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        return [f"cannot read registry as UTF-8 text: {path}: {exc}"], warnings, counts
    validate_table_sections(lines, errors)
    if any(line.strip() in {"## V2 Capability Table", "## Level-1 Sub-capability Table"} for line in lines):
        errors.append("legacy flat Capability/Sub-capability table sections are not allowed")
    capabilities, sub_capabilities = parse_capability_sections(lines, errors)
    legacy_mappings = parse_legacy_table(lines, errors)
    counts = {
        "capabilities": len(capabilities),
        "sub_capabilities": len(sub_capabilities),
        "legacy_mappings": len(legacy_mappings),
    }
    for field in ("Capability ID", "Capability slug", "Downstream document prefix"):
        for duplicate in sorted(duplicate_values(capabilities, field)):
            errors.append(f"duplicate {field}: {duplicate}")
    for duplicate in sorted(duplicate_values(sub_capabilities, "Sub-capability ID")):
        errors.append(f"duplicate Sub-capability ID: {duplicate}")
    for duplicate in sorted(duplicate_values(legacy_mappings, "V1 slug")):
        errors.append(f"duplicate V1 slug: {duplicate}")

    capability_by_id = {row["Capability ID"]: row for row in capabilities}
    capability_ids = set(capability_by_id)
    adjacency: dict[str, set[str]] = {}
    for row in capabilities:
        line = row["__line__"]
        capability_id = row["Capability ID"]
        slug = row["Capability slug"]
        prefix = row["Downstream document prefix"]
        if not CAPABILITY_ID_RE.fullmatch(capability_id):
            errors.append(f"line {line}: invalid Capability ID: {capability_id}")
        if not SLUG_RE.fullmatch(slug):
            errors.append(f"line {line}: invalid Capability slug: {slug}")
        if not PREFIX_RE.fullmatch(prefix):
            errors.append(f"line {line}: invalid downstream prefix: {prefix}")
        if row["Lifecycle status"] != "Active v2":
            errors.append(f"line {line}: unsupported Capability lifecycle status: {row['Lifecycle status']}")
        if not row["Owner"]:
            errors.append(f"line {line}: Capability Owner is empty")

        refs = parse_adjacency(row["Adjacent capabilities"], line, errors)
        adjacency[capability_id] = refs
        if capability_id in refs:
            errors.append(f"line {line}: Capability cannot be adjacent to itself: {capability_id}")
        for ref in sorted(refs - capability_ids):
            errors.append(f"line {line}: unknown adjacent Capability ID: {ref}")

    for capability_id, refs in sorted(adjacency.items()):
        for ref in sorted(refs & capability_ids):
            if capability_id not in adjacency.get(ref, set()):
                warnings.append(
                    f"asymmetric adjacency requires touched-boundary review: {capability_id} -> {ref}"
                )

    for row in sub_capabilities:
        line = row["__line__"]
        parent = row["Capability ID"]
        sub_id = row["Sub-capability ID"]
        if parent not in capability_ids:
            errors.append(f"line {line}: unknown parent Capability ID: {parent}")
        if not SUB_CAPABILITY_ID_RE.fullmatch(sub_id):
            errors.append(f"line {line}: invalid Sub-capability ID: {sub_id}")
        elif not sub_id.startswith(f"{parent}-"):
            errors.append(f"line {line}: Sub-capability ID {sub_id} does not match parent {parent}")
        if row["Status"] != "Active v2":
            errors.append(f"line {line}: unsupported Sub-capability status: {row['Status']}")
        if parent in capability_by_id:
            expected_fr_prefix = f"FR-{capability_by_id[parent]['Downstream document prefix']}"
            if row["Related FR prefix"] != expected_fr_prefix:
                errors.append(
                    f"line {line}: Related FR prefix {row['Related FR prefix']} does not match {expected_fr_prefix}"
                )

    for row in legacy_mappings:
        line = row["__line__"]
        legacy_slug = row["V1 slug"]
        mapping = row["V2 mapping"]
        if not SLUG_RE.fullmatch(legacy_slug):
            errors.append(f"line {line}: invalid V1 slug: {legacy_slug}")
        refs = parse_legacy_mapping(mapping, line, errors)
        for ref in sorted(refs - capability_ids):
            errors.append(f"line {line}: unknown Legacy Mapping Capability ID: {ref}")
        if not row["Migration note"]:
            errors.append(f"line {line}: Legacy Mapping migration note is empty")

    return errors, warnings, counts


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="Validate the canonical V2 Capability Registry chapters and Markdown tables."
    )
    parser.add_argument("--path", type=Path, default=DEFAULT_REGISTRY)
    args = parser.parse_args(argv)
    path = args.path if args.path.is_absolute() else ROOT / args.path

    errors, warnings, counts = validate_registry(path)
    print("Capability Registry validation")
    print(f"Path: {path}")
    print(
        "Rows: "
        f"capabilities={counts['capabilities']}, "
        f"sub_capabilities={counts['sub_capabilities']}, "
        f"legacy_mappings={counts['legacy_mappings']}"
    )
    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"- {warning}")
    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"- {error}")
        print("\nResult: failed")
        return 1
    print("\nResult: passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
