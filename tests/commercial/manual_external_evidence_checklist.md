# Manual External Evidence Checklist：商业化订阅上线准备

## 状态
Manual plan ready / external execution pending。本文把剩余外部 provider、store、native 和 release 证据项展开为可人工执行的测试步骤和验收结果模板；不声明任何真实外部测试已经通过。

## 适用范围
| Blocker scope | TC | AC | Traceability row | Evidence ref / gate | Current status |
| --- | --- | --- | --- | --- | --- |
| 商业文案外部一致性 | TC-COM-015 | AC-COM-011 | COM-TR-009 | `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, `SUPPORT_URL` | external-pending |
| 真实支付 provider 沙盒/内测 | TC-COM-019 | AC-COM-013 | COM-TR-011 | `APPLE_SANDBOX_EVIDENCE_REF`, `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` | external-pending |
| 真实 DashScope AI provider 证据 | TC-COM-AI-004 | AC-COM-AI-003 | COM-AI-TR-003 | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` | external-pending |
| 商店提交资料 | TC-COM-021 | AC-COM-014 | COM-TR-012 | `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, `SUPPORT_URL` | external-pending |
| 原生社交登录生产配置 | TC-COM-012 | AC-COM-009 | COM-TR-005, COM-TR-012 | `scripts/check_social_login_release_config.sh` | native-blocked |
| 聚合发布门禁 | TC-COM-022 | AC-COM-014 | COM-TR-012 | `scripts/check_release_readiness.sh` | release-blocked |

## 证据和安全规则
- 所有截图、provider console 日志、backend verification/webhook 日志、商店配置截图、审核账号 vault 引用、symbol upload 记录和 rollback 演练记录必须存储在仓库外，只在 release vars 或报告中引用。
- 不得把 Apple、Google、WeChat、Sentry、签名、审核账号、沙盒账号或用户账号密钥提交到仓库。
- 日志证据必须脱敏：保留 provider transaction id / purchase token hash / event id / backend request id / user id hash，移除完整 token、邮箱、手机号、真实姓名和支付敏感字段。
- 每个场景执行后必须在本文的结果字段、`docs/reports/test_report.md` 和对应 release var 中记录 evidence ref；未执行只能标记为 `blocked`，不得标记为 `passed`。
- DashScope AI evidence 必须使用脱敏文本、脱敏短音频和 hash/media ref；不得上传真实用户音频或完整 signed media URL 到仓库。
- 独立审查人必须复核证据可访问性、截图/日志时间、build tag/commit、账号隔离和 gate 命令结果。

## 验收结果模板
每个人工场景执行后复制并填写以下字段；未执行时 `Actual result` 使用 `blocked` 并写明原因。

| Field | Value |
| --- | --- |
| Execution ID | `YYYYMMDD-TC-COM-XXX-SCENARIO` |
| TC ID | `TC-COM-012` / `TC-COM-015` / `TC-COM-019` / `TC-COM-AI-004` / `TC-COM-021` / `TC-COM-022` |
| Scenario ID | 见下方各场景表 |
| Executor | 待填写 |
| Execution date | 待填写 |
| Environment | TestFlight sandbox / Google internal test / App Store Connect / Play Console / release CI |
| Build tag / commit | 待填写 |
| Device / OS | 待填写；非设备场景写 `N/A - console review` |
| Account / vault ref | 待填写；只允许填写外部 vault/ref，不得填写明文账号密码 |
| Evidence ref | 待填写；外部文档、截图包、日志包或工单链接 |
| Expected result | 复制对应场景预期 |
| Actual result | `pending` / `passed` / `failed` / `blocked` |
| Failure / blocker reason | 待填写；通过时写 `N/A` |
| Reviewer | 待填写 |
| Review result | `pending` / `approved` / `rejected` |

## TC-COM-015：商业文案外部一致性

### 前置条件
- 使用同一 release candidate build、同一 commit 的会员页/profile upsell 截图。
- App Store Connect / Play Console 元数据草稿、订阅商品页、隐私说明和支持 URL 已可访问。
- `scripts/check_commercial_copy_contract.py` 在本地默认模式已通过。

### 人工步骤
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| COPY-IN-APP | 1. 安装 release candidate。2. 打开会员页、profile upsell、恢复购买入口和降级提示。3. 截取所有付费权益文案。4. 对照已上线权益：高级场景 L3、完整句型库、AI 深度反馈、沉浸式对话、更高 AI 练习额度、订阅状态同步。 | 应用内文案只承诺已上线权益；不得出现离线学习包、离线内容包、专属学习报告、无限场景练习、终身会员。 | 会员页/profile/恢复购买/降级提示截图包；build tag/commit。 | pending |
| COPY-STORE | 1. 打开 App Store Connect 和 Play Console 元数据草稿。2. 检查 app description、short description、screenshots、review notes 和订阅商品展示文案。3. 对照应用内权益名称。 | 商店文案和应用内权益一致；不得把未上线能力包装为付费承诺；订阅商品名称、周期和价格展示不冲突。 | App Store Connect / Play Console 截图包或外部文档；`STORE_METADATA_EVIDENCE_REF`。 | pending |
| COPY-PRIVACY-SUPPORT | 1. 打开 `PRIVACY_URL` 和 `SUPPORT_URL`。2. 检查隐私说明、取消订阅/恢复购买/账号注销说明、支持联系方式。3. 对照商店 metadata 中的 privacy/support 配置。 | URL 使用 HTTPS 且公开可访问；隐私/支持说明和商店配置一致；不包含与当前实现冲突的承诺。 | URL 截图、HTTP 访问记录、商店配置截图；`PRIVACY_URL`、`SUPPORT_URL`。 | pending |
| COPY-STRICT-GATE | 1. 设置 `STORE_METADATA_EVIDENCE_REF`、`PRIVACY_URL`、`SUPPORT_URL`。2. 运行 `python3 scripts/check_commercial_copy_contract.py --strict-external`。 | strict copy gate 通过；若任一 evidence ref 或 HTTPS URL 缺失则失败。 | 命令输出、环境变量记录的外部 evidence ref。 | pending |

### TC-COM-015 通过条件
- `COPY-IN-APP`、`COPY-STORE`、`COPY-PRIVACY-SUPPORT` 和 `COPY-STRICT-GATE` 全部 `passed`。
- 独立审查确认截图/文案和 release candidate build 对齐。
- `docs/reports/test_report.md` 记录执行日期、evidence ref 和 reviewer。

## TC-COM-019：真实 provider 沙盒/内测商业边界

### 前置条件
- iOS 使用 TestFlight 或 Apple sandbox tester 可购买的 release candidate。
- Android 使用 Google Play internal test track 和 license tester。
- 后端 provider 验证密钥、webhook / notification 端点、product allowlist 和 entitlement 刷新逻辑已配置在目标环境。
- 每个场景使用可追踪但已脱敏的 app user id、provider account ref、transaction id / purchase token hash。

### Apple sandbox 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| APPLE-PURCHASE | 1. 使用 Apple sandbox tester A 登录设备。2. 使用免费 app 用户 A 登录应用。3. 在会员页购买 weekly/monthly/yearly 任一订阅。4. 返回应用并刷新权益。5. 在后端查询 purchase、subscription、entitlement snapshot。 | Apple transaction 被后端校验通过；服务端写入 purchase/subscription；用户 A 权益变为 active；客户端解锁付费权益。 | 购买流程截图、transaction id、后端 verify success 日志、entitlement active 快照。 | pending |
| APPLE-RESTORE | 1. 卸载或登出应用后重新安装/登录同一 app 用户 A。2. 点击恢复购买。3. 刷新权益。 | restore 经后端校验后恢复同一用户权益；不会授予给错误用户；客户端展示订阅已生效。 | restore 操作截图、restored transaction id、后端 restore success 日志、entitlement active 快照。 | pending |
| APPLE-REFUND-REVOKE | 1. 在 App Store Connect sandbox / provider tooling 中对已购买交易触发退款或撤销。2. 等待 webhook 或手动刷新 provider 状态。3. 打开应用刷新权益。 | 后端记录 refund/revoke provider event；subscription/entitlement 降级为 inactive 或 revoked；客户端不再开放付费能力并显示可恢复状态。 | provider event id、webhook/refresh 日志、downgrade audit、entitlement inactive 快照、客户端降级截图。 | pending |
| APPLE-EXPIRY | 1. 使用 sandbox 加速周期等待订阅过期，或选择已过期 sandbox transaction。2. 触发后端状态刷新或 webhook。3. 打开应用刷新权益。 | 过期状态被映射为 inactive/expired；重复刷新幂等；客户端不继续显示 active entitlement。 | 过期交易证据、backend refresh/webhook 日志、inactive entitlement 快照、客户端截图。 | pending |
| APPLE-GRACE-PERIOD | 1. 在 sandbox/provider 配置中触发 billing retry / grace-period 状态，或使用 provider 指定测试状态。2. 刷新后端订阅状态。3. 打开应用确认用户提示。 | 后端把 grace-period 映射为可审计状态；客户端展示可恢复/管理订阅提示；不会把状态误写为永久 active。 | grace-period 状态截图、backend status mapping 日志、客户端 recoverable state 截图。 | pending |
| APPLE-ACCOUNT-SWITCH | 1. app 用户 A 完成购买。2. 登出 app 用户 A。3. app 用户 B 使用同一设备/provider account 尝试恢复或刷新同一 transaction。4. 查询后端归属。 | 后端拒绝错误账号恢复，或保持权益归属用户 A；用户 B 不获得用户 A 的权益；审计记录 account mismatch。 | 用户 A/B 操作截图、backend mismatch/reject 日志、两个用户 entitlement 快照。 | pending |

### Google Play internal 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| GOOGLE-PURCHASE | 1. 使用 Google license tester A 安装 internal test build。2. 使用免费 app 用户 A 登录应用。3. 购买 weekly/monthly/yearly 任一订阅。4. 返回应用并刷新权益。5. 查询后端 purchase/subscription/entitlement。 | Google purchase token 被后端校验通过；服务端写入 purchase/subscription；用户 A 权益变为 active；客户端解锁付费权益。 | 购买流程截图、purchase token hash、后端 verify success 日志、entitlement active 快照。 | pending |
| GOOGLE-RESTORE | 1. 卸载或登出应用后重新安装/登录同一 app 用户 A。2. 点击恢复购买。3. 刷新权益。 | restore 经后端校验后恢复同一用户权益；不会授予给错误用户；客户端展示订阅已生效。 | restore 截图、purchase token hash、后端 restore success 日志、entitlement active 快照。 | pending |
| GOOGLE-REFUND-REVOKE | 1. 在 Play Console / provider tooling 中触发 refund、revoke 或 voided purchase 状态。2. 等待 notification 或手动刷新 provider 状态。3. 打开应用刷新权益。 | 后端记录 refund/revoke provider event；subscription/entitlement 降级；客户端不再开放付费能力。 | provider event id、notification/refresh 日志、downgrade audit、inactive entitlement 快照、客户端截图。 | pending |
| GOOGLE-EXPIRY | 1. 使用 internal test 加速周期等待订阅过期，或使用已过期测试 purchase。2. 触发后端状态刷新。3. 打开应用刷新权益。 | 过期状态被映射为 inactive/expired；客户端不继续显示 active entitlement。 | 过期订阅证据、backend refresh 日志、inactive entitlement 快照、客户端截图。 | pending |
| GOOGLE-GRACE-PERIOD | 1. 在 Play billing 测试配置中触发 billing retry / grace-period 状态，或使用 provider 指定测试状态。2. 刷新后端订阅状态。3. 打开应用确认提示。 | 后端把 grace-period 映射为可审计状态；客户端展示可恢复/管理订阅提示；不会把状态误写为永久 active。 | grace-period 状态截图、backend mapping 日志、客户端 recoverable state 截图。 | pending |
| GOOGLE-ACCOUNT-SWITCH | 1. app 用户 A 完成购买。2. 登出 app 用户 A。3. app 用户 B 使用同一设备/provider account 尝试恢复或刷新同一 purchase token。4. 查询后端归属。 | 后端拒绝错误账号恢复，或保持权益归属用户 A；用户 B 不获得用户 A 的权益；审计记录 account mismatch。 | 用户 A/B 操作截图、backend mismatch/reject 日志、两个用户 entitlement 快照。 | pending |

### TC-COM-019 通过条件
- Apple 六个场景和 Google 六个场景全部 `passed`，或失败项有修复后重跑证据。
- `APPLE_SANDBOX_EVIDENCE_REF` 和 `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` 指向完整证据包。
- `python3 scripts/check_provider_sandbox_evidence.py --strict-external` 通过。

## TC-COM-AI-004：真实 DashScope AI Provider 证据

### 前置条件
- `commercial-ai-provider-hardening` 的 API/security/media 契约已经通过实现前审查。
- DashScope sandbox 或 controlled live 环境凭据只存在于后端/secret manager。
- 使用脱敏文本、短音频、异常音频和格式样本；不得使用真实用户敏感录音。
- 后端已开启 provider metric 记录，且日志不包含完整 signed media URL、raw audio、provider secret 或完整 transcript。

### DashScope 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| AI-QWEN-VALID | 1. 使用脱敏 learner transcript 调用 coach/feedback。2. 记录 provider model、request id、latency、token estimate、schema result。 | Qwen 返回 strict JSON；后端 schema validation 通过；不直接写最终 mastery 或 entitlement。 | 后端 request id、model、latency、schema-valid result、cost estimate。 | pending |
| AI-QWEN-FALLBACK | 1. 触发或模拟 provider unsafe/invalid schema response。2. 检查 fallback。 | 无效输出被映射为 recoverable fallback；不写 learning evidence；usage 按策略 release/commit。 | invalid schema mapping、fallback response、usage event。 | pending |
| AI-ASR-VALID | 1. 上传脱敏短音频并生成 trusted `audio_ref`。2. 调用 DashScope Paraformer。3. 记录 transcript/status。 | ASR 返回 available 或 typed status；media metadata、duration、format 和 latency 可审计。 | media hash/ref、format metadata、latency、duration、transcript status、cost estimate。 | pending |
| AI-ASR-REJECT | 1. 使用本地路径、unsigned URL、伪造签名、过期或超限 media ref。2. 调用 ASR。 | 请求在 provider call 前被拒绝或返回 typed fallback；不记录完整 signed URL。 | rejection reason、provider call count、audit hash evidence。 | pending |
| AI-TTS-GENERATE | 1. 使用固定 text/model/voice 请求 TTS。2. 记录 provider call。 | TTS 生成 media ref；记录字符数、latency、cost estimate 和 cache miss。 | media hash/ref、model、voice、latency、char count、cost estimate。 | pending |
| AI-TTS-CACHE | 1. 重复同一 text/model/voice 请求。2. 检查 cache hit。 | 返回同一有效 media ref；不重复 provider call；cache hit metric 记录。 | cache key/hash、cache hit event、provider call count。 | pending |
| AI-PROVIDER-ERROR | 1. 触发 timeout/rate-limit/provider error。2. 检查 fallback 和告警。 | 返回 typed provider_unavailable/fallback；usage 状态正确；provider anomaly 或 budget alert 可见。 | normalized error、fallback status、usage event、alert/cost dashboard entry。 | pending |

### TC-COM-AI-004 通过条件
- DashScope LLM、ASR、TTS 和 provider error 场景全部 `passed`，或失败项有修复后重跑证据。
- `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` 指向完整证据包。
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` 通过。
- 独立审查确认 evidence ref、时间戳、环境、commit/build tag、payload 脱敏和成本记录。

