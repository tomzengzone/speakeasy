# Identity & Account Lifecycle Requirements（身份认证与账号生命周期需求）

## 状态
Draft（草案） - 当前文件是 Product Base 下 `Identity & Account Lifecycle` 稳定模块的需求草案。本文同时包含两类需求：当前后端代码已经实现且可用代码证据追溯的代码基线需求，以及真实短信 OTP、真实 Apple / WeChat provider validation、生产凭证门禁和 identity release gate 的目标态需求。目标态需求必须标记为 Proposed / 待实现，不得被计入已实现代码覆盖。

## Owner（负责人）
Requirement Development Agent（需求开发 Agent）

## Product Manager Decision（产品经理决策）
- Product object mode（产品对象模式）: `product-base-consolidation`
- Source mode（来源模式）: `current-code-baseline-consolidation` + `target-requirement-refinement`
- 模块：`Identity & Account Lifecycle / 身份认证与账号生命周期`
- 范围：把当前后端已实现的身份认证、账号创建或解析、会话、当前用户、退出登录、账号删除、删除审计和基础安全门禁行为反向固化为 Product Base 模块需求，并新增真实短信 OTP、真实 Apple / WeChat provider validation、生产凭证门禁和 identity release gate 目标态需求，作为后续 spec、AC、TC 和实现的上游输入。
- 当前交付：补齐 12 个子章节中的已实现需求 item，新增真实短信 OTP、真实 Apple / WeChat provider validation、生产凭证门禁和 identity release gate 目标态需求，并在 `traceability.md` 中区分已实现代码证据和目标需求待实现状态；下游 `spec.md` 已作为 Draft 规格生成，但 Product Base merge、AC、TC 和测试证据仍待后续补齐。
- 非范围：本文不生成 `acceptance.md`、测试用例或测试证据，不修改后端代码，不把未实现的真实短信 OTP、真实 Apple/WeChat provider 校验、风控限流或 identity 专属生产 release gate 写成已实现代码证据。

## 上游来源
- `docs/product/base/requirements.md`：Product Base 总需求库格式和 merge-back 规则。
- `docs/product/base/spec.md`：Product Base 总规格库的下游契约边界。
- `docs/product/base/acceptance.md`：Product Base 总验收标准的下游契约边界。
- `docs/product/base/traceability.md`：Product Base 总追溯矩阵的覆盖和证据规则。
- `docs/product/increments/mvp-backend-foundation-auth/requirements.md`：MVP 后端认证基础需求来源。
- `docs/product/increments/mvp-backend-foundation-auth/spec.md`：MVP 后端认证基础规格来源。
- `docs/product/increments/mvp-backend-foundation-auth/acceptance.md`：MVP 后端认证基础验收来源。
- `docs/product/stages/p0-commercial-readiness.md`：商业化准备阶段中生产账号、社交登录配置和发布门禁要求来源。
- 用户提供的真实短信 OTP 策略表：真实短信 OTP 目标态需求来源。
- 当前后端身份认证、账号删除、审计和安全配置代码：作为本文已实现需求的反向固化来源。

## Product Base 规则
- Product Base 是活的总需求库；本模块文档用于承载身份认证与账号生命周期的稳定需求分库。
- 本文只写用户目标、用户路径、功能需求、成功标准、非目标和边界；不写 API schema、prompt schema、UI 布局、数据库字段、代码实现或测试实现。
- 每个需求 item 必须有唯一 ID，并能独立转化为 spec flow、acceptance criteria、test case 和 traceability row。
- 已实现代码基线需求必须能在 traceability 中追到 `Requirement -> Code Evidence`；`spec.md` 生成后，traceability 的 `Spec Flow` / `Spec Item` 必须更新为具体 spec ID；`AC` 和 `TC` 在验收标准与测试用例生成前标记为后续补齐。
- 目标态需求必须显式标记为 Proposed / 待实现；在代码实现前只能进入 target pending 追溯区，不得声明 code evidence traced。
- 未完成实现、验收、追溯、测试和报告证据的增量行为，不得在本文中标记为 Accepted。

## 稳定能力范围
`Identity & Account Lifecycle` 负责用户从身份证明、账号创建或解析、登录、会话签发、当前用户识别、退出登录，到账号删除、删除审计和基础认证错误的生命周期。该模块不承载会员订阅、支付、学习内容、AI 练习、课程推荐、业务学习状态或 identity 专属生产发布门禁实现。

