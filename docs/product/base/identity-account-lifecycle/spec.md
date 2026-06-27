# Identity & Account Lifecycle Spec（身份认证与账号生命周期规格）

## 状态
Draft（草案） - 本文件把 `Identity & Account Lifecycle` Product Base 模块需求下沉为可追溯、可验收、可生成 AC/TC 的模块规格。本文同时区分当前代码基线行为、真实短信 OTP 目标态行为、真实 Apple / WeChat provider validation 目标态行为、生产凭证门禁目标态行为和 release gate 目标态边界；目标态行为在实现、验收、测试和追溯证据补齐前不得声明为已实现或 Accepted。

## Owner
Feature Spec Generate Skill（功能规格生成 Skill）

## Product Object
- Product object mode：`product-base-consolidation`
- Source mode：`current-code-baseline-consolidation` + `target-requirement-refinement`
- Module：`Identity & Account Lifecycle / 身份认证与账号生命周期`
- Primary feature：`identity-account-lifecycle`
- Affected features：`access-onboarding`、`profile-membership`、`commercial-subscription`、`ai-provider-operations`、`goal-driven-learning-autopilot`、`learning-memory-review`
- Output path：`docs/product/base/identity-account-lifecycle/spec.md`
- Product Base merge target：后续证据完整并经 Product Manager 批准后，才可合并到 `docs/product/base/spec.md`。

## 上游输入
- Module requirements：`docs/product/base/identity-account-lifecycle/requirements.md`
- Module traceability draft：`docs/product/base/identity-account-lifecycle/traceability.md`
- Product Base requirements：`docs/product/base/requirements.md`
- Product Base spec：`docs/product/base/spec.md`
- Product Base acceptance：`docs/product/base/acceptance.md`
- Product Base traceability：`docs/product/base/traceability.md`
- MVP backend auth requirements：`docs/product/increments/mvp-backend-foundation-auth/requirements.md`
- MVP backend auth spec：`docs/product/increments/mvp-backend-foundation-auth/spec.md`
- P0 commercial readiness stage：`docs/product/stages/p0-commercial-readiness.md`
- Current backend identity, security, ops, audit and deletion code evidence referenced by module traceability.

## 规格目标与稳定能力边界
本规格定义用户从身份证明、账号创建或解析、登录、会话签发、当前用户识别、退出登录，到账号删除、删除审计和基础认证错误的可观察行为边界。规格 item 必须能直接作为后续 acceptance criteria 和 test case 的上游输入。

本规格不定义会员订阅、支付、学习内容、AI 练习、课程推荐、业务学习状态、生产短信 provider 采购方案、Apple / WeChat 商务接入方案或 identity 专属发布门禁实现脚本。跨域数据清理只作为账号删除依赖被引用，不把被清理领域的业务规则纳入 identity 模块。

## Requirement 到 Spec 的映射
| Requirement range | Spec item range | Status |
| --- | --- | --- |
| IDENTITY-ACCOUNT-001..011 | IDENTITY-SPEC-ACCOUNT-001..011 | Code baseline |
| IDENTITY-OTP-001..003 | IDENTITY-SPEC-OTP-001..003 | Code baseline |
| IDENTITY-OTP-004..030, IDENTITY-OTP-032..037 | IDENTITY-SPEC-OTP-004..030, IDENTITY-SPEC-OTP-032..037 | Target pending |
| OTP-TESTABILITY-001 | N/A - QA/testability input | Target QA input |
| IDENTITY-PROVIDER-001..004 | IDENTITY-SPEC-PROVIDER-001..004 | Code baseline |
| IDENTITY-PROVIDER-005..015 | IDENTITY-SPEC-PROVIDER-005..015 | Target pending |
| IDENTITY-LOGIN-001..007 | IDENTITY-SPEC-LOGIN-001..007 | Code baseline |
| IDENTITY-LOGIN-008 | IDENTITY-SPEC-LOGIN-008 | Target pending |
| IDENTITY-TOKEN-001..012 | IDENTITY-SPEC-TOKEN-001..012 | Code baseline |
| IDENTITY-ME-001..006 | IDENTITY-SPEC-ME-001..006 | Code baseline |
| IDENTITY-LINK-001..003 | IDENTITY-SPEC-LINK-001..003 | Code baseline |
| IDENTITY-LOGOUT-001..005 | IDENTITY-SPEC-LOGOUT-001..005 | Code baseline |
| IDENTITY-DELETE-001..020 | IDENTITY-SPEC-DELETE-001..020 | Code baseline |
| IDENTITY-RISK-001..003 | IDENTITY-SPEC-RISK-001..003 | Code baseline |
| IDENTITY-AUDIT-001..006 | IDENTITY-SPEC-AUDIT-001..006 | Code baseline |
| IDENTITY-RELEASE | IDENTITY-SPEC-RELEASE-000 | No accepted baseline |
| IDENTITY-RELEASE-001..003 | IDENTITY-SPEC-RELEASE-001..003 | Release target pending |

## Specification

### 公共状态、输入输出与错误信号定义

本节集中定义后续代码、AC、TC、Domain/API/Architecture 契约会引用的规格级状态、输入、输出、错误、降级和安全信号。这里的 Ref ID 是规格语言，不直接等同于代码枚举、数据库字段或 API schema；后续契约可把这些 Ref ID 映射为正式领域状态、错误码或接口字段。

#### 账号、身份与 Profile
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| ACCOUNT-IN-PHONE-SUBJECT | 输入 | 去除前后空白后的手机号 subject。 |
| ACCOUNT-IN-IDENTITY-KEY | 输入 | 身份来源 provider 和身份 subject 组成的唯一身份键。 |
| ACCOUNT-STATE-ACTIVE | 状态 | 可登录和可访问的 active 用户账号状态。 |
| ONBOARDING-STATE-INCOMPLETE | 状态 | 新账号默认未完成首评。 |
| ONBOARDING-STATE-COMPLETE | 状态 | 用户完成首评后的 onboarding status。 |
| PROFILE-DEFAULT | 输出 | 新账号创建时同步创建的默认 profile。 |
| PROFILE-DEFAULT-TARGET-LEVEL-L1 | 输出 | 默认 profile 的目标等级 `L1`。 |
| PROFILE-DEFAULT-DAILY-MINUTES-10 | 输出 | 默认 profile 的每日分钟数 `10`。 |
| ACCOUNT-ERR-DUPLICATE-IDENTITY | 安全错误 | 同一身份来源和 subject 不得绑定多个用户。 |
| PROVIDER-IN-APPLE | 输入 | Apple 登录入口请求。 |
| PROVIDER-IN-WECHAT | 输入 | WeChat 登录入口请求。 |
| PROVIDER-IN-TOKEN | 输入 | 当前代码基线第三方登录请求携带的非空 provider token；不表示 token 真实性、过期、签名或服务端 provider 校验已完成。 |
| PROVIDER-IN-APPLE-IDENTITY-TOKEN | 输入 | 目标态 Apple 登录提交的 identity token；必须由后端验证签名、issuer、audience 和 expiry 后才能作为身份证明输入。 |
| PROVIDER-IN-APPLE-NONCE | 输入 | 目标态 Apple 登录绑定的一次性 nonce；必须与本次登录 challenge 匹配且不可重放。 |
| PROVIDER-IN-APPLE-AUTHORIZATION-CODE | 输入 | Apple 授权码；可用于平台交互或后续 Apple 流程，但不得作为稳定身份 subject。 |
| PROVIDER-IN-WECHAT-CODE | 输入 | 目标态 WeChat 登录提交的 authorization code；必须由后端使用生产 provider 配置交换并校验成功响应。 |
| PROVIDER-IN-WECHAT-STATE | 输入 | 目标态 WeChat 登录绑定的 `state` 或等效一次性 challenge；必须与本次登录 challenge 匹配且不可重放。 |
| PROVIDER-SUBJECT-HASH | 输出 | 当前代码基线由 provider token hash 得到的第三方身份 subject；不表示 Apple `sub` 或 WeChat `openid` / `unionid` 已验证或使用。 |
| PROVIDER-OUT-STABLE-SUBJECT | 输出 | 目标态 provider verifier 成功后得到的 Apple `sub`、WeChat `unionid` 或允许 fallback 的 WeChat `openid`。 |
| PROVIDER-OUT-SUBJECT-DIGEST | 输出 | 基于 `PROVIDER-OUT-STABLE-SUBJECT` 产生的版本化、不可逆、服务端 secret 保护摘要；不得由 raw provider credential 直接 hash 得到。 |
| PROVIDER-ERR-VALIDATION | 失败 | provider token 缺失或空白时的输入存在性失败。 |
| PROVIDER-ERR-INVALID-CREDENTIAL | 安全错误 | provider identity token、authorization code、签名、issuer、audience、expiry、provider 响应或 stable subject 校验失败。 |
| PROVIDER-ERR-NONCE-MISMATCH | 安全错误 | Apple nonce 缺失、不匹配、过期或重放。 |
| PROVIDER-ERR-STATE-MISMATCH | 安全错误 | WeChat `state` 或等效 challenge 缺失、不匹配、过期或重放。 |
| PROVIDER-ERR-UNAVAILABLE | 失败 | provider 服务不可用、超时或生产 provider 配置不可用。 |
| PROVIDER-ERR-SUBJECT-CONFLICT | 安全错误 | WeChat `openid` fallback 升级到 `unionid` 或 provider stable subject 解析时出现账号冲突。 |
| LINK-OUT-INITIAL-AUTH-IDENTITY | 输出 | 新账号创建后基于本次已验证身份建立的初始登录身份绑定。 |
| LINK-STATE-AUTH-IDENTITY-ACTIVE | 状态 | 新建登录身份默认 active。 |
| LINK-IN-IDENTITY-KEY | 输入 | 身份来源和身份 subject 组成的身份键。 |
| ME-IN-AUTHENTICATED | 输入 | 复用 `TOKEN-FLOW-AUTHENTICATE-BEARER` 得到的常规用户认证上下文。 |
| ME-OUT-CURRENT-USER | 输出 | 当前认证用户的用户标识、display name、avatar ref、locale、account status、onboarding status。 |
| ME-OUT-PROFILE | 输出 | 当前用户 profile 的 target level 和 daily minutes；current code baseline 下缺失 profile 时可为空。 |
| ME-IN-PROFILE-UPDATE | 输入 | 当前用户可编辑资料更新输入，包含展示字段 display name、avatar ref，以及 profile preference 字段 target level、daily minutes、reminder enabled、reminder time；未提供字段保持既有值。 |
| ME-ERR-UNAUTHENTICATED | 安全错误 | 当前用户资料读取或更新时认证上下文缺失或无效。 |
| ME-ERR-INVALID-AVATAR | 失败 | avatar ref 为空白或非内置头像引用。 |

