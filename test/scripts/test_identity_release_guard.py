from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/check_identity_release_guard.py"
SPEC = importlib.util.spec_from_file_location("check_identity_release_guard", SCRIPT)
assert SPEC is not None
guard = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules["check_identity_release_guard"] = guard
SPEC.loader.exec_module(guard)


VALID_RELEASE_REFS = {
    "SMS_PROVIDER_CONFIG_REF": "vault://prod/identity/sms/alibaba-cloud",
    "PHONE_RISK_PROVIDER_CONFIG_REF": "vault://prod/identity/phone-risk/twilio-lookup",
    "CAPTCHA_PROVIDER_CONFIG_REF": "vault://prod/identity/captcha/turnstile",
    "STEP_UP_PROVIDER_CONFIG_REF": "vault://prod/identity/step-up/webauthn",
    "TRUSTED_PROXY_CONFIG_REF": "vault://prod/identity/network/trusted-proxy",
    "OTP_HMAC_SECRET_REF": "vault://prod/identity/otp/hmac-secret",
    "APPLE_PROVIDER_CONFIG_REF": "vault://prod/identity/apple-provider",
    "WECHAT_PROVIDER_CONFIG_REF": "vault://prod/identity/wechat-provider",
    "SPEAKEASY_OTP_ALLOWED_COUNTRIES": "CN,US",
    "PHONE_RISK_COVERED_COUNTRIES": "CN,US",
    "SMS_PROVIDER_EVIDENCE_REF": "evidence://identity/otp/sms-provider/2026-06-25/run-001",
    "PHONE_RISK_PROVIDER_EVIDENCE_REF": "evidence://identity/otp/phone-risk/2026-06-25/run-001",
    "PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF": "evidence://identity/otp/phone-risk/cn-sim-swap/2026-06-25/run-001",
    "CAPTCHA_PROVIDER_EVIDENCE_REF": "evidence://identity/otp/captcha/2026-06-25/run-001",
    "STEP_UP_PROVIDER_EVIDENCE_REF": "evidence://identity/otp/step-up/2026-06-25/run-001",
    "HTTPS_ENFORCEMENT_EVIDENCE_REF": "evidence://identity/otp/https/2026-06-25/run-001",
    "OTP_RETENTION_EVIDENCE_REF": "evidence://identity/otp/retention/2026-06-25/run-001",
    "APPLE_PROVIDER_VERIFIER_EVIDENCE_REF": "evidence://identity/social/apple-verifier/2026-06-25/run-001",
    "WECHAT_PROVIDER_VERIFIER_EVIDENCE_REF": "evidence://identity/social/wechat-verifier/2026-06-25/run-001",
}

SAFE_PHONE = """
    var consumedOtp = otpChallenge.consume(verificationCode);
    final String consumedSubject = consumedOtp.normalizedPhone();
    return loginOrCreate("phone", consumedSubject, "Phone User");
"""

SAFE_SOCIAL = """
    var verifiedProvider = providerVerifier.verify(providerToken);
    final String stableSubject = verifiedProvider.stableSubject();
    return loginOrCreate(provider, stableSubject, provider + " User");
"""