## 稳定 Feature 映射
| Feature slug | 纳入状态 | Product Base 边界 |
| --- | --- | --- |
| `access-onboarding` | Included partial（部分纳入） | 登录门禁、首次账号创建和当前用户认证状态；首评提交、首评内容和首页下一步动作不在本模块承接。 |
| `identity-account-lifecycle` | Draft（草案） | 身份认证、账号生命周期、会话、删除、风控、审计和隐私的稳定模块候选；identity 专属生产发布门禁只作为未实现的下游 DevOps/Security target boundary，不纳入当前稳定能力候选。 |
| `profile-membership` | Related（相关） | 只引用 profile/current user 和账号设置入口；不承载会员权益、支付或订阅业务。 |

## 假设
- 当前文件不声明商业化身份系统已完整可发布。
- 真实短信 OTP、真实 Apple / WeChat provider validation、生产凭证门禁和 identity release gate 已在本文形成目标态需求，并已进入 Draft `spec.md` 和 pending traceability；仍需要在后续增量中补齐 AC、TC、架构/API/领域契约、实现和测试证据。
- 邮箱等其他生产级身份入口需要在后续增量中重新形成需求、规格、验收和测试证据。
- 审计、隐私和合规是横切能力；本文只归档当前身份生命周期已触发或复用的代码基线行为。
- 本模块已与 Draft `spec.md` 形成初始规格链路；后续还需与 `acceptance.md`、`traceability.md`、测试证据和质量报告形成完整追溯链，才可被 Product Base 总库引用或合并。
- 当前 token 策略是服务端 opaque bearer token，不是 JWT。

## 用户路径
1. 用户打开 App 或访问受保护能力，系统根据认证状态决定允许访问或返回认证错误。
2. 目标态手机号登录或注册中，用户先请求发送 OTP；系统校验手机号、同意状态、发送频率和风险信号后创建 OTP challenge 并发送短信。
3. 目标态手机号登录或注册中，用户提交 OTP 后，系统校验 challenge、验证码、过期时间、尝试次数和重放状态。
4. 新用户在 OTP 验证成功后才创建账号、基础 profile 和登录会话。
5. 已有用户通过已绑定身份再次登录时，系统解析到同一个账号并签发新的会话。
6. 已登录用户使用 access token 访问当前用户和受保护能力。
7. 会话过期前，客户端可使用 refresh token 刷新会话；刷新成功后旧 token hash 被替换。
8. 用户可以退出当前会话；退出后当前 session 不得继续访问受保护能力。
9. 用户可以发起账号删除；系统按 idempotency key 处理重复请求，撤销会话，清理用户数据并记录删除结果。
10. 运维可以查询共享审计日志，并在账号删除失败时按规则重试删除 job。

## 功能需求

### IDENTITY-ACCOUNT 账号创建与身份解析
- **IDENTITY-ACCOUNT-001** 当前代码基线的手机号登录解析中，系统必须使用去除前后空白后的手机号作为 `phone` 身份来源的 subject；该行为不等同于目标态 E.164 规范化。
- **IDENTITY-ACCOUNT-002** 当身份来源和身份 subject 组成的身份键已绑定用户账号时，系统必须解析到该绑定账号；账号可登录状态由登录需求处理。
- **IDENTITY-ACCOUNT-003** 当身份凭证校验通过且未解析到已有身份时，系统必须创建新的用户账号；目标态手机号 OTP 只能在 OTP 验证成功后触发账号创建。
- **IDENTITY-ACCOUNT-004** 新用户账号必须初始化为 `active` 账号状态。
- **IDENTITY-ACCOUNT-005** 新用户账号必须初始化为 `incomplete` 首评状态。
- **IDENTITY-ACCOUNT-006** 新用户账号创建时必须默认初始化 locale 为 `zh-CN`。
- **IDENTITY-ACCOUNT-007** 新用户账号必须绑定本次通过认证的登录身份作为初始登录身份。
- **IDENTITY-ACCOUNT-008** 新用户账号必须同时创建默认 profile。
- **IDENTITY-ACCOUNT-009** 同一身份来源和身份 subject 的有效身份绑定最多只能对应一个用户账号；冲突时系统不得创建或绑定重复身份。
- **IDENTITY-ACCOUNT-010** 默认 profile 的目标等级必须为 `L1`。
- **IDENTITY-ACCOUNT-011** 默认 profile 的每日分钟数必须为 `10`。

当前不归档为已实现：手机号 E.164 规范化、国家或地区 allowlist、独立注册接口。

### IDENTITY-OTP 手机短信 OTP
#### 当前代码基线（已实现）
- **IDENTITY-OTP-001** 当前代码基线的手机号登录请求必须提供非空手机号字段；该要求只代表输入存在性校验，不代表 E.164 规范化、短信发送或 OTP challenge 已实现。
- **IDENTITY-OTP-002** 当前代码基线的手机号登录请求必须提供非空验证码字段；该要求不代表验证码正确性、过期、一次性消费或重放控制已实现。
- **IDENTITY-OTP-003** 当手机号或验证码字段为空时，系统必须拒绝当前手机号登录请求并停止登录处理；不得继续身份解析、账号创建或 session 签发。

