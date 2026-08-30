# Usability Checklist

- [ ] User can identify the next action within 3 seconds.
- [ ] Primary action is visually clear.
- [ ] Loading state explains what is happening.
- [ ] Error state preserves user input.
- [ ] Feedback is no longer than needed.
- [ ] Correction tone is supportive and specific.
- [ ] Mobile layout avoids dense text blocks.
- [ ] Saved or completed state is visible immediately.
- [ ] Empty state includes a useful next step.
- [ ] MVP scope does not introduce hidden workflows.

- [ ] 用户能在 3 秒内识别下一步动作。
- [ ] 主操作在视觉上足够清晰。
- [ ] 加载状态会说明当前正在发生什么。
- [ ] 错误状态会保留用户输入。
- [ ] 反馈长度不超过必要信息量。
- [ ] 纠错语气保持支持性且具体。
- [ ] 移动端布局避免密集大段文字。
- [ ] 保存或完成状态会立即可见。
- [ ] 空状态包含有用的下一步。
- [ ] MVP 范围不会引入隐藏工作流。

## Phone Account Recovery

- [ ] `login_account_recovery_entry` 只在恢复 feature flag 开启且普通登录未在提交时可用；它是可独立聚焦、可理解名称为“恢复账号”的次级操作，不与普通登录或发码合并。
- [ ] 从手机号登录进入恢复页时只带入学习者输入的手机号表单值，不带入普通登录 code、错误、协议状态或任何认证事实。
- [ ] 首屏同时说明“使用已绑定且仍可接收短信的手机号”和“恢复成功后所有设备退出”，但不展示账号是否存在、手机号是否绑定/可用或短信是否实际投递。
- [ ] 恢复发码 `202 accepted` 始终使用同一“请求已受理”外形；文案不包含“账号存在”、“已绑定”、“短信已发送”或“未注册”等可枚举信息。
- [ ] 恢复页只请求和提交 purpose-bound recovery code，不复用普通登录验证码，不调用 login-or-create，不建立或替换账号/身份。
- [ ] 发码和恢复提交在途时都有明确 loading 文案，禁用重复操作；恢复提交在途时页头和系统返回均被拦截。
- [ ] 发码请求在途时返回只取消当前 UI caller 并清空恢复 code；恢复完成请求的 cancellation、timeout 或 connection loss 不作为失败或成功，而是进入 result-unknown。
- [ ] `400`、privacy-safe `401`、`429`、`503` 和网络失败均有明确且可操作的文案；账号不存在、手机号未绑定/不可用、code 错误/过期/已使用/用途不匹配共用同一验证失败文案。
- [ ] `Retry-After` 倒计时不每秒向辅助技术宣告，未到期不可操作，到期只恢复可操作状态，不自动发码或提交。
- [ ] 恢复成功前的所有失败、返回和重试分支都不创建新账号、不改变身份凭据或任何会话，页面也不声称这些事实已变更。
- [ ] result-unknown 显示“为避免误建新账号”的明确原因和唯一下一步 `account_recovery_retry_after_unknown`；页头/系统返回和 `account_recovery_return_to_phone_login` 均不可用。
- [ ] result-unknown 重试会清空原 code、由学习者明确请求新的 purpose-bound code，并只重跑 only-existing-identity 恢复；不重放原 code，不调用普通 login-or-create、recovery-status 或 no-create-login 探测。
- [ ] 只有客户端明确收到 `200 { status: recovered, next_action: login_phone }` 才显示服务端恢复已成功；响应和 UI 不含或产生新 Session、Access Token 或 Refresh Token，也不自动登录。
- [ ] 明确成功文案告知“已安全退出所有设备”，但不暴露 user/session/token 标识或被撤销数量。
- [ ] 明确 `200 recovered` 后本机清理在途时显示独立进度；清理失败显示“服务端恢复已成功，本机清理未完成”，只提供 `account_recovery_retry_local_cleanup`，不把它误报为 result-unknown。
- [ ] 本机清理失败后的重试只清理旧 credential、learner-specific body 和恢复 code，不再调用恢复 API 或重放 code；清理完成前不显示返回普通登录入口。
- [ ] 只有明确 `200 recovered` 且本机清理完成后，`account_recovery_return_to_phone_login` 才可用；返回只带入非认证手机号表单值，学习者必须另行登录。
- [ ] 恢复页没有伪空状态：首屏为完整表单，code 和提交在发码受理前禁用；loading、accepted、error、rate-limited、result-unknown、local-cleanup 和 success 状态都不以空页替代。
- [ ] heading、持续可见 field label、field-error 关联、phone keyboard、one-time-code autofill、dynamic text、软键盘避让、非仅颜色状态和平台最小触控目标均可用。
- [ ] `202`、错误、result-unknown、本机清理失败和成功都使用适度 live region 且只宣告一次；焦点分别进入 code field、首个错误/无效 field、安全重试动作、本机清理重试动作和 success heading。
- [ ] 稳定 selector 可定位恢复入口、页面、返回、表单、loading、隐私说明、受理、限流、错误、result-unknown 重试、本机清理/重试、成功和返回登录状态。
- [ ] 如果发送 UX event，只使用有界 result allowlist，不包含 raw/hashed phone、verification code、token、user/session/device identifier、任意 backend message 或 raw path。

## Content Catalog And Version-Pinned Course Detail

