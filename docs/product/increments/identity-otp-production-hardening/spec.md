# Spec：Identity OTP Production Hardening

## 状态
Backend API/DB/domain/core evidence added. 本文是 OTP Product Base 全量落地执行规格；后端核心切片已实现，外部 provider evidence、release evidence、Dart client drift 和社交 provider verifier closure 仍 pending。

## 上游来源
- `docs/product/increments/identity-otp-production-hardening/requirements.md`
- `docs/product/base/identity-account-lifecycle/spec.md`

## Historical Implementation Baseline
- Backend `AuthController` 当前暴露带 `phone_number`、`verification_code` 和 `terms_accepted` 的 `POST /auth/login/phone`。
- Backend `AuthService.loginPhone` 当前校验非空输入，并调用 `loginOrCreate("phone", phoneNumber.trim(), "Phone User")`。
- `loginOrCreate(...)` 是 identity resolution、account creation、profile creation 和 session issuance 的 canonical account lifecycle boundary。
- Flutter `ApiClient.sendSmsCode` 当前返回本地 fake response，不调用后端 SMS send。
- Database `auth_identities` 当前强制唯一 `(provider, provider_subject)`，且还没有 normalized phone subject migration evidence。

## Phone Identity Migration Dry-Run
| Item | Specification |
| --- | --- |
| Export source | `SELECT auth_identity_id,user_id,provider,provider_subject,status FROM auth_identities WHERE provider='phone' ORDER BY provider_subject, auth_identity_id;` exported as CSV with header. |
| Dry-run command | `python3 scripts/audit_phone_identity_subjects.py phone_identities.csv --default-region CN --audit-country CN --audit-country US > phone_identity_audit.md` |
| Classification | `already_e164`, `normalize_default_region`, `unsupported_country`, `invalid_format`, normalized-subject conflict. |
| Write migration gate | Write migration is blocked while any conflict, invalid format or unsupported country row remains unresolved. |
| Conflict handling | Any normalized-subject duplicate blocks write migration. Cross-user duplicates require ownership/manual support decision; same-user duplicates require explicit duplicate cleanup before update because the database unique key is `(provider, provider_subject)`. Automated merge or reassignment is forbidden. |
| Rollback evidence | Before any write migration, preserve original exported CSV and migration transaction ID; rollback restores original `provider_subject` values from the export. |
| Production normalizer | Backend implementation must use Google libphonenumber; the dry-run script is conservative planning evidence only. |
| Production country allowlist | Country allowlist is config-driven and release-gated. `CN` is the default raw-subject region, but `CN` production release remains blocked until phone-risk/SIM-swap evidence exists. Dry-run `--audit-country` values are audit coverage only, not release approval. |
| Test/dev country allowance | Test/dev fake-provider profiles may keep `CN` and `US` fixtures to preserve existing regression data without implying production allowlist. |

## Target Flow
| Flow ID | Trigger | Required behavior | Failure boundary |
| --- | --- | --- | --- |
| OTP-PROD-FLOW-SEND | User requests phone OTP. | Normalize phone to E.164, validate consent version, CAPTCHA, risk, HTTPS/context and rate limits; create non-session OTP challenge and send SMS. | Invalid phone, missing consent, CAPTCHA fail, risk block, rate limit, insecure transport or provider failure must not create a verifiable challenge or session. |
| OTP-PROD-FLOW-RESEND | User requests another OTP for same phone/purpose. | Enforce cooldown/rate limits; invalidate previous active challenge; create a new active challenge only after provider send succeeds. | Old challenge must not verify after resend; phone+purpose failure counts must not reset. |
| OTP-PROD-FLOW-VERIFY | User submits challenge and code. | Verify active challenge, phone, code, expiry, attempts, phone+purpose lock and step-up status; atomically consume once; then enter existing `loginOrCreate(...)`. | Expired, invalid, replayed, locked, step-up pending or wrong code must not create account/session. |
| OTP-PROD-FLOW-RISK | Send or verify reaches risk evaluation. | Risk provider returns allow/block/step_up from SIM swap, number transfer, IP/device/install velocity and short-window request signals. | Block denies send/session; step-up requires separate proof before session. |
| OTP-PROD-FLOW-AUDIT-RETENTION | OTP security event or cleanup occurs. | Write redacted audit with retention policy version; cleanup deletes or invalidates expired challenge/hash material within 24 hours. | Audit must never contain OTP plaintext, token plaintext or full phone number. |

## API Contract Targets
| Endpoint | Method | Purpose | Required fields | Output | Status |
| --- | --- | --- | --- | --- | --- |
| `/auth/otp/send` | POST | Send or resend OTP challenge. | `schema_version`, `phone_number`, `terms_accepted`, `consent_version`, optional policy-required `captcha_token`, optional `device_id`, optional `install_id` | `challenge_id`, `expires_at`, `resend_after_seconds`, `risk_decision`, `step_up_status` | Backend implemented - provider/release evidence pending |
| `/auth/otp/step-up` | POST | Submit step-up proof for a step-up-required challenge. | `schema_version`, `challenge_id`, `step_up_token` | `challenge_id`, `step_up_status` | Backend implemented - provider/release evidence pending |
| `/auth/login/phone` | POST | Verify consumed OTP and create/resolve account session. | `schema_version=2`, `challenge_id`, `phone_number`, `verification_code`, `terms_accepted` | Existing `AuthSessionResponse` | Backend implemented - provider/release evidence pending |

本增量后，`schema_version=1` raw phone login 必须在生产环境被拒绝，或只限制在有 release guard 保护的非生产 test profile 中。