#### 真实短信 OTP 目标态（Proposed / 待实现）
##### Product behavior target（产品行为目标）
- **IDENTITY-OTP-004** 所有接收手机号的 OTP 登录或注册入口必须先完成 E.164 规范化；不支持国家或地区以及格式非法的号码不得进入 OTP 登录或注册流程。
- **IDENTITY-OTP-005** 用户请求手机号登录或注册 OTP 只启动一次待验证的 OTP 挑战，不得完成账号创建或认证会话。
- **IDENTITY-OTP-006** OTP 挑战必须绑定规范化手机号、`purpose=login_or_register`、挑战标识、请求上下文和过期时间。
- **IDENTITY-OTP-007** OTP 必须由服务端安全随机能力生成。
- **IDENTITY-OTP-032** OTP 默认格式必须为 6 位数字，且 OTP 位数配置不得低于 6 位。
- **IDENTITY-OTP-008** OTP 默认有效期必须从挑战可验证开始计算，默认 5 分钟，且有效期配置不得超过 10 分钟。
- **IDENTITY-OTP-009** OTP 明文只允许进入短信发送流程，不得持久化、不得写入日志、不得进入错误响应。
- **IDENTITY-OTP-010** OTP 持久化校验值必须使用服务端 secret 参与的不可逆校验机制，并绑定挑战和规范化手机号。
- **IDENTITY-OTP-011** 发送 OTP 前必须确认用户已接受当前版本服务条款和隐私政策；未接受时不得发送 OTP。
- **IDENTITY-OTP-012** 同一手机号重复发送 OTP 必须有冷却时间，默认冷却时间为 60 秒；命中冷却时不得发送 OTP。
- **IDENTITY-OTP-013** 同一手机号发送 OTP 必须按可配置时间窗口限流，默认每小时最多 5 次且每天最多 10 次。
- **IDENTITY-OTP-014** 同一 IP、device 或 install_id 必须有独立 OTP 发送限流；默认每个 IP 每小时最多 30 次且每天最多 100 次，每个 device 或 install_id 每小时最多 10 次且每天最多 30 次。
- **IDENTITY-OTP-015** 重新发送 OTP 后，旧 active OTP 不得再通过验证，且不得重置手机号和 purpose 级别的失败计数。
- **IDENTITY-OTP-016** 单个 OTP 挑战默认最多允许 5 次错误验证；超过上限后该挑战不得继续验证成功。
- **IDENTITY-OTP-017** OTP 验证失败必须增加手机号和 purpose 级别的失败计数；同一手机号和 purpose 在 30 分钟窗口内累计 10 次错误验证后，系统必须锁定该手机号和 purpose 的 OTP 发送和验证 15 分钟。
- **IDENTITY-OTP-018** OTP 验证成功必须只能消费一次挑战；已消费的挑战不得再次验证成功。
- **IDENTITY-OTP-033** 只有 OTP 挑战成功消费后，系统才允许进入账号创建或账号解析流程。
- **IDENTITY-OTP-019** OTP 验证成功后，用户必须获得登录会话能力。
- **IDENTITY-OTP-020** 已存在手机号身份时，OTP 验证成功必须解析到原用户，不得重复创建账号。
- **IDENTITY-OTP-021** 新手机号首次 OTP 验证成功后，系统必须按账号创建与身份解析规则创建账号、初始登录身份和默认资料。
- **IDENTITY-OTP-022** OTP 相关错误响应不得泄露手机号是否已注册。
- **IDENTITY-OTP-023** 短信 provider 发送失败时，系统必须返回 provider 失败类业务错误，且不得完成 OTP 登录。

##### Security and abuse-control target boundary（安全与防滥用目标边界）
- **IDENTITY-OTP-025** SMS 发送内容必须包含 App 名称、验证码、有效期和风险提示，且不得包含用户 ID、token、profile 信息或其他敏感用户资料。
- **IDENTITY-OTP-026** 生产 OTP 能力只能通过安全传输入口提供；非安全传输入口不得处理生产 OTP 请求。
- **IDENTITY-OTP-027** OTP 审计必须记录发送请求、验证成功、验证失败、过期、限流和 provider 失败事件。
- **IDENTITY-OTP-034** OTP 审计内容必须使用脱敏或 hash 后的手机号、purpose、request_id 和风险处置结果，不得记录 OTP 明文或 token 明文。
- **IDENTITY-OTP-028** OTP 策略必须纳入 SIM swap 或号码转移、异常设备、异常 IP 和短时大量请求风险信号。
- **IDENTITY-OTP-035** 命中 block 级风险时，系统不得发送 OTP 或发放会话，并必须返回风险阻断错误。
- **IDENTITY-OTP-036** 命中 step-up 级风险时，系统必须要求额外验证；额外验证未完成前不得发放会话。
- **IDENTITY-OTP-029** CAPTCHA 只能作为防自动化的分层控制；CAPTCHA 未通过时不得发送 OTP 或发放会话，CAPTCHA 通过后仍必须完成正确 OTP 校验才能登录或注册。
- **IDENTITY-OTP-030** OTP challenge 和校验值必须接入数据保留策略，并在过期后 24 小时内删除或失效。
- **IDENTITY-OTP-037** OTP 审计事件必须保留脱敏数据和 retention policy 版本。

