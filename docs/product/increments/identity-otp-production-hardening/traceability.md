# Traceability：Identity OTP Production Hardening

## 状态
Backend API/DB/domain/core evidence 已补充。后端切片的 Code Evidence 和 Test Evidence 记录如下；provider evidence、release evidence、Dart client drift 和 social provider verifier closure 仍为 pending，不能解读为商业发布批准。

## 上游链路
```text
docs/product/base/identity-account-lifecycle/requirements.md
  -> docs/product/base/identity-account-lifecycle/spec.md
  -> docs/product/increments/identity-otp-production-hardening/definition.md
  -> docs/product/increments/identity-otp-production-hardening/requirements.md
  -> docs/product/increments/identity-otp-production-hardening/spec.md
  -> docs/product/increments/identity-otp-production-hardening/acceptance.md
  -> docs/product/increments/identity-otp-production-hardening/test_cases.md
  -> docs/product/increments/identity-otp-production-hardening/traceability.md
```

## Provider And Release Evidence Registry
| Evidence boundary | Required reference | Owning requirement(s) | Status |
| --- | --- | --- | --- |
| SMS provider config | `SMS_PROVIDER_CONFIG_REF` | 023, 024, 025 | Pending |
| SMS provider evidence | `SMS_PROVIDER_EVIDENCE_REF` | 023, 024, 025 | Pending |
| Phone risk provider config | `PHONE_RISK_PROVIDER_CONFIG_REF` | 028, 035, 036 | Pending |
| Phone risk provider evidence | `PHONE_RISK_PROVIDER_EVIDENCE_REF` | 028, 035, 036 | Pending |
| Phone risk covered countries | `PHONE_RISK_COVERED_COUNTRIES` | 028, 035, 036 | Pending |
| `CN` SIM-swap evidence | `PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF` | 028, 035, 036 | Pending |
| CAPTCHA provider config | `CAPTCHA_PROVIDER_CONFIG_REF` | 029 | Pending |
| CAPTCHA provider evidence | `CAPTCHA_PROVIDER_EVIDENCE_REF` | 029 | Pending |
| Step-up provider config | `STEP_UP_PROVIDER_CONFIG_REF` | 036 | Pending |
| Step-up provider evidence | `STEP_UP_PROVIDER_EVIDENCE_REF` | 036 | Pending |
| HTTPS enforcement evidence | `HTTPS_ENFORCEMENT_EVIDENCE_REF` | 026 | Pending |
| Trusted proxy config | `TRUSTED_PROXY_CONFIG_REF` | 026 | Pending |
| OTP HMAC secret | `OTP_HMAC_SECRET_REF` | 010 | Pending |
| OTP retention evidence | `OTP_RETENTION_EVIDENCE_REF` | 030, 037 | Pending |

## Second Batch Audit Artifacts
| Artifact | Purpose | Related rows | Status |
| --- | --- | --- | --- |
| `scripts/audit_phone_identity_subjects.py` | Dry-run audit for existing `AuthIdentity(provider='phone')` subjects before E.164 migration; it does not write DB rows and does not count as production normalization implementation. | OTP-PROD-TR-004, OTP-PROD-TR-020 | Added |
| `test/scripts/test_audit_phone_identity_subjects.py` | Unit tests for dry-run classification, conflict detection and malformed CSV handling. | OTP-PROD-TR-004, OTP-PROD-TR-020 | Added |
| `docs/product/increments/identity-otp-production-hardening/spec.md#phone-identity-migration-dry-run` | Migration dry-run command, conflict policy, rollback policy, default region and allowlist decisions. | OTP-PROD-TR-004, OTP-PROD-TR-020 | Added |

这些 artifacts 是第二批 planning 和 migration-readiness evidence；它们不会把 Product Base OTP rows 从 `Pending` 移动到 `Implemented`。

