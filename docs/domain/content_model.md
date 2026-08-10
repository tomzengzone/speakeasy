# 内容领域模型

## 状态与权威来源

- Artifact ID：`DOMAIN_MODEL`（`content` 专项）
- 状态：已批准 `Content 001/002` 交付的拟议候选
- 负责 Agent：`domain_schema`
- 领域所有者：内容/场景限界上下文
- 后端所有者：`BE-CONTENT-SCENARIO`
- 持久化所有者：`DB-IDENTITY-CONTENT`

规范产品输入仅为已批准的 `VS-CONTENT-001-1`、`VS-CONTENT-002-1`、`FR-CONTENT-001` 和 `FR-CONTENT-002`。工程上下文为 ADR 0008 和已验收的 PR-001 架构基线。`docs/domain/domain_schema.md` 与 `docs/domain/entity_relationship.md` 分别提供配套的领域概要和关系视图。

Task Plan 只授权执行本契约，不是 authored content 权威来源。具体而言，计划中的 `seed`、示例数量或拟议映射都不是课程库存的事实源。本模型只支持后续由 owning approved product/content source 授权的库存。PR-005 写入初始 authored data 前必须存在该 canonical content authority；本文不列出或承诺课程数量、标题、时长或 CEFR 覆盖。

## 范围边界

本模型只定义已批准 `Content 001/002` 所需的稳定身份、authored snapshot、发布、绑定、持久化和读取解析事实。

- `Course != Scenario`。
- `Scenario` 继续表示官方主题身份。
- `ScenarioVersion` 继续表示经过审核的场景内容版本。
- `ScenarioLevel` 继续表示一个 `Scenario` 的单一 CEFR 内容轨道；不得删除、重命名、复制或将其用作 `Course`/`CourseVersion` 别名。
- `CefrLevel` 仅允许 `A1`、`A2`、`B1`、`B2`、`C1`、`C2`；这不改变 mastery `L0-L5` 或 hint `L1-L4`。
- `US-CONTENT-003` 至 `US-CONTENT-012` 仅为兼容性边界。本模型不为它们创建 stage、progress、session、turn、AI、media、evidence、scoring、playback 或 learner runtime 实体/字段。
- 通用 CMS、内容创作工作流、审批角色模型、批量发布系统和具体库存不在范围内。

## 所有权与事实分类

| 事实 | 所有者 | 规则 |
| --- | --- | --- |
| `Course` 身份、`Scenario` 归属、`slug` 和目录排序 | 内容领域 / `BE-CONTENT-SCENARIO` | 通过 `DB-IDENTITY-CONTENT` 持久化的 authored Content 事实，不是用户事实。 |
| `CourseVersion` authored snapshot 与发布生命周期 | 内容领域 / `BE-CONTENT-SCENARIO` | 发布是 Content 事实；已发布的 authored snapshot 不可变。 |
| `CourseContentBinding` | 内容领域 / `BE-CONTENT-SCENARIO` | 指向现有 `Scenario` 内容的稳定 authored 关联；已发布 binding 不可变。 |
| 当前学习者可见性 | 服务端 Content 读取投影 | 可以消费 entitlement decision；不得在 `Course`、`CourseVersion` 或 binding 中保存 per-user visibility 和 entitlement truth。 |
| `ScenarioVersion` 与 `ScenarioLevel` | 既有内容/场景所有者 | 通过稳定引用复用；`Course` 不复制或改变其含义。 |
| 运行时 session/progress/evidence/AI/media/scoring 事实 | 既有 Practice、Training、Learning、AI 和 Media 所有者 | 只有适用契约获批后，这些所有者才能引用 `Course`；Content 不吸收其事实。 |

## 值对象

### `CefrLevel`

合法值严格为 `A1`、`A2`、`B1`、`B2`、`C1`、`C2`。Legacy `L1`、`L2`、`L3`，mastery `L0-L5` 与 hint `L1-L4` 属于不同命名空间，均不是合法的课程 CEFR 值。

