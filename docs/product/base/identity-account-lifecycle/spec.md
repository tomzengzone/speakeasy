# Identity & Account Lifecycle Spec（身份认证与账号生命周期规格）

## 状态
Draft（草案） - 本文件把 `Identity & Account Lifecycle` Product Base 模块需求下沉为可追溯、可验收、可生成 AC/TC 的模块规格。本文同时区分当前代码基线行为和真实短信 OTP 目标态行为；目标态行为在实现、验收、测试和追溯证据补齐前不得声明为已实现或 Accepted。

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

本规格不定义会员订阅、支付、学习内容、AI 练习、课程推荐、业务学习状态、生产短信 provider 采购方案或 identity 专属发布门禁实现。跨域数据清理只作为账号删除依赖被引用，不把被清理领域的业务规则纳入 identity 模块。

## Requirement 到 Spec 的映射
| Requirement range | Spec item range | Status |
| --- | --- | --- |
| IDENTITY-ACCOUNT-001..011 | IDENTITY-SPEC-ACCOUNT-001..011 | Code baseline |
| IDENTITY-OTP-001..003 | IDENTITY-SPEC-OTP-001..003 | Code baseline |
| IDENTITY-OTP-004..030, IDENTITY-OTP-032..037 | IDENTITY-SPEC-OTP-004..030, IDENTITY-SPEC-OTP-032..037 | Target pending |
| OTP-TESTABILITY-001 | N/A - QA/testability input | Target QA input |
| IDENTITY-PROVIDER-001..004 | IDENTITY-SPEC-PROVIDER-001..004 | Code baseline |
| IDENTITY-LOGIN-001..007 | IDENTITY-SPEC-LOGIN-001..007 | Code baseline |
| IDENTITY-TOKEN-001..012 | IDENTITY-SPEC-TOKEN-001..012 | Code baseline |
| IDENTITY-ME-001..008 | IDENTITY-SPEC-ME-001..008 | Code baseline |
| IDENTITY-LINK-001..003 | IDENTITY-SPEC-LINK-001..003 | Code baseline |
| IDENTITY-LOGOUT-001..005 | IDENTITY-SPEC-LOGOUT-001..005 | Code baseline |
| IDENTITY-DELETE-001..020 | IDENTITY-SPEC-DELETE-001..020 | Code baseline |
| IDENTITY-RISK-001..003 | IDENTITY-SPEC-RISK-001..003 | Code baseline |
| IDENTITY-AUDIT-001..006 | IDENTITY-SPEC-AUDIT-001..006 | Code baseline |
| IDENTITY-RELEASE | IDENTITY-SPEC-RELEASE-000 | No accepted baseline |

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
| PROVIDER-SUBJECT-HASH | 输出 | 当前代码基线由 provider token hash 得到的第三方身份 subject；不表示 Apple `sub` 或 WeChat `openid` / `unionid` 已验证或使用。 |
| PROVIDER-ERR-VALIDATION | 失败 | provider token 缺失或空白时的输入存在性失败。 |
| LINK-STATE-INITIAL-IDENTITY | 状态 | 新账号创建时绑定的初始登录身份。 |
| LINK-STATE-AUTH-IDENTITY-ACTIVE | 状态 | 新建登录身份默认 active。 |
| LINK-IN-IDENTITY-KEY | 输入 | 身份来源和身份 subject。 |
| ME-IN-AUTHENTICATED | 输入 | 已认证用户上下文。 |
| ME-OUT-CURRENT-USER | 输出 | 当前用户 ID、display name、avatar ref、locale、account status、onboarding status。 |
| ME-OUT-PROFILE | 输出 | 当前 profile 的 target level 和 daily minutes。 |
| ME-IN-PROFILE-UPDATE | 输入 | display name、avatar ref、target level、daily minutes、reminder enabled、reminder time。 |
| ME-ERR-UNAUTHENTICATED | 安全错误 | 未认证或 session/token 不满足 active 要求。 |
| ME-ERR-INVALID-AVATAR | 失败 | 非内置头像引用。 |
| HOME-OUT-NEXT-ACTION | 输出 | 首页摘要根据 onboarding status 输出的下一步动作。 |

