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
SHARD_NAME = re.compile(r"^user_story_CAP_([A-Z][A-Z0-9-]*)\.md$")


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


def validate(story_maps: list[Path], registry: Path, selected: set[str]) -> list[str]:
    adjacency = registry_adjacency(registry)
    errors: list[str] = []
    unknown = selected - adjacency.keys()
    if unknown:
        errors.append(f"unknown capability: {', '.join(sorted(unknown))}")

    seen: dict[str, tuple[Path, int]] = {}
    counts = {capability: {"US": 0, "VS": 0} for capability in selected}

    for story_map in story_maps:
        shard_match = SHARD_NAME.fullmatch(story_map.name)
        expected_capability = f"CAP-{shard_match.group(1)}" if shard_match else None
        current: str | None = None
        current_story: str | None = None
        section_count = 0

        for number, line in enumerate(story_map.read_text(encoding="utf-8").splitlines(), start=1):
            location = f"{story_map}:{number}"
            heading = SECTION.match(line)
            if heading:
                current = heading.group(1)
                current_story = None
                section_count += 1
                if expected_capability and current != expected_capability:
                    errors.append(
                        f"{location}: section {current} does not match shard {expected_capability}"
                    )
                continue
            if not line.startswith("|"):
                continue

            row = cells(line)
            if row and row[0] in {"Id", "---"}:
                continue
            if len(row) != 5:
                errors.append(f"{location}: expected 5 columns, found {len(row)}")
                continue
            row_id = unquote(row[0])
            match = STORY_ID.fullmatch(row_id)
            if not match:
                errors.append(f"{location}: invalid Story/Slice ID {row_id}")
                continue
            if row_id in seen:
                first_path, first_number = seen[row_id]
                errors.append(
                    f"{location}: duplicate {row_id}; first seen at {first_path}:{first_number}"
                )
            else:
                seen[row_id] = (story_map, number)

            kind, prefix, _ = match.groups()
            if kind == "US":
                current_story = row_id
            elif current_story is None:
                errors.append(f"{location}: {row_id} has no parent User Story in this shard")

            if current not in selected:
                continue
            counts[current][kind] += 1
            expected_prefix = current.removeprefix("CAP-")
            if prefix != expected_prefix:
                errors.append(f"{location}: {row_id} prefix does not match section {current}")

            status = unquote(row[2])
            if status not in {"draft", "approved"}:
                errors.append(f"{location}: unsupported status {status}")
            primary = unquote(row[3])
            if primary != current:
                errors.append(f"{location}: primary {primary} does not match section {current}")

            affected_cell = row[4]
            affected_pattern = r"`none`|—|`CAP-[A-Z][A-Z0-9-]*`(?:, `CAP-[A-Z][A-Z0-9-]*`)*"
            if not re.fullmatch(affected_pattern, affected_cell):
                errors.append(f"{location}: malformed affected capability list")
                continue
            affected = set(re.findall(r"`(CAP-[A-Z][A-Z0-9-]*)`", affected_cell))
            invalid = affected - adjacency.get(current, set())
            if invalid:
                errors.append(
                    f"{location}: {row_id} uses non-adjacent capability "
                    f"{', '.join(sorted(invalid))} for {current}"
                )

        if expected_capability and section_count != 1:
            errors.append(f"{story_map}: expected exactly one Capability section")

    for capability, kinds in counts.items():
        if kinds["US"] == 0 or kinds["VS"] == 0:
            errors.append(f"{capability}: expected at least one User Story and one Vertical Slice")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--story-map", type=Path, action="append")
    parser.add_argument("--registry", type=Path, default=Path("docs/product/feature_registry.md"))
    parser.add_argument("--capability", action="append", required=True)
    args = parser.parse_args()

    selected = set(args.capability)
    story_maps = args.story_map or sorted(
        Path("docs/product/user_stories").glob("user_story_CAP_*.md")
    )
    errors = [] if story_maps else ["no canonical Story Map shards found"]
    errors.extend(validate(story_maps, args.registry, selected))
    if errors:
        print("Story map validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Story map validation passed: {', '.join(sorted(selected))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