class IdentityReleaseGuardTest(unittest.TestCase):
    def run_fixture(self, phone_body: str = SAFE_PHONE, social_body: str = SAFE_SOCIAL, env: dict[str, str] | None = None) -> list[str]:
        source = f"""
package com.speakeasy.identity;

class AuthService {{
  AuthSessionResult loginPhone(String phoneNumber, String verificationCode, boolean termsAccepted) {{
{phone_body}
  }}

  AuthSessionResult loginSocial(String provider, String providerToken, boolean termsAccepted) {{
{social_body}
  }}
}}
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = root / guard.AUTH_SERVICE
            path.parent.mkdir(parents=True)
            path.write_text(source, encoding="utf-8")
            return guard.run_checks(root, VALID_RELEASE_REFS if env is None else env)

    def test_current_repository_identity_guard_fails_only_on_remaining_release_blockers(self) -> None:
        errors = guard.run_checks(ROOT, {})

        self.assertFalse(any("IDENTITY-RELEASE-001" in error for error in errors))
        self.assertTrue(any("IDENTITY-RELEASE-002" in error for error in errors))
        self.assertTrue(any("IDENTITY-RELEASE-003" in error for error in errors))

    def test_safe_fixture_passes_with_production_refs(self) -> None:
        self.assertEqual(self.run_fixture(), [])

    def test_missing_release_refs_fail(self) -> None:
        errors = self.run_fixture(env={})

        self.assertGreaterEqual(sum("IDENTITY-RELEASE-003" in error for error in errors), 18)

    def test_placeholder_release_refs_fail(self) -> None:
        env = {
            **VALID_RELEASE_REFS,
            "SMS_PROVIDER_CONFIG_REF": "fake-sms-config",
            "PHONE_RISK_PROVIDER_CONFIG_REF": "mock-risk-config",
            "CAPTCHA_PROVIDER_EVIDENCE_REF": "captcha-placeholder-evidence",
            "APPLE_PROVIDER_CONFIG_REF": "mock-apple-config",
            "WECHAT_PROVIDER_CONFIG_REF": "dev-wechat-config",
            "WECHAT_PROVIDER_VERIFIER_EVIDENCE_REF": "staging-provider-evidence",
        }

        errors = self.run_fixture(env=env)

        self.assertEqual(sum("IDENTITY-RELEASE-003" in error for error in errors), 6)

    def test_phone_risk_coverage_must_match_allowed_countries(self) -> None:
        env = {
            **VALID_RELEASE_REFS,
            "SPEAKEASY_OTP_ALLOWED_COUNTRIES": "CN,US",
            "PHONE_RISK_COVERED_COUNTRIES": "US",
        }

        errors = self.run_fixture(env=env)

        self.assertTrue(any("PHONE_RISK_COVERED_COUNTRIES" in error and "CN" in error for error in errors))

    def test_cn_allowed_requires_cn_sim_swap_evidence(self) -> None:
        env = {
            **VALID_RELEASE_REFS,
            "PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF": "",
        }

        errors = self.run_fixture(env=env)

        self.assertTrue(any("PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF" in error for error in errors))

    def test_test_spring_profile_fails_release_guard(self) -> None:
        errors = self.run_fixture(env={**VALID_RELEASE_REFS, "SPRING_PROFILES_ACTIVE": "production,test"})

        self.assertTrue(any("IDENTITY-RELEASE-004" in error for error in errors))

    def test_phone_raw_alias_after_otp_consume_fails(self) -> None:
        errors = self.run_fixture(
            phone_body="""
    otpChallenge.verify(verificationCode);
    final String verifiedSubject = phoneNumber.trim();
    return loginOrCreate("phone", verifiedSubject, "Phone User");
"""
        )

        self.assertTrue(any("IDENTITY-RELEASE-001" in error for error in errors))

    def test_social_raw_credential_alias_after_provider_verify_fails(self) -> None:
        errors = self.run_fixture(
            social_body="""
    providerVerifier.verify(providerToken);
    final String verifiedSubject = providerToken;
    return loginOrCreate(provider, verifiedSubject, provider + " User");
"""
        )

        self.assertTrue(any("IDENTITY-RELEASE-002" in error for error in errors))

    def test_social_token_hasher_alias_after_provider_verify_fails(self) -> None:
        errors = self.run_fixture(
            social_body="""
    appleVerifier.verify(identityToken);
    final String stableSubjectDigest = TokenHasher.hash(identityToken);
    return loginOrCreate(provider, stableSubjectDigest, provider + " User");
"""
        )

        self.assertTrue(any("IDENTITY-RELEASE-002" in error for error in errors))

    def test_social_auth_code_alias_after_provider_verify_fails(self) -> None:
        errors = self.run_fixture(
            social_body="""
    providerVerifier.verify(provider, authCode);
    var verifiedProviderSubject = authCode;
    return loginOrCreate(provider, verifiedProviderSubject, provider + " User");
"""
        )

        self.assertTrue(any("IDENTITY-RELEASE-002" in error for error in errors))

    def test_second_login_or_create_path_must_also_be_safe(self) -> None:
        errors = self.run_fixture(
            phone_body="""
    var consumedOtp = otpChallenge.consume(verificationCode);
    final String consumedSubject = consumedOtp.normalizedPhone();
    if (termsAccepted) {
      return loginOrCreate("phone", consumedSubject, "Phone User");
    }
    final String verifiedSubject = phoneNumber.trim();
    return loginOrCreate("phone", verifiedSubject, "Phone User");
"""
        )

        self.assertTrue(any("IDENTITY-RELEASE-001" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
