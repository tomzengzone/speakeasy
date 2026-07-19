# ADR 0007：开发流程精简与产品事实、工程交付分离

## Status

Accepted for migration preparation（已接受用于迁移准备），尚未激活为交付流程。

计划在 PR3 完成后 supersede ADR 0001，**当前尚未 supersede**。只有 PR3 原子切换完成、全量校验对同一候选 commit 通过且新的 governance authority 被激活后，supersede 才实际生效。在 PR1 和 PR2 期间，ADR 0001、现有 `docs/process/workflow.md`、Definition of Done、Gate、Skill 以及 Product Base / Increment artifact 仍是唯一 runtime authority。

这里的 runtime authority 指 Codex、Agent、Skill、治理校验器和 CI 在开发交付时必须遵循的有效流程，不指应用程序运行时。

## Context

本决策的治理目标是**精简 AI 辅助开发流程**，不是推广某一种需求文档形式。approved User Story / Vertical Slice 只是目标流程选择的产品输入模型：它们提供可独立验证的用户闭环，但不能替代流程治理、工程 Contract、TC oracle 或交付证据。

当前正式链路为：

```text
User Story / Vertical Slice
-> Functional Requirement (FR)
-> Feature Spec
-> Acceptance Criteria (AC)
-> Test Case (TC)
-> implementation and evidence
```

Product Base 和每个 Increment 还分别维护 requirements、spec、acceptance、test cases、traceability 等 artifact。该设计提高了早期可审计性，但随着产品事实和实现范围增长，出现了以下问题：

- 同一个用户行为在 Story / Vertical Slice、FR、Spec、AC、TC 和 traceability 中被重复改写，修改成本高，并容易产生语义漂移。
- Spec 和 AC 被当成固定交付阶段，而不是按真实信息缺口选择的表达方式。AI 辅助开发需要读取过长的文档链，相关上下文被重复内容稀释。
- Stage、Increment、Work Package 等交付规划对象进入产品追溯链和测试设计，造成“本次怎么交付”与“产品长期应如何表现”混合。
- 测试用例依赖 AC 编号才能获得 pass/fail 语义；一旦移除 AC 文档，如果没有重新定义 TC 的自包含 oracle，就会损失行为精度。
- Contract 和风险治理没有被清晰区分：API、Domain、Persistence、AI schema 或 UX 边界是否需要更新，应由事实边界是否变化决定；ADR、独立审查、迁移和发布控制是否需要追加，应由风险决定。

本决策需要缩短 AI 辅助 coding 的输入和反馈链，同时保留可执行、可验证、可审计的行为定义。删除独立 Spec / AC 阶段不等于删除规格思考、异常场景、pass/fail oracle 或验收责任。

### Legacy 基线的统一计量口径

PR1 固定比较口径，PR2 再对同一组代表性 fixture 采集实际数值，避免用不同功能规模证明流程变短：

| 维度 | Legacy 基线口径 | PR2 对比要求 |
| --- | --- | --- |
| 强制事实/验证节点 | selected approved Story / VS、FR、Spec、AC、TC 共 5 个节点 | 单 Slice 目标链路不超过 `approved VS -> TC` 2 个节点；有跨 Slice 稳定规则时不超过 `approved VS -> FR -> TC` 3 个节点 |
| 强制翻译跳数 | `VS -> FR -> Spec -> AC -> TC` 共 4 次跨 artifact 翻译 | 记录删除的跳数，并确认没有把同一翻译转移到 Issue、Contract 或 TC 正文 |
| 重复事实 | 同一可判定行为、规则、异常或边界在多个 canonical artifact 中出现时，每个额外 owning 位置计 1 次重复 | canonical owning source 数量为 1，双写为 0 |
| Gate 等待 | 统计 `G-SPEC`、`G-AC-TC` 等必经 Gate 的数量；存在可比时间戳时同时记录从提交到结论的持续时间 | 分别报告 Gate 数量和等待时间，不用估算值替代缺失时间戳 |
| AI 上下文负担 | 为完成同一 fixture 必须读取的文件数、稳定引用数和 UTF-8 字节数；全文与按需片段分开记录 | 目标 context bundle 不包含无关 Stage / Increment / Spec / AC 全文，文件/引用总量或字节数不高于基线的 60% |
| 行为精度 | 以 approved 行为、异常、边界和 pass/fail oracle 的可定位覆盖为分母 | 新旧口径都必须达到 100%，不得用减少覆盖换取流程缩短 |

