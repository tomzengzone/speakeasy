# 产品开发状态

## 状态
Revalidated / P0.2 stage replanned for goal-driven autopilot - TC-P01-013/014 local blockers closed；2026-06-03 P0.1 Product Base/production hardening TC-P01-021 through TC-P01-031 have local passed evidence inside the existing P0.1 stage；P0.2 has been replanned from memory scheduling into GoalProfile, DiagnosticAssessment, GoalBackplan, AutopilotTraining, MemoryCurvePolicy, ProgressForecast and OutcomeCheckpoint across three planned increments；commercial release and paid AI voice remain blocked by explicit external/native/store/release evidence

## Owner
Product Manager Agent

## Current Date
2026-06-05

## 活动目标
以 Product Base 活需求库承载已接受稳定能力。本轮已按顺序完成 TC-P01-013、TC-P01-014、TC-COM-AI-004 evidence preparation 和 TC-COM-012/015/019/021/022 strict gate revalidation，并完成独立审核；2026-06-03 又在同一 P0.1 stage/increment 内补充商业软件整改设计、需求、验收、测试和追踪口径。后续工作不得把本地通过扩展为 Product Base 合入、生产训练或商业发布批准。
- MVP 后端线：Product Base 已接受能力仍以本地 Flutter macOS + Spring Boot + 真实 PostgreSQL 系统 E2E 为 baseline；2026-06-02 复测通过 `smoke`、`scene-catalog`、`learning-memory`、`practice-feedback`、`profile-settings`、`membership-boundary` 和 `commercial-boundary`。
- 商业发布线：P0 商业化订阅和 AI provider 生产化本地实现/测试边界已复测通过；2026-06-03 strict gates 确认真实支付 provider、native social login、store/reviewer/privacy/support、strict release 和外部 AI evidence refs 仍是商业发布阻断项。
- 价值体验线：P0.1“口语优先、文本兜底的 FSI 式表达自动化训练闭环”保持 next value-experience stage；TC-P01-013 路由级 integration loop 和 TC-P01-014 AI eval validator 已于 2026-06-03 本地关闭。TC-P01-021 through TC-P01-031 已记录本地 passed evidence，覆盖后端 Training API/source-of-truth、证据治理、内容版本、真实 media/AI pipeline、planner audit、backend-only frontend source-of-truth 和 rollout gates；Product Base 合入仍需 PM 设计确认、独立治理复核和不得扩展到商业发布/paid AI voice 的边界确认。
- P0.2 目标达成线：用户目标驱动审查后，旧单体记忆调度 artifact 已删除并被新的 stage scope 吸收；P0.2 正式 stage scope 扩展为 P02-SI-001..013，并拆成 `p0-2-goal-diagnostic-foundation`、`p0-2-goal-backplan-memory-policy` 和 `p0-2-autopilot-progress-checkpoint`。三个新 increment 已完成 requirements/spec/acceptance/test_cases/traceability 下沉设计；Followup-A 已完成本地实现审核；Followup-B 已完成 requirements/spec/acceptance/test_cases/traceability、Domain、API/OpenAPI/generated client sync、AI runtime 和 UX 合同门禁，且 backend/frontend UserAutopilotControl control slice、S002-A notification eligibility policy、S002-B notification outbox lifecycle/replay、S003 missed-day recovery planner、S004 item-level MemoryCurvePolicy、S005 mastery transition 和 S006 replay/performance/coverage/traceability gates 已有本地执行证据；TC-P02-FUB-001/002/003/004/005/006/007/008/009/010/011/012/013/014/015/016/017 passed。Followup-C 已完成 S000 document chain、S001 forecast hardening、S002 checkpoint task library 和 S003 checkpoint-to-plan update 本地实现/测试/独立审核，TC-P02-FUC-001/002/003/004/005/006/007/008/009 passed；S004-S007 projection、surface propagation、downgrade、performance、coverage 和 release evidence 仍为 planned/not started。Followup-B/C are not release-ready；Product Base merge is not approved。Followup-D 仍为 release/commercial gate scaffold。

