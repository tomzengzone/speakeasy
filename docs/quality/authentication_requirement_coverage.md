# Authentication Chapter 8 Requirement Coverage

## Audit context

- Source baseline: `docs/authentication_session_token_lifecycle_requirements.md`, Chapter 8.
- Audit date: 2026-08-30.
- Code baseline before this closure: `209139905220c268f6144df3c2df6b8dc6e3949a`.
- Remediation commits: `d27f61e` (CI baseline), `c750d9b` (server-owned grant policy), `9b26ecd` (client token recovery hardening), `835d246` (upgrade-safe secure credential migration).
- Scope rule: this is an evidence projection over the standalone requirement baseline. It does not approve a Story, FR, Engineering Contract, or new product behavior.

Status semantics:

- `PASS`: current production path and executable evidence satisfy the requirement.
- `PARTIAL`: material behavior exists, but a stated part of the requirement lacks implementation or proof.
- `FAIL`: the required behavior is absent or contradicted by the current production path.
- `N/A`: the conditional mechanism is not adopted by the current architecture.

## Summary

| Status | Count | Share |
| --- | ---: | ---: |
| PASS | 66 | 79.5% |
| PARTIAL | 8 | 9.6% |
| FAIL | 6 | 7.2% |
| N/A | 3 | 3.6% |
| Total | 83 | 100% |

The implementation is not a full Phase 2 / Phase 3 maturity closure. The remaining failures require product, lifecycle, UX, cancellation, or observability decisions rather than another broad authentication rewrite.

## 8.1 Login and identity normalization

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| AUTH-001 | PARTIAL | `AuthService`, `AuthIdentity`, `AuthSession`, and phone/Apple/WeChat controller tests converge supported backend login providers on the same opaque token/session model. | Flutter email/password remains a local demo path and does not establish the canonical backend session/token model. |
| AUTH-002 | PASS | Provider verifiers terminate at `AuthService`; `BearerTokenAuthenticationFilter` accepts only SpeakEasy opaque access tokens for business APIs. | — |
| AUTH-003 | PASS | Provider verification, account-state checks, fail-closed provider configuration, and account/device/network rate limits are covered by `AuthProviderFailClosedHttpTest`, `AuthRateLimitHttpTest`, and auth service tests. | — |
| AUTH-004 | PASS | Mobile requests use a public `client_id`; no mobile client secret exists in production Flutter configuration or auth payloads. | — |
| AUTH-005 | N/A | The current mobile architecture uses native phone/Apple/WeChat exchange APIs and does not implement browser OAuth/OIDC authorization. | PKCE/state/nonce/redirect requirements become applicable if browser authorization is introduced. |
| AUTH-006 | PASS | Production Flutter contains no embedded OAuth credential WebView path; Apple and WeChat use their native service boundaries. | — |
| AUTH-007 | PARTIAL | Phone verification enters the canonical backend Session/Token model. | A real first-party email verification/login path is absent; the visible email/password path is local demo behavior. |
| AUTH-008 | PASS | Apple/WeChat identity material is verified/exchanged by backend provider adapters; business APIs receive only SpeakEasy access tokens. | — |

## 8.2 Token issuance and validation

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| TOKEN-001 | PASS | `AuthService` defaults `speakeasy.auth.access-token-ttl` to 15 minutes and accepts server configuration; lifecycle tests cover expiry. | — |
| TOKEN-002 | PASS | `MobileClientGrantPolicy`, `AuthRefreshTokenFamily`, and `AuthAccessToken` own the fixed first-party client, audience, and least-privilege scope snapshot; `AuthGrantPolicyIntegrationTest` covers scope isolation and inheritance. | — |
| TOKEN-003 | PASS | The selected format is opaque. `AuthAccessToken` is a hash-backed registry and `BearerTokenAuthenticationFilter` is the controlled resource-server validation entry. | JWT signing and `kid` rotation are not applicable to the selected opaque format. |
| TOKEN-004 | PASS | The bearer filter checks token registry state, expiry, client, audience, scope, session/security epoch, and account state before endpoint scope authorization. | — |
| TOKEN-005 | PASS | Flutter treats tokens as opaque credentials; final authentication and authorization decisions remain in the backend filter and Spring Security. | — |
| TOKEN-006 | PASS | Refresh tokens are generated as high-entropy opaque values and only `TokenHasher` digests plus family metadata are persisted. | — |
| TOKEN-007 | PASS | `AuthRefreshTokenFamily` binds the refresh grant to user, session, client, audience, and scope; refresh inherits that snapshot. | — |
| TOKEN-008 | PASS | Refresh tokens are confined to the refresh API and encrypted credential store; audit redaction and `credential_log_scan_test.dart` cover production log leakage. | — |