##### Release / DevOps target boundary（发布与运维目标边界）
- **IDENTITY-OTP-024** 生产环境不得使用 deterministic 或 test OTP provider；错误配置必须被生产发布门禁阻断。

##### QA / testability input（QA 与可测试性输入，不作为 Product Base requirement item）
- **OTP-TESTABILITY-001** OTP 测试设计应使用可控时间和 fake SMS provider，覆盖验证成功、过期、重放、限流和 provider 失败。

当前仍未实现：真实短信发送、验证码正确性校验、验证码过期、验证码一次性消费、验证码重放控制、发送频控、provider release gate、OTP 审计和 OTP 测试替身。

### IDENTITY-PROVIDER Apple / WeChat 第三方身份
- **IDENTITY-PROVIDER-001** 当前代码基线的 Apple 登录入口必须把请求归属为 `apple` 身份来源；该行为不代表 Apple identity token 签名、audience、issuer、expiry 或 nonce 校验已实现。
- **IDENTITY-PROVIDER-002** 当前代码基线的 WeChat 登录入口必须把请求归属为 `wechat` 身份来源；该行为不代表 WeChat code、openid、unionid 或 session 校验已实现。
- **IDENTITY-PROVIDER-003** 当前代码基线的 Apple / WeChat 登录请求必须包含非空 provider token；该要求只代表输入存在性校验，不代表 provider token 真实性、过期、签名或服务端 provider 校验已实现。
- **IDENTITY-PROVIDER-004** 当前代码基线必须把 provider token 的 hash 作为第三方身份 subject；该行为仅归档当前实现限制，不代表目标态 Apple / WeChat 稳定身份 subject 规则。

当前不归档为已实现：Apple identity token 签名、audience、issuer、expiry、nonce 校验；WeChat code、openid、unionid 或 session 校验。

#### 真实 Apple / WeChat provider validation 目标态（Proposed / 待实现）
- **IDENTITY-PROVIDER-005** Apple 登录必须由后端校验 Apple identity token 的签名、issuer、audience 和 expiry；校验通过前不得进入身份解析、账号创建或 session 签发。
- **IDENTITY-PROVIDER-006** Apple 登录必须绑定并校验本次登录 nonce；nonce 缺失、不匹配、过期或重放时必须拒绝登录，且不得进入身份解析、账号创建或 session 签发。
- **IDENTITY-PROVIDER-007** Apple 稳定身份 subject 必须来自已验证 Apple `sub`，或来自基于已验证 `sub` 的版本化、不可逆、服务端 secret 保护摘要；不得使用 raw identity token、authorization code 或 provider token hash 作为稳定 subject。
- **IDENTITY-PROVIDER-008** WeChat 登录必须由后端使用生产 provider 配置交换 authorization code，并校验 provider 响应成功后才允许进入身份解析、账号创建或 session 签发。
- **IDENTITY-PROVIDER-009** WeChat 登录必须绑定并校验 `state` 或等效一次性 challenge；state 缺失、不匹配、过期或重放时必须拒绝登录，且不得进入身份解析、账号创建或 session 签发。
- **IDENTITY-PROVIDER-010** WeChat provider 响应包含已验证 `unionid` 时，稳定身份 subject 必须使用该 `unionid`，不得优先使用 `openid`。
- **IDENTITY-PROVIDER-011** Apple / WeChat provider validation 失败，包括签名、audience、issuer、expiry、nonce、state、provider 错误响应或 subject 缺失，必须在身份解析、账号创建和 session 签发前停止处理。
- **IDENTITY-PROVIDER-012** Apple / WeChat provider 不可用、超时或配置不可用时，系统必须返回 provider failure，不得创建账号、绑定身份或签发 session。
- **IDENTITY-PROVIDER-013** 生产目标态不得把 raw provider token、Apple authorization code、Apple identity token 或 WeChat code 的 hash 作为 Apple / WeChat 稳定身份 subject。
- **IDENTITY-PROVIDER-014** WeChat `openid` 只能在已明确单一 WeChat app 边界且 provider 响应缺少 `unionid` 时作为稳定身份 subject fallback；缺少该边界时不得使用 `openid` 创建账号、绑定身份或签发 session。
- **IDENTITY-PROVIDER-015** WeChat `openid` fallback 身份后续获得已验证 `unionid` 或出现 subject 冲突时，系统必须解析到既有账号或停止处理并返回冲突错误，不得重复创建账号。