上述数据只用于比较流程成本和完整性，不成为产品行为 source of truth。无法从现有证据取得的等待时间必须标记为 unavailable，不得补造。

## Decision

采用“产品事实稳定、工程事实按影响维护、测试 oracle 持久复用、交付状态一次性记录”的精简模型。Story / VS 是进入该模型的产品输入，而不是本次治理目标；本次治理成功与否以文档跳数、重复事实、AI 上下文、反馈时间和质量覆盖的可量化变化判断。

### 1. 分离产品事实轴和工程交付轴

PR3 激活后的目标模型分为两条轴：

```text
产品事实轴
Capability
-> approved User Story
-> approved Vertical Slice
<-> optional Functional Requirement

工程交付轴
Issue / PR selects approved VS and applicable FR
-> Test Case with executable oracle
-> affected engineering contracts
-> test-first implementation
-> CI evidence for the exact commit
-> risk-triggered review, migration and release controls
```

两条轴通过稳定的 VS ID、可选 FR ID、Contract ID 和 TC ID 关联，但不互相复制全文。四类信息必须保持唯一 ownership：

| 信息类别 | 唯一 owning source | 生命周期 |
| --- | --- | --- |
| 产品事实 | Story / VS，以及仅承载跨 Slice 稳定规则的可选 FR | 随产品行为变化而更新 |
| 工程事实 | API / Domain / Persistence / AI / UX 等 Engineering Contract | 随受影响工程边界的事实变化而更新 |
| 持久测试 oracle | TC Catalog 中自包含且可执行的 TC | 可跨 PR 复用，不随交付批次结束而失效 |
| 一次性交付状态 | Issue / PR、绑定 exact commit 的 CI 结果、migration / rollout / release 记录 | 只描述本次选择、执行和证据，不写回前三类事实 |

TC 位于工程交付轴，但不属于某个 Increment 或某次 PR。Issue、PR 或 CI 可以引用上述稳定 ID，不得复制其全文形成第二事实源。

### 2. 删除独立 Spec / AC 阶段，但保留行为精度

PR3 激活后，不再要求为每个功能创建独立 Feature Spec 和 Acceptance Criteria artifact，也不再把 `Spec -> AC` 作为实现前的强制 Gate。原来由 Spec / AC 承担的有效语义分别进入 owning source：

| 对象 | 责任边界 | 不得承载 |
| --- | --- | --- |
| User Story | 用户、场景、目标和用户价值 | 实现任务、测试命令、发布状态 |
| Vertical Slice | 可独立验证的用户闭环，包括触发条件、业务前置状态、用户选择、状态变化、用户可见结果、关键异常与边界 | Increment、Work Package、PR、代码路径和执行证据 |
| Functional Requirement | 跨多个 Slice 复用的稳定业务规则、不变量、阈值、合规约束或 claim guard；仅影响单一 Slice 的规则留在该 Slice | 文档 Gate、实现顺序、测试覆盖率和发布审批 |
| Test Case | 以 approved VS 为主要产品上游，引用适用 FR / Contract，包含自足的 Given / When / Then、边界场景、测试层级和可执行 selector | 新产品行为、Increment 权威、执行状态和持久化测试报告 |
| Engineering Contract | API、Domain、Persistence、AI structured output、UX 等工程边界的当前事实 | 产品价值、交付批次和风险审批结论 |

只有 `approved` 的 User Story / Vertical Slice 才能成为正式开发输入。VS 必须足以让 PM、开发和测试对用户闭环及关键异常形成一致理解；若不满足，先补齐并批准 VS，而不是让实现者或 AI 在 TC 和代码中发明产品行为。

FR 是可选补充，不是每个 VS 的必经翻译层。VS 与适用 FR 冲突时必须阻塞并交由产品事实 owner 裁决，测试或实现不得自行选择。

TC 直接承接原 AC 的 pass/fail oracle，并与测试代码中的稳定 selector 关联。测试执行结果由 CI 的机器可读输出和精确 commit SHA 证明，不写回 TC Catalog 形成第二份执行事实。

### 3. Stage 和 Increment 仅作为规划标签

Stage、Increment 和 Work Package 可以在 Issue、Roadmap 或发布计划中继续用于时间窗口、优先级、批次和协作组织，但不得作为以下对象的权威上游：