## 8.3 Refresh token rotation

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| REFRESH-001 | PASS | `AuthService.refresh` issues a new access/refresh pair; `AuthSessionLifecycleTest` and controller tests verify rotation. | — |
| REFRESH-002 | PASS | The consumed refresh token changes state and the child token preserves its family/parent lineage. | — |
| REFRESH-003 | PASS | Refresh mutation is transactional and concurrency is covered against PostgreSQL by `AuthConcurrencyPostgresTest`. | — |
| REFRESH-004 | PASS | Reuse detection revokes the family and session, emits audit/metrics, and returns `TOKEN_REUSE_DETECTED`; Phase 3 tests verify the path. | — |
| REFRESH-005 | PASS | Idle/absolute expiry, account disable, revocation, invalid, expired, and reuse paths produce stable machine codes covered by lifecycle/security tests. | — |
| REFRESH-006 | PASS | `AuthRateLimitService`, bounded rate-limit dimensions, `AuthMetrics`, and `AuthAuditService` cover refresh limiting and redacted outcomes. | — |
| REFRESH-007 | PASS | Refresh calls execute with `AuthPolicy.none`; `authenticated_request_executor_test.dart` proves a refresh 401 cannot recursively refresh. | — |
| REFRESH-008 | PASS | `CredentialRepository.replaceIfCurrent` serializes and atomically replaces the complete credential set; repository and coordinator tests cover logout/account-switch races. | — |

## 8.4 Client requests and automatic recovery

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| CLIENT-001 | PASS | Authenticated `ApiClient` calls pass through `AuthenticatedRequestExecutor`, which injects the current access token. | — |
| CLIENT-002 | PASS | Business features call `ApiClient`; refresh token reads, refresh execution, and terminal logout remain in the auth core. | — |
| CLIENT-003 | PASS | `AuthCredentials.needsRefreshAt` and `RefreshCoordinator` refresh within the 60-second safety window; proactive tests cover it. | — |
| CLIENT-004 | PASS | The executor parses the structured code and refreshes/retries exactly once only for `401 ACCESS_TOKEN_EXPIRED`. | — |
| CLIENT-005 | PASS | `ACCESS_TOKEN_INVALID`, `SESSION_REVOKED`, `ACCOUNT_DISABLED`, and generic `UNAUTHENTICATED` do not refresh; terminal codes clear credentials through `ApiClient`. | — |
| CLIENT-006 | PASS | Executor retry count is capped at one and refresh calls use `AuthPolicy.none`; loop-prevention tests cover both boundaries. | — |
| CLIENT-007 | PASS | 403 responses bypass refresh; scope/entitlement handling remains outside the authentication retry path. | — |
| CLIENT-008 | PASS | Authentication retry reuses the original headers/body callback, including any Idempotency-Key; backend authentication occurs before controller writes. | — |
| CLIENT-009 | FAIL | No cancellation token or disposed-request signal is propagated through `AuthenticatedRequestExecutor` and the refresh wait path. | Define a client cancellation contract and prove a cancelled waiter is not replayed. |
| CLIENT-010 | PASS | `RefreshCoordinator` bounds waiting callers (default 64) and wait time (default 15 seconds); queue-limit and timeout tests prove rejection without cancelling the owner refresh. | — |

## 8.5 Single-flight refresh

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| CONCURRENCY-001 | PASS | `RefreshCoordinator._inFlightRefresh` permits one owner refresh per process. | — |
| CONCURRENCY-002 | PASS | Concurrent callers await the same in-flight Future subject to the new queue bound and timeout. | — |
| CONCURRENCY-003 | PASS | Successful waiters receive and use the same rotated credential generation; concurrent executor tests cover the behavior. | — |
| CONCURRENCY-004 | PASS | Authentication failure is shared by waiting calls, while `ApiClient` publishes one terminal session-security path. | — |
| CONCURRENCY-005 | PASS | Infrastructure/rate-limit failures preserve credentials and propagate retryable failures; coordinator tests cover both classes. | — |

