# 用户故事地图

## 文档状态

- Owner: Product Manager Agent
- Status: capability-organized story and slice draft
- Artifact: `STORY_MAP_INDEX`
- Canonical navigation path: `docs/product/story_map.md`
- Method: `.agents/skills/story-map-develop/SKILL.md`

本文件是 `STORY_MAP` 的 canonical 导航索引，不直接定义或拥有 User Story 与 Child Vertical Slice 的行为语义。下列 15 个 Capability 文件共同承载当前 Story/VS 内容，并按 `docs/product/feature_registry.md` 的 V2 Capability Table 组织；Capability 只作为边界分类，各文件中的 approved User Story 与其嵌套的 approved Child Vertical Slice 才是当前产品行为来源。

本索引只维护共享规则、追溯说明和 Capability 文件导航，不生成 FR、test cases、API/domain/UX/SWC contract、实现计划或发布决策。

## 当前范围与编号规则

- 一级功能区域按 V2 capability 顺序编号；各 Capability 文件标题使用 capability name，并保留 Capability ID 与 slug。
- User Story ID 使用 `US-<Capability Prefix>-<NNN>`。
- Vertical Slice ID 使用 `VS-<Capability Prefix>-<NNN>`，在同一 capability 内连续编号。
- `Status: draft` 表示待 PM 批准和后续 ready gate；不代表 downstream commitment。除既有 `US-TRAIN-001` / `VS-TRAIN-001` 保留已批准语义外，当前新增 Story/Slice 均为 draft narrative。
- 当前 V2 Capability Registry 没有独立 `CAP-AUTH`。注册、登录、会话恢复暂按 `CAP-ACC-01 账号访问` 纳入 `CAP-ACC`；若后续 registry 拆出 `AUTH` capability，应迁移对应 Story/Slice。
- Child Vertical Slices 以可读闭环叙事嵌套在所属 User Story 下；后续进入交付前仍需按 `story-map-develop` ready gate 补齐或复核完整 metadata。

## 追溯链路

```text
Capability ID
-> approved User Story ID
-> approved Vertical Slice ID
-> Functional Requirement ID when present
-> typed Test Case edge
-> affected Engineering Contract and implementation evidence when applicable
```

`Stage`、`Roadmap`、`Increment`、`Work Package` 和 `PR` 只组织交付，不定义产品行为，也不作为 FR、TC 或 Engineering Contract 的事实上游。Capability Registry 只定义稳定业务边界。

## Capability User Story 文件索引

| 顺序 | Capability | Slug | User Story 文件 |
| --- | --- | --- | --- |
| 1 | `CAP-ACC` - 账号、身份资料与隐私 | `account-profile-privacy` | [`user_story_CAP_ACC.md`](./user_stories/user_story_CAP_ACC.md) |
| 2 | `CAP-LEVEL` - 当前水平与能力画像 | `learner-level-profile` | [`user_story_CAP_LEVEL.md`](./user_stories/user_story_CAP_LEVEL.md) |
| 3 | `CAP-INTENT` - 学习目标与偏好 | `learning-intent-preference` | [`user_story_CAP_INTENT.md`](./user_stories/user_story_CAP_INTENT.md) |
| 4 | `CAP-PLAN` - 学习计划与计划版本 | `learning-plan-version` | [`user_story_CAP_PLAN.md`](./user_stories/user_story_CAP_PLAN.md) |
| 5 | `CAP-CONTENT` - 内容资产 | `content-curriculum-scenario` | [`user_story_CAP_CONTENT.md`](./user_stories/user_story_CAP_CONTENT.md) |
| 6 | `CAP-PRACTICE` - 练习会话与互动 | `practice-session-runtime` | [`user_story_CAP_PRACTICE.md`](./user_stories/user_story_CAP_PRACTICE.md) |
| 7 | `CAP-TRAIN` - 技能训练编排与自动化 | `skill-training-automation` | [`user_story_CAP_TRAIN.md`](./user_stories/user_story_CAP_TRAIN.md) |
| 8 | `CAP-COACH` - AI 教练、反馈与评估 | `ai-coach-feedback-assessment` | [`user_story_CAP_COACH.md`](./user_stories/user_story_CAP_COACH.md) |
| 9 | `CAP-MEMORY` - 学习事实、进度与复盘 | `learning-facts-progress-review` | [`user_story_CAP_MEMORY.md`](./user_stories/user_story_CAP_MEMORY.md) |
| 10 | `CAP-NOTE` - 笔记、词汇与个人素材 | `notebook-vocabulary-assets` | [`user_story_CAP_NOTE.md`](./user_stories/user_story_CAP_NOTE.md) |
| 11 | `CAP-COM` - 会员、商业化与权益 | `membership-commerce-entitlement` | [`user_story_CAP_COM.md`](./user_stories/user_story_CAP_COM.md) |
| 12 | `CAP-ENGAGE` - 参与、通知与留存 | `engagement-notification-retention` | [`user_story_CAP_ENGAGE.md`](./user_stories/user_story_CAP_ENGAGE.md) |
| 13 | `CAP-SETTING` - 应用设置与体验偏好 | `app-experience-settings` | [`user_story_CAP_SETTING.md`](./user_stories/user_story_CAP_SETTING.md) |
| 14 | `CAP-SUPPORT` - 用户支持、反馈与服务 | `user-support-feedback-service` | [`user_story_CAP_SUPPORT.md`](./user_stories/user_story_CAP_SUPPORT.md) |
| 15 | `CAP-BILLING` - 账单与支付服务 | `billing-payment-service` | [`user_story_CAP_BILLING.md`](./user_stories/user_story_CAP_BILLING.md) |