#### 登录、会话与 Token
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| LOGIN-IN-TERMS-ACCEPTED | 输入 | 当前登录请求中用户声明已接受服务条款和隐私政策；不表示 Terms/Privacy consent 持久化已实现。 |
| LOGIN-IN-SCHEMA-VERSION | 输入 | 登录或刷新请求携带的兼容性版本信号；具体字段形态由 API contract 承接。 |
| LOGIN-STATE-PUBLIC-ENDPOINT | 状态 | 手机号、Apple、WeChat 登录入口不要求既有认证 session；该状态不绕过 schema version、terms、凭证或账号状态校验。 |
| LOGIN-IN-PRODUCTION-CREDENTIAL-PROOF | 输入 | 生产目标态凭证证明：手机号登录来自已成功校验并一次性消费的 OTP challenge；Apple / WeChat 登录来自已成功校验的 provider verifier。当前代码基线的非空校验不满足该输入。 |
| LOGIN-STATE-ACCOUNT-ACTIVE | 状态 | 可登录的 active 账号状态。 |
| LOGIN-STATE-SESSION-ACTIVE | 输出 | 为本次解析或创建的用户创建的 active 认证 session。 |
| LOGIN-OUT-TOKEN-PAIR | 输出 | 当前用户、access token、refresh token 和 access token 过期时间；token 生命周期由 `IDENTITY-TOKEN` spec 承接。 |
| LOGIN-ERR-TERMS-REQUIRED | 失败 | 未接受条款时拒绝登录；失败后不得进入身份解析、账号创建或 session 签发。 |
| LOGIN-ERR-INACTIVE-ACCOUNT | 安全错误 | 非 active 账号不得登录；失败后不得创建 session 或返回 token pair。 |
| LOGIN-ERR-UNSUPPORTED-SCHEMA | 失败 | 不支持的 schema version；失败必须发生在认证状态变化前，且不得创建 session、签发 token 或轮换 token。 |
| TOKEN-STATE-OPAQUE | 状态 | 服务端 opaque bearer token，非 JWT；客户端不得从 token 解析身份 claims。 |
| TOKEN-STATE-ACCESS-SESSION-ACTIVE | 状态 | 认证 session 处于 active，access token 摘要匹配且 access expiry 未过期。 |
| TOKEN-STATE-REFRESH-SESSION-ACTIVE | 状态 | 认证 session 处于 active，refresh token 摘要匹配且 refresh expiry 未过期。 |
| TOKEN-IN-BEARER | 输入 | 常规受保护用户请求携带的 Bearer access token；具体 header 字段形态由 API contract 承接。 |
| TOKEN-IN-REFRESH | 输入 | refresh 请求携带的 refresh token。 |
| TOKEN-OUT-ROTATED-TOKEN-PAIR | 输出 | refresh 成功后返回给客户端的新 access token、refresh token 和 access token 过期时间。 |
| TOKEN-STATE-HASH-ROTATED | 状态 | refresh 成功后同一 session 的 access / refresh token 摘要被替换，旧 token 后续匹配失败。 |
| TOKEN-ERR-UNAUTHENTICATED | 安全错误 | token 缺失、格式不匹配、无效、过期、已撤销、已轮换或关联用户不可认证。 |
| TOKEN-SECURE-RANDOM | 安全要求 | 使用密码学安全随机源生成 token 原始值；current Java baseline 使用 `SecureRandom`。 |
| LOGOUT-IN-CURRENT-SESSION | 输入 | 本次 logout 请求通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 得到的当前 session。 |
| LOGOUT-STATE-SESSION-REVOKED | 状态 | session 已撤销。 |
| LOGOUT-OUT-REVOKED-AT | 输出 | 当前 session 的撤销发生时间。 |
| LOGOUT-ERR-UNAUTHENTICATED | 安全错误 | 找不到当前 session 或 session 已无法认证。 |

#### OTP
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| OTP-IN-PHONE-RAW | 输入 | 手机号登录请求中的手机号字段；当前代码基线只要求非空。 |
| OTP-IN-CODE-RAW | 输入 | 手机号登录请求中的验证码字段；当前代码基线只要求非空。 |
| OTP-ERR-VALIDATION | 失败 | 手机号或验证码字段为空时的校验失败。 |
| OTP-IN-PHONE-E164 | 输入 | 规范化后的 E.164 手机号。 |
| OTP-IN-CONTEXT | 输入 | 请求、客户端、设备、IP、device 或 install_id 上下文；不可用的上下文字段可记录为 absent。 |
| OTP-IN-CONSENT | 输入 | 用户已接受当前版本服务条款和隐私政策的证明。 |
| OTP-IN-CAPTCHA | 输入 | 防自动化分层控制的 CAPTCHA 结果。 |
| OTP-STATE-CHALLENGE-ACTIVE | 状态 | 可验证且未过期的 OTP challenge。 |
| OTP-STATE-CHALLENGE-CONSUMED | 状态 | 已被成功验证并原子消费的 OTP challenge。 |
| OTP-STATE-CHALLENGE-EXPIRED | 状态 | OTP challenge 已超过有效期且不可验证。 |
| OTP-STATE-CHALLENGE-INVALIDATED | 状态 | OTP challenge 因重新发送、错误次数超限或其他安全原因不可继续验证。 |
| OTP-STATE-LOCKED | 降级 | 手机号和 purpose 级别因错误次数达到阈值而临时锁定。 |
| OTP-STATE-STEP-UP-REQUIRED | 降级 | 风险策略要求额外验证完成后才允许发放会话。 |
| OTP-ERR-INVALID-PHONE | 失败 | 手机号格式非法、未规范化或国家/地区不支持。 |
| OTP-ERR-CONSENT-REQUIRED | 失败 | 用户未接受当前版本服务条款或隐私政策。 |
| OTP-ERR-RATE-LIMITED | 降级 | 发送频控、IP/device/install_id 限流或冷却时间命中。 |
| OTP-ERR-EXPIRED | 失败 | OTP challenge 已过期。 |
| OTP-ERR-CHALLENGE-ATTEMPTS-EXCEEDED | 安全错误 | 单个 OTP challenge 错误验证次数超过上限。 |
| OTP-ERR-ATTEMPTS-LOCKED | 安全错误 | 返回码 `OTP_ATTEMPTS_LOCKED`。 |
| OTP-ERR-PROVIDER-FAILED | 失败 | 短信 provider 发送失败。 |
| OTP-ERR-RISK-BLOCKED | 安全错误 | 返回码 `OTP_RISK_BLOCKED`，不得发送 OTP 或发放 session。 |
| OTP-ERR-CAPTCHA-FAILED | 安全错误 | CAPTCHA 未通过或缺失。 |
| OTP-AUDIT-SAFE | 输出 | 只包含脱敏或 hash 后手机号、purpose、request_id、风险处置结果和 retention policy version 的 OTP 审计事件。 |

#### 账号删除
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| DELETE-IN-CURRENT-ACCOUNT | 输入 | 通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 的常规 access token 认证解析出的当前账号。 |
| DELETE-IN-IDEMPOTENCY-KEY | 输入 | 当前账号删除请求和运维删除重试请求携带的幂等键；有效长度为 8 到 128 个字符。 |
| DELETE-STATE-ACTIVE | 状态 | 允许发起删除执行的 active 账号状态。 |
| DELETE-STATE-DELETION-REQUESTED | 状态 | 允许发起或重放删除执行的 deletion_requested 账号状态。 |
| DELETE-STATE-DELETED | 状态 | 删除完成后的账号状态。 |
| DELETE-JOB-EXISTING | 输出 | 同一用户和幂等键已经关联的删除任务。 |
| DELETE-JOB-FAILED | 状态 | 可由运维重试的 failed 删除任务。 |
| DELETE-JOB-COMPLETED | 状态 | 已完成删除任务。 |
| DELETE-JOB-IN-PROGRESS | 状态 | 删除任务处于 requested、access_revoked、deleting_learning_data 或 anonymizing_audit_refs。 |
| DELETE-JOB-RETRY-EXISTING | 输出 | 同一删除任务和同一重试幂等键已经存在时返回的删除任务当前状态。 |
| DELETE-ERR-IDEMPOTENCY-KEY | 失败 | 幂等键缺失、长度小于 8 个字符或大于 128 个字符。 |
| DELETE-ERR-INVALID-STATE | 安全错误 | 账号或 job 状态不允许删除或重试。 |
| DELETE-ERR-JOB-NOT-FOUND | 失败 | 当前账号不存在任何删除任务。 |
| DELETE-ERR-IN-PROGRESS | 失败 | 删除任务仍在处理中，不允许启动新的重试执行。 |
| DELETE-CLEANUP-AI | 输出 | AI media、TTS cache ownership 和 provider metric 数据清理。 |
| DELETE-CLEANUP-IDENTITY | 输出 | 登录身份数据和 profile 明细数据清理。 |
| DELETE-CLEANUP-LEARNING | 输出 | onboarding、learning route、scenario、practice、training、learning memory 数据清理。 |
| DELETE-CLEANUP-COMMERCE | 输出 | purchase、subscription、entitlement、usage 和 payment provider event 数据清理。 |
| DELETE-CLEANUP-GOAL | 输出 | goal/autopilot 相关数据清理。 |