### IDENTITY-LOGIN 登录与 session 签发
- **IDENTITY-LOGIN-001** 当前代码基线的手机号登录请求必须声明已接受条款后才允许继续认证处理；未接受时必须拒绝，且不得进入身份解析、账号创建或 session 签发；该要求不代表 Terms/Privacy consent 持久化已实现。
- **IDENTITY-LOGIN-002** 当前代码基线的 Apple / WeChat 登录请求必须声明已接受条款后才允许继续认证处理；未接受时必须拒绝，且不得进入 provider token subject 处理、身份解析、账号创建或 session 签发。
- **IDENTITY-LOGIN-003** 手机号、Apple、WeChat 登录入口必须不要求既有认证 session；public entry 不得绕过 schema version、terms、凭证或账号状态校验。
- **IDENTITY-LOGIN-004** 身份解析或账号创建得到的账号不为 `active` 时，系统必须拒绝登录，且不得创建认证 session 或发放 token。
- **IDENTITY-LOGIN-005** 登录请求通过 schema version、terms、凭证和账号状态门禁后，系统必须为本次解析或创建的用户创建 `active` 认证 session。
- **IDENTITY-LOGIN-006** 登录成功响应必须返回当前用户、access token、refresh token 和 access token 过期时间；access / refresh token 的生命周期和轮换语义由 `IDENTITY-TOKEN` 子章节承接。
- **IDENTITY-LOGIN-007** 当前代码基线的登录和刷新请求必须在认证状态变化前拒绝不支持的 schema version；拒绝后不得创建 session、发放 token 或刷新 token；具体 schema 字段形态由 API contract 承接。
- **IDENTITY-LOGIN-008** 生产目标态登录请求必须在账号解析、账号创建或 session 签发前完成可信凭证门禁：手机号登录必须证明 OTP challenge 已成功校验并一次性消费；Apple / WeChat 登录必须证明 provider verifier 已成功校验。仅校验手机号、验证码或 provider token 非空不得满足生产凭证门禁。

当前不归档为已实现：邮箱登录、密码登录、设备绑定登录、登录失败计数、近期认证策略。

### IDENTITY-TOKEN Access / refresh token 生命周期
- **IDENTITY-TOKEN-001** 登录或刷新成功时，系统必须向客户端返回服务端 opaque access token 和 refresh token；token 不承载客户端可解析身份 claims，JWT 不归档为已实现。
- **IDENTITY-TOKEN-002** token 原始值必须由后端使用不可预测的密码学安全随机源生成；Java `SecureRandom` 是当前代码基线实现证据，不作为产品需求唯一表述。
- **IDENTITY-TOKEN-003** 系统不得持久化 access token 或 refresh token 明文；持久化会话记录只能保存可用于匹配的 token 摘要值。
- **IDENTITY-TOKEN-004** 当前代码基线下，access token 的有效期必须从签发或刷新轮换时起计算为 30 分钟。
- **IDENTITY-TOKEN-005** 当前代码基线下，refresh token 的有效期必须从签发或刷新轮换时起计算为 30 天。
- **IDENTITY-TOKEN-006** 受保护用户请求必须携带 access token 才能认证；当前代码基线通过 Bearer token 传递，具体 header 字段形态由 API contract 承接。
- **IDENTITY-TOKEN-007** 常规 access token 认证必须匹配 active 且 access 未过期的认证 session；不匹配、过期或已撤销时必须拒绝认证。
- **IDENTITY-TOKEN-008** 常规 access token 认证必须要求关联用户为 `active` 状态；账号删除重试的特殊认证路径由 `IDENTITY-DELETE` 子章节承接，不作为常规用户认证通过。
- **IDENTITY-TOKEN-009** refresh token 必须匹配 active 且 refresh 未过期的 session，并且关联用户为 `active` 状态，才能刷新 token。
- **IDENTITY-TOKEN-010** refresh 成功必须在同一认证 session 上发放新的 access token 和 refresh token，并使旧 access / refresh token 不再可用于后续认证或刷新；持久化摘要替换细节由 spec 承接。
- **IDENTITY-TOKEN-011** refresh token 缺失、空白、无效、过期或已被轮换时，系统必须返回未认证错误，且不得刷新、轮换或创建新的 session/token。
- **IDENTITY-TOKEN-012** 受保护 API 认证不得依赖服务端 HTTP session 或 cookie session；用户认证状态必须由 token 与认证 session 记录共同证明。

