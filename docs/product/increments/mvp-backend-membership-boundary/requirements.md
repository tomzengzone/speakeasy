# MVP Backend Membership Boundary Requirements

## 状态
Draft - derived from MVP backend stage。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 membership/boundary requirement IDs。 |

## Owner
Requirement Development Agent

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-BE-FR-011 | MVP-SI-011 | 后端必须提供账号注销、云端学习数据删除或匿名化、删除任务状态、审计日志和退出/注销后的会话失效边界。 |
| MVP-BE-FR-012 | MVP-SI-012 | 后端必须为 MVP 会员页、学习报告、离线内容和成就占位提供边界事实，明确 Android 支付、完整权益 gating、完整报告、离线包和成就不作为 MVP 完成能力。 |

## Success Criteria
- SC-MVP-BE-021：用户请求注销后，后端创建可追踪 deletion job 或同步完成删除/匿名化。
- SC-MVP-BE-022：注销后相关 session/token 不得继续访问用户数据。
- SC-MVP-BE-023：删除/匿名化策略覆盖 Product Base 学习数据或明确记录例外。
- SC-MVP-BE-024：会员/报告/占位响应能区分 available-entry、platform-limited、placeholder，不伪造商业完成状态。
- SC-MVP-BE-025：P0 commercial readiness 的订阅权益、真实支付和商业 gating 不被本 increment 标记为 Done。

## Non-goals
- 不完成真实付费闭环。
- 不生成完整学习报告。
- 不实现离线内容或成就。

## Downstream Artifacts
- `docs/product/increments/mvp-backend-membership-boundary/spec.md`
- `docs/product/increments/mvp-backend-membership-boundary/acceptance.md`
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md`
