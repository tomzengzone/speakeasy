#!/usr/bin/env python3
"""Validate that the manual external evidence checklist covers remaining blockers."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKLIST = ROOT / "tests/commercial/manual_external_evidence_checklist.md"

REQUIRED_TCS = (
    "TC-COM-012",
    "TC-COM-015",
    "TC-COM-019",
    "TC-COM-021",
    "TC-COM-022",
)

REQUIRED_RESULT_FIELDS = (
    "Execution ID",
    "TC ID",
    "Scenario ID",
    "Executor",
    "Execution date",
    "Environment",
    "Build tag / commit",
    "Device / OS",
    "Account / vault ref",
    "Evidence ref",
    "Expected result",
    "Actual result",
    "Failure / blocker reason",
    "Reviewer",
    "Review result",
)

REQUIRED_SCENARIOS = (
    "COPY-IN-APP",
    "COPY-STORE",
    "COPY-PRIVACY-SUPPORT",
    "COPY-STRICT-GATE",
    "APPLE-PURCHASE",
    "APPLE-RESTORE",
    "APPLE-REFUND-REVOKE",
    "APPLE-EXPIRY",
    "APPLE-GRACE-PERIOD",
    "APPLE-ACCOUNT-SWITCH",
    "GOOGLE-PURCHASE",
    "GOOGLE-RESTORE",
    "GOOGLE-REFUND-REVOKE",
    "GOOGLE-EXPIRY",
    "GOOGLE-GRACE-PERIOD",
    "GOOGLE-ACCOUNT-SWITCH",
    "STORE-APPSTORE-METADATA",
    "STORE-PLAY-METADATA",
    "STORE-SUBSCRIPTION-PRODUCTS",
    "STORE-SUBSCRIPTION-TERMS",
    "STORE-PRIVACY-DATA-SAFETY",
    "STORE-PRIVACY-URL",
    "STORE-SUPPORT-URL",
    "STORE-REVIEWER-ACCOUNT",
    "STORE-STRICT-GATE",
    "NATIVE-WECHAT-IOS",
    "NATIVE-WECHAT-ANDROID",
    "NATIVE-APPLE-SIGN-IN",
    "NATIVE-SOCIAL-SMOKE",
    "NATIVE-STRICT-GATE",
    "REL-SECRETS",
    "REL-SIGNING",
    "REL-SYMBOLS",
    "REL-ROLLBACK",
    "REL-STRICT-GATE",
    "REL-FINAL-REVIEW",
)

REQUIRED_COMMANDS = (
    "python3 scripts/check_commercial_copy_contract.py --strict-external",
    "python3 scripts/check_provider_sandbox_evidence.py --strict-external",
    "python3 scripts/check_store_submission_evidence.py --strict-external",
    "scripts/check_social_login_release_config.sh",
    "scripts/check_release_readiness.sh",
)

REQUIRED_REFS = (
    "APPLE_SANDBOX_EVIDENCE_REF",
    "GOOGLE_PLAY_INTERNAL_EVIDENCE_REF",
    "STORE_METADATA_EVIDENCE_REF",
    "REVIEWER_ACCOUNT_REF",
    "PRIVACY_URL",
    "SUPPORT_URL",
    "SYMBOL_UPLOAD_EVIDENCE_REF",
    "ROLLBACK_REHEARSAL_REF",
)


def main() -> int:
    errors: list[str] = []

    try:
        text = CHECKLIST.read_text(encoding="utf-8")
    except FileNotFoundError:
        print(
            f"manual external evidence plan check failed:\n- missing checklist: {CHECKLIST.relative_to(ROOT)}",
            file=sys.stderr,
        )
        return 1

    for item in (
        *REQUIRED_TCS,
        *REQUIRED_RESULT_FIELDS,
        *REQUIRED_SCENARIOS,
        *REQUIRED_COMMANDS,
        *REQUIRED_REFS,
    ):
        if item not in text:
            errors.append(f"missing required checklist item: {item}")

    if "不得把 Apple、Google、WeChat、Sentry、签名、审核账号、沙盒账号或用户账号密钥提交到仓库" not in text:
        errors.append("checklist must explicitly prohibit committing external secrets or credentials")

    if "Actual result | `pending` / `passed` / `failed` / `blocked`" not in text:
        errors.append("checklist must define allowed actual result states")

    if errors:
        print("manual external evidence plan check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("manual external evidence plan check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
