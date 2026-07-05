# APP 功能注册表 V1 冻结快照

## 状态
Archived / not active source of truth - 本文是 2026-07-01 迁移到 V2 capability registry 前的 V1 快照，只用于历史追溯。当前唯一 active registry 是 `docs/product/feature_registry.md`。新增或修改下游 requirements、spec、acceptance criteria、test cases、stage scope 和 increment definition 时，不得继续引用本文作为 active source of truth，必须改用 V2 `Capability ID` 和 `Sub-capability ID`。

## 冻结说明
- 本快照保留迁移前的 V1 slug、稳定能力、当前状态、owner、长期边界和关联 product source/stage/increment。
- V1 中的 `access-onboarding` 是用户旅程聚合，V2 已拆分到账号、诊断、目标计划和触达留存能力。
- V1 中的 `server-backed-learning-foundation` 与 `ai-provider-operations` 是服务端、AI provider、运营和发布支撑，V2 不再把它们作为顶层业务 capability。
- 历史 increment、FR、AC、TC 可通过 active registry 的 `Legacy Mapping` 追溯到 V2。

## 上游来源
- `docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`：当前稳定产品能力 source of truth。
- `docs/product/features/mvp-learning-loop-requirements.md`：历史来源路径；文件已删除，内容已迁入 Product Base / increment 或由 V2 `Legacy Mapping` 承接，不再作为 active source、compatibility source 或新增下游输入。
- `docs/product/features/mvp-learning-loop-spec.md`：历史来源路径；文件已删除，内容已迁入 Product Base / increment 或由 V2 `Legacy Mapping` 承接，不再作为 active source、compatibility source 或新增下游输入。
- `docs/product/roadmap.md`
- `docs/product/development_status.md`
- `docs/product/stages/mvp-backend-foundation.md`
- `docs/product/stages/p0-commercial-readiness.md`
- `docs/product/stages/p0-1-expression-automation.md`
- `docs/process/change_request.md`

## V1 注册规则（历史）
- Feature 是 APP 长期稳定能力，不是 MVP、P0.1、P0.2、Now、Next、Later。
- Stage 只表示交付阶段或优先级窗口。
- Increment 在 V1 历史模型中是某个 stage 内的交付切片，并引用历史主能力和受影响能力字段；该规则不适用于新增或修改的下游文档。
- Baseline 只记录已实现事实，不承诺未来新增需求。

## V1 Feature 列表