- 用户行为、业务状态或产品规则；
- Test Case 的 oracle 或覆盖成立条件；
- API、Domain、Persistence、AI 或 UX Contract；
- Capability、User Story、Vertical Slice 或 FR 的生命周期状态。

交付对象可以选择一组 approved VS / FR / TC，但选择关系不反向改变产品事实。禁止使用 Increment ID、Stage Scope ID 或 Work Package ID 定义产品行为，也禁止把它们作为新 TC 或 Contract 的必填事实依赖。

### 4. Contract 按事实变化触发，治理按风险触发

Contract 更新与风险治理采用两个独立判定：

1. **事实变化判定**：只要 API、OpenAPI、Domain、Persistence、结构化 AI 输出、Prompt fallback、UX flow 或其他 owning boundary 的事实发生变化，就必须更新对应 Contract，并运行相应 contract / integration / migration / eval 验证。风险较低不能豁免事实同步。
2. **风险判定**：只有当变更触及安全、隐私、支付、数据完整性、不可逆迁移、跨系统兼容、重大共享拓扑或生产发布风险时，才追加 ADR / RFC、独立审查、安全审查、兼容迁移、feature flag、canary、回滚和发布 Gate。

行为不变的内部重构或 UI polish 不因形式上的跨文件修改而新增产品文档。普通单 Slice 可逆变更走最小测试优先路径；跨边界或高风险变更按实际影响逐级增加证据和控制。

### 5. AI 辅助交付采用最小上下文和短反馈闭环

正式切换后的普通实现遵循成熟工程团队常用的小批量、test-first 和 exact-commit 反馈模式：

1. **最小上下文包**：默认只加载 selected approved VS、适用 FR、受影响 Contract、相邻代码/测试和本次验证命令。Stage、Increment、Work Package、archived Spec / AC 或整库文档只在迁移、审计或实际依赖要求时按需加载。
2. **小批量 PR**：一个 PR 只覆盖可独立评审、验证和回滚的 selected Slice 范围；范围扩张必须重新显式确认，不用长会话隐式累积额外目标。
3. **Test-first**：先把 TC oracle 映射到稳定 selector 并取得可归因的失败证据，再做满足 selected VS 的最小实现；不得先实现后反向改写 oracle 迎合代码。
4. **快速本地反馈**：先运行受影响单元、contract、integration、migration 或 eval 的最窄检查，快速修正后再运行适用全量治理检查；局部通过不能替代最终检查。
5. **Exact-commit CI**：最终机器证据必须绑定候选 commit SHA。Issue / PR 记录证据链接和交付判断，TC Catalog 不保存易过期的 pass/fail 执行状态。
6. **风险追加治理**：事实变化始终触发 owning Contract 同步；只有实际风险命中时才追加 ADR、安全/隐私审查、数据迁移、兼容策略、flag / canary、回滚和 release Gate。

PR1 只确立上述目标合同；PR2 在 shadow fixture 中验证其可行性，PR3 才原子激活，PR4 再用真实功能验证实际反馈闭环。

### 6. 使用迁移 manifest 防止旧事实丢失

PR1 建立 `docs/process/migrations/spec-ac-retirement.json`，用于逐条盘点旧 Spec / AC 及相关迁移对象的去向。manifest 只能记录旧事实如何被分类和迁移，不得定义新行为，也不得成为任何产品、工程或测试 artifact 的直接输入。

每个旧对象最终必须归类到以下一种或多种目标：

- approved Vertical Slice；
- stable Functional Requirement；
- API / Domain / Persistence / AI / UX Contract；
- executable regression Test Case；
- obsolete、rejected 或 grandfathered-unverified。

manifest 使用 `destinations` 数组表达已迁移去向；每个 destination 必须同时记录 `kind` 和稳定 `id`。同一旧对象可以拥有多个不同 `kind` 的 destination，例如同时关联 Vertical Slice、Functional Requirement 和 executable regression Test Case。`grandfathered-unverified`、`obsolete` 和 `rejected` 条目不得填写 destination，避免把未核验或终止对象伪装成已迁移事实。

manifest 是 `migration-only` artifact。所有条目达到规定的 terminal 状态、旧 authority 完成归档且迁移校验通过后，manifest 移入治理归档并从 active artifact route 中移除。它不得演化成第二套产品事实源或长期审批环节。

