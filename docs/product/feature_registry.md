# APP 功能注册表

## 状态
Active v2 - 本文是 Product Manager 管理的当前唯一 active Capability Registry。下游 artifact 需要记录 capability classification 时，只使用本文 active V2 `Capability ID` / `Sub-capability ID`；产品行为仍以已批准 User Story / Vertical Slice 及其直接下游为来源。V1 已冻结到 `docs/product/baselines/feature-registry-v1-20260701.md`，只用于历史追溯，不再作为 active、compatibility 或新增下游 source of truth。

## 治理入口
- Product Manager 拥有本文中的 Capability / Sub-capability 产品事实、业务边界取舍和批准权。
- 创建、修改、拆分、合并、废弃、映射或 ready gate 使用 `.agents/skills/capability-registry-develop/SKILL.md`；未经 Product Manager 批准的 proposal 不写入本文。
- Canonical path、schema、文档类别、内容边界或 source-of-truth 规则变化进入 Documentation Governance 和 Product Object Governance Change / Check 流程。
- Registry 变更不自动创建或批量改写 Story、stage、increment、requirements、spec、AC、TC、架构或 evidence；受影响对象先进入 impact inventory，再由各自 owning workflow 处理。

## 注册边界
- Feature capability 是稳定商业学习类 APP 的长期业务能力，不是交付阶段、用户旅程步骤、技术基础设施、Domain、SWC、provider 运营或实现切片。
- Onboarding / first-run journey 不能作为顶层 capability；它应拆解映射到账号资料、当前水平画像、学习目标偏好、学习计划、触达留存等稳定业务能力。
- `server-backed-learning-foundation`、`ai-provider-operations` 不再作为顶层业务 capability；它们只作为架构、数据、AI runtime、运营、发布或旧能力映射支撑。
- 本注册表只登记稳定功能域、边界、一级子能力、相邻能力、下游文档前缀和旧能力映射；不写需求正文、spec、AC、TC、实现任务、测试证据或发布证据。

## 术语表

| 术语 | English term | 定义 | Owner |
| --- | --- | --- | --- |
| 训练对象 | Trainable Object | 内容库中可被计划、训练、评估和记忆引用的一级训练目标，例如一个 scenario、expression、word、phrase 或 sentence pattern。 | `CAP-CONTENT` |
| 练习单元 | Practice Unit | 隶属于训练对象的最小练习颗粒度，可被内容定义、练习互动、训练编排、反馈评估和学习证据引用，例如跟读、填空、选择、变形表达、听一句示范或 AI 对话触发点。 | `CAP-CONTENT` |
| 训练流 | Training Flow | 一个训练对象下预设的练习单元序列、分支、通过规则和 fallback 规则；训练流是内容资产，不由运行时 AI 为每个用户即时生成。 | `CAP-CONTENT` |
| 计划训练项 | Plan Training Item / Daily Plan Item | daily plan 中的最小规划颗粒度，通常引用一个训练对象，并携带计划原因、优先级、预期时长、完成规则和训练流引用。 | `CAP-PLAN` |
| 训练会话 | Training Session | 用户进入训练后由 `CAP-TRAIN` 创建、继续或恢复的一次运行实例，可承接一个或多个计划训练项。 | `CAP-TRAIN` |
| 反馈信号 | Coach Signal | 针对练习互动中的用户表现产生的评分、纠错、建议和解释；可被 `CAP-TRAIN` 用于训练节奏控制，也可被 `CAP-MEMORY` 用作证据候选。 | `CAP-COACH` |
| 学习证据 | Learning Evidence | 经规则接受后的学习事实，用于掌握度、弱项、复习和进度记录。 | `CAP-MEMORY` |

## 关系模型

```text
Capability ID
-> Sub-capability ID
-> Story / Vertical Slice classification and ownership

Stage Scope ID
-> Increment delivery commitment

Story / Vertical Slice
-> FR
-> Spec
-> AC
-> TC
-> SWC/API/Domain/AI/UX when applicable
-> Evidence
```

Capability / Sub-capability 是稳定分类，Stage Scope / Increment 是交付结构，Story / Vertical Slice 才是行为来源。完整分类、交付和 evidence join 只在 owning Product Base 或 increment `traceability.md` 中维护。

## CAP-ACC - 账号、身份资料与隐私

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-ACC` | `account-profile-privacy` | 账号、身份资料与隐私 | 用户账户能力 | Product Manager | Active v2 | 账号身份、基础资料、隐私授权、数据权利入口、账号安全设置 | 当前水平测评、学习目标偏好、学习计划、商业权益判定、onboarding 流程编排、通用 App 设置、用户支持服务、账单交易处理 | 用户能安全进入产品、管理身份资料和隐私权利 | `CAP-LEVEL`; `CAP-INTENT`; `CAP-COM`; `CAP-ENGAGE`; `CAP-SETTING`; `CAP-SUPPORT`; `CAP-BILLING` | `ACC` | 迁入旧 `access-onboarding` 的账号进入部分和旧 `profile-membership` 的个人资料部分 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-ACC` | `CAP-ACC-01` | 账号访问 | 登录方式选择、注册、登录凭证/验证码/第三方回调校验、账号恢复、登录态恢复、session/token 续期、当前设备退出 | 当前水平测评、商业权益授予、登录设备与远端会话管理 | 用户需要进入 App 或恢复身份 | 可识别账号或游客/未登录状态 | `FR-ACC` | Active v2 |
| `CAP-ACC` | `CAP-ACC-02` | 基础资料 | 昵称、头像、基础个人信息展示和编辑入口 | 当前水平画像、会员权益 | 用户已进入账号资料上下文 | 可展示和更新的基础资料 | `FR-ACC` | Active v2 |
| `CAP-ACC` | `CAP-ACC-03` | 隐私与授权 | 条款、隐私同意、权限授权状态 | 训练计划、支付协议 | 用户触发隐私、条款或权限场景 | 可追踪授权状态 | `FR-ACC` | Active v2 |
| `CAP-ACC` | `CAP-ACC-04` | 数据权利入口 | 数据导出、账号删除、注销入口 | 后端删除实现细节、审计任务 | 用户请求管理个人数据 | 可提交的数据权利请求 | `FR-ACC` | Active v2 |
| `CAP-ACC` | `CAP-ACC-05` | 安全设置 | 登录方式绑定/解绑、登录设备与远端会话管理、安全提示、二次验证入口、用户可见风险状态 | 登录凭证校验、风控模型实现 | 用户进入账号安全管理 | 可见安全状态和用户操作入口 | `FR-ACC` | Active v2 |

