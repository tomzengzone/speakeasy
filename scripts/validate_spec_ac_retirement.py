#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any


MANIFEST_REL = Path("docs/process/migrations/spec-ac-retirement.json")
SCHEMA_REL = Path("docs/process/governance/schemas/spec-ac-retirement.schema.json")
INDEX_REL = Path("docs/process/governance/index.json")
ARTIFACT_SHARDS_REL = Path("docs/process/governance/artifacts")
GOVERNANCE_SHARD_ROUTE = "artifacts/governance.json"
EXPECTED_SCHEMA_SHA256 = "605d159875e6fdd9a531dd491e8c745b685b4ea32d95219b38816d9556df9d7b"

TOP_LEVEL_FIELDS = {
    "schema_version",
    "artifact_id",
    "lifecycle",
    "legacy_root",
    "legacy_glob",
    "archive_root",
    "expected_file_count",
    "legacy_path_digest",
    "prohibited_input_domains",
    "sunset_conditions",
    "records",
}
RECORD_FIELDS = {
    "old_path",
    "old_id",
    "source_kind",
    "status",
    "destinations",
    "reason",
    "owner",
}
DESTINATION_FIELDS = {"kind", "id"}
SOURCE_KINDS = {"spec", "acceptance"}
DESTINATION_KINDS = {
    "vertical-slice",
    "functional-requirement",
    "api-contract",
    "domain-contract",
    "persistence-contract",
    "ai-contract",
    "ux-contract",
    "executable-regression-test",
}
STATUSES = {"grandfathered-unverified", "migrated", "obsolete", "rejected"}
NON_MIGRATED_STATUSES = {"grandfathered-unverified", "obsolete", "rejected"}
LEGACY_ID_PATTERN = (
    r"^(?:(?:[A-Z0-9]+-)*SPEC(?:-[A-Z0-9]+)*|"
    r"(?:[A-Z0-9]+-)*AC(?:-[A-Z0-9]+)*)-[0-9]{3}$"
)
LEGACY_ID = re.compile(LEGACY_ID_PATTERN)
DESTINATION_ID_PATTERN = r"^[A-Z][A-Z0-9_-]*$"
DESTINATION_ID = re.compile(DESTINATION_ID_PATTERN)
HEADING_TOKEN = re.compile(r"^#{1,6}\s+([^\s`]+)")
MARKDOWN_HEADING = re.compile(r"^#{1,6}\s+(.+?)\s*$")
DEFINITION_TABLE_HEADINGS = {
    "Spec Trace IDs",
    "Spec Coverage",
    "Acceptance Coverage Map",
    "Acceptance Criteria",
}

EXPECTED_ARTIFACTS = {
    "SPEC_AC_RETIREMENT_MANIFEST": {
        "canonical_path": MANIFEST_REL.as_posix(),
        "accountable_owner": "product-object-governance-change",
        "lifecycle": "migration-only",
        "validation_command": "python scripts/validate_spec_ac_retirement.py",
    },
    "SPEC_AC_RETIREMENT_SCHEMA": {
        "canonical_path": SCHEMA_REL.as_posix(),
        "accountable_owner": "product-object-governance-change",
        "lifecycle": "migration-only",
        "validation_command": "python scripts/validate_spec_ac_retirement.py",
    },
    "SPEC_AC_RETIREMENT_VALIDATOR": {
        "canonical_path": "scripts/validate_spec_ac_retirement.py",
        "accountable_owner": "product-object-governance-change",
        "lifecycle": "migration-only",
        "validation_command": "python -m unittest tests.test_validate_spec_ac_retirement -v",
    },
    "SPEC_AC_RETIREMENT_VALIDATOR_TEST": {
        "canonical_path": "tests/test_validate_spec_ac_retirement.py",
        "accountable_owner": "product-object-governance-change",
        "lifecycle": "migration-only",
        "validation_command": "python -m unittest tests.test_validate_spec_ac_retirement -v",
    },
}