### 7. 按 PR1 至 PR4 分阶段执行并在 PR3 原子切换

#### PR1：决策与迁移合同

- 接受本 ADR，登记迁移 manifest 的 artifact contract、schema、validator 和测试。
- 盘点旧事实，但不迁移或重新批准产品行为。
- 旧流程继续作为唯一 runtime authority。
- 不改变 workflow、Definition of Done、Gate、Skill、产品事实、应用代码或应用测试。

#### PR2：影子验证

- 只在非 canonical fixture / shadow job 中验证新 FR、TC、approved VS coverage 和禁止旧治理对象回流的规则。
- 新模型不得用于正式功能交付，不得与旧模型形成双 authority。

#### PR3：原子 Cutover

- 在同一候选变更中更新 workflow、Definition of Done、governance artifact / Gate / actor / exchange / intent、相关 Skill 和 validator。
- 建立新 canonical FR / TC 路由，归档旧 Product Base / Increment Spec、AC 和 traceability authority。
- 只有所有适用校验对同一候选 commit 通过，且 governance authority 被显式激活后，本 ADR 才实际 supersede ADR 0001。
- 任一必要部分未完成时，整个切换不得激活；禁止部分新流程与部分旧流程共同生效。

#### PR4：真实 Slice 试点

- 选择一个已由 PM 补齐并批准的 Vertical Slice，迁移适用稳定规则和回归 oracle。
- 以 VS / 可选 FR 为产品输入、以 TC 为可执行 oracle，完成一次 test-first 实现和 CI 验证。
- 试点发现的是产品事实缺口时回到 owning VS / FR 修正；发现的是流程或 schema 缺口时修正相应治理 Contract，不创建临时 Spec / AC 绕过新模型。

#### 文件级落地顺序

以下顺序用于控制依赖、评审和验证，不表示其中某一组文件可以提前成为 authority：

1. **PR1**：先完成本 ADR；再建立 retirement manifest、Schema、专用 validator 和正负例测试；最后仅登记这些 migration-only artifact 所需的治理 route 和 artifact rows。不得修改 workflow、DoD、Gate 或 Skill。
2. **PR2**：先在 `docs/process/governance/shadow/story-slice-delivery/**` 建立 non-canonical 旧/新流程对照以及 FR / TC / coverage / context-bundle fixture；再建立 shadow validator 和测试；最后由 owner 在 manifest 中核验 typed destinations。active governance 文件保持不变。
3. **PR3**：先用 PR2 结果固定 canonical FR / TC、archive 和 validator 的精确路径；在同一候选 commit 中构建新 canonical artifact、迁移并归档 legacy authority、同步 workflow / DoD / governance / Skill / validator / CI；治理 status 与新 route 在逻辑上最后激活。任何单组文件都不得独立生效。
4. **PR4**：先由 PM 固化真实功能和 approved VS，并修订、重新批准精确路径；按 TC 先失败、最小实现、定向验证、exact-commit CI、独立审查和用户验收的顺序交付。

### 8. 禁止双写和提前生效

- PR1 / PR2 不得把新 FR / TC schema 用作 canonical 交付依据。
- PR3 激活前，不得停止执行现有 `G-SPEC`、`G-AC-TC` 或现有 DoD。
- PR3 激活后，不得为同一新行为同时维护 legacy Spec / AC 和新 VS / FR / TC 两套权威。
- 历史 Spec / AC 在归档后只读保留，用于审计和迁移追溯，不得被新 Issue、TC、Contract 或代码变更作为 authoritative input。

### 9. PR1 明确不改变的内容

本 ADR 属于迁移决策，不授权在 PR1 修改或删除以下内容：

- `docs/process/workflow.md`；
- `docs/process/definition_of_done.md`；
- 当前 Gate、Actor、Exchange、Intent 或现有 Skill 的交付语义；
- Product Base、Story Map、Capability Registry、Stage、Increment 或其他现有产品事实；
- ADR 0001 的历史内容；
- 应用代码、应用测试、API、数据库、AI runtime 或部署配置。

PR1 的其他允许变更仅限迁移 manifest、其 artifact contract / schema / validator / validator tests，以及为登记这些迁移对象所必需的治理路由。任何正式流程变更必须等待 PR3。