## 产品对象状态
- Product Base requirements：`docs/product/base/requirements.md`
- Product Base spec：`docs/product/base/spec.md`
- Product Base acceptance：`docs/product/base/acceptance.md`
- Product Base traceability：`docs/product/base/traceability.md`
- Feature registry：`docs/product/feature_registry.md`
- Validated MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- MVP backend foundation/auth increment：`docs/product/increments/mvp-backend-foundation-auth/definition.md`
- MVP backend onboarding/content increment：`docs/product/increments/mvp-backend-onboarding-content/definition.md`
- MVP backend practice/AI increment：`docs/product/increments/mvp-backend-practice-ai/definition.md`
- MVP backend learning/memory increment：`docs/product/increments/mvp-backend-learning-memory/definition.md`
- MVP backend membership/boundary increment：`docs/product/increments/mvp-backend-membership-boundary/definition.md`
- MVP backend client/QA/release increment：`docs/product/increments/mvp-backend-client-qa-release/definition.md`
- MVP system E2E validation increment：`docs/product/increments/mvp-system-e2e-validation/definition.md`
- Active release-blocking stage：`docs/product/stages/p0-commercial-readiness.md`
- Next value-experience stage：`docs/product/stages/p0-1-expression-automation.md`
- P0.1 increment definition：`docs/product/increments/p0-1-expression-automation-training/definition.md`
- P0.1 increment requirements：`docs/product/increments/p0-1-expression-automation-training/requirements.md`
- P0.1 increment spec：`docs/product/increments/p0-1-expression-automation-training/spec.md`
- P0.1 acceptance criteria：`docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- P0.1 test cases：`docs/product/increments/p0-1-expression-automation-training/test_cases.md`
- P0.1 traceability：`docs/product/increments/p0-1-expression-automation-training/traceability.md`
- P0.2 stage：`docs/product/stages/p0-2-training-memory.md`
- P0.2 goal diagnostic foundation definition：`docs/product/increments/p0-2-goal-diagnostic-foundation/definition.md`
- P0.2 goal diagnostic foundation requirements/spec/AC/TC/traceability：`docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md`, `docs/product/increments/p0-2-goal-diagnostic-foundation/spec.md`, `docs/product/increments/p0-2-goal-diagnostic-foundation/acceptance.md`, `docs/product/increments/p0-2-goal-diagnostic-foundation/test_cases.md`, `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`
- P0.2 goal backplan memory policy definition：`docs/product/increments/p0-2-goal-backplan-memory-policy/definition.md`
- P0.2 goal backplan memory policy requirements/spec/AC/TC/traceability：`docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md`, `docs/product/increments/p0-2-goal-backplan-memory-policy/spec.md`, `docs/product/increments/p0-2-goal-backplan-memory-policy/acceptance.md`, `docs/product/increments/p0-2-goal-backplan-memory-policy/test_cases.md`, `docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md`
- P0.2 autopilot progress checkpoint definition：`docs/product/increments/p0-2-autopilot-progress-checkpoint/definition.md`
- P0.2 autopilot progress checkpoint requirements/spec/AC/TC/traceability：`docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`, `docs/product/increments/p0-2-autopilot-progress-checkpoint/spec.md`, `docs/product/increments/p0-2-autopilot-progress-checkpoint/acceptance.md`, `docs/product/increments/p0-2-autopilot-progress-checkpoint/test_cases.md`, `docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md`
- P0.2 Followup-A definition/traceability scaffold：`docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/definition.md`, `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/traceability.md`
- P0.2 Followup-B definition and pre-implementation docs/contracts：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md`, `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md`, `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/spec.md`, `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/acceptance.md`, `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/test_cases.md`, `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md`
- P0.2 Followup-C definition/requirements/spec/AC/TC/traceability：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`, `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/requirements.md`, `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/spec.md`, `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/acceptance.md`, `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/test_cases.md`, `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md`
- P0.2 Followup-D definition/traceability scaffold：`docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md`, `docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md`
- Commercial readiness increment definition：`docs/product/increments/commercial-subscription-readiness/definition.md`
- Commercial readiness requirements：`docs/product/increments/commercial-subscription-readiness/requirements.md`
- Commercial readiness spec：`docs/product/increments/commercial-subscription-readiness/spec.md`
- Commercial readiness acceptance：`docs/product/increments/commercial-subscription-readiness/acceptance.md`
- Commercial readiness traceability：`docs/product/increments/commercial-subscription-readiness/traceability.md`
- Commercial AI provider hardening definition：`docs/product/increments/commercial-ai-provider-hardening/definition.md`
- Commercial AI provider hardening requirements：`docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- Commercial AI provider hardening spec：`docs/product/increments/commercial-ai-provider-hardening/spec.md`
- Commercial AI provider hardening acceptance：`docs/product/increments/commercial-ai-provider-hardening/acceptance.md`
- Commercial AI provider hardening test cases：`docs/product/increments/commercial-ai-provider-hardening/test_cases.md`
- Commercial AI provider hardening traceability：`docs/product/increments/commercial-ai-provider-hardening/traceability.md`
- Legacy MVP requirements source：`docs/product/features/mvp-learning-loop-requirements.md`
- Legacy acceptance source：`docs/product/acceptance_criteria.md`
- Legacy traceability source：`docs/product/traceability_matrix.md`
- Legacy P0.1 spec source：`docs/product/features/mvp-learning-loop-spec.md`

## Product Base 状态
- `docs/product/base/` 是当前产品总需求库 source of truth，记录已实现、已验收或已接受的稳定能力。
- Product Base 不是冻结 baseline；未来需要冻结时，应从 Product Base 生成 `docs/product/baselines/<baseline-id>/`。
- 旧全局 MVP 文档已标记为 legacy/source 或历史参考，不再作为后续稳定需求的写回位置。
- MVP backend stage 已完成当前 committed stage work；它没有改变 Product Base 用户范围，而是补齐后端/API/数据库、客户端集成、测试、发布证据和本地系统 E2E 证据。
- `mvp-system-e2e-validation` 已验证 TC-MVP-E2E-001 到 TC-MVP-E2E-010；其中真实支付 provider 只作为 manual/external gate 保留，不作为本地自动化通过项。
- P0 `commercial-subscription-readiness` 是商业软件功能补齐和付费发布阻塞 stage；完成实现、验收、追溯、测试、发布和外部门禁后，才允许 Product Manager 批准商业发布口径。
- P0.1 `expression-automation-training` 是 next value-experience stage；完成实现、验收、追溯、测试和报告后，才允许由 Product Manager 批准 merge back 到 Product Base。
- 2026-06-03 复测结论：P0.1 TC-P01-013/014 本地关闭；P0.1 Product Base/production hardening TC-P01-021 through TC-P01-031 已有本地 passed evidence，可作为设计确认后的 Product Base 合入复核输入；TC-COM-AI-004 controlled-live evidence-prep 报告已生成；所有 strict external/native/store/release evidence blockers 仍不得关闭。
- 后续每个多步骤产品、需求、工作流或文档治理任务，每一步完成后必须由独立 checker agent 审查是否符合预期、是否偏离、是否存在非预期变更。