## Third Batch Backend API/DB/Domain/Core Artifacts
| Artifact | Purpose | Related rows | Status |
| --- | --- | --- | --- |
| `backend/src/main/resources/db/migration/V202606250032__identity_otp_persistence.sql` | Adds `otp_challenges`, `otp_rate_counters`, and `otp_failure_locks` for pending/active/consumed challenge lifecycle, rate counters, failure locks and retention cleanup state. | OTP-PROD-TR-005..018, OTP-PROD-TR-030, OTP-PROD-TR-037 | Added |
| `backend/src/main/java/com/speakeasy/identity/OtpChallenge*.java`, `OtpRateCounter*.java`, `OtpFailureLock*.java` | JPA domain/persistence model for OTP challenge state, risk/step-up state, atomic lookup and cleanup queries. | OTP-PROD-TR-006, OTP-PROD-TR-012..018, OTP-PROD-TR-030 | Added |
| `backend/src/main/java/com/speakeasy/identity/OtpService.java` | Backend OTP send, pending challenge activation after provider success, verify/consume, resend invalidation, failure locking, risk/CAPTCHA/secure-transport policy gates, audit and retention cleanup core. | OTP-PROD-TR-004..030, OTP-PROD-TR-032..037 | Added |
| `backend/src/main/java/com/speakeasy/identity/OtpPhoneRiskProvider.java`, `ConfiguredOtpPhoneRiskProvider.java` | Phone-risk provider boundary used by OTP send; current backend slice supplies configurable allow/block/step_up fixtures while production provider and country coverage evidence remain release-gated. | OTP-PROD-TR-028, OTP-PROD-TR-035, OTP-PROD-TR-036 | Added |
| `backend/src/main/java/com/speakeasy/identity/OtpStepUpProvider.java`, `DisabledOtpStepUpProvider.java` | Step-up provider boundary; default backend provider fails closed until production step-up proof integration and evidence exist. | OTP-PROD-TR-036 | Added |
| `backend/src/main/java/com/speakeasy/identity/OtpCaptchaVerifier.java`, `DisabledOtpCaptchaVerifier.java` | CAPTCHA server-verifier boundary; default disabled verifier fails closed instead of accepting arbitrary client tokens. | OTP-PROD-TR-029 | Added |
| `backend/src/main/java/com/speakeasy/identity/OtpRetentionCleanupScheduler.java`, `backend/src/main/java/com/speakeasy/config/SchedulingConfig.java` | Config-gated scheduled cleanup entry that reuses the existing OTP retention cleanup boundary. | OTP-PROD-TR-030, OTP-PROD-TR-037 | Added |
| `backend/src/main/java/com/speakeasy/api/AuthController.java`, `backend/src/main/java/com/speakeasy/security/SecurityConfig.java` | Adds `/auth/otp/send`, `/auth/otp/step-up`, OTP v2 `/auth/login/phone` and anonymous auth whitelist for OTP routes. | OTP-PROD-TR-005, OTP-PROD-TR-011, OTP-PROD-TR-019, OTP-PROD-TR-022, OTP-PROD-TR-029, OTP-PROD-TR-033 | Added |
| `backend/src/main/java/com/speakeasy/identity/AuthService.java` | Routes OTP v2 phone login through `OtpService.verifyAndConsume(...)` before the existing `loginOrCreate("phone", consumedVerifiedE164Phone, ...)` account/session lifecycle boundary; v1 raw phone login is test-profile compatibility only. | OTP-PROD-TR-018..021, OTP-PROD-TR-033 | Added |
| `backend/src/test/java/com/speakeasy/identity/Otp*Test.java`, `AuthServicePhoneLoginProfileTest.java` | Automated backend tests for normalization, secure random code length, HMAC verifier, send/no-account, provider failure, consent, phone/IP/device/install limits, resend invalidation and consumed cooldown, expiry, failure lock, replay/consume, existing identity reuse, SMS template, secure transport/trusted proxy opt-in on send/login/step-up, audit redaction, risk block, CAPTCHA fail-closed, step-up provider boundary and retention scheduler. | OTP-PROD-TR-004..030, OTP-PROD-TR-032..037 | Passed |
| `scripts/check_identity_release_guard.py`, `scripts/check_release_configuration.sh` | Release gates for consumed OTP before phone session, no Spring test profile in release, no fake/deterministic provider evidence, required OTP/SMS/social provider refs, and phone-risk allowed-country coverage including `CN` SIM-swap evidence. | OTP-PROD-TR-024, OTP-PROD-TR-026, OTP-PROD-TR-028, OTP-PROD-TR-033, OTP-PROD-TR-035, OTP-PROD-TR-036 | Added |
| `docs/architecture/api_contract.md`, `docs/architecture/openapi/speakeasy-api.yaml` | API contract and OpenAPI source of truth for OTP v2 routes and typed OTP errors. | OTP-PROD-TR-011, OTP-PROD-TR-022, OTP-PROD-TR-029, OTP-PROD-TR-033 | Passed contract lint |