### 10. 目标 Definition of Done（仅在 PR3 原子激活后生效）

以下是目标流程的 DoD 合同，不是 PR1 / PR2 的当前执行规则。在 PR3 激活前，现有 Definition of Done 继续唯一生效；PR1 接受本 ADR 不代表下列条目已经生效。

- 产品输入引用完整且 approved 的 Story / VS；实现者和 AI 不得在代码或 TC 中发明缺失行为。
- 只有跨多个 Slice 复用的稳定规则才创建或更新 FR；单 Slice 规则留在 owning VS。
- 不强制创建 Spec / AC；异常、边界和 pass/fail 语义必须在 VS、适用 FR、TC 或 owning Contract 中有且只有一个归属。
- TC 直接引用 approved VS、可选 FR 和受影响 Contract，包含自足 Given / When / Then、边界/负例、测试层级和稳定 selector。
- API、Domain、Persistence、AI 或 UX 事实发生变化时，相应 Contract 已同步，并通过适用 contract / integration / migration / eval 验证；风险低不能豁免事实同步。
- 测试先于实现，保留可归因的先失败、后通过证据；实现只覆盖 selected VS 的最小范围。
- 本地定向检查通过，CI 对同一 exact commit 通过；TC Catalog 不保存执行状态。
- 已完成风险分类；安全、隐私、支付、数据完整性、不可逆迁移、跨系统兼容和生产发布风险按需追加独立审查、迁移、flag / canary、回滚和 release Gate。
- Issue / PR 只记录本次交付选择、状态和证据；Stage、Increment、Work Package 和 archived Spec / AC 不作为产品行为、TC 或 Contract 的 authoritative input。
- 无重复事实、无双写、无未解释例外；适用 owner、独立 checker 和用户要求的 PR 验收均已通过。

### 11. 最终验收指标

这些指标评价 PR1 至 PR4 的整体结果，不是 PR1 单独完成或提前激活目标流程的证明：

- 新功能强制 Spec 和 AC 数量均为 0；PR3 后 active `G-SPEC`、`G-AC-TC` 和 legacy Spec / AC route 数量均为 0。
- 单 Slice 链路最多为 `approved VS -> TC` 2 个节点；存在跨 Slice 稳定规则时最多为 `approved VS -> FR -> TC` 3 个节点，相对 legacy 5 节点分别减少至少 60% 和 40%。
- 同一行为或规则的 canonical owning source 数量为 1；Stage / Increment / Work Package / archived Spec / AC 的新 authoritative reference 和双写数量均为 0。
- 116 份 legacy 文件和 262 个 Spec / AC ID 的 disposition 覆盖率为 100%；仍有效事实迁移覆盖率为 100%，未解释的 `grandfathered-unverified` 当前行为数量为 0。
- Approved VS 到 executable regression TC 的覆盖率为 100%；TC 具备自包含 oracle、边界、测试层级和稳定 selector 的比例为 100%。
- 事实发生变化的 Engineering Contract 同步率及适用 contract / integration / migration / eval 验证率均为 100%。
- 在 PR2 同一代表性 fixture 上，默认 AI context bundle 不含 Stage / Increment / Spec / AC 全文，文件/引用总量或 UTF-8 字节数不高于 legacy 必需上下文的 60%，行为与边界覆盖保持 100%。
- 每个 PR 的适用自动验证、治理 validator 和 exact-commit CI 通过率为 100%；未关闭 blocker 和独立 checker 缺失数量均为 0。
- PR4 试点新增 Spec / AC、legacy authority 引用和重复事实数量均为 0；测试先失败/后通过、最小 context bundle、Contract 影响判断和 exact-commit CI 证据完整率为 100%。

## Alternatives

- **保留强制 `FR -> Spec -> AC -> TC` 链路**：拒绝。它保留了审计形式，但重复表达、上下文膨胀和漂移成本会持续增长，不能解决产品事实与交付治理混合的问题。
- **立即删除 Spec / AC，不做 manifest 和影子验证**：拒绝。旧文档中仍可能存在唯一业务规则、Contract 约束和回归 oracle，直接删除会造成不可检测的事实丢失。
- **让新旧流程长期并行并按团队自行选择**：拒绝。双 authority 会使 AI、CI 和人员无法确定哪个 artifact 定义当前行为，并扩大冲突和漏测风险。
- **保留 FR 作为每个 VS 的强制阶段**：拒绝。单 Slice 规则再次改写为 FR 仍然是重复翻译；FR 只应承载稳定、跨 Slice 复用的规则。
- **用 Increment 继续承载 TC 和 Contract**：拒绝。交付批次会变化或结束，而产品行为、工程边界和回归测试需要稳定生命周期。

