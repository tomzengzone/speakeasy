# 用户故事地图

## 文档状态

- Owner: Product Manager Agent
- Status: capability-organized story and slice draft
- Canonical path: `docs/product/story_map.md`
- Legacy compatibility: `docs/product/user_stories.md` 仅作为旧入口；新增或触碰的 Story/Slice 必须写入本文。
- Method: `.agents/skills/story-map-develop/SKILL.md`

本文按 `docs/product/feature_registry.md` 的 V2 Capability Table 组织 User Story 与 Child Vertical Slices。Capability 只作为边界分类，不作为产品行为来源；产品行为主要来自 `docs/product/user_stories.md` 的 legacy 清单和本次 PM 输入示例。

本文只定义 User Story 与 Vertical Slice 的产品价值、用户可见行为、边界和 E2E 验收意图。本文不生成 FR、spec、pass/fail acceptance criteria、test cases、API/domain/UX/SWC contract、实现计划或发布决策。

## 当前范围与编号规则

- 一级功能区域按 V2 capability 顺序编号，章节名使用 capability name，并保留 Capability ID 与 slug。
- User Story ID 使用 `US-<Capability Prefix>-<NNN>`。
- Vertical Slice ID 使用 `VS-<Capability Prefix>-<NNN>`，在同一 capability 内连续编号。
- `Status: draft` 表示待 PM 批准和后续 ready gate；不代表 downstream commitment。除既有 `US-TRAIN-001` / `VS-TRAIN-001` 保留已批准语义外，本文新增 Story/Slice 均为 draft narrative。
- 当前 V2 Capability Registry 没有独立 `CAP-AUTH`。注册、登录、会话恢复暂按 `CAP-ACC-01 账号访问` 纳入 `CAP-ACC`；若后续 registry 拆出 `AUTH` capability，应迁移对应 Story/Slice。
- Child Vertical Slices 以可读闭环叙事写入本节；后续进入交付前仍需按 `story-map-develop` ready gate 补齐或复核完整 metadata。

## 追溯链路

```text
User Story ID / Vertical Slice ID
-> Primary Capability ID / Affected Capability IDs
-> Increment ID
-> FR ID
-> Spec ID
-> AC ID
-> TC ID
-> Contract / SWC gate when applicable
-> WP ID
-> PR / Code Evidence
-> Test Evidence
-> Product Base merge decision
```

`Stage`、`Roadmap`、`Increment`、`Work Package` 和 `PR` 只组织交付，不定义产品行为。Capability Registry 只定义稳定业务边界。

## 1. 账号、身份资料与隐私（CAP-ACC / account-profile-privacy）

### US-ACC-001 - 未认证学习者完成登录或注册后进入 App

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-001` | 作为未认证学习者，当我启动 App 时，我希望看到当前设备可用的登录和注册入口，并在同意服务条款与隐私政策后，通过手机号验证码、邮箱、微信或 Apple 完成认证，以便进入 App 首页并开始或继续学习。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-001` | 当未认证学习者启动 App 时，系统展示登录/注册入口和当前设备可用的认证方式；成功时学习者可以选择一种方式继续；若无可用方式或网络异常，展示可恢复提示。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ACC-002` | 当学习者准备继续认证时，需要查看并同意服务条款和隐私政策；同意后可继续，未同意时不能继续认证但可返回或查看协议。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ACC-003` | 学习者输入手机号并完成验证码校验；若手机号已有账号则登录，若手机号未注册则创建账号并登录；成功后进入首页，失败时展示验证码错误、过期、发送失败或重试入口。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ACC-004` | 学习者通过明确的邮箱认证方式完成登录或注册；成功后进入首页，失败时展示邮箱无效、验证失败、密码错误或重试入口。产品上仍需明确“邮箱入口”到底是邮箱验证码、邮箱密码，还是邮箱链接。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ACC-005` | 学习者选择微信授权；授权成功后登录或创建账号并进入首页；授权取消、微信不可用或授权失败时，返回认证入口并允许切换方式。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ACC-006` | 学习者在支持 Apple 登录的设备上选择 Apple 授权；授权成功后登录或创建账号并进入首页；授权取消、设备不支持或授权失败时，返回认证入口并允许切换方式。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ACC-007` | 已登录学习者启动 App 时直接进入首页；若登录态失效，系统回到认证入口并提示重新登录。 | `draft` | `CAP-ACC` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

### US-ACC-002 - 已登录学习者查看账户中心并理解当前账户状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-002` | 作为已登录学习者，当我进入账户相关页面时，我希望看到当前账号身份、资料完整度、隐私授权、数据权利和安全设置入口，以便确认自己的账户状态并继续管理个人账户。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-008` | 当已登录学习者从“我的”或设置入口进入账户中心时，系统展示账户相关管理入口；成功时学习者能看到账号身份、基础资料、隐私、数据权利和安全设置入口；若账户信息加载失败，展示可恢复提示并允许重试。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |
| `VS-ACC-009` | 学习者进入账户中心后，可以看到当前账号的主要身份标识和已绑定登录方式摘要；成功时能判断手机号、邮箱、微信、Apple 等方式是否已绑定；失败时展示信息不可用状态，不允许误导用户认为绑定状态已改变。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |
| `VS-ACC-010` | 当账户存在资料未完善、隐私授权待确认、安全风险或数据权利请求处理中等状态时，账户中心展示明确提醒；成功时学习者知道需要处理什么；若状态不可用，展示保守的空状态或重试提示。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |

### US-ACC-003 - 已登录学习者管理账号身份与登录绑定方式

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-003` | 作为已登录学习者，我希望查看、绑定、更换或解除账号的身份凭证和登录方式，以便在设备更换、账号恢复或第三方账号变化时仍能安全访问自己的学习账户。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-011` | 当学习者进入账号身份设置页时，系统展示当前主账号标识、已绑定方式和可绑定方式；成功时学习者知道哪些方式可用于后续登录；若状态加载失败，展示重试提示且不允许执行绑定/解绑操作。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-012` | 学习者选择绑定手机号并完成验证码验证；成功时手机号成为当前账号的可用身份凭证；失败时展示手机号格式错误、验证码错误、验证码过期、号码已被其他账号占用或发送失败等可恢复状态。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-013` | 学习者在已有手机号的情况下发起更换，并完成必要身份确认和新手机号验证；成功时新手机号替代旧手机号；失败或中断时保持原手机号不变，并提示可重新尝试。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-014` | 学习者添加或更换邮箱，并完成明确的邮箱验证方式；成功时邮箱成为当前账号的可用身份凭证；失败时展示邮箱无效、验证失败、邮箱已被占用或验证过期等状态。这里需要产品上明确邮箱验证是“邮箱验证码”“邮箱链接”还是“邮箱密码”。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-015` | 学习者在账号身份设置中选择绑定或解除微信；成功时微信绑定状态更新；若微信不可用、授权取消、授权失败或解除后会导致账号无可用登录方式，系统展示阻断或可恢复提示。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-016` | 学习者在支持 Apple 登录的设备上绑定或解除 Apple；成功时 Apple 绑定状态更新；若设备不支持、授权取消、授权失败或解除后会导致账号不可登录，系统展示阻断或切换方式入口。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

### US-ACC-004 - 已登录学习者管理基础身份资料

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-004` | 作为已登录学习者，我希望查看和维护头像、昵称和基础个人信息，以便在 App 内形成稳定的个人身份展示，并确保账户资料保存失败时不会错误覆盖已有资料。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-017` | 当学习者进入基础资料页时，系统展示当前头像、昵称和基础个人信息字段；成功时学习者能确认当前资料；若资料加载失败，展示空状态或重试入口，且不改变已有资料。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |
| `VS-ACC-018` | 学习者修改头像或昵称并保存；成功时账户资料页和相关展示位置反映新资料；失败时展示格式、内容、上传或保存失败提示，并保持原资料不被错误覆盖。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |
| `VS-ACC-021` | 当基础资料字段缺失、部分字段暂不可编辑或内容不符合规则时，系统给出明确提示；成功时学习者知道哪些资料可以补全、哪些暂不能修改；失败时不应让用户误以为资料已保存。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |

Boundary note:

- 学习目的、职业场景偏好和英语水平自评不归入 `CAP-ACC`；对应完整流程由 `CAP-INTENT` 和 `CAP-LEVEL` 承接，账户资料不提供可下游消费的 Story/VS。
- 通用显示主题、语言、音频等 App 体验偏好不归入 `CAP-ACC`；在 PM 确认设置类 capability 或 registry 边界前，不在本文中作为可下游消费的 Story/VS 承接。

### US-ACC-005 - 已登录学习者管理隐私授权与使用规则

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-005` | 作为已登录学习者，我希望查看和调整与隐私相关的授权、设备权限和使用规则入口，以便知道 App 如何使用我的设备权限和学习数据，并能按自己的选择继续使用。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-022` | 学习者进入隐私授权中心后，系统展示当前隐私授权和权限状态；成功时学习者能看到哪些授权已开启、哪些未开启、哪些需要前往系统设置处理；失败时展示状态不可用并允许重试。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-023` | 当学习者需要语音练习但麦克风权限未开启时，可从隐私授权中心查看并进入授权引导；成功时学习者理解权限用途并能前往开启；拒绝或系统限制时，展示功能影响和替代路径。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-024` | 学习者查看通知授权状态并选择开启、关闭或前往系统设置调整；成功时授权状态在账户侧可见；失败或系统不允许修改时，展示说明，不误报授权已改变。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-025` | 学习者可从隐私中心查看服务条款、隐私政策和当前同意状态；成功时能打开对应协议内容；若协议加载失败，展示可恢复提示，不阻塞已有账户信息展示。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