## 当前已实现能力判断
| 能力 | 当前状态 | 证据 | 产品判断 |
| --- | --- | --- | --- |
| 登录、首评、首页 | 已实现前端主流程 | `lib/main.dart`, `lib/core/bootstrap/app_root.dart`, `lib/pages/onboarding_page.dart`, `lib/pages/home_page.dart` | 作为 Product Base 稳定能力保留 |
| 官方场景资产 | 已有 2 个真实场景 | `assets/data/interview_scene_catalog.json`, `assets/data/interview_scene_wikis/` | 后续先扩展场景包，不承诺任意场景 |
| 场景等级 | 已有 L1/L2/L3 | `assets/data/interview_scene_wikis/*.json` | 后续再映射到 CEFR A1-C2 |
| 听力热身/跟读 | 已实现 | `lib/features/interview/interview_scene_listening_page.dart` | 进入口语训练前的输入环节 |
| 推荐表达队列 | 已实现 | `lib/features/interview/expression_daily_queue_coordinator.dart` | 后续接入训练 planner |
| 表达练习 | 已实现多种任务 | `lib/features/interview/interview_expression_learning_page.dart` | 可复用为 FSI micro-drill |
| 语音场景模拟 | 已实现主流程 | `lib/features/interview/interview_practice_page.dart` | P0 主路径应改为语音优先 |
| TTS/录音/转写 | 已接入 | `lib/services/audio_service.dart`, `lib/services/voice_chat_service.dart`, `ApiClient.transcribeAudio` 调用 | 不再作为 P1 后置能力处理 |
| LLM 教练反馈 | 已接入 | `lib/features/interview/interview_llm_scheduler.dart` | 需收敛为训练型 schema 和状态机 |
| 发音/表达评分 | 已有基础能力 | `lib/services/oral_assessment_service.dart`, `lib/features/interview/expression_shadow_scoring.dart` | P0 可展示基础反馈，P1 做评分产品化 |
| 个人 Wiki/复习沉淀 | 已实现本地优先 | `lib/features/interview/interview_wiki_store.dart` | 作为记忆引擎基础 |
| 会员页 | 已有页面和 Apple IAP 前端接入 | `lib/pages/membership_page.dart`, `lib/services/apple_payment_service.dart` | 不作为 P0.1 训练闭环阻塞项；作为商业化订阅上线准备的输入，不等同于真实付费闭环 |
| MVP 后端与数据库 | 当前 stage 已完成 | `backend/`, `docs/architecture/openapi/speakeasy-api.yaml`, `docs/product/stages/mvp-backend-foundation.md`, `docs/reports/test_report.md` | Product Base 当前 MVP 能力已有后端/API/DB、测试和发布证据；真实支付 provider 和真实第三方 provider 质量仍走外部门禁 |
| 本地系统 E2E gate | 2026-06-02 已复测通过 TC-MVP-E2E-001 到 TC-MVP-E2E-010 相关 suites | `docs/product/increments/mvp-system-e2e-validation/`, `integration_test/`, `scripts/run_mvp_system_e2e.sh`, `docs/reports/mvp_system_e2e_handoff.md` | 电脑端可自动化验证 Flutter UI + Spring Boot + 真实 PostgreSQL；脚本已补 OPS auth 和 deterministic provider isolation；真实支付 provider 保留 manual/external gate |
| 离线包/成就/旧课程/通用场景 | 存在页面或代码但非主流程 | `lib/pages/offline_content_page.dart`, `lib/pages/achievements_page.dart`, `lib/pages/learning_page.dart`, `lib/features/scenario/scene_page.dart` | 暂不进入下一阶段主线 |

