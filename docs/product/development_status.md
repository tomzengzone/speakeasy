# 产品开发状态

## 状态
Validated - MVP 后端与数据库全量补齐已完成，系统 E2E gate 已通过

## Owner
Product Manager Agent

## Current Date
2026-05-29

## 活动目标
以 Product Base 活需求库承载已接受稳定能力。当前 MVP 后端与数据库补齐 stage 已完成实现、测试、发布证据和本地系统 E2E gate；后续工作进入新 stage/increment 时必须继续从 Product Base 和对应 increment 追溯，不得把本次完成状态扩展为 P0.1 或商业化自动批准。
- MVP 后端线：Product Base 已接受的登录、首评、官方场景、练习会话、AI/语音、推荐表达、学习记忆、会员边界和测试发布证据已补齐为当前后端/API/数据库事实，并通过本地 Flutter macOS + Spring Boot + 真实 PostgreSQL 系统 E2E 验证。
- 价值体验线：P0.1“口语优先、文本兜底的 FSI 式表达自动化训练闭环”保持 planned，后续实现应基于已验证的 MVP 后端/API/DB baseline，而不是重新绕开服务端事实。
- 商业发布线：P0 商业化订阅上线准备保持 planned/blocked-by-provider-readiness；真实支付 provider、webhook、退款/恢复和权益 gating 仍需独立商业化门禁。

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
- Active value-experience stage：`docs/product/stages/p0-1-expression-automation.md`
- P0.1 increment definition：`docs/product/increments/p0-1-expression-automation-training/definition.md`
- P0.1 increment requirements：`docs/product/increments/p0-1-expression-automation-training/requirements.md`
- P0.1 increment spec：`docs/product/increments/p0-1-expression-automation-training/spec.md`
- P0.1 acceptance criteria：`docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- P0.1 traceability：`docs/product/increments/p0-1-expression-automation-training/traceability.md`
- Commercial readiness stage：`docs/product/stages/p0-commercial-readiness.md`
- Commercial readiness increment definition：`docs/product/increments/commercial-subscription-readiness/definition.md`
- Commercial readiness requirements：`docs/product/increments/commercial-subscription-readiness/requirements.md`
- Commercial readiness spec：`docs/product/increments/commercial-subscription-readiness/spec.md`
- Commercial readiness acceptance：`docs/product/increments/commercial-subscription-readiness/acceptance.md`
- Commercial readiness traceability：`docs/product/increments/commercial-subscription-readiness/traceability.md`
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
- P0.1 `expression-automation-training` 仍是 increment planned 内容，完成实现、验收、追溯、测试和报告后，才允许由 Product Manager 批准 merge back 到 Product Base。
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
| 本地系统 E2E gate | 已通过 TC-MVP-E2E-001 到 TC-MVP-E2E-010 | `docs/product/increments/mvp-system-e2e-validation/`, `integration_test/`, `scripts/run_mvp_system_e2e.sh`, `docs/reports/mvp_system_e2e_handoff.md` | 电脑端可自动化验证 Flutter UI + Spring Boot + 真实 PostgreSQL；真实支付 provider 保留 manual/external gate |
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
19. 下一步不再是继续补齐 MVP backend foundation；应在确认外部门禁边界后，分别路由 P0.1 训练体验升级或 P0 商业化订阅上线准备。真实支付 provider、真实 LLM/ASR/TTS provider SLA、真机音频权限和商业权益 gating 不得被本地 E2E 自动化结果替代。

## 风险与边界
- 当前只有 2 个真实官方场景，内容规模不足以支撑“任意场景”承诺。
- 当前 L1/L2/L3 不等同于完整 CEFR A1-C2，需要单独设计映射。
- 语音能力虽已接入并有 deterministic provider 自动化证据，但真实 LLM/ASR/TTS provider 可用性、音频权限、失败兜底和评分稳定性仍需外部门禁。
- 文档和部分中文静态内容存在编码显示风险，进入新阶段前应作为质量项处理。
- 训练 Agent 必须有确定性状态机，不能只依赖自由 LLM 对话。
- P0.1 只接管 session 内训练；跨 session、跨天、跨场景的长期调度放入 P0.2。
- 当前商业化能力仍不是完整付费上线闭环；真实支付 provider、Android/iOS 生产校验、webhook、退款/恢复、商业 gating 和付费流量风控必须由 `commercial-subscription-readiness` 或后续 owning increment 承接。
- 会员边界 UI 已有系统 E2E 证据，但会员页涉及真实权益兑现的文案、入口和 provider 状态仍需在商业化发布前单独验收。
- `/user/stats` 和 macOS notification 初始化在本地 E2E 中仍有非阻断日志，已记录为后续兼容性/测试环境清理项。

## 状态口径
当前不是从零开发新 MVP，而是在已有语音场景训练基线上补齐服务端事实。当前开发口径已从“先完成 MVP 后端与数据库全量补齐”更新为“以已验证的 MVP 后端/API/DB/系统 E2E baseline 为基础，进入 P0.1 训练体验升级或 P0 商业化订阅上线准备；所有新增能力仍需重新走 owning increment、契约、测试和发布门禁”。