Verification commands:
```bash
cd backend && mvn -q -Dtest='com.speakeasy.identity.Otp*Test' test
cd backend && mvn -q -Dtest='AuthControllerTest,AuthServiceTest,AuthServicePhoneLoginProfileTest,FoundationErrorContractTest,FoundationResponseContractTest' test
npm run lint:openapi
npm run check:openapi-contract
python3 test/scripts/test_identity_release_guard.py
APP_API_BASE_URL=https://api.speakeasyapp.com ENV=production ENABLE_TEST_PHONE_LOGIN=false SPRING_PROFILES_ACTIVE=production scripts/check_release_configuration.sh
python3 scripts/check_identity_release_guard.py
```

Verification result:
- OTP backend/API/domain/core tests 已通过。
- Auth/Foundation compatibility tests 已通过。
- OpenAPI lint 和 OpenAPI contract gate 已通过。
- Release guard unit tests 已通过，且当前 repository 不再出现 `IDENTITY-RELEASE-001`。
- Release configuration fixture 在 production profile 下通过，并在 Spring `test` profile 激活时失败。
- Strict release guard 仍按设计在 `IDENTITY-RELEASE-002` 和 `IDENTITY-RELEASE-003` 上失败，直到 Apple/WeChat provider verifier 以及所有 OTP/provider production config/evidence refs 落地，包括 phone-risk allowed-country coverage 和 `CN` SIM-swap evidence。
- Dart client drift 仍为 pending，因为 Flutter client generation 不属于本后端批次。