## CAP-LEVEL - 当前水平与能力画像

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-LEVEL` | `learner-level-profile` | 当前水平与能力画像 | 学习画像能力 | Product Manager | Active v2 | 当前水平自报、系统能力测评、能力标准与等级映射、多维能力画像、弱项证据与置信度、水平更新与复测版本 | 学习目标与偏好、学习计划生成、训练运行、单次反馈生成、商业权益 | 用户知道自己现在在哪，并获得可解释、可更新的能力画像 | `CAP-ACC`; `CAP-INTENT`; `CAP-PLAN`; `CAP-COACH`; `CAP-MEMORY` | `LEVEL` | 迁入旧 `access-onboarding` 的首评部分和旧 `goal-driven-learning-autopilot` 的当前水平画像边界 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-LEVEL` | `CAP-LEVEL-01` | 当前水平自报 | 用户自报等级、分项能力自评、学习经历、近期能力感受、入口来源标签 | 系统测评分数、目标设定、计划生成 | 用户首次进入水平上下文或主动更新 | 用户自报水平事实 | `FR-LEVEL` | Active v2 |
| `CAP-LEVEL` | `CAP-LEVEL-02` | 系统能力测评 | 首评/复测任务、能力采样、等级判断、测评完成状态 | 训练会话运行、官方考试认证承诺 | 用户完成测评任务或系统触发复测 | 系统测评结果与置信度 | `FR-LEVEL` | Active v2 |
| `CAP-LEVEL` | `CAP-LEVEL-03` | 能力标准与等级映射 | 能力维度、rubric、等级轨道、用户能力到等级的映射 | 官方考试认证、内容资产维护 | 需要解释或定位用户能力等级 | 可引用的等级映射 | `FR-LEVEL` | Active v2 |
| `CAP-LEVEL` | `CAP-LEVEL-04` | 多维能力画像 | 口语、听力、阅读、词汇、发音、流利度、语法和表达完成度等能力维度画像 | 单次训练运行、计划版本生成 | 自报、测评或学习证据存在 | 当前多维能力画像 | `FR-LEVEL` | Active v2 |
| `CAP-LEVEL` | `CAP-LEVEL-05` | 弱项、证据与置信度 | 薄弱项、证据来源、证据时间、置信度说明 | 纠错反馈生成、学习证据接受、掌握状态与遗忘风险 | 测评或学习证据可用 | 可解释弱项与置信度 | `FR-LEVEL` | Active v2 |
| `CAP-LEVEL` | `CAP-LEVEL-06` | 水平更新与复测版本 | 画像版本、复测入口、更新原因、前后对比状态 | 计划重算控制、周期复盘展示 | 用户主动更新或系统判断需要复测 | 新版本当前水平画像 | `FR-LEVEL` | Active v2 |

## CAP-INTENT - 学习目标与偏好

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-INTENT` | `learning-intent-preference` | 学习目标与偏好 | 目标偏好能力 | Product Manager | Active v2 | 目标设定、能力重点偏好、场景与内容偏好、投入约束与可用时间、学习形式与反馈偏好、目标支持状态与生命周期 | 当前水平测评、计划版本生成、训练运行、通知发送、商业权益、通用 App 设置 | 用户明确想去哪、愿意怎么学，并能维护目标生命周期 | `CAP-ACC`; `CAP-LEVEL`; `CAP-PLAN`; `CAP-CONTENT`; `CAP-TRAIN`; `CAP-ENGAGE` | `INTENT` | 迁入旧 `access-onboarding` 的目标与偏好采集部分和旧 `goal-driven-learning-autopilot` 的目标定义边界 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-INTENT` | `CAP-INTENT-01` | 目标设定 | 目标类型、目标水平、期限、成功标准 | 当前水平测评、路线生成 | 用户建立或修改学习目标 | 可追踪目标定义 | `FR-INTENT` | Active v2 |
| `CAP-INTENT` | `CAP-INTENT-02` | 能力重点偏好 | 口语、听力、阅读、词汇、发音、表达等能力重点和优先级 | 能力缺口测算、计划训练项生成、训练对象/训练流生产 | 用户选择学习重点 | 能力重点偏好 | `FR-INTENT` | Active v2 |
| `CAP-INTENT` | `CAP-INTENT-03` | 场景与内容偏好 | 场景、主题、内容类型、兴趣与回避项 | 官方内容资产维护、内容审核 | 用户设置内容偏好 | 可用于计划和推荐的内容偏好 | `FR-INTENT` | Active v2 |
| `CAP-INTENT` | `CAP-INTENT-04` | 投入约束与可用时间 | 每日/每周可用时间、强度、可学习时间段、不可用时段 | 目标期限、通知发送、计划重算策略 | 用户声明投入约束 | 可计算学习约束 | `FR-INTENT` | Active v2 |
| `CAP-INTENT` | `CAP-INTENT-05` | 学习形式与反馈偏好 | 练习形式、反馈深度、纠错频率、语音/文本偏好 | AI 反馈生成、训练会话运行 | 用户设置或调整学习方式 | 学习形式与反馈偏好 | `FR-INTENT` | Active v2 |
| `CAP-INTENT` | `CAP-INTENT-06` | 目标支持状态与生命周期 | 目标 active/paused/archived 状态、supported/partial/unsupported 支持状态、支持原因、生命周期边界 | 计划版本、达标预测、训练运行状态 | 目标需要评估或发生状态变化 | 目标支持状态 | `FR-INTENT` | Active v2 |