## 新需求阶段映射
| 新需求 | 产品判断 | 阶段 |
| --- | --- | --- |
| FSI 方法论训练 | 接受，作为下一阶段核心差异点 | P0.1 |
| 全动作链路地道表达训练 | 接受，限定为现有 2 个官方场景先验证 | P0.1 |
| 用户只做小响应动作 | 接受，作为 P0.1 体验目标 | P0.1 |
| Session 内训练 planner | 接受，负责当前小动作、目标表达、提示等级、重试、降级、升级或轻量施压 | P0.1 |
| Micro-action UI/flow | 接受，覆盖听一句、选一个、回一句、跟一句、补一句、追问继续说 | P0.1 |
| Hint ladder | 接受，从无提示到句框、选项、chunk shadowing、model-then-retry | P0.1 |
| In-session pressure check | 接受，连续通过后减少提示并进入轻量追问 | P0.1 |
| 教练/导演/搭子/考官/记忆引擎 | 接受为行为模块，不做五个独立 persona | P0.1/P0.2 |
| 跨天自动组织训练、复习和场景复现 | 接受，拆成 daily planner、cross-session pressure ladder、mastery ladder | P0.2 |
| 任意短语/单词查询并加笔记 | 接受，但不阻塞训练闭环 | P1 |
| 发音和表达评分 | 基础能力进入 P0，完整评分体系进入 P1 | P0.1/P1 |
| A1-C2 情景库和语料库 | 接受为长期内容战略，先从场景包扩展开始 | P1/P2 |
| 任意场景 | 暂不作为近期承诺，先做官方场景包 | Later |
| 商业化订阅上线准备 | 接受，作为付费发布阻塞增量；不替代 P0.1 训练闭环 | P0 |
| 订阅权益后端 | 接受，Apple/Google 校验和权益持久化必须服务端负责 | P0 |
| Android 订阅闭环 | 接受，Google Play Billing 和后端 purchase token 校验必须补齐 | P0 |
| 商业权益 gating | 接受，作为商业发布线任务；不作为 P0.1 训练闭环前置条件 | P0 |
| 会员页权益文案一致性 | 接受，未实现的离线、成就、500+ 句型库或专属报告不得作为已兑现付费承诺 | P0 |
| 商业风控和 AI 成本控制 | 接受，付费流量开放前必须定义速率限制、用量、审计和滥用检测 | P0/P1 |
| 对象存储上传链路 | 接受，真实 ASR 生产可用前必须由后端生成可信 `audio_ref` | P0 |
| 持久化 TTS 缓存 | 接受，付费 AI 流量规模化前必须具备跨实例/重启可复用缓存；命中率和 CDN 优化可后续迭代 | P0/P1 |
| 真实 DashScope sandbox / controlled live 测试 | 接受；本地 evidence-prep 已生成，但不能用本地报告替代外部 evidence ref、provider latency/error/cost/format evidence 和独立审查 | P0 |
| AI 成本看板 | 接受，P0 需要最小套餐/用户/provider 成本看板；P1 做高级毛利分析和 provider A/B | P0/P1 |
| 生产级 AI 数据策略 | 接受，音频、转写、provider payload、TTS cache、日志和账号注销保留删除必须在 paid AI voice 前明确 | P0 |
| MVP 后端与数据库全量补齐 | 已完成当前 MVP stage；后续只允许通过新 owning increment 扩展能力或关闭外部门禁 | MVP - Validated |