### `Duration`

`Duration` 由 `duration_value` 和 `duration_unit` 组成。

- `duration_value` 必须大于零。
- `duration_unit` 必须非 null，并且 `trim` 后非空。
- 本领域契约不选择 API 序列化形式，也不把单位限制为未经批准的枚举；后续 API Contract 必须保持“数值 + 单位”不变量。

## 实体

### `Course`

| 属性 | 契约 |
| --- | --- |
| 所有者 | 内容/场景领域；`BE-CONTENT-SCENARIO` |
| 稳定身份 | `course_id`：应用生成的 UUID，不可变且不得从展示文本推导 |
| 字段 | `course_id`、`scenario_id`、`slug`、`sort_order`、`created_at`、`updated_at` |
| 场景归属 | `scenario_id` 非 null 且不可变；每个 `Course` 恰好属于一个 `Scenario` |
| Slug | 非 null、`trim` 后非空、唯一且不可变的稳定查找键；持久化/API 实现必须采用单一且确定的标准化和大小写策略 |
| 排序 | 非负、持久化且由 Content 拥有的目录顺序；在一个 `Scenario` 内唯一，且绝不从 per-user 状态计算。如果未来获准变更，它必须是显式 Content 排序事务，而不是 `CourseVersion` 变更 |
| 发布 | `Course` 没有独立的 published 标记。目录资格由精确的当前 published `CourseVersion` 和当前学习者可见性投影共同派生 |
| 删除 | 本文不定义硬删除/退役工作流。被引用的 authored Course 身份必须保留；账号删除不影响它 |

`Course` 生命周期面向身份：

```text
registered -> versioned
```

- `registered` 表示稳定 `Course` 身份和 `Scenario` 归属已经存在。
- `versioned` 表示至少存在一组 `CourseVersion`/binding。
- 两种状态都不会自动使 `Course` 对学习者可见。可见性是 publication 与可选 entitlement decision 形成的读取投影。

### `CourseVersion`

| 属性 | 契约 |
| --- | --- |
| 所有者 | 内容/场景领域；`BE-CONTENT-SCENARIO` |
| 稳定身份 | `course_version_id`：应用生成的 UUID，不可变 |
| 父实体 | `course_id` 非 null；每个 `CourseVersion` 恰好属于一个 `Course` |
| 字段 | `course_version_id`、`course_id`、`version_key`、`title_en`、`summary_zh`、`cefr_level`、`duration_value`、`duration_unit`、`background_asset_ref`、`publication_status`、`published_at`、`superseded_at`、`created_at`、`updated_at` |
| 版本键 | `version_key` 是稳定字符串，必须非 null、`trim` 后非空，并在一个 `Course` 内唯一；不得从时间戳或展示文案推导，发布后不可变 |
| Authored snapshot | `title_en` 与 `summary_zh` 必须 `trim` 后非空；`cefr_level` 必须是一个合法 `CefrLevel`；`Duration` 必须有效；`background_asset_ref` 可以为 null |
| 可选背景 | `background_asset_ref` 为 null 或不可用时，不得阻止发布或读取全部必备课程信息；媒体降级行为属于后续 API/Screen 契约 |
| 当前发布 | 每个 `Course` 同一时刻至多有一个 `publication_status = published` 的 `CourseVersion` |
| 不可变性 | 首次转换为 `published` 后，身份、父实体、`version_key`、全部 authored snapshot 字段和 `CourseContentBinding` 都不可变；只有发布生命周期元数据可以转为 `superseded` |
| 删除 | 已发布或已 superseded 的版本及其 binding 必须保留，以保证稳定引用和安全回滚；账号删除不影响它们 |

生命周期：

```text
draft -> published -> superseded
```

