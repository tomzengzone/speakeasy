# Authentication alerts

These runbooks cover the Phase 3 account-security alerts. Use only low-cardinality
metric labels when investigating. Never put tokens, authorization headers, user or
session identifiers, device identifiers, IP addresses, or request identifiers into
Prometheus labels or incident chat.

## Refresh failure rate high

The alert fires when more than 5% of at least 100 refresh attempts fail during a
ten-minute window.

1. Compare failure outcomes (`invalid`, `expired`, `revoked`, and `token_reuse`)
   without adding identity labels.
2. Check recent authentication deployments and datastore health.
3. If failures are dominated by `token_reuse`, follow the token-reuse runbook.
4. Roll back the latest authentication deployment if the increase correlates with
   that deployment and rollback is safer than forward repair.

## HTTP 401 rate high

The alert uses a fixed initial safety threshold: more than 3% of at least 100
backend HTTP requests return 401 within ten minutes. Replace this rule with a
baseline-relative recording rule only after representative production history is
available.

1. Break down results by low-cardinality route template and deployment version.
2. Compare authentication failures with total request volume and refresh failures.
3. Check identity-provider, database, and clock-health signals.
4. Do not weaken authentication or restore revoked sessions to reduce the rate.

## Token reuse detected

One or two token reuse events within five minutes produce this warning.

1. Confirm that the affected token family was revoked and cannot refresh again.
2. Check the security audit stream for a matching redacted event.
3. If three events accumulate in five minutes, follow the critical burst response.

## Token reuse burst

Three or more token reuse events within five minutes indicate a critical security
event.

1. Page the security on-call and preserve relevant redacted audit evidence.
2. Confirm token-family revocation is succeeding and inspect operation-failure alerts.
3. Compare provider, platform, and application-version aggregates only; do not add
   identity data to metric labels.
4. If compromise scope cannot be bounded, use the approved account/session
   revocation procedure.

## Security operation failed

This critical alert covers failed `session_revoke` and `account_disable` operations.

1. Identify the failed low-cardinality `operation` label.
2. Check database availability, transaction failures, and application errors using
   the protected log platform.
3. Verify the requested security state directly before retrying the operation.
4. Escalate immediately if an access or refresh token remains usable after a
   requested revocation or account disable.

## Security audit write failed

Authentication security actions fail closed when their required audit record cannot
be written. This alert is therefore critical even when the enclosing transaction
was rolled back successfully.

1. Check audit storage availability and serialization errors.
2. Verify whether the enclosing security operation committed or rolled back.
3. Restore audit writes before retrying the security operation.
4. Record incident evidence outside Prometheus labels and without credentials.

## Authentication endpoint latency high

The alert fires when the five-minute p95 latency estimate for authentication route
templates stays above 500 milliseconds for ten minutes.

1. Check request volume and latency by route template.
2. Inspect database pool saturation and identity-provider latency.
3. Confirm that retries are bounded and are not amplifying load.
4. Roll back a correlated deployment if rollback is safe and the security model is
   preserved.

## Authentication rate limit burst

The alert fires when one bounded endpoint/dimension pair blocks at least 100
requests per five minutes for five minutes. It does not expose the affected
identifier.

1. Distinguish an expected attack response from thresholds that are rejecting
   legitimate traffic by comparing aggregate login and refresh success rates.
2. Check edge/WAF request volume and trusted-proxy configuration without copying
   IP addresses, tokens, device identifiers, or user identifiers into alert labels.
3. Inspect deduplicated `auth_rate_limit_blocked` audit events in the protected
   audit store and correlate by request ID only within access-controlled tooling.
4. Do not disable application enforcement during an active attack. Use the
   approved per-endpoint threshold change and rollback procedure if tuning is needed.

## Authentication rate limit store unavailable

Any shared limiter storage error triggers this critical alert. `observe` mode
continues requests and `enforce` mode returns `503 AUTH_SERVICE_UNAVAILABLE`.

1. Check Redis availability, latency, connection saturation, failover state, and
   application connectivity.
2. Confirm which rollout mode is active and monitor authentication 503s; do not
   silently switch enforcement mode without incident-owner approval.
3. Restore the shared Redis path and verify a multi-instance bucket before closing
   the incident.
4. Confirm audit and metrics pipelines recovered; deduplication failures must not
   alter the authentication decision.

## Metric dependencies

| Prometheus metric | Required labels | Producer |
| --- | --- | --- |
| `speakeasy_auth_refresh_total` | `application`, `outcome`, `reason` | `AuthMetrics.refresh`; outcome is `success` or `failure`, and reason is bounded |
| `speakeasy_auth_http_total` | `application`, `api_family`, `outcome` | `AuthMetrics.access`; bearer authentication result counter used for the initial 401-rate rule |
| `speakeasy_auth_token_reuse_total` | `application` | Dedicated `AuthMetrics.refresh` token-reuse counter |
| `speakeasy_auth_security_operation_total` | `application`, `operation`, `outcome` | Security operation counter; operation is `session_revoke` or `account_disable` for these rules |
| `speakeasy_auth_security_operation_total` | `application`, `operation=audit_write`, `outcome` | Required authentication audit write result counter |
| `speakeasy_auth_rate_limit_total` | `application`, `endpoint`, `dimension`, `outcome` | Bounded authentication limiter decisions; never contains the raw identifier |
| `http_server_requests_seconds_bucket` | `application`, `uri`, `le` | Micrometer HTTP histogram; histogram publishing must be enabled |

Allowed authentication metric dimensions are bounded values such as `provider`,
`outcome`, `operation`, `event`, `platform`, and coarse application-version groups.
The metrics must not carry `user`, `user_id`, `session`, `session_id`, `device`,
`device_id`, `request`, `request_id`, token, authorization, or IP labels.