## 8.6 App startup and lifecycle restoration

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| RESTORE-001 | FAIL | Startup restoration exists in `SessionLifecycleCoordinator`, but the application has no explicit `INITIALIZING` auth state that gates authenticated UI until resolution. | Add an approved startup state-machine/UI contract before implementation. |
| RESTORE-002 | PARTIAL | Hydration checks secure credential expiry and refreshes when needed; legacy Hive access-token recovery was removed. | `loadStoredSession` may project a cached user before server hydration and lacks a single explicit authoritative auth state. |
| RESTORE-003 | PASS | Healthy secure credentials restore through `/user/me`; lifecycle tests verify no unnecessary refresh and current-user validation. | — |
| RESTORE-004 | PASS | Expired credentials refresh before session hydration; authentication failure does not fall back to the old access token. | — |
| RESTORE-005 | FAIL | No app lifecycle observer calls the shared coordinator on foreground resume. | Define foreground-refresh ownership and add lifecycle/widget evidence. |
| RESTORE-006 | PARTIAL | Refresh infrastructure failure preserves valid credentials and may fall back to `/user/me`; expired credentials are not erased solely for a network error. | The UI lacks an explicit recoverable offline/degraded auth state and end-to-end evidence. |

## 8.7 Logout and session revocation

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| LOGOUT-001 | PASS | Current-device logout calls the backend and revokes the Session/Token Family. | — |
| LOGOUT-002 | PASS | App logout attempts the server first and clears credentials, profile, stats, and auth memory even on network failure; tests cover order and warning copy. | — |
| LOGOUT-003 | PASS | Local cleanup deletes the encrypted credential set and legacy auth session; no plaintext refresh token is queued for later revocation. | — |
| LOGOUT-004 | PASS | Backend `logout-all` revokes all user sessions; device-session API/client tests cover the endpoint. | — |
| LOGOUT-005 | PASS | Targeted session delete scopes revocation to the selected session; account-security API tests cover it. | — |
| LOGOUT-006 | PASS | Normal logout, terminal security logout, and account deletion use distinct operations/audit reasons and user copy. | — |

## 8.8 Multiple devices and security events

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| SESSION-001 | PASS | Installation ID and device metadata create independent server sessions; account-security tests create multiple devices. | — |
| SESSION-002 | PASS | Session list API and `DeviceSessionsPage` expose current/other devices with minimized metadata. | — |
| SESSION-003 | PASS | The user can revoke one device or all other devices through the canonical session endpoints and Flutter coordinator. | — |
| SESSION-004 | FAIL | No production password reset/change, verified email replacement, social relink, or account recovery use case invokes full session revocation. `revokeForHighRiskCredentialChange` is an unconnected helper. | Product Manager must first approve credential-recovery behavior and decide whether password change preserves the current session; then backend/test ownership can implement CR001-CR004 evidence. |
| SESSION-005 | PASS | Account disable increments security state and revokes all sessions; Phase 3 tests verify existing credentials fail. | — |
| SESSION-006 | PASS | Refresh-token reuse revokes the affected family and session and publishes a security event. | — |
| SESSION-007 | PASS | Admin revocation records actor, reason, time, and audit reference through account-security/audit boundaries without tokens. | — |

## 8.9 Credential storage

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| STORAGE-001 | PASS | Complete credentials are persisted through `flutter_secure_storage`, backed by Keychain/Keystore on supported platforms. | — |
| STORAGE-002 | PASS | Cross-startup access tokens exist only in the encrypted credential set; the first credential read clears any legacy Hive access token and neither `ApiClient` nor lifecycle restoration uses it. | — |
| STORAGE-003 | PASS | One encrypted JSON value stores the complete pair and repository serialization prevents partial replacement. | — |
| STORAGE-004 | PASS | Production refresh tokens are absent from SharedPreferences/Hive; legacy cleanup runs on credential replacement and clear. | — |
| STORAGE-005 | PASS | Logout, account deletion, revoked/disabled/reuse, refresh-terminal failures, and `ACCESS_TOKEN_INVALID` clear the full secure credential set. | — |
| STORAGE-006 | PASS | iOS migrates v1 credentials by writing a `first_unlock_this_device`, non-synchronizing v2 item before deleting v1; Android disables credential backup migration while retaining the existing namespace, and the manifest sets `allowBackup=false`. | — |

