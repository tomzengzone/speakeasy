# MVP Backend Practice AI Requirements

## 状态
Draft - derived from MVP backend stage。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 practice/AI requirement IDs。 |

## Owner
Requirement Development Agent

## Capability Classification
- Primary Capability ID：`CAP-PRACTICE`
- Primary Sub-capability ID：`CAP-PRACTICE-03`
- Affected Capability IDs：`CAP-COACH`
- Affected Sub-capability IDs：`CAP-COACH-03`、`CAP-COACH-05`

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-BE-FR-006 | MVP-SI-006 | 后端必须承接 TTS、ASR、pronunciation/scoring 和 LLM feedback provider 调用，保护 provider secret，统一 schema、重试、超时、错误和降级语义。 |
| MVP-BE-FR-008 | MVP-SI-008 | 后端必须实现 Product Base practice session lifecycle，包括 start/resume/get/submit turn/complete/recovery，并维持同一用户同一场景同一等级的未完成会话恢复规则；Practice turn 只要携带 `audio_ref`，就必须先校验其为当前认证用户拥有的后端可信 `media://audio/...` 引用，不得保存本地路径、裸 URL、client-created ref、wrong-owner ref 或未验证 ref。 |
| MVP-BE-FR-009 | MVP-SI-009 | 后端必须返回 coach feedback、message assistance、score signal、next question 或可恢复错误中的至少一种，并能把 feedback 与 session/turn 关联。 |

## Success Criteria
- SC-MVP-BE-011：客户端不需要直接持有 AI/ASR/TTS/pronunciation provider secret。
- SC-MVP-BE-012：同一用户同一场景同一等级可恢复未完成 session。
- SC-MVP-BE-013：提交有效 turn 后可得到用户消息、feedback/next question/error 的确定性响应。
- SC-MVP-BE-014：provider timeout、schema invalid、quota unavailable 或 media invalid 必须返回可恢复错误或明确失败。
- SC-MVP-BE-015：session complete 能生成 summary 输入或 evidence candidate，供 learning-memory increment 接收。
- SC-MVP-BE-016：Practice turn 同时包含 transcript 和非法 `audio_ref` 时，后端必须拒绝并且不得持久化 turn、不得生成 coach feedback、不得调用 provider。
- SC-MVP-BE-017：Practice turn 携带其他用户已验证的 `media://audio/...` 时，后端必须按不可消费媒体拒绝，并且不得持久化 turn、不得生成 coach feedback、不得调用 provider。

## Non-goals
- 不要求 P0.1 micro-action、hint ladder 或 pressure check。
- 不直接写入最终 mastery；最终学习事实由 learning-memory increment 负责。

## Downstream Artifacts
- `docs/product/increments/mvp-backend-practice-ai/spec.md`
- `docs/product/increments/mvp-backend-practice-ai/acceptance.md`
- `docs/product/increments/mvp-backend-practice-ai/traceability.md`
