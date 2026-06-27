#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTH_SERVICE = Path("backend/src/main/java/com/speakeasy/identity/AuthService.java")

REQUIRED_EVIDENCE_REFS = (
    "SMS_PROVIDER_EVIDENCE_REF",
    "PHONE_RISK_PROVIDER_EVIDENCE_REF",
    "CAPTCHA_PROVIDER_EVIDENCE_REF",
    "STEP_UP_PROVIDER_EVIDENCE_REF",
    "HTTPS_ENFORCEMENT_EVIDENCE_REF",
    "OTP_RETENTION_EVIDENCE_REF",
    "APPLE_PROVIDER_VERIFIER_EVIDENCE_REF",
    "WECHAT_PROVIDER_VERIFIER_EVIDENCE_REF",
)

REQUIRED_PROVIDER_CONFIG_REFS = (
    "SMS_PROVIDER_CONFIG_REF",
    "PHONE_RISK_PROVIDER_CONFIG_REF",
    "CAPTCHA_PROVIDER_CONFIG_REF",
    "STEP_UP_PROVIDER_CONFIG_REF",
    "TRUSTED_PROXY_CONFIG_REF",
    "OTP_HMAC_SECRET_REF",
    "APPLE_PROVIDER_CONFIG_REF",
    "WECHAT_PROVIDER_CONFIG_REF",
)

SPRING_PROFILE_ENV_REFS = ("SPRING_PROFILES_ACTIVE", "SPRING_PROFILES_INCLUDE")
DEFAULT_ALLOWED_COUNTRIES = "CN,US"

PHONE_RAW_LOGIN_PATTERN = re.compile(
    r"loginOrCreate\s*\(\s*\"phone\"\s*,\s*phoneNumber\s*\.\s*trim\s*\(",
    re.MULTILINE,
)

PROVIDER_RAW_HASH_PATTERN = re.compile(
    r"loginOrCreate\s*\([^;]*TokenHasher\s*\.\s*hash\s*\(\s*providerToken\s*\)",
    re.MULTILINE | re.DOTALL,
)

OTP_CONSUME_OR_VERIFY_PATTERN = re.compile(
    r"\b(?:\w*otp\w*|\w*challenge\w*)\s*\.\s*(?:\w*consume\w*|\w*verify\w*)\s*\("
    r"|\b(?:\w*consume\w*|\w*verify\w*)\s*\(\s*(?:\w*otp\w*|\w*challenge\w*)",
    re.IGNORECASE,
)

PROVIDER_VERIFY_PATTERN = re.compile(
    r"\b(?:apple|wechat|provider)\w*\s*\.\s*(?:verify|validate)\w*\s*\("
    r"|\b(?:verify|validate)\w*\s*\(\s*(?:apple|wechat|provider)\w*",
    re.IGNORECASE,
)

RAW_PROVIDER_TOKEN_HASH_PATTERN = re.compile(r"TokenHasher\s*\.\s*hash\s*\(\s*providerToken\s*\)", re.MULTILINE)

PLACEHOLDER_VALUE_PATTERN = re.compile(
    r"(^|\b|[_:/.-])(?:todo|tbd|placeholder|example|changeme|dummy|pending|n/?a|none|null|native|test|sandbox|fake|mock|dev|staging|local|nonprod|qa|uat)(\b|[_:/.-]|$)"
    r"|example\.com|localhost|127\.0\.0\.1|0\.0\.0\.0",
    re.IGNORECASE,
)

RAW_CREDENTIAL_ARGUMENT_PATTERN = re.compile(
    r"\b(?:"
    r"\w*(?:provider|identity|id|authorization|wechat|apple)\w*(?:token|code)\w*|"
    r"\w*(?:auth|oauth)\w*code\w*|"
    r"\w*raw\w*(?:token|credential)\w*|"
    r"\w*credential\w*"
    r")\b",
    re.IGNORECASE,
)

RAW_PHONE_ARGUMENT_PATTERN = re.compile(r"\b(phoneNumber|verificationCode)\b")

VERIFIED_SUBJECT_ARGUMENT_PATTERN = re.compile(r"\b(verified|stable|consumed|normalized|e164)\w*|\w*(Subject|Digest)\b")

