#!/usr/bin/env python3
"""Validate selected story-map capability sections against the registry boundary."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


CAPABILITY_ID = re.compile(r"^CAP-[A-Z][A-Z0-9-]*$")
STORY_ID = re.compile(r"^(US|VS)-([A-Z][A-Z0-9-]*)-(\d{3})$")
SECTION = re.compile(r"^## \d+\..*[（(](CAP-[A-Z][A-Z0-9-]*)\s*/")


def cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def unquote(value: str) -> str:
    return value[1:-1] if value.startswith("`") and value.endswith("`") else value


def registry_adjacency(path: Path) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        row = cells(line) if line.startswith("|") else []
        if len(row) != 12:
            continue
        capability = unquote(row[0])
        if not CAPABILITY_ID.fullmatch(capability):
            continue
        adjacent = {
            value
            for value in re.findall(r"`(CAP-[A-Z][A-Z0-9-]*)`", row[9])
            if value != capability
        }
        result[capability] = adjacent
    return result


def validate(story_map: Path, registry: Path, selected: set[str]) -> list[str]:
    adjacency = registry_adjacency(registry)
    errors: list[str] = []
    unknown = selected - adjacency.keys()
    if unknown:
        errors.append(f"unknown capability: {', '.join(sorted(unknown))}")

    current: str | None = None
    seen: dict[str, int] = {}
    counts = {capability: {"US": 0, "VS": 0} for capability in selected}

    for number, line in enumerate(story_map.read_text(encoding="utf-8").splitlines(), start=1):
        heading = SECTION.match(line)
        if heading:
            current = heading.group(1)
            continue
        if not line.startswith("|"):
            continue

        row = cells(line)
        if row and row[0] in {"Id", "---"}:
            continue
        if current not in selected:
            if len(row) == 5:
                external_id = unquote(row[0])
                if STORY_ID.fullmatch(external_id):
                    if external_id in seen:
                        errors.append(
                            f"line {number}: duplicate {external_id}; "
                            f"first seen at line {seen[external_id]}"
                        )
                    seen[external_id] = number
            continue
        if len(row) != 5:
            errors.append(f"line {number}: expected 5 columns, found {len(row)}")
            continue
        row_id = unquote(row[0])
        match = STORY_ID.fullmatch(row_id)
        if not match:
            errors.append(f"line {number}: invalid Story/Slice ID {row_id}")
            continue
        if row_id in seen:
            errors.append(f"line {number}: duplicate {row_id}; first seen at line {seen[row_id]}")
        seen[row_id] = number

        kind, prefix, _ = match.groups()
        counts[current][kind] += 1
        expected_prefix = current.removeprefix("CAP-")
        if prefix != expected_prefix:
            errors.append(f"line {number}: {row_id} prefix does not match section {current}")

        status = unquote(row[2])
        if status not in {"draft", "approved"}:
            errors.append(f"line {number}: unsupported status {status}")
        primary = unquote(row[3])
        if primary != current:
            errors.append(f"line {number}: primary {primary} does not match section {current}")

        affected_cell = row[4]
        affected_pattern = r"`none`|`CAP-[A-Z][A-Z0-9-]*`(?:, `CAP-[A-Z][A-Z0-9-]*`)*"
        if not re.fullmatch(affected_pattern, affected_cell):
            errors.append(f"line {number}: malformed affected capability list")
            continue
        affected = set(re.findall(r"`(CAP-[A-Z][A-Z0-9-]*)`", affected_cell))
        invalid = affected - adjacency.get(current, set())
        if invalid:
            errors.append(
                f"line {number}: {row_id} uses non-adjacent capability "
                f"{', '.join(sorted(invalid))} for {current}"
            )

    for capability, kinds in counts.items():
        if kinds["US"] == 0 or kinds["VS"] == 0:
            errors.append(f"{capability}: expected at least one User Story and one Vertical Slice")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--story-map", type=Path, default=Path("docs/product/story_map.md"))
    parser.add_argument("--registry", type=Path, default=Path("docs/product/feature_registry.md"))
    parser.add_argument("--capability", action="append", required=True)
    args = parser.parse_args()

    selected = set(args.capability)
    errors = validate(args.story_map, args.registry, selected)
    if errors:
        print("Story map validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Story map validation passed: {', '.join(sorted(selected))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