#### 登录、会话与 Token
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| LOGIN-IN-TERMS-ACCEPTED | 输入 | 当前登录请求中用户声明已接受服务条款和隐私政策；不表示 Terms/Privacy consent 持久化已实现。 |
| LOGIN-IN-SCHEMA-VERSION | 输入 | 登录或刷新请求携带的兼容性版本信号；具体字段形态由 API contract 承接。 |
| LOGIN-STATE-PUBLIC-ENDPOINT | 状态 | 手机号、Apple、WeChat 登录入口不要求既有认证 session；该状态不绕过 schema version、terms、凭证或账号状态校验。 |
| LOGIN-STATE-ACCOUNT-ACTIVE | 状态 | 可登录的 active 账号状态。 |
| LOGIN-STATE-SESSION-ACTIVE | 输出 | 为本次解析或创建的用户创建的 active 认证 session。 |
| LOGIN-OUT-TOKEN-PAIR | 输出 | 当前用户、access token、refresh token 和 access token 过期时间；token 生命周期由 `IDENTITY-TOKEN` spec 承接。 |
| LOGIN-ERR-TERMS-REQUIRED | 失败 | 未接受条款时拒绝登录；失败后不得进入身份解析、账号创建或 session 签发。 |
| LOGIN-ERR-INACTIVE-ACCOUNT | 安全错误 | 非 active 账号不得登录；失败后不得创建 session 或返回 token pair。 |
| LOGIN-ERR-UNSUPPORTED-SCHEMA | 失败 | 不支持的 schema version；失败必须发生在认证状态变化前，且不得创建 session、签发 token 或轮换 token。 |
| TOKEN-STATE-OPAQUE | 状态 | 服务端 opaque bearer token，非 JWT。 |
| TOKEN-STATE-SESSION-ACTIVE | 状态 | active 且未过期的认证 session。 |
| TOKEN-IN-BEARER | 输入 | `Authorization: Bearer` header 中的 access token。 |
| TOKEN-IN-REFRESH | 输入 | refresh token。 |
| TOKEN-OUT-ROTATED | 输出 | 刷新后同一 session 的新 access token hash 和 refresh token hash。 |
| TOKEN-ERR-UNAUTHENTICATED | 安全错误 | token 缺失、无效、过期、已撤销或已轮换。 |
| TOKEN-SECURE-RANDOM | 安全要求 | 使用 `SecureRandom` 生成 token 原始字节。 |
| LOGOUT-IN-AUTHENTICATED | 输入 | 已认证用户当前 session。 |
| LOGOUT-STATE-SESSION-REVOKED | 状态 | session 已撤销。 |
| LOGOUT-OUT-REVOKED-AT | 输出 | session revoked time。 |
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
| DELETE-IN-AUTHENTICATED | 输入 | 已认证用户当前账号。 |
| DELETE-IN-IDEMPOTENCY-KEY | 输入 | 长度 8 到 128 个字符的幂等键。 |
| DELETE-STATE-ACTIVE | 状态 | 允许发起删除执行的 active 账号状态。 |
| DELETE-STATE-DELETION-REQUESTED | 状态 | 允许发起或重放删除执行的 deletion_requested 账号状态。 |
| DELETE-STATE-DELETED | 状态 | 删除完成后的账号状态。 |
| DELETE-JOB-EXISTING | 输出 | 同一用户和幂等键对应的已有删除 job。 |
| DELETE-JOB-FAILED | 状态 | 可由运维重试的 failed 删除 job。 |
| DELETE-JOB-COMPLETED | 状态 | 已完成删除 job。 |
| DELETE-ERR-IDEMPOTENCY-KEY | 失败 | 幂等键长度不合法。 |
| DELETE-ERR-INVALID-STATE | 安全错误 | 账号或 job 状态不允许删除或重试。 |
| DELETE-CLEANUP-AI | 输出 | AI media、TTS cache ownership 和 provider metric 数据清理。 |
| DELETE-CLEANUP-IDENTITY | 输出 | auth identity 和 user profile 清理。 |
| DELETE-CLEANUP-LEARNING | 输出 | onboarding、learning route、scenario、practice、training、learning memory 数据清理。 |
| DELETE-CLEANUP-COMMERCE | 输出 | purchase、subscription、entitlement、usage 和 payment provider event 数据清理。 |
| DELETE-CLEANUP-GOAL | 输出 | goal/autopilot 相关数据清理。 |