#### 审计、风控与 release 边界
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| RISK-IN-BEARER | 输入 | 受保护用户请求携带的 bearer token；是否能建立常规用户认证上下文由 `TOKEN-FLOW-AUTHENTICATE-BEARER` 判定。 |
| RISK-IN-OPS-BEARER | 输入 | admin 请求携带的 ops bearer token。 |
| RISK-OUT-UNAUTHENTICATED-JSON | 输出 | 未建立常规用户认证上下文时返回的 JSON 未认证错误响应。 |
| RISK-ERR-ADMIN-FORBIDDEN | 安全错误 | 已建立常规用户认证上下文但不具备 ops 权限的请求访问 admin 入口时的安全错误。 |
| RISK-SEC-OPS-TOKEN-DIGEST-MATCH | 安全要求 | ops bearer token 原始值必须与服务端保存的 ops token 摘要匹配，不得使用 ops token 明文作为比较基准。 |
| AUDIT-IN-RAW | 输入 | 审计记录创建时接收的原始目标引用、请求标识和详情内容。 |
| AUDIT-OUT-REDACTED | 输出 | 已按 `AUDIT-SENSITIVE-PATTERN` 清洗后的审计目标引用、请求标识和详情内容。 |
| AUDIT-SENSITIVE-PATTERN | 安全要求 | key token 封闭集合为 `api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`；value pattern 封闭集合为 `signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`；安全占位为 sensitive details key `redacted_field_<index>` + value `redacted`、sensitive details value `redacted`、target ref `redacted:target_ref`、request id `unknown`。 |
| AUDIT-EVENT-DELETION-COMPLETED | 输出 | 账号删除执行完成审计事件；必须能区分普通完成与运维重试完成。 |
| AUDIT-EVENT-DELETION-FAILED | 输出 | 账号删除执行失败审计事件；必须能区分普通失败与运维重试失败。 |
| AUDIT-EVENT-DELETION-RETRY | 输出 | 通过 ops 运维认证并被接受进入处理的账号删除重试请求审计事件。 |
| AUDIT-EVENT-QUERY | 输出 | ops admin 审计日志列表查询行为审计事件。 |
| RELEASE-BOUNDARY-NO-BASELINE | 范围边界 | 当前没有 identity 专属已实现 release gate 可归档为 Product Base 代码基线；通用 release health warning 不构成 identity 专属生产阻断。 |
| RELEASE-TARGET-PENDING | 目标边界 | 生产禁用 fake OTP、禁用未校验 provider token、identity provider 配置阻断和 identity 专属 release gate 均仍为未实现目标。 |
| RELEASE-ERR-IDENTITY-BACKEND-UNVERIFIED | 安全错误 | 生产发布门禁发现后端仍允许未消费 OTP challenge 登录，或仍允许 raw provider credential hash 作为 Apple / WeChat stable subject。 |
| RELEASE-ERR-IDENTITY-PROVIDER-CONFIG | 安全错误 | 生产发布门禁发现真实 SMS、Apple 或 WeChat provider 配置缺失、使用 placeholder/native test 配置，或缺少外部证据引用。 |
| RELEASE-OUT-IDENTITY-EVIDENCE | 输出 | 生产发布门禁要求的 identity 证据引用，包括 OTP provider、Apple verifier、WeChat verifier、配置来源、外部 provider 校验证据和执行时间。 |

### IDENTITY-ACCOUNT 账号创建与身份解析

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-ACCOUNT-001 | IDENTITY-ACCOUNT-001 | Code baseline | 手机号登录解析身份时，系统必须在 current code baseline 下使用 `ACCOUNT-IN-PHONE-SUBJECT` 作为 `phone` provider 的 subject；该规格不表示目标态 E.164 normalization。 |
| IDENTITY-SPEC-ACCOUNT-002 | IDENTITY-ACCOUNT-002 | Code baseline | 当存在 `ACCOUNT-IN-IDENTITY-KEY` 对应身份时，系统必须解析到该身份绑定的已有账号；账号 active/inactive 登录校验由 `IDENTITY-SPEC-LOGIN-004` 处理。 |
| IDENTITY-SPEC-ACCOUNT-003 | IDENTITY-ACCOUNT-003 | Code baseline | 当身份凭证已验证且未解析到 `ACCOUNT-IN-IDENTITY-KEY` 时，系统必须创建新的用户账号；目标态 OTP 只在 verify success 后进入本创建流程。 |
| IDENTITY-SPEC-ACCOUNT-004 | IDENTITY-ACCOUNT-004 | Code baseline | 新用户账号创建后必须进入 `ACCOUNT-STATE-ACTIVE`。 |
| IDENTITY-SPEC-ACCOUNT-005 | IDENTITY-ACCOUNT-005 | Code baseline | 新用户账号创建后必须进入 `ONBOARDING-STATE-INCOMPLETE`。 |
| IDENTITY-SPEC-ACCOUNT-006 | IDENTITY-ACCOUNT-006 | Code baseline | 新用户账号创建后必须初始化 locale 为 `zh-CN`。 |
| IDENTITY-SPEC-ACCOUNT-007 | IDENTITY-ACCOUNT-007 | Code baseline | 新用户账号创建时必须绑定本次通过认证的 provider+subject，并使该初始登录身份进入 active。 |
| IDENTITY-SPEC-ACCOUNT-008 | IDENTITY-ACCOUNT-008 | Code baseline | 新用户账号创建时必须同时创建 `PROFILE-DEFAULT`。 |
| IDENTITY-SPEC-ACCOUNT-009 | IDENTITY-ACCOUNT-009 | Code baseline | 当同一 `ACCOUNT-IN-IDENTITY-KEY` 试图绑定多个用户时，系统必须保持既有绑定不变，不得创建重复身份，并返回 `ACCOUNT-ERR-DUPLICATE-IDENTITY`。 |
| IDENTITY-SPEC-ACCOUNT-010 | IDENTITY-ACCOUNT-010 | Code baseline | `PROFILE-DEFAULT` 的 target level 必须为 `PROFILE-DEFAULT-TARGET-LEVEL-L1`。 |
| IDENTITY-SPEC-ACCOUNT-011 | IDENTITY-ACCOUNT-011 | Code baseline | `PROFILE-DEFAULT` 的 daily minutes 必须为 `PROFILE-DEFAULT-DAILY-MINUTES-10`。 |

### IDENTITY-OTP 手机短信 OTP

#### 当前代码基线（已实现）

##### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-OTP-001 | IDENTITY-OTP-001 | Code baseline | Current code baseline 下，手机号登录请求必须包含非空 `OTP-IN-PHONE-RAW`；该 item 不表示 `OTP-IN-PHONE-E164` 或 OTP challenge 已实现。 |
| IDENTITY-SPEC-OTP-002 | IDENTITY-OTP-002 | Code baseline | Current code baseline 下，手机号登录请求必须包含非空 `OTP-IN-CODE-RAW`；该 item 不表示验证码正确性、过期、一次性消费或重放控制已实现。 |
| IDENTITY-SPEC-OTP-003 | IDENTITY-OTP-003 | Code baseline | 当 `OTP-IN-PHONE-RAW` 或 `OTP-IN-CODE-RAW` 为空时，系统必须返回 `OTP-ERR-VALIDATION`，停止手机号登录处理，并不得进入身份解析、账号创建或 session 签发流程。 |

#### 真实短信 OTP 目标态（Proposed / 待实现）

##### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| OTP-FLOW-SEND | 用户请求手机号登录或注册 OTP。 | 手机号可规范化、consent 有效、频控和风险允许、provider 可用。 | 创建 `OTP-STATE-CHALLENGE-ACTIVE`，发送 SMS。不得创建账号或认证 session。 | 手机号非法、consent 缺失、频控、风险阻断、provider 失败或 CAPTCHA 未通过时，不得创建可验证 challenge 或 session。 |
| OTP-FLOW-RESEND | 用户重新发送 OTP。 | 已有 active challenge 或同一手机号可再次请求。 | 旧 active challenge 进入 `OTP-STATE-CHALLENGE-INVALIDATED`，失败计数不重置；新的可验证 challenge 按发送流程创建。 | 频控、风险、provider 或 consent 失败时，不得产生新的可验证 challenge。 |
| OTP-FLOW-VERIFY | 用户提交手机号 OTP。 | challenge active、未过期、未超出错误次数、未被消费或失效。 | 正确 OTP 使 challenge 进入 `OTP-STATE-CHALLENGE-CONSUMED`，随后进入账号创建或解析流程，并按 token 生命周期发放会话。 | 过期、错误次数超限、累计锁定、重放、风险阻断或验证码错误时，不得创建账号或发放 session。 |
| OTP-FLOW-RISK | 发送或验证前触发风险评估。 | 存在手机号、purpose 和请求上下文。 | allow 继续；step-up 进入 `OTP-STATE-STEP-UP-REQUIRED`；block 返回风险阻断。 | block 时不得发送 OTP 或发放 session；step-up 未完成时不得发放 session。 |
| OTP-FLOW-PROVIDER-FAILURE | SMS provider 发送失败。 | 发送流程已通过前置校验但 provider 不可用或失败。 | 返回 `OTP-ERR-PROVIDER-FAILED`。 | 不得创建可验证 challenge，不得创建账号或认证 session。 |

##### Product Behavior Target Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-OTP-004 | IDENTITY-OTP-004 | Target pending | 所有接收手机号的 OTP 入口必须输出 `OTP-IN-PHONE-E164`；非法或不支持号码必须返回 `OTP-ERR-INVALID-PHONE`，且不得创建 challenge 或 session。 |
| IDENTITY-SPEC-OTP-005 | IDENTITY-OTP-005 | Target pending | OTP-FLOW-SEND 在手机号、consent、频控、风险和 provider 前置校验通过后，只能创建 `OTP-STATE-CHALLENGE-ACTIVE` 并发送 SMS，不得创建用户账号或认证 session。 |
| IDENTITY-SPEC-OTP-006 | IDENTITY-OTP-006 | Target pending | `OTP-STATE-CHALLENGE-ACTIVE` 必须绑定 `OTP-IN-PHONE-E164`、`purpose=login_or_register`、`challenge_id`、`OTP-IN-CONTEXT` 和过期时间。 |
| IDENTITY-SPEC-OTP-007 | IDENTITY-OTP-007 | Target pending | OTP 原始值必须由服务端安全随机能力生成。 |
| IDENTITY-SPEC-OTP-032 | IDENTITY-OTP-032 | Target pending | OTP 默认格式必须为 6 位数字，且 OTP 位数配置不得低于 6 位。 |
| IDENTITY-SPEC-OTP-008 | IDENTITY-OTP-008 | Target pending | `OTP-STATE-CHALLENGE-ACTIVE` 默认可验证 5 分钟，且有效期配置不得超过 10 分钟；过期后进入 `OTP-STATE-CHALLENGE-EXPIRED` 并返回 `OTP-ERR-EXPIRED`。 |
| IDENTITY-SPEC-OTP-009 | IDENTITY-OTP-009 | Target pending | OTP 明文只允许进入短信发送流程，不得持久化、写入日志或进入错误响应。 |
| IDENTITY-SPEC-OTP-010 | IDENTITY-OTP-010 | Target pending | OTP 持久化校验值必须使用 keyed HMAC 或等效 secret-peppered hash，并绑定 challenge 和 `OTP-IN-PHONE-E164`；不得保存可逆明文或普通裸 hash。 |
| IDENTITY-SPEC-OTP-011 | IDENTITY-OTP-011 | Target pending | OTP-FLOW-SEND 必须校验 `OTP-IN-CONSENT`；consent 缺失或版本不匹配时返回 `OTP-ERR-CONSENT-REQUIRED`，且不得创建 challenge 或 session。 |
| IDENTITY-SPEC-OTP-012 | IDENTITY-OTP-012 | Target pending | 同一手机号重复发送 OTP 必须命中默认 60 秒冷却控制，否则返回 `OTP-ERR-RATE-LIMITED`。 |
| IDENTITY-SPEC-OTP-013 | IDENTITY-OTP-013 | Target pending | 同一手机号发送 OTP 必须按可配置窗口限流，默认每小时最多 5 次且每天最多 10 次；超限返回 `OTP-ERR-RATE-LIMITED`。 |
| IDENTITY-SPEC-OTP-014 | IDENTITY-OTP-014 | Target pending | OTP 发送限流必须覆盖 IP、device 和 install_id：默认每个 IP 每小时最多 30 次且每天最多 100 次，每个 device 或 install_id 每小时最多 10 次且每天最多 30 次；超限返回 `OTP-ERR-RATE-LIMITED`。 |
| IDENTITY-SPEC-OTP-015 | IDENTITY-OTP-015 | Target pending | OTP-FLOW-RESEND 后，旧 `OTP-STATE-CHALLENGE-ACTIVE` 必须进入 `OTP-STATE-CHALLENGE-INVALIDATED`，且不得重置手机号和 purpose 级别失败计数。 |
| IDENTITY-SPEC-OTP-016 | IDENTITY-OTP-016 | Target pending | 单个 OTP challenge 默认最多允许 5 次错误验证；超过上限后必须进入 `OTP-STATE-CHALLENGE-INVALIDATED` 并返回 `OTP-ERR-CHALLENGE-ATTEMPTS-EXCEEDED`。 |
| IDENTITY-SPEC-OTP-017 | IDENTITY-OTP-017 | Target pending | OTP 验证失败必须增加手机号和 purpose 级别失败计数；同一手机号和 purpose 在 30 分钟内累计 10 次错误验证后进入 `OTP-STATE-LOCKED` 15 分钟并返回 `OTP-ERR-ATTEMPTS-LOCKED`。 |
| IDENTITY-SPEC-OTP-018 | IDENTITY-OTP-018 | Target pending | OTP 验证成功必须使 active challenge 只成功一次地进入 `OTP-STATE-CHALLENGE-CONSUMED`；已消费 challenge 不得再次验证成功。 |
| IDENTITY-SPEC-OTP-033 | IDENTITY-OTP-033 | Target pending | 只有 `OTP-STATE-CHALLENGE-CONSUMED` 的 challenge 才能进入账号创建或账号解析流程。 |
| IDENTITY-SPEC-OTP-019 | IDENTITY-OTP-019 | Target pending | OTP 验证成功后，系统必须按 `IDENTITY-SPEC-TOKEN-*` 签发 access token 和 refresh token，并返回登录会话输出。 |
| IDENTITY-SPEC-OTP-020 | IDENTITY-OTP-020 | Target pending | 已存在手机号身份时，OTP 验证成功必须解析到原用户，不得重复创建账号。 |
| IDENTITY-SPEC-OTP-021 | IDENTITY-OTP-021 | Target pending | 新手机号首次 OTP 验证成功后，系统必须进入 `IDENTITY-SPEC-ACCOUNT-003..011` 定义的账号创建、初始登录身份绑定和默认 profile 初始化流程。 |
| IDENTITY-SPEC-OTP-022 | IDENTITY-OTP-022 | Target pending | OTP 相关错误响应不得泄露手机号是否已注册。 |
| IDENTITY-SPEC-OTP-023 | IDENTITY-OTP-023 | Target pending | 短信 provider 发送失败时，系统必须返回 `OTP-ERR-PROVIDER-FAILED`，且不得创建可验证 challenge 或认证 session。 |

