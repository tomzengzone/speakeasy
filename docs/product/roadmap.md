# 产品路线图

## 状态
Validated for MVP backend stage with local system E2E gate - MVP 后端与数据库全量补齐已完成 TC-MVP-E2E-001 到 TC-MVP-E2E-010 本地系统黑盒验证；P0 商业化订阅上线准备是 P0.1 之上的商业软件功能补齐和付费发布阻塞 stage；真实支付 provider 和真实 AI provider 生产化证据均保留外部门禁。

## Owner
Product Manager Agent

## 规划判断
当前 SpeakEasy 已经不是“纯文本 MVP”。代码基线已经具备官方职场场景、语音场景模拟、TTS、录音、ASR/转写、LLM 教练反馈、发音/表达评分信号、表达队列、收藏、个人 Wiki、复习沉淀、练习总结、会员页和 Apple IAP 前端雏形。MVP 后端和数据库补齐 stage 已完成，Product Base 的当前 MVP 能力已具备后端/API/数据库事实和本地系统 E2E 证据。

后续路线拆成三条有顺序约束的主线：

**已完成线：MVP 后端与数据库全量补齐。**

**Now 发布阻塞线：商业软件功能补齐、真实商业订阅上线准备和 AI provider 生产化加固。**

**Next 价值体验线：口语优先、文本兜底的 FSI 式表达自动化训练闭环。**

**Next 目标达成线：目标画像、真实诊断、目标倒排计划、自动带练、记忆曲线、进度预测和周期复测。**

**外部门禁线：真实 payment provider、真实 AI provider、对象存储、商店配置、支付沙盒/生产校验、合规和发布证据。**

PM 复查判断：`p0-commercial-readiness` 是 P0 级 stage，位于 P0.1 训练体验升级之上。今天如果目标是“商业软件功能补齐”或“面向真实用户收费前准备”，下一步应先路由 P0 商业化订阅上线准备，而不是直接做 P0.1 前端 UI 设计。P0.1 仍是核心价值体验升级线，可以在不混入商业发布承诺的前提下做规划或并行预研，但不能替代 P0 的账号、支付、权益、合规、风控和发布门禁。

