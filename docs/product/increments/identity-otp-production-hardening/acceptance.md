# Acceptance Criteria：Identity OTP Production Hardening

## 状态
Backend API/DB/domain/core evidence added. AC 行已记录后端测试证据，但未因缺少 provider/release evidence、Dart client drift closure 和独立审查而升级为商业验收通过。

## 上游来源
- `docs/product/increments/identity-otp-production-hardening/requirements.md`
- `docs/product/increments/identity-otp-production-hardening/spec.md`
- Product Base `docs/product/base/identity-account-lifecycle/spec.md`

## Acceptance Criteria
| AC ID | Upstream Requirement | Pass/fail acceptance criteria | Status |
| --- | --- | --- | --- |
| AC-OTP-PROD-004 | IDENTITY-OTP-004 | Given any OTP send or verify request, when `phone_number` is received, then the server must normalize it to supported E.164 before any challenge/session action; invalid or unsupported numbers must return `OTP_INVALID_PHONE` and create no challenge/session. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-005 | IDENTITY-OTP-005 | Given OTP send succeeds, then only an OTP challenge may exist; no account, identity, access token, refresh token or auth session may be created. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-006 | IDENTITY-OTP-006 | Given a challenge becomes active, then it must bind E.164 phone, `purpose=login_or_register`, unpredictable `challenge_id`, server-owned context and expiry timestamp. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-007 | IDENTITY-OTP-007 | Given a code is generated, then it must come from service-side cryptographically secure randomness and not from deterministic/test generation in production. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-032 | IDENTITY-OTP-032 | Given OTP digit length configuration is loaded, then default length must be 6 digits and production config below 6 digits must fail startup or release guard. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-008 | IDENTITY-OTP-008 | Given a challenge is active, then it is verifiable for 5 minutes by default and never more than 10 configured minutes; expired challenges must return `OTP_EXPIRED` and cannot create session. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-009 | IDENTITY-OTP-009 | Given any OTP value exists, then plaintext OTP may only be passed to SMS provider and must never be persisted, logged or returned in API errors/responses. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-010 | IDENTITY-OTP-010 | Given OTP validation is stored, then stored verifier must be HMAC/secret-peppered, bound to challenge and E.164 phone, and validated using constant-time compare. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-011 | IDENTITY-OTP-011 | Given OTP send is requested, then current terms/privacy consent and matching `consent_version` must be verified before provider send; missing/mismatched consent returns `OTP_CONSENT_REQUIRED`. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-012 | IDENTITY-OTP-012 | Given same phone requests another OTP before 60 seconds, then system returns `OTP_RATE_LIMITED` and sends no SMS. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-013 | IDENTITY-OTP-013 | Given same phone exceeds 5 sends/hour or 10 sends/day defaults, then system returns `OTP_RATE_LIMITED` and sends no SMS. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-014 | IDENTITY-OTP-014 | Given same IP/device/install_id exceeds configured limits, then system returns `OTP_RATE_LIMITED` and sends no SMS, even if phone limit is not reached. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-015 | IDENTITY-OTP-015 | Given resend succeeds, then previous active challenge becomes invalidated, cannot verify, and phone+purpose failure counters remain unchanged. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-016 | IDENTITY-OTP-016 | Given one challenge receives more than 5 wrong verification attempts, then challenge is invalidated/locked and cannot later verify successfully. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-017 | IDENTITY-OTP-017 | Given phone+purpose reaches 10 wrong attempts in 30 minutes, then OTP send and verify are locked for 15 minutes and return `OTP_ATTEMPTS_LOCKED`. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-018 | IDENTITY-OTP-018 | Given correct OTP is submitted concurrently or repeatedly, then exactly one transaction can consume the challenge; all replays fail and create no extra session. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-033 | IDENTITY-OTP-033 | Given challenge is not consumed, then account creation, identity resolution and session issuance must not be reachable; only consumed challenge may enter `loginOrCreate`. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-019 | IDENTITY-OTP-019 | Given challenge is correctly consumed and all risk/step-up gates pass, then system returns access token, refresh token and session expiry using the existing session lifecycle. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-020 | IDENTITY-OTP-020 | Given an existing phone identity maps to the verified E.164 subject, then login resolves that original user and does not create a duplicate account. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-021 | IDENTITY-OTP-021 | Given verified E.164 phone has no existing identity, then system creates account, initial phone identity and default profile through existing account lifecycle rules. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-022 | IDENTITY-OTP-022 | Given any OTP error happens, then API response must not reveal whether the phone number is registered or new. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-023 | IDENTITY-OTP-023 | Given SMS provider send fails, then API returns provider failure, no active/verifiable challenge is returned, and no account/session is created. | Backend fail-closed boundary covered - live SMS evidence pending |
| AC-OTP-PROD-025 | IDENTITY-OTP-025 | Given SMS content is rendered, then it contains only App name, OTP, expiry and risk warning; it contains no user id, token, profile, account or session data. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-026 | IDENTITY-OTP-026 | Given production OTP endpoint is called over non-secure transport or untrusted forwarded headers, then request is rejected or proven blocked by gateway evidence. | Backend secure-transport gate covered - trusted proxy/release evidence pending |
| AC-OTP-PROD-027 | IDENTITY-OTP-027 | Given OTP send, verify success, verify failure, expiry, rate limit or provider failure occurs, then a corresponding audit event is recorded. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-034 | IDENTITY-OTP-034 | Given OTP audit event is stored, then it contains only hashed/redacted phone, purpose, request id, risk decision and safe metadata; no OTP/token plaintext appears. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-028 | IDENTITY-OTP-028 | Given OTP risk evaluation runs, then it includes SIM swap or number-transfer intelligence, abnormal IP/device/install_id and short-window request signals for every allowed country. | Backend risk policy gate covered - phone-risk provider evidence pending |
| AC-OTP-PROD-035 | IDENTITY-OTP-035 | Given risk decision is block, then system does not send OTP, does not verify OTP and does not issue session; response is `OTP_RISK_BLOCKED`. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-036 | IDENTITY-OTP-036 | Given risk decision is step-up, then session is denied until a distinct step-up proof succeeds; CAPTCHA success alone must not satisfy this proof. | Backend step-up denial boundary covered - step-up provider evidence pending |
| AC-OTP-PROD-029 | IDENTITY-OTP-029 | Given CAPTCHA is required and missing/failed, then no OTP is sent and no session is issued; given CAPTCHA passes, OTP verification is still required. | Backend CAPTCHA fail-closed boundary covered - CAPTCHA provider evidence pending |
| AC-OTP-PROD-030 | IDENTITY-OTP-030 | Given challenge/hash material is expired, then cleanup deletes or irreversibly invalidates it within 24 hours and evidence records execution. | Backend cleanup scheduler boundary covered - retention release evidence pending |
| AC-OTP-PROD-037 | IDENTITY-OTP-037 | Given OTP audit events are retained, then only redacted data and retention policy version are retained according to policy. | Backend slice covered - provider/release evidence pending |
| AC-OTP-PROD-024 | IDENTITY-OTP-024 | Given production release gate runs, then deterministic/test/fake OTP provider or placeholder/missing OTP provider evidence blocks release. | Backend release guard expanded - strict release blocked until refs land |

## Acceptance Gate
所有 AC 行在路由到代码实现前，必须映射到 `test_cases.md` 中稳定的 TC ID。没有代码证据、测试证据、适用的 release evidence 和独立审查时，任何行都不得升级为商业验收通过。