### US-ACC-006 - 已登录学习者使用数据权利入口并管理账号状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-006` | 作为已登录学习者，我希望在账户中找到个人数据相关权利入口，并可以退出登录或注销账号，以便查看、导出、删除或提交与个人数据有关的请求，并管理当前账号状态。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-026` | 学习者进入数据权利页面后，系统展示可用的数据权利操作，例如查看数据摘要、导出数据、删除数据或注销账号入口；成功时学习者知道每类操作的影响；失败时展示可恢复错误，不执行任何数据动作。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-027` | 学习者发起个人数据导出请求并完成必要确认；成功时系统记录请求并展示后续获取方式或处理状态；失败时展示请求失败原因，并允许重新提交。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-028` | 学习者发起删除数据或注销账号请求，并看到明确影响说明和确认步骤；成功时请求进入处理状态或完成状态；取消、验证失败或不满足条件时，账户和数据保持不变。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-029` | 学习者查看已提交的数据权利请求状态；成功时能看到处理中、已完成、失败或需补充操作等状态；失败时展示状态不可用并允许重试，不重复提交请求。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-030` | 学习者选择退出当前账号；成功时当前会话失效并回到登录/认证入口；失败时展示可恢复提示，不错误清除当前学习状态。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |

### US-ACC-007 - 已登录学习者管理隐私授权版本与撤回

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-007` | 作为已登录学习者，当我检查隐私授权和数据使用规则时，我希望看到当前同意的协议版本、非必要授权和可撤回的数据使用选择，以便知道 App 当前如何使用我的权限和学习数据，并能撤回不再接受的授权。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-031` | 学习者从隐私授权中心查看当前服务条款、隐私政策和授权版本；成功时看到当前版本、同意状态和更新时间；版本信息不可用时展示保守提示并允许重试。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-032` | 学习者撤回非必要授权或个性化数据使用选择；成功时授权状态更新并展示受影响功能；撤回失败或系统限制时保持原状态并说明原因。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-033` | 当隐私授权变更会影响语音练习、提醒或训练体验时，系统展示影响说明和可恢复路径；成功时学习者知道哪些功能仍可用，哪些需要重新授权；状态不可用时不误报授权已变更。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

### US-ACC-008 - 学习者恢复账号访问

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-008` | 作为无法正常登录的学习者，当我忘记登录方式、凭证失效或更换设备时，我希望通过已绑定的手机号、邮箱或可用验证方式恢复账号访问，以便安全回到自己的学习数据而不是误建新账号。 | `draft` | `CAP-ACC` | `CAP-MEMORY`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-034` | 学习者从登录页进入账号恢复入口并选择手机号或邮箱验证；成功时看到可继续验证的路径；账号不存在、验证方式不可用或发送失败时展示可恢复提示。 | `draft` | `CAP-ACC` | `CAP-MEMORY`, `CAP-COM` |
| `VS-ACC-035` | 学习者完成账号恢复验证后回到原账号；成功时保留原学习数据和订阅权益状态；验证失败、过期或中断时不创建新账号并允许重新尝试。 | `draft` | `CAP-ACC` | `CAP-MEMORY`, `CAP-COM` |

### US-ACC-009 - 学习者管理账号安全与登录设备

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-009` | 作为已登录学习者，当我怀疑账号风险或更换设备时，我希望查看登录设备、远端会话、安全风险提示，并在敏感操作前完成重新验证，以便确认账号仍由自己安全控制。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-036` | 学习者进入账号安全页后查看当前设备、其他登录设备和远端会话摘要；成功时能识别登录位置和最近活动；加载失败时展示状态不可用并阻止误操作。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-037` | 学习者选择退出其他设备或结束远端会话；成功时对应会话失效并展示结果；失败或权限不足时保持会话状态并说明原因。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-038` | 学习者执行注销、删除数据、解绑最后一种登录方式或管理订阅等敏感操作前，系统要求重新验证；成功时允许继续原操作；验证失败或取消时原操作不生效。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-039` | 当系统检测到用户可见的账号安全风险时，账号安全页展示风险提示和处理入口；成功时学习者知道建议动作；风险状态不可用时展示保守状态，不制造错误告警。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

## 2. 当前水平与能力画像（CAP-LEVEL / learner-level-profile）

### US-LEVEL-001 - 已登录新用户完成首评并获得当前学习起点

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-LEVEL-001` | 作为已登录新用户，当我首次进入学习流程且系统尚不了解我的英语输出水平时，我希望完成首评并提交当前输出水平相关信息，以便形成第一版当前水平画像并支撑后续学习路线生成。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-LEVEL-001` | 当已登录新用户没有当前水平画像时，系统展示首评入口和任务说明；成功时学习者知道需要完成什么；若任务不可用，展示可恢复提示并允许稍后再试。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-002` | 学习者选择当前输出水平、表达卡点或完成系统采样任务；成功时系统记录可用于初始画像的信息；失败时展示提交错误，不推进首评完成状态。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-003` | 当首评信息有效时，系统生成当前水平、关键能力标签和画像置信提示；成功时学习者知道自己当前处于什么起点；无可用结果时展示空状态并允许重试或补充信息。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-004` | 首评完成后，系统将当前水平结果交接给目标偏好和初始计划生成；成功时学习者可以继续设置学习目标；失败时保留首评结果，不重复要求学习者完成相同步骤。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

