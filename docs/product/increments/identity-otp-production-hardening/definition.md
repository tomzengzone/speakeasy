# Increment Definition：Identity OTP Production Hardening

## 状态
Backend API/DB/domain/core evidence added。本文建立 OTP Product Base 全量落地执行包，并记录本批后端核心实现证据；不得解释为 Product Base OTP 已 complete、外部 provider evidence 已完成或商业 release-ready。

## Increment ID
`identity-otp-production-hardening`

## Product Object Mode
- Type: `feature-increment`
- Source mode: Product Base target implementation package
- Upstream source of truth: `docs/product/base/identity-account-lifecycle/requirements.md` and `docs/product/base/identity-account-lifecycle/spec.md`

## Problem Statement
手机号登录当前仍只做手机号/验证码非空校验后进入账号解析和 session 签发。Product Base 已定义真实短信 OTP 目标态，但所有 OTP target 仍为 pending。该执行包用于把 OTP target 拆成可实现、可验收、可测试、可发布门禁验证的工作项，避免后续实现只关闭核心 challenge/consume 而遗漏风控、审计、retention、生产 provider 和 release evidence。

## Scope
本执行包覆盖并锁定以下 Product Base OTP target IDs：

`IDENTITY-OTP-004..030`（其中 `IDENTITY-OTP-024` 是 release boundary）和 `IDENTITY-OTP-032..037`。

## Non-Goals
- 不修改 Apple / WeChat provider verifier 目标态。
- 不替代现有 `AuthService.loginOrCreate(...)` 账号解析、账号创建、profile 初始化或 session/token 签发逻辑。
- 不把 Product Base OTP rows 标为 complete。
- 不把 fake、deterministic、sandbox 或 placeholder provider 证据算作生产 release evidence。

## Provider Decisions
| Provider boundary | Decision | Release evidence requirement | Status |
| --- | --- | --- | --- |
| Production SMS | Primary production SMS adapter target: Alibaba Cloud SMS Dysmsapi for `+86` phone numbers. This SMS decision does not open the production allowlist by itself; `+86` release remains blocked until matching `+86` phone-risk/SIM-swap evidence exists. Additional regions require explicit allowlist and provider evidence before opening. | `SMS_PROVIDER_CONFIG_REF`, `SMS_PROVIDER_EVIDENCE_REF`, approved SMS signature/template evidence, delivery failure fixture evidence | Backend fail-closed provider boundary added; production provider evidence pending |
| SIM swap / phone risk | Production risk adapter must use authoritative carrier/phone-intelligence data for every allowed production country. No `+86` phone-risk provider is approved in this first-batch execution package; release guard must block `+86` OTP production until `PHONE_RISK_PROVIDER_CONFIG_REF` and `PHONE_RISK_PROVIDER_EVIDENCE_REF` prove `+86` SIM-swap or number-transfer coverage. Initial non-`+86` candidate: Twilio Lookup SIM Swap / Lookup risk signals. | `PHONE_RISK_PROVIDER_CONFIG_REF`, `PHONE_RISK_PROVIDER_EVIDENCE_REF`, `PHONE_RISK_COVERED_COUNTRIES`, `PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF`, timeout/fail-closed fixture evidence, supported-country matrix | Backend phone-risk provider boundary and policy gates added; production provider/country coverage evidence pending |
| CAPTCHA | Cloudflare Turnstile is the selected CAPTCHA provider. CAPTCHA is only an automation-control layer and must not be counted as OTP verification or step-up proof. | `CAPTCHA_PROVIDER_CONFIG_REF`, `CAPTCHA_PROVIDER_EVIDENCE_REF`, server-side token verification fixture evidence | Backend CAPTCHA policy gate added; production provider evidence pending |
| Step-up | Step-up proof is distinct from CAPTCHA. Accepted first target: platform passkey/WebAuthn assertion for an existing resolved phone identity with enrolled step-up factor. New or unbound phone identities without step-up enrollment must be risk-blocked rather than silently bypassed. | `STEP_UP_PROVIDER_CONFIG_REF`, `STEP_UP_PROVIDER_EVIDENCE_REF`, enrolled/not-enrolled/block fixture evidence | Backend step-up fail-closed boundary added; production provider evidence pending |
| HTTPS / trusted proxy | Production OTP endpoints must be served only through HTTPS or a trusted proxy that asserts HTTPS through configured trusted headers. | `HTTPS_ENFORCEMENT_EVIDENCE_REF`, `TRUSTED_PROXY_CONFIG_REF`, non-HTTPS rejection fixture evidence | Backend secure-transport gate added; trusted proxy/release evidence pending |
| OTP HMAC secret | OTP hashes must use a production secret/pepper from secret storage, never a source-controlled default. | `OTP_HMAC_SECRET_REF`, secret presence release-guard evidence | Backend HMAC verifier added; production secret evidence pending |
| Retention | OTP challenge/hash cleanup must delete or irreversibly invalidate expired challenge material within 24 hours; audit retains only redacted evidence. | `OTP_RETENTION_EVIDENCE_REF`, cleanup execution fixture evidence, retention policy version | Backend cleanup/invalidation added; release operation evidence pending |