- 只有字段、binding、Scenario 和 CEFR 的全部不变量在一个 Content 事务内通过后，才允许 `draft -> published`。
- 发布新的当前版本时，如存在先前的当前 `published` 版本，必须在同一事务中把它转为 `superseded` 并发布候选版本。替换后事务不得以零个或两个当前 published 版本提交。
- 本契约禁止 `draft -> superseded`、`superseded -> published`、publication 回滚为 `draft`，以及首次发布后的 authored mutation。
- 目录只读取当前 `published` 版本。对 draft、superseded、缺失或其他不可用版本的精确详情读取必须返回类型化结果，不得替换为 `latest` 或其他版本。

### `CourseContentBinding`

| 属性 | 契约 |
| --- | --- |
| 所有者 | 内容/场景领域；`BE-CONTENT-SCENARIO` |
| 稳定身份 | `course_content_binding_id`：应用生成的 UUID，不可变 |
| 字段 | `course_content_binding_id`、`course_version_id`、`scenario_version_id`、`scenario_level_id`、`created_at`、`updated_at` |
| 基数 | 每个已提交的 `CourseVersion` 恰好有一个 binding；每个 binding 恰好属于一个 `CourseVersion`，并且恰好引用一个 `ScenarioVersion` 和一个 `ScenarioLevel` |
| Scenario 一致性 | `Course.scenario_id = ScenarioVersion.scenario_id = ScenarioLevel.scenario_id` |
| CEFR 一致性 | `CourseVersion.cefr_level = ScenarioLevel.level_code = ScenarioLevel.target_level` |
| 不可变性 | 只有在保持恰好一个 binding 的前提下，draft binding 才能通过经过校验的 Content 事务替换；首次发布时 binding 永久冻结 |
| 失败规则 | 引用缺失、多个 binding、Scenario 不一致或 CEFR 不一致时，必须返回类型化领域结果并回滚；resolver 不得选择其他 `Course`、`CourseVersion`、`ScenarioVersion` 或 `ScenarioLevel` |
| 删除 | binding 与其 `CourseVersion` 一起保留；账号删除不影响它 |

Binding 生命周期由其 `CourseVersion` 派生：

```text
attached_to_draft -> frozen_on_publication -> retained_with_superseded_version
```

## 关系与基数

| 起点 | 关系 | 终点 | 基数 | 不变量 |
| --- | --- | --- | --- | --- |
| `Scenario` | 归组 | `Course` | 1 -> 0..many | 每个 `Course` 恰好指向一个现有 `Scenario`。 |
| `Course` | 拥有 | `CourseVersion` | 1 -> 0..many | 每个 `CourseVersion` 恰好拥有一个 `Course`；`(course_id, version_key)` 唯一且版本键非空。 |
| `CourseVersion` | 拥有 | `CourseContentBinding` | 1 -> 1 | 在 aggregate 边界内原子创建；任何已提交的孤立版本均无效。 |
| `CourseContentBinding` | 引用 | `ScenarioVersion` | many -> 1 | 被引用的 `ScenarioVersion` 必须属于 `Course` 所属的 `Scenario`。 |
| `CourseContentBinding` | 指向 | `ScenarioLevel` | many -> 1 | 被引用的 `ScenarioLevel` 必须属于同一 `Scenario`，并与 `CourseVersion` 具有相同 CEFR。 |

Binding 是关联实体，不是第二种内容版本、可见性记录或运行时 aggregate。

## Aggregate 不变量与事务

### 创建 `Course` 身份

- 分配稳定 UUID，并持久化有效且唯一的 `slug`、`Scenario` 引用和非负的 per-Scenario `sort_order`。
- 不得从现有 `ScenarioLevel` 推导 `Course`，也不得仅因为 Task Plan 包含一条 `seed` 而创建 `Course`。

### 创建或修订 draft `CourseVersion`

- 原子提交 `CourseVersion` 和恰好一个 binding。
- 校验所有必备 snapshot 字段、一个合法 `CefrLevel`、正值 `Duration` 和所有被引用的行。
- 提交前校验跨行 Scenario 与 CEFR 等式。
- 替换 draft binding 时，不得暴露已经提交的零 binding 或多个 binding 状态。

