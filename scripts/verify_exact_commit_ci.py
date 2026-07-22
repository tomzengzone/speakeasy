#!/usr/bin/env python3
"""Verify and attest an exact-commit CI run without mutating Git refs."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Optional, Sequence
from urllib.parse import urlsplit, urlunsplit

try:
    from scripts.validate_story_slice_cutover import (
        authority_graph_digest as _candidate_authority_graph_digest,
    )
except ModuleNotFoundError as exc:  # Direct `python scripts/...` execution.
    if exc.name != "scripts":
        raise
    from validate_story_slice_cutover import (  # type: ignore[no-redef]
        authority_graph_digest as _candidate_authority_graph_digest,
    )


BASELINE_REF = "refs/heads/speakeasy-20260705"
CANDIDATE_REF = "refs/heads/pr-003-candidate"
CONTROLLER_FILES = (Path(".github/workflows/ci.yml"), Path("scripts/verify_exact_commit_ci.py"))
AUTHORITY_INDEX = Path("docs/process/governance/index.json")
CHECKPOINTS = ("start", "after-governance", "after-application")
PASS_RESULTS = {"pass", "passed", "success", "successful"}
SHA_PATTERN = re.compile(r"[0-9a-f]{40}(?:[0-9a-f]{24})?")
NAME_PATTERN = re.compile(r"[a-z0-9][a-z0-9._-]*")


class VerificationError(RuntimeError):
    """Raised when an exact-commit invariant does not hold."""


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _git(root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode:
        detail = result.stderr.strip() or result.stdout.strip() or f"exit {result.returncode}"
        raise VerificationError(f"git {' '.join(args)} failed: {detail}")
    return result


def _require_sha(value: str, label: str) -> str:
    normalized = value.strip().lower()
    if SHA_PATTERN.fullmatch(normalized) is None:
        raise VerificationError(f"{label} must be a full lowercase Git object ID")
    return normalized


def _resolve_commit(root: Path, value: str, label: str) -> str:
    expected = _require_sha(value, label)
    actual = _git(root, "rev-parse", "--verify", f"{expected}^{{commit}}").stdout.strip().lower()
    if actual != expected:
        raise VerificationError(f"{label} does not resolve to the declared exact commit")
    return expected


def _head(root: Path) -> str:
    return _git(root, "rev-parse", "HEAD").stdout.strip().lower()


def _validate_branch(root: Path, branch: str) -> str:
    normalized = branch.strip()
    if not normalized or normalized.startswith("refs/"):
        raise VerificationError("candidate branch must be a branch name without refs/heads/")
    result = _git(root, "check-ref-format", f"refs/heads/{normalized}", check=False)
    if result.returncode:
        raise VerificationError("candidate branch is not a valid Git branch name")
    if f"refs/heads/{normalized}" == BASELINE_REF:
        raise VerificationError("candidate branch must be separate from the protected baseline branch")
    return normalized


def _remote_ref(root: Path, remote: str, ref: str) -> str:
    result = _git(root, "ls-remote", "--refs", remote, ref, check=False)
    if result.returncode:
        raise VerificationError(f"cannot read {ref} from remote {remote}")
    rows = [line.split() for line in result.stdout.splitlines() if line.strip()]
    matches = [row[0].lower() for row in rows if len(row) == 2 and row[1] == ref]
    if len(matches) != 1:
        raise VerificationError(f"remote {remote} must expose exactly one {ref}")
    return _require_sha(matches[0], f"remote ref {ref}")


def _sanitize_remote_url(value: str) -> str:
    value = value.strip()
    if "://" in value:
        parts = urlsplit(value)
        hostname = parts.hostname or ""
        if parts.port is not None:
            hostname = f"{hostname}:{parts.port}"
        return urlunsplit((parts.scheme, hostname, parts.path, "", ""))
    if "@" in value and ":" in value.split("@", 1)[1]:
        return value.split("@", 1)[1]
    return value


def _remote_identity(root: Path, remote: str) -> dict[str, str]:
    if not remote.strip() or remote.startswith("-"):
        raise VerificationError("remote name is invalid")
    url = _git(root, "remote", "get-url", remote).stdout.strip()
    if not url:
        raise VerificationError(f"remote {remote} has no URL")
    return {"name": remote, "url": _sanitize_remote_url(url)}


def authority_graph_digest(root: Path) -> str:
    """Use the cutover validator's canonical candidate-graph derivation."""
    try:
        return _candidate_authority_graph_digest(root.resolve())
    except (OSError, ValueError, KeyError, TypeError) as exc:
        raise VerificationError(f"cannot derive candidate authority graph: {exc}") from exc


