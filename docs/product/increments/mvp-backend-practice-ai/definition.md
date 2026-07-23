# Increment Definition：MVP 练习会话与 AI/语音网关

## 状态
Draft - MVP backend-first stage planned increment。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 practice/AI 切片定义。 |

## Increment ID
`mvp-backend-practice-ai`

## Active Stage
`docs/product/stages/mvp-backend-foundation.md`

## Primary Capability
- Capability ID：`CAP-PRACTICE`
- Sub-capability ID：`CAP-PRACTICE-03`

## Affected Capabilities
- Capability IDs：`CAP-COACH`
- Sub-capability IDs：`CAP-COACH-03`、`CAP-COACH-05`

## 上游决策
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- AI runtime contract：`docs/ai_runtime/prompt_contract.md`
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`

## Scope
- Product Base voice practice session start/resume/get/turn/complete/recovery 后端生命周期。
- 用户录音转写、TTS、pronunciation/scoring 和 LLM feedback 的后端 provider boundary。
- Coach feedback、message playback/translation 边界、score signal 和可恢复错误。
- 后端只实现 Product Base 已接受的语音场景模拟能力，不实现 P0.1 训练 planner。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| MVP-SI-006 | 通过 `MVP-BE-FR-006` 覆盖 TTS、ASR、pronunciation、LLM feedback 网关与 provider secret 后端边界。 |
| MVP-SI-008 | 通过 `MVP-BE-FR-008` 覆盖 practice session lifecycle。 |
| MVP-SI-009 | 通过 `MVP-BE-FR-009` 覆盖 coach feedback、message assistance、score signal 和可恢复失败。 |

## Excluded Stage Scope Items
- MVP-SI-007 和 MVP-SI-010 的长期学习沉淀由 `mvp-backend-learning-memory` 覆盖。
- P0.1 session planner、micro-action、hint ladder 和 pressure check 不属于本 MVP backend increment。

## Required Product Artifacts
- `docs/product/increments/mvp-backend-practice-ai/requirements.md`
- `docs/product/increments/mvp-backend-practice-ai/spec.md`
- `docs/product/increments/mvp-backend-practice-ai/acceptance.md`
- `docs/product/increments/mvp-backend-practice-ai/traceability.md`

## Required Downstream Gates
- Domain/API：practice session、turn、message、feedback、score、provider request/response。
- AI Runtime：prompt/schema、provider fallback、deterministic validation。
- Security：provider secret 不进入客户端。
- Backend：session lifecycle、AI/ASR/TTS/pronunciation gateway、error handling。
- QA：provider mocked tests、contract tests、recoverable failure tests。

## Non-goals
- 不实现训练型 Agent planner。
- 不实现完整学习记忆写回；只产出可交给 learning memory increment 的 evidence candidate。
- 不要求外部 provider 在所有环境可用。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent。