#### 审计、风控与 release 边界
| Ref ID | 类型 | 定义 |
| --- | --- | --- |
| RISK-IN-BEARER | 输入 | 受保护接口携带的 bearer token。 |
| RISK-IN-OPS-BEARER | 输入 | admin 接口携带的 ops bearer token。 |
| RISK-OUT-UNAUTHENTICATED-JSON | 输出 | JSON 格式未认证错误响应。 |
| RISK-ERR-ADMIN-FORBIDDEN | 安全错误 | 非 ops bearer token 访问 admin 接口。 |
| RISK-SEC-HASH-COMPARE | 安全要求 | ops bearer token 以 hash 形式比较。 |
| AUDIT-IN-RAW | 输入 | 写入 audit log 前的 target ref、request id 和 details。 |
| AUDIT-OUT-REDACTED | 输出 | 清洗后的 audit log 字段。 |
| AUDIT-SENSITIVE-PATTERN | 安全要求 | token、secret、signature、receipt、URL 等敏感 key 或 value。 |
| AUDIT-EVENT-DELETION-COMPLETED | 输出 | 账号删除完成 audit event。 |
| AUDIT-EVENT-DELETION-FAILED | 输出 | 账号删除失败 audit event。 |
| AUDIT-EVENT-DELETION-RETRY | 输出 | 账号删除重试请求 audit event。 |
| AUDIT-EVENT-QUERY | 输出 | 共享 audit log 查询行为 audit event。 |
| RELEASE-BOUNDARY-NO-BASELINE | 范围边界 | 当前没有 identity 专属已实现 release gate 可归档为 Product Base 代码基线。 |
| RELEASE-TARGET-PENDING | 目标边界 | 生产禁用 fake OTP、禁用未校验 provider token、identity provider 配置阻断和 identity 专属 release gate 均仍为未实现目标。 |

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

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-PROVIDER-001 | IDENTITY-PROVIDER-001 | Code baseline | Current code baseline 下，Apple 登录入口必须把 `PROVIDER-IN-APPLE` 归属为 `apple` 身份来源；该 item 不表示 Apple identity token validation 或 Apple stable subject extraction 已实现。 |
| IDENTITY-SPEC-PROVIDER-002 | IDENTITY-PROVIDER-002 | Code baseline | Current code baseline 下，WeChat 登录入口必须把 `PROVIDER-IN-WECHAT` 归属为 `wechat` 身份来源；该 item 不表示 WeChat code/session/openid/unionid validation 或 stable subject extraction 已实现。 |
| IDENTITY-SPEC-PROVIDER-003 | IDENTITY-PROVIDER-003 | Code baseline | Current code baseline 下，第三方登录请求必须包含非空 `PROVIDER-IN-TOKEN`；缺失或空白时返回 `PROVIDER-ERR-VALIDATION`；该 item 不表示 provider token 真实性、过期、签名或服务端校验已实现。 |
| IDENTITY-SPEC-PROVIDER-004 | IDENTITY-PROVIDER-004 | Code baseline | Current code baseline 下，系统必须把 `PROVIDER-IN-TOKEN` 计算为 `PROVIDER-SUBJECT-HASH` 并作为第三方身份 subject；该 item 不表示 Apple `sub` 或 WeChat `openid` / `unionid` 已验证或使用。 |

### IDENTITY-LOGIN 登录与 session 签发

#### Flow Segments
| Flow ID | Trigger | Precondition | State transition / output | Failure boundary |
| --- | --- | --- | --- | --- |
| LOGIN-FLOW-AUTHENTICATE | 未认证客户端调用手机号、Apple 或 WeChat 登录入口。 | 入口为 `LOGIN-STATE-PUBLIC-ENDPOINT`。 | 系统按 schema version、terms、凭证/身份输入、账号状态顺序处理；通过后创建 `LOGIN-STATE-SESSION-ACTIVE` 并返回 `LOGIN-OUT-TOKEN-PAIR`。 | schema version、terms、凭证/身份输入或账号状态失败时，不得创建 session、发放 token 或返回 token pair。 |
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

