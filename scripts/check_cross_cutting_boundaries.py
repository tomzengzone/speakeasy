#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OPENAPI_SOURCE = "docs/architecture/openapi/speakeasy-api.yaml"
GENERATED_DART_ROOT = "lib/generated/api/"

STATUS_DOC_PREFIXES = (
    "docs/reports/",
    "docs/release/",
    ".github/",
)

BLOCKED_OR_NEGATED_CONTEXT = re.compile(
    r"\b("
    r"not|blocked|pending|planned|required|requires|remain|remains|still|future|"
    r"must\s+not|not\s+approved|not\s+release[- ]ready|"
    r"does\s+not|do\s+not"
    r")\b",
    re.IGNORECASE,
)

NARROW_NO_STATUS_CLAIM_CONTEXT = re.compile(
    r"\bno\s+(?:"
    r"followup-e\b[^.;\n]*\b(?:implemented|tested|complete|completed|passed|release[- ]ready)|"
    r"(?:commercial\s+release|release\s+readiness|paid\s+ai\s+external\s+evidence|"
    r"product\s+base\s+merge)\b[^.;\n]*\b(?:approved|pass(?:ed)?|release[- ]ready)"
    r")\b",
    re.IGNORECASE,
)

BLOCKED_OR_NEGATED_SUBSTRINGS = (
    "不得",
    "不能",
    "未",
    "不",
    "阻塞",
    "仍",
    "保持",
    "计划",
    "待",
    "需要",
    "剩余 blocker",
)

PRODUCTION_CODE_SUFFIXES = {".dart", ".java"}

LEGACY_LOCAL_AUDIO_CALL_PATTERN = re.compile(
    r"\bApiClient\.(?:legacyTranscribeLocalAudioForScene|legacyScoreLocalAudioForPronunciation)\s*\(",
)

LEGACY_SCENE_AUDIO_CALL_PATTERN = re.compile(
    r"\b(?!ApiClient\b)\w+\s*\.\s*legacyTranscribeLocalAudioForScene\s*\(",
)

REMOVED_LOCAL_AUDIO_API_DEFINITION_PATTERN = re.compile(
    r"\b(?:static\s+)?Future(?:<[^(\n]*>)?\s+(?:transcribeAudio|scoreAudio|legacyTranscribeLocalAudioForScene|legacyScoreLocalAudioForPronunciation|fetchOralAssessmentAuth|scorePronunciation)\s*\(",
)

COMMERCIAL_FINAL_FACT_PATTERN = re.compile(
    r"\b(?:"
    r"(?:is)?releaseReady|release_ready|commercialReleaseApproved|commercial_release_approved|"
    r"productBaseMergeApproved|product_base_merge_approved|paidAiExternalEvidencePassed|"
    r"paid_ai_external_evidence_passed|entitlementGranted|entitlement_granted|"
    r"quotaUnlimited|quota_unlimited|billingApproved|billing_approved|refundApproved|refund_approved"
    r")\b\s*(?::|=|=>)\s*(?:true|['\"](?:approved|passed|ready|granted|unlimited)['\"])",
    re.IGNORECASE,
)

GOAL_FINAL_FACT_PATTERN = re.compile(
    r"\b(?:"
    r"officialScoreEquivalence|official_score_equivalence|goalCompletionClaimAllowed|"
    r"goal_completion_claim_allowed|guaranteedOutcome|guaranteed_outcome|goalComplete|"
    r"goal_complete|claimGuard|claim_guard|diagnosticMode|diagnostic_mode|"
    r"confidenceBand|confidence_band|etaRange|eta_range"
    r")\b\s*(?::|=|=>)\s*(?:true|['\"](?:complete|completed|approved|high|precise|enabled|audio_first)['\"])",
    re.IGNORECASE,
)

LOG_CALL_PATTERN = re.compile(r"\b(?:logger|log|print|System\.out|auditLogs?\.save)\b", re.IGNORECASE)

SENSITIVE_FIELD_NAME_PATTERN = re.compile(
    r"\b(?:"
    r"rawAudio|raw_audio|rawTranscript|raw_transcript|providerPayload|provider_payload|"
    r"signedUrl|signed_url|secret|receipt|idempotencyKey|idempotency_key"
    r")\b",
    re.IGNORECASE,
)