def _load_json(path: Path, label: str, errors: list[str]) -> dict[str, Any] | None:
    if not path.is_file():
        errors.append(f"missing {label}: {path.as_posix()}")
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        errors.append(f"invalid {label} JSON at {path.as_posix()}: {exc}")
        return None
    if not isinstance(value, dict):
        errors.append(f"{label} must be a JSON object: {path.as_posix()}")
        return None
    return value


def _canonical_json_sha256(value: Any) -> str:
    encoded = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def _validate_schema(schema: dict[str, Any], errors: list[str]) -> None:
    if _canonical_json_sha256(schema) != EXPECTED_SCHEMA_SHA256:
        errors.append("schema canonical SHA-256 does not match the pinned migration contract")
    if schema.get("type") != "object":
        errors.append("schema root type must be object")
    if schema.get("additionalProperties") is not False:
        errors.append("schema root additionalProperties must be false")
    required = schema.get("required")
    if not isinstance(required, list) or set(required) != TOP_LEVEL_FIELDS:
        errors.append("schema root required fields do not match the manifest contract")
    properties = schema.get("properties")
    if not isinstance(properties, dict) or not TOP_LEVEL_FIELDS <= set(properties):
        errors.append("schema root properties do not cover every required field")
        return

    expected_constants = {
        "schema_version": "1.0",
        "artifact_id": "SPEC_AC_RETIREMENT_MANIFEST",
        "lifecycle": "migration-only",
        "legacy_root": "docs/product/increments",
        "legacy_glob": "**/*.md",
        "archive_root": "docs/archive/product-increments",
    }
    for field, expected in expected_constants.items():
        definition = properties.get(field)
        if not isinstance(definition, dict) or definition.get("const") != expected:
            errors.append(f"schema {field} must declare const {expected!r}")

    records = properties.get("records")
    items = records.get("items") if isinstance(records, dict) else None
    if not isinstance(items, dict):
        errors.append("schema records.items must be an object schema")
        return
    if items.get("type") != "object" or items.get("additionalProperties") is not False:
        errors.append("schema record must be an object with additionalProperties false")
    record_required = items.get("required")
    if not isinstance(record_required, list) or set(record_required) != RECORD_FIELDS:
        errors.append("schema record required fields do not match the record contract")
    record_properties = items.get("properties")
    if not isinstance(record_properties, dict) or not RECORD_FIELDS <= set(record_properties):
        errors.append("schema record properties do not cover every required field")
        return
    expected_enums = {
        "source_kind": SOURCE_KINDS,
        "status": STATUSES,
    }
    for field, expected in expected_enums.items():
        definition = record_properties.get(field)
        actual = definition.get("enum") if isinstance(definition, dict) else None
        if not isinstance(actual, list) or set(actual) != expected:
            errors.append(f"schema record {field} enum does not match the validator contract")
    old_id_definition = record_properties.get("old_id")
    if (
        not isinstance(old_id_definition, dict)
        or old_id_definition.get("pattern") != LEGACY_ID_PATTERN
    ):
        errors.append("schema record old_id pattern does not match the strict parser contract")
    destinations_definition = record_properties.get("destinations")
    destination_items = (
        destinations_definition.get("items")
        if isinstance(destinations_definition, dict)
        else None
    )
    if not isinstance(destination_items, dict):
        errors.append("schema record destinations.items must be an object schema")
        return
    if (
        destination_items.get("type") != "object"
        or destination_items.get("additionalProperties") is not False
        or set(destination_items.get("required", [])) != DESTINATION_FIELDS
    ):
        errors.append("schema destination object contract is incomplete")
    destination_properties = destination_items.get("properties")
    if not isinstance(destination_properties, dict):
        errors.append("schema destination properties must be an object")
        return
    kind_definition = destination_properties.get("kind")
    kind_enum = kind_definition.get("enum") if isinstance(kind_definition, dict) else None
    if not isinstance(kind_enum, list) or set(kind_enum) != DESTINATION_KINDS:
        errors.append("schema destination kind enum does not match the validator contract")
    id_definition = destination_properties.get("id")
    if (
        not isinstance(id_definition, dict)
        or id_definition.get("pattern") != DESTINATION_ID_PATTERN
    ):
        errors.append("schema destination id pattern does not match the validator contract")