##### Security and Abuse-Control Target Boundary Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-OTP-025 | IDENTITY-OTP-025 | Target pending | SMS 发送内容必须包含 App 名称、验证码、有效期和风险提示，且不得包含用户 ID、token、profile 信息或其他敏感资料。 |
| IDENTITY-SPEC-OTP-026 | IDENTITY-OTP-026 | Target pending | 生产 OTP 请求只能由安全传输入口处理；非 HTTPS 生产入口不得处理 OTP 请求，并必须返回安全错误或由安全网关阻断。 |
| IDENTITY-SPEC-OTP-027 | IDENTITY-OTP-027 | Target pending | OTP 审计必须记录 `otp_send_requested`、`otp_verify_succeeded`、`otp_verify_failed`、`otp_expired`、`otp_rate_limited` 和 `otp_provider_failed` 事件。 |
| IDENTITY-SPEC-OTP-034 | IDENTITY-OTP-034 | Target pending | OTP 审计必须只写入 `OTP-AUDIT-SAFE`，不得记录 OTP 明文或 token 明文。 |
| IDENTITY-SPEC-OTP-028 | IDENTITY-OTP-028 | Target pending | OTP 风险策略输入必须纳入 SIM swap 或号码转移、异常设备、异常 IP 和短时大量请求风险信号。 |
| IDENTITY-SPEC-OTP-035 | IDENTITY-OTP-035 | Target pending | OTP 策略命中 block 级风险时，系统必须返回 `OTP-ERR-RISK-BLOCKED`，且不得发送 OTP 或发放 session。 |
| IDENTITY-SPEC-OTP-036 | IDENTITY-OTP-036 | Target pending | OTP 策略命中 step-up 级风险时，系统必须进入 `OTP-STATE-STEP-UP-REQUIRED`；额外验证完成前不得发放 session。 |
| IDENTITY-SPEC-OTP-029 | IDENTITY-OTP-029 | Target pending | CAPTCHA 只能作为防自动化分层控制；`OTP-IN-CAPTCHA` 未通过时返回 `OTP-ERR-CAPTCHA-FAILED`，不得发送 OTP 或发放 session；CAPTCHA 通过后仍必须完成正确 OTP 校验。 |
| IDENTITY-SPEC-OTP-030 | IDENTITY-OTP-030 | Target pending | OTP challenge 和校验值必须接入保留策略，并在过期后 24 小时内删除或失效。 |
| IDENTITY-SPEC-OTP-037 | IDENTITY-OTP-037 | Target pending | OTP 审计事件必须保留脱敏数据和 retention policy 版本。 |

##### Release / DevOps Target Boundary Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-OTP-024 | IDENTITY-OTP-024 | Target pending | 生产环境必须禁用 deterministic 或 test OTP provider；错误配置必须由 release gate 阻断。 |

##### Testability Expectations（Not Product Spec Items）
| Testability ID | Source | Status | Expectation |
| --- | --- | --- | --- |
| OTP-TESTABILITY-001 | QA/testability input moved from removed target OTP test item | Target QA input | OTP 测试设计应使用可控时间和 fake SMS provider，覆盖验证成功、过期、重放、限流和 provider 失败。 |

### IDENTITY-PROVIDER Apple / WeChat 第三方身份

#### 当前代码基线（已实现）

##### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-PROVIDER-001 | IDENTITY-PROVIDER-001 | Code baseline | Current code baseline 下，Apple 登录入口必须把 `PROVIDER-IN-APPLE` 归属为 `apple` 身份来源；该 item 不表示 Apple identity token validation 或 Apple stable subject extraction 已实现。 |
| IDENTITY-SPEC-PROVIDER-002 | IDENTITY-PROVIDER-002 | Code baseline | Current code baseline 下，WeChat 登录入口必须把 `PROVIDER-IN-WECHAT` 归属为 `wechat` 身份来源；该 item 不表示 WeChat code/session/openid/unionid validation 或 stable subject extraction 已实现。 |
| IDENTITY-SPEC-PROVIDER-003 | IDENTITY-PROVIDER-003 | Code baseline | Current code baseline 下，第三方登录请求必须包含非空 `PROVIDER-IN-TOKEN`；缺失或空白时返回 `PROVIDER-ERR-VALIDATION`；该 item 不表示 provider token 真实性、过期、签名或服务端校验已实现。 |
| IDENTITY-SPEC-PROVIDER-004 | IDENTITY-PROVIDER-004 | Code baseline | Current code baseline 下，系统必须把 `PROVIDER-IN-TOKEN` 计算为 `PROVIDER-SUBJECT-HASH` 并作为第三方身份 subject；该 item 不表示 Apple `sub` 或 WeChat `openid` / `unionid` 已验证或使用。 |

#### 真实 Apple / WeChat provider validation 目标态（Proposed / 待实现）

##### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| PROVIDER-FLOW-APPLE-VERIFY | 客户端提交 Apple 登录凭证。 | 请求包含 `PROVIDER-IN-APPLE-IDENTITY-TOKEN` 和 `PROVIDER-IN-APPLE-NONCE`。 | 后端验证 Apple identity token 签名、issuer、audience、expiry 和 nonce；成功后输出 Apple stable subject。 | identity token、issuer、audience、expiry、nonce 或 provider 可用性失败时，返回 provider 错误，不得进入身份解析、账号创建或 session 签发。 |
| PROVIDER-FLOW-WECHAT-VERIFY | 客户端提交 WeChat 登录凭证。 | 请求包含 `PROVIDER-IN-WECHAT-CODE` 和 `PROVIDER-IN-WECHAT-STATE`，且生产 WeChat provider 配置可用。 | 后端交换 authorization code 并校验 provider 响应；成功后输出 WeChat stable subject。 | code、state、provider 响应、stable subject、subject conflict 或 provider 可用性失败时，返回 provider 错误，不得进入身份解析、账号创建或 session 签发。 |
| PROVIDER-FLOW-SUBJECT-DERIVE | provider verifier 已成功校验 Apple 或 WeChat 身份。 | 存在 `PROVIDER-OUT-STABLE-SUBJECT`。 | 生成 `PROVIDER-OUT-SUBJECT-DIGEST` 或直接使用已验证 stable subject 作为身份键 subject，并进入账号解析或账号创建流程。 | 若系统将 raw provider token、Apple authorization code、Apple identity token 或 WeChat code 的 hash 作为 stable subject，或在无明确单一 WeChat app 边界时使用 `openid` fallback，必须视为生产目标态失败。 |

