#!/usr/bin/env python3
"""Validate commercial copy against shipped P0 subscription benefits."""

from __future__ import annotations

import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

MEMBERSHIP_PAGE = ROOT / "lib/pages/membership_page.dart"
PROFILE_PAGE = ROOT / "lib/pages/profile_page.dart"
GOAL_AUTOPILOT_PANEL = ROOT / "lib/features/goal_autopilot/goal_autopilot_panel.dart"
PAYMENT_CONFIG = ROOT / "lib/config/payment_config.dart"
RELEASE_CHECKLIST = ROOT / "docs/release/release_checklist.md"
RELEASE_RUNBOOK = ROOT / "docs/release/commercial_release_runbook.md"

REQUIRED_MEMBERSHIP_BENEFITS = (
    "高级场景 L3",
    "完整句型库",
    "AI 深度反馈",
    "沉浸式对话",
    "更高 AI 练习额度",
    "订阅状态同步",
)

PROHIBITED_MEMBERSHIP_PROMISES = (
    "离线学习包",
    "离线内容包",
    "专属学习报告",
    "无限场景练习",
    "终身会员",
)

REQUIRED_GOAL_AUTOPILOT_PRIVACY_COPY = (
    "Privacy and controls",
    "Goal, diagnostic, plan, reminder, forecast, checkpoint and progress facts are used for product-internal training surfaces.",
    "Export, account deletion and retention follow backend data-governance rules.",
    "Raw audio, raw transcripts, provider payloads, idempotency keys and notification payloads stay out of this surface.",
    "Reminder prompts are blocked until backend consent is on.",
)

PROHIBITED_GOAL_AUTOPILOT_PROMISES = (
    "guaranteed achievement",
    "official-score equivalence",
    "unlimited AI",
    "unlimited checkpoint",
    "release approved",
)

REQUIRED_PLAN_IDS = ("weekly", "monthly", "yearly")
REQUIRED_PRODUCT_IDS = (
    "com.speakeasy.plan.weekly",
    "com.speakeasy.plan.monthly",
    "com.speakeasy.plan.yearly",
)

EXTERNAL_EVIDENCE_KEYS = (
    "STORE_METADATA_EVIDENCE_REF",
    "PRIVACY_URL",
    "SUPPORT_URL",
)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(f"missing required file: {path.relative_to(ROOT)}")
        return ""


errors: list[str] = []
release_blockers: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def require_contains(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"{label} must contain {needle!r}")


def require_absent(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"{label} must not promise unavailable benefit {needle!r}")


def main(argv: list[str]) -> int:
    strict_external = "--strict-external" in argv

    membership = read(MEMBERSHIP_PAGE)
    profile = read(PROFILE_PAGE)
    goal_autopilot_panel = read(GOAL_AUTOPILOT_PANEL)
    payment_config = read(PAYMENT_CONFIG)
    release_checklist = read(RELEASE_CHECKLIST)
    release_runbook = read(RELEASE_RUNBOOK)

    for benefit in REQUIRED_MEMBERSHIP_BENEFITS:
        require_contains(membership, benefit, "MembershipPage")

    for phrase in PROHIBITED_MEMBERSHIP_PROMISES:
        require_absent(membership, phrase, "MembershipPage")

    require_absent(profile, "解锁无限场景练习", "Profile membership upsell")
    require_contains(profile, "解锁 L3 高级场景、完整句型库和更高 AI 练习额度", "Profile membership upsell")

    for copy in REQUIRED_GOAL_AUTOPILOT_PRIVACY_COPY:
        require_contains(goal_autopilot_panel, copy, "Goal autopilot privacy copy")

    for phrase in PROHIBITED_GOAL_AUTOPILOT_PROMISES:
        require_absent(goal_autopilot_panel, phrase, "Goal autopilot privacy copy")

    for plan_id in REQUIRED_PLAN_IDS:
        require_contains(payment_config, f"{plan_id}PlanId", "PaymentConfig")

    for product_id in REQUIRED_PRODUCT_IDS:
        require_contains(payment_config, product_id, "PaymentConfig")

    require_contains(release_checklist, "TC-COM-015", "Release checklist")
    require_contains(release_checklist, "TC-COM-016", "Release checklist")
    require_contains(release_runbook, "scripts/check_commercial_copy_contract.py", "Release runbook")
    require_contains(release_runbook, "TC-COM-015", "Release runbook")
    require_contains(release_runbook, "TC-COM-016", "Release runbook")

    for key in EXTERNAL_EVIDENCE_KEYS:
        value = os.environ.get(key, "").strip()
        if not value:
            release_blockers.append(f"{key} is required to close external store/privacy copy evidence")
        elif key.endswith("_URL") and not value.startswith("https://"):
            fail(f"{key} must use https")

    if release_blockers and strict_external:
        errors.extend(release_blockers)

    if errors:
        print("commercial copy contract check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("commercial copy contract check passed")
    if release_blockers:
        print("release blockers:")
        for blocker in release_blockers:
            print(f"- {blocker}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