## CAP-PLAN - 学习计划与计划版本

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-PLAN` | `learning-plan-version` | 学习计划与计划版本 | 计划编排能力 | Product Manager | Active v2 | 目标差距映射、计划约束与优先级策略、周期计划生成、计划训练项交接、复习与记忆调度、计划版本重算与控制、阶段检查点、预测与解释 | 当前水平测评、目标业务定义、训练会话运行、练习单元状态、练习结果摘要、练习单元节奏、内容资产维护、通知渠道执行 | 系统能把当前水平和目标偏好转化为可解释、可重算的学习计划版本 | `CAP-LEVEL`; `CAP-INTENT`; `CAP-CONTENT`; `CAP-TRAIN`; `CAP-PRACTICE`; `CAP-MEMORY`; `CAP-ENGAGE` | `PLAN` | 迁入旧 `goal-driven-learning-autopilot` 的 backplan、计划版本、复习调度和阶段检查点边界 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-PLAN` | `CAP-PLAN-01` | 目标差距映射 | 当前水平与目标之间的能力差距、阶段差距说明 | 当前水平测评、目标业务定义 | 当前水平画像和目标偏好存在 | 目标差距模型 | `FR-PLAN` | Active v2 |
| `CAP-PLAN` | `CAP-PLAN-02` | 计划约束与优先级策略 | 派生计划时间预算、能力重点、内容边界、风险优先级策略 | 用户偏好原始定义、内容资产生产 | 目标、偏好、水平画像可用 | 计划约束与优先级策略 | `FR-PLAN` | Active v2 |
| `CAP-PLAN` | `CAP-PLAN-03` | 周期计划生成 | 周计划、日计划、计划训练项清单、阶段里程碑；计划训练项以训练对象为最小规划目标，并包含预期题量/时长、完成规则、优先级和计划来源 | 训练会话运行、练习单元状态、练习结果摘要、练习单元节奏 | 差距和约束已确定 | 包含 weekly plan、daily plan 和计划训练项清单的可执行学习计划版本 | `FR-PLAN` | Active v2 |
| `CAP-PLAN` | `CAP-PLAN-04` | 计划训练项交接 | 将 daily plan 中的计划训练项交接给 `CAP-TRAIN`，包含训练对象引用、训练流引用、预期题量/时长、完成规则、优先级和计划来源 | AI 训练界面、训练会话运行、练习单元状态、部分完成记录、练习结果摘要、训练闭环判定 | daily plan 可用 | 可由 `CAP-TRAIN` 承接的计划训练项交接摘要 | `FR-PLAN` | Active v2 |
| `CAP-PLAN` | `CAP-PLAN-05` | 复习与记忆调度 | 复习间隔、到期窗口、记忆策略、跨天调度 | 学习事实本体、通知发送渠道、训练运行 | 记忆事实和计划策略可用 | 复习与记忆调度安排 | `FR-PLAN` | Active v2 |
| `CAP-PLAN` | `CAP-PLAN-06` | 计划版本、重算与控制 | 计划版本、stale/replan 标记、重算触发、计划冻结、计划取消、计划恢复、计划替换控制 | 目标生命周期定义、训练会话运行、练习单元状态、计划训练项实际完成结果 | 约束、进度信号或水平发生变化 | 新增、更新、替换、标记 stale 或废止的计划版本 | `FR-PLAN` | Active v2 |
| `CAP-PLAN` | `CAP-PLAN-07` | 阶段检查点、预测与解释 | 阶段检查点、达标预测、风险解释、计划解释 | 官方证书或考试分数认证、学习事实生成 | 计划进度和学习证据存在 | 阶段检查点、预测与解释状态 | `FR-PLAN` | Active v2 |

## CAP-CONTENT - 内容资产

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-CONTENT` | `content-curriculum-scenario` | 内容资产 | 内容供给能力 | Product Manager | Active v2 | 官方内容库与目录结构、内容条目与课程定义、可训练对象、练习单元与训练流资产 | 训练会话运行、练习单元状态、练习结果摘要、用户学习进度、个性化计划策略、会员权益判定、反馈信号生成、内容错误反馈处理、任意生成内容承诺、用户目标定义 | 用户能浏览官方内容库，并打开可被下游练习、训练和复习模块引用的内容、训练对象、练习单元和训练流 | `CAP-INTENT`; `CAP-PLAN`; `CAP-PRACTICE`; `CAP-TRAIN`; `CAP-NOTE`; `CAP-COM`; `CAP-SUPPORT` | `CONTENT` | 迁入旧 `official-scenario-library`；旧 `voice-scenario-practice` 的内容资产部分迁入本域；旧 `expression-practice-queue` 中可复用练习素材资产部分迁入本域 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-CONTENT` | `CAP-CONTENT-01` | 官方内容库与目录结构 | 官方课程/场景内容库、按等级/场景/主题/课程路径组织的目录结构、目录入口、目录分组、目录排序、课程与多个目录视图的挂载关系 | 单个课程详情字段、课程内练习运行、用户学习进度、个性化推荐策略、会员权益判定、AI 反馈与评分 | 用户进入官方内容库、首页内容入口、计划/推荐链路需要引用官方内容集合 | 可浏览、可筛选、可进入课程详情的官方内容目录 | `FR-CONTENT` | Active v2 |
| `CAP-CONTENT` | `CAP-CONTENT-02` | 内容条目与课程定义 | 单个课程条目的课程类型、标题、简介、难度等级、所属目录、场景标签、能力标签、目标能力、适用人群、预计时长、课程内学习活动规划、素材摘要、权益要求标识、展示状态、版本/更新时间 | 听写文本输入、跟读录音、AI 对话聊天界面、表达小练作答流程、练习互动状态、用户是否拥有权益、反馈信号生成、评分解释、学习证据接受、掌握状态与遗忘风险 | 用户从内容目录、首页、计划、复习或推荐入口打开具体课程 | 可展示、可被下游练习模块引用的课程定义与课程上下文 | `FR-CONTENT` | Active v2 |
| `CAP-CONTENT` | `CAP-CONTENT-03` | 可训练对象、练习单元与训练流资产 | 面向场景、词汇、表达、句型等训练对象的素材集合；训练对象对应的标准练习单元、训练步骤序列和训练流模板；填空、听写、选择、变形选择、跟读、重复对话、图文/视频关联题等题型资产定义；题干、标准答案/参考答案、选项、干扰项、媒体引用、提示模板、可用变体、通过规则引用、难度、目标能力、适用场景、练习用途标签和版本状态 | 用户今日练什么、daily plan 生成、个性化训练顺序、训练会话运行、练习单元状态、练习结果、反馈信号生成、训练节奏控制、学习证据接受、掌握状态与遗忘风险 | 官方内容、场景、词汇或表达资产需要被练习、训练、复习或 AI 调度引用 | 可被 `CAP-PRACTICE` 互动、被 `CAP-TRAIN` 调度、被 `CAP-PLAN` 引用的训练对象、练习单元、训练流和题型资产 | `FR-CONTENT` | Active v2 |