- [ ] `content_asset_entry` 的“全部主题”请求省略 `query` 与 `category`，页面完整呈现 API 返回的 published+visible themes，并保持 API 顺序。
- [ ] 零可见 Course 的已发布可见主题仍显示在 `content_theme_catalog`；选择后看到明确的真实空状态，而不是主题消失。
- [ ] `selected_theme_course_summaries` 完整呈现 API 返回的 current published+visible summaries，并保持服务端 `Course.sort_order` 投影顺序，不按 learner state 重排。
- [ ] 只有成功 `200` 空集合显示空状态；`CONTENT_READ_UNAVAILABLE` / `503` 显示错误和 retry，且不伪装为空或部分成功。
- [ ] 可重试 catalog/list/detail 失败在同一 learner/auth context 内保留选中主题、已知列表、滚动位置和安全返回路径。
- [ ] `401`、privacy-safe `404`、登出、换用户或认证上下文变化会清除旧 learner-specific body；文案不泄漏内容存在性、发布状态或可见性原因。
- [ ] 每个 `course_summary_card` 可定位非空 `title_en`、非空 `summary_zh` 和唯一 A1/A2/B1/B2/C1/C2；`course_id + course_version_id` 只作为导航/测试 data，不成为主视觉。
- [ ] Course detail 只使用来源卡片的精确 `course_id + course_version_id`；不存在 latest、其他 Course、其他版本、ScenarioLevel 或相邻 CEFR fallback。
- [ ] `course_detail_header` 展示与来源 summary 一致的 title、summary、CEFR，以及正值时长和非空单位。
- [ ] `background_asset_ref = null` 是正常 loaded 变体：显示中性/装饰性背景，不出现损坏图标，不阻断必备信息，也不暗示缺失内容。
- [ ] 从 detail 返回会恢复同一主题、Course list 滚动位置与先前聚焦卡片；详情页没有“开始学习”或训练动作。
- [ ] heading、list、card/button semantics、焦点顺序、dynamic text、对比度与非仅颜色表达在 catalog/list/detail 三屏一致可用。
- [ ] loading/error 由适度 live region 宣告；retry 后焦点进入更新后的列表/header 或错误标题；所有操作满足平台最小触控目标。
- [ ] 装饰背景从 semantics tree 排除，正文在有图和无图两种 loaded 变体中都保持足够对比度。
- [ ] 稳定 selector 保持可定位：`content_asset_entry`、`content_theme_catalog`、`theme_card`、`selected_theme_course_summaries`、`course_summary_list`、`course_summary_card`、`course_detail_header`；既有 `course_card` 只作为同一 summary card 节点的兼容定位键。
- [ ] UI 不向学习者暴露 ETag/`304`，不把 cache 当成 publication/visibility truth，也不把 Task Plan seed 或 OpenAPI example 当成 authored content。
- [ ] 本轮不引入学习路线、阶段、训练、AI、media、scoring、CMS、authored inventory 管理或其他 Course 入口实现。

## P0 Commercial

- [ ] Membership page shows server entitlement state and does not rely on local `memberPlan` as final truth.
- [ ] Purchase, restore, empty restore, invalid receipt, and provider unavailable states each have a clear next action.
- [ ] Paywall and protected feature entry use the same gating result for scenario list, scenario detail, training entry, AI feedback, and reports.
- [ ] Expired, refunded, revoked, grace-period, and quota-exhausted states are visually distinct.
- [ ] Account deletion confirmation explains cloud deletion/anonymization and local cleanup before the destructive action.
- [ ] Commercial copy matches store metadata, privacy copy, and actual implemented entitlement rules.

- [ ] 会员页展示服务端权益状态，不把本地 `memberPlan` 当作最终事实。
- [ ] 购买、恢复购买、空恢复、无效票据和供应商不可用状态都提供清晰的下一步。
- [ ] 付费墙和受保护功能入口在场景列表、场景详情、训练入口、AI 反馈和报告中使用同一门控结果。
- [ ] 过期、退款、撤销、宽限期和额度用尽状态在视觉上可区分。
- [ ] 账号删除确认在破坏性操作前说明云端删除或匿名化，以及本地清理规则。
- [ ] 商业文案与商店元数据、隐私文案和实际实现的权益规则一致。

## P0.1 Expression Automation Training

- [ ] The learner sees exactly one primary micro-action in the active training panel.
- [ ] The current action chain step is visible but does not crowd the main action.
- [ ] Voice answer controls include record, cancel, submit and re-record states.
- [ ] Text fallback appears only after mic denial, ASR failure or debug mode.
- [ ] Hint level changes are visible through concrete support: sentence frame, options, chunk shadowing or model-then-retry.
- [ ] Feedback names one main issue and one next action.
- [ ] Pronunciation unavailable state does not block progress.
- [ ] Pressure check is visually distinct from normal retry and stays session-only.
- [ ] Recoverable error preserves user input or recap where possible.
- [ ] Recap stays available even when learning evidence write-back is retryable.
- [ ] P0.1 screens do not show third-scene creation, arbitrary scene generation, cross-day schedule, full L0-L5 mastery or commercial gating as completion conditions.

- [ ] 学习者在当前训练面板中只看到一个主要微动作。
- [ ] 当前动作链步骤可见，但不会挤压主操作。
- [ ] 语音回答控件包含录音、取消、提交和重新录制状态。
- [ ] 文本兜底只在麦克风拒绝、ASR 失败或调试模式下出现。
- [ ] 提示等级变化通过具体支持方式体现：句子框架、选项、分块跟读或示范后重试。
- [ ] 反馈只指出一个主要问题和一个下一步动作。
- [ ] 发音评分不可用时不阻断训练进度。
- [ ] Pressure check 在视觉上区别于普通重试，并且只属于当前 session。
- [ ] 可恢复错误尽可能保留用户输入或回顾内容。
- [ ] 即使学习证据回写可重试，回顾内容也保持可用。
- [ ] P0.1 页面不得把第三场景创建、任意场景生成、跨天排期、完整 L0-L5 掌握或商业门控展示为完成条件。