## Second Batch Phone Identity Audit Decisions
| Decision area | Decision | Status |
| --- | --- | --- |
| Existing storage baseline | `auth_identities` stores `provider` and raw `provider_subject` under unique `(provider, provider_subject)`; current phone login writes `phoneNumber.trim()` as subject. | Audited from schema/code |
| Dry-run tool | `scripts/audit_phone_identity_subjects.py` audits exported `auth_identities` rows where `provider='phone'`; it classifies already-E.164, default-region normalizable, unsupported-country, invalid-format and normalized-subject conflict rows without writing to DB. | Added |
| Dry-run test | `test/scripts/test_audit_phone_identity_subjects.py` covers classification, conflict detection and malformed CSV failure. | Added |
| Normalization library for backend implementation | Use Google libphonenumber Java dependency during backend implementation; the Python dry-run remains conservative and does not replace production normalization. | Decided |
| Default region for legacy raw domestic subjects | `CN`, because current user/account baseline defaults locale to `zh-CN` and most phone fixtures use `+86`; raw 11-digit CN mobile subjects normalize to `+86`. | Decided |
| Production allowlist rule | No country is production-open by SMS evidence alone. A country may enter production OTP allowlist only when SMS, phone-risk/SIM-swap, CAPTCHA/step-up as applicable, HTTPS and release evidence are all present. | Decided |
| Non-production fixture rule | Test/dev profiles may include `CN` and `US` fixture numbers through fake providers, but release guard must block those fixtures from production evidence. | Decided |
| Conflict policy | Any two or more phone identities normalizing to the same E.164 subject block write migration. Cross-user duplicates are ownership conflicts; same-user duplicates are unique-index/cleanup conflicts because `(provider, provider_subject)` must remain unique. | Decided |
| Invalid/unsupported policy | Invalid or unsupported subjects block write migration for those rows and must be manually resolved or excluded from production OTP rollout. | Decided |
| Rollback policy | A write migration must be preceded by CSV export evidence; rollback restores original `provider_subject` values from that export inside a reviewed transaction. | Decided |
| Audit country semantics | `--audit-country` values are dry-run coverage only and must not be interpreted as production allowlist approval. | Decided |

## Work Packages
| WP ID | Work package | Product Base IDs | Primary outcome | Status |
| --- | --- | --- | --- | --- |
| OTP-PROD-WP-000 | Execution package and traceability setup | All locked OTP IDs | Definition, AC, TC, traceability and provider/evidence format exist | Complete for planning; backend evidence added |
| OTP-PROD-WP-001 | Phone normalization and legacy identity migration | 004, 020 | E.164 normalization and existing phone identity migration plan/code/tests | Backend normalization implemented; write migration/release evidence pending |
| OTP-PROD-WP-002 | OTP API contract and server-owned context | 005, 006, 011, 022, 026, 029, 035, 036 | Send/resend/verify/step-up contracts, typed errors, HTTPS/context boundary | Backend API/context implemented; Dart client and HTTPS evidence pending |
| OTP-PROD-WP-003 | OTP domain state and secure verification | 007, 032, 008, 009, 010, 015, 016, 017, 018, 033 | Secure code generation, hashing, state machine, attempts, locks, atomic consume | Backend implemented and tested |
| OTP-PROD-WP-004 | SMS provider and template hardening | 023, 025, 024 | Production SMS provider, safe template, fake provider disabled in prod | Backend fail-closed boundary/template implemented; live provider evidence pending |
| OTP-PROD-WP-005 | Abuse controls, risk, CAPTCHA and step-up | 012, 013, 014, 028, 029, 035, 036 | Cooldown, rate limits, phone risk, CAPTCHA and step-up behavior | Backend limits/provider boundaries/policy gates implemented; live risk/CAPTCHA/step-up evidence pending |
| OTP-PROD-WP-006 | Audit and retention | 027, 034, 030, 037 | Redacted audit events and retention cleanup | Backend audit/retention implemented; release operation evidence pending |
| OTP-PROD-WP-007 | Auth and client integration | 019, 020, 021, 033 | Consumed OTP subject enters existing loginOrCreate; Flutter send/verify uses challenge | Backend auth integration implemented; Flutter client pending |
| OTP-PROD-WP-008 | Release guard and evidence | 024 and release-related OTP IDs | Strict release blocks missing provider/config/security/evidence | Partial: `IDENTITY-RELEASE-001` cleared; `IDENTITY-RELEASE-002/003` pending, including phone-risk country coverage refs |

## Completion Gate
在每个锁定的 Product Base OTP ID 都映射到以下链路前，本增量不得标记为完成：

`Requirement -> Spec -> AC -> TC -> Code Evidence -> Test Evidence -> Release Evidence -> independent review`

当前可以记录本包的后端代码和测试证据，但在非占位的生产 provider/config/security refs、generated client closure 和独立审查全部完成前，release evidence 必须保持 `Pending`。