## 当前下一步
1. Product Manager 已建立 Product Base 活需求库：requirements、spec、acceptance 和 traceability。
2. Product Manager 已接受 `CR-20260523-001 表达自动化训练 Agent`，范围限定为 P0.1/P0.2 分阶段落地。
3. Product Manager 将 P0.1 收紧为 session 内训练接管，而不只是训练回合增强。
4. `docs/process/change_request.md` 已修正 P0.1/P0.2 边界，避免把 L0-L5、跨天复现和长期记忆调度误写入 P0.1。
5. Product Manager 已建立 `docs/product/feature_registry.md`、`docs/product/base/`、P0.1/P0.2 stage scope 和 P0.1 increment definition。
6. Product Manager 已从 legacy P0.1 spec source 提炼并生成 P0.1 标准增量工件：requirements、spec、acceptance criteria 和 traceability。
7. Development Orchestrator 下一步应确认下游门禁：domain model、AI runtime schema、dialogue state machine、screen spec、architecture/module boundary 和测试用例。
8. P0.1 完成实现、验收、追溯、测试和报告后，应将已接受稳定能力 merge back 到 `docs/product/base/`，而不是写回旧 legacy 文档。
9. Product Manager 已接受 `CR-20260524-001 商业化订阅上线准备`，并新增 `commercial-subscription` feature、`p0-commercial-readiness` stage 和 `commercial-subscription-readiness` increment definition。
10. Product Manager 已补齐 `commercial-subscription-readiness` 的 requirements、spec、acceptance 和 traceability；商业化下一步不是直接改会员页或单接支付 SDK，而是由 Domain/API/Architecture/UX/Backend/Frontend/QA/DevOps 补齐强制下游门禁。
11. 后续不应直接进入代码实现，除非对应 increment spec 已被验收标准和相关契约承接，且 traceability 中的 contract gaps 已补齐或明确不适用。
12. 2026-05-25 Product Manager 已撤回不符合全量范围要求的商业化架构草案和技术栈 ADR，避免后续开发误用为 source of truth。
13. 2026-05-25 Product Manager 复盘结论：前一次架构任务失败的根因不是漏写某个功能，而是缺少“全量架构范围模式、源文档清单、feature/stage 覆盖矩阵、市场方案对比、遗漏范围分类和追溯检查”这些通用门禁。
14. 2026-05-25 已将该类问题抽象为通用治理规则，更新 Product Manager、System Architect、Development Orchestrator、document-traceability-check、skill-quality-check 和 skill quality standard；后续全量架构任务必须先通过 coverage gate，再允许形成技术栈推荐或 ADR。
15. 2026-05-28 Product Manager 已建立 MVP backend-first stage：`docs/product/stages/mvp-backend-foundation.md`。
16. 2026-05-28 Product Manager 已将 MVP backend stage 拆成 6 个 increments：`mvp-backend-foundation-auth`、`mvp-backend-onboarding-content`、`mvp-backend-practice-ai`、`mvp-backend-learning-memory`、`mvp-backend-membership-boundary`、`mvp-backend-client-qa-release`。
17. 2026-05-29 六个 MVP backend increments 已完成实现、测试和报告证据，`MVP-SI-001` 到 `MVP-SI-014` 均在 `docs/product/stages/mvp-backend-foundation.md` 中闭环。
18. 2026-05-29 Product Manager 已补充 `mvp-system-e2e-validation`，并通过 TC-MVP-E2E-001 到 TC-MVP-E2E-010 验证本地 Flutter macOS + Spring Boot + 真实 PostgreSQL 系统路径。
19. 2026-05-29 PM 复查决策：`p0-commercial-readiness` 是 P0 级商业软件功能补齐 stage，位于 P0.1 训练体验升级之上；下一步不再是继续补齐 MVP backend foundation。
20. 若今天目标是商业软件功能补齐或真实收费准备，应先启动 `commercial-subscription-readiness` 的下游门禁：Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、Backend、Frontend、QA/Test Plan、DevOps/Release 和独立 checker agent。
21. P0.1 UI/UX 设计仍可作为价值体验预研，但范围只覆盖 session 内训练体验：听一句、选一个、回一句、跟一句、补一句、追问继续说、hint ladder、语音主路径/文本兜底、教练反馈和学习证据写回；不得替代 P0 商业发布门禁，也不得扩展到 P0.2/P1/P2 或完整商业订阅 UI。
22. 2026-05-29 Product Manager 已为 P0 商业化订阅上线准备补充 PM 阶段开发计划，位置为 `docs/product/increments/commercial-subscription-readiness/definition.md` 的 `PM 阶段开发计划`。
23. 2026-05-29 在本轮执行前，P0 商业化实现就绪状态为 blocked：`docs/product/increments/commercial-subscription-readiness/test_cases.md` 尚未建立，Domain/API/Architecture/UX/QA 下游门禁未全部通过，因此不得直接开始 Backend、Frontend、AI Runtime 或 DevOps 实现。
24. 2026-05-29 本轮执行目标是由 Development Orchestrator 路由 `P0-COM-DOM-001`、`P0-COM-API-001`、`P0-COM-ARCH-001`、`P0-COM-UX-001` 和 `P0-COM-QA-001`，并在 AC-to-TC gate 通过后再进入商业 foundation、权益 gating、支付 provider、Flutter 商业 UI、release 和 QA 执行批次。
25. 2026-05-29 已完成 `P0-COM-DOM-001`、`P0-COM-API-001`、`P0-COM-ARCH-001`、`P0-COM-UX-001` 和 `P0-COM-QA-001` 的文档门禁补齐；`docs/product/increments/commercial-subscription-readiness/test_cases.md` 已建立。
26. P0 商业化需求到测试用例的 100% 追溯已建立：`FR-COM-001` 到 `FR-COM-012` 均通过 `AC-COM-001` 到 `AC-COM-014` 映射到 `TC-COM-001` 到 `TC-COM-023`；`TC-COM-023` OpenAPI contract gate 已通过。
27. P0 商业化仍不是商业发布 ready：`TC-COM-001` 到 `TC-COM-023` 已有追溯和部分本地自动化/系统 E2E/contract evidence；但 TC-COM-012/015/019/021/022 strict native/social/store/provider/release gates 在 2026-06-03 复测仍失败，Apple/Google sandbox/internal test、社交登录生产配置、release secrets、签名、符号表、商店材料、外部 evidence refs 和独立审查仍是发布阻塞项。
28. 2026-06-01 Product Manager 已接受 `CR-20260601-002 商业 AI Provider 生产化加固`，并新增 `commercial-ai-provider-hardening` increment，承接对象存储上传、持久化 TTS cache、真实 DashScope evidence、AI 成本看板和生产 AI 数据策略。
29. `commercial-ai-provider-hardening` 的本地实现和测试证据已建立：TC-COM-AI-001 through TC-COM-AI-003、TC-COM-AI-005 through TC-COM-AI-007 通过；TC-COM-AI-004 结构化 evidence gate 通过，2026-06-03 脱敏 controlled-live evidence-prep 通过，但 strict external evidence ref 仍未供应。
30. 2026-06-02 P0/P0.1 blocker 复测完成：P0.1 local core/provider suites、P0 commercial backend/Flutter/API contract suites、MVP system E2E suites 均通过；测试环境修复包括 OPS health auth、E2E deterministic provider isolation、会员 restore button 滚动断言和账号注销 audit event 断言。
31. 2026-06-03 已按顺序关闭本地可控 P0.1 blockers：TC-P01-013 通过 `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop`，TC-P01-014 通过 `dart run scripts/check_ai_eval_cases.dart`。
32. 2026-06-03 新增 P0.1 商业软件整改批次：不新增 stage，在 `p0-1-expression-automation-training` 内补齐 P01-FR-012 through P01-FR-017、P01-SPEC-013 through P01-SPEC-018、AC-P01-014 through AC-P01-019、TC-P01-021 through TC-P01-028、P01-TR-013 through P01-TR-018 和 `P01-GAP-009` through `P01-GAP-014`。
33. P0 商业发布外部门禁仍必须补齐 TC-COM-012/015/019/021/022 和 TC-COM-AI-004 的外部/native/store/release evidence refs 并 rerun strict gates；这些不被 P0.1 本地或生产整改文档替代。
34. 2026-06-04 Product Manager 已接受启动 P0.2 文档设计，不等待代码实现：早期单体记忆调度 artifact 曾形成 P02-SI-001..006 的部分设计输入，但用户目标驱动审查后已被删除并 superseded，不能作为实现入口。
35. P0.2 当前 implementation readiness 为 gated by release/Product Base approval：三个新 increment 已有 requirements/spec/acceptance/test_cases/traceability 和本地 deterministic slice evidence；Followup-A 已完成本地实现审核；Followup-B 已完成 requirements/spec/acceptance/test_cases/traceability、domain model、UX/screen spec、AI runtime schema、API/OpenAPI contract 和 generated client sync 审核。Followup-B backend/frontend control source/update/pause/resume slice、S002-A notification eligibility policy、S002-B notification outbox lifecycle/replay、S003 missed-day recovery planner、S004 item-level MemoryCurvePolicy、S005 mastery transition 和 S006 replay/performance/coverage/traceability gates 已有本地执行证据；TC-P02-FUB-001/002/003/004/005/006/007/008/009/010/011/012/013/014/015/016/017 passed，其中 TC-P02-FUB-002 关闭当前 S001 control、control idempotency、redacted audit、retention policy snapshot 和 account-deletion cleanup 范围，TC-P02-FUB-005/006 关闭 reason precedence、quiet hours、permission/consent/entitlement/quota/stale/missing-plan 和 Flutter no-false-completion 范围，TC-P02-FUB-007/008 关闭 pending/scheduled/blocked/cancelled/failed/expired/sent lifecycle、dedupe key、cancel/reschedule、retry/failure recovery、redacted payload projection、replay audit 和 outbox deletion cleanup 范围，TC-P02-FUB-009/010 关闭 compress/defer/replace、hard safety/feasibility precedence、balanced tie-breaker、no overdue stacking、daily budget cap、decision persistence、idempotent replay 和 recovery replay audit 范围，TC-P02-FUB-011/012 关闭 forgetting risk、retrieval success/failure、paused/control-blocked、overlearning cap、interleaving cap、daily budget defer、default intervals 和 item_policy replay determinism 范围，TC-P02-FUB-013/014 关闭 accepted evidence thresholds、one-level promotion cap、hold/demotion、read-only transition audit、deterministic mastery_transition replay audit、account-deletion cleanup 和 AI forbidden persistent-field rejection 范围，TC-P02-FUB-015/016/017 关闭 global replay fixture、p95 performance budgets、coverage gate 和 dedicated traceability script 范围。Followup-C S000 文档链验证、S001 forecast hardening、S002 checkpoint task library 和 S003 checkpoint-to-plan update 已有本地执行证据，TC-P02-FUC-001/002/003/004/005/006/007/008/009 passed；S004-S007 尚未开始。Followup-B/C are not release-ready；Product Base merge is not approved。
36. 2026-06-04 用户目标驱动审查结论：现有 Product Base、P0.1、P0.2 旧设计、P1/P2 均未完整覆盖 GoalProfile、DiagnosticAssessment、GoalBackplan、AutopilotTraining、MemoryCurvePolicy、ProgressForecast 和 OutcomeCheckpoint；P0.2 stage 已重排为 `goal-driven-learning-autopilot` primary feature。
37. 2026-06-04 P0.2 新 stage plan：`p0-2-goal-diagnostic-foundation` 先建立目标画像和诊断，`p0-2-goal-backplan-memory-policy` 再生成目标倒排计划和记忆曲线策略，`p0-2-autopilot-progress-checkpoint` 最后承接自动带练、达标预测和周期复测。旧单体记忆调度 artifact 已删除；有效实现入口只剩三个新 planned increment。
38. 2026-06-04 P0.2 policy gates 下沉完成：P02-PG-001 through P02-PG-005 已进入三个 increment 的 requirements/spec/acceptance/test_cases/traceability；P02-SI-001 through P02-SI-013 均有 planned FR/Spec/AC/TC/Traceability 覆盖。实现仍受 domain/API/AI/UX、实际代码、性能预算、>=80% 代码覆盖率和 executed evidence gates 约束。
39. 2026-06-04 P0.2 Followup-A through Followup-D definition 和 WP traceability scaffold 已建立：A 关闭 GoalProfile/diagnostic user path，B 关闭 autopilot control/planner/memory，C 关闭 checkpoint/forecast/surfaces，D 关闭 release/commercial/data/ops gates。Followup-B 已补齐自己的 requirements/spec/acceptance/test_cases/traceability 和 Domain/API/OpenAPI/AI/UX 合同审核；这只解除 pre-implementation 文档/合同缺口，不等同于实现批准、测试通过或 release approval。
40. 2026-06-05 P0.2 Followup-C S000 文档链验证、S001 forecast hardening、S002 checkpoint task library 和 S003 checkpoint-to-plan update 本地实现/测试/独立审核已完成：TC-P02-FUC-001/002/003/004/005/006/007/008/009 passed，OpenAPI/generated Dart drift 已同步，AI deterministic no-provider fallback、candidate-only claim guard、checkpoint task-selection deterministic N/A 和 checkpoint-to-plan backend-owned replay signal 边界已记录。S004-S007 仍需按 slice 路由执行，不得把 S001/S002/S003 证据扩展为 Followup-C 完成、release ready 或 Product Base merge approval。