### US-LEVEL-002 - 学习者查看可解释的能力画像

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-LEVEL-002` | 作为学习者，当我查看当前英语能力画像时，我希望看到口语、听力、阅读、词汇、发音、流利度、语法和表达完成度等维度的解释，以及等级映射、证据来源和置信度，以便理解系统为什么这样判断我的当前水平。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-LEVEL-005` | 学习者从当前水平页进入能力画像详情；成功时看到多维能力画像和各维度当前状态；画像不可用时展示原因和补充信息入口。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-LEVEL-006` | 学习者查看等级映射和能力标准解释；成功时能理解当前等级如何对应能力维度；映射不可用时不展示误导性的等级结论。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-LEVEL-007` | 学习者查看弱项证据、证据来源时间和置信度；成功时知道判断依据来自首评、复测或学习证据；证据不足时展示不确定状态。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |

### US-LEVEL-003 - 学习者更新或复测当前水平

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-LEVEL-003` | 作为学习者，当我认为当前水平画像已经过期或需要重新确认时，我希望主动更新自报信息或完成复测任务，并看到新旧画像差异，以便后续目标、计划和训练基于新的当前水平。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-LEVEL-008` | 学习者从当前水平页主动更新自报等级、分项自评、学习经历或近期能力感受；成功时形成新的自报水平事实；保存失败时保持原画像不变。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-009` | 学习者触发复测并完成复测任务；成功时系统生成新的测评结果和完成状态；任务不可用、中断或提交失败时展示可恢复入口，不替换原画像。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-010` | 当新画像生成后，系统展示画像版本前后对比、更新原因和影响提示；成功时学习者知道哪些能力判断发生变化；对比不可用时保留新画像并提示暂不可比较。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

## 3. 学习目标与偏好（CAP-INTENT / learning-intent-preference）

### US-INTENT-001 - 学习者设定目标偏好并理解当前支持状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-001` | 作为学习者，当我完成首评并需要建立初始学习方向时，我希望选择目标方向、表达卡点、当前输出水平和每日分钟数，并看到该方向是否被当前 MVP 完整支持，以便 App 保存我的偏好且不会把暂未完整支持的方向误导为已有完整场景可练。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-001` | 学习者在目标设置中选择英语面试、入职介绍、日常服务或其他方向；成功时系统记录目标方向；若方向暂未支持，展示明确支持状态而不是进入不可练流程。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-002` | 学习者选择表达卡点、口语输出问题或能力重点；成功时偏好可用于后续路线和推荐；失败时展示保存失败并保留原选择。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-003` | 学习者设置每日可投入分钟数；成功时形成学习投入约束；无效输入或保存失败时展示可恢复提示，不生成错误计划。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-004` | 当学习者选择日常服务等暂未完整支持方向时，系统允许完成首评进入首页，但明确展示该方向的支持状态；成功时学习者不会误以为已有完整日常服务场景可练。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-005` | 当目标、卡点、水平和时间约束都可用时，系统保存偏好并交接给计划能力；成功时学习者进入首页或路线预览；失败时展示可恢复错误且不丢失已填写信息。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |

### US-INTENT-002 - 学习者维护官方场景学习路线

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-002` | 作为学习者，当我从官方内容中选择适合自己的学习方向后，我希望能加入、移除、设为当前场景并切换目标等级，以便让学习路线持续匹配我的当前目标和能力状态。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-007` | 学习者加入或移除英语面试、入职介绍等官方场景；成功时个人路线状态更新；失败时保持原路线并提示可重试。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-008` | 学习者将某个已加入场景设为当前学习场景；成功时首页和训练入口引用该场景；失败时不切换当前路线。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-009` | 学习者为已加入场景切换目标等级；成功时后续计划和训练入口使用新等级；若该等级无可用内容，展示不可用状态并保留原等级或提供退回选择。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |

Boundary note:

- 官方内容的搜索、筛选、排序和目录浏览归入 `CAP-CONTENT`；`CAP-INTENT` 只承接用户把内容选择转化为个人学习路线、当前场景和目标等级的状态变化。

### US-INTENT-003 - 学习者维护完整目标生命周期

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-003` | 作为学习者，当我的学习目标发生变化或暂时不再适用时，我希望设置目标水平、期限和成功标准，并暂停、恢复或归档目标，以便学习路线和后续计划始终反映当前真实目标状态。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-010` | 学习者从目标设置页补充目标水平、期限和成功标准；成功时形成可追踪目标定义；输入无效或保存失败时保留原目标状态。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-011` | 学习者暂停、恢复或归档学习目标；成功时目标生命周期状态更新并展示对路线入口的影响；失败时目标状态保持不变。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-012` | 学习者查看目标支持状态和原因；成功时知道目标当前是 supported、partial 还是 unsupported；状态不可用时展示保守提示，不误导用户进入不可练流程。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |

### US-INTENT-004 - 学习者设置学习方式与反馈偏好

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-004` | 作为学习者，当我调整自己的学习方式时，我希望设置练习形式、反馈深度、纠错频率以及语音或文本优先偏好，以便后续练习和反馈更贴近我当前愿意采用的学习方式。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-013` | 学习者设置练习形式偏好，例如听、说、读、写或混合练习；成功时偏好被保存供后续路线和训练引用；保存失败时保留原偏好。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-INTENT-014` | 学习者设置反馈深度和纠错频率；成功时后续反馈入口能引用该偏好；无效设置或保存失败时展示可恢复提示。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-INTENT-015` | 学习者设置语音或文本优先偏好；成功时系统在可用练习入口中展示匹配的默认方式；对应方式不可用时展示替代路径。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

### US-INTENT-005 - 学习者维护时间约束

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-005` | 作为学习者，当我的可学习时间和投入强度变化时，我希望维护每日/每周投入、学习强度、可学习时间段和不可用时段，以便后续计划和提醒不会基于错误时间约束。 | `draft` | `CAP-INTENT` | `CAP-PLAN`, `CAP-ENGAGE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-016` | 学习者设置每日/每周投入和学习强度；成功时形成可用于计划的时间约束；输入无效或保存失败时不生成错误约束。 | `draft` | `CAP-INTENT` | `CAP-PLAN`, `CAP-ENGAGE` |
| `VS-INTENT-017` | 学习者设置可学习时间段和不可用时段；成功时后续计划和提醒可引用这些时间窗口；冲突或保存失败时展示可恢复提示并保留原设置。 | `draft` | `CAP-INTENT` | `CAP-PLAN`, `CAP-ENGAGE` |

## 4. 学习计划与计划版本（CAP-PLAN / learning-plan-version）

### US-PLAN-001 - 学习者在首页找到当前最该继续的学习入口

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-001` | 作为学习者，当我进入首页查看今日学习状态时，我希望看到情景学习、推荐表达和我的三个主入口，并优先看到未完成会话、到期复习、薄弱表达或下一条未掌握表达，以便直接继续当前最该做的练习。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-001` | 当学习者进入首页时，系统展示情景学习、推荐表达和我的入口；成功时学习者知道当前 MVP 的核心流程；加载失败时展示可恢复状态。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |
| `VS-PLAN-002` | 当存在未完成训练会话时，首页优先展示继续入口；成功时学习者可回到同一场景同一等级继续；状态不可用时不错误提示可恢复会话。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |
| `VS-PLAN-003` | 当存在到期复习、薄弱表达或下一条未掌握表达时，首页展示对应入口；成功时学习者能直接进入相关训练；无任务时展示清晰空状态。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |
| `VS-PLAN-004` | 当学习者已有当前官方场景和目标等级时，首页入口展示对应场景上下文；成功时学习者知道下一步练什么；路线信息不可用时展示选择场景入口。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |

### US-PLAN-002 - 学习者获得可解释的学习计划版本

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-002` | 作为学习者，当我完成当前水平和目标偏好设置后，我希望看到一个可解释的日/周学习计划版本，包含当前水平到目标的差距、计划训练项、优先级、时间约束和复习安排，以便知道今天为什么练这些内容。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-005` | 学习者从计划页查看当前水平与目标之间的差距说明；成功时看到能力差距和阶段差距摘要；差距数据不可用时展示需要补充水平或目标的信息。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |
| `VS-PLAN-006` | 学习者生成或查看当前日计划和周计划；成功时看到计划版本、计划周期和计划训练项清单；生成失败时展示可恢复状态，不替换已有计划。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-PLAN-007` | 学习者查看某个计划训练项的训练对象、预期时长、完成规则和计划原因；成功时知道该项为何被安排；引用内容不可用时展示替代入口或不可用状态。 | `draft` | `CAP-PLAN` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-PLAN-008` | 学习者查看计划优先级和时间约束解释；成功时理解计划如何引用目标、能力重点和可用时间；解释不可用时保留计划但不展示无依据结论。 | `draft` | `CAP-PLAN` | `CAP-INTENT`, `CAP-LEVEL`, `CAP-MEMORY` |
| `VS-PLAN-009` | 学习者查看复习与记忆调度安排；成功时看到到期窗口、跨天安排和可进入的复习入口；记忆事实不足时展示暂无到期复习的空状态。 | `draft` | `CAP-PLAN` | `CAP-MEMORY`, `CAP-ENGAGE`, `CAP-TRAIN` |
| `VS-PLAN-010` | 学习者选择某个计划训练项并进入对应训练或复习入口；成功时系统把训练对象、训练流引用、预期时长、完成规则和计划来源交给后续入口；引用缺失或入口不可用时展示替代路径或不可用原因。 | `draft` | `CAP-PLAN` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-MEMORY` |