### 发布 `CourseVersion`

- 在一个事务边界内重新读取 `Course`、候选 `CourseVersion`、binding、`ScenarioVersion` 和 `ScenarioLevel`。
- 拒绝过期/缺失引用、无效字段、binding 基数冲突、Scenario 不一致或 CEFR 不一致。
- 绑定的 `ScenarioVersion` 必须按现有 Content owner 规则处于可发布读取状态。不可用时返回 `bound_content_unavailable`、回滚，并且不得选择其他 `ScenarioVersion`、`CourseVersion` 或 level。
- 如果存在当前 published 版本，必须在保持每个 `Course` 至多一个当前 published 版本的前提下，原子 supersede 旧版本并发布候选版本。
- 首次发布时冻结 authored snapshot 和 binding。
- 发布失败时，先前的 published 版本和全部 binding 事实保持不变。

### 解析目录与精确详情

- 目录投影从已发布主题和当前 published `CourseVersion` 事实开始；适用时再应用当前学习者可见性 decision。
- 即使投影中包含零个课程摘要，已发布主题仍必须保留在结果中。
- 课程摘要携带稳定 `course_id` 和精确 `course_version_id`；后续详情解析必须同时使用这两个身份。
- 详情解析必须返回请求的精确 published 版本及其经过校验的 binding；不得选择 `latest`、相邻 CEFR、其他 `ScenarioLevel` 或其他 `Course`。
- 空目录、不可见/不可用精确版本与依赖/基础设施失败必须保持不同结果类别。

## 类型化领域结果

以下是供后续 API 映射使用的语义结果类别，不是 endpoint error code 定义。

| 结果 | 含义 | 必需行为 |
| --- | --- | --- |
| `course_not_found` | 稳定 `Course` 身份无法解析 | 失败；不得替换。 |
| `course_version_not_found` | 精确版本身份不属于该 `Course` | 失败；不得回退到 `latest`。 |
| `course_version_not_published` | 精确版本为 draft、superseded 或因其他原因无法用于已批准读取 | 失败；在安全诊断中保留请求的身份。 |
| `course_not_visible` | publication 存在，但当前学习者读取投影拒绝访问 | Fail closed；外部映射不得泄漏受保护资源是否存在。 |
| `binding_missing` | 精确 `CourseVersion` 没有已提交 binding | 失败，并视为契约/数据完整性错误。 |
| `binding_cardinality_violation` | 一个 `CourseVersion` 出现多个 binding | 失败，并视为契约/数据完整性错误。 |
| `binding_scenario_mismatch` | `Course`、`ScenarioVersion` 与 `ScenarioLevel` 不属于同一 `Scenario` | 事务/读取失败；不得选择替代项。 |
| `binding_cefr_mismatch` | `CourseVersion` CEFR 与 `ScenarioLevel` CEFR 字段不一致 | 事务/读取失败；不得选择相邻等级。 |
| `bound_content_unavailable` | 被引用的 `ScenarioVersion` 或 `ScenarioLevel` 按其 owner 规则不可用 | 精确解析失败；读取时不得重新绑定。 |
| `published_snapshot_immutable` | 写入尝试修改已发布 authored 字段 | 拒绝写入，且不得产生部分变更。 |
| `published_binding_immutable` | 写入尝试重新绑定已发布版本 | 拒绝写入，且不得产生部分变更。 |
| `current_published_version_conflict` | 写入会使一个 `Course` 存在多个当前 published 版本 | 拒绝或回滚发布事务。 |

API Contract 可以安全收敛外部可观察的 authorization/not-found 响应，但必须保留类型化内部结果，且绝不能把任何失败转换为其他成功的 `Course`/version/level。

## Additive 持久化契约

以下名称描述归属本领域的关系型数据组；migration 实现可以遵循仓库命名约定，但必须保持这些事实和约束。本文不包含 SQL。

### `content_course`

