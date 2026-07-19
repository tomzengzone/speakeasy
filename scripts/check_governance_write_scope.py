#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Sequence


def path_pattern(template: str) -> re.Pattern[str]:
    escaped = re.escape(template).replace(r"\{", "{").replace(r"\}", "}")
    escaped = re.sub(r"\{[^{}]+\}", r"[^/]+", escaped)
    return re.compile(rf"^{escaped}$")


def load_artifacts(root: Path) -> list[dict]:
    contract_root = root / "docs/process/governance"
    index = json.loads((contract_root / "index.json").read_text(encoding="utf-8"))
    artifacts: list[dict] = []
    for shard in sorted(set(index["artifact_routes"].values())):
        data = json.loads((contract_root / shard).read_text(encoding="utf-8"))
        artifacts.extend({**data["defaults"], **item} for item in data["artifacts"])
    return artifacts


GOVERNED_PREFIXES = (
    "AGENTS.md", ".codex/config.toml", ".codex/agents/", ".agents/skills/", "docs/process/", ".github/workflows/",
    "scripts/validate_agent_skills.py", "scripts/check_document_language.py",
    "scripts/validate_governance_contracts.py", "scripts/check_governance_write_scope.py",
    "tests/test_validate_governance_contracts.py",
)


METADATA_PATTERN = re.compile(r"^Governance-(Actor|Scope):\s*(\S.*?)\s*$", re.MULTILINE | re.IGNORECASE)
HEADING_PATTERN = re.compile(r"^(#{1,6})\s+(.+?)\s*$")


def parse_governance_metadata(text: str) -> tuple[list[str], list[str]]:
    actors: list[str] = []
    scopes: list[str] = []
    for kind, value in METADATA_PATTERN.findall(text or ""):
        if kind.lower() == "actor":
            actors.append(value.strip())
        else:
            scopes.append(value.strip())
    actors = list(dict.fromkeys(actors))
    if not actors:
        raise ValueError("at least one Governance-Actor trailer is required")
    return actors, list(dict.fromkeys(scopes))


def load_event_metadata(path: Path) -> tuple[list[str], list[str]]:
    event = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(event.get("pull_request"), dict):
        pull_request = event["pull_request"]
        text = f"{pull_request.get('title') or ''}\n{pull_request.get('body') or ''}"
    else:
        text = (event.get("head_commit") or {}).get("message") or ""
    return parse_governance_metadata(text)


def _scope_refs(value: str | Sequence[str] | None) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    return list(value)


def _is_governed_path(path: str) -> bool:
    return path.replace("\\", "/").removeprefix("./").startswith(GOVERNED_PREFIXES)


def _normalize_markdown_sections(text: str, headings: set[str]) -> str:
    result: list[str] = []
    hidden_level: int | None = None
    for line in text.splitlines(keepends=True):
        match = HEADING_PATTERN.match(line.rstrip("\r\n"))
        if match:
            level = len(match.group(1))
            if hidden_level is not None and level > hidden_level:
                continue
            hidden_level = None
            if match.group(2).strip() in headings:
                hidden_level = level
                result.append(line)
                result.append("<governance-scope-content>\n")
            else:
                result.append(line)
        elif hidden_level is None:
            result.append(line)
    return "".join(result)


def _table_cells(line: str) -> list[str]:
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        return []
    return [cell.strip() for cell in stripped[1:-1].split("|")]


def _is_table_separator(line: str, width: int) -> bool:
    cells = _table_cells(line)
    return len(cells) == width and all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells)


def _normalize_markdown_tables(text: str, scope: dict) -> str:
    append_headings = set(scope.get("append_headings", []))
    if append_headings:
        text = _normalize_markdown_sections(text, append_headings)
    lines = text.splitlines(keepends=True)
    allowed_columns = set(scope.get("columns", []))
    target_heading = scope.get("table_heading")
    result: list[str] = []
    current_heading: str | None = None
    index = 0
    while index < len(lines):
        heading = HEADING_PATTERN.match(lines[index].rstrip("\r\n"))
        if heading:
            current_heading = heading.group(2).strip()
        headers = _table_cells(lines[index])
        if (
            headers
            and index + 1 < len(lines)
            and _is_table_separator(lines[index + 1], len(headers))
            and (target_heading is None or current_heading == target_heading)
        ):
            result.extend(lines[index:index + 2])
            allowed_indexes = {position for position, name in enumerate(headers) if name in allowed_columns}
            index += 2
            while index < len(lines):
                cells = _table_cells(lines[index])
                if len(cells) != len(headers):
                    break
                for position in allowed_indexes:
                    cells[position] = "<governance-scope-cell>"
                newline = "\r\n" if lines[index].endswith("\r\n") else "\n"
                result.append("| " + " | ".join(cells) + " |" + newline)
                index += 1
            continue
        result.append(lines[index])
        index += 1
    return "".join(result)


