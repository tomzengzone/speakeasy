## 1. 账号、身份资料与隐私（CAP-ACC / account-profile-privacy）

### US-ACC-001 - 手机号注册与短信验证码登录（P0）

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-001` | 作为用户，我想要使用手机号和短信验证码进行注册或登录，以便我可以快速获得账号并开始使用产品。 | `draft` | `CAP-ACC` | — |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-001` | 输入过程中实时校验手机号格式（位数、字符合法性），不合法时即时提示 | `draft` | `CAP-ACC` | — |
| `VS-ACC-002` | 默认使用中国区号（+86），手机号按 11 位规则校验 | `draft` | `CAP-ACC` | — |
| `VS-ACC-003` | 提供独立的「发送验证码」按钮，手机号格式不合法时该按钮置灰不可用 | `draft` | `CAP-ACC` | — |
| `VS-ACC-004` | 用户主动点击「发送验证码」按钮后才发送验证码，不自动触发发送 | `draft` | `CAP-ACC` | — |
| `VS-ACC-005` | 「发送验证码」点击后进入 60 秒倒计时，防止重复点击 | `draft` | `CAP-ACC` | — |
| `VS-ACC-006` | 验证码发送成功后，页面根据用户当前输入的手机号动态生成脱敏提示，例如手机号 13812341234 显示为“验证码已发送至 138****1234”，不得固定展示示例号码 | `draft` | `CAP-ACC` | — |
| `VS-ACC-007` | 验证码输入框仅允许数字，过滤非法字符 | `draft` | `CAP-ACC` | — |
| `VS-ACC-008` | 验证码位数校验（固定 6 位），未满足 6 位时提交按钮不可点击 | `draft` | `CAP-ACC` | — |
| `VS-ACC-009` | 支持短信验证码自动填充（Android OTP API / iOS 短信建议） | `draft` | `CAP-ACC` | — |
| `VS-ACC-010` | 验证码验证成功后，系统自动判断该手机号是否已注册 | `draft` | `CAP-ACC` | — |
| `VS-ACC-011` | 已注册账号直接登录，未注册自动创建新账号 | `draft` | `CAP-ACC` | — |
| `VS-ACC-012` | 用户无需手动选择"注册"或"登录" | `draft` | `CAP-ACC` | — |
| `VS-ACC-013` | 虚拟运营商号段（如 170/171/165/167 等）不直接拒绝，但标记为风险因子，由后端风控策略（US-110）决定是否触发额外验证 | `draft` | `CAP-ACC` | — |