## CAP-PRACTICE - 练习会话与互动

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-PRACTICE` | `practice-session-runtime` | 练习会话与互动 | 练习运行能力 | Product Manager | Active v2 | 课程内专项练习、题型化巩固练习、AI 对话练习、练习输入、提交、回合互动、互动状态和结果摘要产出 | weekly/daily plan 生成、计划训练项顺序、练习单元状态、训练对象/训练流生产、课程资产所有权、音频与语音体验偏好配置、反馈信号生成、学习证据接受、掌握状态与遗忘风险、计划重算、provider 生产运营 | 用户能在某个课程节点或练习单元中完成具体互动练习，并产出可交接的练习结果摘要 | `CAP-CONTENT`; `CAP-PLAN`; `CAP-TRAIN`; `CAP-COACH`; `CAP-MEMORY`; `CAP-NOTE`; `CAP-COM`; `CAP-SETTING` | `PRACTICE` | 迁入旧 `voice-scenario-practice`、`listening-shadowing` 和 `expression-practice-queue` 的具体练习互动部分 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-PRACTICE` | `CAP-PRACTICE-01` | 课程内专项练习 | 课程内容节点内的听写、跟读、文本输入、录音作答、播放、提交和练习结果摘要 | 课程总练习入口、课程内容编排、课程资产维护、计划训练项顺序、反馈信号生成和评分解释 | 用户进入包含专项练习节点的课程内容 | 课程节点内专项练习的互动状态和结果摘要 | `FR-PRACTICE` | Active v2 |
| `CAP-PRACTICE` | `CAP-PRACTICE-02` | 题型化巩固练习 | 针对训练对象或练习单元完成填空、听写、选择、变形选择、重复对话等训练或测试互动，并记录练习结果 | 训练对象/训练流生产、daily plan 生成、练习单元状态、反馈信号生成、学习证据接受和掌握状态与遗忘风险 | `CAP-CONTENT-03` 训练对象或练习单元被课程、训练、复习或用户主动练习引用 | 题型化练习的互动状态、作答记录和结果摘要 | `FR-PRACTICE` | Active v2 |
| `CAP-PRACTICE` | `CAP-PRACTICE-03` | AI 对话练习 | 类聊天界面的文本/语音对话练习、AI 回合回复、上下文连续互动、用户输入提交和对话练习结果摘要 | LLM provider 运维、练习单元顺序、最终评分规则、学习证据接受、掌握状态与遗忘风险、计划重算 | 用户从练习单元、场景内容或主动入口进入 AI 对话练习 | AI 对话练习状态、对话记录和结果摘要 | `FR-PRACTICE` | Active v2 |

## CAP-TRAIN - 技能训练编排与自动化

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-TRAIN` | `skill-training-automation` | 技能训练编排与自动化 | 训练编排能力 | Product Manager | Active v2 | 计划训练项承接、训练会话控制、练习单元节奏、练习单元状态、训练进度与结果交接、训练闭环展示状态 | 目标业务定义、daily plan 生成、计划版本与重算、训练对象/练习单元/训练流资产生产、具体作答运行、反馈信号生成、通知触达渠道、商业权益、学习证据接受、掌握状态与遗忘风险 | 用户能被系统持续带练并推进技能自动化 | `CAP-INTENT`; `CAP-PLAN`; `CAP-CONTENT`; `CAP-PRACTICE`; `CAP-COACH`; `CAP-MEMORY`; `CAP-ENGAGE` | `TRAIN` | 迁入旧 `expression-automation-training`、旧 `expression-practice-queue` 队列部分和旧 `goal-driven-learning-autopilot` 自动带练部分 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-TRAIN` | `CAP-TRAIN-01` | 计划训练项承接 | 从 daily plan 接收计划训练项，校验训练对象引用、训练流引用、计划版本、预期时长、完成规则和计划来源；生成可进入训练会话的入口 | daily plan 生成、训练对象生产、训练流生产、计划版本重算 | daily plan 可用 | 可进入训练会话的计划训练项入口 | `FR-TRAIN` | Active v2 |
| `CAP-TRAIN` | `CAP-TRAIN-02` | 训练会话控制 | 创建、继续、恢复、暂停和结束训练会话；维护训练会话状态、当前计划训练项、当前训练流位置和当前练习单元游标 | 练习输入与提交的具体运行、AI 对话 turn 内容生成、课程学习界面 | 计划训练项可执行 | 训练会话状态、当前计划训练项、当前训练流位置和当前练习单元游标 | `FR-TRAIN` | Active v2 |
| `CAP-TRAIN` | `CAP-TRAIN-03` | 练习单元节奏 | 根据训练流、练习单元状态、练习结果和反馈信号，控制继续、重做、跳过、降级、升级、fallback、疲劳保护和训练内复练节奏 | 训练流生成、反馈信号生成、provider 调用细节、学习证据接受、掌握状态与遗忘风险 | 训练会话进行中且存在练习单元状态 | 练习单元节奏状态 | `FR-TRAIN` | Active v2 |
| `CAP-TRAIN` | `CAP-TRAIN-04` | 练习单元状态 | 记录练习单元的未开始、进行中、完成、跳过、中断和失败状态；按计划训练项完成规则汇总为未开始、进行中、部分完成、完成、跳过、中断或失败 | 单次练习详情、录音详情、评分解释、学习证据接受规则 | 练习单元开始或状态变化 | 练习单元状态和计划训练项状态汇总 | `FR-TRAIN` | Active v2 |
| `CAP-TRAIN` | `CAP-TRAIN-05` | 训练进度与结果交接 | 汇总计划训练项、训练会话、练习单元状态、练习结果摘要和反馈信号，向 `CAP-MEMORY` 交学习证据候选，向 `CAP-PLAN` 交 completed / partial / skipped / interrupted / stale / replan-needed 信号 | 学习证据接受、掌握状态与遗忘风险、计划版本生成、复习调度策略 | 训练会话产生练习结果摘要或反馈信号 | 学习证据候选交接、completed / partial / skipped / interrupted / stale / replan-needed 信号 | `FR-TRAIN` | Active v2 |
| `CAP-TRAIN` | `CAP-TRAIN-06` | 训练闭环展示状态 | 向用户展示训练会话完成情况、计划训练项进度、卡点、已跳过内容、可恢复状态和下一步处理状态 | 反馈文案生成、评估解释、复盘与学习报告、目标达成预测 | 训练会话运行后或可恢复状态出现 | 用户可见训练闭环展示状态 | `FR-TRAIN` | Active v2 |

