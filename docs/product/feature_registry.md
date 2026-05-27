# APP 功能注册表

## 状态
Draft - 从当前 MVP 基线和 P0.1 规划文档提炼。本文是稳定产品能力地图，不承载阶段计划细节、实现任务或测试证据。

## 上游来源
- `docs/product/features/mvp-learning-loop-requirements.md`：当前 Flutter APP 已实现能力基线。
- `docs/product/features/mvp-learning-loop-spec.md`：P0.1 表达自动化训练闭环 legacy spec。
- `docs/product/roadmap.md`
- `docs/product/development_status.md`
- `docs/process/change_request.md`

## 注册规则
- Feature 是 APP 长期稳定能力，不是 MVP、P0.1、P0.2、Now、Next、Later。
- Stage 只表示交付阶段或优先级窗口。
- Increment 是某个 stage 内的交付切片，必须引用 primary feature 和 affected features。
- Baseline 只记录已实现事实，不承诺未来新增需求。

## Feature 列表

| Feature slug | 稳定能力 | 当前状态 | Owner | 长期边界 | 关联 baseline/stage/increment |
| --- | --- | --- | --- | --- | --- |
| `access-onboarding` | 启动、登录门禁、首评和学习路线初始化 | Baseline | Product Manager | 负责用户进入 APP、完成首评、生成初始学习路线；不负责训练编排或支付权益 | `baselines/current-mvp` |
| `official-scenario-library` | 官方场景库、场景目录、场景等级和场景资产 | Baseline | Product Manager | 负责官方场景资产的选择、展示、加入、移除和等级切换；不承诺任意场景生成 | `baselines/current-mvp`, P0.1 |
| `listening-shadowing` | 听力热身、对话播放、跟读录音和基础评分反馈 | Baseline | Product Manager | 负责输入型练习和跟读；不负责 session 内训练编排 | `baselines/current-mvp`, P0.1 affected |
| `expression-practice-queue` | 推荐表达队列、表达小练、复习和变体任务 | Baseline | Product Manager | 负责表达任务队列和表达练习入口；不等同于长期记忆调度 | `baselines/current-mvp`, P0.1 affected |
| `voice-scenario-practice` | 语音场景模拟、录音作答、转写提交、教练反馈和会话恢复 | Baseline | Product Manager | 负责开放式语音场景练习；P0.1 将其升级为训练型 Agent 主路径 | `baselines/current-mvp`, P0.1 primary input |
| `expression-automation-training` | 训练型 Agent、action chain、micro-action、hint ladder、轻量压力检测 | Planned | Product Manager | 负责把表达训练到自动化；不在 P0.1 承诺跨天长期调度和完整 L0-L5 | P0.1 primary |
| `learning-memory-review` | 学习证据、个人 Wiki、复习沉淀、薄弱表达和练习总结 | Baseline | Product Manager | 负责记录和展示学习结果；P0.2 扩展跨 session/跨天调度 | `baselines/current-mvp`, P0.1 affected, P0.2 primary |
| `scoring-feedback` | 发音、表达完成度、语法或任务完成度反馈 | Baseline / Expanding | Product Manager | 负责反馈信号展示和训练建议；不让单次分数独立决定长期掌握状态 | `baselines/current-mvp`, P0.1 affected, P1 |
| `notebook-vocabulary` | 任意短语/单词查询、笔记和个人学习资产 | Planned | Product Manager | 负责笔记本和词句沉淀；不进入 P0.1 阻塞范围 | P1 |
| `profile-membership` | 我的、学习结果入口、会员页、Apple IAP 前端接入和设置 | Baseline / Affected | Product Manager | 负责个人中心和商业入口展示；不作为 P0.1 训练闭环阻塞项；商业付费闭环由 `commercial-subscription` 负责 | `baselines/current-mvp`, `commercial-subscription-readiness` affected |
| `commercial-subscription` | 生产账号、订阅支付、服务端权益、商业 gating、账号生命周期、合规和发布门禁 | Planned | Product Manager | 负责真实商业订阅上线能力；不负责训练 Agent 价值体验本身，也不承诺新增内容包或 CMS | `stages/p0-commercial-readiness`, `increments/commercial-subscription-readiness` |

## 当前 feature 判断
- 当前 APP 已有基础学习闭环，不是从零 MVP。
- P0.1 的 primary feature 是 `expression-automation-training`，它复用并改造 `voice-scenario-practice`、`listening-shadowing`、`expression-practice-queue`、`learning-memory-review` 和 `scoring-feedback`。
- P0 商业化订阅上线准备的 primary feature 是 `commercial-subscription`，它影响 `profile-membership`、`access-onboarding`、`voice-scenario-practice`、`official-scenario-library`、`learning-memory-review` 和 `scoring-feedback`，但不替代 P0.1 训练闭环。
- P0.2 的 primary feature 应是 `learning-memory-review` 的增强，即跨 session/跨天训练编排和记忆引擎。
- P1/P2 才进入 `notebook-vocabulary`、评分产品化、更多场景包和完整 A1-C2 内容体系。

## Legacy 文档处理
- `docs/product/features/mvp-learning-loop-requirements.md` 保留为 legacy baseline source。
- `docs/product/features/mvp-learning-loop-spec.md` 保留为 legacy P0.1 spec source。
- 新增产品工作必须优先使用 `docs/product/baselines/`、`docs/product/stages/` 和 `docs/product/increments/` 下的对象化路径。
