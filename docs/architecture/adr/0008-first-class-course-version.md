# ADR 0008：Content 边界内的一等 Course / CourseVersion

- Status: Accepted for candidate baseline
- Date: 2026-08-07
- Decision owner: System Architect
- Normative product input: approved `US-CONTENT-001`、`US-CONTENT-002` and applicable `FR-CONTENT-001`、`FR-CONTENT-002` only

## Context

已批准的 Content Catalog 与 Course Detail 行为需要一个可长期引用、可精确打开版本的学习者可见课程身份。现有 Scenario、ScenarioVersion 与 ScenarioLevel 已分别表达官方场景、场景内容版本和场景下的 CEFR/等级轨道；把其中任一对象重新解释为 Course 会混淆内容导航身份与场景等级语义，并使后续 practice、training、learning、AI、media runtime facts 容易回流到 Content。

当前 `US-CONTENT-003` 至 `US-CONTENT-012` 都是 draft。它们只用于提前检查架构兼容性，不能成为 endpoint、字段、状态、表、provider、验收或实现的权威输入。本架构不定义 Course inventory 的数量、标题或时长；真实库存必须来自 owning approved product/content source。已批准 001/002 只授权完整 published/visible collection 与 detail semantics，不授权具体库存，也不承诺 A1-C2 或 A1/C1/C2 覆盖。

## Decision

### Identity and content relation

- 在既有 Content / Scenario bounded context 内建立一等 `Course` 与 `CourseVersion` 架构身份，不新建独立微服务或第二套内容事实源。
- `Course` 是稳定的学习者可见课程单位；`CourseVersion` 是一个 Course 的不可变、可发布版本身份。详情读取必须绑定明确 Course/CourseVersion，版本不可用时失败，不得静默替换为 latest。
- `Course != Scenario`。`Scenario` 继续表达官方场景主题，`ScenarioVersion` 继续表达经审核的场景内容版本，`ScenarioLevel` 继续表达该场景下的 CEFR/等级轨道；`ScenarioLevel` 不得成为 Course 或 CourseVersion alias。
- 后续 `CourseContentBinding` 把一个 CourseVersion 关联到匹配的 `ScenarioVersion` 与 `ScenarioLevel`。binding 必须保持 scenario 与 level 的语义一致性，但本 ADR 不定义字段、基数、表、API payload 或迁移细节；它们由后续 Domain Model、API Contract 与 migration decision 持有。

### SWC allocation and reuse

- `FE-CONTENT` 拥有已批准 001/002 的 catalog/detail UI orchestration、稳定 identity 选择、loading、真实空内容、typed failure 与 last-known display context；它必须复用 `FE-API-CLIENT` 和 `FE-LOCAL-CACHE`。
- `BE-CONTENT-SCENARIO` 拥有 authored、published、visible Scenario/Course 事实和精确 CourseVersion resolution；可见性规则适用时，它消费 `BE-COMMERCE-ENTITLEMENT` 的 decision input，但不复制 entitlement truth。
- `DB-IDENTITY-CONTENT` 是后续已批准 additive Course/CourseVersion/CourseContentBinding persistence 的落点；当前 ADR 不创建表或 migration。
- Practice、Training、Learning、AI 与 Media owner 继续分别拥有 session/turn/attempt、planner、progress/evidence、prompt/provider、recording/transcript/score/media lifecycle。Course 只能提供或消费稳定 reference，不拥有这些 runtime facts。
- 禁止在 home、interview、training 或其他 feature 中建立重复 Course DTO/client/repository/cache/version resolver，也禁止绕过既有 backend owner、AI Gateway 或 Media Storage。

### Approved catalog and detail semantics

- catalog 返回完整可见 theme 投影；一个已发布 theme 可以真实地包含零 Course。empty 与 failure 必须分离，读取失败不得伪造成空目录。
- detail 使用稳定 Course identity 与精确 CourseVersion identity。不可见或不可用版本返回 typed failure；客户端缓存不能修改 publication、visibility 或 version truth。
- 本 ADR 只规定高层跨组件语义，不规定 endpoint、字段、UI 状态枚举、错误码、缓存期限、表或 provider。相应细节只能在已批准后由 owning Engineering Contract 定义。

### Draft-story impact check and evolution

`software_component_architecture.md` 的 Architecture Coverage Matrix 对 `US-CONTENT-003` 至 `US-CONTENT-012` 提供逐行预分类。草稿获批后，System Architect 必须先对相应行执行 local impact check。