##### Target Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-PROVIDER-005 | IDENTITY-PROVIDER-005 | Target pending | `PROVIDER-FLOW-APPLE-VERIFY` 必须由后端校验 `PROVIDER-IN-APPLE-IDENTITY-TOKEN` 的签名、issuer、audience 和 expiry；校验通过前不得进入身份解析、账号创建或 session 签发。 |
| IDENTITY-SPEC-PROVIDER-006 | IDENTITY-PROVIDER-006 | Target pending | `PROVIDER-FLOW-APPLE-VERIFY` 必须校验 `PROVIDER-IN-APPLE-NONCE`；nonce 缺失、不匹配、过期或重放时返回 `PROVIDER-ERR-NONCE-MISMATCH`，且不得进入身份解析、账号创建或 session 签发。 |
| IDENTITY-SPEC-PROVIDER-007 | IDENTITY-PROVIDER-007 | Target pending | Apple stable subject 必须来自已验证 Apple `sub`，或来自基于已验证 `sub` 的版本化、不可逆、服务端 secret 保护摘要；不得使用 raw identity token、authorization code 或 provider token hash 作为 stable subject。 |
| IDENTITY-SPEC-PROVIDER-008 | IDENTITY-PROVIDER-008 | Target pending | `PROVIDER-FLOW-WECHAT-VERIFY` 必须由后端使用生产 provider 配置交换 `PROVIDER-IN-WECHAT-CODE`，并校验 provider 响应成功后才允许进入身份解析、账号创建或 session 签发。 |
| IDENTITY-SPEC-PROVIDER-009 | IDENTITY-PROVIDER-009 | Target pending | `PROVIDER-FLOW-WECHAT-VERIFY` 必须校验 `PROVIDER-IN-WECHAT-STATE` 或等效一次性 challenge；缺失、不匹配、过期或重放时返回 `PROVIDER-ERR-STATE-MISMATCH`，且不得进入身份解析、账号创建或 session 签发。 |
| IDENTITY-SPEC-PROVIDER-010 | IDENTITY-PROVIDER-010 | Target pending | WeChat provider 响应包含已验证 `unionid` 时，`PROVIDER-OUT-STABLE-SUBJECT` 必须使用该 `unionid`，不得优先使用 `openid`。 |
| IDENTITY-SPEC-PROVIDER-011 | IDENTITY-PROVIDER-011 | Target pending | Apple / WeChat provider validation 出现签名、issuer、audience、expiry、nonce、state、provider 错误响应或 stable subject 缺失时，系统必须返回 `PROVIDER-ERR-INVALID-CREDENTIAL`、`PROVIDER-ERR-NONCE-MISMATCH` 或 `PROVIDER-ERR-STATE-MISMATCH`，并在身份解析、账号创建和 session 签发前停止处理。 |
| IDENTITY-SPEC-PROVIDER-012 | IDENTITY-PROVIDER-012 | Target pending | Apple / WeChat provider 不可用、超时或配置不可用时，系统必须返回 `PROVIDER-ERR-UNAVAILABLE`，不得创建账号、绑定身份或签发 session。 |
| IDENTITY-SPEC-PROVIDER-013 | IDENTITY-PROVIDER-013 | Target pending | `PROVIDER-FLOW-SUBJECT-DERIVE` 在生产目标态不得把 raw provider token、Apple authorization code、Apple identity token 或 WeChat code 的 hash 作为 Apple / WeChat stable subject。 |
| IDENTITY-SPEC-PROVIDER-014 | IDENTITY-PROVIDER-014 | Target pending | WeChat `openid` 只能在已明确单一 WeChat app 边界且 provider 响应缺少 `unionid` 时作为 `PROVIDER-OUT-STABLE-SUBJECT` fallback；缺少该边界时必须返回 `PROVIDER-ERR-INVALID-CREDENTIAL`，不得创建账号、绑定身份或签发 session。 |
| IDENTITY-SPEC-PROVIDER-015 | IDENTITY-PROVIDER-015 | Target pending | WeChat `openid` fallback 身份后续获得已验证 `unionid` 或出现 subject conflict 时，系统必须解析到既有账号或返回 `PROVIDER-ERR-SUBJECT-CONFLICT` 并停止处理，不得重复创建账号。 |

### IDENTITY-LOGIN 登录与 session 签发

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| LOGIN-FLOW-AUTHENTICATE | 未认证客户端调用手机号、Apple 或 WeChat 登录入口。 | 入口为 `LOGIN-STATE-PUBLIC-ENDPOINT`。 | 系统按 schema version、terms、凭证/身份输入、账号状态顺序处理；生产目标态还必须满足 `LOGIN-IN-PRODUCTION-CREDENTIAL-PROOF`；通过后创建 `LOGIN-STATE-SESSION-ACTIVE` 并返回 `LOGIN-OUT-TOKEN-PAIR`。 | schema version、terms、凭证/身份输入、生产可信凭证证明或账号状态失败时，不得创建 session、发放 token 或返回 token pair。 |
| LOGIN-FLOW-REFRESH-SCHEMA | 客户端提交刷新请求。 | 请求进入 refresh token 生命周期处理前。 | schema version 支持时继续进入 `IDENTITY-SPEC-TOKEN-*` refresh 流程。 | schema version 不支持时返回 `LOGIN-ERR-UNSUPPORTED-SCHEMA`，不得刷新或轮换 token。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-LOGIN-001 | IDENTITY-LOGIN-001 | Code baseline | Current code baseline 下，手机号登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续认证处理；否则返回 `LOGIN-ERR-TERMS-REQUIRED`，并不得进入身份解析、账号创建或 session 签发流程。 |
| IDENTITY-SPEC-LOGIN-002 | IDENTITY-LOGIN-002 | Code baseline | Current code baseline 下，Apple / WeChat 登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续认证处理；否则返回 `LOGIN-ERR-TERMS-REQUIRED`，并不得进入 provider token subject 处理、身份解析、账号创建或 session 签发流程。 |
| IDENTITY-SPEC-LOGIN-003 | IDENTITY-LOGIN-003 | Code baseline | 手机号、Apple 和 WeChat 登录入口必须处于 `LOGIN-STATE-PUBLIC-ENDPOINT`；该状态只表示不要求既有认证 session，仍必须执行 schema version、terms、凭证和账号状态门禁。 |
| IDENTITY-SPEC-LOGIN-004 | IDENTITY-LOGIN-004 | Code baseline | 账号不处于 `LOGIN-STATE-ACCOUNT-ACTIVE` 时，系统必须返回 `LOGIN-ERR-INACTIVE-ACCOUNT` 并拒绝登录；不得创建 `LOGIN-STATE-SESSION-ACTIVE` 或返回 `LOGIN-OUT-TOKEN-PAIR`。 |
| IDENTITY-SPEC-LOGIN-005 | IDENTITY-LOGIN-005 | Code baseline | 登录请求通过 schema version、terms、凭证和账号状态门禁后，系统必须为本次解析或创建的用户创建 `LOGIN-STATE-SESSION-ACTIVE`。 |
| IDENTITY-SPEC-LOGIN-006 | IDENTITY-LOGIN-006 | Code baseline | 登录成功响应必须返回 `LOGIN-OUT-TOKEN-PAIR`；token 生命周期、有效期和轮换行为以 `IDENTITY-SPEC-TOKEN-*` 为 source of truth。 |
| IDENTITY-SPEC-LOGIN-007 | IDENTITY-LOGIN-007 | Code baseline | 登录和刷新请求携带不支持的 `LOGIN-IN-SCHEMA-VERSION` 时，系统必须在认证状态变化前返回 `LOGIN-ERR-UNSUPPORTED-SCHEMA`；失败后不得创建 session、签发 token 或轮换 token；API 字段形态由 API contract 承接。 |
| IDENTITY-SPEC-LOGIN-008 | IDENTITY-LOGIN-008 | Target pending | 生产目标态的 `LOGIN-FLOW-AUTHENTICATE` 必须在身份解析、账号创建或 session 签发前满足 `LOGIN-IN-PRODUCTION-CREDENTIAL-PROOF`：手机号登录来自已成功校验并一次性消费的 OTP challenge；Apple / WeChat 登录来自已成功校验的 provider verifier。仅校验手机号、验证码或 provider token 非空不得满足该输入。 |

### IDENTITY-TOKEN Access / refresh token 生命周期

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| TOKEN-FLOW-ISSUE | 登录或刷新流程通过前置门禁。 | 账号和会话状态满足对应登录或刷新规格。 | 系统生成 `TOKEN-STATE-OPAQUE` access token 与 refresh token，只持久化 token 摘要，并向客户端返回 token pair。 | 任一前置门禁失败时，不得创建 session、替换 token 摘要或返回 token pair。 |
| TOKEN-FLOW-AUTHENTICATE-BEARER | 常规受保护用户请求携带 access token。 | 请求包含 `TOKEN-IN-BEARER`。 | access token 匹配 `TOKEN-STATE-ACCESS-SESSION-ACTIVE` 且关联用户 active 时，建立常规用户认证上下文。 | token 缺失、格式不匹配、无效、过期、已撤销、已轮换或关联用户不可认证时，返回 `TOKEN-ERR-UNAUTHENTICATED`，不得建立用户认证上下文。 |
| TOKEN-FLOW-REFRESH | 客户端提交 refresh token。 | `LOGIN-FLOW-REFRESH-SCHEMA` 已通过。 | `TOKEN-IN-REFRESH` 匹配 `TOKEN-STATE-REFRESH-SESSION-ACTIVE` 且关联用户 active 时，返回 `TOKEN-OUT-ROTATED-TOKEN-PAIR` 并进入 `TOKEN-STATE-HASH-ROTATED`。 | refresh token 不满足 eligibility 或关联用户不可认证时，返回 `TOKEN-ERR-UNAUTHENTICATED`，不得创建 session、替换 token 摘要或返回新 token pair。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-TOKEN-001 | IDENTITY-TOKEN-001 | Code baseline | 登录或刷新成功时，系统必须签发 `TOKEN-STATE-OPAQUE` access token 和 refresh token，并把该 token pair 返回给客户端；JWT claims、JWT 签名校验和 JWKS 不属于当前代码基线。 |
| IDENTITY-SPEC-TOKEN-002 | IDENTITY-TOKEN-002 | Code baseline | 系统必须分别使用 `TOKEN-SECURE-RANDOM` 为 access token 和 refresh token 生成不可预测原始值；current Java baseline 使用 `SecureRandom`。 |
| IDENTITY-SPEC-TOKEN-003 | IDENTITY-TOKEN-003 | Code baseline | 认证 session 持久化状态必须只保存 access token 和 refresh token 的摘要值；token 明文只能在签发或刷新成功响应中返回给客户端，不得写入持久化 session。 |
| IDENTITY-SPEC-TOKEN-004 | IDENTITY-TOKEN-004 | Code baseline | access token 的 `expiresAt` 必须从登录签发或 refresh 轮换时起计算为 30 分钟，并随成功响应返回。 |
| IDENTITY-SPEC-TOKEN-005 | IDENTITY-TOKEN-005 | Code baseline | refresh token 的 refresh expiry 必须从登录签发或 refresh 轮换时起计算为 30 天，并用于后续 refresh eligibility 判断。 |
| IDENTITY-SPEC-TOKEN-006 | IDENTITY-TOKEN-006 | Code baseline | 常规受保护用户请求必须从 `TOKEN-IN-BEARER` 提取 access token；缺失、格式不匹配或认证失败时不得建立用户认证上下文，并按受保护端点规则返回 `TOKEN-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-TOKEN-007 | IDENTITY-TOKEN-007 | Code baseline | access token 只有匹配 `TOKEN-STATE-ACCESS-SESSION-ACTIVE` 时才能通过常规用户认证；未匹配、过期、已撤销或已轮换时必须返回 `TOKEN-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-TOKEN-008 | IDENTITY-TOKEN-008 | Code baseline | 常规 access token 认证必须要求关联用户为 active 状态，否则返回 `TOKEN-ERR-UNAUTHENTICATED`；账号删除重试 fallback 使用同一 access token 输入但由 `IDENTITY-SPEC-DELETE-*` 承接。 |
| IDENTITY-SPEC-TOKEN-009 | IDENTITY-TOKEN-009 | Code baseline | 在 `LOGIN-FLOW-REFRESH-SCHEMA` 通过后，`TOKEN-IN-REFRESH` 只有匹配 `TOKEN-STATE-REFRESH-SESSION-ACTIVE` 且关联用户为 active 状态时才能刷新；否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-TOKEN-010 | IDENTITY-TOKEN-010 | Code baseline | refresh 成功必须在同一 session 上生成新的 access token 和 refresh token，产生 `TOKEN-OUT-ROTATED-TOKEN-PAIR`，替换持久化 access / refresh token 摘要进入 `TOKEN-STATE-HASH-ROTATED`，并使旧 access / refresh token 后续匹配失败。 |
| IDENTITY-SPEC-TOKEN-011 | IDENTITY-TOKEN-011 | Code baseline | refresh token 缺失、空白、无效、过期、已撤销 session 关联或已被轮换后，系统必须返回 `TOKEN-ERR-UNAUTHENTICATED`，且不得创建 session、替换 token 摘要或返回新 token pair。 |
| IDENTITY-SPEC-TOKEN-012 | IDENTITY-TOKEN-012 | Code baseline | 当前代码基线的受保护 API 认证必须不创建或依赖服务端 HTTP session；认证成功来自 bearer token 匹配持久化认证 session，Spring Security stateless 配置仅作为实现证据。 |