### IDENTITY-TOKEN Access / refresh token 生命周期

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-TOKEN-001 | IDENTITY-TOKEN-001 | Code baseline | 系统必须签发 `TOKEN-STATE-OPAQUE` access token 和 refresh token。 |
| IDENTITY-SPEC-TOKEN-002 | IDENTITY-TOKEN-002 | Code baseline | 系统必须使用 `TOKEN-SECURE-RANDOM` 生成 token 原始字节。 |
| IDENTITY-SPEC-TOKEN-003 | IDENTITY-TOKEN-003 | Code baseline | 系统必须只持久化 access token 和 refresh token 的 hash，不得持久化 token 明文。 |
| IDENTITY-SPEC-TOKEN-004 | IDENTITY-TOKEN-004 | Code baseline | access token 默认有效期必须为 30 分钟。 |
| IDENTITY-SPEC-TOKEN-005 | IDENTITY-TOKEN-005 | Code baseline | refresh token 默认有效期必须为 30 天。 |
| IDENTITY-SPEC-TOKEN-006 | IDENTITY-TOKEN-006 | Code baseline | 受保护请求必须从 `TOKEN-IN-BEARER` 提取 access token。 |
| IDENTITY-SPEC-TOKEN-007 | IDENTITY-TOKEN-007 | Code baseline | access token 只有匹配 `TOKEN-STATE-SESSION-ACTIVE` 时才能认证通过，否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-TOKEN-008 | IDENTITY-TOKEN-008 | Code baseline | access token 认证必须要求关联用户为 active 状态，否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-TOKEN-009 | IDENTITY-TOKEN-009 | Code baseline | `TOKEN-IN-REFRESH` 只有匹配 active 且 refresh 未过期 session 时才能刷新。 |
| IDENTITY-SPEC-TOKEN-010 | IDENTITY-TOKEN-010 | Code baseline | refresh 成功必须产生 `TOKEN-OUT-ROTATED`，并替换同一 session 的旧 token hash。 |
| IDENTITY-SPEC-TOKEN-011 | IDENTITY-TOKEN-011 | Code baseline | refresh token 为空、无效、过期或已被轮换后，系统必须返回 `TOKEN-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-TOKEN-012 | IDENTITY-TOKEN-012 | Code baseline | 后端安全配置必须使用 stateless session 策略，不依赖服务端 HTTP session。 |

### IDENTITY-ME 当前用户与 profile gate state

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-ME-001 | IDENTITY-ME-001 | Code baseline | `/user/me` 必须只允许 `ME-IN-AUTHENTICATED` 访问，否则返回 `ME-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-ME-002 | IDENTITY-ME-002 | Code baseline | `/user/me` 必须返回 `ME-OUT-CURRENT-USER`。 |
| IDENTITY-SPEC-ME-003 | IDENTITY-ME-003 | Code baseline | `/user/me` 必须返回 `ME-OUT-PROFILE`。 |
| IDENTITY-SPEC-ME-004 | IDENTITY-ME-004 | Code baseline | 当前用户访问必须要求 access token 对应 active 且未过期 session，并且关联用户为 active 状态，否则返回 `ME-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-ME-005 | IDENTITY-ME-005 | Code baseline | 用户必须能提交 `ME-IN-PROFILE-UPDATE` 并保存允许更新的 profile 字段。 |
| IDENTITY-SPEC-ME-006 | IDENTITY-ME-006 | Code baseline | 当 avatar ref 不是内置头像引用时，系统必须返回 `ME-ERR-INVALID-AVATAR` 并拒绝更新。 |
| IDENTITY-SPEC-ME-007 | IDENTITY-ME-007 | Code baseline | 用户完成首评后，系统必须把 onboarding status 更新为 `ONBOARDING-STATE-COMPLETE`。 |
| IDENTITY-SPEC-ME-008 | IDENTITY-ME-008 | Code baseline | 首页摘要必须根据 onboarding status 输出 `HOME-OUT-NEXT-ACTION`。 |

### IDENTITY-LINK 身份绑定与解绑

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-LINK-001 | IDENTITY-LINK-001 | Code baseline | 新账号创建时必须绑定 `LINK-STATE-INITIAL-IDENTITY`。 |
| IDENTITY-SPEC-LINK-002 | IDENTITY-LINK-002 | Code baseline | 新建登录身份必须初始化为 `LINK-STATE-AUTH-IDENTITY-ACTIVE`。 |
| IDENTITY-SPEC-LINK-003 | IDENTITY-LINK-003 | Code baseline | 身份解析必须使用 `LINK-IN-IDENTITY-KEY`。 |

### IDENTITY-LOGOUT 退出登录

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-LOGOUT-001 | IDENTITY-LOGOUT-001 | Code baseline | 已认证用户调用 logout 时，系统必须撤销 `LOGOUT-IN-AUTHENTICATED` 对应的当前 session。 |
| IDENTITY-SPEC-LOGOUT-002 | IDENTITY-LOGOUT-002 | Code baseline | logout 找不到当前 session 时，系统必须返回 `LOGOUT-ERR-UNAUTHENTICATED`。 |
| IDENTITY-SPEC-LOGOUT-003 | IDENTITY-LOGOUT-003 | Code baseline | session 被撤销时，系统必须进入 `LOGOUT-STATE-SESSION-REVOKED`。 |
| IDENTITY-SPEC-LOGOUT-004 | IDENTITY-LOGOUT-004 | Code baseline | session 被撤销时，系统必须记录 `LOGOUT-OUT-REVOKED-AT`。 |
| IDENTITY-SPEC-LOGOUT-005 | IDENTITY-LOGOUT-005 | Code baseline | `LOGOUT-STATE-SESSION-REVOKED` 不得继续通过 access token 认证。 |

### IDENTITY-DELETE 账号删除与生命周期状态

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-DELETE-001 | IDENTITY-DELETE-001 | Code baseline | `DELETE-IN-AUTHENTICATED` 必须能发起当前账号删除请求。 |
| IDENTITY-SPEC-DELETE-002 | IDENTITY-DELETE-002 | Code baseline | 账号删除请求必须校验 `DELETE-IN-IDEMPOTENCY-KEY` 长度，非法时返回 `DELETE-ERR-IDEMPOTENCY-KEY`。 |
| IDENTITY-SPEC-DELETE-003 | IDENTITY-DELETE-003 | Code baseline | 同一用户使用同一 `DELETE-IN-IDEMPOTENCY-KEY` 重复删除时，系统必须返回 `DELETE-JOB-EXISTING`。 |
| IDENTITY-SPEC-DELETE-004 | IDENTITY-DELETE-004 | Code baseline | 系统只允许 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 账号发起删除执行，否则返回 `DELETE-ERR-INVALID-STATE`。 |
| IDENTITY-SPEC-DELETE-005 | IDENTITY-DELETE-005 | Code baseline | 删除执行必须撤销该用户所有 active session。 |
| IDENTITY-SPEC-DELETE-006 | IDENTITY-DELETE-006 | Code baseline | 删除执行必须完成 `DELETE-CLEANUP-AI`。 |
| IDENTITY-SPEC-DELETE-007 | IDENTITY-DELETE-007 | Code baseline | 删除完成后，账号状态必须进入 `DELETE-STATE-DELETED`。 |
| IDENTITY-SPEC-DELETE-008 | IDENTITY-DELETE-008 | Code baseline | 删除完成后，系统必须把 display name 改为 `Deleted User`，清空 avatar ref，并把 onboarding status 标记为 `deleted`。 |
| IDENTITY-SPEC-DELETE-009 | IDENTITY-DELETE-009 | Code baseline | 已认证用户必须能查询当前账号最新删除 job 状态。 |
| IDENTITY-SPEC-DELETE-010 | IDENTITY-DELETE-010 | Code baseline | 运维用户必须能重试 `DELETE-JOB-FAILED`。 |
| IDENTITY-SPEC-DELETE-011 | IDENTITY-DELETE-011 | Code baseline | 删除重试只允许 `DELETE-JOB-FAILED` 进入重试执行；`DELETE-JOB-COMPLETED` 必须返回已有结果，其他状态返回 `DELETE-ERR-INVALID-STATE`。 |
| IDENTITY-SPEC-DELETE-012 | IDENTITY-DELETE-012 | Code baseline | 删除重试认证必须允许携带同一 `DELETE-IN-IDEMPOTENCY-KEY` 的 deleted 或 deletion_requested 用户重放同一个 `DELETE /user/me` 请求。 |
| IDENTITY-SPEC-DELETE-013 | IDENTITY-DELETE-013 | Code baseline | 删除执行必须删除该用户的 auth identity 记录。引用：`DELETE-CLEANUP-IDENTITY`。 |
| IDENTITY-SPEC-DELETE-014 | IDENTITY-DELETE-014 | Code baseline | 删除执行必须删除该用户的 user profile 记录。引用：`DELETE-CLEANUP-IDENTITY`。 |
| IDENTITY-SPEC-DELETE-015 | IDENTITY-DELETE-015 | Code baseline | 删除执行必须删除该用户的 onboarding assessment、learning route 和 user scenario state 记录。引用：`DELETE-CLEANUP-LEARNING`。 |
| IDENTITY-SPEC-DELETE-016 | IDENTITY-DELETE-016 | Code baseline | 删除执行必须删除该用户的 practice session、practice turn 和 session summary 记录。引用：`DELETE-CLEANUP-LEARNING`。 |
| IDENTITY-SPEC-DELETE-017 | IDENTITY-DELETE-017 | Code baseline | 删除执行必须删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 记录。引用：`DELETE-CLEANUP-LEARNING`。 |
| IDENTITY-SPEC-DELETE-018 | IDENTITY-DELETE-018 | Code baseline | 删除执行必须删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 记录。引用：`DELETE-CLEANUP-COMMERCE`。 |
| IDENTITY-SPEC-DELETE-019 | IDENTITY-DELETE-019 | Code baseline | 删除执行必须删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 记录。引用：`DELETE-CLEANUP-LEARNING`。 |
| IDENTITY-SPEC-DELETE-020 | IDENTITY-DELETE-020 | Code baseline | 删除执行必须删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 记录。引用：`DELETE-CLEANUP-GOAL`。 |

### IDENTITY-RISK 风控、限流与防滥用

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-RISK-001 | IDENTITY-RISK-001 | Code baseline | 无效 `RISK-IN-BEARER` 访问受保护接口时，系统必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`。 |
| IDENTITY-SPEC-RISK-002 | IDENTITY-RISK-002 | Code baseline | admin 接口必须只允许 `RISK-IN-OPS-BEARER` 认证通过，否则返回 `RISK-ERR-ADMIN-FORBIDDEN`。 |
| IDENTITY-SPEC-RISK-003 | IDENTITY-RISK-003 | Code baseline | ops bearer token 必须使用 `RISK-SEC-HASH-COMPARE`，不得以明文直接比较。 |