## 当前 Product Base
标准 Product Base 工件：
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`

- 登录门禁、首评、首页学习状态、官方场景管理。
- 官方场景资产：`job_interview`、`onboarding_introduction`，当前为 L1/L2/L3 结构，不等同于完整 A1-C2 体系。
- 听力热身、跟读、推荐表达队列、表达小练、收藏。
- 语音场景模拟：录音、转写、LLM 教练反馈、TTS 播放、可恢复错误、会话恢复。
- 学习沉淀：掌握表达、薄弱表达、复习时间、个人 Wiki、场景进度、练习总结。
- 商业入口：会员页和 Apple IAP 前端接入；Android 支付、服务端权益、完整权益 gating、生产账号和商业合规仍未形成真实付费闭环。
- 后端/数据库：MVP 后端与数据库补齐 stage 已完成；Product Base 的首评、场景内容、练习会话、AI/语音网关、学习记忆、Flutter client integration、release evidence 和本地系统 E2E gate 已形成当前基线。真实支付 provider、真实第三方 provider SLA、真机音频权限和商业权益 gating 仍保留外部门禁。

## Completed: MVP 后端与数据库全量补齐
目标：把 Product Base 已接受的 MVP 学习闭环补齐为后端/API/数据库可承接、可测试、可发布、可追溯的服务端事实。该 stage 已完成当前 MVP 后端基础，不扩大 P0.1 训练 Agent、P0 商业订阅、P0.2 长期记忆或 P1/P2 内容体系范围。

Canonical scope：
- `docs/product/stages/mvp-backend-foundation.md`
- `docs/product/increments/mvp-backend-foundation-auth/`
- `docs/product/increments/mvp-backend-onboarding-content/`
- `docs/product/increments/mvp-backend-practice-ai/`
- `docs/product/increments/mvp-backend-learning-memory/`
- `docs/product/increments/mvp-backend-membership-boundary/`
- `docs/product/increments/mvp-backend-client-qa-release/`
- `docs/product/increments/mvp-system-e2e-validation/`（`MVP-SI-014` 的系统级黑盒验证加固，不扩大产品功能范围）

每个 MVP backend increment 均包含 `definition.md`、`requirements.md`、`spec.md`、`acceptance.md` 和 `traceability.md`。

Stage Scope ID 到 increment 的全量分解：
- `MVP-SI-001`、`MVP-SI-002` -> `mvp-backend-foundation-auth`
- `MVP-SI-003`、`MVP-SI-004`、`MVP-SI-005` -> `mvp-backend-onboarding-content`
- `MVP-SI-006`、`MVP-SI-008`、`MVP-SI-009` -> `mvp-backend-practice-ai`
- `MVP-SI-007`、`MVP-SI-010` -> `mvp-backend-learning-memory`
- `MVP-SI-011`、`MVP-SI-012` -> `mvp-backend-membership-boundary`
- `MVP-SI-013`、`MVP-SI-014` -> `mvp-backend-client-qa-release`
- `MVP-SI-014` system E2E hardening -> `mvp-system-e2e-validation`

完成证据：
- 六个 MVP backend increments 已完成实现、测试和报告证据，`MVP-SI-001` 到 `MVP-SI-014` 均在 `docs/product/stages/mvp-backend-foundation.md` 中闭环。
- 系统级黑盒测试加固使用 `MVP-SI-014 -> MVP-E2E-FR-* -> MVP-E2E-SPEC-* -> AC-MVP-E2E-* -> MVP-E2E-TR-*`，当前本地 gate 已通过 TC-MVP-E2E-001 到 TC-MVP-E2E-010，并反向映射 Product Base AC-001 到 AC-013；TC-MVP-E2E-010 的真实支付 provider 子范围保留 manual/external gate，不得误计为本地自动化已完成真实支付。

## Now: P0 商业化订阅上线准备（商业软件功能补齐 / 付费发布阻塞）
目标：把当前“会员入口 + Apple IAP 前端雏形”升级为可以面向真实用户收费的商业订阅闭环。该路线不替代 P0.1 训练闭环；在当前执行顺序上，商业化实现不得混入 P0.1 训练体验当前切片，真实 provider 仍走独立外部门禁。

Canonical scope：
- `docs/product/stages/p0-commercial-readiness.md`
- `docs/product/increments/commercial-subscription-readiness/definition.md`
- `docs/product/increments/commercial-subscription-readiness/requirements.md`
- `docs/product/increments/commercial-subscription-readiness/spec.md`
- `docs/product/increments/commercial-subscription-readiness/acceptance.md`
- `docs/product/increments/commercial-subscription-readiness/traceability.md`
- `docs/product/increments/commercial-ai-provider-hardening/definition.md`
- `docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- `docs/product/increments/commercial-ai-provider-hardening/spec.md`
- `docs/product/increments/commercial-ai-provider-hardening/acceptance.md`
- `docs/product/increments/commercial-ai-provider-hardening/test_cases.md`
- `docs/product/increments/commercial-ai-provider-hardening/traceability.md`

下一工件：
- 订阅闭环本地 Domain/API/Architecture/UX/QA/DevOps 门禁和自动化复测已完成；下一步是补齐 TC-COM-012/015/019/021/022 的外部/native/store/release evidence。
- AI provider 生产化本地 architecture/backend/QA/ops/security gates 已完成；2026-06-03 controlled-live evidence-prep passed and wrote a sanitized local report；下一步是补齐 `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`、object-storage lifecycle、cost dashboard approval 和 retention/privacy external evidence。
- 每个剩余外部门禁完成后，仍需进入 Product Object Governance Check、Documentation Governance 和独立质量复核。

## Now: P0 商业 AI Provider 生产化加固（paid AI voice 发布阻塞）
目标：把 P0.1 已实现的本地可测 DashScope adapter 边界，补齐为生产 paid AI voice 可用的媒体、缓存、真实 provider、成本和数据策略能力。该路线不改变 P0.1 训练体验目标；它负责回答“AI 能力能不能安全、可控成本、可审计地对真实用户开放”。

范围：
- 对象存储上传链路：Flutter 录音后上传到后端或对象存储，由后端生成可信 `audio_ref`。
- 持久化 TTS 缓存：text hash/model/voice/language 命中后复用对象存储音频，支持多实例、重启、过期和删除。
- 真实 DashScope sandbox / controlled live 测试：LLM、Paraformer ASR、TTS 的 latency、error code、cost、format compatibility 和 fallback evidence。
- AI 成本看板：按套餐、用户 hash、provider family、模型、状态、cache hit 和 fallback reason 统计成本和毛利风险。
- 生产级数据策略：音频、转写、provider payload、TTS cache、日志和账号注销的保留、删除、匿名化和审计证据。