def _validate_record_shape(record: Any, index: int, errors: list[str]) -> bool:
    prefix = f"record[{index}]"
    if not isinstance(record, dict):
        errors.append(f"{prefix} must be an object")
        return False
    missing = sorted(RECORD_FIELDS - set(record))
    unexpected = sorted(set(record) - RECORD_FIELDS)
    if missing:
        errors.append(f"{prefix} missing fields: {', '.join(missing)}")
    if unexpected:
        errors.append(f"{prefix} has unexpected fields: {', '.join(unexpected)}")
    if missing or unexpected:
        return False

    old_path = record["old_path"]
    old_id = record["old_id"]
    source_kind = record["source_kind"]
    status = record["status"]
    destinations = record["destinations"]

    if not isinstance(old_path, str) or not old_path:
        errors.append(f"{prefix}.old_path must be a non-empty string")
    if not isinstance(old_id, str) or LEGACY_ID.fullmatch(old_id) is None:
        errors.append(f"{prefix}.old_id is not a valid Spec/AC ID: {old_id!r}")
    if not isinstance(source_kind, str) or source_kind not in SOURCE_KINDS:
        errors.append(f"{prefix}.source_kind has invalid enum value: {source_kind!r}")
    if not isinstance(status, str) or status not in STATUSES:
        errors.append(f"{prefix}.status has invalid enum value: {status!r}")
    if not isinstance(destinations, list):
        errors.append(f"{prefix}.destinations must be an array")
        destinations = []
    else:
        destination_pairs: list[tuple[str, str]] = []
        for destination_index, destination in enumerate(destinations):
            destination_prefix = f"{prefix}.destinations[{destination_index}]"
            if not isinstance(destination, dict):
                errors.append(f"{destination_prefix} must be an object")
                continue
            missing_destination_fields = sorted(DESTINATION_FIELDS - set(destination))
            unexpected_destination_fields = sorted(set(destination) - DESTINATION_FIELDS)
            if missing_destination_fields:
                errors.append(
                    f"{destination_prefix} missing fields: {', '.join(missing_destination_fields)}"
                )
            if unexpected_destination_fields:
                errors.append(
                    f"{destination_prefix} has unexpected fields: {', '.join(unexpected_destination_fields)}"
                )
            if missing_destination_fields or unexpected_destination_fields:
                continue
            kind = destination["kind"]
            destination_id = destination["id"]
            if not isinstance(kind, str) or kind not in DESTINATION_KINDS:
                errors.append(f"{destination_prefix}.kind has invalid enum value: {kind!r}")
            if (
                not isinstance(destination_id, str)
                or DESTINATION_ID.fullmatch(destination_id) is None
            ):
                errors.append(f"{destination_prefix}.id is invalid: {destination_id!r}")
            if isinstance(kind, str) and isinstance(destination_id, str):
                destination_pairs.append((kind, destination_id))
        if len(destination_pairs) != len(set(destination_pairs)):
            errors.append(f"{prefix}.destinations must be unique")
    if (
        not isinstance(record["reason"], str)
        or not record["reason"].strip()
        or re.search(r"[\u4e00-\u9fff]", record["reason"]) is None
    ):
        errors.append(f"{prefix}.reason must be a non-empty Chinese explanation")
    if not isinstance(record["owner"], str) or not record["owner"].strip():
        errors.append(f"{prefix}.owner must be a non-empty string")

    if status == "migrated" and not destinations:
        errors.append(f"{prefix} migrated requires at least one typed destination")
    elif isinstance(status, str) and status in NON_MIGRATED_STATUSES and destinations:
        errors.append(f"{prefix} status {status} requires empty destinations")
    return True