## TC-COM-021：商店提交资料人工审查

### 前置条件
- App Store Connect 和 Play Console 中已建立 release candidate 版本或草稿。
- weekly/monthly/yearly 商品、价格、本地化名称、订阅周期、自动续订说明已配置。
- 隐私 URL、支持 URL 和审核账号 vault ref 已准备好。

### 人工步骤
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| STORE-APPSTORE-METADATA | 1. 打开 App Store Connect app version metadata。2. 检查 app name、subtitle、description、keywords、age rating、category、localized screenshots。3. 对照应用内会员权益和禁止承诺清单。 | App Store metadata 完整、可提交、文案不承诺未上线能力。 | App Store Connect 截图包；metadata 导出或外部文档。 | pending |
| STORE-PLAY-METADATA | 1. 打开 Play Console store listing。2. 检查 title、short/full description、category、content rating、graphics、screenshots。3. 对照应用内会员权益和禁止承诺清单。 | Play metadata 完整、可提交、文案不承诺未上线能力。 | Play Console 截图包；metadata 导出或外部文档。 | pending |
| STORE-SUBSCRIPTION-PRODUCTS | 1. 检查 App Store 和 Play Console 订阅商品。2. 确认 weekly/monthly/yearly product id、localized name、price、duration、renewal disclosure。3. 对照 `PaymentConfig` 和后端 product allowlist。 | 商品 ID 与客户端/后端一致；价格和周期清晰；自动续订披露存在。 | 商品配置截图、product id 清单、allowlist 对照记录。 | pending |
| STORE-SUBSCRIPTION-TERMS | 1. 检查商店描述、审核说明和会员页。2. 确认自动续订、取消路径、账单说明、恢复购买说明。 | 用户能在商店和应用内看到一致的订阅条款、取消和恢复路径。 | 条款截图、会员页截图、审核说明截图。 | pending |
| STORE-PRIVACY-DATA-SAFETY | 1. 检查 App Store privacy labels 和 Play Data safety。2. 对照生产后端、登录、支付、AI、analytics/crash reporting、账号注销。3. 确认数据收集/用途声明不漏项。 | Privacy labels / Data safety 与实际实现一致；账号删除和支持路径存在。 | 隐私配置截图、对照记录、生产数据流说明引用。 | pending |
| STORE-PRIVACY-URL | 1. 打开 `PRIVACY_URL`。2. 确认 HTTPS、公开可访问、内容覆盖登录、支付、AI 数据、崩溃日志、账号注销。3. 对照商店配置 URL。 | `PRIVACY_URL` 可访问且与商店配置一致。 | URL 截图、HTTP 访问记录、商店配置截图。 | pending |
| STORE-SUPPORT-URL | 1. 打开 `SUPPORT_URL`。2. 确认 HTTPS、公开可访问、支持联系方式和订阅/恢复/注销说明存在。3. 对照商店配置 URL。 | `SUPPORT_URL` 可访问且与商店配置一致。 | URL 截图、HTTP 访问记录、商店配置截图。 | pending |
| STORE-REVIEWER-ACCOUNT | 1. 在外部 vault 中创建/确认审核账号。2. 使用审核账号登录 release candidate。3. 验证 reviewer notes 中的登录、购买、恢复购买、注销或联系支持步骤可执行。 | 审核账号可用；步骤不依赖内部人员；凭证只存 vault，不进入仓库。 | `REVIEWER_ACCOUNT_REF`、审核步骤截图、vault 访问记录。 | pending |
| STORE-STRICT-GATE | 1. 设置 `STORE_METADATA_EVIDENCE_REF`、`REVIEWER_ACCOUNT_REF`、`PRIVACY_URL`、`SUPPORT_URL`。2. 运行 `python3 scripts/check_store_submission_evidence.py --strict-external`。 | strict store evidence gate 通过。 | 命令输出、release vars 截图或 CI 日志。 | pending |

