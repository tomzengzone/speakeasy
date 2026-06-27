#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, TextIO

E164_RE = re.compile(r"^\+[1-9]\d{7,14}$")
CN_MOBILE_RE = re.compile(r"^1[3-9]\d{9}$")
US_NANP_RE = re.compile(r"^[2-9]\d{2}[2-9]\d{6}$")

COUNTRY_CODES = {
    "1": "US",
    "86": "CN",
}


@dataclass(frozen=True)
class PhoneIdentityRow:
    auth_identity_id: str
    user_id: str
    provider: str
    provider_subject: str
    status: str


@dataclass(frozen=True)
class AuditResult:
    row: PhoneIdentityRow
    normalized_subject: str
    country: str
    action: str
    reason: str


def clean_subject(value: str) -> str:
    return re.sub(r"[\s().-]+", "", value.strip())


def country_for_e164(value: str) -> str:
    digits = value[1:]
    for width in (2, 1):
        country = COUNTRY_CODES.get(digits[:width])
        if country:
            return country
    return "unsupported"


def normalize_subject(subject: str, default_region: str, audit_countries: set[str]) -> tuple[str, str, str, str]:
    cleaned = clean_subject(subject)
    if E164_RE.fullmatch(cleaned):
        country = country_for_e164(cleaned)
        if country in audit_countries:
            return cleaned, country, "already_e164", "subject is already supported E.164"
        return cleaned, country, "unsupported_country", "E.164 country is not in audit allowlist"

    digits = re.sub(r"\D+", "", cleaned)
    if default_region == "CN" and CN_MOBILE_RE.fullmatch(digits):
        normalized = "+86" + digits
        return normalized, "CN", "normalize_default_region", "CN domestic mobile subject can normalize to E.164"
    if default_region == "US" and US_NANP_RE.fullmatch(digits):
        normalized = "+1" + digits
        return normalized, "US", "normalize_default_region", "US NANP subject can normalize to E.164"

    return "", "unknown", "invalid_format", "subject is not E.164 and does not match default region"


def read_rows(handle: TextIO) -> list[PhoneIdentityRow]:
    reader = csv.DictReader(handle)
    required = {"auth_identity_id", "user_id", "provider", "provider_subject", "status"}
    missing = required.difference(reader.fieldnames or [])
    if missing:
        raise ValueError("CSV is missing required columns: " + ", ".join(sorted(missing)))

    rows: list[PhoneIdentityRow] = []
    for record in reader:
        provider = (record.get("provider") or "").strip()
        if provider != "phone":
            continue
        rows.append(PhoneIdentityRow(
            auth_identity_id=(record.get("auth_identity_id") or "").strip(),
            user_id=(record.get("user_id") or "").strip(),
            provider=provider,
            provider_subject=(record.get("provider_subject") or "").strip(),
            status=(record.get("status") or "").strip(),
        ))
    return rows


def audit_rows(rows: Iterable[PhoneIdentityRow], default_region: str, audit_countries: set[str]) -> list[AuditResult]:
    results = []
    for row in rows:
        normalized, country, action, reason = normalize_subject(row.provider_subject, default_region, audit_countries)
        results.append(AuditResult(row, normalized, country, action, reason))
    return results


def conflict_keys(results: Iterable[AuditResult]) -> set[str]:
    by_subject: dict[str, list[AuditResult]] = defaultdict(list)
    for result in results:
        if result.normalized_subject:
            by_subject[result.normalized_subject].append(result)
    return {subject for subject, subject_results in by_subject.items() if len(subject_results) > 1}


def conflict_reason(subject: str, results: Iterable[AuditResult]) -> str:
    subject_results = [result for result in results if result.normalized_subject == subject]
    if len(subject_results) <= 1:
        return "none"
    user_ids = {result.row.user_id for result in subject_results}
    if len(user_ids) > 1:
        return "cross_user_ownership_conflict"
    return "same_user_unique_key_duplicate"


def render_markdown(results: list[AuditResult], default_region: str, audit_countries: set[str]) -> str:
    conflicts = conflict_keys(results)
    counts = Counter(result.action for result in results)
    conflict_count = sum(1 for result in results if result.normalized_subject in conflicts)
    lines = [
        "# Phone Identity Subject Audit Dry Run",
        "",
        "## Scope",
        f"- Default region: `{default_region}`",
        f"- Audit countries: `{', '.join(sorted(audit_countries))}`",
        "- Source: exported `auth_identities` rows where `provider='phone'`.",
        "- This dry run does not modify database rows.",
        "- Audit countries are dry-run coverage only; they are not a production allowlist.",
        "- E.164 checks are syntax-level dry-run checks; backend implementation must revalidate with libphonenumber.",
        "",
        "## Summary",
        "| Metric | Count |",
        "| --- | --- |",
        f"| phone identity rows | {len(results)} |",
        f"| already E.164 | {counts['already_e164']} |",
        f"| normalizable by default region | {counts['normalize_default_region']} |",
        f"| unsupported country | {counts['unsupported_country']} |",
        f"| invalid format | {counts['invalid_format']} |",
        f"| rows in normalized-subject conflicts | {conflict_count} |",
        "",
        "## Row Actions",
        "| auth_identity_id | user_id | original_subject | normalized_subject | country | action | reason | conflict | conflict_reason |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for result in results:
        conflict = "yes" if result.normalized_subject in conflicts else "no"
        conflict_detail = conflict_reason(result.normalized_subject, results) if conflict == "yes" else "none"
        lines.append(
            "| {auth} | {user} | `{original}` | `{normalized}` | {country} | {action} | {reason} | {conflict} | {conflict_detail} |".format(
                auth=result.row.auth_identity_id or "unknown",
                user=result.row.user_id or "unknown",
                original=result.row.provider_subject,
                normalized=result.normalized_subject or "N/A",
                country=result.country,
                action=result.action,
                reason=result.reason,
                conflict=conflict,
                conflict_detail=conflict_detail,
            )
        )

    lines.extend([
        "",
        "## Gate Recommendation",
    ])
    if conflicts or counts["invalid_format"] or counts["unsupported_country"]:
        lines.append("- Result: `blocked`.")
        lines.append("- Do not run a write migration until normalized-subject duplicates, invalid formats and unsupported countries are resolved.")
    else:
        lines.append("- Result: `ready_for_review`.")
        lines.append("- A write migration may be designed from this dry-run output and reviewed separately.")
    return "\n".join(lines) + "\n"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit phone auth identity subjects before E.164 migration.")
    parser.add_argument("csv_path", nargs="?", help="CSV export path. Reads stdin when omitted.")
    parser.add_argument("--default-region", choices=("CN", "US"), default="CN")
    parser.add_argument("--audit-country", action="append", dest="audit_countries", choices=("CN", "US"), default=None)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    audit_countries = set(args.audit_countries or [args.default_region])
    try:
        if args.csv_path:
            with Path(args.csv_path).open(newline="", encoding="utf-8") as handle:
                rows = read_rows(handle)
        else:
            rows = read_rows(sys.stdin)
        results = audit_rows(rows, args.default_region, audit_countries)
    except (OSError, ValueError) as exception:
        print(f"phone identity audit failed: {exception}", file=sys.stderr)
        return 2

    sys.stdout.write(render_markdown(results, args.default_region, audit_countries))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