命中以下任一条件时，必须在实现前新增 ADR 或进行 global architecture review：
- stable Course/CourseVersion identity 或 version-resolution semantics 改变；
- authored 或 runtime fact ownership 跨越 SWC；
- 出现新的 cross-SWC transaction、atomicity 或 compensation boundary；
- 引入新的 provider、storage、security 或 privacy boundary；
- 与既有 reuse rule 冲突、产生 forbidden duplicate 或绕过共享边界；
- CourseContentBinding 无法继续保持与匹配 ScenarioVersion + ScenarioLevel 的关系而不改变全局拓扑。

若一个条件都未命中，只记录 local impact check 并增加对应 Engineering Contract Artifact；不得仅因矩阵存在而把 draft Story 视为 approved authority。

## Quality attributes and operations

### Security and privacy

- backend 执行 authentication、publication 与 visibility decision；不可见 Course/version 不应通过响应差异、缓存键或日志泄漏。
- frontend 不持有 authored truth、entitlement truth、provider secret、signed storage credential 或 runtime evidence truth。
- telemetry 只记录 request/trace identity、结果类别和经脱敏的 Course/version reference，不记录 raw authored content、用户音频、transcript、score payload 或 provider secret。

### Reliability

- CourseVersion resolution 是 exact-match；禁止 silent latest fallback。
- catalog empty、unavailable version 与 infrastructure failure 是不同结果类别。last-known cache 只帮助显示和恢复，不得掩盖服务端失败或成为事实源。
- 后续读契约需支持兼容部署；旧 Scenario、practice、training 与 learning flows 在新 Course read path 不可用时仍保持原语义。

### Observability and operability

- `FE-API-CLIENT`、controller 与 `BE-CONTENT-SCENARIO` 传播 request_id/trace_id，并记录 feature area、result class、version-resolution outcome 与 visibility-decision outcome。
- dashboard/alert 的具体阈值属于后续 release/observability contract；本 ADR 只要求能够区分成功、真实空内容、不可见/不可用版本、依赖失败和缓存恢复。
- 运维排障必须可追踪 exact CourseVersion resolution，但不得通过日志复制 authored payload 或 learner runtime data。

### Deployment and rollback

- 后续实现采用 additive Domain/API/migration、backend-first compatibility、generated client 更新和 feature flag/route rollout；兼容应用版本继续使用既有 Scenario 读取语义，不建立 legacy Course 双轨；不得 dual-write 到 ScenarioLevel，也不得重解释现有 Scenario 数据。
- rollback 首选关闭新 catalog/detail read path 与入口，恢复既有 Scenario/practice/training flow；已写入的 additive Course data 保留供修复后重用，不执行破坏性 down migration。
- 如果后续写路径产生跨 SWC side effect，必须在实现前由新的 ADR/global review 定义 idempotency、compensation 与 rollback；本 ADR 不预先授权该写路径。

## Consequences

- 已批准的 catalog/detail 获得稳定、可演进且可版本锁定的内容身份，不污染 ScenarioLevel 语义。
- Content、Practice、Training、Learning、AI 与 Media 的事实所有权保持清晰，现有复用边界继续有效。
- 新增一个 proposed frontend SWC `FE-CONTENT`，并扩展既有 `BE-CONTENT-SCENARIO` 与 `DB-IDENTITY-CONTENT` 的未来责任；本次不改变代码、API、Domain Schema 或数据库。
- 未来 003-012 可逐行判断是否适配 baseline，但必须在产品批准和相应 Contract 完成后才能实施。

## Alternatives rejected or deferred

- 用 `ScenarioLevel` 作为 Course/CourseVersion alias：拒绝。它会合并不同身份语义，破坏版本锁定，并把 level 演进与课程发布耦合。
- 为 Course 建立独立内容微服务或第二套 persistence：拒绝当前采用。001/002 不需要新的网络、事务和运维边界，复用 Content / Scenario bounded context 更符合现有 modular-monolith baseline。
- 现在建立通用 CMS：deferred。内容创作工作流、审核、权限、批量发布和完整 A1-C2 库存均未获批准，需要独立产品范围与架构评审。
- 让 Course 聚合 runtime session/progress/evidence/media/AI facts：拒绝。它会跨越既有事实 owner，扩大事务与隐私边界，并破坏可独立回滚性。

## Non-goals

- 不批准或实现 `US-CONTENT-003` 至 `US-CONTENT-012`。
- 不定义 endpoint、request/response、领域字段、状态机、表、migration、provider、UI 细节或测试验收。
- 不承诺 A1-C2、A1/C1/C2 或通用 CMS，不改变现有 Practice、Training、Learning、AI、Media 或 Commerce 产品行为。