### TC-COM-021 通过条件
- 全部 store 场景 `passed`。
- `STORE_METADATA_EVIDENCE_REF`、`REVIEWER_ACCOUNT_REF`、`PRIVACY_URL` 和 `SUPPORT_URL` 均已登记。
- 独立审查确认商店资料、订阅条款、隐私/支持 URL 与 release candidate 一致。

## TC-COM-012：原生社交登录生产配置

### 前置条件
- 微信开放平台、Apple Developer、Xcode signing、Android package/signature 和后端回调配置均可访问。
- Release candidate 使用生产 bundle id / package name / associated domains。

### 人工步骤
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| NATIVE-WECHAT-IOS | 1. 检查 `WECHAT_APP_ID` 为真实微信 AppID。2. 检查 iOS `Info.plist` URL scheme 不再是 `wx0000000000000000`，且与微信开放平台 AppID 一致。3. 检查 Universal Link 和 Associated Domains 配置。 | iOS 微信登录不含占位配置；Universal Link 使用 HTTPS 且已绑定。 | 微信开放平台截图、Info.plist/entitlement 截图、Associated Domains 截图。 | pending |
| NATIVE-WECHAT-ANDROID | 1. 检查 Android package/signature 与微信开放平台配置一致。2. 确认 `WXEntryActivity` 存在并在 release build 可回调。3. 使用安装了微信的设备发起登录并回到应用。 | Android 微信登录可完成授权回调；无测试 AppID 或占位回调。 | 微信开放平台截图、Android manifest/activity 截图、设备登录录屏或截图。 | pending |
| NATIVE-APPLE-SIGN-IN | 1. 检查 Apple Developer capability 和 Xcode target signing。2. 确认 entitlement 包含 `com.apple.developer.applesignin`。3. 在 iOS 设备或 TestFlight build 执行 Apple 登录。 | Apple 登录 entitlement 和签名配置齐备；登录回调成功；商店版本不缺能力。 | Apple Developer/Xcode 截图、entitlements 截图、设备登录截图/日志。 | pending |
| NATIVE-SOCIAL-SMOKE | 1. 使用 release candidate 分别执行微信和 Apple 登录。2. 检查后端 auth callback / token exchange 日志。3. 确认账号绑定、登出、重新登录不破坏 entitlement。 | 登录成功，后端只写当前用户身份；不会影响已有订阅权益归属。 | 客户端截图、后端 request id/log、用户 entitlement 快照。 | pending |
| NATIVE-STRICT-GATE | 1. 设置真实 `WECHAT_APP_ID` 和 `WECHAT_UNIVERSAL_LINK`。2. 运行 `scripts/check_social_login_release_config.sh`。 | strict social login gate 通过；若 iOS URL scheme 占位或 Apple Sign In entitlement 缺失则失败。 | 命令输出、CI 日志。 | pending |

