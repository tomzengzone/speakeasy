# ADR 0005: DashScope Provider Adapter Behind Current AI Gateway

## Status
Proposed - implementation and independent review pending.

## Context
P0.1 training and commercial usage control need real LLM/TTS/ASR capability, but the project must not switch to the old `speakeasy_backend_export` backend. The old backend is only a provider integration reference for DashScope Qwen, Paraformer ASR and TTS.

The current backend already owns AI REST, usage reservation and provider isolation through `AiProviderGateway`.

## Decision
Add a configurable DashScope provider adapter inside the current Spring Boot backend:

- `deterministic` provider remains the default for local development and CI.
- `dashscope` provider implements Qwen LLM, DashScope TTS and Paraformer ASR behind the existing `AiProviderGateway`.
- Flutter continues to call only the existing AI REST endpoints.
- Provider credentials stay server-side.
- Provider output is normalized into `TranscribeResult`, `TtsResult`, `ScoreResult` and `CoachResult`.
- Invalid JSON, unavailable provider, unsupported media ref, empty ASR result and TTS failure return typed fallback/status.

## Alternatives
- Switch to the old Node/FastAPI backend: rejected. It bypasses current Spring Boot auth, usage, traceability, OpenAPI and commercial gates.
- Modify `DeterministicAiProviderGateway` to call DashScope: rejected. It would make CI flaky, slow and dependent on third-party credentials.
- Let Flutter call DashScope directly: rejected. It exposes provider secrets and bypasses usage/cost control.

## Consequences
- Provider selection becomes a deploy-time configuration, not a client decision.
- Tests can verify real adapter behavior with mock HTTP fixtures while preserving deterministic local integration tests.
- Commercial cost, entitlement and usage controls stay in one backend path.
- Live DashScope E2E remains an external evidence step requiring real credentials and provider-accessible media refs.

## Commercial Controls
- TTS must use a stable text/model/voice cache key before provider calls.
- ASR must reject or safely fail local file paths that are not provider-accessible.
- LLM output must be strict JSON and cannot write final mastery, entitlement, billing or review schedule.
- Observability can record provider, model, latency, status, fallback reason and usage family only.

## Rollback
Set `speakeasy.ai.provider=deterministic` to return to local deterministic provider behavior without changing Flutter or AI REST contracts.
