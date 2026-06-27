# Identity OTP Production Hardening SWC Allocation

## Status
Proposed - 本文补齐 `identity-otp-production-hardening` 的 SWC allocation。该增量已经修改后端、DB migration、OpenAPI 和 release scripts，属于 implementation-impacting brownfield update；本文只记录相对既有全局 SWC baseline 的 delta，不重新定义 requirement、spec、AC、TC、Domain Schema 或 OpenAPI schema。

## Scope
- Increment ID: `identity-otp-production-hardening`
- Active stage: `N/A - Product Base identity-account-lifecycle OTP target`
- Covered Stage Scope IDs: `N/A - Product Base OTP target`
- Primary feature: `identity-account-lifecycle`
- Affected features: `access-onboarding`, `commercial-subscription`, `profile-membership`
- Explicit non-goals: 不在本增量新增稳定 SWC；不替换既有 auth/session/profile store；不绕过 OpenAPI、`AuthService`、JPA repository、release gate 或 provider boundary；不把 Apple/WeChat verifier、SMS vendor evidence、phone-risk coverage evidence 或 Flutter client generation 宣称为已完成。
- Change mode: `brownfield-update`

## Existing Implementation Baseline
本增量继承既有账号生命周期、登录、session、profile、audit 和 release gate 设计，只在既有 identity/backend boundary 内增加 OTP production hardening。