## 8.10 Errors, UX, and degradation

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| ERROR-001 | PASS | Backend `ApiException` responses provide structured machine code, safe message, and request ID; auth controller tests assert envelopes. | — |
| ERROR-002 | PASS | Flutter routes on generated `ErrorCode`/structured `error.code`, including exact `ACCESS_TOKEN_EXPIRED`, rather than reason phrases. | — |
| ERROR-003 | PASS | Network, TLS, DNS, 5xx, and rate-limit/infrastructure refresh failures preserve credentials and are not terminal logout conditions. | — |
| ERROR-004 | PASS | Only mapped refresh/session/access-token terminal codes publish `SessionSecurityFailure` and clear credentials. | — |
| ERROR-005 | PASS | Successful proactive/reactive refresh is transparent; executor tests complete without emitting an auth error. | — |
| ERROR-006 | PARTIAL | Distinct terminal failures publish safe re-login copy and clear the session. | The application does not preserve and restore an intended navigation target after re-authentication. |
| ERROR-007 | PARTIAL | 401 security failures and 403 authorization/entitlement failures take different lower-level paths. | Cross-screen UX evidence for a consistent recovery path is incomplete. |
| ERROR-008 | FAIL | TTS/audio presentation can still surface playback failure after an upstream authentication failure. | Route terminal auth state ahead of feature error copy and add TTS/widget end-to-end tests. |

## 8.11 Security, privacy, and observability

| ID | Status | Current evidence | Gap or decision |
| --- | --- | --- | --- |
| SECURITY-001 | PASS | Release configuration requires HTTPS, main/profile manifests do not enable cleartext, debug-only cleartext is isolated, and Android backup is disabled. | Deployment termination/certificate evidence remains a release-environment concern, not a code gap. |
| SECURITY-002 | PASS | The mobile client uses a public client identifier and contains no client secret. | — |
| SECURITY-003 | PASS | Credential log scanning, audit redaction, and code boundaries exclude tokens, verification codes, provider authorization codes, and Authorization headers from production logs. | — |
| SECURITY-004 | PASS | Authentication audit/metrics use bounded outcomes and redacted identifiers; no raw token labels are emitted. | — |
| SECURITY-005 | PASS | Login/refresh endpoints enforce account, device, and network dimensions with fail-closed store behavior and anomaly metrics/alerts. | — |
| SECURITY-006 | N/A | Opaque tokens are selected, so JWT signing-key rotation is not part of this architecture. | Protect/rotate the hashing and rate-limit secrets operationally; signing-key controls apply if JWT is later adopted. |
| SECURITY-007 | PARTIAL | Session device metadata is constrained and network identifiers are hashed/minimized. | No authoritative retention period for device/network metadata is recorded. |
| SECURITY-008 | N/A | Certificate pinning is not adopted. | If risk review later adopts it, add rotation and failure-recovery design before implementation. |
| OBS-001 | PARTIAL | `AuthMetrics` covers login, refresh outcome/reason, unauthorized access, token reuse, revocation, security operations, and rate limits. | There is no explicit Force Logout counter that distinguishes client terminal logout volume. |
| OBS-002 | FAIL | Authentication HTTP metrics hard-code `api_family=bearer` and do not include bounded app-version or platform labels. | Define safe-cardinality labels and propagate trusted platform/app-version/API-family context. |
| OBS-003 | PASS | Prometheus rules, runbook, checker, and checker tests cover refresh-failure spikes, 401 spikes, token reuse, revocation/audit failures, and rate-limit store failures. Signature-validation alerts are inapplicable to opaque access tokens. | — |

## Remaining work ordered by severity

### P0

No open P0 item was found after restoring the authoritative GitHub CI baseline.

### P1

1. `SESSION-004`: Product Manager approval for password reset/change and high-risk credential recovery semantics, followed by full-session revocation implementation and CR001-CR004 tests.
2. `RESTORE-001`: approved startup authentication state machine with explicit `INITIALIZING` gating.
3. `ERROR-008`: auth-first TTS/business error routing so terminal authentication never degrades into playback copy.

### P2

1. `CLIENT-009`: cancellation-aware refresh wait and replay contract.
2. `RESTORE-005`: foreground-resume token check through the existing coordinator.
3. `RESTORE-002` / `RESTORE-006`: one authoritative restored/offline/degraded auth state and end-to-end evidence.
4. `ERROR-006` / `ERROR-007`: preserved navigation target and consistent 401/403 recovery UX.
5. `SECURITY-007`: authoritative device/network metadata retention period.
6. `OBS-001` / `OBS-002`: explicit force-logout metric and bounded platform/app-version/API-family aggregation.