- 主键：UUID `course_id`。
- 非空外键：`scenario_id -> Scenario.scenario_id`；`Course` 存在时限制破坏性删除。
- 唯一/check 约束：标准化 `slug` 唯一且非空；`sort_order >= 0`；`(scenario_id, sort_order)` 唯一。
- 读取索引：`(scenario_id, sort_order, course_id)`，用于确定性主题目录排序。

### `content_course_version`

- 主键：UUID `course_version_id`。
- 非空外键：`course_id -> content_course.course_id`；限制破坏性删除。
- 唯一/check 约束：`(course_id, version_key)` 唯一；`version_key`、`title_en` 和 `summary_zh` 必须 `trim` 后非空；`cefr_level` 仅允许六个 `CefrLevel` 值；`duration_value > 0`；`duration_unit` 必须 `trim` 后非空。
- 发布 check：`published` 必须有 `published_at`；`superseded` 必须同时有 `published_at` 和 `superseded_at`；draft 不得通过时间戳伪装成 published。
- 条件唯一约束/索引：对于 `publication_status = published` 的行，每个 `course_id` 至多一行。
- 读取索引：`(course_id, publication_status)` 和 `(publication_status, course_id)`；精确读取仍使用主键并校验父实体归属。
- `background_asset_ref` 可为 null，并且不存在使它成为发布前置条件的 check。

### `content_course_content_binding`

- 主键：UUID `course_content_binding_id`。
- 非空外键：`course_version_id -> content_course_version`、`scenario_version_id -> ScenarioVersion`、`scenario_level_id -> ScenarioLevel`；对保留引用限制破坏性删除。
- 唯一约束：`course_version_id` 唯一，保证每个版本至多一个 binding。
- 读取/完整性索引：`scenario_version_id`、`scenario_level_id` 和 `(scenario_version_id, scenario_level_id)`。
- “至少一个 binding”和跨行 Scenario/CEFR 等式无法在不复制事实的前提下安全简化为基础外键；它们是事务级 Content 领域不变量，必须由 Contract-TC 证明。

核心 Course 事实必须使用普通类型化列和约束，不得用不透明 JSON 替代。时间戳提供生命周期审计能力；本契约不要求用户拥有的 author 字段，因此账号删除不会切断 authored Content 所有权。

## 迁移、灰度与回滚

- Migration 只做增加：创建三个归属本领域的持久化数据组、约束和索引，不重命名、删除、复制或双写 `Scenario`、`ScenarioVersion` 或 `ScenarioLevel`。
- 现有 Scenario/practice/training/learning 流程保持有效且不变；不得创建 legacy Course 轨道。
- 不得通过重新解释每个 `ScenarioLevel` 来合成 Course 行。只有经另一个 approved canonical content authority 授权后，才可以插入 authored 行和 binding。
- Task Plan 的拟议 `seed` 不是充分权威来源。初始 seed 值、稳定 ID 和映射必须在 PR-005 前获得 canonical 批准；在此之前，仅 schema migration 或空 Course 库存均有效。
- 经授权的回填/导入必须保留稳定 UUID 身份，并执行与正常 Content 写入相同的字段、binding、Scenario 和 CEFR 校验。
- Rollout 采用 backend-first；数据和契约就绪前可以保持新的 catalog/detail 路径关闭。
- 安全回滚关闭新的读取路径/入口并恢复现有 Scenario 流程。Additive Course 数据、published snapshot 和 binding 必须保留以供修复和后续复用；不得执行破坏性 down migration 或重新解释 `ScenarioLevel`。
- 账号删除不得删除、匿名化或重写 `Course`/`CourseVersion`/binding 行，因为其中不包含 learner-owned 或 per-user entitlement 事实。

## API Contract 交接

后续 API Contract/OpenAPI owner 必须消费而不是重新定义以下领域事实：