## Consequences

- 正式切换后，AI coding 的最小上下文可以收敛为 selected approved VS、适用 FR、实际受影响 Contract、相邻代码 / 测试和验证命令。
- 产品事实与一次性交付状态分离，Stage / Increment 调整不再要求重写产品、测试和 Contract 权威。
- Spec / AC 的文档数量和 Gate 减少，但 VS、FR 和 TC 的内容质量要求提高；尤其 TC 必须自包含可执行 oracle。
- PM 需要先处理尚未 approved 或不够精确的 Slice，不能通过下游 Spec / AC 补写来掩盖上游事实缺口。
- 测试设计和 CI 需要建立 VS-to-TC coverage、selector 可执行性和精确 SHA 证据校验。
- 历史迁移产生一次性盘点成本，但 manifest 提供可统计的迁移进度、缺口和归档条件。

### 安全、可靠性与可运维性影响

- **安全与隐私**：安全、隐私、支付、账号恢复、数据删除等规则必须进入 owning VS / FR 和相应 Contract；高风险变更继续强制独立审查、审计证据和发布控制，不能因删除 AC 而降级。
- **可靠性**：业务状态、不变量、失败模式和边界案例必须在 VS / FR 与 TC oracle 中可定位；Contract 变化必须有对应 contract、integration、migration 或 AI eval 证据。
- **可运维性**：执行事实绑定精确 commit SHA，由 CI、部署和观测系统保存；TC Catalog 不混入易过期的 pass/fail 状态。生产风险触发 feature flag、canary、监控和回滚计划。
- **可审计性**：稳定 ID 和 manifest 保留旧对象到新 authority 的去向；历史 Spec / AC 只读归档，不改写历史决策和证据。

## Risks

- **未批准或过于粗糙的 VS 无法直接支撑测试。** 缓解：只有 approved VS 可进入开发；先补齐触发、状态、结果和异常边界，再生成 TC。
- **迁移 manifest 变成新的长期审批层或事实源。** 缓解：声明 `migration-only`、禁止下游输入、限定 terminal 状态和 sunset 条件，并由 validator 执行。
- **PR3 部分切换导致双 authority。** 缓解：以单个候选 commit 原子更新所有 authority；全部校验通过前保持 legacy 唯一生效。
- **旧 Spec / AC 中的规则或 oracle 遗失。** 缓解：按稳定 ID 全量盘点，要求每条记录有分类、目标引用、owner、理由和 terminal 状态；无法确认的内容标记 `grandfathered-unverified`，不得静默删除。
- **Stage / Increment 再次渗入产品事实。** 缓解：新 schema 和 validator 禁止其成为 VS / FR / TC / Contract 的行为依赖，只允许 Issue / PR 中记录选择关系。
- **Contract 因低风险判断被漏更。** 缓解：先执行事实变化判定，再执行风险判定；Contract obligation 不受风险等级豁免。
- **大量 draft Slice 被机械批准以满足新 Gate。** 缓解：批准权仍归产品事实 owner，逐 Slice 审核用户闭环和异常边界，不进行批量状态迁移。

## Rollback

PR1 和 PR2 不改变 runtime authority，因此在 PR3 激活前可以删除本 ADR、迁移 manifest 及其专用治理 Contract / validator，旧流程无需恢复，应用行为也不受影响。

PR3 采用“验证后激活”：如果候选变更的任一必要校验失败，保持 governance authority 未激活并整体撤回候选切换，禁止只回退其中一部分。manifest 保留失败原因和未迁移对象，供后续修复。

PR3 激活后如发现新模型存在不可接受风险，优先以前向修复补齐 VS、FR、TC、Contract 或 validator。确需恢复旧流程时，必须通过新的 ADR 和一次新的原子治理变更，恢复完整 workflow、DoD、Gate、Skill、artifact route 和 CI 语义；不得临时重新启用单个 Spec / AC Gate 或形成双写。历史归档保持只读，不通过改写 ADR 0001 或历史 artifact 伪造连续性。