### IDENTITY-ME 当前用户与 profile

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| ME-FLOW-READ-CURRENT | 已认证用户请求读取当前用户资料。 | 请求满足 `ME-IN-AUTHENTICATED`。 | 返回 `ME-OUT-CURRENT-USER` 和 `ME-OUT-PROFILE`。 | 认证上下文缺失或无效时返回 `ME-ERR-UNAUTHENTICATED`，不得返回当前用户或 profile 输出。 |
| ME-FLOW-UPDATE-PROFILE | 已认证用户提交当前用户可编辑资料更新。 | 请求满足 `ME-IN-AUTHENTICATED`，输入满足 `ME-IN-PROFILE-UPDATE`。 | 保存允许更新的当前用户展示字段和 profile preference 字段；未提供字段保持既有值。 | 认证上下文缺失或无效时返回 `ME-ERR-UNAUTHENTICATED`；avatar ref 空白或非内置时返回 `ME-ERR-INVALID-AVATAR` 且不得保存该输入。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-ME-001 | IDENTITY-ME-001 | Code baseline | 当前用户资料读取入口必须只允许满足 `ME-IN-AUTHENTICATED` 的常规用户访问；认证上下文缺失或无效时返回 `ME-ERR-UNAUTHENTICATED`；具体 endpoint path 由 API contract 承接。 |
| IDENTITY-SPEC-ME-002 | IDENTITY-ME-002 | Code baseline | 当前用户资料读取成功时必须返回 `ME-OUT-CURRENT-USER`，其内容必须归属当前认证用户。 |
| IDENTITY-SPEC-ME-003 | IDENTITY-ME-003 | Code baseline | 当前用户资料读取成功时必须返回 `ME-OUT-PROFILE`；current code baseline 下缺失 profile 时可返回空 profile 字段，本 item 不承诺读取时补建 profile。 |
| IDENTITY-SPEC-ME-004 | IDENTITY-ME-004 | Code baseline | 当前用户资料读取必须复用 `TOKEN-FLOW-AUTHENTICATE-BEARER` 的常规用户认证结果；认证上下文不满足时返回 `ME-ERR-UNAUTHENTICATED`，不得返回 `ME-OUT-CURRENT-USER` 或 `ME-OUT-PROFILE`。 |
| IDENTITY-SPEC-ME-005 | IDENTITY-ME-005 | Code baseline | 满足 `ME-IN-AUTHENTICATED` 的用户必须能提交 `ME-IN-PROFILE-UPDATE` 更新自己的 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time；未提供的字段保持既有值。 |
| IDENTITY-SPEC-ME-006 | IDENTITY-ME-006 | Code baseline | 当 `ME-IN-PROFILE-UPDATE` 包含空白或非内置 avatar ref 时，系统必须返回 `ME-ERR-INVALID-AVATAR`，不得保存 avatar ref 或其他依赖该输入的更新结果。 |

### IDENTITY-LINK 初始登录身份绑定与身份键解析

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| LINK-FLOW-CREATE-INITIAL | 账号创建流程需要为新账号建立初始登录身份绑定。 | `IDENTITY-SPEC-ACCOUNT-003` 已创建新账号，且本次已验证身份存在 `LINK-IN-IDENTITY-KEY`。 | 创建 `LINK-OUT-INITIAL-AUTH-IDENTITY`，并使登录身份进入 `LINK-STATE-AUTH-IDENTITY-ACTIVE`。 | 身份键缺失、账号未创建或重复身份冲突时，不得创建初始登录身份绑定；重复身份冲突由 `IDENTITY-SPEC-ACCOUNT-009` 承接。 |
| LINK-FLOW-RESOLVE-IDENTITY | 登录或账号解析流程需要根据登录身份查找账号。 | 输入为 `LINK-IN-IDENTITY-KEY`。 | 命中绑定时进入 `IDENTITY-SPEC-ACCOUNT-002` 的账号解析结果；未命中时由账号创建流程决定后续处理。 | 不得只用 subject 或只用身份来源单独解析；身份状态过滤不属于当前 code baseline。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-LINK-001 | IDENTITY-LINK-001 | Code baseline | 在 `IDENTITY-SPEC-ACCOUNT-003` 创建新账号后，系统必须基于本次已验证身份的 `LINK-IN-IDENTITY-KEY` 创建初始登录身份绑定，并输出 `LINK-OUT-INITIAL-AUTH-IDENTITY`；二次绑定和解绑不属于当前 code baseline。 |
| IDENTITY-SPEC-LINK-002 | IDENTITY-LINK-002 | Code baseline | 初始登录身份绑定创建成功后，该登录身份必须进入 `LINK-STATE-AUTH-IDENTITY-ACTIVE`；该状态不表示身份禁用、解绑或 inactive 查询过滤已实现。 |
| IDENTITY-SPEC-LINK-003 | IDENTITY-LINK-003 | Code baseline | 身份解析 flow 必须用 `LINK-IN-IDENTITY-KEY` 查找绑定账号；命中时进入 `IDENTITY-SPEC-ACCOUNT-002` 的账号解析结果，未命中时由账号创建 flow 决定后续处理；重复身份冲突由 `IDENTITY-SPEC-ACCOUNT-009` 承接。 |

### IDENTITY-LOGOUT 退出登录

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| LOGOUT-FLOW-CURRENT-SESSION | 已认证用户发起 logout。 | logout 请求满足 `LOGOUT-IN-CURRENT-SESSION`。 | 系统仅撤销该当前 session，使其进入 `LOGOUT-STATE-SESSION-REVOKED`，并记录 `LOGOUT-OUT-REVOKED-AT`。 | 请求缺少或无法解析当前 session 时，返回 `LOGOUT-ERR-UNAUTHENTICATED`，不得创建、撤销或修改任何 session；已撤销 session 的 access token 后续在 `TOKEN-FLOW-AUTHENTICATE-BEARER` 中按 `TOKEN-ERR-UNAUTHENTICATED` 处理。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-LOGOUT-001 | IDENTITY-LOGOUT-001 | Code baseline | 当 logout 请求满足 `LOGOUT-IN-CURRENT-SESSION` 时，系统必须撤销该当前 session；不得撤销同用户其他 session。 |
| IDENTITY-SPEC-LOGOUT-002 | IDENTITY-LOGOUT-002 | Code baseline | 当 logout 请求缺少或无法解析 `LOGOUT-IN-CURRENT-SESSION` 时，系统必须返回 `LOGOUT-ERR-UNAUTHENTICATED`，且不得创建、撤销或修改 session。 |
| IDENTITY-SPEC-LOGOUT-003 | IDENTITY-LOGOUT-003 | Code baseline | 当前 session 撤销成功后，该 session 必须进入 `LOGOUT-STATE-SESSION-REVOKED`。 |
| IDENTITY-SPEC-LOGOUT-004 | IDENTITY-LOGOUT-004 | Code baseline | 当前 session 撤销成功后，系统必须记录 `LOGOUT-OUT-REVOKED-AT` 作为该 session 的撤销发生时间。 |
| IDENTITY-SPEC-LOGOUT-005 | IDENTITY-LOGOUT-005 | Code baseline | `LOGOUT-STATE-SESSION-REVOKED` 对应 session 的 access token 后续必须在 `TOKEN-FLOW-AUTHENTICATE-BEARER` 中认证失败，并按 `TOKEN-ERR-UNAUTHENTICATED` 处理。 |