def _normalize_yaml_steps(text: str, job_id: str, allowed_step_ids: set[str]) -> str:
    lines = text.splitlines(keepends=True)
    job_start = None
    job_end = len(lines)
    job_indent = 0
    for index, line in enumerate(lines):
        match = re.match(r"^(\s*)([A-Za-z0-9_-]+):\s*(?:#.*)?$", line.rstrip("\r\n"))
        if match and match.group(2) == job_id:
            job_start = index
            job_indent = len(match.group(1))
            break
    if job_start is None:
        return text
    for index in range(job_start + 1, len(lines)):
        stripped = lines[index].strip()
        indent = len(lines[index]) - len(lines[index].lstrip())
        if stripped and indent <= job_indent:
            job_end = index
            break

    remove: set[int] = set()
    for index in range(job_start + 1, job_end):
        match = re.match(r"^(\s*)id:\s*([A-Za-z0-9_-]+)\s*(?:#.*)?$", lines[index].rstrip("\r\n"))
        if not match or match.group(2) not in allowed_step_ids:
            continue
        id_indent = len(match.group(1))
        step_start = index
        while step_start > job_start:
            candidate = lines[step_start]
            indent = len(candidate) - len(candidate.lstrip())
            if indent < id_indent and candidate.lstrip().startswith("- "):
                break
            step_start -= 1
        step_indent = len(lines[step_start]) - len(lines[step_start].lstrip())
        step_end = job_end
        for candidate_index in range(step_start + 1, job_end):
            candidate = lines[candidate_index]
            indent = len(candidate) - len(candidate.lstrip())
            if indent == step_indent and candidate.lstrip().startswith("- "):
                step_end = candidate_index
                break
        remove.update(range(step_start, step_end))
    return "".join(line for index, line in enumerate(lines) if index not in remove)


def validate_content_scope(before: str, after: str, scope: dict) -> list[str]:
    scope_type = scope.get("type")
    if scope_type == "json-document":
        return []
    if scope_type == "markdown-sections":
        normalized_before = _normalize_markdown_sections(before, set(scope.get("headings", [])))
        normalized_after = _normalize_markdown_sections(after, set(scope.get("headings", [])))
    elif scope_type == "markdown-table-columns":
        normalized_before = _normalize_markdown_tables(before, scope)
        normalized_after = _normalize_markdown_tables(after, scope)
    elif scope_type == "append-record":
        if not after.startswith(before):
            return ["append-record scope changed or removed existing content"]
        addition = after[len(before):]
        level = int(scope.get("heading_level", 0))
        heading = re.compile(rf"^{'#' * level}\s+.+$", re.MULTILINE)
        matches = list(heading.finditer(addition))
        if not matches or addition[:matches[0].start()].strip():
            return ["append-record scope requires newly appended records at the declared heading level"]
        actor_field = scope.get("actor_field")
        for position, match in enumerate(matches):
            end = matches[position + 1].start() if position + 1 < len(matches) else len(addition)
            if actor_field and actor_field not in addition[match.start():end]:
                return [f"append-record is missing actor marker: {actor_field}"]
        return []
    elif scope_type == "yaml-step-ids":
        normalized_before = _normalize_yaml_steps(before, scope.get("job_id", ""), set(scope.get("step_ids", [])))
        normalized_after = _normalize_yaml_steps(after, scope.get("job_id", ""), set(scope.get("step_ids", [])))
    else:
        return [f"unsupported mutable scope type: {scope_type}"]
    return [] if normalized_before == normalized_after else [f"change exceeds declared {scope_type} scope"]


