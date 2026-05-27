# Data Flow

## 状态
Proposed - whole-app architecture。本文描述跨模块数据流，不替代 API schema、domain schema 或 AI output schema。

## Shared Flow Rules
- 服务端是用户、权益、用量、训练 session、学习证据和审计的最终事实源。
- Flutter 本地状态只作为缓存、离线兜底或会话恢复草稿。
- Provider payload 不直接进入客户端；后端只返回经过 schema validation 和脱敏后的字段。
- 所有高成本 provider 调用先经过 entitlement/usage check。
- 学习证据写回必须保留 rule trace，不由 LLM 自由文本直接修改最终掌握状态。

## P0 Subscription Purchase / Restore Flow
```text
Flutter membership/paywall
  -> platform purchase sheet
  -> client receives platform transaction token
  -> POST /subscriptions/apple|google/verify
  -> backend verifies with Apple/Google
  -> subscription state machine updates Purchase, Subscription, EntitlementSnapshot
  -> audit log writes payment event
  -> GET /entitlements refreshes client display cache
  -> UI unlocks or shows recoverable failure
```

Failure paths:
- invalid receipt -> `INVALID_RECEIPT` and no entitlement change;
- restored purchase empty -> typed empty restore state;
- refund/revocation/expiration webhook -> entitlement downgraded on server, client refresh shows downgraded state;
- network failure after platform purchase -> client retries verify with idempotency key.

## P0 Commercial Usage Flow
```text
Flutter requests AI/ASR/TTS/scoring
  -> backend checks auth
  -> backend checks entitlement
  -> backend reserves usage quota
  -> backend calls provider through AI Gateway
  -> backend validates provider/AI schema
  -> backend commits or releases usage reservation
  -> backend returns typed result or fallback
```

Rules:
- Quota cannot be decremented only on the client.
- Provider timeout must release or mark usage according to an auditable rule.
- Abuse detection consumes request metadata, not raw sensitive audio payloads.

## P0.1 Micro-Action Training Turn Flow
```text
Flutter training screen
  -> current TrainingSession loaded
  -> learner completes micro-action
  -> audio/transcript submitted to /training/sessions/{id}/turns
  -> Training Planner evaluates deterministic state
  -> AI Gateway requests structured feedback if needed
  -> schema validation filters AI output
  -> planner decides retry / hint / next micro-action / pressure check / complete
  -> learning evidence candidates are generated
  -> deterministic evidence rule writes accepted evidence
  -> Flutter renders one next action
```

State boundaries:
- Action chain and micro-action state are domain objects.
- LLM may suggest feedback and follow-up prompt.
- Planner decides whether a step is satisfied.
- Mastery/evidence updates include source turn, rule trace, schema version, and timestamp.

## Product Base Practice Turn Flow
```text
Scenario selection
  -> PracticeSession start/resume
  -> learner voice turn
  -> ASR or fallback transcript
  -> AI coach feedback
  -> correction / saved expression candidate
  -> summary
  -> local and eventually backend learning evidence
  -> home / queue / wiki refresh
```

This flow remains supported as Product Base behavior while P0.1 introduces stricter planner boundaries.

## AI Provider Fallback Flow
```text
Provider request
  -> timeout/error/invalid JSON
  -> typed fallback from AI Gateway
  -> no mastery mutation
  -> UI shows recoverable state
  -> observability event with request_id and provider label
```

Fallback output may provide a safe next action, but cannot complete a session or write final learning evidence unless deterministic rules confirm the required state.

## Account Deletion And Data Retention Flow
```text
Flutter account deletion confirmation
  -> DELETE /user/me
  -> backend creates deletion job
  -> token/session revoked
  -> local session data cleared
  -> backend deletes or anonymizes user profile, learning data, audio refs, transcripts, entitlement links
  -> audit log records deletion without sensitive payload
  -> user sees completion or in-progress state
```

Deletion must define:
- which data is hard-deleted;
- which data is anonymized for legal/accounting/audit reasons;
- retention duration for audio/transcripts/provider payloads;
- retry and manual ops path for failed deletion jobs.

## Observability Flow
```text
Flutter request
  -> request_id / trace context
  -> backend structured logs
  -> OpenTelemetry trace and metrics
  -> Sentry client crash/performance signal
  -> release dashboard and incident triage
```

Minimum attributes:
- app version, platform, feature area, request_id;
- provider label, not raw provider secret or raw audio;
- entitlement status class, not full payment credential;
- schema version and validation result.

## Release Flow
```text
PR / release candidate
  -> document traceability gate
  -> contract/schema/test gate
  -> commercial boundary test matrix
  -> release secrets/config gate
  -> store metadata and privacy declaration check
  -> staged rollout
  -> monitor Sentry/OpenTelemetry/payment webhooks
  -> rollback or feature flag disable if needed
```

P0 paid release must not proceed while entitlement, usage, account deletion, commercial copy, or rollback evidence is missing.