## PM 下一阶段开发计划

### Product Manager 理解与执行方式
本次规划请求属于 product direction / planning request，产品对象模式为 `feature-increment` 和 release-readiness planning。PM 已以 `docs/product/roadmap.md`、`docs/product/feature_registry.md`、`docs/product/stages/p0-commercial-readiness.md`、`docs/product/stages/p0-1-expression-automation.md`、三个活跃 increment definition、`docs/reports/test_report.md` 和 `docs/reports/quality_report.md` 为输入，先判断当前事实，再制定后续开发顺序。

执行步骤：
1. 确认 Product Base、feature registry、active stages 和 increment coverage。
2. 区分本地已关闭项、商业发布外部门禁、paid AI voice 外部门禁和 P0.1 价值体验合入复核。
3. 只在 PM 拥有的产品状态和 increment definition 中记录计划，不新增详细需求、测试用例或实现任务细节。
4. 将下一步交给 Development Orchestrator 路由，但要求每一步完成后进入独立 checker 审查。

### PM 结论
当前项目不需要重新启动 MVP 后端或继续补本地 P0.1 blocker。下一阶段主计划仍是关闭 P0 商业发布和 paid AI voice 的外部/native/store/release evidence，并做 P0.1 已实现训练闭环的 Product Base 合入复核；P0.2 已按用户指令进入 follow-up 批次。Followup-B 的 P02 domain/API/AI/UX 契约和 AC-to-TC 设计门禁已关闭，backend/frontend UserAutopilotControl control slice、S002-A notification eligibility policy、S002-B notification outbox lifecycle/replay、S003 missed-day recovery planner、S004 item-level MemoryCurvePolicy、S005 mastery transition 和 S006 replay/performance/coverage/traceability gates 已回写本地证据。Followup-C S000 文档链、S001 forecast hardening、S002 checkpoint task library 和 S003 checkpoint-to-plan update 已回写本地证据，S004-S007 仍需分片执行。Followup-B/C are not release-ready；Product Base merge is not approved。