### US-ACC-002 - 邮箱注册与登录（P0）

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-002` | 作为用户，我想要使用邮箱和邮件验证码进行注册或登录，以便在不使用手机号的情况下快速获得账号并开始使用产品。 | `draft` | `CAP-ACC` | — |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-014` | 用户进入邮箱验证码登录页面后，可看到邮箱输入框、验证码输入框、发送验证码按钮和提交按钮 | `draft` | `CAP-ACC` | — |
| `VS-ACC-015` | 用户输入邮箱过程中，系统实时校验邮箱基本格式，不合法时即时提示 | `draft` | `CAP-ACC` | — |
| `VS-ACC-016` | 系统自动移除邮箱首尾空格，避免因误输入空格导致校验失败 | `draft` | `CAP-ACC` | — |
| `VS-ACC-017` | 系统对邮箱域名部分进行大小写标准化，不因域名大小写差异识别为不同邮箱 | `draft` | `CAP-ACC` | — |
| `VS-ACC-018` | 邮箱为空或格式不合法时，「发送验证码」按钮置灰不可点击 | `draft` | `CAP-ACC` | — |
| `VS-ACC-019` | 用户主动点击「发送验证码」按钮后，系统才发送邮件验证码，不自动触发发送 | `draft` | `CAP-ACC` | — |
| `VS-ACC-020` | 用户点击发送验证码后，「发送验证码」按钮进入加载状态，防止请求过程中重复点击 | `draft` | `CAP-ACC` | — |
| `VS-ACC-021` | 验证码发送请求成功后，按钮进入 60 秒倒计时，倒计时结束后允许重新发送 | `draft` | `CAP-ACC` | — |
| `VS-ACC-022` | 验证码发送成功后，页面提示"验证码已发送至 t***@example.com"，脱敏展示目标邮箱 | `draft` | `CAP-ACC` | — |
| `VS-ACC-023` | 验证码发送成功后，页面提示用户检查收件箱和垃圾邮件文件夹 | `draft` | `CAP-ACC` | — |
| `VS-ACC-024` | 验证码发送失败时，页面提示发送失败，并允许用户重新发送 | `draft` | `CAP-ACC` | — |
| `VS-ACC-025` | 邮件服务返回频率限制时，页面提示操作过于频繁，并在限制时间内阻止再次发送 | `draft` | `CAP-ACC` | — |
| `VS-ACC-026` | 用户在倒计时结束后点击重新发送，系统向当前填写的邮箱发送新的验证码 | `draft` | `CAP-ACC` | — |
| `VS-ACC-027` | 新验证码发送成功后，之前发送但尚未使用的验证码立即失效 | `draft` | `CAP-ACC` | — |
| `VS-ACC-028` | 用户修改邮箱地址后，系统清空已输入的验证码，并使原邮箱验证码不可用于当前提交 | `draft` | `CAP-ACC` | — |
| `VS-ACC-029` | 验证码输入框仅允许输入数字，并过滤空格及其他非法字符 | `draft` | `CAP-ACC` | — |
| `VS-ACC-030` | 邮件验证码固定为 6 位，验证码不足 6 位时提交按钮不可点击 | `draft` | `CAP-ACC` | — |
| `VS-ACC-031` | 邮箱格式合法且验证码达到 6 位时，提交按钮进入可点击状态 | `draft` | `CAP-ACC` | — |
| `VS-ACC-032` | 用户点击提交后，按钮进入加载状态，防止重复提交验证请求 | `draft` | `CAP-ACC` | — |
| `VS-ACC-033` | 用户提交正确且仍在有效期内的验证码后，验证码验证成功 | `draft` | `CAP-ACC` | — |
| `VS-ACC-034` | 用户提交错误验证码后，页面提示"验证码错误"，并允许在剩余次数内重新输入 | `draft` | `CAP-ACC` | — |
| `VS-ACC-035` | 用户提交已过期验证码后，页面提示"验证码已过期"，并提供重新发送验证码入口 | `draft` | `CAP-ACC` | — |
| `VS-ACC-036` | 用户提交已经使用过或已被新验证码替换的验证码时，页面提示验证码已失效 | `draft` | `CAP-ACC` | — |
| `VS-ACC-037` | 验证码连续错误达到限制次数后，本次验证码失效，并要求用户重新获取验证码 | `draft` | `CAP-ACC` | — |
| `VS-ACC-038` | 验证码验证成功后，系统自动判断该邮箱是否已关联现有账号 | `draft` | `CAP-ACC` | — |
| `VS-ACC-039` | 邮箱已关联现有账号时，系统直接登录该账号 | `draft` | `CAP-ACC` | — |
| `VS-ACC-040` | 邮箱未关联任何账号时，系统自动创建新账号并完成登录 | `draft` | `CAP-ACC` | — |
| `VS-ACC-041` | 用户无需手动选择"注册"或"登录"，系统根据邮箱账号状态自动处理 | `draft` | `CAP-ACC` | — |
| `VS-ACC-042` | 新账号创建成功后，系统将当前邮箱标记为已验证邮箱 | `draft` | `CAP-ACC` | — |
| `VS-ACC-043` | 新账号创建失败时，系统不建立登录态，并提示用户稍后重试 | `draft` | `CAP-ACC` | — |
| `VS-ACC-044` | 登录成功后，系统建立有效登录态，并跳转至登录前目标页面或产品默认首页 | `draft` | `CAP-ACC` | — |
| `VS-ACC-045` | 登录态建立失败时，系统提示登录失败，并允许用户重新提交或重新获取验证码 | `draft` | `CAP-ACC` | — |
| `VS-ACC-046` | 系统对"邮箱未注册"和"邮箱已注册"的验证码发送结果使用一致提示，避免暴露账号是否存在 | `draft` | `CAP-ACC` | — |
| `VS-ACC-047` | 系统不因邮箱域名较少见而直接拒绝注册，但可将异常域名、临时邮箱域名等标记为风险因子，由后端风控策略 US-110 决定是否限制或触发额外验证 | `draft` | `CAP-ACC` | — |
| `VS-ACC-048` | 同一邮箱、设备或网络地址短时间内频繁发送验证码时，由后端风控策略 US-110 决定是否拦截或触发额外验证 | `draft` | `CAP-ACC` | — |
| `VS-ACC-049` | 邮件验证码验证成功后立即失效，不允许再次用于登录 | `draft` | `CAP-ACC` | — |
| `VS-ACC-050` | 用户离开页面后重新进入时，不恢复明文验证码内容 | `draft` | `CAP-ACC` | — |
| `VS-ACC-051` | 用户可返回并修改邮箱，修改后重新执行邮箱校验和验证码发送流程 | `draft` | `CAP-ACC` | — |