## CAP-COACH - AI 教练、反馈与评估

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-COACH` | `ai-coach-feedback-assessment` | AI 教练、反馈与评估 | 反馈评估能力 | Product Manager | Active v2 | 训练反馈总结、练习纠错建议、评分信号、评估解释、反馈信号交接 | provider 接入、成本观测、数据保留删除、练习单元节奏、训练会话状态、计划版本生成、商业权益判定、用户支持服务工单、学习证据接受、掌握状态与遗忘风险 | 用户获得可理解、可执行、可追踪的反馈与评估 | `CAP-PRACTICE`; `CAP-TRAIN`; `CAP-MEMORY`; `CAP-LEVEL`; `CAP-COM`; `CAP-SUPPORT` | `COACH` | 迁入旧 `scoring-feedback`；旧 `ai-provider-operations` 仅保留为运营支撑映射 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-COACH` | `CAP-COACH-01` | 训练反馈总结 | 面向计划训练项或训练会话生成用户可见训练反馈总结，汇总练习结果摘要、关键问题、表现亮点和下一步建议文本 | 练习单元节奏、训练会话状态、计划版本重算、复盘与学习报告 | 计划训练项或训练会话已有练习结果摘要或反馈信号 | 用户可见训练反馈总结 | `FR-COACH` | Active v2 |
| `CAP-COACH` | `CAP-COACH-02` | 练习纠错建议 | 针对练习互动中的用户输入给出语法、表达、词汇、发音、任务完成纠错和正确或更地道表达建议 | 练习单元状态记录、学习证据接受 | 练习互动产生用户输入且可评估 | 可执行纠错建议 | `FR-COACH` | Active v2 |
| `CAP-COACH` | `CAP-COACH-03` | 评分信号 | 针对练习互动产出发音准确度、流利度、完整度、表达质量、任务完成度等评分或等级信号 | 通过、重做、升级、降级决策、学习证据接受和掌握状态与遗忘风险 | 练习互动存在可评分输入 | 评分或等级信号 | `FR-COACH` | Active v2 |
| `CAP-COACH` | `CAP-COACH-04` | 评估解释 | 解释评分信号和纠错原因，包括 rubric、证据、扣分原因、可信度或不确定性说明 | 官方考试分数认证、当前水平画像维护 | 评分信号或纠错建议存在 | 可理解评估解释 | `FR-COACH` | Active v2 |
| `CAP-COACH` | `CAP-COACH-05` | 反馈信号交接 | 将纠错建议、评分信号、评估解释和必要建议结构化为反馈信号，交给 `CAP-TRAIN` 用于练习单元节奏，或交给 `CAP-MEMORY` 作为学习证据候选 | 练习单元节奏决策、练习单元状态判定、学习证据接受 | 纠错建议、评分信号或评估解释存在 | 可交接反馈信号 | `FR-COACH` | Active v2 |

## CAP-MEMORY - 学习事实、进度与复盘

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-MEMORY` | `learning-facts-progress-review` | 学习事实、进度与复盘 | 学习事实能力 | Product Manager | Active v2 | 学习历史时间线、学习证据接受、掌握状态与遗忘风险、学习进度解释、复盘与学习报告 | 原始练习运行、AI 对话生成、评分/纠错生成、计划版本生成、复习调度策略、官方内容资产、通知触达执行、用户主动保存的笔记/词汇/收藏 | 用户能知道自己学过什么、进展如何、哪些掌握或薄弱，以及后续计划和训练可依据哪些学习事实 | `CAP-LEVEL`; `CAP-PLAN`; `CAP-TRAIN`; `CAP-PRACTICE`; `CAP-COACH`; `CAP-NOTE`; `CAP-ENGAGE` | `MEMORY` | 迁入旧 `learning-memory-review`；旧 `goal-driven-learning-autopilot` 的学习事实和复盘依据迁入本域 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-MEMORY` | `CAP-MEMORY-01` | 学习历史时间线 | 训练会话、计划训练项、练习单元的完成/跳过/中断记录、发生时间、来源引用和可追溯链路 | 原始练习运行、AI 对话生成、反馈信号生成、原始音频长期保留策略 | 用户完成、跳过或中断训练会话、计划训练项或练习单元 | 可查询、可追溯的学习历史时间线 | `FR-MEMORY` | Active v2 |
| `CAP-MEMORY` | `CAP-MEMORY-02` | 学习证据接受 | 接受来自 `CAP-TRAIN` 和 `CAP-COACH` 的学习证据候选，记录证据类型、来源、时间、适用训练对象/练习单元、接受/拒绝状态和证据置信度 | 练习结果摘要生成、反馈信号生成、单次 AI 反馈绕过学习证据接受规则 | 训练会话产生练习结果摘要或反馈信号 | 已接受、已拒绝或待处理的学习证据 | `FR-MEMORY` | Active v2 |
| `CAP-MEMORY` | `CAP-MEMORY-03` | 掌握状态与遗忘风险 | 基于已接受学习证据和可记忆跟踪的 `CAP-NOTE` 个人资产引用，维护学习对象、词汇、表达和笔记资产的掌握状态、薄弱状态、复现证据、遗忘风险、复习到期事实和状态置信度 | 评分/纠错生成、当前水平画像维护、复习调度策略、计划版本生成 | 已接受学习证据或可记忆跟踪的个人资产引用存在 | 可追踪的掌握状态、遗忘风险和复习到期事实 | `FR-MEMORY` | Active v2 |
| `CAP-MEMORY` | `CAP-MEMORY-04` | 学习进度解释 | 解释实际完成、进度口径、证据来源、状态变化原因和当前学习沉淀 | 目标差距映射、达标预测、计划重算、官方分数认证 | 学习历史时间线或已接受学习证据存在 | 可解释学习事实进度和变化原因 | `FR-MEMORY` | Active v2 |
| `CAP-MEMORY` | `CAP-MEMORY-05` | 复盘与学习报告 | 每日学习总结卡、单次练习复盘、阶段复盘、学习报告视图/入口和可追溯依据 | 评分/纠错内容生成、课程资产维护、计划版本生成、通知渠道执行 | 学习历史时间线、已接受学习证据或掌握状态存在 | 用户可见复盘、总结卡和学习报告入口 | `FR-MEMORY` | Active v2 |