## Legacy 覆盖索引

> 本节是从既有旅程名称到当前 User Story ID 的 derived/历史覆盖说明，仅用于导航与核对，不拥有或定义 Story/VS 语义。

- `启动、登录与首评`：覆盖到 `US-ACC-001`、`US-ACC-002`、`US-LEVEL-001`、`US-LEVEL-002`、`US-LEVEL-003`、`US-INTENT-001`、`US-INTENT-003`、`US-INTENT-004`、`US-INTENT-005`。
- `情景学习`：覆盖到 `US-PLAN-001`、`US-PLAN-002`、`US-PLAN-003`、`US-PLAN-004`、`US-CONTENT-001`、`US-CONTENT-002`、`US-CONTENT-003`、`US-CONTENT-004`、`US-INTENT-002`、`US-INTENT-003`。
- `听力热身与推荐表达`：覆盖到 `US-PRACTICE-001`、`US-PRACTICE-002`、`US-PRACTICE-004`、`US-TRAIN-002`、`US-TRAIN-004`、`US-TRAIN-005`、`US-NOTE-001`。
- `语音模拟与教练反馈`：覆盖到 `US-PRACTICE-003`、`US-PRACTICE-005`、`US-COACH-001`、`US-COACH-002`、`US-COACH-003`、`US-TRAIN-003`、`US-TRAIN-004`。
- `复盘、复习与个人结果`：覆盖到 `US-PLAN-002`、`US-PLAN-003`、`US-PLAN-004`、`US-TRAIN-001`、`US-MEMORY-001`、`US-MEMORY-002`、`US-MEMORY-003`、`US-MEMORY-004`、`US-NOTE-001`、`US-NOTE-002`、`US-NOTE-003`、`US-NOTE-004`。
- `我的与账号设置`：覆盖到 `US-ACC-003`、`US-ACC-005`、`US-ACC-006`、`US-ACC-007`、`US-ACC-008`、`US-ACC-009`、`US-ACC-010`、`US-SETTING-001`、`US-SETTING-002`、`US-SETTING-003`、`US-ENGAGE-001`、`US-ENGAGE-002`、`US-ENGAGE-003`、`US-ENGAGE-004`、`US-ENGAGE-005`。
- `会员订阅与账单`：覆盖到 `US-COM-001`、`US-COM-002`、`US-COM-003`、`US-BILLING-001`、`US-BILLING-002`、`US-BILLING-003`、`US-BILLING-004`。
- `用户支持与反馈`：覆盖到 `US-SUPPORT-001`、`US-SUPPORT-002`、`US-SUPPORT-003`、`US-SUPPORT-004`。

## Ready Gate 记录

> 本节是历史治理记录，仅保留当时的来源、范围与评审上下文，不拥有或定义 Story/VS 语义，也不改变各 Capability 文件中的当前状态。

Assumptions:

- Scope mode: `capability`，目标范围为 `CAP-SETTING`、`CAP-SUPPORT`、`CAP-BILLING`。
- Product classification: `product-base-consolidation` / capability-organized story map normalization.
- Capability classification: 依据 `docs/product/feature_registry.md` 的 V2 Capability Table 做章节和边界映射；不从 Capability Registry 反推产品行为。
- Product behavior source: `docs/product/user_stories.md` legacy 清单和本次 PM 输入示例。
- 本轮行为来源：用户明确要求将上一轮已评审的商业化 Story/Slice 草案写入 story map，分类为 `user-authorized draft proposal`；它允许持久化为 `draft`，不等于 PM approval 或 downstream commitment。Registry 的 owns / does not own / sub-capability 仅用于约束边界和 mapping，不作为行为来源。
- 当前 registry 没有 `CAP-AUTH`；认证主流程暂纳入 `CAP-ACC`，后续如新增 `AUTH` capability 需迁移。
- 本轮按成熟商业软件的产品叙事重写三个 capability：每个 Slice 必须承载具体业务对象、用户决策、状态变化或跨 capability 交接，不能仅用通用成功/失败句式填充；进入交付前仍需对选中的 Story/Slice 运行完整 ready gate。

Row-level Source Coverage:

- `US-SETTING-001..003`、`VS-SETTING-001..009` -> user-authorized draft proposal：用户明确要求持久化上一轮商业化草案。
- `US-SUPPORT-001..004`、`VS-SUPPORT-001..012` -> user-authorized draft proposal：用户明确要求持久化上一轮商业化草案。
- `US-BILLING-001..004`、`VS-BILLING-001..012` -> user-authorized draft proposal：用户明确要求持久化上一轮商业化草案。

Omitted Scope:

- 本轮不决定具体支付/税务 provider、精确客服 SLA、退款或争议审批规则、账号/内容/AI 治理结论、下游 FR/TC/contract/implementation/release artifact。

Ready Gate Finding:

- Result: pass
- Gate: draft structural + narrative quality
- Source authority finding: 本轮 44 个 rows 均分类为 user-authorized draft proposal，来源是用户明确要求持久化的上一轮商业化草案；它们保持 `draft`，未被表述成 PM-approved facts。具体 provider、精确客服 SLA、审批规则和治理结论仍保留为 omitted scope。
- Coverage finding: `CAP-SETTING`、`CAP-SUPPORT`、`CAP-BILLING` 的目标 Story/Slice 已全部覆盖；Affected Capability IDs 已限制为 registry 对各 Primary Capability 声明的相邻 capability，非相邻责任域只在 description 或 Boundary note 中作为“不拥有/不改变”边界说明。
- Narrative finding: Story Map 已按 V2 capability 章节组织；本轮重写的 `CAP-SETTING`、`CAP-SUPPORT`、`CAP-BILLING` 不再把页面加载或通用错误提示当作独立价值，而是明确偏好生效范围、临时与全局设置、反馈上下文、工单与争议生命周期、交易与权益分离、支付恢复和账号/交易匹配等业务决策。
- Metadata completeness finding: 每条 User Story 与 Child Vertical Slice 均使用现行五列结构，包含 ID、description、Status、Primary Capability ID 和 Affected Capability IDs；Parent Story 由章节嵌套表达。该结果仅表示 draft structural 与 narrative quality 通过，不表示这些 `draft` rows 已通过 approval semantic gate。
- Narrative/metadata consistency finding: Capability metadata 仅作为边界分类；用户行为来自 legacy 清单、PM 输入或本轮明确标注的 user-authorized draft proposal，没有把 capability 条目直接当需求来源，也没有把 user-authorized draft 误写成 PM approval。
- Ambiguity finding: 邮箱认证方式、`AUTH` capability 是否拆出、学习报告完整内容、推荐/复习算法、provider 实现、支付 provider、税务 provider、客服 SLA、退款审批和 AI/内容治理最终结论均保持为待澄清或 out of scope，不在本文中替下游决策。
- Split finding: 三个 capability 的 sibling slices 均有可单独说明的用户目标或业务状态：设置按使用环境、听说默认体验和本地存储拆分；支持按自助帮助、反馈、人工服务和正式争议拆分；账单按交易历史、支付恢复、退款争议和账号/交易不匹配拆分。

PM Approval Required:

- PM approval: yes, for promoting any `draft` User Story or Vertical Slice to `approved` or downstream-consumable status.
- Downstream commitment: no. 任何 increment、FR、TC、contract 或实现工作仍需后续 PM execution brief 与对应下游 skill/agent 产物。