API_SENSITIVE_FIELD_NAME_PATTERN = re.compile(
    r"\b(?:"
    r"rawAudio|raw_audio|rawTranscript|raw_transcript|providerPayload(?!Redacted)|provider_payload(?!_redacted)|"
    r"providerSecret|provider_secret|signedUrl|signed_url|fullSignedUrl|full_signed_url"
    r")\b",
    re.IGNORECASE,
)

API_DTO_DECLARATION_PREFIX_PATTERN = re.compile(
    r"(?:^|[(,])\s*"
    r"(?:@\w+(?:\([^)]*\))?\s+)*"
    r"(?:(?:public|protected|private|static|final|transient|volatile)\s+)*"
    r"(?:[A-Za-z_$][\w$.]*(?:\s*<[^;\n()]*>)?(?:\[\])?\s+)+$"
)

STATUS_CLAIM_PATTERNS = [
    (
        "XCB-007",
        re.compile(
            r"\b(?:"
            r"commercial release approved|commercial release pass(?:ed)?|release[- ]ready|"
            r"release readiness pass(?:ed)?|paid ai external evidence pass(?:ed)?|"
            r"product base merge (?:is )?approved|product base merge pass(?:ed)?"
            r")\b",
            re.IGNORECASE,
        ),
        "Reports and release docs must not claim release/Product Base approval without explicit approved evidence.",
    ),
    (
        "XCB-007",
        re.compile(
            r"\bfollowup-e\b.*\b(?:implemented|tested|complete|completed|passed|release[- ]ready)\b",
            re.IGNORECASE,
        ),
        "Followup-E is planning/contract evidence only unless implementation and test evidence are explicitly accepted.",
    ),
]


@dataclass(frozen=True)
class Violation:
    boundary_id: str
    path: str
    line: int
    message: str


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def run_git(args: list[str]) -> list[str]:
    completed = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        return []
    return [line.strip().replace("\\", "/") for line in completed.stdout.splitlines() if line.strip()]


def changed_paths(base_ref: str | None, include_worktree: bool) -> list[Path]:
    names: set[str] = set()
    if base_ref and not re.fullmatch(r"0{40}", base_ref):
        names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT", f"{base_ref}...HEAD"]))
        if not names:
            names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT", base_ref, "HEAD"]))
    if include_worktree:
        names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT"]))
        names.update(run_git(["ls-files", "--others", "--exclude-standard"]))
    return sorted((ROOT / name for name in names if (ROOT / name).exists()), key=lambda path: rel(path))


