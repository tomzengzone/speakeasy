# 产品路线图

## 状态
Draft - 基于当前已实现 MVP 基线和商业化订阅审查重新规划

## Owner
Product Manager Agent

## 规划判断
当前 SpeakEasy 已经不是“纯文本 MVP”。代码基线已经具备官方职场场景、语音场景模拟、TTS、录音、ASR/转写、LLM 教练反馈、发音/表达评分信号、表达队列、收藏、个人 Wiki、复习沉淀、练习总结、会员页和 Apple IAP 前端雏形。因此后续路线需要拆成两条并行主线：

**口语优先、文本兜底的 FSI 式表达自动化训练闭环。**

**真实商业订阅上线前的账号、支付、权益、合规和风控闭环。**

## 当前 MVP 基线
标准基线工件：`docs/product/baselines/current-mvp.md`。

- 登录门禁、首评、首页学习状态、官方场景管理。
- 官方场景资产：`job_interview`、`onboarding_introduction`，当前为 L1/L2/L3 结构，不等同于完整 A1-C2 体系。
- 听力热身、跟读、推荐表达队列、表达小练、收藏。
- 语音场景模拟：录音、转写、LLM 教练反馈、TTS 播放、可恢复错误、会话恢复。
- 学习沉淀：掌握表达、薄弱表达、复习时间、个人 Wiki、场景进度、练习总结。
- 商业入口：会员页和 Apple IAP 前端接入；Android 支付、服务端权益、完整权益 gating、生产账号和商业合规仍未形成真实付费闭环。

## Now: P0 商业化订阅上线准备（付费发布阻塞）
目标：把当前“会员入口 + Apple IAP 前端雏形”升级为可以面向真实用户收费的商业订阅闭环。该路线不替代 P0.1 训练闭环，而是作为付费发布前的阻塞条件。

Canonical scope：
- `docs/product/stages/p0-commercial-readiness.md`
- `docs/product/increments/commercial-subscription-readiness/definition.md`
- `docs/product/increments/commercial-subscription-readiness/requirements.md`
- `docs/product/increments/commercial-subscription-readiness/spec.md`
- `docs/product/increments/commercial-subscription-readiness/acceptance.md`
- `docs/product/increments/commercial-subscription-readiness/traceability.md`

下一工件：
- 由 Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、QA/Test Plan、DevOps/Release 分别补齐强制下游门禁。
- 每个下游门禁完成后，进入 Product Object Governance Check 和 Documentation Governance 复核。

## Now: P0.1 表达自动化训练闭环
目标：把现有语音场景模拟升级为训练型 Agent。用户只需完成听一句、选一个、回一句、跟一句、补一句、在追问下继续说等小动作；agent 在 session 内接管训练组织、节奏控制、难度拆解、重复推进、即时反馈和轻量场景施压。

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

下一工件：
- 更新 domain model、AI runtime schema、dialogue state machine、screen spec、architecture/module boundary 和测试用例。

Legacy source：
- `docs/product/features/mvp-learning-loop-spec.md` 仅作为 P0.1 legacy spec source，P0.1 标准增量工件已迁移生成到 `docs/product/increments/p0-1-expression-automation-training/`。

## Next: P0.2 跨 session 训练编排与记忆引擎强化
目标：让用户不需要自己决定今天练什么、练几组、哪些旧表达要复现、哪些薄弱点要插入新场景。

范围：
- Daily training planner：根据到期复习、薄弱表达、未完成 session、当前场景目标自动生成今日训练。
- Cross-session pressure ladder：跨轮次逐步减少提示、增强追问、提高复现要求。
- Mastery ladder：L0 未见过、L1 认得、L2 能跟读、L3 能提示下说出、L4 能场景中说出、L5 能压力下自然说出。
- Long-term session planner：系统决定跨天练几组、何时复习、何时复现、何时换场景。
- 训练证据进入首页推荐、表达队列和个人 Wiki。

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
- 训练闭环优先于场景数量。
- 表达自动化优先于解释知识点。
- Session 内训练接管必须进入 P0.1；跨 session 和跨天调度放入 P0.2。
- 语音主路径优先，但必须有文本兜底。
- 场景内容先做少而深，再做多而全。
- AI 不直接拥有持久化掌握状态的最终变更权；掌握更新必须可追踪、可测试。