### Completed Local Evidence - P0.1 Training Product Base/Production Hardening
目标：不新增 stage，在现有 `p0-1-expression-automation-training` increment 内把已通过本地验证的训练 Agent 加固到商业软件可接受的后端事实源、证据治理和运营门禁。该本地证据批次已完成；下一步不是继续执行这些 TC，而是等待 PM/用户确认设计方案后进入 Product Base 合入复核。

已完成批次：
1. `P01-HARDEN-001`：后端 Training API/source-of-truth 已有本地证据，TC-P01-021/022 passed。
2. `P01-HARDEN-002`：learning evidence rule trace、删除保留和数据治理已有本地证据，TC-P01-023/024 passed。
3. `P01-HARDEN-003`：reviewed versioned content/action-chain/target-expression mapping 已有本地证据，TC-P01-025 passed。
4. `P01-HARDEN-004`：media/AI Training pipeline 和 usage reservation/fallback 规则已有本地证据，TC-P01-026 passed；paid AI voice 仍受 P0 AI provider hardening gate 约束。
5. `P01-HARDEN-005`：planner decision audit、配置版本和 replay fixture 已有本地证据，TC-P01-027 passed。
6. `P01-HARDEN-006`：训练运营指标、feature flag、kill switch 和 rollout health gate 已有本地证据，TC-P01-028 passed。
7. `P01-HARDEN-007`：AC-to-TC、traceability、test report、quality report 和 release checklist 同步复核已完成到本地证据口径；不得用顶层 `[x] All required tests pass` 覆盖具体 commercial / paid AI external blockers。

### Now - P0 商业发布外部门禁关闭
目标：把 `commercial-subscription-readiness` 从“本地边界和契约通过”推进到“可被 PM 判断是否进入商业发布口径”。

优先批次：
1. `P0-COM-EXT-001`：补齐 TC-COM-019 支付 provider evidence，提供 `APPLE_SANDBOX_EVIDENCE_REF` 和 `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF`，覆盖购买、恢复、空恢复、退款、过期、宽限期和账号切换。
2. `P0-COM-NATIVE-001`：补齐 TC-COM-012 native social login evidence，替换 iOS WeChat placeholder URL scheme，提供 `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK` 和 Apple Sign In entitlement 证据。
3. `P0-COM-STORE-001`：补齐 TC-COM-015/021 store evidence，提供 `STORE_METADATA_EVIDENCE_REF`、`REVIEWER_ACCOUNT_REF`、`PRIVACY_URL` 和 `SUPPORT_URL`，并复核会员页、商店文案、隐私说明和真实权益一致。
4. `P0-COM-REL-002`：补齐 TC-COM-022 release evidence，提供生产 API URL、`ENV=production`、release signing、Sentry/symbol upload、rollback rehearsal、release secrets 和 strict gate 运行证据。
5. `P0-COM-QA-003`：rerun `scripts/check_provider_sandbox_evidence.py --strict-external`、`scripts/check_store_submission_evidence.py --strict-external`、`scripts/check_social_login_release_config.sh` 和 `scripts/check_release_readiness.sh`，并把结果写回 test/quality/release reports。

### Now - P0 paid AI voice 外部门禁关闭
目标：把 `commercial-ai-provider-hardening` 从“本地实现和 controlled-live evidence-prep 通过”推进到“真实 paid AI voice 可被 PM 审查”。