def full_scan_paths() -> list[Path]:
    paths: list[Path] = []
    for directory, suffix in (
        (ROOT / "lib", ".dart"),
        (ROOT / "backend/src/main/java", ".java"),
    ):
        if directory.exists():
            paths.extend(path for path in directory.rglob(f"*{suffix}") if path.is_file())
    if (ROOT / "lib/generated/api").exists():
        paths.extend(path for path in (ROOT / "lib/generated/api").rglob("*") if path.is_file())
    return sorted(set(paths), key=lambda path: rel(path))


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def check_flutter_audio_ref(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if not relative.startswith("lib/") or not relative.endswith(".dart"):
        return []
    violations: list[Violation] = []
    for match in REMOVED_LOCAL_AUDIO_API_DEFINITION_PATTERN.finditer(text):
        violations.append(
            Violation(
                "XCB-001",
                relative,
                line_number(text, match.start()),
                "Removed File-based/local pronunciation audio API names must not be reintroduced; use trusted media upload and media://audio/... audio_ref.",
            )
        )
    patterns = []
    patterns.append(
        (
            re.compile(r"""['"]audio_ref['"]\s*:\s*[^,\n]*\.path\b"""),
            "Flutter must not send a local File.path as audio_ref; use backend-owned media upload first.",
        )
    )
    patterns.append(
        (
            re.compile(r"""\bApiClient\.(?:transcribeAudio|scoreAudio|legacyTranscribeLocalAudioForScene|legacyScoreLocalAudioForPronunciation)\s*\("""),
            "Production Flutter flows must not call removed File-based AI audio methods.",
        )
    )
    for pattern, message in patterns:
        for match in pattern.finditer(text):
            violations.append(Violation("XCB-001", relative, line_number(text, match.start()), message))
    for match in LEGACY_LOCAL_AUDIO_CALL_PATTERN.finditer(text):
        violations.append(
            Violation(
                "XCB-001",
                relative,
                line_number(text, match.start()),
                "Legacy local-file AI audio wrappers have been retired; use trusted media upload and media://audio/... audio_ref.",
            )
        )
    for match in LEGACY_SCENE_AUDIO_CALL_PATTERN.finditer(text):
        violations.append(
            Violation(
                "XCB-001",
                relative,
                line_number(text, match.start()),
                "Scene local-audio transcription has been retired; use trusted media upload and media://audio/... audio_ref.",
            )
        )
    return violations


def is_test_or_generated(relative: str) -> bool:
    return relative.startswith(("test/", "integration_test/", GENERATED_DART_ROOT))


def is_status_doc(relative: str) -> bool:
    return relative.endswith((".md", ".txt", ".yml", ".yaml")) and relative.startswith(STATUS_DOC_PREFIXES)


def has_blocked_or_negated_context(line: str) -> bool:
    return (
        bool(BLOCKED_OR_NEGATED_CONTEXT.search(line))
        or bool(NARROW_NO_STATUS_CLAIM_CONTEXT.search(line))
        or any(marker in line for marker in BLOCKED_OR_NEGATED_SUBSTRINGS)
    )


def statement_windows(text: str, trigger_pattern: re.Pattern[str], max_lines: int = 6) -> list[tuple[int, str]]:
    lines = text.splitlines(keepends=True)
    offsets: list[int] = []
    offset = 0
    for line in lines:
        offsets.append(offset)
        offset += len(line)

    windows: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        if not trigger_pattern.search(line):
            continue
        window_parts = [line]
        for next_index in range(index + 1, min(len(lines), index + max_lines)):
            if ";" in "".join(window_parts):
                break
            window_parts.append(lines[next_index])
        windows.append((offsets[index], "".join(window_parts)))
    return windows


def looks_like_api_dto_sensitive_declaration(line: str, field_start: int, field_end: int) -> bool:
    stripped = line.lstrip()
    if stripped.startswith(("//", "/*", "*")):
        return False
    field_name = line[field_start:field_end]
    if not field_name or not (field_name[0].islower() or "_" in field_name):
        return False
    if line[field_end:].lstrip().startswith("("):
        return False
    return bool(API_DTO_DECLARATION_PREFIX_PATTERN.search(line[:field_start]))


def check_flutter_commercial_and_goal_facts(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if not relative.startswith("lib/") or not relative.endswith(".dart") or is_test_or_generated(relative):
        return []
    violations: list[Violation] = []
    for pattern, boundary_id, message in (
        (
            COMMERCIAL_FINAL_FACT_PATTERN,
            "XCB-004",
            "Flutter must not hardcode backend-owned entitlement/quota/billing/release facts.",
        ),
        (
            GOAL_FINAL_FACT_PATTERN,
            "XCB-005",
            "Flutter must not hardcode backend-owned Goal Autopilot final facts.",
        ),
    ):
        for match in pattern.finditer(text):
            violations.append(Violation(boundary_id, relative, line_number(text, match.start()), message))
    return violations


def check_sensitive_payload_exposure(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if is_test_or_generated(relative):
        return []
    if path.suffix not in PRODUCTION_CODE_SUFFIXES:
        return []
    violations: list[Violation] = []
    for start, window in statement_windows(text, LOG_CALL_PATTERN):
        for match in SENSITIVE_FIELD_NAME_PATTERN.finditer(window):
            violations.append(
                Violation(
                    "XCB-006",
                    relative,
                    line_number(text, start + match.start()),
                    "Production logs/audit events must not include raw audio, transcript, provider payload, secrets, signed URLs, receipts, or idempotency keys.",
                )
            )
            break
    if relative.startswith("backend/src/main/java/com/speakeasy/api/"):
        for match in API_SENSITIVE_FIELD_NAME_PATTERN.finditer(text):
            line_start = text.rfind("\n", 0, match.start()) + 1
            line_end = text.find("\n", match.start())
            if line_end == -1:
                line_end = len(text)
            line = text[line_start:line_end]
            field_start = match.start() - line_start
            field_end = match.end() - line_start
            if not looks_like_api_dto_sensitive_declaration(line, field_start, field_end):
                continue
            violations.append(
                Violation(
                    "XCB-006",
                    relative,
                    line_number(text, match.start()),
                    "API DTOs must not expose raw audio, transcript, provider payload, provider secrets, or full signed URLs.",
                )
            )
    return violations


def check_status_document_claims(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if not is_status_doc(relative):
        return []
    violations: list[Violation] = []
    offset = 0
    for line in text.splitlines(keepends=True):
        line_text = line.strip()
        for boundary_id, pattern, message in STATUS_CLAIM_PATTERNS:
            if pattern.search(line_text) and not has_blocked_or_negated_context(line_text):
                violations.append(Violation(boundary_id, relative, line_number(text, offset), message))
        offset += len(line)
    return violations


def check_backend_provider_bypass(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if not relative.startswith("backend/src/main/java/") or not relative.endswith(".java"):
        return []
    if relative.startswith("backend/src/main/java/com/speakeasy/ai/"):
        return []
    violations: list[Violation] = []
    patterns = [
        (
            re.compile(r"""\bimport\s+com\.speakeasy\.ai\.AiProviderGateway\s*;"""),
            "Business code must not depend on AiProviderGateway directly; inject AiGatewayService instead.",
        ),
        (
            re.compile(r"""(?<!com\.speakeasy\.ai\.)\bAiProviderGateway\b"""),
            "Business code must not reference AiProviderGateway directly; route provider calls through AiGatewayService.",
        ),
        (
            re.compile(r"""\bprovider\.(?:transcribe|scorePronunciation|coach|synthesize)\s*\("""),
            "Business code must route provider calls through AiGatewayService and policy/usage gates.",
        ),
    ]
    for pattern, message in patterns:
        for match in pattern.finditer(text):
            violations.append(Violation("XCB-002", relative, line_number(text, match.start()), message))
    return violations


def check_file_content(paths: list[Path]) -> list[Violation]:
    violations: list[Violation] = []
    for path in paths:
        relative = rel(path)
        if relative.startswith(("test/", "integration_test/")):
            continue
        if path.suffix not in PRODUCTION_CODE_SUFFIXES and not is_status_doc(relative):
            continue
        text = read_text(path)
        violations.extend(check_flutter_audio_ref(path, text))
        violations.extend(check_flutter_commercial_and_goal_facts(path, text))
        violations.extend(check_backend_provider_bypass(path, text))
        violations.extend(check_sensitive_payload_exposure(path, text))
        violations.extend(check_status_document_claims(path, text))
    return violations


def check_generated_client_changes(paths: list[Path], scope: str) -> list[Violation]:
    if scope != "changed":
        return []
    relative_paths = {rel(path) for path in paths}
    generated_changes = sorted(path for path in relative_paths if path.startswith(GENERATED_DART_ROOT))
    if not generated_changes or OPENAPI_SOURCE in relative_paths:
        return []
    first = generated_changes[0]
    return [
        Violation(
            "XCB-003",
            first,
            1,
            "Generated Dart client changes must be paired with the OpenAPI source-of-truth update.",
        )
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Check cross-cutting architecture boundary violations.")
    parser.add_argument("--scope", choices=("changed", "full"), default="full")
    parser.add_argument("--base-ref", help="Base git ref for changed-only checks.")
    parser.add_argument(
        "--include-worktree",
        action="store_true",
        help="Include uncommitted and untracked files in changed-only checks.",
    )
    args = parser.parse_args()

    paths = changed_paths(args.base_ref, args.include_worktree) if args.scope == "changed" else full_scan_paths()
    violations = check_file_content(paths)
    violations.extend(check_generated_client_changes(paths, args.scope))

    if violations:
        print("Cross-cutting boundary check failed:")
        for violation in violations:
            print(f"- {violation.boundary_id} {violation.path}:{violation.line} - {violation.message}")
        return 1

    print(f"Cross-cutting boundary check passed: scope={args.scope}, files={len(paths)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
