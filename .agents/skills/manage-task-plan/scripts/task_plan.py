#!/usr/bin/env python3
"""Manage persistent, approval-gated PR task plans with no third-party packages."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parents[1]
TASK_TEMPLATE = SKILL_DIR / "assets" / "task-plan.template.md"
PR_TEMPLATE = SKILL_DIR / "assets" / "pr-unit.template.md"
TASKS_RELATIVE_DIR = Path(".codex") / "task-plans"
DOC_RE = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.DOTALL)
TASK_ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

TASK_STATUSES = {"draft", "awaiting_approval", "in_progress", "blocked", "completed", "cancelled"}
PR_STATUSES = {
    "proposed",
    "planned",
    "in_progress",
    "awaiting_acceptance",
    "blocked",
    "completed",
    "cancelled",
    "superseded",
}
ACTIVE_PR_STATUSES = {"in_progress", "awaiting_acceptance"}
TERMINAL_PR_STATUSES = {"completed", "cancelled", "superseded"}

TASK_HEADINGS = [
    "Goal",
    "Success Criteria",
    "Scope",
    "Constraints",
    "PR Sequence",
    "Cross-PR Dependencies",
    "Overall Verification",
    "Overall Evidence",
    "Current Summary",
    "Next Approval Required",
]
TASK_PLAN_HEADINGS = [
    "Goal",
    "Success Criteria",
    "Scope",
    "Constraints",
    "PR Sequence",
    "Cross-PR Dependencies",
    "Overall Verification",
]
PR_HEADINGS = [
    "Objective",
    "Included Scope",
    "Excluded Scope",
    "Allowed Paths",
    "Acceptance Criteria",
    "Verification Commands",
    "Governance and Review Requirements",
    "Current State",
    "Changes Made",
    "Evidence",
    "Blockers",
    "Next Action",
    "Recent Checkpoints",
]
PR_PLAN_HEADINGS = [
    "Objective",
    "Included Scope",
    "Excluded Scope",
    "Allowed Paths",
    "Acceptance Criteria",
    "Verification Commands",
    "Governance and Review Requirements",
]


class PlanError(Exception):
    pass


def now_iso() -> str:
    return datetime.now().astimezone().replace(microsecond=0).isoformat()


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug[:48] or "task"


def tasks_root(workspace: Path) -> Path:
    return workspace.resolve() / TASKS_RELATIVE_DIR


def read_doc(path: Path) -> tuple[dict[str, str], str]:
    if not path.is_file():
        raise PlanError(f"Missing document: {path}")
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
    match = DOC_RE.match(text)
    if not match:
        raise PlanError(f"Invalid frontmatter: {path}")
    metadata: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            raise PlanError(f"Invalid metadata line in {path}: {line}")
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip()
    return metadata, match.group(2)


def write_doc(path: Path, metadata: dict[str, str], body: str) -> None:
    for key, value in metadata.items():
        if "\n" in key or "\n" in value:
            raise PlanError(f"Metadata must be single-line: {key}")
    frontmatter = "\n".join(f"{key}: {value}" for key, value in metadata.items())
    content = f"---\n{frontmatter}\n---\n{body.lstrip()}"
    temp_path = path.with_suffix(path.suffix + ".tmp")
    temp_path.write_text(content, encoding="utf-8", newline="\n")
    os.replace(temp_path, path)


def section_content(body: str, heading: str) -> str | None:
    pattern = re.compile(rf"(?ms)^## {re.escape(heading)}\s*\n(.*?)(?=^## |\Z)")
    match = pattern.search(body)
    return match.group(1).strip() if match else None


def substantive(content: str | None) -> bool:
    if content is None:
        return False
    clean = re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL).strip()
    return clean.lower() not in {"", "-", "todo", "tbd", "待补充", "pending"}


def pr_paths(task_dir: Path) -> list[Path]:
    return sorted((task_dir / "prs").glob("PR-*.md")) if (task_dir / "prs").is_dir() else []


def dependency_ids(metadata: dict[str, str]) -> list[str]:
    return [item.strip() for item in metadata.get("depends_on", "").split(",") if item.strip()]


def strict_content_errors(task_dir: Path) -> list[str]:
    errors: list[str] = []
    try:
        _, task_body = read_doc(task_dir / "plan.md")
    except PlanError as exc:
        return [str(exc)]
    for heading in TASK_PLAN_HEADINGS:
        if not substantive(section_content(task_body, heading)):
            errors.append(f"plan.md section '{heading}' is incomplete")
    for path in pr_paths(task_dir):
        try:
            metadata, body = read_doc(path)
        except PlanError as exc:
            errors.append(str(exc))
            continue
        pr_id = metadata.get("pr_unit_id", path.stem)
        for heading in PR_PLAN_HEADINGS:
            if not substantive(section_content(body, heading)):
                errors.append(f"{pr_id} section '{heading}' is incomplete")
    return errors


def validate_task(task_dir: Path) -> list[str]:
    errors: list[str] = []
    try:
        task_meta, task_body = read_doc(task_dir / "plan.md")
    except PlanError as exc:
        return [str(exc)]

    for key in ("schema_version", "task_id", "title", "status", "delivery_target", "created_at", "updated_at"):
        if not task_meta.get(key):
            errors.append(f"plan.md missing metadata '{key}'")
    if task_meta.get("status") not in TASK_STATUSES:
        errors.append(f"plan.md has invalid status '{task_meta.get('status', '')}'")
    for heading in TASK_HEADINGS:
        if section_content(task_body, heading) is None:
            errors.append(f"plan.md missing section '{heading}'")

    paths = pr_paths(task_dir)
    if not paths:
        errors.append("task has no PR unit files")
        return errors

    pr_records: dict[str, tuple[dict[str, str], str]] = {}
    for path in paths:
        try:
            metadata, body = read_doc(path)
        except PlanError as exc:
            errors.append(str(exc))
            continue
        pr_id = metadata.get("pr_unit_id", "")
        if not pr_id:
            errors.append(f"{path.name} missing metadata 'pr_unit_id'")
            continue
        if pr_id in pr_records:
            errors.append(f"duplicate PR unit id '{pr_id}'")
        pr_records[pr_id] = (metadata, body)
        for key in ("schema_version", "title", "status", "revision", "updated_at"):
            if not metadata.get(key):
                errors.append(f"{pr_id} missing metadata '{key}'")
        if metadata.get("status") not in PR_STATUSES:
            errors.append(f"{pr_id} has invalid status '{metadata.get('status', '')}'")
        try:
            revision = int(metadata.get("revision", ""))
            if revision < 1:
                raise ValueError
        except ValueError:
            errors.append(f"{pr_id} revision must be a positive integer")
            revision = -1
        approved = metadata.get("approved_revision", "")
        status = metadata.get("status", "")
        if status in ACTIVE_PR_STATUSES | {"completed"} and approved != str(revision):
            errors.append(f"{pr_id} approved_revision must match revision while status is {status}")
        if status in {"proposed", "planned"} and approved:
            errors.append(f"{pr_id} must not retain approval while status is {status}")
        for heading in PR_HEADINGS:
            if section_content(body, heading) is None:
                errors.append(f"{pr_id} missing section '{heading}'")
        if status in {"awaiting_acceptance", "completed"} and not substantive(section_content(body, "Evidence")):
            errors.append(f"{pr_id} requires evidence while status is {status}")
        if status in {"in_progress", "awaiting_acceptance", "blocked"} and not substantive(
            section_content(body, "Next Action")
        ):
            errors.append(f"{pr_id} requires one concrete Next Action while status is {status}")

    active = [pr_id for pr_id, (meta, _) in pr_records.items() if meta.get("status") in ACTIVE_PR_STATUSES]
    if len(active) > 1:
        errors.append(f"single-PR execution lock violated: {', '.join(active)}")

    for pr_id, (metadata, _) in pr_records.items():
        for dependency in dependency_ids(metadata):
            if dependency not in pr_records:
                errors.append(f"{pr_id} references missing dependency '{dependency}'")
            elif metadata.get("status") in ACTIVE_PR_STATUSES | {"completed"}:
                if pr_records[dependency][0].get("status") != "completed":
                    errors.append(f"{pr_id} started before dependency '{dependency}' completed")

    task_status = task_meta.get("status")
    pr_statuses = [metadata.get("status") for metadata, _ in pr_records.values()]
    if task_status != "draft":
        errors.extend(strict_content_errors(task_dir))
    if task_status == "awaiting_approval" and any(status != "proposed" for status in pr_statuses):
        errors.append("all PR units must remain proposed while the task awaits plan approval")
    if task_status in {"in_progress", "blocked", "completed"} and any(status == "proposed" for status in pr_statuses):
        errors.append("approved tasks must not contain proposed PR units")
    if task_status == "blocked" and not any(status == "blocked" for status in pr_statuses):
        errors.append("blocked task must identify a blocked PR unit")
    if task_status == "completed":
        if any(status != "completed" for status in pr_statuses):
            errors.append("completed task requires every PR unit to be completed")
        if not substantive(section_content(task_body, "Overall Evidence")):
            errors.append("completed task requires Overall Evidence")
    return errors


def task_dirs(workspace: Path) -> list[Path]:
    root = tasks_root(workspace)
    return sorted((path.parent for path in root.glob("*/plan.md")), key=lambda path: path.name)


def resolve_task(workspace: Path, task_id: str) -> Path:
    path = tasks_root(workspace) / task_id
    if not (path / "plan.md").is_file():
        raise PlanError(f"Unknown task id: {task_id}")
    return path


def load_pr(task_dir: Path, pr_id: str) -> tuple[Path, dict[str, str], str]:
    path = task_dir / "prs" / f"{pr_id}.md"
    metadata, body = read_doc(path)
    if metadata.get("pr_unit_id") != pr_id:
        raise PlanError(f"PR id/path mismatch: {path}")
    return path, metadata, body


def git_snapshot(workspace: Path) -> tuple[str, str, int]:
    def run(*args: str) -> str:
        result = subprocess.run(
            ["git", *args], cwd=workspace, text=True, capture_output=True, check=False
        )
        return result.stdout.strip() if result.returncode == 0 else ""

    branch = run("branch", "--show-current")
    head = run("rev-parse", "HEAD")
    dirty = len([line for line in run("status", "--short").splitlines() if line.strip()])
    return branch, head, dirty


def render_template(path: Path, replacements: dict[str, str]) -> str:
    text = path.read_text(encoding="utf-8")
    for key, value in replacements.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def command_init(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    root = tasks_root(workspace)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    task_id = args.task_id or f"task-{timestamp}-{slugify(args.title)}"
    if not TASK_ID_RE.fullmatch(task_id):
        raise PlanError("task id must use lowercase kebab-case")
    task_dir = root / task_id
    if task_dir.exists():
        raise PlanError(f"Task already exists: {task_id}")
    if not args.pr:
        raise PlanError("At least one --pr title is required")

    now = now_iso()
    task_dir.joinpath("prs").mkdir(parents=True)
    sequence: list[str] = []
    for index, title in enumerate(args.pr, start=1):
        pr_id = f"PR-{index:03d}"
        sequence.append(f"- [{pr_id}](prs/{pr_id}.md) — {title.strip()}")
        content = render_template(
            PR_TEMPLATE,
            {"PR_UNIT_ID": pr_id, "TITLE": title.strip(), "NOW": now},
        )
        (task_dir / "prs" / f"{pr_id}.md").write_text(content, encoding="utf-8", newline="\n")
    plan = render_template(
        TASK_TEMPLATE,
        {
            "TASK_ID": task_id,
            "TITLE": args.title.strip(),
            "DELIVERY_TARGET": args.delivery_target,
            "NOW": now,
            "PR_SEQUENCE": "\n".join(sequence),
        },
    )
    (task_dir / "plan.md").write_text(plan, encoding="utf-8", newline="\n")
    print(f"Created task {task_id}")
    print(task_dir)
    return 0


def command_list(args: argparse.Namespace) -> int:
    print("TASK_ID\tSTATUS\tUPDATED_AT\tTITLE")
    for task_dir in task_dirs(Path(args.workspace)):
        metadata, _ = read_doc(task_dir / "plan.md")
        print(
            f"{metadata.get('task_id', task_dir.name)}\t{metadata.get('status', '')}\t"
            f"{metadata.get('updated_at', '')}\t{metadata.get('title', '')}"
        )
    return 0


def command_validate(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    targets = [resolve_task(workspace, args.task_id)] if args.task_id else task_dirs(workspace)
    if not targets:
        raise PlanError("No task plans found")
    failed = False
    for task_dir in targets:
        errors = validate_task(task_dir)
        if errors:
            failed = True
            print(f"{task_dir.name}: INVALID")
            for error in errors:
                print(f"- {error}")
        else:
            print(f"{task_dir.name}: valid")
    return 1 if failed else 0


def command_approve_plan(args: argparse.Namespace) -> int:
    task_dir = resolve_task(Path(args.workspace), args.task_id)
    task_path = task_dir / "plan.md"
    task_meta, task_body = read_doc(task_path)
    if task_meta.get("status") != "awaiting_approval":
        raise PlanError("Task must be awaiting_approval before plan approval")
    errors = validate_task(task_dir)
    if errors:
        raise PlanError("Plan is not approvable:\n- " + "\n- ".join(errors))
    records = [load_pr(task_dir, path.stem) for path in pr_paths(task_dir)]
    if any(metadata.get("status") != "proposed" for _, metadata, _ in records):
        raise PlanError("All PR units must be proposed before plan approval")
    now = now_iso()
    for path, metadata, body in records:
        metadata["status"] = "planned"
        metadata["updated_at"] = now
        write_doc(path, metadata, body)
    task_meta["status"] = "in_progress"
    task_meta["updated_at"] = now
    write_doc(task_path, task_meta, task_body)
    print(f"Approved task plan {args.task_id}; PR units are planned and still require individual approval")
    return 0


def command_approve_pr(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    task_dir = resolve_task(workspace, args.task_id)
    task_path = task_dir / "plan.md"
    task_meta, task_body = read_doc(task_path)
    if task_meta.get("status") not in {"in_progress", "blocked"}:
        raise PlanError("Task must be in_progress or blocked before PR approval")
    errors = validate_task(task_dir)
    if errors:
        raise PlanError("Task is invalid:\n- " + "\n- ".join(errors))
    path, metadata, body = load_pr(task_dir, args.pr_id)
    if metadata.get("status") not in {"planned", "blocked"}:
        raise PlanError("PR must be planned or blocked before approval")
    active = []
    for candidate in pr_paths(task_dir):
        candidate_meta, _ = read_doc(candidate)
        if candidate_meta.get("status") in ACTIVE_PR_STATUSES:
            active.append(candidate_meta.get("pr_unit_id", candidate.stem))
    if active:
        raise PlanError(f"Another PR is active: {', '.join(active)}")
    for dependency in dependency_ids(metadata):
        _, dependency_meta, _ = load_pr(task_dir, dependency)
        if dependency_meta.get("status") != "completed":
            raise PlanError(f"Dependency {dependency} is not completed")
    now = now_iso()
    branch, head, _ = git_snapshot(workspace)
    metadata["status"] = "in_progress"
    metadata["approved_revision"] = metadata["revision"]
    metadata["approved_at"] = now
    metadata["updated_at"] = now
    metadata["branch"] = branch
    metadata["head"] = head
    write_doc(path, metadata, body)
    if task_meta.get("status") == "blocked":
        task_meta["status"] = "in_progress"
        task_meta["updated_at"] = now
        write_doc(task_path, task_meta, task_body)
    print(f"Approved {args.pr_id} revision {metadata['revision']} for execution")
    return 0


TASK_TRANSITIONS = {
    "draft": {"awaiting_approval", "cancelled"},
    "awaiting_approval": {"cancelled"},
    "in_progress": {"blocked", "completed", "cancelled"},
    "blocked": {"in_progress", "cancelled"},
    "completed": set(),
    "cancelled": set(),
}
PR_TRANSITIONS = {
    "proposed": {"cancelled", "superseded"},
    "planned": {"cancelled", "superseded"},
    "in_progress": {"awaiting_acceptance", "blocked", "cancelled"},
    "awaiting_acceptance": {"completed", "in_progress", "cancelled"},
    "blocked": {"cancelled", "superseded"},
    "completed": set(),
    "cancelled": set(),
    "superseded": set(),
}


def command_transition(args: argparse.Namespace) -> int:
    task_dir = resolve_task(Path(args.workspace), args.task_id)
    task_path = task_dir / "plan.md"
    task_meta, task_body = read_doc(task_path)
    now = now_iso()
    if args.target == "task":
        current = task_meta.get("status", "")
        if args.to not in TASK_TRANSITIONS.get(current, set()):
            raise PlanError(f"Illegal task transition: {current} -> {args.to}")
        if args.to == "awaiting_approval":
            structural_errors = validate_task(task_dir)
            if structural_errors:
                raise PlanError("Task is invalid:\n- " + "\n- ".join(structural_errors))
            errors = strict_content_errors(task_dir)
            if errors:
                raise PlanError("Plan is incomplete:\n- " + "\n- ".join(errors))
        if args.to == "blocked":
            records = [read_doc(path)[0] for path in pr_paths(task_dir)]
            if not any(record.get("status") == "blocked" for record in records):
                raise PlanError("Block a concrete PR unit before blocking the task")
        if args.to == "completed":
            records = [read_doc(path)[0] for path in pr_paths(task_dir)]
            if any(record.get("status") != "completed" for record in records):
                raise PlanError("Every PR unit must be completed first")
            if not substantive(section_content(task_body, "Overall Evidence")):
                raise PlanError("Overall Evidence is required before task completion")
        task_meta["status"] = args.to
        task_meta["updated_at"] = now
        write_doc(task_path, task_meta, task_body)
        print(f"Task {args.task_id}: {current} -> {args.to}")
        return 0

    path, metadata, body = load_pr(task_dir, args.target)
    current = metadata.get("status", "")
    if args.to not in PR_TRANSITIONS.get(current, set()):
        hint = "; use approve-pr for planned/blocked -> in_progress" if args.to == "in_progress" else ""
        raise PlanError(f"Illegal PR transition: {current} -> {args.to}{hint}")
    if args.to in {"awaiting_acceptance", "completed"}:
        if metadata.get("approved_revision") != metadata.get("revision"):
            raise PlanError("approved_revision must match revision")
        if not substantive(section_content(body, "Evidence")):
            raise PlanError("Evidence is required for acceptance or completion")
    if args.to == "awaiting_acceptance" and not substantive(section_content(body, "Next Action")):
        raise PlanError("Next Action is required before awaiting acceptance")
    metadata["status"] = args.to
    metadata["updated_at"] = now
    write_doc(path, metadata, body)
    if args.to == "blocked":
        task_meta["status"] = "blocked"
    elif current == "awaiting_acceptance" and args.to == "in_progress":
        task_meta["status"] = "in_progress"
    task_meta["updated_at"] = now
    write_doc(task_path, task_meta, task_body)
    print(f"{args.target}: {current} -> {args.to}")
    return 0


def command_revise_pr(args: argparse.Namespace) -> int:
    task_dir = resolve_task(Path(args.workspace), args.task_id)
    task_path = task_dir / "plan.md"
    task_meta, task_body = read_doc(task_path)
    path, metadata, body = load_pr(task_dir, args.pr_id)
    if metadata.get("status") in TERMINAL_PR_STATUSES:
        raise PlanError("Terminal PR units cannot be revised")
    metadata["revision"] = str(int(metadata["revision"]) + 1)
    metadata["approved_revision"] = ""
    metadata["approved_at"] = ""
    metadata["status"] = "proposed" if task_meta.get("status") in {"draft", "awaiting_approval"} else "planned"
    metadata["updated_at"] = now_iso()
    write_doc(path, metadata, body)
    if task_meta.get("status") == "blocked":
        task_meta["status"] = "in_progress"
        task_meta["updated_at"] = metadata["updated_at"]
        write_doc(task_path, task_meta, task_body)
    print(f"Revised {args.pr_id} to revision {metadata['revision']}; approval cleared")
    return 0


def command_checkpoint(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    task_dir = resolve_task(workspace, args.task_id)
    path, metadata, body = load_pr(task_dir, args.pr_id)
    if metadata.get("status") not in {"in_progress", "awaiting_acceptance", "blocked"}:
        raise PlanError("Checkpoint requires an active, acceptance, or blocked PR")
    branch, head, _ = git_snapshot(workspace)
    metadata["branch"] = branch
    metadata["head"] = head
    metadata["updated_at"] = now_iso()
    write_doc(path, metadata, body)
    errors = validate_task(task_dir)
    if errors:
        raise PlanError("Checkpoint saved but task is invalid:\n- " + "\n- ".join(errors))
    print(f"Checkpointed {args.pr_id} at {branch or '(no branch)'} {head[:12] if head else '(no HEAD)'}")
    return 0


def summarize(task_dir: Path, workspace: Path, include_git: bool) -> list[str]:
    task_meta, task_body = read_doc(task_dir / "plan.md")
    records = [read_doc(path) for path in pr_paths(task_dir)]
    active = [(meta, body) for meta, body in records if meta.get("status") in ACTIVE_PR_STATUSES]
    blocked = [(meta, body) for meta, body in records if meta.get("status") == "blocked"]
    planned = [(meta, body) for meta, body in records if meta.get("status") in {"planned", "proposed"}]
    current = active[0] if active else (blocked[0] if blocked else (planned[0] if planned else None))
    goal = section_content(task_body, "Goal") or ""
    lines = [
        f"Task: {task_meta.get('task_id')} — {task_meta.get('title')}",
        f"Task status: {task_meta.get('status')}",
        f"Goal: {re.sub(r'<!--.*?-->', '', goal, flags=re.DOTALL).strip() or '(not recorded)'}",
    ]
    if current:
        metadata, body = current
        lines.extend(
            [
                f"Current/next PR: {metadata.get('pr_unit_id')} — {metadata.get('title')}",
                f"PR status: {metadata.get('status')}",
                f"Revision: {metadata.get('revision')} (approved: {metadata.get('approved_revision') or 'none'})",
                f"Next action: {section_content(body, 'Next Action') or '(not recorded)'}",
            ]
        )
    if task_meta.get("status") in {"completed", "cancelled"}:
        gate = "NONE"
    elif task_meta.get("status") == "awaiting_approval":
        gate = "PLAN_APPROVAL"
    elif current and current[0].get("status") == "planned":
        gate = "PR_APPROVAL"
    elif current and current[0].get("status") == "awaiting_acceptance":
        gate = "PR_ACCEPTANCE"
    elif current and current[0].get("status") == "blocked":
        gate = "BLOCKER_RESOLUTION_AND_PR_APPROVAL"
    elif current and current[0].get("status") == "in_progress":
        gate = "NONE_WITHIN_APPROVED_REVISION"
    elif records and all(meta.get("status") == "completed" for meta, _ in records):
        gate = "TASK_ACCEPTANCE"
    else:
        gate = "PLAN_DEVELOPMENT" if task_meta.get("status") == "draft" else "NONE"
    lines.append(f"Approval gate: {gate}")
    if include_git:
        branch, head, dirty = git_snapshot(workspace)
        lines.append(f"Repository: branch={branch or '(none)'} head={head[:12] if head else '(none)'} dirty={dirty}")
        if current:
            expected_branch = current[0].get("branch", "")
            expected_head = current[0].get("head", "")
            if expected_branch and branch != expected_branch:
                lines.append(f"DRIFT: expected branch {expected_branch}, found {branch or '(none)'}")
            if expected_head and head != expected_head:
                lines.append(f"DRIFT: expected HEAD {expected_head[:12]}, found {head[:12] if head else '(none)'}")
    return lines


def command_show(args: argparse.Namespace) -> int:
    task_dir = resolve_task(Path(args.workspace), args.task_id)
    print("\n".join(summarize(task_dir, Path(args.workspace), include_git=False)))
    return 0


def command_resume(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    if args.task_id:
        task_dir = resolve_task(workspace, args.task_id)
    else:
        candidates = []
        for candidate in task_dirs(workspace):
            metadata, _ = read_doc(candidate / "plan.md")
            if metadata.get("status") not in {"completed", "cancelled"}:
                candidates.append(candidate)
        if len(candidates) != 1:
            ids = ", ".join(path.name for path in candidates) or "none"
            raise PlanError(f"Resume without task id requires exactly one active task; found: {ids}")
        task_dir = candidates[0]
    errors = validate_task(task_dir)
    if errors:
        raise PlanError("Task cannot resume until repaired:\n- " + "\n- ".join(errors))
    print("\n".join(summarize(task_dir, workspace, include_git=True)))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default=".", help="Repository/workspace root (default: current directory)")
    commands = parser.add_subparsers(dest="command", required=True)

    init = commands.add_parser("init", help="Create a draft task and PR cards")
    init.add_argument("--title", required=True)
    init.add_argument("--task-id")
    init.add_argument("--delivery-target", choices=("local", "committed", "opened", "merged"), default="local")
    init.add_argument("--pr", action="append", required=True, help="PR unit title; repeat for each unit")
    init.set_defaults(func=command_init)

    list_cmd = commands.add_parser("list", help="List task plans")
    list_cmd.set_defaults(func=command_list)

    validate = commands.add_parser("validate", help="Validate one task or every task")
    validate.add_argument("task_id", nargs="?")
    validate.set_defaults(func=command_validate)

    show = commands.add_parser("show", help="Show a compact task summary")
    show.add_argument("task_id")
    show.set_defaults(func=command_show)

    approve_plan = commands.add_parser("approve-plan", help="Persist explicit user approval of the task plan")
    approve_plan.add_argument("task_id")
    approve_plan.set_defaults(func=command_approve_plan)

    approve_pr = commands.add_parser("approve-pr", help="Persist explicit user approval of one PR revision")
    approve_pr.add_argument("task_id")
    approve_pr.add_argument("pr_id")
    approve_pr.set_defaults(func=command_approve_pr)

    transition = commands.add_parser("transition", help="Apply a legal task or PR state transition")
    transition.add_argument("task_id")
    transition.add_argument("--target", required=True, help="task or PR-NNN")
    transition.add_argument("--to", required=True)
    transition.set_defaults(func=command_transition)

    revise = commands.add_parser("revise-pr", help="Increment a PR revision and clear approval")
    revise.add_argument("task_id")
    revise.add_argument("pr_id")
    revise.set_defaults(func=command_revise_pr)

    checkpoint = commands.add_parser("checkpoint", help="Refresh repository snapshot for the current PR")
    checkpoint.add_argument("task_id")
    checkpoint.add_argument("pr_id")
    checkpoint.set_defaults(func=command_checkpoint)

    resume = commands.add_parser("resume", help="Validate and print cross-session recovery context")
    resume.add_argument("task_id", nargs="?")
    resume.set_defaults(func=command_resume)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except (PlanError, OSError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