def _validate_manifest_shape(manifest: dict[str, Any], errors: list[str]) -> list[dict[str, Any]]:
    missing = sorted(TOP_LEVEL_FIELDS - set(manifest))
    unexpected = sorted(set(manifest) - TOP_LEVEL_FIELDS)
    if missing:
        errors.append(f"manifest missing fields: {', '.join(missing)}")
    if unexpected:
        errors.append(f"manifest has unexpected fields: {', '.join(unexpected)}")

    expected_constants = {
        "schema_version": "1.0",
        "artifact_id": "SPEC_AC_RETIREMENT_MANIFEST",
        "lifecycle": "migration-only",
        "legacy_root": "docs/product/increments",
        "legacy_glob": "**/*.md",
        "archive_root": "docs/archive/product-increments",
    }
    for field, expected in expected_constants.items():
        if manifest.get(field) != expected:
            errors.append(f"manifest {field} must be {expected!r}")
    if not isinstance(manifest.get("expected_file_count"), int) or manifest.get("expected_file_count", -1) < 0:
        errors.append("manifest expected_file_count must be a non-negative integer")
    digest = manifest.get("legacy_path_digest")
    if not isinstance(digest, str) or re.fullmatch(r"[a-f0-9]{64}", digest) is None:
        errors.append("manifest legacy_path_digest must be a lowercase SHA-256 digest")
    prohibited = manifest.get("prohibited_input_domains")
    if (
        not isinstance(prohibited, list)
        or any(not isinstance(item, str) for item in prohibited)
        or set(prohibited) != {"product", "engineering"}
        or len(prohibited) != 2
    ):
        errors.append("manifest prohibited_input_domains must contain product and engineering exactly once")
    sunset = manifest.get("sunset_conditions")
    if (
        not isinstance(sunset, list)
        or len(sunset) < 3
        or len(sunset) != len(set(item for item in sunset if isinstance(item, str)))
        or any(not isinstance(item, str) or not item.strip() for item in sunset)
    ):
        errors.append("manifest sunset_conditions must contain at least three unique non-empty strings")

    records = manifest.get("records")
    if not isinstance(records, list):
        errors.append("manifest records must be an array")
        return []
    valid_records: list[dict[str, Any]] = []
    for index, record in enumerate(records):
        if _validate_record_shape(record, index, errors):
            valid_records.append(record)
    return valid_records


def _definition_tokens(line: str, table_is_definition: bool) -> list[str]:
    tokens: list[str] = []
    heading = HEADING_TOKEN.match(line)
    if heading:
        tokens.append(heading.group(1).strip("`"))
    if table_is_definition and line.startswith("|"):
        first_cell = line.strip().strip("|").split("|", 1)[0].strip().strip("`")
        tokens.append(first_cell)
    return tokens


def extract_definition_ids(path: Path) -> set[str]:
    ids: set[str] = set()
    current_heading = ""
    for line in path.read_text(encoding="utf-8").splitlines():
        heading = MARKDOWN_HEADING.match(line)
        if heading:
            current_heading = heading.group(1).strip()
        for token in _definition_tokens(line, current_heading in DEFINITION_TABLE_HEADINGS):
            if LEGACY_ID.fullmatch(token):
                ids.add(token)
    return ids