### TC-COM-012 通过条件
- `NATIVE-WECHAT-IOS`、`NATIVE-WECHAT-ANDROID`、`NATIVE-APPLE-SIGN-IN`、`NATIVE-SOCIAL-SMOKE` 和 `NATIVE-STRICT-GATE` 全部 `passed`。
- `scripts/check_social_login_release_config.sh` strict mode 通过。

## TC-COM-022：聚合发布门禁和发布证据

### 前置条件
- TC-COM-012、TC-COM-015、TC-COM-019 和 TC-COM-021 的外部证据已完成或明确阻断。
- Release CI 可访问生产 API、release secrets、signing secrets、Sentry 和商店证据 refs。

### 人工步骤
| Scenario ID | 步骤 | 预期结果 | 必需证据 | 验收结果 |
| --- | --- | --- | --- | --- |
| REL-SECRETS | 1. 检查 `APP_API_BASE_URL` / `API_BASE_URL`、`ENV=production`、`ENABLE_TEST_PHONE_LOGIN=false`、Sentry、Android signing、WeChat、provider/store refs。2. 确认没有 example/local/test login。 | release secrets/vars 完整且不使用测试值；敏感值只在 CI/secret store。 | CI secret 配置截图或审批记录；脱敏变量清单。 | pending |
| REL-SIGNING | 1. 触发或 dry-run release signing。2. 确认 Android keystore、iOS signing profile/certificate 使用 release 配置。 | 签名配置可用；不会产出 debug/test 签名包。 | CI 日志、签名配置审批或外部证据。 | pending |
| REL-SYMBOLS | 1. 构建 release artifact。2. 上传或验证 dSYM / ProGuard mapping。3. 记录 Sentry 或符号平台 artifact。 | 符号表上传完成，可用于崩溃解析。 | `SYMBOL_UPLOAD_EVIDENCE_REF`、CI 日志、Sentry artifact 截图。 | pending |
| REL-ROLLBACK | 1. 按 `docs/release/rollback_plan.md` 执行演练或发布负责人审批。2. 验证关闭发布、回滚版本、禁用付费入口或撤回商店提交的路径。 | 回滚责任人、步骤、触发条件和证据明确。 | `ROLLBACK_REHEARSAL_REF`、演练记录或审批记录。 | pending |
| REL-STRICT-GATE | 1. 设置所有 required release vars 和 evidence refs。2. 运行 `scripts/check_release_readiness.sh` strict mode。3. 保存完整命令输出。 | strict release readiness 通过；任一外部/native 证据缺失时失败。 | 命令输出、CI gate 日志。 | pending |
| REL-FINAL-REVIEW | 1. 独立审查人核对 TC-COM-012/015/019/021/022 的结果记录。2. 确认 `docs/reports/test_report.md`、`quality_report.md` 和 release vars 一致。3. 出具 release approval 或 blocker list。 | 没有 pending/blocked 结果时才可进入 PM release approval；否则保持 blocker closure。 | 独立审查记录、最终 blocker list 或 approval 记录。 | pending |