### US-ACC-003 - 已登录学习者查看账户中心并理解当前账户状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-003` | 作为已登录学习者，当我进入账户相关页面时，我希望看到当前账号身份、资料完整度、隐私授权、数据权利和安全设置入口，以便确认自己的账户状态并继续管理个人账户。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-052` | 当已登录学习者从“我的”或设置入口进入账户中心时，系统展示账户相关管理入口；成功时学习者能看到账号身份、基础资料、隐私、数据权利和安全设置入口；若账户信息加载失败，展示可恢复提示并允许重试。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |
| `VS-ACC-053` | 学习者进入账户中心后，可以看到当前账号的主要身份标识和已绑定登录方式摘要；成功时能判断手机号、邮箱、微信、Apple 等方式是否已绑定；失败时展示信息不可用状态，不允许误导用户认为绑定状态已改变。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |
| `VS-ACC-054` | 当账户存在资料未完善、隐私授权待确认、安全风险或数据权利请求处理中等状态时，账户中心展示明确提醒；成功时学习者知道需要处理什么；若状态不可用，展示保守的空状态或重试提示。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-ENGAGE`, `CAP-MEMORY` |

### US-ACC-004 - 已登录学习者管理账号身份与登录绑定方式

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-004` | 作为已登录学习者，我希望查看、绑定、更换或解除账号的身份凭证和登录方式，以便在设备更换、账号恢复或第三方账号变化时仍能安全访问自己的学习账户。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-055` | 当学习者进入账号身份设置页时，系统展示当前主账号标识、已绑定方式和可绑定方式；成功时学习者知道哪些方式可用于后续登录；若状态加载失败，展示重试提示且不允许执行绑定/解绑操作。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-056` | 学习者选择绑定手机号并完成验证码验证；成功时手机号成为当前账号的可用身份凭证；失败时展示手机号格式错误、验证码错误、验证码过期、号码已被其他账号占用或发送失败等可恢复状态。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-057` | 学习者在已有手机号的情况下发起更换，并完成必要身份确认和新手机号验证；成功时新手机号替代旧手机号；失败或中断时保持原手机号不变，并提示可重新尝试。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-058` | 学习者添加或更换邮箱，并完成明确的邮箱验证方式；成功时邮箱成为当前账号的可用身份凭证；失败时展示邮箱无效、验证失败、邮箱已被占用或验证过期等状态。这里需要产品上明确邮箱验证是“邮箱验证码”“邮箱链接”还是“邮箱密码”。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-059` | 学习者在账号身份设置中选择绑定或解除微信；成功时微信绑定状态更新；若微信不可用、授权取消、授权失败或解除后会导致账号无可用登录方式，系统展示阻断或可恢复提示。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-060` | 学习者在支持 Apple 登录的设备上绑定或解除 Apple；成功时 Apple 绑定状态更新；若设备不支持、授权取消、授权失败或解除后会导致账号不可登录，系统展示阻断或切换方式入口。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