优先批次：
1. `P0-AI-EXT-001`：补齐 `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`，外部 evidence package 必须覆盖 LLM/ASR/TTS latency、error、cost、format compatibility、fallback 和独立审查。
2. `P0-AI-STORAGE-001`：本地阿里云 OSS storage adapter、canonical object_ref、signed upload/read URL 和 forged object_ref regression 已完成；后续补齐 `AI_MEDIA_STORAGE_EVIDENCE_REF`，证明真实对象存储 bucket、signed media ref、生命周期删除和 provider 可访问性。
3. `P0-AI-COST-001`：补齐 `AI_COST_DASHBOARD_EVIDENCE_REF`，确认套餐/用户/provider/model/cache hit/status 维度的最小成本看板、预算阈值和告警。
4. `P0-AI-RETENTION-001`：补齐 `AI_RETENTION_POLICY_EVIDENCE_REF`，证明音频、转写、provider payload、TTS cache、日志和账号注销删除策略已批准并可执行。
5. `P0-AI-QA-002`：rerun `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external`、`python3 scripts/check_ai_external_release_evidence.py --strict-external` 和 aggregate release gates；若 strict evidence 缺失，继续保持 paid AI voice blocked。

### Next - P0.1 Product Base 合入复核
目标：在不扩大 P0.1 范围的前提下，判断 `expression-automation-training` 的本地训练闭环是否可以作为稳定能力合入 Product Base。

优先批次：
1. `P01-PM-ACCEPT-001`：PM 复核 P0.1 traceability、test report、quality report，确认 TC-P01-013/014 已关闭且 P0.1 非目标边界仍有效。
2. `P01-GOV-001`：Product Object Governance Check 独立复核 P01-SI-001 到 P01-SI-011 是否仍由 `p0-1-expression-automation-training` 完整覆盖。
3. `P01-BASE-001`：若复核通过，只把已验证的 session 内训练能力合入 `docs/product/base/`；不得合入 P0.2 跨天调度、P1 笔记本/评分产品化或商业权益 gating。
4. `P01-REG-001`：更新 feature registry 中 `expression-automation-training` 的状态，并保留 paid AI voice release residual 指向 `commercial-ai-provider-hardening`。

### Next - P0.2 Followup-B 后续实现路由
- P0.2 目标驱动自动带练：原始三个 increment 已完成 requirements/spec/acceptance/test_cases/traceability 和本地 deterministic slice evidence；Followup-A 已完成本地实现审核；Followup-B 已完成 requirements/spec/acceptance/test_cases、traceability、Domain、API/OpenAPI/generated client sync、AI runtime 和 UX 合同审核，并已完成 backend/frontend UserAutopilotControl control slice、S002-A notification eligibility policy、S002-B notification outbox lifecycle/replay、S003 missed-day recovery planner、S004 item-level MemoryCurvePolicy、S005 mastery transition 与 S006 replay/performance/coverage/traceability gates 的本地执行证据回写。Followup-C 已完成 S000 document chain、S001 forecast hardening、S002 checkpoint task library 和 S003 checkpoint-to-plan update 本地证据；当前合法下一步是继续路由 Followup-C S004 backend projection、S005 Home/Queue/Wiki surfaces、S006 downgrade/data governance 和 S007 performance/final traceability 小 slice。Followup-D 仍需补齐 release/commercial/data/ops gates。

### Later - 暂不进入当前实现
- P1 笔记本与评分产品化：只保留 backlog，不进入当前实现。
- P1 场景包扩展和 P2 A1-C2 内容体系：只保留内容战略，不进入当前实现。
- 任意场景、公开社区、真人导师市场、课程市场：继续 Not Now。

## 风险与边界
- 当前只有 2 个真实官方场景，内容规模不足以支撑“任意场景”承诺。
- 当前 L1/L2/L3 不等同于完整 CEFR A1-C2，需要单独设计映射。
- 语音能力虽已接入并有 deterministic provider 自动化证据，但真实 LLM/ASR/TTS provider 可用性、音频权限、失败兜底和评分稳定性仍需外部门禁。
- 文档和部分中文静态内容存在编码显示风险，进入新阶段前应作为质量项处理。
- 训练 Agent 必须有确定性状态机，不能只依赖自由 LLM 对话。
- P0.1 只接管 session 内训练；跨 session、跨天、跨场景的长期调度放入 P0.2。
- 当前商业化能力仍不是完整付费上线闭环；真实支付 provider、Android/iOS 生产校验、webhook、退款/恢复、商业 gating 和付费流量风控必须由 `commercial-subscription-readiness` 或后续 owning increment 承接。
- 会员边界 UI 已有系统 E2E 证据，但会员页涉及真实权益兑现的文案、入口和 provider 状态仍需在商业化发布前单独验收。
- P0.1 DashScope adapter 已有本地 fake-provider 边界证据和 2026-06-03 脱敏 controlled-live evidence-prep；paid AI voice 仍需 `commercial-ai-provider-hardening` 关闭完整外部 evidence matrix、对象存储上传、外部 evidence refs、成本看板审批和生产数据策略。
- `/user/stats` 和 macOS notification 初始化在本地 E2E 中仍有非阻断日志，已记录为后续兼容性/测试环境清理项。

## 状态口径
当前不是从零开发新 MVP，而是在已有语音场景训练基线上继续升级。当前开发口径是“以已复测的 MVP 后端/API/DB/系统 E2E baseline 为基础，P0.1 TC-P01-013/014 本地 blocker 已关闭，P0 商业软件本地边界继续收敛外部/native/store/release evidence；任何商业发布、真实收费或 paid AI voice 目标必须先通过 owning increment、契约、测试、strict evidence gate 和独立审核”。