### IDENTITY-DELETE 账号删除与生命周期状态

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| DELETE-FLOW-REQUEST-CURRENT-ACCOUNT | 当前账号用户发起账号删除请求。 | 请求满足 `DELETE-IN-CURRENT-ACCOUNT`，且携带有效 `DELETE-IN-IDEMPOTENCY-KEY`。 | 若同一用户和同一幂等键已有删除任务，返回 `DELETE-JOB-EXISTING`；否则创建删除任务并进入 `DELETE-FLOW-EXECUTE`。 | `DELETE-IN-IDEMPOTENCY-KEY` 缺失、长度小于 8 个字符或大于 128 个字符时，返回 `DELETE-ERR-IDEMPOTENCY-KEY`，不得创建删除任务、撤销 session 或改变账号状态。 |
| DELETE-FLOW-EXECUTE | 删除任务开始执行。 | 账号状态为 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED`。 | 系统撤销该用户所有 active session，完成 `DELETE-CLEANUP-AI`、`DELETE-CLEANUP-IDENTITY`、`DELETE-CLEANUP-LEARNING`、`DELETE-CLEANUP-COMMERCE` 和 `DELETE-CLEANUP-GOAL` 中适用于该用户的数据清理，并使账号进入 `DELETE-STATE-DELETED`。 | 账号状态不属于 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 时，返回 `DELETE-ERR-INVALID-STATE`，不得启动清理执行。 |
| DELETE-FLOW-QUERY-LATEST-JOB | 当前账号用户查询删除任务状态。 | 请求满足 `DELETE-IN-CURRENT-ACCOUNT`。 | 返回当前账号最新删除任务状态。 | 当前账号不存在任何删除任务时，返回 `DELETE-ERR-JOB-NOT-FOUND`。 |
| DELETE-FLOW-ADMIN-RETRY | 运维用户发起删除任务重试。 | 请求通过 `RISK-IN-OPS-BEARER` 运维认证，并携带有效 `DELETE-IN-IDEMPOTENCY-KEY`。 | 按重试决策表处理 failed、completed、in-progress 和 replay 分支。 | `DELETE-IN-IDEMPOTENCY-KEY` 缺失、长度小于 8 个字符或大于 128 个字符时，返回 `DELETE-ERR-IDEMPOTENCY-KEY`，不得创建重试幂等记录、启动清理执行、撤销 session 或改变账号/删除任务状态。 |
| DELETE-FLOW-REPLAY-DELETION-REQUEST | 删除中的账号或已删除账号重放账号删除请求。 | token 对应账号处于 `DELETE-STATE-DELETED` 或 `DELETE-STATE-DELETION-REQUESTED`，且 `DELETE-IN-IDEMPOTENCY-KEY` 与该账号已有删除任务匹配。 | 返回该已有删除任务。 | 该认证例外不得扩展到常规 `TOKEN-FLOW-AUTHENTICATE-BEARER`，也不得用于登录、资料读取或其他受保护用户请求。 |

#### Retry Decision Table
| 条件 | 结果 |
| --- | --- |
| `DELETE-JOB-FAILED` 且同一删除任务和同一重试幂等键尚未存在 | 启动新的重试执行。 |
| 同一删除任务和同一重试幂等键已经存在 | 返回 `DELETE-JOB-RETRY-EXISTING`，不得启动新的重试执行。 |
| `DELETE-JOB-COMPLETED` | 返回该已完成任务，不得启动新的重试执行。 |
| `DELETE-JOB-IN-PROGRESS` | 返回 `DELETE-ERR-IN-PROGRESS`，不得启动新的重试执行。 |
| 未识别任务状态 | 返回 `DELETE-ERR-INVALID-STATE`，不得启动新的重试执行。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-DELETE-001 | IDENTITY-DELETE-001 | Code baseline | 在 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 中，`DELETE-IN-CURRENT-ACCOUNT` 表示通过常规 access token 认证解析出的当前账号；该输入只能发起当前账号的删除请求，不得指定或影响其他账号。 |
| IDENTITY-SPEC-DELETE-002 | IDENTITY-DELETE-002 | Code baseline | 在 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 和 `DELETE-FLOW-ADMIN-RETRY` 中，当 `DELETE-IN-IDEMPOTENCY-KEY` 缺失、长度小于 8 个字符或大于 128 个字符时，系统必须返回 `DELETE-ERR-IDEMPOTENCY-KEY`，不得创建删除任务或重试幂等记录，不得启动清理执行，不得撤销 session，不得改变账号或删除任务状态。 |
| IDENTITY-SPEC-DELETE-003 | IDENTITY-DELETE-003 | Code baseline | 当同一用户和同一 `DELETE-IN-IDEMPOTENCY-KEY` 已有关联删除任务时，系统必须返回 `DELETE-JOB-EXISTING` 指向的该已有任务，且不得创建第二个删除任务或重复启动清理执行。 |
| IDENTITY-SPEC-DELETE-004 | IDENTITY-DELETE-004 | Code baseline | `DELETE-FLOW-EXECUTE` 只允许 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 账号进入删除执行；账号状态不属于这两者时，系统必须返回 `DELETE-ERR-INVALID-STATE`，且不得启动清理执行。 |
| IDENTITY-SPEC-DELETE-005 | IDENTITY-DELETE-005 | Code baseline | `DELETE-FLOW-EXECUTE` 进入访问撤销阶段后，必须撤销该用户所有 active session；该行为不复用 LOGOUT 的 current-session-only 语义。 |
| IDENTITY-SPEC-DELETE-006 | IDENTITY-DELETE-006 | Code baseline | `DELETE-FLOW-EXECUTE` 必须完成 `DELETE-CLEANUP-AI`，覆盖 AI media、TTS cache ownership 和 provider metric 数据清理。 |
| IDENTITY-SPEC-DELETE-007 | IDENTITY-DELETE-007 | Code baseline | `DELETE-FLOW-EXECUTE` 完成 `DELETE-CLEANUP-AI`、`DELETE-CLEANUP-IDENTITY`、`DELETE-CLEANUP-LEARNING`、`DELETE-CLEANUP-COMMERCE` 和 `DELETE-CLEANUP-GOAL` 中适用于该用户的数据清理后，账号状态必须进入 `DELETE-STATE-DELETED`。 |
| IDENTITY-SPEC-DELETE-008 | IDENTITY-DELETE-008 | Code baseline | 删除完成后，保留的最小账号信息必须输出匿名化状态：display name 为 `Deleted User`、avatar ref 为空、onboarding status 为 `deleted`；profile 明细数据删除由 `DELETE-CLEANUP-IDENTITY` 承接。 |
| IDENTITY-SPEC-DELETE-009 | IDENTITY-DELETE-009 | Code baseline | `DELETE-FLOW-QUERY-LATEST-JOB` 必须允许 `DELETE-IN-CURRENT-ACCOUNT` 查询当前账号最新删除任务状态；当该当前账号不存在任何删除任务时，系统必须返回 `DELETE-ERR-JOB-NOT-FOUND`。 |
| IDENTITY-SPEC-DELETE-010 | IDENTITY-DELETE-010 | Code baseline | 通过 `RISK-IN-OPS-BEARER` 运维认证的请求，必须能在 `DELETE-FLOW-ADMIN-RETRY` 中对 `DELETE-JOB-FAILED` 发起重试。 |
| IDENTITY-SPEC-DELETE-011 | IDENTITY-DELETE-011 | Code baseline | `DELETE-FLOW-ADMIN-RETRY` 必须按重试决策表处理：`DELETE-JOB-FAILED` 且无同重试幂等记录时启动新重试执行；同一删除任务和同一重试幂等键已存在时返回 `DELETE-JOB-RETRY-EXISTING` 且不启动新执行；`DELETE-JOB-COMPLETED` 返回该已完成任务；`DELETE-JOB-IN-PROGRESS` 返回 `DELETE-ERR-IN-PROGRESS`；未识别任务状态返回 `DELETE-ERR-INVALID-STATE`。 |
| IDENTITY-SPEC-DELETE-012 | IDENTITY-DELETE-012 | Code baseline | `DELETE-FLOW-REPLAY-DELETION-REQUEST` 仅在 token 对应账号处于 `DELETE-STATE-DELETED` 或 `DELETE-STATE-DELETION-REQUESTED`、且 `DELETE-IN-IDEMPOTENCY-KEY` 与该账号已有删除任务匹配时成立；成立时系统必须返回该已有删除任务，且该认证例外不得扩展到常规 `TOKEN-FLOW-AUTHENTICATE-BEARER`。 |
| IDENTITY-SPEC-DELETE-013 | IDENTITY-DELETE-013 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-IDENTITY` 中删除该用户的登录身份数据。 |
| IDENTITY-SPEC-DELETE-014 | IDENTITY-DELETE-014 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-IDENTITY` 中删除该用户的 profile 明细数据；删除后保留的最小账号信息由 `IDENTITY-SPEC-DELETE-008` 承接。 |
| IDENTITY-SPEC-DELETE-015 | IDENTITY-DELETE-015 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 onboarding assessment、learning route 和 scenario state 数据。 |
| IDENTITY-SPEC-DELETE-016 | IDENTITY-DELETE-016 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 practice session、practice turn 和 session summary 数据。 |
| IDENTITY-SPEC-DELETE-017 | IDENTITY-DELETE-017 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 数据。 |
| IDENTITY-SPEC-DELETE-018 | IDENTITY-DELETE-018 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-COMMERCE` 中删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 数据。 |
| IDENTITY-SPEC-DELETE-019 | IDENTITY-DELETE-019 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 数据。 |
| IDENTITY-SPEC-DELETE-020 | IDENTITY-DELETE-020 | Code baseline | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-GOAL` 中删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 数据。 |

### IDENTITY-RISK 认证错误、ops admin 访问门禁与当前防滥用边界

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| RISK-FLOW-PROTECTED-UNAUTHENTICATED | 受保护用户请求进入认证检查。 | 请求需要常规用户认证，且无法通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 建立常规用户认证上下文。 | 返回 `RISK-OUT-UNAUTHENTICATED-JSON`。 | 不得进入受保护业务处理；公共端点不由本 flow 承诺。 |
| RISK-FLOW-ADMIN-OPS-AUTH | admin 请求进入权限检查。 | 请求目标为 admin 处理。 | `RISK-IN-OPS-BEARER` 通过 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH` 时获得 ops 权限并可进入 admin 处理。 | 未建立认证上下文的 admin 请求返回 `RISK-OUT-UNAUTHENTICATED-JSON`；已建立常规用户认证上下文但无 ops 权限时返回 `RISK-ERR-ADMIN-FORBIDDEN`。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-RISK-001 | IDENTITY-RISK-001 | Code baseline | 在 `RISK-FLOW-PROTECTED-UNAUTHENTICATED` 中，当受保护用户请求无法通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 建立常规用户认证上下文时，系统必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`，不得进入受保护业务处理。 |
| IDENTITY-SPEC-RISK-002 | IDENTITY-RISK-002 | Code baseline | 在 `RISK-FLOW-ADMIN-OPS-AUTH` 中，admin 请求只有满足 `RISK-IN-OPS-BEARER` 并通过 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH` 时才能获得 ops 权限；已建立常规用户认证上下文但不具备 ops 权限的请求访问 admin 入口时必须返回 `RISK-ERR-ADMIN-FORBIDDEN`；未建立认证上下文的 admin 请求必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`。 |
| IDENTITY-SPEC-RISK-003 | IDENTITY-RISK-003 | Code baseline | `RISK-IN-OPS-BEARER` 认证必须使用 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH` 与服务端保存的 ops token 摘要匹配；不得把 ops token 明文作为比较基准。 |