### US-PLAN-003 - 学习者处理计划变更和重算

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-003` | 作为学习者，当我的目标、水平、时间约束或学习事实发生变化时，我希望知道当前计划是否已经过期，并能触发重算、查看新旧差异或恢复已有计划版本，以便继续使用可信的学习安排。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-011` | 当目标、水平、时间约束或学习事实变化后，系统在计划页提示当前计划 stale 或需要重算；成功时学习者知道计划为何不再可信；判断不可用时保留原计划并提示稍后检查。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY`, `CAP-TRAIN` |
| `VS-PLAN-012` | 学习者触发计划重算后查看新旧计划差异；成功时看到训练项、优先级或时间安排的变化；重算失败时保留旧计划并允许重试。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY`, `CAP-TRAIN` |
| `VS-PLAN-013` | 学习者取消当前计划版本；成功时计划版本变为取消状态并展示当前无生效计划或替代入口；取消失败时保持原计划生效状态。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-PLAN-014` | 学习者恢复一个可恢复的计划版本；成功时该计划重新成为可用计划并展示恢复后的下一步入口；恢复失败或版本不可恢复时保持当前状态并说明原因。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-PLAN-015` | 学习者用新计划版本替换当前计划；成功时系统展示新生效版本和旧版本状态；替换失败时保留原计划并允许返回或重试。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY` |

### US-PLAN-004 - 学习者查看阶段检查点与达标预测

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-004` | 作为学习者，当我想确认当前学习是否按计划推进时，我希望查看阶段检查点、达标预测和风险解释，以便判断是否需要调整目标、投入或学习节奏。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-016` | 学习者从计划页查看阶段检查点；成功时看到阶段目标、当前进展和下一检查点；检查点不可用时展示需要更多学习事实或目标信息。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |
| `VS-PLAN-017` | 学习者查看达标预测和风险解释；成功时知道当前风险来自时间、进度或能力差距；预测不可用时展示不确定状态，不承诺达标结果。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |

## 5. 内容资产（CAP-CONTENT / content-curriculum-scenario）

### US-CONTENT-001 - 学习者浏览并理解官方职场场景

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-001` | 作为学习者，当我浏览可练内容时，我希望看到英语面试和入职介绍两个官方场景，并能查看场景简介、标签、目标等级、表达数量和内容可用状态，以便判断哪个真实职场场景适合加入学习。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-001` | 当学习者进入情景学习入口时，系统展示英语面试和入职介绍两个官方场景；成功时学习者能选择真实可练的职场场景；无内容时展示空状态。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-002` | 学习者打开场景详情后，可以看到简介、场景标签和适用目标；成功时能判断场景是否符合当前目标；加载失败时展示重试入口。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-003` | 场景详情展示目标等级、表达数量和内容可用状态；成功时学习者能判断是否加入学习；内容状态不可用时展示保守提示，不伪造学习状态。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-004` | 学习者从场景详情进入可训练内容上下文；成功时系统展示后续练习可引用的对话、表达或训练对象摘要；内容版本不可用时展示可恢复提示。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Boundary note:

- 用户学习进度不归入 `CAP-CONTENT`；内容页如需展示进度，只能引用 `CAP-MEMORY`、`CAP-TRAIN` 或 `CAP-PLAN` 的外部只读摘要，不把进度状态作为内容资产自身行为。

### US-CONTENT-002 - 学习者查看场景表达与训练素材

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-002` | 作为学习者，当我进入已选择的官方场景时，我希望看到该场景中的对话、表达、候选人台词和可练素材摘要，以便理解后续听力热身、表达练习和语音模拟会围绕哪些内容展开。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-005` | 学习者进入场景素材页后，系统展示完整场景对话和角色信息；成功时学习者能理解语境；内容缺失时展示空状态并阻止进入依赖该素材的练习。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-CONTENT-006` | 学习者查看场景中的表达、句型或关键短语清单；成功时知道后续会练哪些表达；加载失败时展示重试提示。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-CONTENT-007` | 学习者查看候选人台词与训练对象的对应关系；成功时能理解跟读和语音模拟的练习对象；关系不可用时不进入需要该关系的训练流。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

### US-CONTENT-003 - 学习者浏览完整官方内容目录

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-003` | 作为学习者，当我从首页、内容入口或学习路线选择内容时，我希望按目录、等级、主题或课程路径浏览官方内容，并能搜索、筛选和排序，以便找到适合当前目标和能力状态的可练课程。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-008` | 学习者按目录、等级、主题或课程路径浏览官方内容；成功时看到可进入的内容集合；无内容时展示空状态和返回入口。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-COM` |
| `VS-CONTENT-009` | 学习者搜索、筛选或排序官方内容；成功时看到匹配结果和清除条件入口；无结果、筛选条件冲突或加载失败时展示可恢复状态。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-COM` |
| `VS-CONTENT-010` | 学习者打开不可用、无权限、下架或暂不支持的官方内容时，系统展示明确状态和可返回路径；成功时学习者知道为何不能继续，而不误以为内容已加入路线。 | `draft` | `CAP-CONTENT` | `CAP-COM`, `CAP-INTENT`, `CAP-PLAN` |

### US-CONTENT-004 - 学习者理解课程条目与训练流

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-004` | 作为学习者，当我打开一个官方课程或场景条目时，我希望理解课程定义、预计时长、能力标签、适用人群、学习活动规划、训练对象、练习单元和训练流状态，以便确认该课程能如何被练习、训练和复习引用。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-011` | 学习者查看课程定义、预计时长、能力标签和适用人群；成功时能判断课程是否适合自己；字段缺失或加载失败时展示保守状态。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN`, `CAP-COM` |
| `VS-CONTENT-012` | 学习者查看课程内学习活动规划；成功时知道课程包含哪些学习活动和大致顺序；规划不可用时不承诺可进入完整训练。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-013` | 学习者查看训练对象、练习单元和训练流可用状态；成功时知道哪些对象可被练习、训练或复习引用；训练流不可用时展示不可进入原因。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-014` | 学习者查看内容版本、更新时间或内容不可用提示；成功时知道当前内容是否仍可用于后续练习；版本冲突或下架时展示替代入口。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN`, `CAP-COM` |