### US-ACC-005 - 已登录学习者管理基础身份资料

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-005` | 作为已登录学习者，我希望查看和维护头像、昵称和基础个人信息，以便在 App 内形成稳定的个人身份展示，并确保账户资料保存失败时不会错误覆盖已有资料。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-061` | 当学习者进入基础资料页时，系统展示当前头像、昵称和基础个人信息字段；成功时学习者能确认当前资料；若资料加载失败，展示空状态或重试入口，且不改变已有资料。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |
| `VS-ACC-062` | 学习者修改头像或昵称并保存；成功时账户资料页和相关展示位置反映新资料；失败时展示格式、内容、上传或保存失败提示，并保持原资料不被错误覆盖。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |
| `VS-ACC-063` | 当基础资料字段缺失、部分字段暂不可编辑或内容不符合规则时，系统给出明确提示；成功时学习者知道哪些资料可以补全、哪些暂不能修改；失败时不应让用户误以为资料已保存。 | `draft` | `CAP-ACC` | `CAP-MEMORY` |

Boundary note:

- 学习目的、职业场景偏好和英语水平自评不归入 `CAP-ACC`；对应完整流程由 `CAP-INTENT` 和 `CAP-LEVEL` 承接，账户资料不提供可下游消费的 Story/VS。
- 通用显示主题、语言、音频等 App 体验偏好不归入 `CAP-ACC`；在 PM 确认设置类 capability 或 registry 边界前，不在本文中作为可下游消费的 Story/VS 承接。

### US-ACC-006 - 已登录学习者管理隐私授权与使用规则

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-006` | 作为已登录学习者，我希望查看和调整与隐私相关的授权、设备权限和使用规则入口，以便知道 App 如何使用我的设备权限和学习数据，并能按自己的选择继续使用。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-064` | 学习者进入隐私授权中心后，系统展示当前隐私授权和权限状态；成功时学习者能看到哪些授权已开启、哪些未开启、哪些需要前往系统设置处理；失败时展示状态不可用并允许重试。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-065` | 当学习者需要语音练习但麦克风权限未开启时，可从隐私授权中心查看并进入授权引导；成功时学习者理解权限用途并能前往开启；拒绝或系统限制时，展示功能影响和替代路径。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-066` | 学习者查看通知授权状态并选择开启、关闭或前往系统设置调整；成功时授权状态在账户侧可见；失败或系统不允许修改时，展示说明，不误报授权已改变。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-067` | 学习者可从隐私中心查看服务条款、隐私政策和当前同意状态；成功时能打开对应协议内容；若协议加载失败，展示可恢复提示，不阻塞已有账户信息展示。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

### US-ACC-007 - 已登录学习者使用数据权利入口并管理账号状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-007` | 作为已登录学习者，我希望在账户中找到个人数据相关权利入口，并可以退出登录或注销账号，以便查看、导出、删除或提交与个人数据有关的请求，并管理当前账号状态。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-068` | 学习者进入数据权利页面后，系统展示可用的数据权利操作，例如查看数据摘要、导出数据、删除数据或注销账号入口；成功时学习者知道每类操作的影响；失败时展示可恢复错误，不执行任何数据动作。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-069` | 学习者发起个人数据导出请求并完成必要确认；成功时系统记录请求并展示后续获取方式或处理状态；失败时展示请求失败原因，并允许重新提交。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-070` | 学习者发起删除数据或注销账号请求，并看到明确影响说明和确认步骤；成功时请求进入处理状态或完成状态；取消、验证失败或不满足条件时，账户和数据保持不变。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-071` | 学习者查看已提交的数据权利请求状态；成功时能看到处理中、已完成、失败或需补充操作等状态；失败时展示状态不可用并允许重试，不重复提交请求。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |
| `VS-ACC-072` | 学习者选择退出当前账号；成功时当前会话失效并回到登录/认证入口；失败时展示可恢复提示，不错误清除当前学习状态。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY`, `CAP-ENGAGE` |

### US-ACC-008 - 已登录学习者管理隐私授权版本与撤回

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-008` | 作为已登录学习者，当我检查隐私授权和数据使用规则时，我希望看到当前同意的协议版本、非必要授权和可撤回的数据使用选择，以便知道 App 当前如何使用我的权限和学习数据，并能撤回不再接受的授权。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-073` | 学习者从隐私授权中心查看当前服务条款、隐私政策和授权版本；成功时看到当前版本、同意状态和更新时间；版本信息不可用时展示保守提示并允许重试。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-074` | 学习者撤回非必要授权或个性化数据使用选择；成功时授权状态更新并展示受影响功能；撤回失败或系统限制时保持原状态并说明原因。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |
| `VS-ACC-075` | 当隐私授权变更会影响语音练习、提醒或训练体验时，系统展示影响说明和可恢复路径；成功时学习者知道哪些功能仍可用，哪些需要重新授权；状态不可用时不误报授权已变更。 | `draft` | `CAP-ACC` | `CAP-ENGAGE`, `CAP-PRACTICE`, `CAP-TRAIN` |

