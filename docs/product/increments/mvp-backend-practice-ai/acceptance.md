# MVP Backend Practice AI Acceptance

## 状态
Draft - practice/AI acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 practice/AI AC。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Coverage Map
| AC | Stage Scope ID | FR | Spec |
| --- | --- | --- | --- |
| AC-MVP-BE-006 | MVP-SI-006 | MVP-BE-FR-006 | MVP-BE-SPEC-006 |
| AC-MVP-BE-008 | MVP-SI-008 | MVP-BE-FR-008 | MVP-BE-SPEC-008 |
| AC-MVP-BE-009 | MVP-SI-009 | MVP-BE-FR-009 | MVP-BE-SPEC-009 |

## AC-MVP-BE-006 Provider Gateway
- 给定客户端需要 ASR/TTS/pronunciation/LLM，客户端不得直接要求配置 provider secret。
- 给定 provider 返回成功，后端必须返回符合 OpenAPI/AI schema 的规范化结果。
- 给定 provider timeout、不可用或 schema invalid，后端必须返回可恢复错误或明确失败，不得写入伪成功反馈。
- 给定请求未认证或 session 不匹配，后端必须拒绝 provider 调用。

## AC-MVP-BE-008 Practice Session Lifecycle
- 给定用户从官方场景和等级开始练习，后端必须创建或恢复 active session。
- 给定同一用户同一场景同一等级有未完成 session，再次进入必须返回可恢复 session。
- 给定用户提交有效 turn，后端必须持久化 turn 并推进 session 状态。
- 给定用户完成 session，后端必须返回 summary payload 或可供 learning-memory increment 写入的 evidence candidate。
- 给定 session 已完成，后端不得继续把它作为 active recovery session。

## AC-MVP-BE-009 Feedback And Failure Handling
- 给定用户提交有效回答，后端必须返回 coach feedback、retry suggestion、expression suggestion、next question、score signal 或 recoverable error 中至少一种。
- 给定反馈包含评分，后端必须标记评分来源和可用性，不得让单次评分独立决定长期掌握状态。
- 给定 message playback/translation 失败，后端或客户端 contract 必须能表达失败且不丢失 session。
- 给定 provider output 不符合 schema，用户不得看到未经验证的反馈。

## Traceability
完整追溯见 `docs/product/increments/mvp-backend-practice-ai/traceability.md`。
