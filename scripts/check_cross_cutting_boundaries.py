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
MIGRATION_ROOT = "backend/src/main/resources/db/migration/"

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

LOCAL_PAID_GATE_PATTERNS = (
    (
        re.compile(r"(?:\)\s*|[A-Za-z_$][\w$]*(?:\s*(?:\.|\?\.)\s*[A-Za-z_$][\w$]*(?:\s*\([^;\n]*?\))?)*)\s*(?:\.|\?\.)\s*isPro\b"),
        "Paid UI gates must consume backend entitlement projection, not local AppSession.isPro/memberPlan compatibility state.",
    ),
    (
        re.compile(r"\bmemberPlan\b\s*(?:==|!=)\s*['\"](?:free|pro|monthly|yearly|enterprise)['\"]"),
        "Paid UI gates must not compare local memberPlan; consume backend entitlement projection.",
    ),
    (
        re.compile(r"['\"](?:free|pro|monthly|yearly|enterprise)['\"]\s*(?:==|!=)\s*\bmemberPlan\b"),
        "Paid UI gates must not compare local memberPlan; consume backend entitlement projection.",
    ),
    (
        re.compile(r"\bcurrentPlan\b\s*(?:==|!=)\s*['\"]free['\"]"),
        "Paid UI gates must not treat currentPlan/free as entitlement truth; consume backend entitlement projection.",
    ),
    (
        re.compile(r"\bhasProEntitlement\b"),
        "Boolean hasProEntitlement plumbing must not be reintroduced; pass CommercialEntitlementProjection instead.",
    ),
    (
        re.compile(r"CommercialScenarioGate\.canAccess\s*\([\s\S]{0,300}\bisPro\s*:"),
        "CommercialScenarioGate must be called with backend entitlement projection, not an isPro boolean.",
    ),
)

LEGACY_RAW_AI_ENDPOINT_PATTERN = re.compile(
    r"""['"][^'"]*(?:/ai/(?:scene-draft|sessions(?:/[^'"]*)?|scene-turn-meta|translate|conversation-summary|grammar-score|voice-chat))""",
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

CREATE_TABLE_PATTERN = re.compile(
    r"\bCREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?"
    r"((?:\"[^\"]+\"|[A-Za-z_][\w]*)(?:\s*\.\s*(?:\"[^\"]+\"|[A-Za-z_][\w]*))?)"
    r"\s*\((.*?)\)\s*;",
    re.IGNORECASE | re.DOTALL,
)

XCB006_SENSITIVE_FIELD_PATTERN = re.compile(
    r"\b(?:"
    r"user_id|user_hash|user_ref|owner_hash|owner_ref|owner_ref_id|audio_ref|media_id|cache_id|"
    r"raw_transcript|transcript|provider_payload|raw_provider_payload|signed_url|payload_ref|"
    r"idempotency_key|idempotency_key_hash|request_hash|response_json|response_json_redacted|"
    r"target_ref|redacted_details|notification_payload|receipt|access_token_hash|token_hash|token|secret"
    r")\b",
    re.IGNORECASE,
)

XCB006_SENSITIVE_FIELD_TOKENS = {
    "audit",
    "audits",
    "audio",
    "details",
    "email",
    "evidence",
    "idempotency",
    "media",
    "owner",
    "payload",
    "provider",
    "receipt",
    "redacted",
    "ref",
    "secret",
    "signed",
    "target",
    "token",
    "transcript",
    "url",
    "user",
}

XCB006_SENSITIVE_SAFE_FIELD_TOKENS = {
    "audio",
    "cache",
    "email",
    "idempotency",
    "media",
    "owner",
    "payload",
    "provider",
    "receipt",
    "redacted",
    "ref",
    "secret",
    "signed",
    "target",
    "token",
    "transcript",
    "url",
    "user",
}

XCB006_SENSITIVE_TABLE_TOKENS = {
    "ai",
    "audit",
    "audits",
    "audio",
    "cache",
    "diagnostic",
    "evidence",
    "evidences",
    "idempotency",
    "media",
    "metric",
    "metrics",
    "notification",
    "notifications",
    "provider",
    "retention",
    "replay",
    "replays",
    "telemetry",
    "transcript",
}

XCB006_CODE_COVERAGE_PATHS = (
    "backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java",
    "backend/src/main/java/com/speakeasy/ai/AiRetentionService.java",
    "backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java",
)

XCB006_EXCEPTION_DOC_PATHS = (
    "docs/process/cross_cutting_boundary_registry.md",
    "docs/domain/domain_schema.md",
    "docs/domain/entity_relationship.md",
    "docs/architecture/backend_db_foundation_contract.md",
    "docs/architecture/api_contract.md",
)

XCB006_EXCEPTION_FIELD_PATTERN = re.compile(
    r"\b("
    r"table|owner|safe_fields|redacted_fields|omitted_fields|"
    r"retention_trigger|deletion_behavior|export_behavior|rationale"
    r")\s*=\s*([^;]*)",
    re.IGNORECASE,
)

XCB006_EXCEPTION_TYPE_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_])XCB-006\s+"
    r"(retained-redacted|legacy|not-applicable)"
    r"\s+exception\s*:"
)