- catalog-to-detail 导航中的稳定 `Course` 身份和精确 `CourseVersion` 身份。
- 已发布主题和当前 published/visible 课程摘要的完整服务端投影，包括真实的零 Course 主题。
- 摘要/详情必备事实：非空英文标题、非空中文简介和一个合法 CEFR；详情还必须携带正值 `Duration` 及其非空单位。背景资产引用仍为可选。
- 精确 Course/version 解析和类型化 empty/failure 类别；不得回退到 `latest`、相邻等级或其他 `Course`。
- 服务端拥有 publication 和 visibility 编排；entitlement 只是 decision input，任何 per-user visibility 字段都不得成为 authored Course 状态。
- 除非后续 approved contract 有暴露安全引用的具体需要，否则 binding 解析保持为内部稳定引用编排。
- Authentication、authorization-safe error mapping、request/trace 传播和 generated-client drift check 归 API Contract 所有，不属于本模型。

## Contract-TC 交接

本 PR 无权修改 Test Case Artifact。在后续获授权 PR 中，`test_case_development` / Test Case Artifact owner 必须创建或更新 Contract-TC，至少证明：

1. UUID 身份稳定、Course-to-Scenario 归属正确、slug/order 唯一；`version_key` 是 `trim` 后非空的稳定字符串，在一个 `Course` 内唯一，不从时间/展示文案推导，并在发布后不可变。
2. `title_en`/`summary_zh` 非空、CEFR 为六值之一、duration 数值为正、duration 单位非空，并且背景可空。
3. 每个已提交 `CourseVersion` 恰好有一个 binding；缺失/重复 binding 必须被拒绝。
4. `Course`、`ScenarioVersion` 与 `ScenarioLevel` 属于同一 `Scenario`，且 `CourseVersion` CEFR 等于 `ScenarioLevel` 的两个 CEFR 字段；每种不一致都返回类型化失败并回滚。
5. 发布要求绑定的 `ScenarioVersion` 按现有 Content owner 规则可发布读取；内容不可用时返回 `bound_content_unavailable`、回滚，且绝不替换其他 `ScenarioVersion`、`CourseVersion` 或 level。
6. 每个 `Course` 至多一个当前 published 版本，supersede/publish 原子执行，发布失败时保留先前版本。
7. 已发布 authored snapshot 和 binding 不可变，包括拒绝 rebind 且不产生部分变更。
8. catalog/detail 精确版本解析；不可用/不可见/完整性失败均有类型化结果，且不回退到其他 Course/version/level。
9. Publication 是 Content 事实；学习者 visibility 是服务端读取投影，可以消费但不得持久化 entitlement decision。
10. Additive migration 与安全回滚保留 `ScenarioLevel` 语义、Course 数据和现有 Scenario/practice/training/learning 流程。
11. 账号删除后 authored `Course`/`CourseVersion`/binding 数据保持不变。
12. 回归证明 `ScenarioLevel` 未被重命名或复制，mastery `L0-L5` 与 hint `L1-L4` 保持不变。
13. 初始 authored data 只接受最终 canonical content authority；不得把 Task Plan 的 seed/数量/示例当作产品事实源。Schema 能承载经批准的稳定键（例如 `2026.08-v1`），但该示例本身不是 authored inventory truth。

在这些 Contract-TC Artifact 由 owner 完成并获批准前，本节只是测试设计交接，不是测试证据。

## 明确非目标

- 不定义 SQL、JPA entity/repository/service/controller、endpoint、DTO、OpenAPI schema、Flutter state 或测试实现。
- 不定义具体 Course inventory、标题、时长、CEFR 覆盖，也不承诺 A1/C1/C2 Course。
- 不定义通用 CMS、author/editor 角色、review queue、schedule 或批量发布工作流。
- 不定义 draft `US-CONTENT-003` 至 `US-CONTENT-012` 的行为或领域事实。
- 不让 Course 拥有 stage/progress/session/turn/AI/media/evidence/scoring 事实。
- 不重命名、替换、复制或双写 `ScenarioLevel`，也不提供 fallback。