阶段判断：
- P0 必须落地 minimum production gate：对象存储上传、持久化 TTS cache、DashScope evidence、最小成本看板和数据策略。
- P1 可以继续优化：provider A/B、CDN 命中率、毛利预测、定价实验和多 provider fallback。
- P0.1 只消费该能力，不负责关闭生产化发布门禁。

## Next: P0.1 表达自动化训练闭环
目标：把现有语音场景模拟升级为训练型 Agent。用户只需完成听一句、选一个、回一句、跟一句、补一句、在追问下继续说等小动作；agent 在 session 内接管训练组织、节奏控制、难度拆解、重复推进、即时反馈和轻量场景施压。该路线是核心价值体验升级线，但排序低于 P0 商业软件功能补齐的付费发布阻塞 stage；实际 committed implementation 必须先通过 P0.1 范围的 UI/UX、domain、AI runtime、dialogue state、architecture/module boundary 和测试用例门禁。

范围：
- 以两个现有官方场景为第一批验证场景。
- 将每个场景拆为 action chain：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 基于 FSI 思路实现 micro-drill：模仿、替换、转换、回忆、场景回答、压力检测。
- 将五角色落成行为模块：教练、导演、对话搭子、考官、记忆引擎。
- Session 内训练 planner：决定当前小动作、目标表达、提示等级、重试、降级、升级或轻量施压。
- Micro-action UI/flow：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- Hint ladder：从无提示到句框、选项、chunk shadowing、model-then-retry。
- In-session pressure check：用户连续通过后减少提示，并进入轻量追问或近场景复现。
- 语音作为主路径，文本作为 ASR 失败、麦克风拒绝或调试兜底。
- 发音评分进入反馈，但不作为唯一通关条件；表达完成度和场景任务完成度是主指标。
- 每轮训练必须写回学习证据：掌握、薄弱、复习、个人素材、下一步建议。

已生成标准增量工件：
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`

当前证据：
- 2026-06-03 TC-P01-013 route integration passed through `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop`。
- 2026-06-03 TC-P01-014 AI eval validator passed through `dart run scripts/check_ai_eval_cases.dart`。
- P0.1 本地 route/eval blocker 已关闭；不得把该结论扩展为商业发布或 paid AI voice readiness。

下一工件：
- PM 审查更新后的 P0.1 traceability、test report 和 quality report，决定是否把已接受稳定能力 merge back 到 Product Base。
- 若继续做体验差异化，只覆盖 P0.1 session 内训练体验，不扩展到 P0.2 跨天调度、P1 笔记本/评分产品化、P1/P2 内容体系或完整商业订阅 UI。

P0.1 标准增量工件：
- `docs/product/increments/p0-1-expression-automation-training/`

## Next: P0.2 目标驱动自动带练与跨 session 记忆引擎
目标：让用户不只是“不用决定今天练什么”，而是可以输入短期目标，例如 IELTS/TOEFL 口语目标分、商务英语口语能力、截止日期、每日可投入时间和强度偏好；系统诊断真实水平，倒排周计划/日计划/每次训练内容，并自动带用户完成训练、复习和复测，持续更新达标预测。

范围：
- GoalProfile：目标类型、目标分数/能力、截止日期、每日可投入时间、强度偏好。
- DiagnosticAssessment：初始口语测评、目标 rubric、弱项分解、置信度。
- GoalBackplan：从目标倒推周计划、日计划和每次训练内容。
- AutopilotTraining：系统自动开练、自动切换训练/复习/复测，不依赖用户自律。
- MemoryCurvePolicy：明确间隔复习算法、遗忘风险、复现、过度学习和 interleaving。
- ProgressForecast：当前距目标差距、预计达标日期、风险提醒、阶段复测。
- OutcomeCheckpoint：每周或每两周模拟考试/商务任务复测，更新计划。
- Daily training planner：根据到期复习、薄弱表达、未完成 session、当前场景目标自动生成今日训练。
- Cross-session pressure ladder：跨轮次逐步减少提示、增强追问、提高复现要求。
- Mastery ladder：L0 未见过、L1 认得、L2 能跟读、L3 能提示下说出、L4 能场景中说出、L5 能压力下自然说出。
- Long-term session planner：系统决定跨天练几组、何时复习、何时复现、何时换场景。
- 训练证据进入首页推荐、表达队列和个人 Wiki。

现有 stage 覆盖审查：
- Product Base 首评只覆盖目标方向、当前输出水平和每日分钟数，不能覆盖目标分数、截止日期、强度偏好或真实水平诊断。
- P0.1 覆盖 session 内训练自动化，不覆盖跨天目标倒排、达标预测或周期复测。
- 旧单体记忆调度设计覆盖 daily planner、pressure ladder、mastery 和 long-term schedule，但缺少 GoalProfile、DiagnosticAssessment、GoalBackplan、AutopilotTraining、MemoryCurvePolicy、ProgressForecast 和 OutcomeCheckpoint。
- P1 笔记本/评分产品化和 P1/P2 内容扩展可增强 rubric、内容和评分，但太靠后，不能作为目标驱动自动带练的前置核心。

重新规划的 P0.2 增量拆分：
- `p0-2-goal-diagnostic-foundation`：GoalProfile + DiagnosticAssessment，建立目标事实源、诊断测评、目标 rubric、弱项分解和置信度。
- `p0-2-goal-backplan-memory-policy`：GoalBackplan + MemoryCurvePolicy，基于目标、诊断、每日可投入时间和记忆曲线生成周计划/日计划/每次训练内容。
- `p0-2-autopilot-progress-checkpoint`：AutopilotTraining + ProgressForecast + OutcomeCheckpoint，自动开练、自动切换训练/复习/复测，并周期性更新目标差距和计划。

已启动标准增量文档设计：
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/definition.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/definition.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/definition.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/definition.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md`