### IDENTITY-AUDIT 审计、隐私与合规

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-AUDIT-001 | IDENTITY-AUDIT-001 | Code baseline | 写入 audit log 时，系统必须把 `AUDIT-IN-RAW` 清洗为 `AUDIT-OUT-REDACTED`。 |
| IDENTITY-SPEC-AUDIT-002 | IDENTITY-AUDIT-002 | Code baseline | audit redaction 必须识别 `AUDIT-SENSITIVE-PATTERN` 并避免敏感信息进入 audit 输出。 |
| IDENTITY-SPEC-AUDIT-003 | IDENTITY-AUDIT-003 | Code baseline | 账号删除完成时，系统必须写入 `AUDIT-EVENT-DELETION-COMPLETED`。 |
| IDENTITY-SPEC-AUDIT-004 | IDENTITY-AUDIT-004 | Code baseline | 账号删除失败时，系统必须写入 `AUDIT-EVENT-DELETION-FAILED`。 |
| IDENTITY-SPEC-AUDIT-005 | IDENTITY-AUDIT-005 | Code baseline | 账号删除重试请求必须写入 `AUDIT-EVENT-DELETION-RETRY`。 |
| IDENTITY-SPEC-AUDIT-006 | IDENTITY-AUDIT-006 | Code baseline | 共享 audit log 查询必须记录 `AUDIT-EVENT-QUERY`。 |