def _file_digests(root: Path) -> dict[str, str]:
    digests: dict[str, str] = {}
    for relative in CONTROLLER_FILES:
        try:
            content = (root / relative).read_bytes()
        except OSError as exc:
            raise VerificationError(f"cannot read controller file {relative.as_posix()}: {exc}") from exc
        digests[relative.as_posix()] = hashlib.sha256(content).hexdigest()
    return digests


def _assert_clean(root: Path) -> None:
    unstaged = _git(root, "diff", "--quiet", check=False)
    staged = _git(root, "diff", "--cached", "--quiet", check=False)
    if unstaged.returncode not in (0, 1) or staged.returncode not in (0, 1):
        raise VerificationError("cannot determine tracked worktree state")
    if unstaged.returncode or staged.returncode:
        raise VerificationError("tracked checkout content drifted from the candidate commit")


def _assert_snapshot(root: Path, state: dict[str, Any]) -> tuple[str, str]:
    candidate_sha = state["candidate"]["sha"]
    head = _head(root)
    if head != candidate_sha:
        raise VerificationError(f"checkout HEAD drift: expected {candidate_sha}, found {head}")
    digest = authority_graph_digest(root)
    expected_digest = state["authority_graph"]["digest"]
    if digest != expected_digest:
        raise VerificationError(
            f"authority graph digest drift: expected {expected_digest}, found {digest}"
        )
    if _file_digests(root) != state["controller"]["file_digests"]:
        raise VerificationError("candidate workflow/verifier digest drift")
    _assert_clean(root)
    return head, digest


def _assert_remote_binding(root: Path, state: dict[str, Any], activated: bool = False) -> None:
    candidate = state["candidate"]
    baseline = state["baseline"]
    remote = candidate["remote"]["name"]
    current_identity = _remote_identity(root, remote)
    if current_identity != candidate["remote"]:
        raise VerificationError("candidate remote identity drifted from the attested remote")
    branch_sha = _remote_ref(root, remote, f"refs/heads/{candidate['branch']}")
    if branch_sha != candidate["sha"]:
        raise VerificationError(
            f"candidate branch HEAD drift: expected {candidate['sha']}, found {branch_sha}"
        )
    baseline_sha = _remote_ref(root, remote, BASELINE_REF)
    expected_baseline = candidate["sha"] if activated else baseline["base_sha"]
    if baseline_sha != expected_baseline:
        label = "activated baseline" if activated else "protected baseline"
        raise VerificationError(
            f"{label} drift: expected {expected_baseline}, found {baseline_sha}"
        )


def _load_json(path: Path, label: str) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise VerificationError(f"cannot load {label}: {exc}") from exc
    if not isinstance(data, dict):
        raise VerificationError(f"{label} must be a JSON object")
    return data


def _write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(handle, "w", encoding="utf-8") as stream:
            json.dump(data, stream, indent=2, sort_keys=True)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def _parse_required_checks(values: Iterable[str]) -> list[str]:
    checks: list[str] = []
    for value in values:
        name = value.strip()
        if NAME_PATTERN.fullmatch(name) is None:
            raise VerificationError(f"invalid required check name: {value}")
        if name in checks:
            raise VerificationError(f"duplicate required check: {name}")
        checks.append(name)
    if not checks:
        raise VerificationError("at least one required check must be declared")
    return checks