## CAP-NOTE - 笔记、词汇与个人素材

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-NOTE` | `notebook-vocabulary-assets` | 笔记、词汇与个人素材 | 个人资产能力 | Product Manager | Active v2 | 用户保存的词汇、短语、句型、笔记、收藏和个人学习素材整理 | 官方课程库、完整掌握度模型、AI provider 媒体生命周期 | 用户能沉淀和复用自己的语言素材 | `CAP-CONTENT`; `CAP-MEMORY`; `CAP-PRACTICE` | `NOTE` | 迁入旧 `notebook-vocabulary` 和旧场景练习中的个人表达沉淀 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-NOTE` | `CAP-NOTE-01` | 词汇本 | 单词、短语、释义、来源 | 官方课程内容治理 | 用户收藏或新增词句 | 个人词汇资产；可被 `CAP-MEMORY` 建立记忆状态的个人资产引用 | `FR-NOTE` | Active v2 |
| `CAP-NOTE` | `CAP-NOTE-02` | 短语与句型 | 句型、表达模板、替换练习素材 | 训练队列编排 | 用户沉淀表达 | 可复用表达资产；可被 `CAP-MEMORY` 建立记忆状态的个人资产引用 | `FR-NOTE` | Active v2 |
| `CAP-NOTE` | `CAP-NOTE-03` | 学习笔记 | 用户备注、例句、场景标签 | 自动评分 | 用户记录学习内容 | 个人笔记条目 | `FR-NOTE` | Active v2 |
| `CAP-NOTE` | `CAP-NOTE-04` | 收藏资产 | 收藏、取消收藏、收藏页复看 | 会员权益判断 | 用户保存内容 | 收藏集合状态 | `FR-NOTE` | Active v2 |
| `CAP-NOTE` | `CAP-NOTE-05` | 个人资产管理与检索 | 标签、分类、搜索、筛选、排序、批量管理、归档/软删、资产级导入导出、个人资产复习或训练用户意图交接入口 | 复习调度、训练会话状态、掌握度模型、全量账号数据权利、官方内容管理 | 个人词汇、表达、批注、收藏或其他个人资产存在 | 可管理、可检索、可迁移并可向 `CAP-PLAN` / `CAP-TRAIN` 交接用户复用意图的个人资产 | `FR-NOTE` | Active v2 |

## CAP-COM - 会员、商业化与权益

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-COM` | `membership-commerce-entitlement` | 会员、商业化与权益 | 商业能力 | Product Manager | Active v2 | 会员计划、购买入口、权益判定、订阅权益状态、商业 access gate | 学习价值能力本体、个人资料管理、交易记录、支付尝试/失败处理、退款请求、账单凭证、账单争议服务、provider 运营成本 | 用户能理解、购买、恢复并使用对应权益 | `CAP-ACC`; `CAP-CONTENT`; `CAP-PRACTICE`; `CAP-COACH`; `CAP-ENGAGE`; `CAP-BILLING`; `CAP-SUPPORT` | `COM` | 迁入旧 `commercial-subscription` 的会员方案、权益和商业门禁部分，以及旧 `profile-membership` 的会员部分 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-COM` | `CAP-COM-01` | 会员计划 | 会员方案、权益文案、价格展示 | 学习价值能力实现 | 用户进入商业入口 | 可理解会员计划 | `FR-COM` | Active v2 |
| `CAP-COM` | `CAP-COM-02` | 购买入口 | 会员购买、恢复购买和订阅管理入口；将支付尝试交接给账单能力 | 支付 provider 内部实现、支付尝试状态、交易记录、退款请求处理 | 用户选择会员付费或管理订阅动作 | 商业入口状态和可交接支付意图 | `FR-COM` | Active v2 |
| `CAP-COM` | `CAP-COM-03` | 权益判定 | 功能 access、额度、商业 gate 判定 | 前端本地最终事实 | 用户访问受限能力 | 可追踪权益结果 | `FR-COM` | Active v2 |
| `CAP-COM` | `CAP-COM-04` | 订阅权益状态 | 当前会员计划、过期、宽限、退款或撤销后的权益状态、恢复后的权益状态 | 订单明细、支付流水、收据、退款申请处理、账号基础资料 | 支付、订阅或账单状态影响权益时 | 可见订阅权益状态 | `FR-COM` | Active v2 |
| `CAP-COM` | `CAP-COM-05` | 商业 access gate | 付费墙、用量限制、升级提示、降级体验 | 训练内容本体 | 用户触达商业限制 | 合规商业门禁体验 | `FR-COM` | Active v2 |