### IDENTITY-RELEASE 测试替身与生产环境 release gate

#### Spec Items
| Spec ID | Upstream Requirement | Status | Specification |
| --- | --- | --- | --- |
| IDENTITY-SPEC-RELEASE-000 | N/A - 当前无可归档 requirement item | No accepted baseline | 在 `RELEASE-BOUNDARY-NO-BASELINE` 下，本规格不得把 `RELEASE-TARGET-PENDING` 写成已实现行为；后续只有形成独立 requirement、spec、AC、TC、实现和 release evidence 后，才能新增 identity release gate spec item。 |

## 模块影响与 owner agent
| 能力域 | 影响范围 | Owner agent / skill |
| --- | --- | --- |
| Product scope | Product Base 模块边界、稳定 feature 映射、merge-back 决策 | Product Manager Agent |
| Requirements | `identity-account-lifecycle/requirements.md` 的需求 item 维护 | Requirement Development Agent |
| Feature spec | 本文件的模块规格、状态、输入输出、失败路径、非目标和下游契约影响 | Feature Spec Generate Skill |
| Domain model | UserAccount、AuthIdentity、AuthSession、OtpChallenge、AccountDeletionJob、AuditLog 等生命周期对象 | Domain Schema Agent / `domain-model-generate` |
| API contract | auth、user/me、logout、refresh、account deletion、admin audit、目标态 OTP endpoints | Backend Agent / `api-contract-generate` |
| Architecture / Security | opaque token、provider boundary、OTP security、audit redaction、admin bearer、release gate | System Architect Agent |
| QA | AC/TC、覆盖矩阵、当前代码基线和目标态 OTP 的测试分层 | QA Agent / `acceptance-criteria-generate` / `test-case-generate` |
| DevOps / Release | 生产 HTTPS、OTP provider 禁用测试替身、identity 专属 release gate | DevOps Agent |
| Traceability | Requirement -> Spec -> AC -> TC -> Evidence 链路 | `document-traceability-check` |

