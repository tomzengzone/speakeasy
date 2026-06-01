# 功能 Backlog

## 状态
基于当前 Product Base、MVP 后端补齐、P0.1 训练闭环和商业化订阅审查重新规划。

## Owner
Product Manager Agent

## 规则
- 进入 Backlog 的功能必须能说明用户价值、阶段归属、范围边界和下游工件。
- 当前已实现能力不重复作为未实现 backlog；只记录需要产品化、扩展或重构的后续能力。
- 新功能进入实现前必须经过 Product Manager 接受范围，并由 Requirement Development 输出需求或 feature spec。

## MVP - 后端与数据库全量补齐（已完成 / Validated）
- `mvp-backend-foundation-auth`：后端 runtime、PostgreSQL/Flyway、统一错误、auth/session/current user/profile。
- `mvp-backend-onboarding-content`：首评、learning route、官方场景内容、场景状态和首页状态 API。
- `mvp-backend-practice-ai`：practice session lifecycle、ASR/TTS/pronunciation/LLM provider gateway、coach feedback 和可恢复失败。
- `mvp-backend-learning-memory`：推荐表达队列、复习、收藏、learning evidence、mastery、weakness、history 和 personal wiki。
- `mvp-backend-membership-boundary`：账号删除、云端学习数据处理、会员/报告/占位页 MVP 边界。
- `mvp-backend-client-qa-release`：OpenAPI/Dart client/Flutter integration、契约测试、实现报告、质量报告和 release evidence。
- Canonical scope：`docs/product/stages/mvp-backend-foundation.md`。
- 强制追溯：`MVP-SI-* -> MVP-BE-FR-* -> MVP-BE-SPEC-* -> AC-MVP-BE-* -> MVP-BE-TR-*`。

## P0 - 商业化订阅上线准备
- `commercial-subscription-readiness`：真实商业订阅上线准备，canonical scope 见 `docs/product/stages/p0-commercial-readiness.md` 和 `docs/product/increments/commercial-subscription-readiness/`。
- 强制下游门禁：Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、QA/Test Plan、DevOps/Release、Product Object Governance Check、Documentation Governance。
- `commercial-ai-provider-hardening`：paid AI voice / real provider 生产化加固，canonical scope 见 `docs/product/increments/commercial-ai-provider-hardening/`。
- AI provider 生产化强制门禁：对象存储上传可信 `audio_ref`、持久化 TTS cache、真实 DashScope sandbox evidence、AI 成本看板、生产 AI 数据保留/删除策略。
- P1 可继续优化 provider A/B、CDN 命中率、成本预测和多 provider fallback；P0 先关闭商业发布必需的最小安全/成本/合规边界。

## P0.1 - 表达自动化训练闭环
- 训练型 Agent：把现有语音场景模拟升级为由 agent 接管的训练流程，而不是开放式问答。
- Session 内训练 planner：决定当前小动作、目标表达、提示等级、重试、降级、升级或轻量施压。
- Micro-action UI/flow：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- Hint ladder：从无提示到句框、选项、chunk shadowing、model-then-retry。
- In-session pressure check：用户连续通过后减少提示，并进入轻量追问或近场景复现。
- FSI 式 micro-drill：模仿、替换、转换、回忆、场景回答、压力检测。
- 语音优先训练回合：TTS 提示、用户录音、ASR 转写、LLM 反馈、基础发音/表达评分。
- Action chain 训练：每个官方场景拆为可推进的小动作链路。
- 五角色行为模块：教练、导演、对话搭子、考官、记忆引擎。
- 训练证据写回：mastery、weakness、review queue、personal wiki、session summary。

## P0.2 - 跨 session 训练编排与记忆引擎
- Daily training planner：根据复习、薄弱点、未完成 session 和当前目标生成今日训练。
- Cross-session pressure ladder：跨轮次逐步减少提示、增加追问和场景压力。
- Mastery ladder：L0-L5 表达自动化等级。
- Long-term session planner：系统决定跨天练几组、何时复习、何时复现、何时换场景。
- 首页下一步建议接入训练 planner。

## P1 - 笔记本与评分产品化
- 任意短语/单词查询并加入笔记本。
- 笔记条目支持释义、例句、用户备注、场景来源、标签和复习状态。
- 表达评分、发音评分、流利度、完整度合并为口语表现卡。
- 评分历史进入学习报告和训练推荐。

## P1 - 场景包扩展
- 新增 3-5 个高频官方场景包。
- 每个场景包必须包含 action chain、目标表达、等级轨道、示范对话、跟读材料和评分 rubric。
- 将现有 L1/L2/L3 与 CEFR 做映射设计，但不立即承诺完整 A1-C2 覆盖。

## P2 - 内容体系与运营工具
- 完整 A1/A2/B1/B2/C1/C2 场景库。
- 内容生产、审核、版本管理和质量检查工具。
- 后台 CMS 或内容包构建流程。
- 高级间隔复习和跨场景迁移训练。

## Not Now
- 无限任意场景作为默认主流程。
- 用户生成公开场景社区。
- 真人导师市场。
- 课程市场。
- 把完整商业权益 gating 作为 P0.1 训练闭环前置条件；商业 gating 作为 P0 商业化订阅上线准备单独推进。
