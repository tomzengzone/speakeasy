#!/usr/bin/env python3
"""Validate the authentication Prometheus alert contract."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml


DEFAULT_RULES = Path("ops/observability/prometheus/authentication-alerts.yml")
PROJECT_ROOT = Path(__file__).resolve().parents[1]
REQUIRED_ALERTS = {
    "SpeakEasyAuthRefreshFailureRateHigh",
    "SpeakEasyAuthHttp401RateHigh",
    "SpeakEasyAuthTokenReuseDetected",
    "SpeakEasyAuthTokenReuseBurst",
    "SpeakEasyAuthSecurityOperationFailed",
    "SpeakEasyAuthAuditWriteFailed",
    "SpeakEasyAuthEndpointLatencyHigh",
    "SpeakEasyAuthRateLimitBurst",
    "SpeakEasyAuthRateLimitStoreUnavailable",
}
BANNED_LABEL_NAMES = {
    "user",
    "user_id",
    "session",
    "session_id",
    "device",
    "device_id",
    "request",
    "request_id",
    "token",
    "authorization",
    "ip",
}


def load_rules(path: Path) -> list[dict]:
    try:
        document = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as exc:
        raise ValueError(f"cannot load {path}: {exc}") from exc

    if not isinstance(document, dict) or not isinstance(document.get("groups"), list):
        raise ValueError("rules document must contain a groups list")

    rules: list[dict] = []
    for group in document["groups"]:
        if not isinstance(group, dict) or not isinstance(group.get("rules"), list):
            raise ValueError("every group must contain a rules list")
        rules.extend(group["rules"])
    return rules


def compact(expression: str) -> str:
    return re.sub(r"\s+", " ", expression).strip()


def require_fragments(errors: list[str], alert: str, expression: str, fragments: tuple[str, ...]) -> None:
    for fragment in fragments:
        if fragment not in expression:
            errors.append(f"{alert}: expression must contain {fragment!r}")


def validate_backend_dependencies(project_root: Path) -> list[str]:
    errors: list[str] = []
    source_fragments = {
        "backend/src/main/java/com/speakeasy/identity/AuthMetrics.java": (
            'registry.counter("speakeasy.auth.refresh"',
            'registry.counter("speakeasy.auth.http"',
            'registry.counter("speakeasy.auth.token.reuse"',
            'registry.counter("speakeasy.auth.security.operation"',
            'registry.counter(\n        "speakeasy.auth.rate.limit"',
        ),
        "backend/src/main/java/com/speakeasy/identity/AccountSecurityService.java": (
            'monitor("session_revoke"',
            'monitor("account_disable"',
            'metrics.securityOperation(operation, "failure")',
        ),
        "backend/src/main/java/com/speakeasy/ops/AuthAuditService.java": (
            'metrics.securityOperation("audit_write", "failure")',
        ),
        "backend/pom.xml": (
            "<artifactId>micrometer-registry-prometheus</artifactId>",
        ),
    }
    for relative, fragments in source_fragments.items():
        path = project_root / relative
        try:
            contents = path.read_text(encoding="utf-8")
        except OSError as exc:
            errors.append(f"cannot read required metric producer {relative}: {exc}")
            continue
        for fragment in fragments:
            if fragment not in contents:
                errors.append(f"{relative}: missing metric dependency {fragment!r}")

    application_path = project_root / "backend/src/main/resources/application.yml"
    try:
        application = yaml.safe_load(application_path.read_text(encoding="utf-8"))
        metrics = application["management"]["metrics"]
        if metrics["tags"].get("application") != "${spring.application.name}":
            errors.append("application.yml: application metric tag must use spring.application.name")
        histogram_enabled = metrics["distribution"]["percentiles-histogram"].get("http.server.requests")
        if histogram_enabled is not True:
            errors.append("application.yml: http.server.requests percentile histogram must be enabled")
    except (OSError, KeyError, TypeError, yaml.YAMLError) as exc:
        errors.append(f"application.yml: cannot verify authentication metric configuration: {exc}")
    return errors


def validate(path: Path) -> list[str]:
    try:
        rules = load_rules(path)
    except ValueError as exc:
        return [str(exc)]

    errors: list[str] = []
    by_name: dict[str, dict] = {}
    for rule in rules:
        if not isinstance(rule, dict):
            errors.append("every rule must be a mapping")
            continue
        name = rule.get("alert")
        if not isinstance(name, str) or not name:
            errors.append("every rule must have a non-empty alert name")
            continue
        if name in by_name:
            errors.append(f"duplicate alert name: {name}")
        by_name[name] = rule

        expression = rule.get("expr")
        if not isinstance(expression, str) or not expression.strip():
            errors.append(f"{name}: expr must be a non-empty string")
            expression = ""
        if "for" not in rule:
            errors.append(f"{name}: for is required")

        labels = rule.get("labels")
        if not isinstance(labels, dict) or labels.get("severity") not in {"warning", "critical"}:
            errors.append(f"{name}: severity must be warning or critical")
        annotations = rule.get("annotations")
        if not isinstance(annotations, dict):
            errors.append(f"{name}: annotations must be a mapping")
        else:
            if not annotations.get("summary"):
                errors.append(f"{name}: summary annotation is required")
            if not annotations.get("runbook_url"):
                errors.append(f"{name}: runbook_url annotation is required")

        serialized_labels = " ".join(
            str(key) for key in (labels or {}).keys()
        )
        expression_label_names = re.findall(r"([A-Za-z_][A-Za-z0-9_]*)\s*(?:=|!=|=~|!~)", expression)
        for label_name in set(expression_label_names + serialized_labels.split()):
            if label_name.lower() in BANNED_LABEL_NAMES:
                errors.append(f"{name}: forbidden high-cardinality label {label_name!r}")

    missing = REQUIRED_ALERTS - set(by_name)
    unexpected = set(by_name) - REQUIRED_ALERTS
    if missing:
        errors.append(f"missing required alerts: {', '.join(sorted(missing))}")
    if unexpected:
        errors.append(f"unexpected alerts: {', '.join(sorted(unexpected))}")

    expressions = {
        name: compact(str(rule.get("expr", ""))) for name, rule in by_name.items()
    }
    if "SpeakEasyAuthRefreshFailureRateHigh" in expressions:
        require_fragments(errors, "SpeakEasyAuthRefreshFailureRateHigh", expressions["SpeakEasyAuthRefreshFailureRateHigh"], (
            "speakeasy_auth_refresh_total", "[10m]", "> 0.05", ">= 100",
        ))
    if "SpeakEasyAuthHttp401RateHigh" in expressions:
        require_fragments(errors, "SpeakEasyAuthHttp401RateHigh", expressions["SpeakEasyAuthHttp401RateHigh"], (
            "speakeasy_auth_http_total", 'api_family="bearer"', 'outcome="unauthorized"', "[10m]", "> 0.03", ">= 100",
        ))
    if "SpeakEasyAuthTokenReuseDetected" in expressions:
        require_fragments(errors, "SpeakEasyAuthTokenReuseDetected", expressions["SpeakEasyAuthTokenReuseDetected"], (
            "speakeasy_auth_token_reuse_total", "[5m]", ">= 1", "< 3",
        ))
    if "SpeakEasyAuthTokenReuseBurst" in expressions:
        require_fragments(errors, "SpeakEasyAuthTokenReuseBurst", expressions["SpeakEasyAuthTokenReuseBurst"], (
            "speakeasy_auth_token_reuse_total", "[5m]", ">= 3",
        ))
    if "SpeakEasyAuthSecurityOperationFailed" in expressions:
        require_fragments(errors, "SpeakEasyAuthSecurityOperationFailed", expressions["SpeakEasyAuthSecurityOperationFailed"], (
            "speakeasy_auth_security_operation_total", 'operation=~"session_revoke|account_disable"', 'outcome="failure"', "[5m]", "> 0",
        ))
    if "SpeakEasyAuthAuditWriteFailed" in expressions:
        require_fragments(errors, "SpeakEasyAuthAuditWriteFailed", expressions["SpeakEasyAuthAuditWriteFailed"], (
            "speakeasy_auth_security_operation_total", 'operation="audit_write"', 'outcome="failure"', "[5m]", "> 0",
        ))
    if "SpeakEasyAuthEndpointLatencyHigh" in expressions:
        require_fragments(errors, "SpeakEasyAuthEndpointLatencyHigh", expressions["SpeakEasyAuthEndpointLatencyHigh"], (
            "histogram_quantile( 0.95", "http_server_requests_seconds_bucket", "[5m]", "> 0.5",
        ))
        if str(by_name["SpeakEasyAuthEndpointLatencyHigh"].get("for")) != "10m":
            errors.append("SpeakEasyAuthEndpointLatencyHigh: for must be 10m")
    if "SpeakEasyAuthRateLimitBurst" in expressions:
        require_fragments(errors, "SpeakEasyAuthRateLimitBurst", expressions["SpeakEasyAuthRateLimitBurst"], (
            "speakeasy_auth_rate_limit_total", 'outcome="blocked"', "[5m]", ">= 100",
        ))
    if "SpeakEasyAuthRateLimitStoreUnavailable" in expressions:
        require_fragments(
            errors,
            "SpeakEasyAuthRateLimitStoreUnavailable",
            expressions["SpeakEasyAuthRateLimitStoreUnavailable"],
            ("speakeasy_auth_rate_limit_total", 'dimension="store"', 'outcome="unavailable"', "[5m]", "> 0"),
        )

    errors.extend(validate_backend_dependencies(PROJECT_ROOT))
    return errors


def run_promtool(path: Path, executable: str) -> int:
    result = subprocess.run(
        [executable, "check", "rules", str(path)],
        check=False,
        text=True,
    )
    return result.returncode


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rules", nargs="?", type=Path, default=DEFAULT_RULES)
    parser.add_argument(
        "--promtool",
        nargs="?",
        const="promtool",
        help="also run Prometheus promtool (optionally provide its executable path)",
    )
    args = parser.parse_args()

    errors = validate(args.rules)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"Authentication alert contract OK: {args.rules}")
    if args.promtool:
        executable = shutil.which(args.promtool) if args.promtool == "promtool" else args.promtool
        if not executable:
            print("ERROR: promtool executable was not found", file=sys.stderr)
            return 1
        return run_promtool(args.rules, executable)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
