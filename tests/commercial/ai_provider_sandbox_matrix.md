# AI Provider Sandbox Matrix：商业 AI Provider 生产化加固

## 状态
External pending - 本矩阵定义 `TC-COM-AI-004` 必需证据，不声明真实 DashScope sandbox / controlled live 已通过。

## 适用范围
- Increment：`commercial-ai-provider-hardening`
- Stage Scope：COM-SI-015
- Requirement：FR-COM-AI-003
- Acceptance：AC-COM-AI-003
- Test Case：TC-COM-AI-004

## Evidence Contract
| Field | Requirement |
| --- | --- |
| DashScope evidence ref | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` must point to LLM, ASR and TTS evidence. |
| Evidence format | Provider console logs, backend request ids, latency/error/cost summary, sanitized audio fixture metadata and reviewer notes must be stored outside the repo and referenced from release vars. |
| Safety | Evidence must not include provider API keys, raw learner audio, full signed media URLs, phone/email, full transcript or raw payment data. |
| Current local boundary | Fake transport and deterministic provider tests are useful regression evidence, but cannot close this matrix. |

## Scenario Matrix
| Provider capability | Scenario | Required evidence | Current status | Evidence ref |
| --- | --- | --- | --- | --- |
| DashScope Qwen LLM | Valid strict coach JSON | backend request id, model, latency, schema-valid result, token estimate, cost estimate | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |
| DashScope Qwen LLM | Invalid/unsafe provider output fallback | backend request id, invalid schema mapping, fallback result, no learning evidence mutation | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |
| DashScope Paraformer ASR | Valid backend-signed short audio | media hash/ref, sanitized format metadata, latency, transcript status, duration, cost estimate | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |
| DashScope Paraformer ASR | Unsupported/oversize/expired media fallback | rejected reason, no provider call or typed provider failure, usage release evidence | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |
| DashScope TTS | Valid text/model/voice generation | cache miss provider call, media hash/ref, latency, character count, cost estimate | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |
| DashScope TTS | Repeated text/model/voice cache reuse | cache hit evidence, no duplicate provider call, reusable media ref | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |
| DashScope provider ops | Timeout/rate-limit/provider error | normalized error code, fallback status, usage release/commit behavior, alert event | external-pending | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` |

## External Blockers
- DashScope sandbox or controlled live credentials are required.
- Provider-accessible sanitized media fixtures are required.
- Cost estimate inputs must be approved by PM/Ops.
- Independent reviewer must verify evidence refs, timestamps, environment, commit/build tag and sanitized payload policy.