def _parse_check_results(values: Iterable[str]) -> dict[str, str]:
    results: dict[str, str] = {}
    for value in values:
        name, separator, result = value.partition("=")
        name = name.strip()
        result = result.strip().lower()
        if not separator or NAME_PATTERN.fullmatch(name) is None or not result:
            raise VerificationError(f"check result must use <name>=<result>: {value}")
        if name in results:
            raise VerificationError(f"duplicate check result: {name}")
        results[name] = result
    return results


def start_verification(
    root: Path,
    controller_root: Path,
    controller_sha: str,
    state_file: Path,
    candidate_sha: str,
    base_sha: str,
    candidate_branch: str,
    remote: str,
    event_name: str,
    repository: str,
    workflow_name: str,
    workflow_run_id: str,
    workflow_run_attempt: str,
    required_checks: Sequence[str],
) -> dict[str, Any]:
    root = root.resolve()
    controller_root = controller_root.resolve()
    if event_name != "workflow_dispatch":
        raise VerificationError("exact-commit candidate CI requires workflow_dispatch")
    if not repository.strip() or not workflow_name.strip() or not workflow_run_id.strip():
        raise VerificationError("repository, workflow name, and workflow run ID are required")
    if not workflow_run_attempt.strip().isdigit() or int(workflow_run_attempt) < 1:
        raise VerificationError("workflow run attempt must be a positive integer")

    candidate = _resolve_commit(root, candidate_sha, "candidate SHA")
    base = _resolve_commit(root, base_sha, "base SHA")
    controller = _resolve_commit(controller_root, controller_sha, "controller SHA")
    if _head(controller_root) != controller:
        raise VerificationError("controller checkout HEAD does not match controller SHA")
    branch = _validate_branch(root, candidate_branch)
    if f"refs/heads/{branch}" != CANDIDATE_REF:
        raise VerificationError(f"candidate ref must be {CANDIDATE_REF}")
    if _head(root) != candidate:
        raise VerificationError(f"checkout HEAD does not match candidate SHA {candidate}")

    remote_identity = _remote_identity(root, remote)
    remote_candidate = _remote_ref(root, remote, f"refs/heads/{branch}")
    if remote_candidate != candidate:
        raise VerificationError(
            f"candidate branch HEAD mismatch: expected {candidate}, found {remote_candidate}"
        )
    remote_base = _remote_ref(root, remote, BASELINE_REF)
    if remote_base != base:
        raise VerificationError(f"protected baseline drift: expected {base}, found {remote_base}")
    if candidate == base:
        raise VerificationError("candidate SHA must differ from the protected baseline SHA")
    fast_forward = _git(root, "merge-base", "--is-ancestor", base, candidate, check=False)
    if fast_forward.returncode != 0:
        raise VerificationError("candidate is not a fast-forward descendant of the protected baseline")
    candidate_count = _git(root, "rev-list", "--count", f"{base}..{candidate}").stdout.strip()
    if candidate_count != "1":
        raise VerificationError("exact-commit CI requires one atomic candidate commit above the baseline")
    parents = _git(root, "rev-list", "--parents", "-n", "1", candidate).stdout.split()
    if len(parents) != 2 or parents[1].lower() != base:
        raise VerificationError("candidate must be the baseline's single direct child commit")
    if _git(root, "rev-list", "--merges", f"{base}..{candidate}").stdout.strip():
        raise VerificationError("candidate range must not contain a merge commit")

    digest = authority_graph_digest(root)
    controller_digests = _file_digests(controller_root)
    candidate_digests = _file_digests(root)
    if controller_digests != candidate_digests:
        raise VerificationError("controller and candidate workflow/verifier digest mismatch")
    _assert_clean(root)
    checks = _parse_required_checks(required_checks)
    created_at = _now()
    state: dict[str, Any] = {
        "schema_version": 1,
        "phase": "running",
        "controller": {
            "sha": controller,
            "digest_algorithm": "sha256",
            "file_digests": controller_digests,
        },
        "candidate": {
            "sha": candidate,
            "branch": branch,
            "remote": remote_identity,
        },
        "baseline": {"ref": BASELINE_REF, "base_sha": base},
        "rollback_target": base,
        "event": {
            "name": event_name,
            "repository": repository.strip(),
            "workflow": workflow_name.strip(),
            "run_id": workflow_run_id.strip(),
            "run_attempt": int(workflow_run_attempt),
        },
        "authority_graph": {
            "index": AUTHORITY_INDEX.as_posix(),
            "digest_algorithm": "sha256",
            "digest": digest,
        },
        "independent_checker_input": {
            "candidate_sha": candidate,
            "base_sha": base,
            "change_range": f"{base}...{candidate}",
            "authority_graph_digest": digest,
        },
        "required_check_names": checks,
        "checkpoints": [
            {"name": "start", "head": candidate, "authority_graph_digest": digest, "at": created_at}
        ],
        "created_at": created_at,
    }
    _write_json(state_file, state)
    return state