## CAP-ENGAGE - 参与、通知与留存

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-ENGAGE` | `engagement-notification-retention` | 参与、通知与留存 | 留存触达能力 | Product Manager | Active v2 | 学习提醒、触达偏好、连续学习激励、召回、活动入口、留存节奏 | 学习计划本体、目标业务定义、商业权益判定、账号隐私设置、通用 App 设置、语言/音频偏好 | 用户能被合规提醒和召回，维持学习连续性 | `CAP-INTENT`; `CAP-PLAN`; `CAP-TRAIN`; `CAP-MEMORY`; `CAP-ACC`; `CAP-COM`; `CAP-SETTING` | `ENGAGE` | 无直接旧顶层 slug；旧 onboarding、profile 或 membership journey 中的触达和回流片段迁入本域 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-ENGAGE` | `CAP-ENGAGE-01` | 触达偏好 | 用户对提醒、push、邮件、活动的偏好 | 隐私政策文本本体 | 用户配置触达方式 | 可用触达偏好 | `FR-ENGAGE` | Active v2 |
| `CAP-ENGAGE` | `CAP-ENGAGE-02` | 学习提醒 | 到期复习、计划提醒、目标提醒 | 学习计划生成、复习调度策略 | 存在计划或复习任务 | 可发送或展示的提醒 | `FR-ENGAGE` | Active v2 |
| `CAP-ENGAGE` | `CAP-ENGAGE-03` | 连续学习激励 | streak、连续学习反馈、轻量激励 | 排行榜或社区竞争 | 用户有连续学习行为 | 连续学习状态 | `FR-ENGAGE` | Active v2 |
| `CAP-ENGAGE` | `CAP-ENGAGE-04` | 召回 | 流失风险、回流入口、恢复学习上下文 | 商业营销策略细节 | 用户中断学习 | 可恢复学习入口 | `FR-ENGAGE` | Active v2 |
| `CAP-ENGAGE` | `CAP-ENGAGE-05` | 活动入口 | 运营活动、学习挑战、限时入口 | 课程内容生产 | 活动被产品批准 | 可见活动入口和状态 | `FR-ENGAGE` | Active v2 |

## CAP-SETTING - 应用设置与体验偏好

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-SETTING` | `app-experience-settings` | 应用设置与体验偏好 | 体验配置能力 | Product Manager | Active v2 | 主题与显示偏好、App 语言与地区设置、音频与语音体验偏好、本地数据与存储偏好 | 账号身份资料、隐私授权、学习目标与反馈偏好、学习计划、通知触达策略、练习会话运行、商业权益、用户支持服务 | 用户能按个人习惯配置 App 使用体验，并让设置状态与账号、练习和触达边界保持清晰 | `CAP-ACC`; `CAP-PRACTICE`; `CAP-ENGAGE` | `SETTING` | 无直接旧顶层 slug；旧 `profile-membership` 中主题和体验偏好片段迁入本域 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-SETTING` | `CAP-SETTING-01` | 主题与显示设置 | 浅色/深色/跟随系统、显示密度、通用展示偏好 | 账号资料、会员权益、学习内容排序 | 用户进入应用设置或体验偏好上下文 | 可保存的显示体验偏好 | `FR-SETTING` | Active v2 |
| `CAP-SETTING` | `CAP-SETTING-02` | 语言与地区设置 | App 显示语言、地区格式、界面语言切换 | 学习目标语言、学习内容偏好、官方内容翻译 | 用户需要调整界面语言或地区格式 | 可保存的语言与地区偏好 | `FR-SETTING` | Active v2 |
| `CAP-SETTING` | `CAP-SETTING-03` | 音频与语音体验偏好 | 播放速度、默认语音/口音偏好、TTS 播放、自动播放、语音输入默认方式 | 麦克风权限授权、练习互动流程、AI 评分、学习形式与反馈偏好 | 用户需要调整音频播放或语音输入体验 | 可被练习界面读取的体验偏好 | `FR-SETTING` | Active v2 |
| `CAP-SETTING` | `CAP-SETTING-04` | 本地数据与存储偏好 | WiFi 下载限制、自动缓存、本地缓存清理、离线资源存储偏好 | 个人数据导出、账号删除、隐私授权、官方内容资产管理 | 用户进入存储或数据使用设置 | 本地数据与存储偏好状态 | `FR-SETTING` | Active v2 |

## CAP-SUPPORT - 用户支持、反馈与服务

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-SUPPORT` | `user-support-feedback-service` | 用户支持、反馈与服务 | 用户服务能力 | Product Manager | Active v2 | 帮助中心、自助指南、问题反馈、内容错误反馈、AI 质量反馈、客服咨询、工单状态、申诉与争议入口 | 产品功能实现、账号安全判定、数据权利处理、会员权益规则、支付/退款事实、AI 评分规则、内容资产维护 | 用户遇到问题时能获得帮助、提交反馈、联系服务或进入人工处理路径 | `CAP-ACC`; `CAP-CONTENT`; `CAP-COACH`; `CAP-COM`; `CAP-BILLING` | `SUPPORT` | 无直接旧顶层 slug；旧范围未承诺帮助反馈或客服闭环，后续 Story/Slice 需单独创建 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-SUPPORT` | `CAP-SUPPORT-01` | 帮助中心与自助指南 | FAQ、使用指南、帮助分类、帮助内容搜索、自助排障入口 | 产品功能实现、需求优先级、发布承诺 | 用户遇到使用问题并进入帮助上下文 | 可浏览和检索的帮助内容入口 | `FR-SUPPORT` | Active v2 |
| `CAP-SUPPORT` | `CAP-SUPPORT-02` | 问题反馈与质量反馈 | 产品建议、Bug 反馈、内容错误反馈、AI 回答质量反馈入口和反馈记录 | Bug 修复流程、内容资产改写、AI 评分规则调整 | 用户发现问题或想提交建议 | 可追踪的用户反馈记录 | `FR-SUPPORT` | Active v2 |
| `CAP-SUPPORT` | `CAP-SUPPORT-03` | 客服咨询与工单沟通 | 在线客服入口、邮件支持入口、工单入口、客服历史和工单状态 | 客服后台排班、领域问题最终判定、支付 provider 处理 | 用户需要人工服务或查看服务记录 | 客服沟通入口和服务状态 | `FR-SUPPORT` | Active v2 |
| `CAP-SUPPORT` | `CAP-SUPPORT-04` | 申诉与争议入口 | 账号异常申诉、内容投诉、AI 评估争议、会员权益争议入口和处理状态 | 账号风控判定、退款审批、权益规则、AI rubric、内容治理结论 | 用户需要对异常、投诉或评估/权益争议发起人工处理 | 可追踪的申诉或争议处理状态 | `FR-SUPPORT` | Active v2 |