## 6. 练习会话与互动（CAP-PRACTICE / practice-session-runtime）

### US-PRACTICE-001 - 学习者完成听力热身和跟读练习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-001` | 作为学习者，当我进入具体场景练习前，我希望先播放完整场景对话，并能上一句/下一句切换、暂停、循环播放或切换到跟读模式录制候选人台词，以便熟悉语境、回答节奏并获得基础完整度或发音反馈。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-001` | 学习者进入听力热身后播放完整场景对话；成功时熟悉语境和回答节奏；音频或文本不可用时展示可恢复错误。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-002` | 学习者上一句/下一句切换、暂停或循环播放；成功时能按自己的节奏听；控制失败时保持当前播放状态并提示重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-003` | 学习者切换到跟读模式并录制候选人台词；成功时生成跟读输入；麦克风不可用、录制失败或中断时展示可恢复提示。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-004` | 跟读提交后系统展示完整度或发音反馈；成功时学习者知道是否需要重读；反馈不可用时保留录音结果并提示稍后重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

### US-PRACTICE-002 - 学习者完成表达小任务

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-002` | 作为学习者，当我处理推荐表达或场景中的练习单元时，我希望完成选择题、填空、意图回忆、接下句、替换槽位、变体改写、流利挑战或跟读等小任务，以便逐步把表达练成自己的话。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-005` | 学习者进入对应练习单元并提交答案；成功时获得练习结果摘要；答案无效、题目不可用或提交失败时展示可恢复状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-006` | 学习者根据语境补全下一句或替换表达槽位；成功时系统记录作答结果；失败时保留当前题目并允许重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-007` | 学习者提交表达变体改写；成功时看到结果摘要或反馈入口；评估不可用时不错误推进掌握状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-008` | 学习者完成限时或语音类表达练习；成功时生成练习结果摘要；录音、计时或提交失败时展示可恢复提示。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

### US-PRACTICE-003 - 学习者完成语音模拟回答

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-003` | 作为学习者，当我按场景和目标等级进入语音模拟时，我希望查看当前目标进度和场景导航，卡住时请求提示，录音后自动转写并提交回答，以便练习真实口语输出并进入后续反馈。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-009` | 学习者从官方场景和目标等级进入语音模拟；成功时系统展示当前问题和练习上下文；入口状态不可用时展示可恢复提示。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |
| `VS-PRACTICE-010` | 语音模拟页展示当前目标进度、场景导航和本轮正在练的表达；成功时学习者知道当前练习位置；进度不可用时展示保守状态。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |
| `VS-PRACTICE-011` | 学习者在当前问题卡住时请求提示；成功时系统给出可帮助继续回答的提示；提示不可用时允许继续作答或跳过。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |
| `VS-PRACTICE-012` | 学习者录音后系统自动转写并提交回答；成功时生成练习输入并进入反馈流程；录音、转写或提交失败时展示可恢复错误，不推进本题完成状态。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |

### US-PRACTICE-004 - 学习者完成课程内文本与听写专项练习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-004` | 作为学习者，当我进入包含听写或文本输入节点的课程内容时，我希望按课程节点完成听写、文本输入和专项练习提交，以便在具体课程语境中产出可交接的练习结果摘要。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-013` | 学习者从课程节点进入听写练习并提交听写内容；成功时生成听写作答记录和结果摘要；音频、题目或提交不可用时展示可恢复错误。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-014` | 学习者从课程节点进入文本输入练习并提交回答；成功时生成文本作答记录和结果摘要；输入无效或提交失败时保留当前题目并允许重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-015` | 学习者完成课程内专项练习后查看本次互动结果摘要；成功时知道本节点是否完成以及可进入的下一步；结果摘要不可用时不错误推进练习状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

### US-PRACTICE-005 - 学习者完成连续 AI 对话练习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-005` | 作为学习者，当我进入 AI 对话练习时，我希望看到当前对话上下文，并通过文本或语音连续多轮提交输入，以便围绕同一场景完成可追踪的对话互动练习。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-016` | 学习者从练习单元、场景内容或主动入口进入 AI 对话练习；成功时看到对话目标、上下文和可用输入方式；上下文不可用时展示可恢复状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-017` | 学习者在同一 AI 对话中提交多轮文本或语音输入；成功时对话记录和本轮互动状态更新；提交失败、转写失败或回复不可用时允许重试或保留当前轮次。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-018` | 学习者中断、重试、恢复或结束 AI 对话练习；成功时看到对话练习状态和结果摘要入口；状态损坏或过期时展示重新开始或返回路径。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

## 7. 技能训练编排与自动化（CAP-TRAIN / skill-training-automation）

### US-TRAIN-001 - 学习者完成官方场景练习后理解训练结果

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-001` | 作为准备职场英语场景表达的学习者，在已选择官方场景并完成一轮语音场景练习后，我希望看到包含本轮掌握、总进度、遗忘曲线、薄弱标签、下轮重点和关键反馈的清晰总结，以便知道这次练习是否有效、哪些表达需要继续巩固，以及下一步该回到哪里继续学习。 | `approved` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-001` | 当学习者从官方场景模拟页完成当前一轮语音练习并触发结束动作时，系统给出本轮练习总结和可见的后续学习入口；成功时学习者看到本轮总结、关键反馈和进度变化；失败或无可用结果时学习者看到可恢复的错误或空状态，且进度不会被错误推进；产品状态变化为本轮练习完成状态与学习证据候选被记录。 | `approved` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-002` | 当本轮训练结果可用时，系统展示本轮掌握、薄弱标签和下轮重点；成功时学习者知道哪些表达需要继续巩固；无可用结果时展示空状态，不生成错误结论。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-003` | 当训练结果可交接给学习事实时，系统展示总进度和遗忘曲线摘要；成功时学习者能观察进度变化；状态更新失败时保持原进度并提示重试。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-004` | 学习者在总结页选择继续练习、复习薄弱表达或返回首页；成功时进入对应入口；入口不可用时展示替代路径。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-002 - 已加入场景的学习者完成推荐表达队列训练

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-002` | 作为已加入场景的学习者，当我进入推荐表达页处理今日训练时，我希望看到每日表达队列，并围绕复习、薄弱和表达变体依次完成训练，以便持续把表达练成自己的话。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-005` | 当已加入场景的学习者进入推荐表达页时，系统展示每日表达队列及每条表达的训练原因；成功时学习者知道今天要练什么；无队列时展示空状态和回到场景入口。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-006` | 学习者选择队列中的表达或点击继续；成功时系统交接到对应练习单元；练习素材不可用时展示可恢复提示。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-007` | 学习者完成表达小任务后，队列更新复习、薄弱、变体或完成状态；成功时学习者看到队列进度；更新失败时不错误标记完成。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-008` | 当每日表达队列完成或无更多可练项时，系统展示下一步入口；成功时学习者可返回首页、继续场景或查看复盘；状态不可用时展示保守提示。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-003 - 中途退出的学习者恢复未完成训练会话

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-003` | 作为中途退出的学习者，当我下次进入同一场景同一等级时，我希望恢复未完成会话，以便不用从头开始并继续完成上次中断的练习。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-009` | 当学习者再次进入场景时，系统检查是否存在可恢复会话；成功时展示继续入口；状态不可用时不展示错误恢复入口。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-010` | 学习者选择继续后，系统恢复当前问题、目标进度和场景导航；成功时可继续练习；恢复失败时允许从头开始或返回首页。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-011` | 当未完成会话过期、内容版本变化或状态损坏时，系统展示原因和替代入口；成功时学习者知道可以重新开始或选择其他任务。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-004 - 学习者在训练中处理节奏与状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-004` | 作为正在训练的学习者，当我需要暂停、继续、跳过、重做或处理不可用内容时，我希望训练会话清楚展示当前练习单元状态和可选动作，以便不中断学习控制权并避免错误推进训练进度。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-012` | 学习者在训练会话中暂停并稍后继续；成功时当前计划训练项、训练流位置和练习单元游标可恢复；暂停或继续失败时展示可恢复提示。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-013` | 学习者对当前练习单元选择跳过、重做或重新开始；成功时练习单元状态和训练节奏更新；操作失败时保持原状态并允许继续当前练习。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-014` | 当训练流内容不可用或需要 fallback 时，系统展示原因和替代训练入口；成功时学习者能继续其他可用训练；无替代入口时展示可返回状态。 | `draft` | `CAP-TRAIN` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-PLAN` |
| `VS-TRAIN-015` | 学习者查看计划训练项或练习单元的部分完成、中断、失败或 stale 状态；成功时知道下一步可继续、重试、重算或返回；状态不可用时不错误标记完成。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-005 - 学习者从计划训练项进入可解释训练会话

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-005` | 作为学习者，当我从学习计划选择一个计划训练项时，我希望进入训练前看到训练来源、完成规则、训练对象和可用训练流，以便知道这次训练为什么出现以及如何完成。 | `draft` | `CAP-TRAIN` | `CAP-PLAN`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-016` | 学习者从计划训练项进入训练会话入口；成功时看到计划来源、训练对象、训练流引用、预期时长和完成规则；入口加载失败时可返回计划页。 | `draft` | `CAP-TRAIN` | `CAP-PLAN`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-MEMORY` |
| `VS-TRAIN-017` | 当训练对象或训练流不可用时，训练入口展示不可用原因和替代入口；成功时学习者可选择其他可练项、返回计划或等待内容恢复。 | `draft` | `CAP-TRAIN` | `CAP-PLAN`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-MEMORY` |

