# Requirements：Identity OTP Production Hardening

## 状态
Backend API/DB/domain/core evidence added. 本文不创建竞争性的产品需求；它把 Product Base `Identity & Account Lifecycle` 中真实短信 OTP target IDs 下沉为本执行包的实现范围。后端核心切片已落地，provider evidence、release evidence、Dart client drift 和社交 provider verifier closure 仍 pending。

## 上游来源
- `docs/product/base/identity-account-lifecycle/requirements.md`
- `docs/product/base/identity-account-lifecycle/spec.md`
- `docs/product/increments/identity-otp-production-hardening/definition.md`

## Locked Requirement Coverage
| Increment Requirement | Upstream Product Base Requirement | Requirement summary | Work package | Status |
| --- | --- | --- | --- | --- |
| OTP-PROD-FR-004 | IDENTITY-OTP-004 | OTP 登录/注册入口必须先输出 E.164；非法或不支持号码不得进入流程。 | OTP-PROD-WP-001 | Backend implemented - release pending |
| OTP-PROD-FR-005 | IDENTITY-OTP-005 | 发送 OTP 只创建待验证 challenge，不得创建账号或 session。 | OTP-PROD-WP-002 | Backend implemented - release pending |
| OTP-PROD-FR-006 | IDENTITY-OTP-006 | Challenge 必须绑定 E.164、purpose、challenge_id、上下文和过期时间。 | OTP-PROD-WP-002 | Backend implemented - release pending |
| OTP-PROD-FR-007 | IDENTITY-OTP-007 | OTP 必须由服务端安全随机能力生成。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-032 | IDENTITY-OTP-032 | OTP 默认 6 位数字，配置不得低于 6 位。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-008 | IDENTITY-OTP-008 | OTP 默认 5 分钟有效，配置上限 10 分钟。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-009 | IDENTITY-OTP-009 | OTP 明文只进入短信发送流程，不持久化、不进日志、不进错误响应。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-010 | IDENTITY-OTP-010 | OTP 校验值必须使用服务端 secret 参与的不可逆机制并绑定 challenge 和手机号。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-011 | IDENTITY-OTP-011 | 发送 OTP 前必须确认当前条款和隐私政策 consent。 | OTP-PROD-WP-002 | Backend implemented - release pending |
| OTP-PROD-FR-012 | IDENTITY-OTP-012 | 同一手机号 resend 默认 60 秒冷却。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-013 | IDENTITY-OTP-013 | 同一手机号发送按小时/日限流。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-014 | IDENTITY-OTP-014 | IP、device、install_id 必须有独立发送限流。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-015 | IDENTITY-OTP-015 | Resend 后旧 active challenge 不得再通过，且不重置 phone+purpose 失败计数。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-016 | IDENTITY-OTP-016 | 单个 challenge 默认最多 5 次错误验证。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-017 | IDENTITY-OTP-017 | phone+purpose 30 分钟 10 次错误后锁定发送和验证 15 分钟。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-018 | IDENTITY-OTP-018 | OTP 验证成功必须只能原子消费一次。 | OTP-PROD-WP-003 | Backend implemented - release pending |
| OTP-PROD-FR-033 | IDENTITY-OTP-033 | 只有 consumed challenge 才能进入账号创建或账号解析。 | OTP-PROD-WP-007 | Backend implemented - release pending |
| OTP-PROD-FR-019 | IDENTITY-OTP-019 | OTP 成功后用户必须获得登录会话能力。 | OTP-PROD-WP-007 | Backend implemented - release pending |
| OTP-PROD-FR-020 | IDENTITY-OTP-020 | 已存在手机号身份时必须解析到原用户，不重复创建账号。 | OTP-PROD-WP-001, OTP-PROD-WP-007 | Backend implemented - release pending |
| OTP-PROD-FR-021 | IDENTITY-OTP-021 | 新手机号首次 OTP 成功后创建账号、登录身份和默认资料。 | OTP-PROD-WP-007 | Backend implemented - release pending |
| OTP-PROD-FR-022 | IDENTITY-OTP-022 | OTP 错误响应不得泄露手机号是否已注册。 | OTP-PROD-WP-002 | Backend implemented - release pending |
| OTP-PROD-FR-023 | IDENTITY-OTP-023 | SMS provider 失败时返回 provider 失败类错误且不得完成 OTP 登录。 | OTP-PROD-WP-004 | Backend implemented - release pending |
| OTP-PROD-FR-025 | IDENTITY-OTP-025 | SMS 内容只包含 App 名、验证码、有效期和风险提示，不含敏感用户资料。 | OTP-PROD-WP-004 | Backend implemented - release pending |
| OTP-PROD-FR-026 | IDENTITY-OTP-026 | 生产 OTP 能力只能通过安全传输入口提供。 | OTP-PROD-WP-002 | Backend implemented - release pending |
| OTP-PROD-FR-027 | IDENTITY-OTP-027 | OTP 审计必须记录发送、验证成功、验证失败、过期、限流和 provider 失败事件。 | OTP-PROD-WP-006 | Backend implemented - release pending |
| OTP-PROD-FR-034 | IDENTITY-OTP-034 | OTP 审计只记录脱敏/hash 手机号、purpose、request_id 和风险处置结果。 | OTP-PROD-WP-006 | Backend implemented - release pending |
| OTP-PROD-FR-028 | IDENTITY-OTP-028 | OTP 风险策略必须纳入 SIM swap/号码转移、异常设备、异常 IP 和短时大量请求。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-035 | IDENTITY-OTP-035 | 风险 block 时不得发送 OTP 或发放 session。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-036 | IDENTITY-OTP-036 | 风险 step-up 时必须完成额外验证后才允许 session。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-029 | IDENTITY-OTP-029 | CAPTCHA 只能作为自动化防护，未通过不得发送 OTP 或登录，通过后仍必须校验 OTP。 | OTP-PROD-WP-005 | Backend implemented - release pending |
| OTP-PROD-FR-030 | IDENTITY-OTP-030 | Challenge 和校验值必须接入 retention，过期后 24 小时内删除或失效。 | OTP-PROD-WP-006 | Backend implemented - release pending |
| OTP-PROD-FR-037 | IDENTITY-OTP-037 | OTP 审计事件必须保留脱敏数据和 retention policy version。 | OTP-PROD-WP-006 | Backend implemented - release pending |
| OTP-PROD-FR-024 | IDENTITY-OTP-024 | 生产环境不得使用 deterministic/test OTP provider，错误配置必须被 release gate 阻断。 | OTP-PROD-WP-004, OTP-PROD-WP-008 | Backend implemented - release pending |

## Provider And Evidence Requirements
- Production SMS provider 必须通过 secret/config refs 配置；当 refs 缺失、占位、fake、sandbox 或非生产时必须 fail closed。
- Phone-risk provider 必须为每个允许的生产国家提供 SIM swap 或号码转移情报；不支持的国家必须留在 OTP allowlist 之外。
- CAPTCHA provider 必须由服务端验证，且不得替代 OTP verification 或 step-up proof。
- Step-up provider 必须与 CAPTCHA 区分。本包的 step-up proof 目标是既有已 enrolled identity 的 passkey/WebAuthn assertion；未绑定或未 enrolled 的 phone identity 必须 risk-blocked，不得绕过 step-up。
- HTTPS enforcement evidence 必须指明能在生产环境阻断非安全 OTP 请求的应用设置或可信 gateway/proxy 证明。

## Implementation Readiness Rule
只有当 `acceptance.md`、`test_cases.md` 和 `traceability.md` 中每一行都具备稳定 AC/TC/trace row 后，才可以开始实现。只有当每一行都挂接代码、测试、release evidence 和独立审查后，才可以声明完成。