当前不归档为已实现：JWT claims、JWT 签名校验、JWKS、refresh token reuse 风险告警。

### IDENTITY-ME 当前用户与 profile
- **IDENTITY-ME-001** 当前用户资料读取能力必须只允许通过常规 access token 认证的用户访问；未认证或认证上下文无效时必须拒绝；具体 endpoint 路径由 API contract 承接。
- **IDENTITY-ME-002** 当前用户资料读取成功时，系统必须返回当前认证用户的用户标识、display name、avatar ref、locale、account status 和 onboarding status；具体响应字段形态由 API contract 承接。
- **IDENTITY-ME-003** 当前用户资料读取成功时，系统必须返回当前用户 profile 的 target level 和 daily minutes；若当前代码基线缺失 profile，补建或错误策略不由本 item 承诺。
- **IDENTITY-ME-004** 当前用户资料读取必须复用 `IDENTITY-TOKEN` 的常规 access token 认证结果；认证上下文无效、session 不可认证或关联用户不可认证时必须拒绝访问。
- **IDENTITY-ME-005** 已认证用户必须只能更新自己的 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time；未提供的可选字段不得被强制改写；avatar ref 允许范围由 `IDENTITY-ME-006` 承接。
- **IDENTITY-ME-006** 当用户提交 avatar ref 更新时，系统必须只接受内置头像引用；空白或非内置引用必须拒绝，且不得保存该 avatar ref 更新。

当前不归档为已实现：独立 profile gate 判定对象、复杂账号权限矩阵；首评提交后的 onboarding status 推进、首评题目、场景选择和首页 next action 编排由 access-onboarding / Home Summary / Learning Entry 承接，不在本模块定义 requirement item。

### IDENTITY-LINK 初始登录身份绑定与身份键解析
- **IDENTITY-LINK-001** 当新账号由账号创建流程产生时，系统必须为该账号建立一条初始登录身份绑定；该绑定必须来自本次已通过认证的身份来源与 subject；已登录用户绑定第二登录身份不由本 item 承诺。
- **IDENTITY-LINK-002** 初始登录身份绑定创建成功时，该登录身份必须初始化为 `active` 状态；该状态只代表当前代码基线的新建身份默认状态，不承诺已实现身份禁用、解绑或状态过滤策略。
- **IDENTITY-LINK-003** 身份解析时，系统必须使用身份来源和身份 subject 组成的身份键查找绑定账号；不得只用 subject 或只用身份来源单独解析；身份状态过滤不归档为当前已实现。

当前不归档为已实现：已登录用户绑定第二登录身份、解绑身份、至少保留一个可登录身份、身份绑定二次验证、身份禁用或恢复、身份查询时过滤 inactive auth identity。

### IDENTITY-LOGOUT 退出登录
- **IDENTITY-LOGOUT-001** 已认证用户调用 logout 时，系统必须撤销本次认证上下文对应的当前 session；该行为只影响当前 session，不承诺退出同用户其他 session。
- **IDENTITY-LOGOUT-002** 当 logout 请求无法解析到可撤销的当前 session 时，系统必须返回未认证错误，且不得创建、撤销或修改任何 session。
- **IDENTITY-LOGOUT-003** 当前 session 撤销成功时，系统必须把该 session 状态更新为 `revoked`。
- **IDENTITY-LOGOUT-004** 当前 session 撤销成功时，系统必须记录该 session 的撤销发生时间。
- **IDENTITY-LOGOUT-005** 已撤销 session 不得再通过常规 access token 认证；后续认证失败边界复用 `IDENTITY-TOKEN` 的常规 access token 认证规则。

当前不归档为已实现：用户主动退出全部设备接口。