def _git_content(root: Path, base_ref: str, path: str) -> str:
    result = subprocess.run(
        ["git", "show", f"{base_ref}:{path}"],
        cwd=root,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    return result.stdout if result.returncode == 0 else ""


def check_paths(root: Path, paths: list[str], actor: str | None, scope_ref: str | Sequence[str] | None = None, governed_only: bool = False) -> list[str]:
    artifacts = load_artifacts(root)
    scope_refs = _scope_refs(scope_ref)
    errors: list[str] = []
    for raw in paths:
        path = raw.replace("\\", "/")
        if path.startswith("./"):
            path = path[2:]
        if governed_only and not path.startswith(GOVERNED_PREFIXES):
            continue
        matches = [item for item in artifacts if path_pattern(item["canonical_path"]).match(path)]
        if not matches:
            if not (root / path).exists():
                continue
            errors.append(f"unregistered governed path: {path}")
            continue
        if actor:
            owners = [item for item in matches if actor == item["accountable_owner"]]
            contributor_items = [item for item in matches if actor in item["contributors"]]
            if not owners and not contributor_items:
                errors.append(f"actor {actor} cannot write {path}; matched {[item['artifact_id'] for item in matches]}")
            elif not owners and not scope_refs:
                errors.append(f"actor {actor} must provide --scope-ref or Governance-Scope trailer for contributor write {path}")
            elif not owners and not any(
                ref in json.dumps(item["mutable_fields"].get(actor), ensure_ascii=False)
                for item in contributor_items for ref in scope_refs
            ):
                errors.append(f"scope-ref {scope_refs} does not match contributor scope for {path}")
    return errors


def check_changes(
    root: Path,
    paths: list[str],
    actor: str,
    scope_refs: Sequence[str],
    base_ref: str,
    governed_only: bool = False,
) -> list[str]:
    errors = check_paths(root, paths, actor, scope_refs, governed_only)
    if errors:
        return errors
    artifacts = load_artifacts(root)
    for raw in paths:
        path = raw.replace("\\", "/").removeprefix("./")
        if governed_only and not path.startswith(GOVERNED_PREFIXES):
            continue
        matches = [item for item in artifacts if path_pattern(item["canonical_path"]).match(path)]
        if any(actor == item["accountable_owner"] for item in matches):
            continue
        before = _git_content(root, base_ref, path)
        target = root / path
        after = target.read_text(encoding="utf-8") if target.exists() else ""
        contributor_scopes = [item["mutable_fields"][actor] for item in matches if actor in item["contributors"]]
        scope_errors = [validate_content_scope(before, after, scope) for scope in contributor_scopes]
        if scope_errors and all(result for result in scope_errors):
            errors.append(f"actor {actor} exceeded contributor scope for {path}: {'; '.join(scope_errors[0])}")
    return errors


def check_authorized_changes(
    root: Path,
    paths: list[str],
    actors: Sequence[str],
    scope_refs: Sequence[str],
    base_ref: str,
    governed_only: bool = False,
) -> list[str]:
    errors: list[str] = []
    for path in paths:
        if governed_only and not _is_governed_path(path):
            continue
        attempts = [check_changes(root, [path], actor, scope_refs, base_ref, governed_only) for actor in actors]
        if attempts and all(attempt for attempt in attempts):
            reasons = " | ".join(f"{actor}: {'; '.join(attempt)}" for actor, attempt in zip(actors, attempts))
            errors.append(f"no declared actor is authorized for {path}: {reasons}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Check changed paths against Artifact owner/contributor contracts.")
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--actor", action="append", default=[])
    parser.add_argument("--scope-ref", action="append", default=[])
    parser.add_argument("--github-event-path", type=Path)
    parser.add_argument("--base-ref")
    parser.add_argument("--governed-only", action="store_true")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    if args.governed_only and not any(_is_governed_path(path) for path in args.paths):
        print("Governance write-scope result: passed (no governed paths changed)")
        return 0
    actors = list(args.actor)
    scope_refs = list(args.scope_ref)
    if args.github_event_path:
        try:
            event_actors, event_scopes = load_event_metadata(args.github_event_path)
        except (OSError, json.JSONDecodeError, ValueError) as exc:
            print(f"ERROR: invalid governance metadata: {exc}")
            return 1
        actors.extend(event_actors)
        scope_refs.extend(event_scopes)
    actors = list(dict.fromkeys(actors))
    scope_refs = list(dict.fromkeys(scope_refs))
    if not actors:
        print("ERROR: add Governance-Actor: <actor-id> to the PR body/commit message, or pass --actor")
        return 1
    if args.base_ref:
        errors = check_authorized_changes(args.root.resolve(), args.paths, actors, scope_refs, args.base_ref, args.governed_only)
    else:
        errors = []
        for path in args.paths:
            attempts = [check_paths(args.root.resolve(), [path], actor, scope_refs, args.governed_only) for actor in actors]
            if attempts and all(attempt for attempt in attempts):
                errors.append(f"no declared actor is authorized for {path}")
    for error in errors:
        print(f"ERROR: {error}")
    print(f"Governance write-scope result: {'failed' if errors else 'passed'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