### IDENTITY-AUDIT 审计、隐私与合规

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| AUDIT-FLOW-REDACT-ON-WRITE | 系统创建审计记录。 | 输入包含 `AUDIT-IN-RAW`。 | 系统必须输出 `AUDIT-OUT-REDACTED` 并只持久化清洗后的审计目标引用、请求标识和详情内容。 | 不得持久化未清洗的 target ref、request id 或 details。 |
| AUDIT-FLOW-REDACT-SENSITIVE-CONTENT | 审计清洗处理目标引用、请求标识或详情内容。 | 输入可按 `AUDIT-SENSITIVE-PATTERN` 判定是否敏感。 | 命中 sensitive details key 时，输出 details key 必须为 `redacted_field_<index>` 且 value 为 `redacted`；命中 sensitive details value 时，value 必须为 `redacted`；命中 sensitive target ref 时必须输出 `redacted:target_ref`；命中 sensitive 或空白 request id 时必须输出 `unknown`。 | 未命中且非空内容可作为清洗后输出；不得输出命中的敏感原文。 |
| AUDIT-FLOW-ACCOUNT-DELETION-RESULT | 账号删除执行完成或失败。 | 删除执行已产生完成或失败结果。 | 完成时写入 `AUDIT-EVENT-DELETION-COMPLETED`；失败时写入 `AUDIT-EVENT-DELETION-FAILED`。 | 来自运维重试的完成或失败必须能与普通删除完成或失败区分；事件内容仍必须经过 `AUDIT-FLOW-REDACT-ON-WRITE`。 |
| AUDIT-FLOW-ACCOUNT-DELETION-RETRY-REQUESTED | 账号删除重试请求被接受进入处理。 | 请求已通过 `RISK-FLOW-ADMIN-OPS-AUTH`，且删除重试请求被接受进入处理。 | 写入 `AUDIT-EVENT-DELETION-RETRY`。 | 未通过 ops 认证或未进入重试处理的请求不由本 flow 承诺写入该事件。 |
| AUDIT-FLOW-ADMIN-AUDIT-QUERY | ops admin 查询审计日志列表。 | 请求已通过 `RISK-FLOW-ADMIN-OPS-AUTH`。 | 返回的审计详情必须来自 `AUDIT-OUT-REDACTED`，并写入 `AUDIT-EVENT-QUERY`。 | 未通过 ops 认证的请求由 RISK 处理；不得输出未清洗 details。 |

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-AUDIT-001 | IDENTITY-AUDIT-001 | Code baseline | 在 `AUDIT-FLOW-REDACT-ON-WRITE` 中，当系统创建审计记录并接收 `AUDIT-IN-RAW` 时，必须输出 `AUDIT-OUT-REDACTED`，且持久化审计记录不得保存未清洗的 target ref、request id 或 details。 |
| IDENTITY-SPEC-AUDIT-002 | IDENTITY-AUDIT-002 | Code baseline | 在 `AUDIT-FLOW-REDACT-SENSITIVE-CONTENT` 中，`AUDIT-SENSITIVE-PATTERN` 必须覆盖 key token 集合 `api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`，以及 value pattern 集合 `signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`；命中 sensitive details key 时，输出 details key 必须为 `redacted_field_<index>` 且 value 为 `redacted`；命中 sensitive details value 时，value 必须为 `redacted`；命中 sensitive target ref 时必须输出 `redacted:target_ref`；命中 sensitive 或空白 request id 时必须输出 `unknown`；所有结果必须进入 `AUDIT-OUT-REDACTED`。 |
| IDENTITY-SPEC-AUDIT-003 | IDENTITY-AUDIT-003 | Code baseline | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RESULT` 中，账号删除执行完成时必须写入 `AUDIT-EVENT-DELETION-COMPLETED`；当完成来自运维重试时，该事件必须能区分 retry completed 变体。 |
| IDENTITY-SPEC-AUDIT-004 | IDENTITY-AUDIT-004 | Code baseline | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RESULT` 中，账号删除执行失败时必须写入 `AUDIT-EVENT-DELETION-FAILED`；当失败来自运维重试时，该事件必须能区分 retry failed 变体。 |
| IDENTITY-SPEC-AUDIT-005 | IDENTITY-AUDIT-005 | Code baseline | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RETRY-REQUESTED` 中，通过 `RISK-FLOW-ADMIN-OPS-AUTH` 且被接受进入重试处理的删除重试请求，必须写入 `AUDIT-EVENT-DELETION-RETRY`。 |
| IDENTITY-SPEC-AUDIT-006 | IDENTITY-AUDIT-006 | Code baseline | 在 `AUDIT-FLOW-ADMIN-AUDIT-QUERY` 中，通过 `RISK-FLOW-ADMIN-OPS-AUTH` 的 ops admin 审计日志列表查询必须记录 `AUDIT-EVENT-QUERY`；返回的审计详情必须来自 `AUDIT-OUT-REDACTED`，不得输出未清洗 details。 |

### IDENTITY-RELEASE 未实现生产发布边界

#### 当前无已实现 release gate baseline

##### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-RELEASE-000 | N/A - 当前无可归档已实现 requirement item | No accepted baseline | 在 `RELEASE-BOUNDARY-NO-BASELINE` 下，本规格不得把 `RELEASE-TARGET-PENDING` 写成已实现行为；当前通用 release health warning 不得作为 identity 专属 release gate code evidence；新增 release target spec items 只能表示待实现发布边界，不能表示 release gate 已实现。 |

#### Release / DevOps target boundary（Proposed / 待实现）

##### Target Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-RELEASE-001 | IDENTITY-RELEASE-001 | Release target pending | 生产发布门禁必须在发现后端仍允许未消费 OTP challenge 完成手机号登录、账号创建或 session 签发时返回 `RELEASE-ERR-IDENTITY-BACKEND-UNVERIFIED`，并阻断商业发布通过。 |
| IDENTITY-SPEC-RELEASE-002 | IDENTITY-RELEASE-002 | Release target pending | 生产发布门禁必须在发现后端仍把 raw provider token、Apple authorization code、Apple identity token 或 WeChat code 的 hash 作为 Apple / WeChat stable subject 时返回 `RELEASE-ERR-IDENTITY-BACKEND-UNVERIFIED`，并阻断商业发布通过。 |
| IDENTITY-SPEC-RELEASE-003 | IDENTITY-RELEASE-003 | Release target pending | 生产发布门禁必须要求真实 SMS、Apple 和 WeChat provider 配置以及 `RELEASE-OUT-IDENTITY-EVIDENCE`；配置或证据缺失、使用 placeholder/native test 配置时必须返回 `RELEASE-ERR-IDENTITY-PROVIDER-CONFIG`，且不得声明商业发布通过。 |

## 模块影响与 owner agent
| 能力域 | 影响范围 | Owner agent / skill |
| --- | --- | --- |
| Product scope | Product Base 模块边界、稳定 feature 映射、merge-back 决策 | Product Manager Agent |
| Requirements | `identity-account-lifecycle/requirements.md` 的需求 item 维护 | Requirement Development Agent |
| Feature spec | 本文件的模块规格、状态、输入输出、失败路径、非目标和下游契约影响 | Feature Spec Generate Skill |
| Domain model | UserAccount、AuthIdentity、AuthSession、OtpChallenge、AccountDeletionJob、AuditLog 等生命周期对象 | Domain Schema Agent / `domain-model-generate` |
| API contract | auth、user/me、logout、refresh、account deletion、admin audit、目标态 OTP endpoints、Apple / WeChat provider validation request semantics | Backend Agent / `api-contract-generate` |
| Architecture / Security | opaque token、provider boundary、OTP security、audit redaction、admin bearer，以及未实现的 identity release gate target boundary | System Architect Agent |
| QA | AC/TC、覆盖矩阵、当前代码基线、目标态 OTP、目标态 provider validation 和 release target boundary 的测试分层 | QA Agent / `acceptance-criteria-generate` / `test-case-generate` |
| DevOps / Release | 生产 HTTPS、OTP provider 禁用测试替身，以及未实现的 identity 专属 release gate target boundary | DevOps Agent |
| Traceability | Requirement -> Spec -> AC -> TC -> Evidence 链路 | `document-traceability-check` |

## 必需下游契约
| Contract area | Required output |
| --- | --- |
| Domain | 定义 `UserAccount`、`AuthIdentity`、`AuthSession`、`OtpChallenge`、OTP attempt/lock、AccountDeletionJob、AuditLog 的实体、状态、生命周期和保留边界。 |
| API | 定义登录、refresh、logout、`/user/me`、profile update、account deletion、admin deletion retry、admin audit query、目标态 OTP send/verify 的 request、response、typed error 和兼容性。 |
| Architecture / Security | 定义 opaque token 策略、hash 存储、provider token baseline boundary、Apple / WeChat verifier、stable subject derivation、OTP CSPRNG/HMAC、rate limit/risk/CAPTCHA、audit redaction、admin bearer、安全错误响应和未实现 release gate target boundary 关系。 |
| QA | 以本规格为直接上游生成 acceptance criteria 和 test cases；每个 spec item 至少映射到一个 AC 或明确例外。 |
| DevOps | 目标态 OTP 和 identity provider 进入生产前，需要生产配置、HTTPS enforcement、测试 provider 禁用、secret 管理、真实 SMS/Apple/WeChat provider evidence、目标态 release health 阻断和回滚验证；这些是下游 DevOps target boundary，不是当前 identity code baseline。 |

## 非目标
- 不声明当前身份认证模块已达到商业化发布就绪。
- 不声明真实短信 OTP、真实 Apple/WeChat provider 校验、登录限流、设备风控、CAPTCHA 或 identity 专属 release gate 已实现。
- 不定义完整 API schema、数据库字段、OpenAPI 片段、prompt schema、UI 布局或测试实现。
- 不把会员订阅、支付、权益 gating、学习业务状态或 AI 练习流程写成 identity 规格。
- 不把平台级 admin audit 查询扩展为身份生命周期业务流程。
- 不修改后端、Flutter、OpenAPI、数据库迁移或测试代码。
- 不更新 Product Base 根目录总库文件。

## 验收覆盖期望
- 每条 `Code baseline` spec item 后续必须至少映射到一个可观察 AC 和一个 TC，或记录明确例外。
- 每条 `Target pending` 或 `Release target pending` spec item 后续必须至少映射到一个目标态 AC 和一个目标态 TC，但在代码实现前不得声明 code evidence traced。
- `IDENTITY-SPEC-RELEASE-000` 只作为当前无已实现 release gate 的边界 spec，不要求生成已实现 AC；`IDENTITY-SPEC-RELEASE-001..003` 是待实现发布门禁目标，必须在实现前维持 pending 状态。
- AC 必须验证用户或系统可观察结果，不得以类名、函数名、数据库字段或具体测试实现作为通过条件。
- traceability 更新时必须保持 `docs/product/base/identity-account-lifecycle/traceability.md` 中的 `Spec Flow` / `Spec Item` 与本文件的具体 spec ID 一致，并补齐对应 `AC`、`TC` 和测试证据。

## Rollout / merge-back 规则
- 本文件为 Draft 模块规格；生成本文件不等于 Product Base 总规格已接受更新。
- 后续必须依次补齐 `acceptance.md`、测试用例、traceability 中与具体 spec ID 对应的 AC/TC 映射、测试证据、实现报告或质量报告。
- Product Base 根目录 `docs/product/base/spec.md` 只有在实现、验收、追溯、测试和报告证据完整或例外已记录后，才能由 Product Manager 批准合并。
- 目标态 OTP、Apple / WeChat provider validation、生产凭证门禁和 identity release gate 进入实现前必须先补齐 Domain、API、Architecture/Security、QA 和 DevOps 契约；实现中发现缺失契约字段时必须停止并先更新对应契约。