def record_checkpoint(root: Path, state_file: Path, name: str) -> dict[str, Any]:
    state = _load_json(state_file, "verification state")
    if state.get("schema_version") != 1 or state.get("phase") != "running":
        raise VerificationError("verification state is not an active schema version 1 run")
    completed = [item.get("name") for item in state.get("checkpoints", []) if isinstance(item, dict)]
    expected_index = len(completed)
    if expected_index >= len(CHECKPOINTS) or name != CHECKPOINTS[expected_index]:
        expected = CHECKPOINTS[expected_index] if expected_index < len(CHECKPOINTS) else "none"
        raise VerificationError(f"checkpoint order violation: expected {expected}, received {name}")
    head, digest = _assert_snapshot(root.resolve(), state)
    state["checkpoints"].append(
        {"name": name, "head": head, "authority_graph_digest": digest, "at": _now()}
    )
    _write_json(state_file, state)
    return state


def _validate_state_shape(state: dict[str, Any]) -> None:
    if state.get("schema_version") != 1:
        raise VerificationError("unsupported verification state schema")
    candidate = state.get("candidate")
    controller = state.get("controller")
    baseline = state.get("baseline")
    graph = state.get("authority_graph")
    if not isinstance(controller, dict) or not isinstance(candidate, dict) or not isinstance(baseline, dict) or not isinstance(graph, dict):
        raise VerificationError("verification state is missing binding objects")
    _require_sha(str(controller.get("sha", "")), "state controller SHA")
    expected_files = {item.as_posix() for item in CONTROLLER_FILES}
    file_digests = controller.get("file_digests")
    if (
        controller.get("digest_algorithm") != "sha256"
        or not isinstance(file_digests, dict)
        or set(file_digests) != expected_files
        or any(re.fullmatch(r"[0-9a-f]{64}", str(value)) is None for value in file_digests.values())
    ):
        raise VerificationError("controller file digest binding is invalid")
    candidate_sha = _require_sha(str(candidate.get("sha", "")), "state candidate SHA")
    base_sha = _require_sha(str(baseline.get("base_sha", "")), "state base SHA")
    if not isinstance(candidate.get("branch"), str) or not candidate["branch"].strip():
        raise VerificationError("candidate branch binding is missing")
    remote = candidate.get("remote")
    if (
        not isinstance(remote, dict)
        or not isinstance(remote.get("name"), str)
        or not remote["name"].strip()
        or not isinstance(remote.get("url"), str)
        or not remote["url"].strip()
    ):
        raise VerificationError("candidate remote binding is missing")
    if baseline.get("ref") != BASELINE_REF:
        raise VerificationError("verification state baseline ref is not the protected baseline")
    if state.get("rollback_target") != base_sha:
        raise VerificationError("rollback target must equal the verified base SHA")
    digest = str(graph.get("digest", ""))
    if re.fullmatch(r"[0-9a-f]{64}", digest) is None or graph.get("digest_algorithm") != "sha256":
        raise VerificationError("authority graph digest binding is invalid")
    if graph.get("index") != AUTHORITY_INDEX.as_posix():
        raise VerificationError("authority graph index binding is invalid")
    event = state.get("event")
    if not isinstance(event, dict) or event.get("name") != "workflow_dispatch":
        raise VerificationError("workflow_dispatch event binding is missing")
    for field in ("repository", "workflow", "run_id"):
        if not isinstance(event.get(field), str) or not event[field].strip():
            raise VerificationError(f"workflow event {field} binding is missing")
    if not isinstance(event.get("run_attempt"), int) or event["run_attempt"] < 1:
        raise VerificationError("workflow run attempt binding is invalid")
    checkpoints = state.get("checkpoints")
    if (
        not isinstance(checkpoints, list)
        or not all(isinstance(item, dict) for item in checkpoints)
        or [item.get("name") for item in checkpoints] != list(CHECKPOINTS)
    ):
        raise VerificationError("all exact-commit checkpoints are required in order")
    for checkpoint in checkpoints:
        if checkpoint.get("head") != candidate_sha:
            raise VerificationError("checkpoint SHA does not match attested candidate SHA")
        if checkpoint.get("authority_graph_digest") != digest:
            raise VerificationError("checkpoint authority digest does not match attested digest")
    independent = state.get("independent_checker_input")
    if not isinstance(independent, dict):
        raise VerificationError("independent checker input binding is missing")
    expected_independent = {
        "candidate_sha": candidate_sha,
        "base_sha": base_sha,
        "change_range": f"{base_sha}...{candidate_sha}",
        "authority_graph_digest": digest,
    }
    if independent != expected_independent:
        raise VerificationError("independent checker input does not match the attested candidate")