def _validate_legacy_inventory(
    root: Path,
    manifest: dict[str, Any],
    records: list[dict[str, Any]],
    errors: list[str],
) -> tuple[int, int]:
    legacy_root_value = manifest.get("legacy_root")
    legacy_glob = manifest.get("legacy_glob")
    if not isinstance(legacy_root_value, str) or not isinstance(legacy_glob, str):
        return 0, 0
    repository_root = root.resolve()
    legacy_root = (root / legacy_root_value).resolve()
    if not _is_within(legacy_root, repository_root) or not legacy_root.is_dir():
        errors.append("manifest legacy_root must be an existing directory inside the repository")
        return 0, 0

    legacy_files = sorted(
        (path for path in legacy_root.glob(legacy_glob) if path.is_file()),
        key=lambda path: path.relative_to(root).as_posix(),
    )
    escaped_files = [path for path in legacy_files if not _is_within(path.resolve(), legacy_root)]
    if escaped_files:
        errors.append("legacy glob resolved files outside legacy_root")
    expected_count = manifest.get("expected_file_count")
    if isinstance(expected_count, int) and len(legacy_files) != expected_count:
        errors.append(
            f"legacy file count mismatch: manifest expects {expected_count}, repository has {len(legacy_files)}"
        )
    normalized_paths = [path.relative_to(root).as_posix() for path in legacy_files]
    actual_digest = hashlib.sha256("\n".join(normalized_paths).encode("utf-8")).hexdigest()
    if manifest.get("legacy_path_digest") != actual_digest:
        errors.append(
            "legacy path digest mismatch: manifest does not cover the exact normalized file set"
        )

    definition_files = sorted(
        (
            path
            for path in legacy_root.rglob("*.md")
            if path.name in {"spec.md", "acceptance.md"}
        ),
        key=lambda path: path.relative_to(root).as_posix(),
    )
    definitions_by_path: dict[str, set[str]] = {}
    for path in definition_files:
        relative = path.relative_to(root).as_posix()
        definitions_by_path[relative] = extract_definition_ids(path)
    expected_pairs = {
        (path, old_id)
        for path, old_ids in definitions_by_path.items()
        for old_id in old_ids
    }

    record_pairs: list[tuple[str, str]] = []
    record_ids: list[str] = []
    for index, record in enumerate(records):
        old_path = record.get("old_path")
        old_id = record.get("old_id")
        if not isinstance(old_path, str) or not isinstance(old_id, str):
            continue
        record_pairs.append((old_path, old_id))
        record_ids.append(old_id)
        candidate = (root / old_path).resolve()
        if not _is_within(candidate, legacy_root):
            errors.append(f"record[{index}].old_path resolves outside legacy_root: {old_path}")
            continue
        if not candidate.is_file():
            errors.append(f"record[{index}].old_path does not exist: {old_path}")
            continue
        expected_kind = "spec" if candidate.name == "spec.md" else "acceptance" if candidate.name == "acceptance.md" else None
        if expected_kind is None:
            errors.append(f"record[{index}].old_path is not a spec.md or acceptance.md file: {old_path}")
        elif record.get("source_kind") != expected_kind:
            errors.append(f"record[{index}].source_kind does not match old_path: {old_path}")
        if old_id not in definitions_by_path.get(old_path, set()):
            errors.append(f"record[{index}] old_id is not defined by its old_path: {old_path}#{old_id}")

    duplicate_pairs = sorted(pair for pair, count in Counter(record_pairs).items() if count > 1)
    if duplicate_pairs:
        errors.append(
            "manifest contains duplicate old_path/old_id records: "
            + ", ".join(f"{path}#{old_id}" for path, old_id in duplicate_pairs)
        )
    duplicate_ids = sorted(old_id for old_id, count in Counter(record_ids).items() if count > 1)
    if duplicate_ids:
        errors.append("manifest contains duplicate old_id values: " + ", ".join(duplicate_ids))

    actual_pairs = set(record_pairs)
    missing = sorted(expected_pairs - actual_pairs)
    unexpected = sorted(actual_pairs - expected_pairs)
    if missing:
        errors.append(
            "manifest is missing defined legacy IDs: "
            + ", ".join(f"{path}#{old_id}" for path, old_id in missing)
        )
    if unexpected:
        errors.append(
            "manifest contains undefined legacy IDs: "
            + ", ".join(f"{path}#{old_id}" for path, old_id in unexpected)
        )

    sorted_pairs = sorted(record_pairs)
    if record_pairs != sorted_pairs:
        errors.append("manifest records must be sorted by old_path then old_id")
    return len(legacy_files), len(expected_pairs)