当前口径：旧单体记忆调度 artifact 已删除并被新的目标驱动 P0.2 stage scope 吸收。P0.2 stage scope 扩展到 P02-SI-001 到 P02-SI-013；三个新 increment 已完成 requirements/spec/acceptance/test_cases/traceability 下沉设计并保留 P02-PG-001 through P02-PG-005 横向 policy gates。Followup-A through Followup-D 已建立正式 definition 和 WP traceability scaffold，用于把完整 GoalProfile UI、pause/resume/notification、Queue/Wiki propagation、commercial/cost/data/release gates 拆成可实施小增量。任何 follow-up 代码启动前仍必须补齐 requirements/spec/acceptance/test_cases、domain/API/AI/UX 契约、实际代码、性能测试、>=80% 代码覆盖率证据和独立 checker 复核。

## Next: P1 笔记本与评分产品化
目标：把“收藏表达”升级为真正的学习笔记与评分系统。

范围：
- 任意短语/单词查询与加入笔记本。
- 笔记条目支持来源、释义、例句、用户备注、场景标签、复习状态。
- 表达评分、发音评分、流利度、完整度形成统一口语表现卡。
- 分数用于推荐下一步训练，但避免单次分数决定长期掌握。

## Next: P1 场景内容扩展
目标：从两个职场场景扩展到可运营的场景包，而不是一次性承诺“任意场景”。

范围：
- 先扩展 3-5 个高频官方场景包，例如工作沟通、会议表达、客户沟通、旅行服务、校园交流。
- 为每个场景定义 action chain、目标表达、等级轨道、示范对话、跟读材料和评分 rubrics。
- 将现有 L1/L2/L3 映射到 CEFR 框架，但不立即承诺完整 A1-C2 全覆盖。

## Later: P2 A1-C2 内容体系与内容生产工具
目标：形成规模化内容体系。

范围：
- 完整 A1/A2/B1/B2/C1/C2 场景库。
- 内容生产、审核、版本管理和质量检查流程。
- 后台 CMS 或内容包构建工具。
- 高级间隔复习和跨场景迁移训练。

## Not Now
- 无限任意场景作为主流程。
- 用户生成公开场景社区。
- 真人导师市场。
- 课程市场。
- 把完整商业权益 gating 作为 P0.1 训练闭环前置条件；商业 gating 已单独进入 P0 商业化订阅上线准备。
- 在没有内容审核和安全边界前开放自由场景生成。

## 产品原则
- MVP 后端和数据库补齐已完成；P0 商业化订阅上线准备是 P0.1 之上的商业软件功能补齐和付费发布阻塞 stage。
- 若目标是商业发布或真实收费，当前 committed stage work 应优先进入 P0 商业化订阅上线准备；若目标是体验预研，P0.1 只能在明确不替代商业发布门禁的前提下推进 UI/UX 与契约门禁。
- 全量需求用于覆盖检查和防遗漏，不用于一次性展开所有阶段的前端 UI 实现。
- 训练闭环优先于场景数量。
- 表达自动化优先于解释知识点。
- Session 内训练接管必须进入 P0.1；跨 session 和跨天调度放入 P0.2。
- 语音主路径优先，但必须有文本兜底。
- 场景内容先做少而深，再做多而全。
- AI 不直接拥有持久化掌握状态的最终变更权；掌握更新必须可追踪、可测试。