| V1 slug | 稳定能力 | 当前状态 | Owner | 长期边界 | 关联 product source/stage/increment |
| --- | --- | --- | --- | --- | --- |
| `access-onboarding` | 启动、登录门禁、首评和学习路线初始化 | Product Base | Product Manager | 负责用户进入 APP、完成首评、生成初始学习路线；不负责训练编排或支付权益 | `product-base` |
| `official-scenario-library` | 官方场景库、场景目录、场景等级和场景资产 | Product Base | Product Manager | 负责官方场景资产的选择、展示、加入、移除和等级切换；不承诺任意场景生成 | `product-base`, P0.1 |
| `listening-shadowing` | 听力热身、对话播放、跟读录音和基础评分反馈 | Product Base | Product Manager | 负责输入型练习和跟读；不负责 session 内训练编排 | `product-base`, P0.1 affected |
| `expression-practice-queue` | 推荐表达队列、表达小练、复习和变体任务 | Product Base | Product Manager | 负责表达任务队列和表达练习入口；不等同于长期记忆调度 | `product-base`, P0.1 affected |
| `voice-scenario-practice` | 语音场景模拟、录音作答、转写提交、教练反馈和会话恢复 | Product Base | Product Manager | 负责开放式语音场景练习；P0.1 将其升级为训练型 Agent 主路径 | `product-base`, P0.1 primary input |
| `expression-automation-training` | 训练型 Agent、action chain、micro-action、hint ladder、轻量压力检测 | Next value-experience | Product Manager | 负责把表达训练到自动化；不在 P0.1 承诺跨天长期调度和完整 L0-L5 | P0.1 primary |
| `goal-driven-learning-autopilot` | 目标画像、诊断测评、目标倒排计划、自动带练、达标预测和周期复测 | Planned P0.2 | Product Manager | 负责把训练从“练什么推荐”升级为“围绕目标自动带用户达标”；不承诺官方考试认证分数，不绕过商业或 paid AI release gates | P0.2 primary |
| `learning-memory-review` | 学习证据、个人 Wiki、复习沉淀、薄弱表达和练习总结 | Product Base / P0.2 affected | Product Manager | 负责记录和展示学习结果；P0.2 作为目标驱动自动带练的 affected feature 扩展跨 session/跨天调度 | `product-base`, P0.1 affected, P0.2 affected, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint` |
| `scoring-feedback` | 发音、表达完成度、语法或任务完成度反馈 | Product Base / Expanding | Product Manager | 负责反馈信号展示和训练建议；不让单次分数独立决定长期掌握状态 | `product-base`, P0.1 affected, P1 |
| `server-backed-learning-foundation` | MVP 服务端学习事实、API/数据库承接、客户端契约和发布证据 | Validated | Product Manager | 负责把 Product Base 学习闭环从本地/前端事实补齐为服务端可追溯事实；不负责 P0.1 训练 Agent 体验升级或 P0 商业订阅闭环 | `stages/mvp-backend-foundation`, `increments/mvp-backend-*`, `increments/mvp-system-e2e-validation` |
| `ai-provider-operations` | 服务端 AI provider、媒体上传、TTS 缓存、成本观测、真实 provider evidence 和数据保留删除 | P0 release-hardening | Product Manager / Ops | 负责把 LLM/ASR/TTS 从本地 adapter 证据升级为可发布、可控成本、可审计、可删除的生产能力；不负责训练 Agent 体验本身或新增内容包 | `stages/p0-commercial-readiness`, `increments/commercial-ai-provider-hardening`, P0.1 affected |
| `notebook-vocabulary` | 任意短语/单词查询、笔记和个人学习资产 | Planned | Product Manager | 负责笔记本和词句沉淀；不进入 P0.1 阻塞范围 | P1 |
| `profile-membership` | 我的、学习结果入口、会员页、Apple IAP 前端接入和设置 | Product Base / Affected | Product Manager | 负责个人中心和商业入口展示；不作为 P0.1 训练闭环阻塞项；商业付费闭环由 `commercial-subscription` 负责 | `product-base`, `commercial-subscription-readiness` affected |
| `commercial-subscription` | 生产账号、订阅支付、服务端权益、商业 gating、账号生命周期、合规和发布门禁 | P0 release-blocking | Product Manager | 负责真实商业订阅上线能力；不负责训练 Agent 价值体验本身，也不承诺新增内容包或 CMS | `stages/p0-commercial-readiness`, `increments/commercial-subscription-readiness` |

## V1 feature 判断
- 当前 Product Base 已覆盖基础学习闭环，不是从零 MVP。
- `server-backed-learning-foundation` 已完成当前 MVP 后端/API/DB/客户端契约/测试发布证据补齐，并通过本地系统 E2E gate。
- P0 商业化订阅上线准备在 V1 历史判断中包含两个主能力方向：`commercial-subscription` 负责订阅、权益、账号和发布门禁；`ai-provider-operations` 负责真实 AI provider 生产化、媒体生命周期、成本观测和数据保留删除。当目标是真实收费或 paid AI voice 准备时，它们都位于 P0.1 价值体验之上的 release-blocking stage。
- P0.1 的 V1 历史主能力是 `expression-automation-training`，它复用并改造 `voice-scenario-practice`、`listening-shadowing`、`expression-practice-queue`、`learning-memory-review` 和 `scoring-feedback`，但不替代 P0 商业发布门禁。
- P0.2 经用户目标驱动审查后，V1 历史主能力调整为 `goal-driven-learning-autopilot`；`learning-memory-review` 是关键受影响能力。旧单体记忆调度 artifact 已删除，后续实现前必须以 `p0-2-goal-diagnostic-foundation`、`p0-2-goal-backplan-memory-policy`、`p0-2-autopilot-progress-checkpoint` 以及 Followup-A through Followup-D hardening increments 为 source of truth；不得只按本地 deterministic 垂直切片声明完整 P0.2。
- P1/P2 才进入 `notebook-vocabulary`、评分产品化、更多场景包和完整 A1-C2 内容体系。

## Legacy 文档处理
- `docs/product/features/mvp-learning-loop-requirements.md` 和 `docs/product/features/mvp-learning-loop-spec.md` 仅作为历史来源路径记录；文件已删除，内容已迁入 Product Base / increment 或由 V2 `Legacy Mapping` 承接。
- 这些历史路径不再作为 active source、compatibility source 或新增下游输入；新增产品工作必须优先使用 V2 `Capability ID` / `Sub-capability ID` 以及 `docs/product/base/`、`docs/product/stages/` 和 `docs/product/increments/` 下的对象化路径。
- Baseline 仅在需要冻结快照时创建，不替代 active V2 registry 或 Product Base。