def _validate_governance_registration(root: Path, errors: list[str]) -> None:
    index = _load_json(root / INDEX_REL, "governance index", errors)
    routes = index.get("artifact_routes") if isinstance(index, dict) else None
    if not isinstance(routes, dict):
        errors.append("governance index artifact_routes must be an object")
        routes = {}
    for artifact_id in EXPECTED_ARTIFACTS:
        if routes.get(artifact_id) != GOVERNANCE_SHARD_ROUTE:
            errors.append(
                f"artifact route for {artifact_id} must be {GOVERNANCE_SHARD_ROUTE}"
            )

    shard_root = root / ARTIFACT_SHARDS_REL
    artifacts: dict[str, list[tuple[str, dict[str, Any]]]] = {}
    for shard_path in sorted(shard_root.glob("*.json")):
        shard = _load_json(shard_path, "governance artifact shard", errors)
        if shard is None:
            continue
        defaults = shard.get("defaults")
        items = shard.get("artifacts")
        containers: list[tuple[str, Any]] = [("defaults", defaults)]
        if isinstance(items, list):
            containers.extend((f"artifact[{index}]", item) for index, item in enumerate(items))
        else:
            errors.append(f"artifact shard {shard_path.as_posix()} artifacts must be an array")
        for location, item in containers:
            if not isinstance(item, dict):
                continue
            for field in ("required_direct_inputs", "conditional_inputs"):
                inputs = item.get(field, [])
                if isinstance(inputs, list) and "SPEC_AC_RETIREMENT_MANIFEST" in inputs:
                    errors.append(
                        "SPEC_AC_RETIREMENT_MANIFEST must not appear in "
                        f"{shard_path.relative_to(root).as_posix()} {location}.{field}"
                    )
            artifact_id = item.get("artifact_id")
            if isinstance(artifact_id, str):
                artifacts.setdefault(artifact_id, []).append(
                    (shard_path.relative_to(root / "docs/process/governance").as_posix(), item)
                )

    for artifact_id, expected in EXPECTED_ARTIFACTS.items():
        occurrences = artifacts.get(artifact_id, [])
        if len(occurrences) != 1:
            errors.append(f"{artifact_id} must be registered exactly once in artifact shards")
            continue
        shard_route, artifact = occurrences[0]
        if shard_route != GOVERNANCE_SHARD_ROUTE:
            errors.append(f"{artifact_id} must be registered in {GOVERNANCE_SHARD_ROUTE}")
        for field, expected_value in expected.items():
            if artifact.get(field) != expected_value:
                errors.append(
                    f"{artifact_id}.{field} must be {expected_value!r}, got {artifact.get(field)!r}"
                )


def validate_repository(root: Path) -> tuple[list[str], dict[str, int]]:
    root = root.resolve()
    errors: list[str] = []
    schema = _load_json(root / SCHEMA_REL, "retirement schema", errors)
    manifest = _load_json(root / MANIFEST_REL, "retirement manifest", errors)
    if schema is not None:
        _validate_schema(schema, errors)
    records: list[dict[str, Any]] = []
    legacy_file_count = 0
    legacy_id_count = 0
    if manifest is not None:
        records = _validate_manifest_shape(manifest, errors)
        legacy_file_count, legacy_id_count = _validate_legacy_inventory(
            root, manifest, records, errors
        )
    _validate_governance_registration(root, errors)
    metrics = {
        "legacy_files": legacy_file_count,
        "legacy_ids": legacy_id_count,
        "manifest_records": len(records),
    }
    return errors, metrics


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate the Spec/AC retirement migration contract.")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    errors, metrics = validate_repository(args.root)
    if errors:
        print("Spec/AC retirement validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        "Spec/AC retirement validation passed: "
        f"{metrics['legacy_files']} legacy files, "
        f"{metrics['legacy_ids']} defined IDs, "
        f"{metrics['manifest_records']} manifest records."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