## 必需下游契约
| Contract area | Required output |
| --- | --- |
| Domain | 定义 `UserAccount`、`AuthIdentity`、`AuthSession`、`OtpChallenge`、OTP attempt/lock、AccountDeletionJob、AuditLog 的实体、状态、生命周期和保留边界。 |
| API | 定义登录、refresh、logout、`/user/me`、profile update、account deletion、admin deletion retry、admin audit query、目标态 OTP send/verify 的 request、response、typed error 和兼容性。 |
| Architecture / Security | 定义 opaque token 策略、hash 存储、provider token boundary、OTP CSPRNG/HMAC、rate limit/risk/CAPTCHA、audit redaction、admin bearer、安全错误响应和 release gate 关系。 |
| QA | 以本规格为直接上游生成 acceptance criteria 和 test cases；每个 spec item 至少映射到一个 AC 或明确例外。 |
| DevOps | 目标态 OTP 和 identity provider 进入生产前，需要生产配置、HTTPS enforcement、测试 provider 禁用、secret 管理、release health 阻断和回滚验证。 |

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
- 每条 `Target pending` spec item 后续必须至少映射到一个目标态 AC 和一个目标态 TC，但在代码实现前不得声明 code evidence traced。
- `IDENTITY-SPEC-RELEASE-000` 只作为边界 spec，不要求生成已实现 AC；后续新增 release gate requirement 后必须替换为具体 spec item。
- AC 必须验证用户或系统可观察结果，不得以类名、函数名、数据库字段或具体测试实现作为通过条件。
- traceability 更新时必须把 `docs/product/base/identity-account-lifecycle/traceability.md` 中的 `Spec Flow` / `Spec Item` 从 `TBD - 后续补齐` 替换为本文件的具体 spec ID。

## Rollout / merge-back 规则
- 本文件为 Draft 模块规格；生成本文件不等于 Product Base 总规格已接受更新。
- 后续必须依次补齐 `acceptance.md`、测试用例、traceability 的 Spec/AC/TC 映射、测试证据、实现报告或质量报告。
- Product Base 根目录 `docs/product/base/spec.md` 只有在实现、验收、追溯、测试和报告证据完整或例外已记录后，才能由 Product Manager 批准合并。
- 目标态 OTP 进入实现前必须先补齐 Domain、API、Architecture/Security、QA 和 DevOps 契约；实现中发现缺失契约字段时必须停止并先更新对应契约。