XCB006_PLANNED_EXCEPTION_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_])XCB-006\s+planned\s+exception\s*:",
    re.IGNORECASE,
)

XCB006_EXCEPTION_REQUIRED_FIELDS = {
    "table",
    "owner",
    "safe_fields",
    "redacted_fields",
    "omitted_fields",
    "retention_trigger",
    "deletion_behavior",
    "export_behavior",
    "rationale",
}

XCB006_NOT_APPLICABLE_RATIONALE_TOKENS = {
    "configuration",
    "no_user_data",
    "not_user_owned",
    "public_reference",
    "reference_data",
}

XCB006_LEGACY_RATIONALE_TOKENS = {
    "migration_compatibility",
    "pre_existing",
}

XCB006_EXCEPTION_PLACEHOLDER_PATTERN = re.compile(
    r"\b(?:todo|tbd|later|future|planned|pending|unknown|temporary)\b",
    re.IGNORECASE,
)

XCB006_EXCEPTION_PLACEHOLDER_TOKENS = {
    "future",
    "later",
    "pending",
    "planned",
    "tbd",
    "temporary",
    "todo",
    "unknown",
}

XCB006_USER_IDENTIFIER_SUBJECT_TOKENS = {
    "account",
    "actor",
    "customer",
    "learner",
    "member",
    "profile",
}

XCB006_USER_IDENTIFIER_VALUE_TOKENS = {
    "hash",
    "id",
    "identifier",
    "key",
    "name",
    "ref",
    "uuid",
}

XCB006_SENSITIVE_SAFE_FIELD_TOKENS.update(XCB006_USER_IDENTIFIER_SUBJECT_TOKENS)

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