## Server-Owned Context
| Context field | Source of truth | Rule |
| --- | --- | --- |
| Client IP | Servlet request remote address or configured trusted proxy chain | Client-supplied IP is ignored unless from trusted proxy header. |
| HTTPS state | Direct TLS request or trusted `X-Forwarded-Proto=https` | Non-secure production OTP requests are rejected or blocked at gateway with evidence. |
| Request ID | `X-Request-Id` if valid, otherwise server generated | Audit stores sanitized request ID only. |
| Device / install ID | Client-provided optional field | Used only for rate/risk; absence is recorded as absent and can raise risk. |

## Provider Decisions
| Boundary | Selected target | Notes |
| --- | --- | --- |
| SMS provider | Alibaba Cloud SMS Dysmsapi for `+86` SMS delivery target. | Template/signature must be approved before production. This does not open `+86` OTP release unless phone-risk/SIM-swap evidence also covers `+86`. Other countries stay unsupported until separate SMS and risk evidence exists. |
| Phone risk / SIM swap | Authoritative phone-intelligence provider for every allowed country. No `+86` provider is approved in this first-batch package; `+86` production OTP release must remain blocked until matching evidence exists. Initial non-`+86` candidate is Twilio Lookup SIM Swap. | Allowed countries must match provider coverage. Missing/timeout risk response fails closed according to risk policy. |
| CAPTCHA | Cloudflare Turnstile. | Server-side verification required; success is not OTP success and not step-up success. |
| Step-up | Passkey/WebAuthn assertion for existing phone identity with enrolled factor. | If no existing identity or no enrolled factor, high-risk flow returns block instead of bypassing step-up. |
| Audit | Reuse existing `audit_logs` / `AuditLogService` pattern where feasible. | Do not create a competing audit source unless existing schema cannot support required retention/query boundaries. |
| Retention | Add OTP cleanup job following existing retention job patterns. | Challenge/hash material expires or is deleted within 24 hours after expiry. |

## Evidence Reference Format
| Evidence type | Required variable/ref | Accepted format | Placeholder values rejected |
| --- | --- | --- | --- |
| SMS provider config | `SMS_PROVIDER_CONFIG_REF` | `vault://prod/identity/sms/<provider>` | yes |
| SMS provider evidence | `SMS_PROVIDER_EVIDENCE_REF` | `evidence://identity/otp/sms-provider/<yyyy-mm-dd>/<run-id>` | yes |
| Phone risk config | `PHONE_RISK_PROVIDER_CONFIG_REF` | `vault://prod/identity/phone-risk/<provider>` | yes |
| Phone risk evidence | `PHONE_RISK_PROVIDER_EVIDENCE_REF` | `evidence://identity/otp/phone-risk/<yyyy-mm-dd>/<run-id>` | yes |
| Phone risk covered countries | `PHONE_RISK_COVERED_COUNTRIES` | ISO-3166 alpha-2 comma list covering every `SPEAKEASY_OTP_ALLOWED_COUNTRIES` value | yes |
| `CN` SIM-swap evidence | `PHONE_RISK_CN_SIM_SWAP_EVIDENCE_REF` | `evidence://identity/otp/phone-risk/cn-sim-swap/<yyyy-mm-dd>/<run-id>` | yes |
| CAPTCHA config | `CAPTCHA_PROVIDER_CONFIG_REF` | `vault://prod/identity/captcha/<provider>` | yes |
| CAPTCHA evidence | `CAPTCHA_PROVIDER_EVIDENCE_REF` | `evidence://identity/otp/captcha/<yyyy-mm-dd>/<run-id>` | yes |
| Step-up config | `STEP_UP_PROVIDER_CONFIG_REF` | `vault://prod/identity/step-up/<provider>` | yes |
| Step-up evidence | `STEP_UP_PROVIDER_EVIDENCE_REF` | `evidence://identity/otp/step-up/<yyyy-mm-dd>/<run-id>` | yes |
| HTTPS evidence | `HTTPS_ENFORCEMENT_EVIDENCE_REF` | `evidence://identity/otp/https/<yyyy-mm-dd>/<run-id>` | yes |
| Trusted proxy config | `TRUSTED_PROXY_CONFIG_REF` | `vault://prod/identity/network/trusted-proxy` | yes |
| OTP HMAC secret | `OTP_HMAC_SECRET_REF` | `vault://prod/identity/otp/hmac-secret` | yes |
| OTP retention evidence | `OTP_RETENTION_EVIDENCE_REF` | `evidence://identity/otp/retention/<yyyy-mm-dd>/<run-id>` | yes |

## Data Model Targets
| Data object | Required fields / behavior | Status |
| --- | --- | --- |
| `otp_challenges` | challenge id, phone E.164, purpose, status, hash version, HMAC digest, sent/active/expiry/consumed timestamps, attempts, context hash, risk decision, step-up state | Backend implemented - provider/release evidence pending |
| `otp_rate_counters` | subject type, subject hash, purpose, window start/end, count, atomic increment | Backend implemented - provider/release evidence pending |
| `otp_failure_locks` | phone hash, purpose, failure count, window start, locked until | Backend implemented - provider/release evidence pending |
| `audit_logs` OTP events | event type, actor type, target ref, redacted details, request id, created at, retention policy version in details | Backend implemented - provider/release evidence pending |
| retention cleanup | scheduled or operator-runnable cleanup that deletes/invalidates expired challenge/hash material within 24 hours | Backend implemented - provider/release evidence pending |

## Auth Integration Rule
`AuthService.loginPhone(...)` 必须先调用 OTP verification/consume，只能把已 consumed 且 verified 的 E.164 phone subject 传入既有 `loginOrCreate("phone", consumedVerifiedE164Phone, "Phone User")`。不允许第二套 account lifecycle implementation。
