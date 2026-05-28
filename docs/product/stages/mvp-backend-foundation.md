# MVP 阶段范围：后端与数据库全量补齐

## 状态
Validated - MVP backend-first stage 已完成六个 increment 的实现、测试和 release evidence 闭环。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 MVP 从 roadmap 到 stage scope 到 increments 的后端优先全量分解。 |
| v1.0 | 2026-05-29 | Validated | MVP-SI-001 到 MVP-SI-014 均通过 increment traceability、code/test/report/release evidence 或明确例外闭环。 |

## 阶段目标
把 Product Base 已接受的 MVP 学习闭环从当前本地/前端优先状态补齐为可上线演进的服务端事实：账号、首评、官方场景、练习会话、AI/语音网关、学习证据、会员边界、OpenAPI client、测试和发布证据都必须具备后端/API/数据库承接。

该阶段优先回答“当前 MVP 后端和数据库如何补齐并可追溯”，不扩大 P0.1 训练 Agent、P0 商业订阅、P0.2 记忆调度或 P1/P2 内容体系范围。

## 入口条件
- Product Base 已建立：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`。
- Feature registry 已登记稳定产品能力：`docs/product/feature_registry.md`。
- OpenAPI source of truth 已存在：`docs/architecture/openapi/speakeasy-api.yaml`。
- 后端和数据库已有部分基础实现，但尚未覆盖 Product Base 全量 MVP 能力。

## 阶段范围
- Spring Boot backend runtime、PostgreSQL schema、Flyway migration、repository、service、controller 和统一错误响应。
- Auth/session/current user/profile 后端事实。
- 首评 assessment、learning route、官方场景内容、场景等级、target expression、加入/移除/当前场景和首页学习状态后端承接。
- TTS/ASR/pronunciation/LLM 网关边界和失败兜底，避免客户端直接拥有 provider secret 或不一致 schema。
- Product Base voice practice session、turn、feedback、summary、recovery 后端承接。
- 推荐表达队列、收藏、复习、学习证据、mastery、weakness、history 和个人 Wiki 的后端持久化边界。
- MVP 会员边界、账号删除和云端学习数据处理；不等同于完整商业化订阅上线。
- OpenAPI 与 Flutter generated/client integration、契约测试、后端测试、端到端证据和 release readiness。

## Stage Scope Items
| Stage Scope ID | Capability / obligation | Required status | Target increment | Current status |
| --- | --- | --- | --- | --- |
| MVP-SI-001 | 后端 runtime、PostgreSQL、Flyway migration、统一响应和错误模型 | required | `mvp-backend-foundation-auth` | Done |
| MVP-SI-002 | Auth/session/current user/profile 后端事实和 token 生命周期 | required | `mvp-backend-foundation-auth` | Done |
| MVP-SI-003 | 首评 assessment、学习路线和 Product Base 场景映射持久化 | required | `mvp-backend-onboarding-content` | Done |
| MVP-SI-004 | 官方场景、版本、等级、target expressions 和内容种子/API | required | `mvp-backend-onboarding-content` | Done |
| MVP-SI-005 | 加入/移除/当前场景、首页学习状态和下一步建议的服务端承接 | required | `mvp-backend-onboarding-content` | Done |
| MVP-SI-006 | TTS、ASR、pronunciation、LLM feedback 网关与 provider secret 后端边界 | required | `mvp-backend-practice-ai` | Done |
| MVP-SI-007 | 推荐表达队列、复习、收藏和表达任务进度的服务端承接 | required | `mvp-backend-learning-memory` | Done |
| MVP-SI-008 | Practice session lifecycle：start/resume/get/turn/complete/recovery | required | `mvp-backend-practice-ai` | Done |
| MVP-SI-009 | Coach feedback、message assistance、score signal 和可恢复失败 | required | `mvp-backend-practice-ai` | Done |
| MVP-SI-010 | Learning evidence、summary、mastery、weakness、history 和 personal wiki | required | `mvp-backend-learning-memory` | Done |
| MVP-SI-011 | Account deletion、云端学习数据删除/匿名化和审计边界 | required | `mvp-backend-membership-boundary` | Done |
| MVP-SI-012 | MVP membership/report/placeholder boundary 的服务端事实和非商业化限制 | required | `mvp-backend-membership-boundary` | Done |
| MVP-SI-013 | OpenAPI 对齐、generated Dart client、Flutter integration 和 endpoint drift 清理 | required | `mvp-backend-client-qa-release` | Done with documented exceptions |
| MVP-SI-014 | 后端测试、契约测试、Flutter integration/e2e、报告和 release evidence | required | `mvp-backend-client-qa-release` | Done |

## Increment 分解
| Increment ID | Lifecycle status | Covered Stage Scope Items | Primary output |
| --- | --- | --- | --- |
| `mvp-backend-foundation-auth` | Done | MVP-SI-001, MVP-SI-002 | 后端运行时、DB migration、认证/session/current user/profile 基础。 |
| `mvp-backend-onboarding-content` | Done | MVP-SI-003, MVP-SI-004, MVP-SI-005 | 首评、学习路线、官方场景内容和首页状态 API。 |
| `mvp-backend-practice-ai` | Done | MVP-SI-006, MVP-SI-008, MVP-SI-009 | 练习 session、AI/语音 provider 网关、反馈和恢复。 |
| `mvp-backend-learning-memory` | Done | MVP-SI-007, MVP-SI-010 | 推荐表达、收藏、复习、学习证据和记忆沉淀。 |
| `mvp-backend-membership-boundary` | Done | MVP-SI-011, MVP-SI-012 | MVP 账号删除、学习数据处理、会员/报告边界。 |
| `mvp-backend-client-qa-release` | Done | MVP-SI-013, MVP-SI-014 | OpenAPI/Dart client/frontend integration、测试和发布证据。 |

## Stage Traceability Matrix
| Stage Scope ID | Increment ID | Requirement ID | Spec ID | Acceptance Criteria ID | Traceability Row ID | Status | Gap |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-SI-001 | `mvp-backend-foundation-auth` | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | Done | Closed |
| MVP-SI-002 | `mvp-backend-foundation-auth` | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | Done | Closed |
| MVP-SI-003 | `mvp-backend-onboarding-content` | MVP-BE-FR-003 | MVP-BE-SPEC-003 | AC-MVP-BE-003 | MVP-BE-TR-003 | Done | Closed |
| MVP-SI-004 | `mvp-backend-onboarding-content` | MVP-BE-FR-004 | MVP-BE-SPEC-004 | AC-MVP-BE-004 | MVP-BE-TR-004 | Done | Closed |
| MVP-SI-005 | `mvp-backend-onboarding-content` | MVP-BE-FR-005 | MVP-BE-SPEC-005 | AC-MVP-BE-005 | MVP-BE-TR-005 | Done | Closed |
| MVP-SI-006 | `mvp-backend-practice-ai` | MVP-BE-FR-006 | MVP-BE-SPEC-006 | AC-MVP-BE-006 | MVP-BE-TR-006 | Done | Closed |
| MVP-SI-007 | `mvp-backend-learning-memory` | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | Done | Closed |
| MVP-SI-008 | `mvp-backend-practice-ai` | MVP-BE-FR-008 | MVP-BE-SPEC-008 | AC-MVP-BE-008 | MVP-BE-TR-008 | Done | Closed |
| MVP-SI-009 | `mvp-backend-practice-ai` | MVP-BE-FR-009 | MVP-BE-SPEC-009 | AC-MVP-BE-009 | MVP-BE-TR-009 | Done | Closed |
| MVP-SI-010 | `mvp-backend-learning-memory` | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | Done | Closed |
| MVP-SI-011 | `mvp-backend-membership-boundary` | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | Done | Closed |
| MVP-SI-012 | `mvp-backend-membership-boundary` | MVP-BE-FR-012 | MVP-BE-SPEC-012 | AC-MVP-BE-012 | MVP-BE-TR-012 | Done | Closed |
| MVP-SI-013 | `mvp-backend-client-qa-release` | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | Done with documented exceptions | Closed |
| MVP-SI-014 | `mvp-backend-client-qa-release` | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | Done | Closed |

## Gap Register
| Gap ID | Gap | Owner / next route | Status |
| --- | --- | --- | --- |
| MVP-BE-GAP-001 | Foundation 已有 backend skeleton/migration/tests，但需确认 Product Base 全量 schema、统一 DTO 和错误模型覆盖。 | Backend + QA | Closed 2026-05-29 |
| MVP-BE-GAP-002 | Auth endpoints 已有部分实现，但 Flutter client endpoint drift、生产登录策略和 current user/profile 覆盖需补齐。 | Backend + Frontend + QA | Closed 2026-05-29 |
| MVP-BE-GAP-003 | 首评、learning route、official scenario content 有 schema 或 OpenAPI，但缺完整 controller/service/seed/versioning。 | Backend + Domain Schema | Closed 2026-05-29 |
| MVP-BE-GAP-004 | 加入/移除/当前场景、首页学习状态和下一步建议仍主要由前端/本地状态承接。 | Backend + Frontend | Closed 2026-05-29 |
| MVP-BE-GAP-005 | AI/ASR/TTS/pronunciation provider 网关、secret 边界、重试和失败兜底未完成。 | Backend + AI Runtime + Security | Closed 2026-05-29 |
| MVP-BE-GAP-006 | 推荐表达、收藏、复习、learning evidence、mastery、history 和 personal wiki 缺服务端持久化闭环。 | Backend + Domain Schema + QA | Closed 2026-05-29 |
| MVP-BE-GAP-007 | Practice session/turn/complete/recovery API 未实现，教练反馈 schema 与持久化证据未闭环。 | Backend + AI Runtime + QA | Closed 2026-05-29 |
| MVP-BE-GAP-008 | 账号删除已有 foundation，但缺 Product Base 学习数据删除/匿名化完整执行和验收证据。 | Backend + Security + QA | Closed 2026-05-29 |
| MVP-BE-GAP-009 | 会员/报告/占位页只需 MVP 边界事实，不应误升级为完整商业订阅；需防止与 P0 商业化 scope 混淆。 | Product Manager + Backend + Frontend | Closed 2026-05-29 |
| MVP-BE-GAP-010 | OpenAPI 与 Flutter 现有 API client 存在 drift，缺 generated Dart client 或等效强约束。 | Frontend + Backend + QA | Closed 2026-05-29 |
| MVP-BE-GAP-011 | 后端测试、契约测试、Flutter integration/e2e、implementation report 和 quality report 尚未覆盖本 stage 全量。 | QA + Development Orchestrator | Closed 2026-05-29 |

## 阶段非目标
- 不实现 P0.1 训练型 Agent 的 session planner、micro-action、hint ladder 或 pressure check；这些仍由 `p0-1-expression-automation-training` 管理。
- 不实现完整商业化订阅上线；Apple/Google 真实交易校验、权益 gating 和商业风控仍由 `commercial-subscription-readiness` 管理。
- 不新增第三个官方场景，不扩展 A1-C2 内容体系，不建设 CMS。
- 不把 P0.2 cross-session planner、L0-L5 长期掌握阶梯或 P1 笔记本/评分产品化纳入 MVP 后端补齐。
- 本阶段完成不自动批准后续 Product Base 之外的代码；未来新增能力仍需重新走 Requirement/Spec/Acceptance/Traceability、Architecture/API/Domain、Backend、Frontend、QA 和 Release workflow。

## 出口条件
- 每个 required Stage Scope Item 至少由一个 increment 覆盖，且对应 requirement/spec/acceptance/traceability 文件存在。
- OpenAPI、backend implementation、Flutter client integration 和测试证据能反向追溯到 `MVP-SI-*`。
- Product Base 中 FR-001 到 FR-011 的后端/API/DB 承接缺口被实现、明确例外或转入后续阶段。
- 所有 MVP backend gaps 均关闭、转移到 owning stage/increment，或被 Product Manager 明确接受为非阻塞例外。
- 完成实现报告、质量报告和独立 Product Object Governance Check。