### US-ACC-009 - 学习者恢复账号访问

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-009` | 作为无法正常登录的学习者，当我忘记登录方式、凭证失效或更换设备时，我希望通过已绑定的手机号、邮箱或可用验证方式恢复账号访问，以便安全回到自己的学习数据而不是误建新账号。 | `draft` | `CAP-ACC` | `CAP-MEMORY`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-076` | 学习者从登录页进入账号恢复入口并选择手机号或邮箱验证；成功时看到可继续验证的路径；账号不存在、验证方式不可用或发送失败时展示可恢复提示。 | `draft` | `CAP-ACC` | `CAP-MEMORY`, `CAP-COM` |
| `VS-ACC-077` | 学习者完成账号恢复验证后回到原账号；成功时保留原学习数据和订阅权益状态；验证失败、过期或中断时不创建新账号并允许重新尝试。 | `draft` | `CAP-ACC` | `CAP-MEMORY`, `CAP-COM` |

### US-ACC-010 - 学习者管理账号安全与登录设备

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ACC-010` | 作为已登录学习者，当我怀疑账号风险或更换设备时，我希望查看登录设备、远端会话、安全风险提示，并在敏感操作前完成重新验证，以便确认账号仍由自己安全控制。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ACC-078` | 学习者进入账号安全页后查看当前设备、其他登录设备和远端会话摘要；成功时能识别登录位置和最近活动；加载失败时展示状态不可用并阻止误操作。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-079` | 学习者选择退出其他设备或结束远端会话；成功时对应会话失效并展示结果；失败或权限不足时保持会话状态并说明原因。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-080` | 学习者执行注销、删除数据、解绑最后一种登录方式或管理订阅等敏感操作前，系统要求重新验证；成功时允许继续原操作；验证失败或取消时原操作不生效。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |
| `VS-ACC-081` | 当系统检测到用户可见的账号安全风险时，账号安全页展示风险提示和处理入口；成功时学习者知道建议动作；风险状态不可用时展示保守状态，不制造错误告警。 | `draft` | `CAP-ACC` | `CAP-COM`, `CAP-MEMORY` |