def read_git_index_text(relative_path: str) -> str | None:
    completed = subprocess.run(
        ["git", "show", f":{relative_path}"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        return None
    return completed.stdout


def git_index_path_exists(relative_path: str) -> bool:
    completed = subprocess.run(
        ["git", "cat-file", "-e", f":{relative_path}"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return completed.returncode == 0


def changed_paths(base_ref: str | None, include_worktree: bool) -> list[Path]:
    names: set[str] = set()
    if base_ref and not re.fullmatch(r"0{40}", base_ref):
        names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT", f"{base_ref}...HEAD"]))
        if not names:
            names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT", base_ref, "HEAD"]))
    if include_worktree:
        names.update(run_git(["diff", "--name-only", "--diff-filter=ACMRT"]))
        names.update(run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMRT"]))
        names.update(run_git(["ls-files", "--others", "--exclude-standard"]))
    return sorted(
        (ROOT / name for name in names if (ROOT / name).exists() or git_index_path_exists(name)),
        key=lambda path: rel(path),
    )


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
    return relative.startswith(("test/", "integration_test/", "backend/src/test/", GENERATED_DART_ROOT))


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


def is_allowed_app_session_compatibility_line(relative: str, line: str, match_text: str) -> bool:
    if relative != "lib/services/app_session.dart":
        return False
    stripped = line.strip()
    if match_text == "memberPlan":
        return (
            stripped.startswith("String get displayMemberPlan")
            or stripped.startswith("String get memberPlan")
            or "_user?.memberPlan" in stripped
            or "remoteUser.memberPlan" in stripped
        )
    if "isPro" in match_text:
        return stripped.startswith("bool get isPro => hasActivePaidEntitlement;")
    return False


def check_flutter_commercial_gate_sources(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if not relative.startswith("lib/") or not relative.endswith(".dart") or is_test_or_generated(relative):
        return []
    violations: list[Violation] = []
    for pattern, message in LOCAL_PAID_GATE_PATTERNS:
        for match in pattern.finditer(text):
            line_start = text.rfind("\n", 0, match.start()) + 1
            line_end = text.find("\n", match.start())
            if line_end == -1:
                line_end = len(text)
            line = text[line_start:line_end]
            matched_text = match.group(0).strip()
            if is_allowed_app_session_compatibility_line(relative, line, matched_text):
                continue
            if ".isPro" in match.group(0) and "this.isPro" in line:
                continue
            violations.append(Violation("XCB-004", relative, line_number(text, match.start()), message))
    return violations


def check_flutter_raw_ai_endpoint_paths(path: Path, text: str) -> list[Violation]:
    relative = rel(path)
    if not relative.startswith("lib/") or not relative.endswith(".dart") or is_test_or_generated(relative):
        return []
    violations: list[Violation] = []
    for match in LEGACY_RAW_AI_ENDPOINT_PATTERN.finditer(text):
        violations.append(
            Violation(
                "XCB-004",
                relative,
                line_number(text, match.start()),
                "Flutter must not call legacy raw high-cost AI endpoints; use generated backend gateway paths, practice/training APIs, or deterministic fallback.",
            )
        )
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


def is_migration_file(relative: str) -> bool:
    return relative.startswith(MIGRATION_ROOT) and relative.endswith(".sql")


@dataclass(frozen=True)
class Xcb006GovernanceCoverage:
    code_text: str
    exception_text: str


def xcb006_governance_coverage() -> Xcb006GovernanceCoverage:
    code_chunks: list[str] = []
    for relative in XCB006_CODE_COVERAGE_PATHS:
        path = ROOT / relative
        if path.exists():
            code_chunks.append(f"\n# {relative}\n{read_text(path)}")
    chunks: list[str] = []
    for relative in XCB006_EXCEPTION_DOC_PATHS:
        path = ROOT / relative
        if path.exists():
            chunks.append(f"\n# {relative}\n{read_text(path)}")
    product_increment_root = ROOT / "docs/product/increments"
    if product_increment_root.exists():
        for path in sorted(product_increment_root.rglob("*.md"), key=lambda item: rel(item)):
            chunks.append(f"\n# {rel(path)}\n{read_text(path)}")
    return Xcb006GovernanceCoverage("\n".join(code_chunks), "\n".join(chunks))


def xcb006_staged_governance_coverage() -> Xcb006GovernanceCoverage:
    code_chunks: list[str] = []
    for relative in XCB006_CODE_COVERAGE_PATHS:
        text = read_git_index_text(relative)
        if text is not None:
            code_chunks.append(f"\n# {relative}\n{text}")
    chunks: list[str] = []
    for relative in XCB006_EXCEPTION_DOC_PATHS:
        text = read_git_index_text(relative)
        if text is not None:
            chunks.append(f"\n# {relative}\n{text}")
    product_increment_root = ROOT / "docs/product/increments"
    staged_docs = [
        path
        for path in run_git(["ls-files", "docs/product/increments"])
        if path.endswith(".md")
    ]
    for relative in sorted(staged_docs):
        text = read_git_index_text(relative)
        if text is not None:
            chunks.append(f"\n# {relative}\n{text}")
    return Xcb006GovernanceCoverage("\n".join(code_chunks), "\n".join(chunks))


def normalize_sql_identifier(identifier: str) -> str:
    cleaned = identifier.strip()
    final_part = re.split(r"\s*\.\s*", cleaned)[-1]
    if final_part.startswith('"') and final_part.endswith('"'):
        return final_part[1:-1]
    return final_part


def identifier_tokens(value: str) -> set[str]:
    camel_split = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", value)
    camel_split = re.sub(r"(?<=[A-Z])(?=[A-Z][a-z])", "_", camel_split)
    return {token for token in re.split(r"[^a-z0-9]+", camel_split.lower()) if token}


def snake_tokens(value: str) -> set[str]:
    return identifier_tokens(value)


def xcb006_sensitive_table_reason(table_name: str, table_body: str) -> str | None:
    table_tokens = snake_tokens(table_name)
    semantic_tokens = sorted(table_tokens & XCB006_SENSITIVE_TABLE_TOKENS)
    if semantic_tokens:
        return semantic_tokens[0]
    match = XCB006_SENSITIVE_FIELD_PATTERN.search(table_body)
    if match:
        return match.group(0)
    field_tokens = sorted(snake_tokens(table_body) & XCB006_SENSITIVE_FIELD_TOKENS)
    if field_tokens:
        return field_tokens[0]
    return None


def quoted_table_pattern(table_name: str) -> str:
    return re.escape(table_name)


def strip_java_comments(text: str) -> str:
    without_block_comments = re.sub(r"/\*[\s\S]*?\*/", "", text)
    return re.sub(r"//.*", "", without_block_comments)


def xcb006_structured_code_coverage_dimensions(table_name: str, coverage_text: str) -> set[str]:
    table = quoted_table_pattern(table_name)
    searchable = strip_java_comments(coverage_text)
    dimension_patterns = {
        "deletion": (
            rf'\bdelete\s*\(\s*"{table}"\s*,',
            rf'\bdelete\s*\(\s*\'{table}\'\s*,',
            rf'\bDELETE\s+FROM\s+{table}\b',
            rf'\bDELETE\s+FROM\s+"{table}"\b',
        ),
        "export": (
            rf'\bdataFamily\s*\(\s*"{table}"\s*,',
            rf'\bdataFamily\s*\(\s*\'{table}\'\s*,',
            rf'\bnew\s+DataFamilyExportRecord\s*\(\s*"{table}"\s*,',
            rf'\bnew\s+DataFamilyExportRecord\s*\(\s*\'{table}\'\s*,',
        ),
        "retention": (
            rf'\bnew\s+RetentionRuleView\s*\(\s*"{table}"\s*,',
            rf'\bnew\s+RetentionRuleView\s*\(\s*\'{table}\'\s*,',
        ),
    }
    return {
        dimension
        for dimension, patterns in dimension_patterns.items()
        if any(re.search(pattern, searchable, re.IGNORECASE) for pattern in patterns)
    }


def xcb006_has_structured_code_coverage(table_name: str, coverage_text: str) -> bool:
    required_dimensions = {"deletion", "export", "retention"}
    return required_dimensions.issubset(
        xcb006_structured_code_coverage_dimensions(table_name, coverage_text)
    )


def xcb006_exception_type(line: str) -> str | None:
    if XCB006_PLANNED_EXCEPTION_PATTERN.search(line):
        return None
    match = XCB006_EXCEPTION_TYPE_PATTERN.search(line)
    if match is None:
        return None
    normalized = match.group(1)
    if normalized == "retained-redacted":
        return "retained-redacted"
    if normalized == "legacy":
        return "legacy"
    if normalized == "not-applicable":
        return "not-applicable"
    return None


def xcb006_parse_exception_fields(line: str) -> dict[str, str]:
    return {
        match.group(1).lower(): match.group(2).strip()
        for match in XCB006_EXCEPTION_FIELD_PATTERN.finditer(line)
    }


def xcb006_exception_has_duplicate_fields(line: str) -> bool:
    seen: set[str] = set()
    for match in XCB006_EXCEPTION_FIELD_PATTERN.finditer(line):
        field = match.group(1).lower()
        if field in seen:
            return True
        seen.add(field)
    return False


def xcb006_exception_table_value(value: str) -> str:
    cleaned = value.strip().strip("`'\"")
    return normalize_sql_identifier(cleaned)


def xcb006_exception_required_fields_present(fields: dict[str, str]) -> bool:
    if not XCB006_EXCEPTION_REQUIRED_FIELDS.issubset(fields):
        return False
    return all(fields[field].strip() for field in XCB006_EXCEPTION_REQUIRED_FIELDS)


def xcb006_exception_safe_fields_are_safe(fields: dict[str, str]) -> bool:
    safe_fields = fields.get("safe_fields", "")
    for field in re.split(r"[,\s]+", safe_fields):
        cleaned = field.strip().strip("`'\"")
        if not cleaned or cleaned.lower() in {"none", "n/a", "not_applicable"}:
            continue
        tokens = identifier_tokens(cleaned)
        if XCB006_SENSITIVE_FIELD_PATTERN.search(cleaned):
            return False
        if tokens & XCB006_SENSITIVE_SAFE_FIELD_TOKENS:
            return False
        if (
            tokens & XCB006_USER_IDENTIFIER_SUBJECT_TOKENS
            and tokens & XCB006_USER_IDENTIFIER_VALUE_TOKENS
        ):
            return False
    return True


def xcb006_exception_fields_are_actionable(fields: dict[str, str]) -> bool:
    return not any(
        XCB006_EXCEPTION_PLACEHOLDER_PATTERN.search(fields.get(field, ""))
        or identifier_tokens(fields.get(field, "")) & XCB006_EXCEPTION_PLACEHOLDER_TOKENS
        for field in XCB006_EXCEPTION_REQUIRED_FIELDS
    )


def xcb006_exact_exception_value(value: str) -> str:
    return value.strip()


def xcb006_rationale_has_allowed_phrase(rationale: str, phrases: set[str]) -> bool:
    normalized = rationale.lower()
    for phrase in phrases:
        phrase_pattern = r"[-_\s]+".join(re.escape(part) for part in phrase.split("_"))
        if re.search(rf"\b(?:not|no|without|non)[-_\s]+{phrase_pattern}\b", normalized):
            return False
        if re.search(
            rf"(?<![A-Za-z0-9_]){phrase_pattern}(?![A-Za-z0-9_])\s*[:=]\s*"
            rf"(?:false|0|no|not|none|without|non)\b",
            normalized,
        ):
            return False
    return any(
        re.search(
            rf"(?<![A-Za-z0-9_])"
            + r"[-_\s]+".join(re.escape(part) for part in phrase.split("_"))
            + r"(?![A-Za-z0-9_])",
            normalized,
        )
        for phrase in phrases
    )


def xcb006_exception_type_fields_are_consistent(exception_type: str, fields: dict[str, str]) -> bool:
    if exception_type != "not-applicable":
        return True
    return (
        xcb006_exact_exception_value(fields.get("redacted_fields", "")) == "none"
        and xcb006_exact_exception_value(fields.get("omitted_fields", "")) == "none"
        and xcb006_exact_exception_value(fields.get("deletion_behavior", "")) == "not_user_owned"
        and xcb006_exact_exception_value(fields.get("export_behavior", "")) == "not_in_user_export"
    )


def xcb006_exception_has_required_rationale(exception_type: str, fields: dict[str, str]) -> bool:
    rationale = fields.get("rationale", "")
    if exception_type == "not-applicable":
        return xcb006_rationale_has_allowed_phrase(rationale, XCB006_NOT_APPLICABLE_RATIONALE_TOKENS)
    if exception_type == "legacy":
        return xcb006_rationale_has_allowed_phrase(rationale, XCB006_LEGACY_RATIONALE_TOKENS)
    return exception_type == "retained-redacted"


def xcb006_line_has_valid_structured_exception(table_name: str, line: str) -> bool:
    exception_type = xcb006_exception_type(line)
    if exception_type is None:
        return False
    if xcb006_exception_has_duplicate_fields(line):
        return False
    fields = xcb006_parse_exception_fields(line)
    if not xcb006_exception_required_fields_present(fields):
        return False
    if xcb006_exception_table_value(fields["table"]) != table_name:
        return False
    if not xcb006_exception_safe_fields_are_safe(fields):
        return False
    if not xcb006_exception_fields_are_actionable(fields):
        return False
    if not xcb006_exception_type_fields_are_consistent(exception_type, fields):
        return False
    return xcb006_exception_has_required_rationale(exception_type, fields)


def xcb006_has_explicit_document_exception(table_name: str, coverage_text: str) -> bool:
    table_pattern = re.compile(rf"(?<![A-Za-z0-9_]){re.escape(table_name)}(?![A-Za-z0-9_])", re.IGNORECASE)
    for line in coverage_text.splitlines():
        if not table_pattern.search(line):
            continue
        has_boundary_context = "XCB-006" in line
        if has_boundary_context and xcb006_line_has_valid_structured_exception(table_name, line):
            return True
    return False


def xcb006_table_has_governance_coverage(
    table_name: str,
    code_coverage_text: str,
    exception_coverage_text: str,
) -> bool:
    return (
        xcb006_has_structured_code_coverage(table_name, code_coverage_text)
        or xcb006_has_explicit_document_exception(table_name, exception_coverage_text)
    )


def check_xcb006_migration_data_governance(
    path: Path,
    text: str,
    coverage_text: str | None = None,
    code_coverage_text: str | None = None,
    exception_coverage_text: str | None = None,
) -> list[Violation]:
    relative = rel(path)
    if not is_migration_file(relative):
        return []
    if coverage_text is not None:
        code_coverage = coverage_text
        exception_coverage = coverage_text
    elif code_coverage_text is not None or exception_coverage_text is not None:
        code_coverage = code_coverage_text or ""
        exception_coverage = exception_coverage_text or ""
    else:
        coverage = xcb006_governance_coverage()
        code_coverage = coverage.code_text
        exception_coverage = coverage.exception_text
    violations: list[Violation] = []
    for match in CREATE_TABLE_PATTERN.finditer(text):
        table_name = normalize_sql_identifier(match.group(1))
        reason = xcb006_sensitive_table_reason(table_name, match.group(2))
        if reason is None:
            continue
        if xcb006_table_has_governance_coverage(table_name, code_coverage, exception_coverage):
            continue
        violations.append(
            Violation(
                "XCB-006",
                relative,
                line_number(text, match.start(1)),
                "New sensitive table "
                + table_name
                + " appears to include "
                + reason
                + " data but is not covered by AccountDeletionService, AiRetentionService, a domain export/retention helper, or a structured XCB-006 retained-redacted, legacy, or not-applicable exception.",
            )
        )
    return violations


def check_xcb006_migration_data_governance_for_paths(paths: list[Path]) -> list[Violation]:
    migration_paths = [path for path in paths if is_migration_file(rel(path))]
    if not migration_paths:
        return []
    coverage = xcb006_governance_coverage()
    staged_coverage = xcb006_staged_governance_coverage()
    staged_paths = set(run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMRT"]))
    violations: list[Violation] = []
    for path in migration_paths:
        relative = rel(path)
        worktree_text = read_text(path) if path.exists() else None
        if worktree_text is not None:
            violations.extend(check_xcb006_migration_data_governance(
                path,
                worktree_text,
                code_coverage_text=coverage.code_text,
                exception_coverage_text=coverage.exception_text,
            ))
        if relative in staged_paths:
            staged_text = read_git_index_text(relative)
            if staged_text is not None:
                violations.extend(check_xcb006_migration_data_governance(
                    path,
                    staged_text,
                    code_coverage_text=staged_coverage.code_text,
                    exception_coverage_text=staged_coverage.exception_text,
                ))
    return list(dict.fromkeys(violations))


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
        violations.extend(check_flutter_commercial_gate_sources(path, text))
        violations.extend(check_flutter_raw_ai_endpoint_paths(path, text))
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
    if args.scope == "changed":
        violations.extend(check_xcb006_migration_data_governance_for_paths(paths))
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