def finalize_verification(
    root: Path,
    state_file: Path,
    attestation_file: Path,
    check_values: Sequence[str],
) -> dict[str, Any]:
    state = _load_json(state_file, "verification state")
    if state.get("phase") != "running":
        raise VerificationError("verification state has already been finalized")
    _validate_state_shape(state)
    _assert_snapshot(root.resolve(), state)
    _assert_remote_binding(root.resolve(), state)
    declared = state.get("required_check_names")
    if not isinstance(declared, list):
        raise VerificationError("required check declaration is missing")
    declared = _parse_required_checks(str(item) for item in declared)
    supplied = _parse_check_results(check_values)
    missing = [name for name in declared if name not in supplied]
    unexpected = [name for name in supplied if name not in declared]
    failed = [name for name in declared if supplied.get(name, "") not in PASS_RESULTS]
    results = [
        {"name": name, "result": supplied.get(name, "missing")} for name in declared
    ]
    accepted = not missing and not unexpected and not failed
    attestation = dict(state)
    attestation["phase"] = "complete"
    attestation["result"] = "pass" if accepted else "rejected"
    attestation["required_checks"] = results
    attestation["completed_at"] = _now()
    if unexpected:
        attestation["unexpected_check_names"] = unexpected
    _write_json(attestation_file, attestation)
    state["phase"] = "complete"
    state["result"] = attestation["result"]
    state["attestation_file"] = str(attestation_file)
    _write_json(state_file, state)
    if not accepted:
        details: list[str] = []
        if missing:
            details.append(f"missing={','.join(missing)}")
        if failed:
            details.append(f"failed={','.join(failed)}")
        if unexpected:
            details.append(f"unexpected={','.join(unexpected)}")
        raise VerificationError("required checks rejected: " + "; ".join(details))
    return attestation