## Full Traceability Matrix
| Trace Row ID | Requirement | Spec | AC | TC | Code Evidence | Test Evidence | Release Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OTP-PROD-TR-004 | IDENTITY-OTP-004 | IDENTITY-SPEC-OTP-004 | AC-OTP-PROD-004 | TC-OTP-PROD-004 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-005 | IDENTITY-OTP-005 | IDENTITY-SPEC-OTP-005 | AC-OTP-PROD-005 | TC-OTP-PROD-005 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-006 | IDENTITY-OTP-006 | IDENTITY-SPEC-OTP-006 | AC-OTP-PROD-006 | TC-OTP-PROD-006 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-007 | IDENTITY-OTP-007 | IDENTITY-SPEC-OTP-007 | AC-OTP-PROD-007 | TC-OTP-PROD-007 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Release guard must reject deterministic/test generation | Backend implemented - release pending |
| OTP-PROD-TR-032 | IDENTITY-OTP-032 | IDENTITY-SPEC-OTP-032 | AC-OTP-PROD-032 | TC-OTP-PROD-032 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Release guard must reject digit length below 6 | Backend implemented - release pending |
| OTP-PROD-TR-008 | IDENTITY-OTP-008 | IDENTITY-SPEC-OTP-008 | AC-OTP-PROD-008 | TC-OTP-PROD-008 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Release guard must reject TTL above 10 minutes | Backend implemented - release pending |
| OTP-PROD-TR-009 | IDENTITY-OTP-009 | IDENTITY-SPEC-OTP-009 | AC-OTP-PROD-009 | TC-OTP-PROD-009 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Release guard/log scan must reject plaintext OTP evidence | Backend implemented - release pending |
| OTP-PROD-TR-010 | IDENTITY-OTP-010 | IDENTITY-SPEC-OTP-010 | AC-OTP-PROD-010 | TC-OTP-PROD-010 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `OTP_HMAC_SECRET_REF` required | Backend implemented - release pending |
| OTP-PROD-TR-011 | IDENTITY-OTP-011 | IDENTITY-SPEC-OTP-011 | AC-OTP-PROD-011 | TC-OTP-PROD-011 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Consent contract evidence required before release | Backend implemented - release pending |
| OTP-PROD-TR-012 | IDENTITY-OTP-012 | IDENTITY-SPEC-OTP-012 | AC-OTP-PROD-012 | TC-OTP-PROD-012 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Rate-limit config evidence required | Backend implemented - release pending |
| OTP-PROD-TR-013 | IDENTITY-OTP-013 | IDENTITY-SPEC-OTP-013 | AC-OTP-PROD-013 | TC-OTP-PROD-013 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Rate-limit config evidence required | Backend implemented - release pending |
| OTP-PROD-TR-014 | IDENTITY-OTP-014 | IDENTITY-SPEC-OTP-014 | AC-OTP-PROD-014 | TC-OTP-PROD-014 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Rate-limit config evidence required | Backend implemented - release pending |
| OTP-PROD-TR-015 | IDENTITY-OTP-015 | IDENTITY-SPEC-OTP-015 | AC-OTP-PROD-015 | TC-OTP-PROD-015 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-016 | IDENTITY-OTP-016 | IDENTITY-SPEC-OTP-016 | AC-OTP-PROD-016 | TC-OTP-PROD-016 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Attempt-limit config evidence required | Backend implemented - release pending |
| OTP-PROD-TR-017 | IDENTITY-OTP-017 | IDENTITY-SPEC-OTP-017 | AC-OTP-PROD-017 | TC-OTP-PROD-017 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Lock-window config evidence required | Backend implemented - release pending |
| OTP-PROD-TR-018 | IDENTITY-OTP-018 | IDENTITY-SPEC-OTP-018 | AC-OTP-PROD-018 | TC-OTP-PROD-018 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-033 | IDENTITY-OTP-033 | IDENTITY-SPEC-OTP-033 | AC-OTP-PROD-033 | TC-OTP-PROD-033 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `IDENTITY-RELEASE-001` guard evidence required | Backend implemented - release pending |
| OTP-PROD-TR-019 | IDENTITY-OTP-019 | IDENTITY-SPEC-OTP-019 | AC-OTP-PROD-019 | TC-OTP-PROD-019 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-020 | IDENTITY-OTP-020 | IDENTITY-SPEC-OTP-020 | AC-OTP-PROD-020 | TC-OTP-PROD-020 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | E.164 migration evidence required | Backend implemented - release pending |
| OTP-PROD-TR-021 | IDENTITY-OTP-021 | IDENTITY-SPEC-OTP-021 | AC-OTP-PROD-021 | TC-OTP-PROD-021 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | N/A - behavior evidence after implementation | Backend implemented - release pending |
| OTP-PROD-TR-022 | IDENTITY-OTP-022 | IDENTITY-SPEC-OTP-022 | AC-OTP-PROD-022 | TC-OTP-PROD-022 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | API error contract evidence required | Backend implemented - release pending |
| OTP-PROD-TR-023 | IDENTITY-OTP-023 | IDENTITY-SPEC-OTP-023 | AC-OTP-PROD-023 | TC-OTP-PROD-023 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `SMS_PROVIDER_EVIDENCE_REF` provider-failure fixture required | Backend implemented - release pending |
| OTP-PROD-TR-025 | IDENTITY-OTP-025 | IDENTITY-SPEC-OTP-025 | AC-OTP-PROD-025 | TC-OTP-PROD-025 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Approved SMS template evidence required | Backend implemented - release pending |
| OTP-PROD-TR-026 | IDENTITY-OTP-026 | IDENTITY-SPEC-OTP-026 | AC-OTP-PROD-026 | TC-OTP-PROD-026 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `HTTPS_ENFORCEMENT_EVIDENCE_REF` and `TRUSTED_PROXY_CONFIG_REF` required | Backend implemented - release pending |
| OTP-PROD-TR-027 | IDENTITY-OTP-027 | IDENTITY-SPEC-OTP-027 | AC-OTP-PROD-027 | TC-OTP-PROD-027 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Audit event evidence required | Backend implemented - release pending |
| OTP-PROD-TR-034 | IDENTITY-OTP-034 | IDENTITY-SPEC-OTP-034 | AC-OTP-PROD-034 | TC-OTP-PROD-034 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Audit redaction evidence required | Backend implemented - release pending |
| OTP-PROD-TR-028 | IDENTITY-OTP-028 | IDENTITY-SPEC-OTP-028 | AC-OTP-PROD-028 | TC-OTP-PROD-028 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `PHONE_RISK_PROVIDER_CONFIG_REF`, `PHONE_RISK_PROVIDER_EVIDENCE_REF`, `PHONE_RISK_COVERED_COUNTRIES` and country-specific evidence required | Backend implemented - release pending |
| OTP-PROD-TR-035 | IDENTITY-OTP-035 | IDENTITY-SPEC-OTP-035 | AC-OTP-PROD-035 | TC-OTP-PROD-035 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Risk block fixture evidence required | Backend implemented - release pending |
| OTP-PROD-TR-036 | IDENTITY-OTP-036 | IDENTITY-SPEC-OTP-036 | AC-OTP-PROD-036 | TC-OTP-PROD-036 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `STEP_UP_PROVIDER_CONFIG_REF` and `STEP_UP_PROVIDER_EVIDENCE_REF` required | Backend implemented - release pending |
| OTP-PROD-TR-029 | IDENTITY-OTP-029 | IDENTITY-SPEC-OTP-029 | AC-OTP-PROD-029 | TC-OTP-PROD-029 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `CAPTCHA_PROVIDER_CONFIG_REF` and `CAPTCHA_PROVIDER_EVIDENCE_REF` required | Backend implemented - release pending |
| OTP-PROD-TR-030 | IDENTITY-OTP-030 | IDENTITY-SPEC-OTP-030 | AC-OTP-PROD-030 | TC-OTP-PROD-030 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | `OTP_RETENTION_EVIDENCE_REF` cleanup evidence required | Backend implemented - release pending |
| OTP-PROD-TR-037 | IDENTITY-OTP-037 | IDENTITY-SPEC-OTP-037 | AC-OTP-PROD-037 | TC-OTP-PROD-037 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Retention policy version evidence required | Backend implemented - release pending |
| OTP-PROD-TR-024 | IDENTITY-OTP-024 | IDENTITY-SPEC-OTP-024 | AC-OTP-PROD-024 | TC-OTP-PROD-024 | Implemented - see Third Batch Backend API/DB/Domain/Core Artifacts | Passed - `docs/reports/test_report.md#identity-otp-production-hardening-20260625` | Release guard must reject fake/deterministic/test provider and missing/placeholder provider refs | Backend implemented - release pending |

## Completion Rules
- `Pending` rows 只有在 code evidence 引用具体文件且测试存在后，才可以移动到 `Implemented`。
- `Implemented` rows 只有在 test evidence 引用 TC ID、script path、command、result 和 report 后，才可以移动到 `Accepted`。
- 没有非占位 release evidence refs 时，release-impacting rows 不得验收。
- OTP completion 不代表 Apple/WeChat provider verifier completion 或 commercial release approval。