## 8. AI 教练、反馈与评估（CAP-COACH / ai-coach-feedback-assessment）

### US-COACH-001 - 学习者获得并复查教练反馈

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COACH-001` | 作为学习者，当我提交语音模拟或表达练习回答后，我希望看到教练反馈、重试建议、表达建议或下一问题，并能播放或翻译教练消息、播放自己的语音回答，以便知道下一步怎么改并复查听说效果。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COACH-001` | 学习者提交回答后，系统展示教练反馈、关键问题和表现亮点；成功时学习者知道当前回答质量；反馈生成失败时展示可恢复提示。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-002` | 当反馈可用时，系统给出重试建议、替代表达或下一问题入口；成功时学习者知道下一步怎么改；建议不可用时仍保留基础反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-003` | 学习者播放或翻译教练消息；成功时能复查听说效果；播放、翻译或音频不可用时展示可恢复提示。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-004` | 学习者回放自己的语音回答；成功时能复查发音和表达；录音不可用时展示空状态，不影响文本反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-005` | 当反馈、纠错或评分信号可用时，系统交接给训练节奏和学习证据候选；成功时后续练习可引用；交接失败时不错误推进掌握状态。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

### US-COACH-002 - 学习者理解评分和评估依据

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COACH-002` | 作为学习者，当我查看一次练习反馈时，我希望看到发音、流利度、完整度、表达质量和任务完成度等评分信号，以及 rubric、证据、扣分原因和不确定性说明，以便理解反馈依据而不是只看到结论。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COACH-006` | 学习者在反馈详情中查看发音、流利度、完整度、表达质量和任务完成度等评分信号；成功时知道各维度表现；评分不可用时展示原因而不是空泛结论。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-007` | 学习者查看纠错原因、rubric 和证据片段；成功时知道反馈依据来自哪些回答内容；证据不足或不可展示时说明限制。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-008` | 当评估存在不确定性或反馈不可用时，系统展示不确定性或不可用状态；成功时学习者知道是否应重试、稍后查看或继续下一步。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

### US-COACH-003 - 学习者使用纠错建议改进回答

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COACH-003` | 作为学习者，当教练指出我的回答问题时，我希望看到语法、词汇、表达、发音和任务完成度相关纠错建议，并能基于建议重试后比较结果，以便把反馈转化为下一次可执行改进。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COACH-009` | 学习者查看语法、词汇、表达、发音或任务完成度纠错建议；成功时看到可执行改法和更自然表达；建议不可用时保留基础反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-COACH-010` | 学习者依据纠错建议发起重试并比较新旧反馈摘要；成功时知道重试是否改善；重试结果不可用时展示可恢复提示，不覆盖原反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY` |

## 9. 学习事实、进度与复盘（CAP-MEMORY / learning-facts-progress-review）

### US-MEMORY-001 - 学习者用练习结果聚焦后续学习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-001` | 作为学习者，当我完成表达或场景练习后，我希望掌握表达、薄弱表达、复习状态和个人素材能影响后续首页或推荐表达，以便之后的练习更聚焦于真正需要巩固的内容。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-001` | 当训练会话产生练习结果摘要或反馈信号时，系统记录学习证据候选；成功时后续状态可引用；失败时不更新掌握或薄弱状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-002` | 当证据被接受后，系统更新表达的掌握或薄弱状态；成功时后续入口能引用；证据不足时保持原状态并标记不确定。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-003` | 当表达需要复习或存在遗忘风险时，系统更新复习到期状态；成功时首页或推荐表达可提示；计算不可用时不生成错误提醒。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-004` | 当收藏、个人表达或学习素材可被引用时，系统将其作为后续推荐或复习依据；成功时学习者看到更聚焦的任务；不可用时不阻断基础训练入口。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

### US-MEMORY-002 - 学习者回顾长期学习结果

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-002` | 作为学习者，当我进入个人中心回顾学习沉淀时，我希望看到学习概览、收藏摘要、技能分布、学习历史、学习报告入口和已完成场景入口，以便理解长期学习结果并回到相关学习证据。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-005` | 学习者进入个人中心后，系统展示学习概览和技能分布；成功时能理解长期进展；数据不可用时展示空状态。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-006` | 学习者打开学习历史入口；成功时看到练习、复习和场景完成记录；加载失败时允许重试，不误报历史为空。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-007` | 学习者看到学习报告入口和可用状态；成功时可进入报告；报告不可用时展示原因，不承诺完整报告已生成。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-008` | 学习者查看已完成场景入口；成功时能回到相关场景结果；状态不可用时展示可恢复提示。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-009` | 学习者在个人中心看到收藏摘要；成功时能进入收藏页复看；收藏状态不可用时展示保守提示。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |

### US-MEMORY-003 - 学习者查看可追溯学习历史

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-003` | 作为学习者，当我回顾自己学过什么时，我希望按时间查看练习、复习、跳过和中断记录，并能看到记录来源、关联场景和表达，以便追溯学习事实来自哪里。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-010` | 学习者从学习历史入口查看按时间排序的练习、复习、跳过和中断记录；成功时看到发生时间和记录类型；历史不可用时展示可恢复状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-011` | 学习者打开一条学习历史记录查看来源引用、关联场景、表达或练习单元；成功时知道该事实来自哪个训练或反馈；来源缺失时展示不完整状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

### US-MEMORY-004 - 学习者查看复盘和学习报告

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-004` | 作为学习者，当我想复盘近期学习效果时，我希望看到每日学习总结卡、单次练习复盘、阶段报告和报告依据，以便理解实际完成、进度变化和后续需要关注的学习事实。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-012` | 学习者查看每日学习总结卡；成功时看到当天完成、复习、薄弱或中断摘要；当天无记录时展示空状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-013` | 学习者查看单次练习复盘；成功时看到本次练习的可追溯事实、反馈摘要和后续入口；复盘依据不足时展示不完整状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-014` | 学习者查看阶段报告和依据；成功时看到阶段内学习事实、进度口径和变化原因；依据不足时展示需要更多学习记录。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-015` | 当学习报告不可用或生成不足时，系统展示原因和后续可补充路径；成功时学习者知道为什么暂时没有报告；状态不可用时允许稍后重试。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

## 10. 笔记、词汇与个人素材（CAP-NOTE / notebook-vocabulary-assets）

### US-NOTE-001 - 学习者收藏并复看有用表达

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-001` | 作为学习者，当我在练习或浏览表达时，我希望收藏或取消收藏表达，并在收藏页看到去重后的收藏表达，以便复看真正有用的表达并删除不再需要的收藏。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-001` | 学习者在表达卡片、推荐表达或练习结果中收藏表达；成功时表达进入个人收藏集合；失败时展示可恢复提示。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-002` | 学习者取消收藏表达；成功时收藏集合更新；失败时保持原收藏状态并允许重试。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-003` | 学习者进入收藏页后，系统展示去重后的收藏表达；成功时可复看真正有用的表达；无收藏时展示空状态。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-004` | 学习者从收藏页删除不需要的表达；成功时列表和摘要更新；失败时不误删收藏。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-005` | 当收藏表达可被记忆能力引用时，系统将其作为个人素材候选；成功时后续复习或推荐可引用；引用失败时不影响收藏本身。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |

### US-NOTE-002 - 学习者管理个人词汇和表达资产

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-002` | 作为学习者，当我遇到想沉淀的单词、短语、句型或表达时，我希望保存它们并查看释义、来源、例句和表达变体，以便形成可复用的个人语言素材。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-006` | 学习者从练习、内容详情或个人入口新增或保存词汇、短语；成功时个人词汇资产创建或更新；保存失败时保留原页面状态并允许重试。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |
| `VS-NOTE-007` | 学习者打开个人词汇或短语条目查看释义、来源和例句；成功时知道素材来自哪里以及如何使用；来源缺失时展示不完整状态。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |
| `VS-NOTE-008` | 学习者保存句型模板或表达变体；成功时模板或变体进入个人表达资产；保存失败、重复或格式无效时展示可恢复提示。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |

### US-NOTE-003 - 学习者记录和管理学习笔记

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-003` | 作为学习者，当我需要记录自己的理解、例句或场景备注时，我希望新增、编辑、删除学习笔记并添加场景标签，以便把个人理解和官方内容或练习经历关联起来。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-009` | 学习者从内容、练习结果或个人素材入口新增学习笔记；成功时笔记条目保存并可在个人素材中找到；保存失败时展示可恢复提示。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |
| `VS-NOTE-010` | 学习者编辑或删除学习笔记；成功时笔记内容或删除状态更新；失败时保持原笔记不变并说明原因。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |
| `VS-NOTE-011` | 学习者为学习笔记添加或调整场景标签；成功时笔记可按标签被检索或归类；标签保存失败时保留原标签状态。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |

### US-NOTE-004 - 学习者检索和整理个人素材

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-004` | 作为学习者，当我的个人词汇、表达、笔记和收藏逐渐增多时，我希望搜索、筛选、排序、批量管理、归档或软删这些素材，并从素材发起复用意图，以便持续整理和复用自己的语言资产。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-012` | 学习者在个人素材页搜索、筛选或排序词汇、表达、笔记和收藏；成功时看到匹配结果；无结果时展示清除条件或新增素材入口。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |
| `VS-NOTE-013` | 学习者批量管理、归档或软删个人素材；成功时素材状态更新并可被筛选查看；操作失败时不误删素材并允许重试。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |
| `VS-NOTE-014` | 学习者从个人素材发起复习或训练意图；成功时系统展示可交接给计划或训练的入口；素材不可用或入口不可用时展示原因，不直接启动未定义训练流程。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |

## 11. 会员、商业化与权益（CAP-COM / membership-commerce-entitlement）

### US-COM-001 - 学习者查看会员方案并管理购买入口

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COM-001` | 作为学习者，当我需要了解订阅或权益入口时，我希望查看会员方案、发起购买或恢复购买，以便理解当前可用的订阅入口和权益获取方式。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COM-001` | 学习者进入会员入口后，系统展示会员方案和权益说明；成功时学习者理解可购买内容；加载失败时展示可恢复提示。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-002` | 学习者选择会员方案并发起购买；成功时进入购买流程状态；失败、取消或购买入口暂不可用时展示可恢复提示。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-003` | 学习者选择恢复购买；成功时系统展示恢复结果或当前订阅状态；失败时说明原因并允许重试。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-004` | 学习者查看当前订阅入口或权益状态摘要；成功时知道是否已拥有对应权益；状态不可用时不错误授予或撤销权益。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

### US-COM-002 - 学习者在受限功能前理解权益限制

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COM-002` | 作为学习者，当我访问会员限定内容、额度受限练习或高级反馈时，我希望在继续前理解当前权益限制、升级选择和可用免费路径，以便决定升级、等待额度恢复或返回可用功能。 | `draft` | `CAP-COM` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COM-005` | 学习者访问受限功能时看到付费墙和权益说明；成功时知道该限制对应哪个会员权益；权益状态不可用时不错误放行或阻断。 | `draft` | `CAP-COM` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-006` | 学习者在用量耗尽时看到升级、等待恢复或查看额度说明；成功时知道下一步选择；额度状态不可用时展示保守提示。 | `draft` | `CAP-COM` | `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-007` | 学习者无权益时可返回、升级或继续免费路径；成功时不会被困在受限流程；可用路径加载失败时展示返回入口。 | `draft` | `CAP-COM` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

### US-COM-003 - 学习者管理订阅生命周期

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COM-003` | 作为已订阅或曾订阅的学习者，当我进入会员与订阅页面时，我希望查看当前计划、到期、宽限、退款、恢复和降级状态，并能进入取消或管理订阅入口，以便理解订阅变化对权益的影响。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COM-008` | 学习者查看当前计划、到期时间、宽限、退款或恢复状态；成功时知道当前订阅是否可用；状态不可用时展示保守提示，不错误授予或撤销权益。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-009` | 学习者进入取消订阅或管理订阅入口；成功时看到可继续处理订阅的路径；入口不可用或订阅管理状态暂不可确认时展示说明和返回路径。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-010` | 学习者在订阅降级、过期或权益变化后查看权益变化说明；成功时知道哪些功能仍可用、哪些受限；说明不可用时不误导用户继续受限功能。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

## 12. 参与、通知与留存（CAP-ENGAGE / engagement-notification-retention）

