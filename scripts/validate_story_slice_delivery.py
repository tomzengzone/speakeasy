#!/usr/bin/env python3
"""Validate optional FR branches, typed Test Cases, and derived Story/Slice traceability."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STORY_ITEM_ID = re.compile(r"^(?:US|VS)-[A-Z0-9]+(?:-[A-Z0-9]+)*$")
STORY_COLUMNS = ["Id", "description", "Status"]
STORY_STATUSES = {"draft", "approved"}
SOURCE_KEYS = {"source_fr_id", "source_contract_id", "source_vs_id"}
TC_REQUIRED = {"type", "layer", "scope", "selector", "script_path", "command", "Given", "When", "Then", "Boundary/negative"}
EXECUTION_RESULT_KEYS = {
    "result", "result_status", "execution_result", "execution_status", "run_result",
    "run_status", "test_result", "test_status", "passed", "failed", "blocked", "skipped",
}


def _records(text: str, prefix: str) -> dict[str, dict[str, str]]:
    pattern = re.compile(rf"^###\s+(({re.escape(prefix)})-[A-Z0-9-]+)\b[^\n]*\n(.*?)(?=^###\s+|\Z)", re.M | re.S)
    result: dict[str, dict[str, str]] = {}
    for match in pattern.finditer(text):
        record_id = match.group(1)
        fields: dict[str, str] = {}
        for line in match.group(3).splitlines():
            field = re.match(r"^-\s+([^:]+):\s*(.*)$", line)
            if field:
                fields[field.group(1).strip()] = field.group(2).strip()
        result[record_id] = fields
    return result


def _ids(value: str, prefix: str) -> list[str]:
    return re.findall(rf"`({re.escape(prefix)}-[A-Z0-9-]+)`", value)


def _table_cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _unquote(value: str) -> str:
    return value[1:-1] if value.startswith("`") and value.endswith("`") else value


def parse_story_map(
    text: str, source: str = "STORY_MAP",
) -> tuple[set[str], dict[str, str], set[str], list[str]]:
    approved_stories: set[str] = set()
    approved_vs: set[str] = set()
    parent_by_vs: dict[str, str] = {}
    first_seen: dict[str, int] = {}
    errors: list[str] = []
    current_story: str | None = None
    story_rows = 0
    valid_headers = 0

    for number, line in enumerate(text.splitlines(), 1):
        if not line.lstrip().startswith("|"):
            continue
        cells = _table_cells(line)
        if cells and cells[0] == "Id":
            if cells != STORY_COLUMNS:
                errors.append(
                    f"{source}:{number}: Story/VS table must have columns "
                    f"{' | '.join(STORY_COLUMNS)}"
                )
            else:
                valid_headers += 1
            continue
        if not cells:
            continue
        item_id = _unquote(cells[0])
        if not STORY_ITEM_ID.fullmatch(item_id):
            continue
        story_rows += 1
        if len(cells) != 3:
            errors.append(f"{source}:{number}: Story/VS row must have 3 columns")
            continue
        if item_id in first_seen:
            errors.append(
                f"duplicate Story/Slice ID {item_id}: "
                f"{source}:{first_seen[item_id]} and {source}:{number}"
            )
            continue
        first_seen[item_id] = number

        status = _unquote(cells[2])
        if status not in STORY_STATUSES:
            errors.append(f"{source}:{number}: unsupported Story/VS status {status!r}")
        approved = status == "approved"
        if item_id.startswith("US-"):
            current_story = item_id
            if approved:
                approved_stories.add(item_id)
        elif current_story:
            parent_by_vs[item_id] = current_story
            if approved:
                approved_vs.add(item_id)
        else:
            errors.append(f"{source}:{number}: {item_id} has no parent User Story above it")
            if approved:
                approved_vs.add(item_id)

    if story_rows and not valid_headers:
        errors.append(
            f"{source}: Story/VS rows require the three-column header "
            f"{' | '.join(STORY_COLUMNS)}"
        )
    return approved_stories, parent_by_vs, approved_vs, errors


def _active_artifact(root: Path, artifact_id: str) -> dict:
    contract_root = root / "docs/process/governance"
    index = json.loads((contract_root / "index.json").read_text(encoding="utf-8"))
    shard = index.get("artifact_routes", {}).get(artifact_id)
    if not shard:
        raise ValueError(f"missing active Artifact route: {artifact_id}")
    data = json.loads((contract_root / shard).read_text(encoding="utf-8"))
    defaults = data.get("defaults", {})
    matches = [row for row in data.get("artifacts", []) if row.get("artifact_id") == artifact_id]
    if len(matches) != 1:
        raise ValueError(f"expected one {artifact_id} contract, found {len(matches)}")
    return {**defaults, **matches[0]}


def resolve_story_map(root: Path = ROOT) -> Path:
    """Resolve the single canonical STORY_MAP document from its active contract."""
    root = root.resolve()
    canonical = str(_active_artifact(root, "STORY_MAP").get("canonical_path", ""))
    if not canonical or "{" in canonical or "}" in canonical:
        raise ValueError("STORY_MAP canonical_path must be one literal document path")
    path = root / canonical.replace("\\", "/")
    if not path.is_file():
        raise ValueError(f"canonical STORY_MAP document does not exist: {canonical}")
    return path


def _active_engineering_contract_ids(root: Path) -> set[str]:
    contract_root = root / "docs/process/governance"
    index = json.loads((contract_root / "index.json").read_text(encoding="utf-8"))
    active_routes = set(index.get("artifact_routes", {}))
    engineering = json.loads((contract_root / "artifacts/engineering.json").read_text(encoding="utf-8"))
    default_contract = engineering.get("defaults", {}).get("engineering_contract", False)
    engineering_ids = {
        row["artifact_id"] for row in engineering.get("artifacts", [])
        if row.get("artifact_id") in active_routes
    }
    contract_ids = {
        row["artifact_id"] for row in engineering.get("artifacts", [])
        if row.get("artifact_id") in active_routes
        and row.get("engineering_contract", default_contract) is True
    }

    product = json.loads((contract_root / "artifacts/product.json").read_text(encoding="utf-8"))
    product_by_id = {row["artifact_id"]: row for row in product.get("artifacts", [])}
    for route_id in ("TEST_CASE_CATALOG", "TRACEABILITY"):
        declared = set(product_by_id[route_id].get("conditional_inputs", [])) & engineering_ids
        missing = sorted(contract_ids - declared)
        extra = sorted(declared - contract_ids)
        if missing or extra:
            raise ValueError(
                f"{route_id} Engineering Contract inputs mismatch: missing={missing}, extra={extra}"
            )
    return contract_ids


def _trace_rows(text: str) -> list[set[str]]:
    rows: list[set[str]] = []
    for line in text.splitlines():
        if not line.lstrip().startswith("|") or re.match(r"^\s*\|\s*-", line):
            continue
        ids = set(re.findall(r"`([A-Z][A-Z0-9_-]+)`", line))
        if ids:
            rows.append(ids)
    return rows


def validate_delivery(root: Path = ROOT) -> tuple[list[str], dict]:
    root = root.resolve()
    errors: list[str] = []
    paths = {
        "fr": root / "docs/product/functional_requirements.md",
        "tc": root / "docs/quality/test_cases.md",
        "trace": root / "docs/quality/traceability.md",
    }
    for name, path in paths.items():
        if not path.is_file():
            errors.append(f"missing canonical {name} document: {path.relative_to(root)}")
    if errors:
        return errors, {}

    fr_text = paths["fr"].read_text(encoding="utf-8")
    tc_text = paths["tc"].read_text(encoding="utf-8")
    trace_text = paths["trace"].read_text(encoding="utf-8")
    try:
        story_map = resolve_story_map(root)
    except (OSError, json.JSONDecodeError, KeyError, ValueError) as exc:
        errors.append(f"cannot resolve canonical STORY_MAP document: {exc}")
        story_map = None
    if story_map is None:
        approved_stories, parent_by_vs, approved_vs = set(), {}, set()
    else:
        story_source = story_map.relative_to(root).as_posix()
        approved_stories, parent_by_vs, approved_vs, story_errors = parse_story_map(
            story_map.read_text(encoding="utf-8"), story_source
        )
        errors.extend(story_errors)
    frs = _records(fr_text, "FR")
    tcs = _records(tc_text, "TC")
    try:
        engineering_contract_ids = _active_engineering_contract_ids(root)
    except (OSError, json.JSONDecodeError, KeyError, ValueError) as exc:
        errors.append(f"cannot resolve active Engineering Contract IDs: {exc}")
        engineering_contract_ids = set()

    frs_by_vs: dict[str, set[str]] = {vs: set() for vs in approved_vs}
    for fr_id, fields in frs.items():
        if fields.get("Status") != "`approved`":
            errors.append(f"{fr_id} must be approved before implementation")
        source_vs_ids = _ids(fields.get("source_vs_ids", ""), "VS")
        if not source_vs_ids:
            errors.append(f"{fr_id} must have non-empty source_vs_ids")
        if len(source_vs_ids) != len(set(source_vs_ids)):
            errors.append(f"{fr_id} repeats a source VS")
        forbidden_lineage = set(fields) & {"source_story_id", "source_story_ids", "source_capability_id", "source_increment_id", "source_stage_id"}
        if forbidden_lineage:
            errors.append(f"{fr_id} contains forbidden second-lineage fields: {sorted(forbidden_lineage)}")
        if not fields.get("Rule"):
            errors.append(f"{fr_id} has no Rule content")
        if not fields.get("primary_capability_id") or not fields.get("primary_sub_capability_id"):
            errors.append(f"{fr_id} lacks Capability/Sub-capability classification")
        for vs_id in source_vs_ids:
            if vs_id not in approved_vs:
                errors.append(f"{fr_id} references missing or unapproved VS {vs_id}")
            else:
                frs_by_vs.setdefault(vs_id, set()).add(fr_id)

    for vs_id in sorted(approved_vs):
        parent = parent_by_vs.get(vs_id)
        if not parent or parent not in approved_stories:
            errors.append(f"approved VS {vs_id} has no unique approved Story parent")

    fr_tc_by_fr: dict[str, set[str]] = {fr_id: set() for fr_id in frs}
    vs_tc_by_vs: dict[str, set[str]] = {vs_id: set() for vs_id in approved_vs}
    for tc_id, fields in tcs.items():
        tc_type = fields.get("type", "").strip("`")
        expected_key = {"FR-TC": "source_fr_id", "Contract-TC": "source_contract_id", "VS-TC": "source_vs_id"}.get(tc_type)
        if not expected_key:
            errors.append(f"{tc_id} has invalid type {tc_type!r}")
            continue
        present_sources = SOURCE_KEYS & set(fields)
        if present_sources != {expected_key}:
            errors.append(f"{tc_id} must contain only direct edge {expected_key}; found {sorted(present_sources)}")
        missing = sorted(field for field in TC_REQUIRED if not fields.get(field))
        if missing:
            errors.append(f"{tc_id} missing executable fields: {missing}")
        normalized_keys = {re.sub(r"[\s/-]+", "_", key.strip().lower()) for key in fields}
        if normalized_keys & EXECUTION_RESULT_KEYS:
            errors.append(
                f"{tc_id} stores execution-result fields: {sorted(normalized_keys & EXECUTION_RESULT_KEYS)}"
            )
        if tc_type == "FR-TC":
            refs = _ids(fields.get(expected_key, ""), "FR")
            if len(refs) != 1 or refs[0] not in frs:
                errors.append(f"{tc_id} must reference exactly one existing FR")
            else:
                fr_tc_by_fr.setdefault(refs[0], set()).add(tc_id)
        elif tc_type == "VS-TC":
            refs = _ids(fields.get(expected_key, ""), "VS")
            if len(refs) != 1 or refs[0] not in approved_vs:
                errors.append(f"{tc_id} must reference exactly one approved VS")
            else:
                vs_tc_by_vs.setdefault(refs[0], set()).add(tc_id)
            if re.search(r"source_fr_ids?|covered_fr_ids?", " ".join(fields), re.I):
                errors.append(f"{tc_id} duplicates derived FR coverage")
        else:
            refs = re.findall(r"`([A-Z][A-Z0-9_]+)`", fields.get(expected_key, ""))
            if len(refs) != 1 or refs[0] not in engineering_contract_ids:
                errors.append(
                    f"{tc_id} must reference exactly one active Engineering Contract Artifact ID"
                )

    for fr_id in sorted(frs):
        if not fr_tc_by_fr.get(fr_id):
            errors.append(f"{fr_id} has no FR-TC and no structured exception")
    for vs_id in sorted(approved_vs):
        if not vs_tc_by_vs.get(vs_id):
            errors.append(f"implementing VS {vs_id} has no user-visible VS-TC")

    if "derived-read-only" not in trace_text:
        errors.append("canonical traceability must be marked derived-read-only")
    if re.search(r"^-\s+source_(?:vs|fr|contract)_id", trace_text, re.M):
        errors.append("canonical traceability must not own direct source fields")
    expected_ids = set(approved_stories) | set(approved_vs) | set(frs) | set(tcs)
    missing_projection = sorted(item for item in expected_ids if f"`{item}`" not in trace_text)
    if missing_projection:
        errors.append(f"canonical traceability projection is missing IDs: {missing_projection}")
    trace_rows = _trace_rows(trace_text)
    for vs_id, fr_ids in frs_by_vs.items():
        story_id = parent_by_vs.get(vs_id)
        for fr_id in fr_ids:
            for tc_id in fr_tc_by_fr.get(fr_id, set()):
                required = {story_id, vs_id, fr_id, tc_id}
                if None in required or not any(required <= row for row in trace_rows):
                    errors.append(
                        f"traceability lacks co-located Story/VS/FR/FR-TC row for "
                        f"{story_id} -> {vs_id} -> {fr_id} -> {tc_id}"
                    )
        for tc_id in vs_tc_by_vs.get(vs_id, set()):
            if not any({vs_id, tc_id} <= row for row in trace_rows):
                errors.append(f"traceability lacks co-located VS/VS-TC row for {vs_id} -> {tc_id}")

    metrics = {
        "story_map_documents": int(story_map is not None),
        "approved_stories": len(approved_stories), "approved_vertical_slices": len(approved_vs),
        "functional_requirements": len(frs), "test_cases": len(tcs),
        "vertical_slices_with_frs": sum(bool(frs_by_vs.get(vs)) for vs in approved_vs),
        "fr_tc_coverage": sum(bool(fr_tc_by_fr.get(fr)) for fr in frs),
        "vs_tc_coverage": sum(bool(vs_tc_by_vs.get(vs)) for vs in approved_vs),
    }
    return errors, metrics


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    errors, metrics = validate_delivery(args.root)
    if args.json:
        print(json.dumps({"errors": errors, "metrics": metrics}, ensure_ascii=False, indent=2))
    else:
        print("Story/Slice delivery validation")
        for error in errors:
            print(f"ERROR: {error}")
        for key, value in metrics.items():
            print(f"{key}: {value}")
        print(f"Result: {'failed' if errors else 'passed'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
