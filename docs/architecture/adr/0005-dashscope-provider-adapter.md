# ADR 0005: DashScope Provider Adapter Behind Current AI Gateway

ADR 0005：当前 AI Gateway 后的 DashScope Provider Adapter。

## Status
Proposed - implementation and independent review pending.

提议中 - 等待实现和独立审查。

## Context
P0.1 training and commercial usage control need real LLM/TTS/ASR capability, but the project must not switch to the old `speakeasy_backend_export` backend. The old backend is only a provider integration reference for DashScope Qwen, Paraformer ASR and TTS.

P0.1 训练和商业用量控制需要真实 LLM/TTS/ASR 能力，但项目不能切换回旧的 `speakeasy_backend_export` 后端。旧后端只能作为 DashScope Qwen、Paraformer ASR 和 TTS 的 provider 集成参考。

The current backend already owns AI REST, usage reservation and provider isolation through `AiProviderGateway`.

当前后端已经通过 `AiProviderGateway` 拥有 AI REST、usage reservation 和 provider isolation 边界。

## Decision
Add a configurable DashScope provider adapter inside the current Spring Boot backend:

在当前 Spring Boot 后端内新增可配置的 DashScope provider adapter：

- `deterministic` provider remains the default for local development and CI.
- `dashscope` provider implements Qwen LLM, DashScope TTS and Paraformer ASR behind the existing `AiProviderGateway`.
- Flutter continues to call only the existing AI REST endpoints.

- `deterministic` provider 继续作为本地开发和 CI 的默认 provider。
- `dashscope` provider 在既有 `AiProviderGateway` 后实现 Qwen LLM、DashScope TTS 和 Paraformer ASR。
- Flutter 仍然只调用既有 AI REST endpoints。

- Provider credentials stay server-side.
- Provider output is normalized into `TranscribeResult`, `TtsResult`, `ScoreResult` and `CoachResult`.
- Invalid JSON, unavailable provider, unsupported media ref, empty ASR result and TTS failure return typed fallback/status.

- Provider credentials 只保留在服务端。
- Provider output 统一归一化为 `TranscribeResult`、`TtsResult`、`ScoreResult` 和 `CoachResult`。
- Invalid JSON、unavailable provider、unsupported media ref、empty ASR result 和 TTS failure 都返回 typed fallback/status。

## Alternatives
- Switch to the old Node/FastAPI backend: rejected. It bypasses current Spring Boot auth, usage, traceability, OpenAPI and commercial gates.
- Modify `DeterministicAiProviderGateway` to call DashScope: rejected. It would make CI flaky, slow and dependent on third-party credentials.
- Let Flutter call DashScope directly: rejected. It exposes provider secrets and bypasses usage/cost control.

- 切换到旧 Node/FastAPI 后端：拒绝。这样会绕过当前 Spring Boot 的 auth、usage、traceability、OpenAPI 和 commercial gates。
- 修改 `DeterministicAiProviderGateway` 直接调用 DashScope：拒绝。这样会让 CI 变慢、不稳定，并依赖第三方 credentials。
- 让 Flutter 直接调用 DashScope：拒绝。这样会暴露 provider secrets，并绕过 usage/cost control。

## Consequences
- Provider selection becomes a deploy-time configuration, not a client decision.
- Tests can verify real adapter behavior with mock HTTP fixtures while preserving deterministic local integration tests.
- Commercial cost, entitlement and usage controls stay in one backend path.
- Live DashScope E2E remains an external evidence step requiring real credentials and provider-accessible media refs.

- Provider selection 变成部署时配置，而不是客户端决策。
- Tests 可以用 mock HTTP fixtures 验证真实 adapter 行为，同时保留 deterministic local integration tests。
- Commercial cost、entitlement 和 usage controls 继续留在同一条后端路径。
- Live DashScope E2E 仍是外部 evidence 步骤，需要真实 credentials 和 provider-accessible media refs。

## Commercial Controls
- TTS must use a stable text/model/voice cache key before provider calls.
- ASR must reject or safely fail local file paths that are not provider-accessible.
- LLM output must be strict JSON and cannot write final mastery, entitlement, billing or review schedule.
- Observability can record provider, model, latency, status, fallback reason and usage family only.

- TTS 在 provider call 前必须使用稳定的 text/model/voice cache key。
- ASR 必须拒绝或安全失败处理不可被 provider 访问的 local file paths。
- LLM output 必须是 strict JSON，且不能写入 final mastery、entitlement、billing 或 review schedule。
- Observability 只能记录 provider、model、latency、status、fallback reason 和 usage family。

## Rollback
Set `speakeasy.ai.provider=deterministic` to return to local deterministic provider behavior without changing Flutter or AI REST contracts.

将 `speakeasy.ai.provider=deterministic` 即可回到本地 deterministic provider 行为，不需要修改 Flutter 或 AI REST contracts。