## CAP-BILLING - 账单与支付服务

### Capability

| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-BILLING` | `billing-payment-service` | 账单与支付服务 | 商业交易服务能力 | Product Manager | Active v2 | 订单与交易记录、支付尝试状态、支付异常处理、退款请求、账单争议、收据与账单凭证 | 会员计划、权益判定、商业 access gate、账号身份验证、通用客服会话、支付 provider 内部实现 | 用户能查看和处理交易、支付异常、退款和账单凭证问题，同时不混淆会员权益判定 | `CAP-ACC`; `CAP-COM`; `CAP-SUPPORT` | `BILLING` | 迁入旧 `commercial-subscription` 的订单、支付异常、退款和账单支持边界 |

### Level-1 Sub-capabilities

| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-BILLING` | `CAP-BILLING-01` | 订单与交易记录 | 历史订单、商品、金额、渠道、交易时间、交易状态、收据引用 | 会员计划定义、权益判定、支付 provider 内部流水 | 用户存在购买、恢复购买或退款相关事实 | 可查询的订单与交易记录 | `FR-BILLING` | Active v2 |
| `CAP-BILLING` | `CAP-BILLING-02` | 支付尝试与异常处理 | 支付尝试状态、支付失败说明、重试入口、provider 跳转或恢复路径 | 会员权益授予、provider 内部实现、前端本地最终支付事实 | 用户发起购买、恢复购买或支付重试 | 支付尝试结果或可恢复异常状态 | `FR-BILLING` | Active v2 |
| `CAP-BILLING` | `CAP-BILLING-03` | 退款请求与账单争议 | 退款申请入口、退款状态、账单争议入口、外部商店处理路径说明 | 会员权益判定、通用客服会话、支付 provider 审批规则 | 用户需要退款、查看退款状态或处理账单争议 | 可追踪的退款或账单争议状态 | `FR-BILLING` | Active v2 |
| `CAP-BILLING` | `CAP-BILLING-04` | 账单凭证与收据支持 | 订单凭证、收据查看、账单证明或发票类入口状态 | 税务 provider 内部实现、会员方案、账号身份验证 | 用户需要交易凭证或账单证明 | 可见账单凭证或收据支持状态 | `FR-BILLING` | Active v2 |

## Legacy Mapping

| V1 slug | V2 mapping | Migration note |
| --- | --- | --- |
| `access-onboarding` | `CAP-ACC`, `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-ENGAGE` | 旧 onboarding 是用户旅程，不再作为顶层 capability；账号进入、当前水平、初始目标偏好、初始计划和触达分别映射。 |
| `official-scenario-library` | `CAP-CONTENT` | 官方场景资产迁入官方内容库与目录结构、内容条目与课程定义；等级、标签、素材摘要和活动规划作为内容条目字段或下游 requirement 展开，不再作为独立子能力。 |
| `listening-shadowing` | `CAP-PRACTICE`, `CAP-COACH` | 跟读和听写互动映射到课程内专项练习；完整度、发音等反馈映射到 AI 教练与评估。 |
| `expression-practice-queue` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE`, `CAP-MEMORY` | 可复用训练对象、练习单元和训练流资产映射到 content；计划训练项交接和复习调度映射到 plan；训练会话控制、练习单元节奏和状态映射到 train；具体练习互动映射到 practice；学习证据映射到 memory。 |
| `voice-scenario-practice` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-COACH` | AI 对话和语音会话互动映射到 practice；场景素材映射到内容；反馈映射到 AI 教练。 |
| `expression-automation-training` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE`, `CAP-MEMORY` | 计划训练项来源和复习安排映射到 plan；训练会话控制、练习单元节奏、状态和结果交接作为 `CAP-TRAIN` 主边界；具体练习互动和学习证据分别映射到 practice 与 memory。 |
| `goal-driven-learning-autopilot` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` | 当前水平、目标偏好、计划版本、自动带练和学习事实拆分到对应稳定业务能力。 |
| `learning-memory-review` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-NOTE` | 学习事实和复盘映射到 memory；复习与记忆调度映射到 plan；个人素材沉淀映射到 note。 |
| `scoring-feedback` | `CAP-COACH`, `CAP-LEVEL`, `CAP-MEMORY` | 评分和反馈归 `CAP-COACH`；可用于当前水平画像的证据归 `CAP-LEVEL`；学习证据接受、掌握状态与遗忘风险归 `CAP-MEMORY`。 |
| `server-backed-learning-foundation` | Architecture/SWC/Domain support for `CAP-*` | 不再作为业务 capability；旧引用保留为服务端事实、API、DB、发布证据支撑。 |
| `ai-provider-operations` | AI runtime / provider / ops support for `CAP-COACH`, `CAP-PRACTICE`, `CAP-TRAIN` | 不再作为业务 capability；旧引用保留为 provider、媒体、成本、保留删除和发布门禁支撑。 |
| `notebook-vocabulary` | `CAP-NOTE`, `CAP-MEMORY` | 个人词句和笔记归 `CAP-NOTE`；学习复习事实归 `CAP-MEMORY`。 |
| `profile-membership` | `CAP-ACC`, `CAP-COM`, `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY`, `CAP-ENGAGE`, `CAP-SETTING` | 个人资料、会员入口、水平/目标/计划概览、学习事实概览、提醒设置和主题/体验偏好拆分到对应能力。 |
| `commercial-subscription` | `CAP-COM`, `CAP-BILLING` | 会员方案、权益和商业门禁归 `CAP-COM`；订单、支付异常、退款和账单支持归 `CAP-BILLING`。 |