### IDENTITY-DELETE 账号删除与生命周期状态
- **IDENTITY-DELETE-001** 通过常规 access token 认证并解析到当前账号的用户，必须能为该当前账号发起删除请求；系统不得允许该用户为其他账号发起删除。
- **IDENTITY-DELETE-002** 当前账号删除请求和运维删除重试请求必须携带长度在 8 到 128 个字符之间的幂等键；当幂等键缺失、长度小于 8 个字符或大于 128 个字符时，系统必须拒绝请求，不得创建删除任务或重试幂等记录、不得撤销 session、不得改变账号或删除任务状态。
- **IDENTITY-DELETE-003** 同一用户使用同一幂等键再次发起删除请求时，系统必须返回该用户和该幂等键已经关联的删除任务，且不得创建第二个删除任务。
- **IDENTITY-DELETE-004** 只有账号状态为 `active` 或 `deletion_requested` 时，系统才允许该账号进入删除执行；账号状态不是这两者时，系统必须拒绝进入删除执行。
- **IDENTITY-DELETE-005** 删除任务进入访问撤销阶段时，系统必须撤销该账号关联用户的所有 active session；该行为不同于 logout 只撤销当前 session。
- **IDENTITY-DELETE-006** 删除执行必须清理该用户关联的 AI media、TTS cache ownership 和 provider metric 数据。
- **IDENTITY-DELETE-007** 删除完成后，系统必须把账号生命周期状态标记为 `deleted`。
- **IDENTITY-DELETE-008** 删除完成后，系统必须保留用于表示删除状态的最小账号信息：展示名为 `Deleted User`、头像引用为空、onboarding status 为 `deleted`；该最小账号信息不等同于 user profile 明细数据，profile 明细删除由 `IDENTITY-DELETE-014` 承接。
- **IDENTITY-DELETE-009** 通过常规 access token 认证并解析到当前账号的用户，必须能查询该当前账号最新删除任务状态；账号进入 `deleted` 后不能通过常规 access token 认证继续查询，删除请求重放场景由 `IDENTITY-DELETE-012` 承接。
- **IDENTITY-DELETE-010** 通过 ops bearer token 运维认证的请求，必须能对状态为 failed 的删除任务发起重试。
- **IDENTITY-DELETE-011** 删除重试只有在删除任务状态为 `failed`，且本次重试幂等键未关联该删除任务时，才允许启动新的重试执行；不得因 `completed`、`requested`、`access_revoked`、`deleting_learning_data`、`anonymizing_audit_refs` 或未识别任务状态启动新的重试执行；具体返回或失败结果由 Spec 重试决策表承接。
- **IDENTITY-DELETE-012** 当请求携带的 token 对应账号状态为 `deleted` 或 `deletion_requested`，且请求幂等键与该账号已有删除任务的幂等键一致时，系统必须允许该请求重放账号删除请求并返回该已有删除任务；该例外不得用于登录、资料读取或其他受保护用户请求。
- **IDENTITY-DELETE-013** 删除执行必须删除该用户的登录身份数据。
- **IDENTITY-DELETE-014** 删除执行必须删除该用户的 profile 明细数据；删除后保留的最小账号信息由 `IDENTITY-DELETE-008` 承接。
- **IDENTITY-DELETE-015** 删除执行必须删除该用户的 onboarding assessment、learning route 和 scenario state 数据。
- **IDENTITY-DELETE-016** 删除执行必须删除该用户的 practice session、practice turn 和 session summary 数据。
- **IDENTITY-DELETE-017** 删除执行必须删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 数据。
- **IDENTITY-DELETE-018** 删除执行必须删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 数据。
- **IDENTITY-DELETE-019** 删除执行必须删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 数据。
- **IDENTITY-DELETE-020** 删除执行必须删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 数据。

当前不归档为已实现：异步队列化删除保证、外部可观察的删除中阶段承诺、可恢复窗口、近期认证、用户自助取消删除。

### IDENTITY-RISK 认证错误、ops admin 访问门禁与当前防滥用边界
- **IDENTITY-RISK-001** 受保护用户请求无法建立常规用户认证上下文时，系统必须返回 JSON 格式的未认证错误；具体 access token eligibility 由 `IDENTITY-TOKEN` 承接，公共端点不由本 item 承诺。
- **IDENTITY-RISK-002** admin 请求只有通过 ops bearer token 运维认证后才能进入 admin 处理；常规用户 access token 不得获得 admin 权限。
- **IDENTITY-RISK-003** ops bearer token 认证必须使用服务端保存的 token 摘要进行匹配，不得以 ops token 明文作为比较基准。

当前不归档为已实现：登录限流、OTP 发送限流、验证码失败次数限制、IP 风控、设备风控、CAPTCHA、账号锁定。