def verify_attestation(
    attestation_file: Path,
    expected_candidate_sha: str,
    expected_base_sha: str,
    require_pass: bool,
    root: Optional[Path] = None,
) -> dict[str, Any]:
    attestation = _load_json(attestation_file, "attestation")
    _validate_state_shape(attestation)
    if attestation.get("phase") != "complete":
        raise VerificationError("attestation is not finalized")
    candidate = _require_sha(expected_candidate_sha, "expected candidate SHA")
    base = _require_sha(expected_base_sha, "expected base SHA")
    if attestation["candidate"]["sha"] != candidate:
        raise VerificationError("attestation candidate SHA mismatch")
    if attestation["baseline"]["base_sha"] != base:
        raise VerificationError("attestation base SHA mismatch")
    checks = attestation.get("required_checks")
    if not isinstance(checks, list) or not checks:
        raise VerificationError("attestation required check results are missing")
    declared_value = attestation.get("required_check_names")
    if not isinstance(declared_value, list):
        raise VerificationError("attestation required check declaration is missing")
    declared = _parse_required_checks(str(item) for item in declared_value)
    names: set[str] = set()
    ordered_names: list[str] = []
    check_failed = False
    for item in checks:
        if not isinstance(item, dict) or NAME_PATTERN.fullmatch(str(item.get("name", ""))) is None:
            raise VerificationError("attestation contains an invalid required check result")
        if item["name"] in names:
            raise VerificationError("attestation contains a duplicate required check result")
        names.add(item["name"])
        ordered_names.append(item["name"])
        if str(item.get("result", "")).lower() not in PASS_RESULTS:
            check_failed = True
    if ordered_names != declared:
        raise VerificationError("attestation check results do not match the declared required checks")
    unexpected = attestation.get("unexpected_check_names", [])
    if (
        not isinstance(unexpected, list)
        or any(NAME_PATTERN.fullmatch(str(item)) is None for item in unexpected)
    ):
        raise VerificationError("attestation unexpected check binding is invalid")
    expected_result = "rejected" if check_failed or unexpected else "pass"
    if attestation.get("result") != expected_result:
        raise VerificationError("attestation result is inconsistent with required checks")
    if require_pass and expected_result != "pass":
        raise VerificationError("a rejected attestation cannot authorize activation")
    if root is not None:
        root = root.resolve()
        if _head(root) != candidate:
            raise VerificationError("verification checkout HEAD does not match attestation")
        digest = authority_graph_digest(root)
        if digest != attestation["authority_graph"]["digest"]:
            raise VerificationError("current authority graph digest does not match attestation")
        _assert_clean(root)
    return attestation