ASSIGNMENT_PATTERN = re.compile(
    r"(?:^|(?<=[;\n}]))\s*"
    r"(?:(?:final|volatile|transient)\s+)*"
    r"(?:(?:var|[A-Za-z_$][\w$]*(?:\s*<[^;=]+>)?(?:\[\])?)\s+)?"
    r"([A-Za-z_$][\w$]*)\s*=\s*([^;]+);",
    re.MULTILINE,
)

SAFE_BOUNDARY_CALL_PATTERN = re.compile(
    r"\b(?:\w*otp\w*|\w*challenge\w*|\w*apple\w*|\w*wechat\w*|\w*provider\w*)"
    r"\s*\.\s*(?:\w*consume\w*|\w*verify\w*|\w*validate\w*)\s*\([^)]*\)"
    r"|\b(?:\w*consume\w*|\w*verify\w*|\w*validate\w*)\s*\([^)]*\)",
    re.IGNORECASE,
)


def read_text(root: Path, relative_path: Path) -> str:
    path = root / relative_path
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def extract_java_method(source: str, method_name: str) -> str:
    match = re.search(rf"\b{re.escape(method_name)}\s*\(", source)
    if match is None:
        return ""
    open_brace = source.find("{", match.end())
    if open_brace == -1:
        return ""

    depth = 0
    for index in range(open_brace, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[open_brace + 1:index]
    return source[open_brace + 1:]


def strip_java_comments(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    return re.sub(r"//.*", "", source)


def find_matching_paren(source: str, open_paren: int) -> int:
    depth = 0
    in_string: str | None = None
    escaped = False
    for index in range(open_paren, len(source)):
        char = source[index]
        if in_string is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == in_string:
                in_string = None
            continue
        if char in {'"', "'"}:
            in_string = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index
    return -1


def split_top_level_args(argument_text: str) -> list[str]:
    args: list[str] = []
    start = 0
    depth = 0
    in_string: str | None = None
    escaped = False
    for index, char in enumerate(argument_text):
        if in_string is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == in_string:
                in_string = None
            continue
        if char in {'"', "'"}:
            in_string = char
        elif char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            args.append(argument_text[start:index].strip())
            start = index + 1
    trailing = argument_text[start:].strip()
    if trailing:
        args.append(trailing)
    return args


def login_or_create_calls(method_body: str) -> list[tuple[int, list[str]]]:
    calls: list[tuple[int, list[str]]] = []
    search_from = 0
    while True:
        login_index = method_body.find("loginOrCreate", search_from)
        if login_index == -1:
            return calls
        open_paren = method_body.find("(", login_index)
        if open_paren == -1:
            calls.append((login_index, []))
            search_from = login_index + len("loginOrCreate")
            continue
        close_paren = find_matching_paren(method_body, open_paren)
        if close_paren == -1:
            calls.append((login_index, []))
            search_from = open_paren + 1
            continue
        calls.append((login_index, split_top_level_args(method_body[open_paren + 1:close_paren])))
        search_from = close_paren + 1


def unsafe_aliases(before_identity_resolution: str, raw_pattern: re.Pattern[str]) -> set[str]:
    unsafe: set[str] = set()
    changed = True
    while changed:
        changed = False
        for match in ASSIGNMENT_PATTERN.finditer(before_identity_resolution):
            name = match.group(1)
            rhs = match.group(2)
            rhs_without_safe_boundary_calls = SAFE_BOUNDARY_CALL_PATTERN.sub("SAFE_BOUNDARY_CALL", rhs)
            rhs_identifiers = set(re.findall(r"\b[A-Za-z_$][\w$]*\b", rhs_without_safe_boundary_calls))
            if (
                raw_pattern.search(rhs_without_safe_boundary_calls)
                or "TokenHasher" in rhs_without_safe_boundary_calls
                or rhs_identifiers.intersection(unsafe)
            ):
                if name not in unsafe:
                    unsafe.add(name)
                    changed = True
    return unsafe


def argument_references_unsafe_alias(argument: str, unsafe: set[str]) -> bool:
    if not unsafe:
        return False
    identifiers = set(re.findall(r"\b[A-Za-z_$][\w$]*\b", argument))
    return bool(identifiers.intersection(unsafe))


def check_phone_otp_guard(auth_service: str) -> list[str]:
    errors: list[str] = []
    login_phone = strip_java_comments(extract_java_method(auth_service, "loginPhone"))

    if not login_phone:
        errors.append("IDENTITY-RELEASE-001: AuthService.loginPhone is missing; release guard cannot prove OTP challenge consumption.")
        return errors

    if PHONE_RAW_LOGIN_PATTERN.search(login_phone):
        errors.append(
            "IDENTITY-RELEASE-001: AuthService.loginPhone still calls loginOrCreate(\"phone\", phoneNumber.trim(), ...) "
            "without proving a consumed OTP challenge."
        )
        return errors

    calls = login_or_create_calls(login_phone)
    if not calls:
        errors.append(
            "IDENTITY-RELEASE-001: AuthService.loginPhone does not show identity resolution after OTP challenge "
            "consumption; release guard cannot prove the production login path."
        )
        return errors

    for login_index, login_args in calls:
        before_identity_resolution = login_phone[:login_index]
        unsafe_phone_subject_aliases = unsafe_aliases(
            before_identity_resolution,
            RAW_PHONE_ARGUMENT_PATTERN,
        )
        if not OTP_CONSUME_OR_VERIFY_PATTERN.search(before_identity_resolution):
            errors.append(
                "IDENTITY-RELEASE-001: AuthService.loginPhone does not show an OTP challenge verify/consume boundary "
                "before every identity resolution or session issuance path."
            )
            break
        if (
            len(login_args) < 2
            or RAW_PHONE_ARGUMENT_PATTERN.search(login_args[1])
            or argument_references_unsafe_alias(login_args[1], unsafe_phone_subject_aliases)
        ):
            errors.append(
                "IDENTITY-RELEASE-001: AuthService.loginPhone must resolve phone identity from a verified/consumed OTP "
                "subject on every path, not raw phone input."
            )
            break
        if not VERIFIED_SUBJECT_ARGUMENT_PATTERN.search(login_args[1]):
            errors.append(
                "IDENTITY-RELEASE-001: AuthService.loginPhone subject must make the verified/consumed OTP boundary "
                "explicit on every path."
            )
            break

    return errors


def check_provider_subject_guard(auth_service: str) -> list[str]:
    errors: list[str] = []
    login_social = strip_java_comments(extract_java_method(auth_service, "loginSocial"))

    if not login_social:
        errors.append("IDENTITY-RELEASE-002: AuthService.loginSocial is missing; release guard cannot prove provider verification.")
        return errors

    if PROVIDER_RAW_HASH_PATTERN.search(login_social) or "TokenHasher.hash(providerToken)" in login_social:
        errors.append(
            "IDENTITY-RELEASE-002: AuthService.loginSocial still derives provider subject from "
            "TokenHasher.hash(providerToken)."
        )
        return errors
    if RAW_PROVIDER_TOKEN_HASH_PATTERN.search(login_social):
        errors.append(
            "IDENTITY-RELEASE-002: AuthService.loginSocial still hashes raw providerToken before provider verification."
        )
        return errors

    calls = login_or_create_calls(login_social)
    if not calls:
        errors.append(
            "IDENTITY-RELEASE-002: AuthService.loginSocial does not show identity resolution after Apple/WeChat "
            "provider verification; release guard cannot prove the production login path."
        )
        return errors

    for login_index, login_args in calls:
        before_identity_resolution = login_social[:login_index]
        unsafe_provider_subject_aliases = unsafe_aliases(
            before_identity_resolution,
            RAW_CREDENTIAL_ARGUMENT_PATTERN,
        )
        if not PROVIDER_VERIFY_PATTERN.search(before_identity_resolution):
            errors.append(
                "IDENTITY-RELEASE-002: AuthService does not show Apple/WeChat provider verifier usage before every "
                "provider subject derivation path."
            )
            break
        if (
            len(login_args) < 2
            or RAW_CREDENTIAL_ARGUMENT_PATTERN.search(login_args[1])
            or "TokenHasher" in login_args[1]
            or argument_references_unsafe_alias(login_args[1], unsafe_provider_subject_aliases)
        ):
            errors.append(
                "IDENTITY-RELEASE-002: AuthService.loginSocial must resolve identity from a verified stable subject "
                "on every path, not raw provider credentials or TokenHasher output."
            )
            break
        if not VERIFIED_SUBJECT_ARGUMENT_PATTERN.search(login_args[1]):
            errors.append(
                "IDENTITY-RELEASE-002: AuthService.loginSocial subject must make the verified/stable provider subject "
                "boundary explicit on every path."
            )
            break

    return errors


def check_release_refs(env: dict[str, str]) -> list[str]:
    errors: list[str] = []
    for name in REQUIRED_PROVIDER_CONFIG_REFS + REQUIRED_EVIDENCE_REFS:
        value = env.get(name, "").strip()
        if not value:
            errors.append(f"IDENTITY-RELEASE-003: {name} is required before commercial release.")
        elif PLACEHOLDER_VALUE_PATTERN.search(value):
            errors.append(f"IDENTITY-RELEASE-003: {name} must reference real production config/evidence, not {value!r}.")
    return errors


def split_countries(value: str) -> set[str]:
    return {country.strip().upper() for country in re.split(r"[,;\s]+", value) if country.strip()}


def check_phone_risk_country_coverage(env: dict[str, str]) -> list[str]:
    errors: list[str] = []
    allowed = split_countries(env.get("SPEAKEASY_OTP_ALLOWED_COUNTRIES", DEFAULT_ALLOWED_COUNTRIES))
    covered = split_countries(env.get("PHONE_RISK_COVERED_COUNTRIES", ""))
    invalid_allowed = sorted(country for country in allowed if not re.fullmatch(r"[A-Z]{2}", country))
    invalid_covered = sorted(country for country in covered if not re.fullmatch(r"[A-Z]{2}", country))
    if invalid_allowed:
        errors.append(
            "IDENTITY-RELEASE-003: SPEAKEASY_OTP_ALLOWED_COUNTRIES must contain ISO-3166 alpha-2 country codes; "
            f"invalid values: {', '.join(invalid_allowed)}."
        )
    if invalid_covered:
        errors.append(
            "IDENTITY-RELEASE-003: PHONE_RISK_COVERED_COUNTRIES must contain ISO-3166 alpha-2 country codes; "
            f"invalid values: {', '.join(invalid_covered)}."
        )
    missing = sorted(allowed - covered)
    if missing:
        errors.append(
            "IDENTITY-RELEASE-003: PHONE_RISK_COVERED_COUNTRIES must cover every SPEAKEASY_OTP_ALLOWED_COUNTRIES "
            f"value before commercial release; missing: {', '.join(missing)}."
        )
    if "CN" in allowed:
        cn_evidence = env.get("PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF", "").strip()
        if not cn_evidence:
            errors.append("IDENTITY-RELEASE-003: PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF is required when CN/+86 OTP is allowed.")
        elif PLACEHOLDER_VALUE_PATTERN.search(cn_evidence):
            errors.append(
                "IDENTITY-RELEASE-003: PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF must reference real production evidence, "
                f"not {cn_evidence!r}."
            )
    return errors


def split_profiles(value: str) -> set[str]:
    return {profile.strip().lower() for profile in re.split(r"[,;\s]+", value) if profile.strip()}


def check_release_profiles(env: dict[str, str]) -> list[str]:
    errors: list[str] = []
    for name in SPRING_PROFILE_ENV_REFS:
        profiles = split_profiles(env.get(name, ""))
        if "test" in profiles:
            errors.append(f"IDENTITY-RELEASE-004: {name} must not include the Spring test profile for commercial release.")
    return errors


def run_checks(root: Path = ROOT, env: dict[str, str] | None = None) -> list[str]:
    env = dict(os.environ if env is None else env)
    auth_service = read_text(root, AUTH_SERVICE)

    errors: list[str] = []
    if not auth_service:
        errors.append(f"IDENTITY-RELEASE-001: missing backend identity source: {AUTH_SERVICE}")
        errors.append(f"IDENTITY-RELEASE-002: missing backend identity source: {AUTH_SERVICE}")
    else:
        errors.extend(check_phone_otp_guard(auth_service))
        errors.extend(check_provider_subject_guard(auth_service))
    errors.extend(check_release_refs(env))
    errors.extend(check_phone_risk_country_coverage(env))
    errors.extend(check_release_profiles(env))
    return errors


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fail strict release until backend identity trust is production-ready: consumed OTP challenge before phone "
            "login, verified Apple/WeChat stable subject before social login, and real provider config/evidence refs."
        )
    )
    parser.add_argument("--root", type=Path, default=ROOT, help="Repository root to scan.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    errors = run_checks(args.root)
    if errors:
        print("identity release guard failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("identity release guard passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