### US-ENGAGE-001 - 学习者配置每日学习提醒

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-001` | 作为学习者，当我设置学习节奏时，我希望设置每日提醒时间和开关，以便按自己的安排接收练习提醒。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-001` | 学习者进入提醒设置后，系统展示当前每日提醒时间、开关和权限状态；成功时学习者知道当前提醒配置；加载失败时展示可恢复提示。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-002` | 学习者设置每日提醒时间；成功时提醒时间保存；无效时间或保存失败时展示可恢复提示。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-003` | 学习者切换每日提醒开关；成功时开关状态更新；权限不足或保存失败时展示说明，不误报已开启。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-004` | 当存在到期复习或计划提醒时，系统让提醒配置引用这些任务；成功时学习者能按节奏收到提醒；无任务时保留提醒偏好但不生成虚假提醒。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

### US-ENGAGE-002 - 学习者管理触达偏好

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-002` | 作为学习者，当我配置学习触达方式时，我希望管理提醒、push、邮件和活动触达偏好，并看到权限不足时的影响和开启路径，以便按自己接受的方式接收学习提示。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-005` | 学习者设置 push、邮件或活动触达偏好；成功时偏好保存并展示当前触达方式；保存失败时保留原偏好并允许重试。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-006` | 当触达权限不足或触达方式不可用时，系统展示影响说明和开启路径；成功时学习者知道哪些提醒无法送达；状态不可用时不误报已开启。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

### US-ENGAGE-003 - 学习者保持连续学习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-003` | 作为学习者，当我持续完成学习时，我希望看到连续学习状态和完成学习后的轻量反馈，以便知道自己是否保持节奏并获得继续学习的可见提示。 | `draft` | `CAP-ENGAGE` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-007` | 学习者查看连续学习状态；成功时看到连续天数、今日是否已计入和状态说明；状态不可用时展示保守提示。 | `draft` | `CAP-ENGAGE` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-ENGAGE-008` | 学习者完成一次有效学习后看到连续学习反馈；成功时知道本次学习是否影响连续状态；反馈不可用时不错误改变连续状态。 | `draft` | `CAP-ENGAGE` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |

### US-ENGAGE-004 - 中断学习者恢复学习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-004` | 作为一段时间未学习的学习者，当我回到 App 或从提醒入口进入时，我希望看到恢复学习入口并回到上次相关学习上下文，以便不用重新判断从哪里继续。 | `draft` | `CAP-ENGAGE` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-009` | 学习者回流后看到恢复学习入口；成功时入口说明上次可继续的计划、训练或复习上下文；上下文不可用时展示替代学习入口。 | `draft` | `CAP-ENGAGE` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-ENGAGE-010` | 学习者从提醒或召回入口回到上次学习上下文；成功时进入对应计划、训练或复习入口；入口失效时展示返回首页或选择其他任务。 | `draft` | `CAP-ENGAGE` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

### US-ENGAGE-005 - 学习者参与活动或挑战

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-005` | 作为学习者，当产品提供学习活动或挑战时，我希望看到活动入口、参与状态和不可用原因，以便判断是否可以加入当前活动或返回常规学习路径。 | `draft` | `CAP-ENGAGE` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-011` | 学习者查看活动或挑战入口和参与状态；成功时知道活动是否可参加、是否已参与或是否可继续；加载失败时展示可恢复提示。 | `draft` | `CAP-ENGAGE` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-COM` |
| `VS-ENGAGE-012` | 当活动不可用、已结束或学习者未满足参与条件时，系统展示明确状态和返回常规学习路径；成功时学习者不会误以为活动仍可参加。 | `draft` | `CAP-ENGAGE` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-COM` |

## Legacy 覆盖索引

- `启动、登录与首评`：覆盖到 `US-ACC-001`、`US-LEVEL-001`、`US-LEVEL-002`、`US-LEVEL-003`、`US-INTENT-001`、`US-INTENT-003`、`US-INTENT-004`、`US-INTENT-005`。
- `情景学习`：覆盖到 `US-PLAN-001`、`US-PLAN-002`、`US-PLAN-003`、`US-PLAN-004`、`US-CONTENT-001`、`US-CONTENT-002`、`US-CONTENT-003`、`US-CONTENT-004`、`US-INTENT-002`、`US-INTENT-003`。
- `听力热身与推荐表达`：覆盖到 `US-PRACTICE-001`、`US-PRACTICE-002`、`US-PRACTICE-004`、`US-TRAIN-002`、`US-TRAIN-004`、`US-TRAIN-005`、`US-NOTE-001`。
- `语音模拟与教练反馈`：覆盖到 `US-PRACTICE-003`、`US-PRACTICE-005`、`US-COACH-001`、`US-COACH-002`、`US-COACH-003`、`US-TRAIN-003`、`US-TRAIN-004`。
- `复盘、复习与个人结果`：覆盖到 `US-PLAN-002`、`US-PLAN-003`、`US-PLAN-004`、`US-TRAIN-001`、`US-MEMORY-001`、`US-MEMORY-002`、`US-MEMORY-003`、`US-MEMORY-004`、`US-NOTE-001`、`US-NOTE-002`、`US-NOTE-003`、`US-NOTE-004`。
- `我的与账号设置`：覆盖到 `US-ACC-002`、`US-ACC-004`、`US-ACC-005`、`US-ACC-006`、`US-ACC-007`、`US-ACC-008`、`US-ACC-009`、`US-COM-001`、`US-COM-002`、`US-COM-003`、`US-ENGAGE-001`、`US-ENGAGE-002`、`US-ENGAGE-003`、`US-ENGAGE-004`、`US-ENGAGE-005`。

## Ready Gate 记录

Assumptions:

- Product classification: `product-base-consolidation` / capability-organized story map normalization.
- Capability classification: 依据 `docs/product/feature_registry.md` 的 V2 Capability Table 做章节和边界映射；不从 Capability Registry 反推产品行为。
- Product behavior source: `docs/product/user_stories.md` legacy 清单和本次 PM 输入示例。
- 当前 registry 没有 `CAP-AUTH`；认证主流程暂纳入 `CAP-ACC`，后续如新增 `AUTH` capability 需迁移。
- 本轮产物优先解决可读性和信息覆盖，Child Vertical Slices 是 draft narrative；进入交付前仍需对选中的 Story/Slice 运行完整 ready gate。

Ready Gate Finding:

- Result: pass
- Narrative finding: Story Map 已按 V2 capability 章节组织；每个 User Story 都有可读叙事、明确 actor、场景、目标动作和用户可见价值；Child Vertical Slices 保留 legacy 行为细节，并补充成功、失败、空状态或状态保护意图。
- Metadata completeness finding: 每条 User Story 均包含用户指定的 `Status`、`Primary Capability ID` 和 `Affected Capability IDs`；每条 Child Vertical Slice 均有 ID、标题和闭环叙事。Child Vertical Slice 当前不是完整 ready-gate metadata 卡，选中进入下游前必须补齐完整 metadata 并单独 ready gate。
- Narrative/metadata consistency finding: Capability metadata 仅作为边界分类；用户行为均来自 legacy 清单或 PM 输入示例，没有把 capability 条目直接当需求来源。
- Ambiguity finding: 邮箱认证方式、`AUTH` capability 是否拆出、学习报告完整内容、推荐/复习算法、provider 实现和支付 provider 均保持为待澄清或 out of scope，不在本文中替下游决策。
- Split finding: 账号、首评、目标、计划、内容、练习、训练、教练、记忆、个人素材、商业和提醒已拆成独立用户价值区域；同一 Story 下的 slices 只表达该 Story 的子闭环。

PM Approval Required:

- PM approval: yes, for promoting any `draft` User Story or Vertical Slice to `approved` or downstream-consumable status.
- Downstream commitment: no. 任何 increment、FR、spec、AC、TC、contract 或实现工作仍需后续 PM execution brief 与对应下游 skill/agent 产物。