### TC-COM-022 通过条件
- `REL-SECRETS`、`REL-SIGNING`、`REL-SYMBOLS`、`REL-ROLLBACK`、`REL-STRICT-GATE` 和 `REL-FINAL-REVIEW` 全部 `passed`。
- `scripts/check_release_readiness.sh` strict mode 通过。
- PM release approval 明确引用通过后的证据 refs。

## 执行后回填要求
| Document | Required update |
| --- | --- |
| `docs/reports/test_report.md` | 记录每个 TC 的执行日期、实际结果、evidence ref、失败/阻断原因。 |
| `docs/product/increments/commercial-subscription-readiness/test_cases.md` | 把对应 TC 的 `结果状态` 从 pending/blocked 更新为 passed/failed，并保留证据报告。 |
| `docs/product/increments/commercial-subscription-readiness/traceability.md` | 更新 Test Evidence / Release Evidence 和 Gap status；不得在证据缺失时关闭 COM-GAP-010。 |
| `docs/product/increments/commercial-ai-provider-hardening/test_cases.md` | 把 TC-COM-AI-004 和相关 AI provider TC 的 `结果状态` 从 pending/blocked 更新为 passed/failed，并保留证据报告。 |
| `docs/product/increments/commercial-ai-provider-hardening/traceability.md` | 更新 Test Evidence / Release Evidence 和 Gap status；不得在证据缺失时关闭 COM-AI-GAP-003 或 P01-GAP-008。 |
| `docs/reports/quality_report.md` | 记录独立审查结果、发现、残余风险和是否允许进入 PM release approval。 |
| `docs/release/release_checklist.md` | 勾选对应 release checklist 项。 |