### IDENTITY-AUDIT 审计、隐私与合规
- **IDENTITY-AUDIT-001** 创建或持久化审计记录时，系统必须对审计目标引用、请求标识和详情内容执行敏感信息清洗；清洗后输出必须满足 `IDENTITY-AUDIT-002` 的敏感集合与安全占位规则。
- **IDENTITY-AUDIT-002** 审计清洗必须按当前代码基线的封闭敏感集合识别 key token：`api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`；并识别 value pattern：`signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`。命中敏感 details key 时必须把 details key 输出为 `redacted_field_<index>` 且 value 输出为 `redacted`；命中敏感 details value 时必须把 value 输出为 `redacted`；敏感 target ref 必须输出 `redacted:target_ref`；敏感或空白 request id 必须输出 `unknown`。
- **IDENTITY-AUDIT-003** 账号删除执行完成时，系统必须写入删除完成审计事件；若完成来自运维重试，审计事件必须能区分重试完成结果。
- **IDENTITY-AUDIT-004** 账号删除执行失败时，系统必须写入删除失败审计事件；若失败来自运维重试，审计事件必须能区分重试失败结果。
- **IDENTITY-AUDIT-005** 通过 ops 运维认证并被接受进入处理的账号删除重试请求，必须写入删除重试请求审计事件；未通过认证或未进入重试处理的请求不由本 item 承诺。
- **IDENTITY-AUDIT-006** ops admin 查询审计日志列表时，系统必须记录该查询行为的审计事件；该事件只证明 admin audit 查询被记录，不承诺普通用户可见的共享审计日志查询。

当前不归档为已实现：登录、refresh、logout、profile 更新的身份审计事件；Terms/Privacy consent 持久化；身份模块专属审计事件目录。

### IDENTITY-RELEASE 未实现生产发布边界
当前无可归档为已实现的 identity 专属 release gate 需求。

#### Release / DevOps target boundary（Proposed / 待实现）
- **IDENTITY-RELEASE-001** 生产发布门禁必须阻断未消费 OTP challenge 即可完成手机号登录、账号创建或 session 签发的后端实现。
- **IDENTITY-RELEASE-002** 生产发布门禁必须阻断 raw provider token、Apple authorization code、Apple identity token 或 WeChat code 的 hash 作为 Apple / WeChat 稳定身份 subject 的后端实现。
- **IDENTITY-RELEASE-003** 生产发布门禁必须要求真实 SMS、Apple 和 WeChat provider 配置以及对应外部证据引用；缺失时不得声明商业发布通过。

当前不归档为已实现：生产环境禁用 fake OTP、生产环境禁用未校验 provider token、identity provider 配置缺失时阻断发布、identity 专属 release gate。现有通用 release health warning 只是状态提示，不是 identity 专属生产阻断。

## 成功标准
- **SC-IDENTITY-001** 每条已实现需求必须有唯一 ID。
- **SC-IDENTITY-002** 每条已实现需求必须只表达一个可验证行为。
- **SC-IDENTITY-003** 每条已实现需求必须能在 `traceability.md` 中追到代码证据。
- **SC-IDENTITY-004** `traceability.md` 必须把已生成规格对应的 `Spec Flow` / `Spec Item` 更新为具体 spec ID，并在验收标准与测试用例生成前显式标记 `AC` 和 `TC` 为后续补齐。
- **SC-IDENTITY-005** 未实现的真实 OTP、真实 provider 校验、风控限流和 identity release gate 不得写成已实现需求。
- **SC-IDENTITY-006** 每条目标态 OTP、provider validation、生产凭证门禁和 release target boundary 需求必须能独立转成至少一个 AC 和至少一个 TC。
- **SC-IDENTITY-007** 目标态 OTP 需求在代码实现前必须在 traceability 中标记为待实现，不得计入 code evidence traced。
- **SC-IDENTITY-008** 目标态 Apple / WeChat provider validation、生产凭证门禁和 identity release gate 需求在代码实现前必须在 traceability 中标记为待实现，不得计入 code evidence traced。

## 非目标
- 本文不生成 `acceptance.md`。
- 本次不生成测试用例或测试证据。
- 本模块文档不单独承载首页摘要等跨模块 Product Base 行为；相关行为由 Product Base 根目录总库承接。
- 本次不修改后端、Flutter、OpenAPI、数据库迁移或测试代码。
- 本次不声明当前实现已经满足商业化身份认证发布要求。
- 本次不声明真实短信 OTP 目标态需求已经完成实现、验收或测试。
- 本次不声明真实 Apple / WeChat provider validation、生产凭证门禁或 identity release gate 目标态需求已经完成实现、验收或测试。
- 本次不把平台级 admin audit 查询写成身份生命周期业务流程。

## 下游产物
- `docs/product/base/identity-account-lifecycle/spec.md`
- `docs/product/base/identity-account-lifecycle/acceptance.md`
- `docs/product/base/identity-account-lifecycle/traceability.md`

## 后续合并规则
后续补齐本模块 `acceptance.md`、测试用例和测试证据后，必须保持 `traceability.md` 的 `Spec Flow` / `Spec Item` 与 `spec.md` 的具体 spec ID 一致，并补齐 AC、TC、测试证据和报告证据；在实现、验收、追溯、测试和报告证据完整或例外已记录后，再由 Product Manager 决定是否合并到 Product Base 总库。