def assert_activation(
    root: Path,
    attestation_file: Path,
    remote: str,
    expected_candidate_sha: str,
    expected_base_sha: str,
    approval_record: Optional[str],
) -> None:
    if not approval_record or not approval_record.strip():
        raise VerificationError("a separate baseline-activation approval record is required")
    root = root.resolve()
    attestation = verify_attestation(
        attestation_file,
        expected_candidate_sha,
        expected_base_sha,
        require_pass=True,
        root=root,
    )
    remote_name = attestation["candidate"]["remote"]["name"]
    if remote != remote_name:
        raise VerificationError("activation remote does not match the attested candidate remote")
    fast_forward = _git(
        root,
        "merge-base",
        "--is-ancestor",
        attestation["baseline"]["base_sha"],
        attestation["candidate"]["sha"],
        check=False,
    )
    if fast_forward.returncode != 0:
        raise VerificationError("attested activation is not a fast-forward from its rollback target")
    change_range = (
        f"{attestation['baseline']['base_sha']}..{attestation['candidate']['sha']}"
    )
    if _git(root, "rev-list", "--count", change_range).stdout.strip() != "1":
        raise VerificationError("attested activation is not one atomic candidate commit")
    if _git(root, "rev-list", "--merges", change_range).stdout.strip():
        raise VerificationError("attested activation contains a merge commit")
    _assert_remote_binding(root, attestation, activated=True)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    start = subparsers.add_parser("start", help="validate candidate/base refs and create CI state")
    start.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    start.add_argument("--controller-root", type=Path, required=True)
    start.add_argument("--controller-sha", required=True)
    start.add_argument("--state-file", type=Path, required=True)
    start.add_argument("--candidate-sha", required=True)
    start.add_argument("--base-sha", required=True)
    start.add_argument("--candidate-branch", required=True)
    start.add_argument("--remote", default="origin")
    start.add_argument("--event-name", required=True)
    start.add_argument("--repository", required=True)
    start.add_argument("--workflow-name", required=True)
    start.add_argument("--workflow-run-id", required=True)
    start.add_argument("--workflow-run-attempt", default="1")
    start.add_argument("--required-check", action="append", default=[])

    checkpoint = subparsers.add_parser("checkpoint", help="assert checkout and graph immutability")
    checkpoint.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    checkpoint.add_argument("--state-file", type=Path, required=True)
    checkpoint.add_argument("--name", choices=CHECKPOINTS[1:], required=True)

    finalize = subparsers.add_parser("finalize", help="write pass/rejected required-check attestation")
    finalize.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    finalize.add_argument("--state-file", type=Path, required=True)
    finalize.add_argument("--attestation-file", type=Path, required=True)
    finalize.add_argument("--check", action="append", default=[])

    verify = subparsers.add_parser("verify-attestation", help="verify attestation bindings")
    verify.add_argument("--attestation-file", type=Path, required=True)
    verify.add_argument("--candidate-sha", required=True)
    verify.add_argument("--base-sha", required=True)
    verify.add_argument("--require-pass", action="store_true")
    verify.add_argument("--root", type=Path)

    activation = subparsers.add_parser(
        "assert-activation", help="after separate approval, assert the remote baseline without changing it"
    )
    activation.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    activation.add_argument("--attestation-file", type=Path, required=True)
    activation.add_argument("--remote", default="origin")
    activation.add_argument("--candidate-sha", required=True)
    activation.add_argument("--base-sha", required=True)
    activation.add_argument("--approval-record")
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        if args.command == "start":
            state = start_verification(
                args.root,
                args.controller_root,
                args.controller_sha,
                args.state_file,
                args.candidate_sha,
                args.base_sha,
                args.candidate_branch,
                args.remote,
                args.event_name,
                args.repository,
                args.workflow_name,
                args.workflow_run_id,
                args.workflow_run_attempt,
                args.required_check,
            )
            print(
                "Exact-commit preflight passed: "
                f"{state['candidate']['sha']} from {state['baseline']['base_sha']}"
            )
        elif args.command == "checkpoint":
            record_checkpoint(args.root, args.state_file, args.name)
            print(f"Exact-commit checkpoint passed: {args.name}")
        elif args.command == "finalize":
            attestation = finalize_verification(
                args.root, args.state_file, args.attestation_file, args.check
            )
            print(
                "Exact-commit attestation passed: "
                f"{attestation['candidate']['sha']} -> {args.attestation_file}"
            )
        elif args.command == "verify-attestation":
            verify_attestation(
                args.attestation_file,
                args.candidate_sha,
                args.base_sha,
                args.require_pass,
                args.root,
            )
            print("Exact-commit attestation verification passed")
        elif args.command == "assert-activation":
            assert_activation(
                args.root,
                args.attestation_file,
                args.remote,
                args.candidate_sha,
                args.base_sha,
                args.approval_record,
            )
            print("Protected baseline activation assertion passed")
        else:  # pragma: no cover - argparse guarantees a known command.
            raise VerificationError(f"unsupported command: {args.command}")
    except VerificationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