| Baseline item | Existing evidence required before new design |
| --- | --- |
| Existing user flow | 既有登录/profile/session flow 由 `SWC-FLOW-AUTH-PROFILE` 承载；请求、审计、release evidence 由 `SWC-FLOW-OBSERVABILITY` 承载；账号删除与 retention 相关约束继承 `SWC-FLOW-ACCOUNT-DELETION`。 |
| Existing code paths | `backend/src/main/java/com/speakeasy/api/AuthController.java`; `backend/src/main/java/com/speakeasy/identity/AuthService.java`; `backend/src/main/java/com/speakeasy/identity/`; `backend/src/main/java/com/speakeasy/security/SecurityConfig.java`; `backend/src/main/resources/db/migration/`; `docs/architecture/openapi/speakeasy-api.yaml`; `scripts/check_release_configuration.sh`; `scripts/check_release_readiness.sh`. |
| Existing SWCs | `FE-AUTH-PROFILE`, `FE-API-CLIENT`, `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `DB-IDENTITY-CONTENT`, `DB-MIGRATIONS`, `OPS-RELEASE-GATES`. |
| Existing global Flow IDs | `SWC-FLOW-AUTH-PROFILE`, `SWC-FLOW-OBSERVABILITY`, `SWC-FLOW-ACCOUNT-DELETION`. |
| Existing API/OpenAPI calls | 既有 `/auth/*`、`/user/me` 和账号生命周期 API 通过 `FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-IDENTITY`；本增量扩展 `POST /auth/otp/send`、`POST /auth/otp/step-up`、`POST /auth/login/phone`，OpenAPI source of truth 为 `docs/architecture/openapi/speakeasy-api.yaml`。 |
| Existing domain/data ownership | `BE-IDENTITY` 拥有 `UserAccount`、`UserProfile`、`AuthIdentity`、`AuthSession` 和 phone auth subject；`DB-IDENTITY-CONTENT`/`DB-MIGRATIONS` 拥有 identity DB migration；`BE-OPS-AUDIT-DELETION` 拥有 audit/deletion/retention orchestration。 |
| Existing tests/evidence | `TC-OTP-PROD-004`..`TC-OTP-PROD-037`; `backend/src/test/java/com/speakeasy/AuthControllerTest.java`; `backend/src/test/java/com/speakeasy/AuthServiceTest.java`; `backend/src/test/java/com/speakeasy/identity/`; `test/scripts/test_identity_release_guard.py`; `docs/reports/test_report.md#identity-otp-production-hardening-20260625`. |
| Behavior that must not regress | 既有 token/session 生成、profile bootstrap、social login API shape、test-profile-only v1 phone login compatibility、foundation error contract、release configuration guard、OpenAPI contract drift gate、audit redaction和账号生命周期 ownership 不得回退。 |
| Known legacy/deprecated parts | `AuthService.loginPhone(String, String, String, String)` 的 schema v1 raw phone login 仅保留 test-profile compatibility；`AuthService.loginSocial` 的 token-hash provider subject 仍由 `IDENTITY-RELEASE-002` 阻塞；Flutter fake SMS path、Apple/WeChat verifier、SMS/risk/CAPTCHA/step-up provider evidence 仍为 release blocker，owner 为 Backend + DevOps，expiry 为 commercial release 前。 |

## Delta From Existing Baseline
本增量只在既有 identity SWC 内增加 OTP challenge、rate limit、risk、CAPTCHA、step-up、retention 和 release guard 逻辑，不创建平行 auth runtime。

| Delta item | Decision |
| --- | --- |
| Reused SWCs | `FE-AUTH-PROFILE`, `FE-API-CLIENT`, `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `DB-IDENTITY-CONTENT`, `DB-MIGRATIONS`, `OPS-RELEASE-GATES`. |
| Reused Flow IDs | `SWC-FLOW-AUTH-PROFILE`, `SWC-FLOW-OBSERVABILITY`, `SWC-FLOW-ACCOUNT-DELETION`; OTP send/verify/step-up/cleanup/release guard 暂以 increment-local flow 记录，分类见 Baseline References 和 SWC Data Flows。 |
| Changed behavior | Phone login schema v2 必须先由 `OtpService.verifyAndConsume(...)` 消费有效 OTP challenge，再复用 `AuthService.loginOrCreate("phone", verifiedE164Phone, ...)` 创建/复用 identity 和 session；send/resend 增加 E.164 normalization、consent、cooldown、rate limit、provider success 后激活、old challenge invalidation；release guard 增加 consumed-OTP、provider evidence、risk coverage 和 social verifier blocker。 |
| Unchanged behavior | 既有 social login、session token response、profile response、foundation error envelope、test profile compatibility、OpenAPI source-of-truth 和 release scripts 的严格失败语义保持不变；provider evidence 未齐时不得通过 release。 |
| New code allowed | `backend/src/main/java/com/speakeasy/config/SchedulingConfig.java`; `backend/src/main/java/com/speakeasy/identity/Otp*.java`; `backend/src/main/java/com/speakeasy/identity/ConfiguredOtpPhoneRiskProvider.java`; `backend/src/main/java/com/speakeasy/identity/DisabledOtpCaptchaVerifier.java`; `backend/src/main/java/com/speakeasy/identity/DisabledOtpSmsProvider.java`; `backend/src/main/java/com/speakeasy/identity/DisabledOtpStepUpProvider.java`; `backend/src/main/java/com/speakeasy/identity/PhoneNumberNormalizer.java`; `backend/src/main/resources/db/migration/V202606250032__identity_otp_persistence.sql`; `backend/src/test/java/com/speakeasy/identity/Otp*Test.java`; `backend/src/test/java/com/speakeasy/identity/OtpIntegrationTestSupport.java`; `backend/src/test/java/com/speakeasy/identity/AuthServicePhoneLoginProfileTest.java`; `scripts/audit_phone_identity_subjects.py`; `scripts/check_identity_release_guard.py`; `test/scripts/test_identity_release_guard.py`; `test/scripts/test_audit_phone_identity_subjects.py`. |
| New code forbidden | 禁止新增独立 OTP backend SWC、独立 OTP database SWC、第二套 auth/session/profile store、第二套 OTP DB schema、绕过 `AuthService` 的 session issuance、controller 直接写 repository、frontend 本地 OTP truth、raw SMS/provider direct call、未登记 release evidence 的 production provider bypass。 |
| Existing code modified | `backend/src/main/java/com/speakeasy/api/AuthController.java`; `backend/src/main/java/com/speakeasy/identity/AuthService.java`; `backend/src/main/java/com/speakeasy/security/SecurityConfig.java`; `backend/src/main/resources/application.yml`; `backend/pom.xml`; `docs/architecture/api_contract.md`; `docs/architecture/openapi/speakeasy-api.yaml`; `scripts/check_release_configuration.sh`; `scripts/check_release_readiness.sh`. |
| Migration/deprecation impact | `V202606250032__identity_otp_persistence.sql` 新增 `otp_challenges`、`otp_rate_counters`、`otp_failure_locks`；schema v1 raw phone login 仅 test profile 可用；既有 phone identity E.164 migration 仍需 dry-run evidence 和商业发布前迁移执行记录。 |
| Regression proof required | `TC-OTP-PROD-004`..`TC-OTP-PROD-037`; `backend/src/test/java/com/speakeasy/identity/Otp*Test.java`; `backend/src/test/java/com/speakeasy/identity/AuthServicePhoneLoginProfileTest.java`; `backend/src/test/java/com/speakeasy/AuthControllerTest.java`; `backend/src/test/java/com/speakeasy/AuthServiceTest.java`; `backend/src/test/java/com/speakeasy/FoundationErrorContractTest.java`; `backend/src/test/java/com/speakeasy/FoundationResponseContractTest.java`; `test/scripts/test_identity_release_guard.py`; `npm run lint:openapi`; `npm run check:openapi-contract`; `python3 scripts/check_swc_allocation.py --scope changed --base-ref HEAD --include-worktree`. |

## Baseline References
| Reference type | Required value |
| --- | --- |
| Global SWC architecture baseline | `docs/architecture/software_component_architecture.md` |
| Referenced global Flow IDs | `SWC-FLOW-AUTH-PROFILE`, `SWC-FLOW-OBSERVABILITY`, `SWC-FLOW-ACCOUNT-DELETION` |
| Referenced SWC Catalog IDs | `FE-AUTH-PROFILE`, `FE-API-CLIENT`, `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `DB-IDENTITY-CONTENT`, `DB-MIGRATIONS`, `OPS-RELEASE-GATES` |
| Inherited data flow rules | `docs/architecture/data_flow.md`; server-owned auth/session/profile facts、provider boundary、audit redaction、retention evidence 和 release blocker 规则。 |
| Inherited module boundary rules | `docs/architecture/module_boundary.md`; controller 只做 HTTP binding，domain decision 留在 `BE-IDENTITY`，DB 只经 repository/service ownership 访问。 |
| Local flow classification | `OTP-LOCAL-FLOW-SEND-RESEND`: `proposed-global`; `OTP-LOCAL-FLOW-VERIFY-LOGIN`: `proposed-global`; `OTP-LOCAL-FLOW-STEP-UP`: `proposed-global`; `OTP-LOCAL-FLOW-RETENTION-CLEANUP`: `proposed-global`; `OTP-LOCAL-FLOW-RELEASE-GUARD`: `one-off`。 |
| Local flow migration owner and expiry | Owner: Backend + System Architect + DevOps。Expiry: OTP routes 被至少一个后续 release increment 复用或商业发布前，必须把稳定 OTP flow 提升到 `docs/architecture/software_component_architecture.md`，或记录 accepted one-off closure。 |

## System Responsibility Allocation
| Layer | Responsibilities in this increment | Non-responsibilities | Facts owned here |
| --- | --- | --- | --- |
| Frontend | 通过 `FE-AUTH-PROFILE` 和 `FE-API-CLIENT` 发起 OTP send、step-up、phone login；渲染 typed error 和登录结果。 | 不生成 OTP、不保存 provider secret、不声明 phone verification truth、不绕过 OpenAPI client。 | Client-cache-only facts only：输入态、错误展示、session display cache。 |
| Backend | `BE-API-CONTROLLERS` 绑定 OTP API；`BE-IDENTITY` 执行 normalization、consent、rate limit、risk、CAPTCHA、step-up、challenge lifecycle、atomic consume、session issuance；`BE-OPS-AUDIT-DELETION` 执行 audit/retention 协作。 | 不拥有 SMS vendor SLA、phone-risk external coverage、Apple/WeChat verifier evidence、Flutter UI copy。 | Server-owned facts：verified E.164 phone subject、OTP challenge state、rate/failure lock、AuthIdentity/AuthSession、audit event。 |
| Database | `DB-MIGRATIONS` 和 `DB-IDENTITY-CONTENT` 持久化 OTP challenge、rate counter、failure lock，并保持 identity/auth/profile/session table ownership。 | 不做 runtime decision、不暴露 raw OTP、不保存 plaintext OTP。 | Tables/migrations owned by backend：`otp_challenges`、`otp_rate_counters`、`otp_failure_locks`、identity/auth/profile/session tables。 |
| Provider / AI runtime | SMS、phone-risk、CAPTCHA、step-up provider 只作为 backend 后方边界；默认 disabled/fail-closed provider 不可作为 release evidence。 | 不拥有 accepted phone identity、session、rate limit truth、release approval。 | Candidate outputs only；accepted persistent facts are owned by `BE-IDENTITY` after deterministic rules accept them。 |
| Ops / release | `OPS-RELEASE-GATES` 校验 release config、provider evidence refs、social verifier blocker、phone-risk coverage、consumed-OTP guard 和 strict failure。 | 不批准产品 scope、不替代真实 provider evidence、不解除 social verifier blocker。 | Gates, audit, rollback, observability evidence。 |

## Requirement Allocation Matrix
| Stage Scope ID | FR | Spec | AC | FE SWC | BE SWC | API/OpenAPI | Domain Entity | DB Table/Migration | Provider/AI Boundary | TC | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-004` | `IDENTITY-SPEC-OTP-004` | `AC-OTP-PROD-004` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge`, `AuthIdentity` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpSmsProvider`; E.164 normalization boundary | `TC-OTP-PROD-004` | Phone subject 必须归一化为 E.164，dry-run migration evidence 仍是 release 前置项。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-005` | `IDENTITY-SPEC-OTP-005` | `AC-OTP-PROD-005` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpSmsProvider` | `TC-OTP-PROD-005` | 未注册手机号可发起 OTP，不能提前创建 session。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-006` | `IDENTITY-SPEC-OTP-006` | `AC-OTP-PROD-006` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpSmsProvider` | `TC-OTP-PROD-006` | OTP challenge lifecycle 由 backend owning service 管理。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-007` | `IDENTITY-SPEC-OTP-007` | `AC-OTP-PROD-007` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpCodeGenerator`; release guard rejects deterministic/test generator | `TC-OTP-PROD-007` | Production OTP 生成必须安全随机。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-032` | `IDENTITY-SPEC-OTP-032` | `AC-OTP-PROD-032` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpCodeGenerator`; release config guard | `TC-OTP-PROD-032` | OTP 位数低于 6 必须被 release guard 拦截。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-008` | `IDENTITY-SPEC-OTP-008` | `AC-OTP-PROD-008` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send`, `POST /auth/login/phone` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | Release config guard rejects long TTL | `TC-OTP-PROD-008` | Expiry 和 verify 均由 backend 判断。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-009` | `IDENTITY-SPEC-OTP-009` | `AC-OTP-PROD-009` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION` | `POST /auth/otp/send`, `POST /auth/login/phone` | `OtpChallenge`, `AuditLog` | `otp_challenges`, `audit_logs`; `V202606250032__identity_otp_persistence.sql` | `OtpHashService`; no plaintext OTP boundary | `TC-OTP-PROD-009` | 只存 HMAC/hash，不记录明文 OTP。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-010` | `IDENTITY-SPEC-OTP-010` | `AC-OTP-PROD-010` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send`, `POST /auth/login/phone` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OTP_HMAC_SECRET_REF` release evidence required | `TC-OTP-PROD-010` | HMAC secret 不得落在客户端或文档明文。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-011` | `IDENTITY-SPEC-OTP-011` | `AC-OTP-PROD-011` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | Consent evidence required before release | `TC-OTP-PROD-011` | Consent 缺失时 fail closed。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-012` | `IDENTITY-SPEC-OTP-012` | `AC-OTP-PROD-012` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpRateCounter` | `otp_rate_counters`; `V202606250032__identity_otp_persistence.sql` | Rate-limit config evidence required | `TC-OTP-PROD-012` | Phone scoped rate limit。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-013` | `IDENTITY-SPEC-OTP-013` | `AC-OTP-PROD-013` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpRateCounter` | `otp_rate_counters`; `V202606250032__identity_otp_persistence.sql` | Rate-limit config evidence required | `TC-OTP-PROD-013` | IP scoped rate limit。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-014` | `IDENTITY-SPEC-OTP-014` | `AC-OTP-PROD-014` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpRateCounter` | `otp_rate_counters`; `V202606250032__identity_otp_persistence.sql` | Rate-limit config evidence required | `TC-OTP-PROD-014` | Device/install scoped rate limit。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-015` | `IDENTITY-SPEC-OTP-015` | `AC-OTP-PROD-015` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge`, `OtpRateCounter` | `otp_challenges`, `otp_rate_counters`; `V202606250032__identity_otp_persistence.sql` | No Idempotency-Key；cooldown/rate-limit/resend invalidation boundary | `TC-OTP-PROD-015` | Resend 不是通用 idempotency；旧 pending challenge 失效。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-016` | `IDENTITY-SPEC-OTP-016` | `AC-OTP-PROD-016` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/login/phone` / `loginPhone` | `OtpFailureLock`, `OtpChallenge` | `otp_failure_locks`, `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | Attempt-limit config evidence required | `TC-OTP-PROD-016` | Verify failure counter 由 backend 拥有。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-017` | `IDENTITY-SPEC-OTP-017` | `AC-OTP-PROD-017` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/login/phone` / `loginPhone` | `OtpFailureLock` | `otp_failure_locks`; `V202606250032__identity_otp_persistence.sql` | Lock-window config evidence required | `TC-OTP-PROD-017` | Lock window 释放前不能创建 session。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-018` | `IDENTITY-SPEC-OTP-018` | `AC-OTP-PROD-018` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/login/phone` / `loginPhone` | `OtpChallenge`, `AuthSession` | `otp_challenges`, `auth_sessions`; `V202606250032__identity_otp_persistence.sql` | Atomic consume boundary | `TC-OTP-PROD-018` | Verify 使用 row lock/atomic consume；replay fails。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-033` | `IDENTITY-SPEC-OTP-033` | `AC-OTP-PROD-033` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `OPS-RELEASE-GATES` | `POST /auth/login/phone` / `loginPhone`; `scripts/check_identity_release_guard.py` | `OtpChallenge`, `AuthSession` | `otp_challenges`, `auth_sessions`; `V202606250032__identity_otp_persistence.sql` | `IDENTITY-RELEASE-001` consumed OTP guard | `TC-OTP-PROD-033` | Session 必须在 consumed verified OTP 后签发；当前 guard 已不再报告 `IDENTITY-RELEASE-001`。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-019` | `IDENTITY-SPEC-OTP-019` | `AC-OTP-PROD-019` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/login/phone` / `loginPhone` | `AuthIdentity`, `AuthSession`, `UserAccount`, `UserProfile` | `auth_identities`, `auth_sessions`, `user_accounts`, `user_profiles` | Existing identity reuse boundary | `TC-OTP-PROD-019` | 已存在 phone identity 必须复用。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-020` | `IDENTITY-SPEC-OTP-020` | `AC-OTP-PROD-020` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/login/phone` / `loginPhone` | `AuthIdentity`, `UserAccount` | `auth_identities`, `user_accounts` | E.164 migration dry-run evidence required | `TC-OTP-PROD-020` | Existing raw phone subjects 仍需 migration readiness evidence。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-021` | `IDENTITY-SPEC-OTP-021` | `AC-OTP-PROD-021` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/login/phone` / `loginPhone` | `AuthIdentity`, `UserProfile`, `AuthSession` | `auth_identities`, `user_profiles`, `auth_sessions` | Existing auth/profile lifecycle boundary | `TC-OTP-PROD-021` | 新 phone user 创建沿用 `loginOrCreate`。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-022` | `IDENTITY-SPEC-OTP-022` | `AC-OTP-PROD-022` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send`, `POST /auth/otp/step-up`, `POST /auth/login/phone` | `OtpChallenge`, `OtpFailureLock` | `otp_challenges`, `otp_failure_locks`; `V202606250032__identity_otp_persistence.sql` | Typed error contract boundary | `TC-OTP-PROD-022` | 错误响应保持 foundation envelope。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-023` | `IDENTITY-SPEC-OTP-023` | `AC-OTP-PROD-023` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpSmsProvider`, `DisabledOtpSmsProvider`, `SMS_PROVIDER_EVIDENCE_REF` pending | `TC-OTP-PROD-023` | Provider failure invalidates challenge and creates no session。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-025` | `IDENTITY-SPEC-OTP-025` | `AC-OTP-PROD-025` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpSmsTemplate`, `SMS_PROVIDER_CONFIG_REF`, `SMS_PROVIDER_EVIDENCE_REF` pending | `TC-OTP-PROD-025` | SMS template evidence 未齐时 release blocked。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-026` | `IDENTITY-SPEC-OTP-026` | `AC-OTP-PROD-026` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `OPS-RELEASE-GATES` | `POST /auth/otp/send`, `POST /auth/otp/step-up`, `POST /auth/login/phone`; `scripts/check_release_configuration.sh` | `OtpRequestContext` | `N/A - secure transport has no dedicated OTP table`; `V202606250032__identity_otp_persistence.sql` | `HTTPS_ENFORCEMENT_EVIDENCE_REF`, `TRUSTED_PROXY_CONFIG_REF` pending | `TC-OTP-PROD-026` | Trusted proxy 配置和 HTTPS enforcement 是 release evidence。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-027` | `IDENTITY-SPEC-OTP-027` | `AC-OTP-PROD-027` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION` | `POST /auth/otp/send`, `POST /auth/otp/step-up`, `POST /auth/login/phone` | `AuditLog`, `OtpChallenge` | `audit_logs`, `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | Audit event evidence required | `TC-OTP-PROD-027` | OTP send/verify/lock/risk event 必须可审计。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-034` | `IDENTITY-SPEC-OTP-034` | `AC-OTP-PROD-034` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION` | `POST /auth/otp/send`, `POST /auth/otp/step-up`, `POST /auth/login/phone` | `AuditLog` | `audit_logs`; `V202606250032__identity_otp_persistence.sql` | Audit redaction boundary | `TC-OTP-PROD-034` | Audit 中手机号、OTP、provider payload 必须 redacted。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-028` | `IDENTITY-SPEC-OTP-028` | `AC-OTP-PROD-028` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `OPS-RELEASE-GATES` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpPhoneRiskProvider`, `ConfiguredOtpPhoneRiskProvider`, `PHONE_RISK_PROVIDER_CONFIG_REF`, `PHONE_RISK_COVERED_COUNTRIES`, `PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF` pending | `TC-OTP-PROD-028` | CN/US coverage 和 country-specific evidence 未齐时 release blocked。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-035` | `IDENTITY-SPEC-OTP-035` | `AC-OTP-PROD-035` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `OPS-RELEASE-GATES` | `POST /auth/otp/send` / `sendOtp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpPhoneRiskProvider`, risk block fixture evidence pending | `TC-OTP-PROD-035` | High-risk phone must be blocked before SMS/session。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-036` | `IDENTITY-SPEC-OTP-036` | `AC-OTP-PROD-036` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `OPS-RELEASE-GATES` | `POST /auth/otp/send`, `POST /auth/otp/step-up` / `submitOtpStepUp` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpStepUpProvider`, `DisabledOtpStepUpProvider`, `STEP_UP_PROVIDER_CONFIG_REF`, `STEP_UP_PROVIDER_EVIDENCE_REF` pending | `TC-OTP-PROD-036` | Step-up 默认 fail closed，不能形成 session。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-029` | `IDENTITY-SPEC-OTP-029` | `AC-OTP-PROD-029` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-API-CONTROLLERS`, `BE-IDENTITY`, `OPS-RELEASE-GATES` | `POST /auth/otp/send`, `POST /auth/otp/step-up` | `OtpChallenge` | `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OtpCaptchaVerifier`, `DisabledOtpCaptchaVerifier`, `CAPTCHA_PROVIDER_CONFIG_REF`, `CAPTCHA_PROVIDER_EVIDENCE_REF` pending | `TC-OTP-PROD-029` | CAPTCHA server verifier 未配置时 fail closed。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-030` | `IDENTITY-SPEC-OTP-030` | `AC-OTP-PROD-030` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `OPS-RELEASE-GATES` | `N/A - scheduled cleanup has no public OpenAPI` | `OtpChallenge`, `OtpRateCounter`, `OtpFailureLock`, `AuditLog` | `otp_challenges`, `otp_rate_counters`, `otp_failure_locks`, `audit_logs`; `V202606250032__identity_otp_persistence.sql` | `OTP_RETENTION_EVIDENCE_REF` pending | `TC-OTP-PROD-030` | Cleanup scheduler 由 config gate 启用，release 需 retention evidence。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-037` | `IDENTITY-SPEC-OTP-037` | `AC-OTP-PROD-037` | `FE-AUTH-PROFILE`, `FE-API-CLIENT` | `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `OPS-RELEASE-GATES` | `N/A - retention policy has no public OpenAPI` | `OtpChallenge`, `OtpRateCounter`, `OtpFailureLock`, `AuditLog` | `otp_challenges`, `otp_rate_counters`, `otp_failure_locks`, `audit_logs`; `V202606250032__identity_otp_persistence.sql` | Retention policy version evidence pending | `TC-OTP-PROD-037` | Retention policy version 需进入 release evidence。 |
| `N/A - Product Base OTP target` | `IDENTITY-OTP-024` | `IDENTITY-SPEC-OTP-024` | `AC-OTP-PROD-024` | `N/A - release gate has no frontend runtime` | `BE-IDENTITY`, `OPS-RELEASE-GATES` | `scripts/check_identity_release_guard.py`; `scripts/check_release_configuration.sh`; `scripts/check_release_readiness.sh` | `AuthIdentity`, `OtpChallenge`, provider evidence registry | `auth_identities`, `otp_challenges`; `V202606250032__identity_otp_persistence.sql` | `OPS-RELEASE-GATES`; `IDENTITY-RELEASE-002` and `IDENTITY-RELEASE-003` remain blocked until social verifier and provider evidence refs land | `TC-OTP-PROD-024` | Release guard 必须拒绝 fake/deterministic/test provider 和 placeholder refs；OTP completion 不等于 commercial release approval。 |

## SWC Data Flows

### OTP-LOCAL-FLOW-SEND-RESEND
- 全局 Flow ID 或本地分类：`proposed-global`；继承 `SWC-FLOW-AUTH-PROFILE` 和 `SWC-FLOW-OBSERVABILITY`，owner 为 Backend + System Architect，商业发布前或跨增量复用时提升为 global flow。
- 触发条件：用户在 auth/profile 登录入口请求 OTP send 或 resend。
- 成功路径：
  ```text
  FE-AUTH-PROFILE
    -> FE-API-CLIENT
    -> BE-API-CONTROLLERS / AuthController.sendOtp
    -> BE-IDENTITY / OtpService
    -> PhoneNumberNormalizer, consent, secure transport, rate counters, risk, CAPTCHA
    -> OtpSmsProvider
    -> DB-IDENTITY-CONTENT / otp_challenges, otp_rate_counters
    -> response
    -> FE-AUTH-PROFILE display
  ```
- 失败路径：normalization、consent、secure transport、rate limit、risk block、CAPTCHA 或 SMS provider 失败时返回 typed error；provider 失败必须使 challenge 不可用且不得创建 session。
- Auth / authorization：OTP send 为 anonymous allowed route，但只允许 controller 到 `BE-IDENTITY`，不得绕过 service。
- Idempotency / retry：send/resend 不使用 `Idempotency-Key`；通过 cooldown、rate-limit 和 old pending challenge invalidation 保证重复请求语义。
- Rollback or compensation：SMS provider 未成功前不得激活 challenge；provider 失败后 challenge 标记为失败或不可消费。
- Audit / logging / metrics：记录 redacted phone、risk/captcha/provider outcome，不记录 plaintext OTP。
- Permission / privacy：phone、OTP、provider payload 必须 redacted；HMAC secret 只在 backend config/ref 边界。
- Response-to-UI mapping（响应映射）：返回 cooldown、masked phone、typed error code；frontend 只展示状态，不拥有 verification truth。

### OTP-LOCAL-FLOW-VERIFY-LOGIN
- 全局 Flow ID 或本地分类：`proposed-global`；继承 `SWC-FLOW-AUTH-PROFILE`，owner 为 Backend + System Architect，商业发布前或跨增量复用时提升为 global flow。
- 触发条件：用户提交 OTP code 执行 phone login。
- 成功路径：
  ```text
  FE-AUTH-PROFILE
    -> FE-API-CLIENT
    -> BE-API-CONTROLLERS / AuthController.loginPhone
    -> BE-IDENTITY / AuthService.loginPhone
    -> BE-IDENTITY / OtpService.verifyAndConsume
    -> DB-IDENTITY-CONTENT / otp_challenges row lock and consume
    -> BE-IDENTITY / loginOrCreate phone identity and session
    -> DB-IDENTITY-CONTENT / auth_identities, auth_sessions, user_accounts, user_profiles
    -> response
    -> FE-AUTH-PROFILE display/cache
  ```
- 失败路径：expired、wrong code、locked、already consumed、step-up pending 或 schema mismatch 均返回 typed error；不得创建 session。
- Auth / authorization：login route anonymous allowed；session issuance 只能发生在 consumed verified challenge 后。
- Idempotency / retry：verify/login 通过 row lock 和 atomic consume 防重放；同一 code 只可消费一次，replay fails。
- Rollback or compensation：identity/session 创建失败时保留 audit evidence；不得回写 frontend verification truth。
- Audit / logging / metrics：记录 verify success/failure/lock/consume outcome，敏感字段 redacted。
- Permission / privacy：backend 只持久化 verified E.164 phone subject 和 hash，不返回 OTP/hash。
- Response-to-UI mapping（响应映射）：成功返回既有 auth/session response；失败映射为 foundation error envelope。

### OTP-LOCAL-FLOW-STEP-UP
- 全局 Flow ID 或本地分类：`proposed-global`；继承 `SWC-FLOW-AUTH-PROFILE` 和 `SWC-FLOW-OBSERVABILITY`，owner 为 Backend + DevOps，商业发布前需 provider evidence 或 accepted closure。
- 触发条件：risk provider 判定需要 step-up，或客户端提交 step-up proof。
- 成功路径：
  ```text
  FE-AUTH-PROFILE
    -> FE-API-CLIENT
    -> BE-API-CONTROLLERS / AuthController.submitOtpStepUp
    -> BE-IDENTITY / OtpService
    -> OtpStepUpProvider
    -> DB-IDENTITY-CONTENT / otp_challenges step-up state
    -> response
    -> FE-AUTH-PROFILE display
  ```
- 失败路径：provider 未配置、proof invalid、challenge expired 或 risk blocked 时 fail closed；不得绕到 phone login session。
- Auth / authorization：anonymous allowed only through controller/service boundary。
- Idempotency / retry：step-up proof 绑定 challenge；重复提交由 challenge state 和 rate/failure guard 控制。
- Rollback or compensation：step-up provider 失败不激活 session，不释放风险 blocker。
- Audit / logging / metrics：记录 provider outcome 和 redacted challenge id。
- Permission / privacy：provider payload 不进入 client，不作为 accepted persistent fact。
- Response-to-UI mapping（响应映射）：返回 step-up required、completed 或 typed failure。

### OTP-LOCAL-FLOW-RETENTION-CLEANUP
- 全局 Flow ID 或本地分类：`proposed-global`；继承 `SWC-FLOW-ACCOUNT-DELETION` 和 `SWC-FLOW-OBSERVABILITY`，owner 为 Backend + DevOps，商业发布前需 retention evidence。
- 触发条件：config-gated scheduler 或运维触发清理过期 OTP challenge/rate/failure state。
- 成功路径：
  ```text
  OPS-RELEASE-GATES / scheduler config
    -> BE-IDENTITY / OtpRetentionCleanupScheduler
    -> BE-IDENTITY / OtpService.cleanupExpired
    -> DB-IDENTITY-CONTENT / otp_challenges, otp_rate_counters, otp_failure_locks
    -> BE-OPS-AUDIT-DELETION / audit evidence
  ```
- 失败路径：scheduler disabled、DB failure 或 retention config missing 时记录 failure evidence，不改变 login success path。
- Auth / authorization：仅 backend scheduled job 或运维边界可触发；无 public OpenAPI。
- Idempotency / retry：cleanup 按 expiry/status 查询，可重复运行；不得删除 active valid challenge。
- Rollback or compensation：保留 migration rollback 和 audit evidence；必要时暂停 scheduler。
- Audit / logging / metrics：记录 cleanup count、policy version、redacted metadata。
- Permission / privacy：清理后不保留 plaintext OTP；policy evidence 进入 release registry。
- Response-to-UI mapping（响应映射）：无直接 UI response；用户只受 expired/locked typed error 影响。

### OTP-LOCAL-FLOW-RELEASE-GUARD
- 全局 Flow ID 或本地分类：`one-off`；继承 `SWC-FLOW-OBSERVABILITY`，owner 为 DevOps + Backend，expiry 为 release blocker 全部关闭或并入全局 release readiness baseline。
- 触发条件：CI、本地 release readiness 或商业发布前手动执行 release gate。
- 成功路径：
  ```text
  OPS-RELEASE-GATES
    -> scripts/check_release_configuration.sh
    -> scripts/check_identity_release_guard.py
    -> scripts/check_release_readiness.sh
    -> release evidence registry
  ```
- 失败路径：检测到 test profile、fake/deterministic provider、未消费 OTP 直接 session、placeholder evidence ref、Apple/WeChat verifier 未闭环、phone-risk country coverage 缺口时 strict fail。
- Auth / authorization：仅 CI/ops 执行，无 runtime user auth。
- Idempotency / retry：脚本可重复执行；结果取决于当前配置、代码和 evidence refs。
- Rollback or compensation：失败时阻断 release，不修改 runtime data。
- Audit / logging / metrics：输出 gate ID，例如 `IDENTITY-RELEASE-001`、`IDENTITY-RELEASE-002`、`IDENTITY-RELEASE-003`。
- Permission / privacy：release evidence refs 不得包含 secret 原文。
- Response-to-UI mapping（响应映射）：无 UI response；发布状态在 release report/checklist 中呈现。

## Reuse And Forbidden Boundaries
| Boundary type | Decision |
| --- | --- |
| Existing SWCs that must be reused | `FE-AUTH-PROFILE`, `FE-API-CLIENT`, `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `DB-IDENTITY-CONTENT`, `DB-MIGRATIONS`, `OPS-RELEASE-GATES`. |
| New SWCs allowed | `N/A - no new stable SWC allowed in this increment`; OTP local flows may be promoted only by updating `docs/architecture/software_component_architecture.md` and `docs/architecture/swc_catalog.md` through governance。 |
| Duplicate components forbidden | 禁止 duplicate OTP runtime、duplicate auth/session/profile store、duplicate provider registry、duplicate migration table family、duplicate release guard、frontend-owned verification truth、controller direct repository write。 |
| Forbidden direct calls or bypasses | Frontend 不得直连 SMS/risk/CAPTCHA/step-up provider；controller 不得绕过 `OtpService`/`AuthService`；phone login 不得绕过 consumed challenge；release scripts 不得 silently skip OTP/social provider blockers。 |
| Legacy exceptions and migration plan | schema v1 raw phone login 仅 test profile；`AuthService.loginSocial` token-hash provider subject、Apple/WeChat verifier、SMS/risk/CAPTCHA/step-up provider refs、CN/US coverage 和 retention evidence 仍为 release blocker，owner 为 Backend + DevOps，expiry 为 commercial release 前。 |

## Verification
| Check | Expected evidence |
| --- | --- |
| Expected tests | `TC-OTP-PROD-004`..`TC-OTP-PROD-037`; `cd backend && mvn -q -Dtest='com.speakeasy.identity.Otp*Test' test`; `cd backend && mvn -q -Dtest='AuthControllerTest,AuthServiceTest,AuthServicePhoneLoginProfileTest,FoundationErrorContractTest,FoundationResponseContractTest' test`; `python3 test/scripts/test_identity_release_guard.py`. |
| Static gates | `python3 scripts/check_swc_allocation.py --scope changed --base-ref HEAD --include-worktree`; `python3 scripts/check_document_language.py --scope changed --base-ref HEAD --include-worktree`; `git diff --check`. |
| OpenAPI/generated drift checks | `npm run lint:openapi`; `npm run check:openapi-contract`; Dart client generation remains pending outside this backend batch and must not be claimed as accepted. |
| Traceability checker | `docs/product/increments/identity-otp-production-hardening/traceability.md` must keep `OTP-PROD-TR-004`..`OTP-PROD-TR-037` mapped to code/test/release evidence; release-impacting rows remain `Backend implemented - release pending` until non-placeholder evidence lands. |
| Software Architecture Governance Check finding | independent Software Architecture Governance Check agent must return pass, or this file must be revised before marking the increment implementation-ready. |

## Notes
- 本文是相对于 `docs/architecture/software_component_architecture.md` 的 delta，不是完整 SWC architecture。
- 不得在本文中重新定义 product scope、requirements、acceptance criteria、domain entity semantics、OpenAPI schemas、AI prompt schemas、UX layout、test implementation 或 release approval。
