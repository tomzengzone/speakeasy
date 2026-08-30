# SpeakEasy 用户认证、会话与 Token 生命周期管理需求方案

> 文档性质：独立需求基线（Standalone Requirements Baseline）
> 版本：1.0
> 日期：2026-08-26
> 状态：Draft for review
> 适用范围：SpeakEasy Flutter 客户端、认证后端、业务 API 与运维安全能力
> 说明：本文不自动纳入项目现有 Story Map、Functional Requirement、Engineering Contract、Gate 或追溯治理体系；如后续决定实施，再按实际交付流程拆分。

## Implementation Note — Phase 2 / Phase 3 Hardening（2026-08-30）

本次实现保持本文需求不变，并采用与现有系统最匹配的 opaque token 演进路径：

- `AuthAccessToken` registry 独立持有 Access Token hash、过期时间、`client_id`、`audience` 和 `scope`；正常 refresh 不再覆盖或撤销未过期旧 Access Token。
- `AuthSession` 不再持有 Access/Refresh Token hash；Refresh Token 生命周期事实只存在于 `AuthRefreshToken`，授权 grant context 由对应 `AuthRefreshTokenFamily` 持有。
- 当前第一方上下文为 `speakeasy-mobile` → `speakeasy-api`，最小 scope 集合为 `user:read`、`user:write`、`course:read`、`learning:read`、`learning:write`、`ai:use`、`session:manage`。
- 统一认证过滤器先验证 opaque registry、token expiry、client/audience、Session/security epoch 和账号状态，再由 Spring Security 校验 endpoint 所需 scope；refresh 只继承原 grant，客户端不能扩大 scope。
- 登录 grant 由服务端 `MobileClientGrantPolicy` 决定并在 Token Family 中快照；请求 header 或后续配置变化不能扩大既有会话 scope。
- Flutter 继续复用现有 SecureTokenStore、CredentialRepository、RefreshCoordinator 和 AuthenticatedRequestExecutor；仅 `ACCESS_TOKEN_EXPIRED` 可触发一次 refresh/retry，等待队列限制为 64 个调用方和 15 秒。
- 跨启动凭证只从 Secure Storage 恢复；首次凭证读取会清除旧 Hive Access Token，且不再将其作为认证回退。安全存储 v1 凭证会先写入设备绑定且不参与同步的 v2 Keychain 条目再删除旧条目；Android 禁止备份迁移并保留历史命名空间以兼容升级。
- Chapter 8 整改后审计结果为 `66 PASS / 8 PARTIAL / 6 FAIL / 3 N/A`；逐项证据和剩余路线见 `docs/quality/authentication_requirement_coverage.md`。其中 `SESSION-004` 仍为 FAIL，未用未接线 helper 冒充密码/账号恢复能力。

该实现注记用于记录代码落地方式，不把本文 standalone baseline 自动转换为 Story/FR/Engineering Contract，也不修改下列 Requirement 的语义。

## 1. 文档目标

建立一套适用于商业移动应用的统一身份认证、登录会话和 Token 生命周期管理体系，解决以下问题：

- 用户通过手机号、邮箱、Apple、微信等方式登录后，如何统一建立 SpeakEasy 会话；
- Access Token 如何签发、保存、使用、刷新和失效；
- Refresh Token 如何安全存储、轮换、撤销和检测重放；
- Access Token 过期后如何无感恢复业务请求；
- 多个并发 API 同时返回 401 时如何只执行一次刷新；
- APP 冷启动、热启动、前后台切换和离线恢复时如何判断真实登录状态；
- Refresh Token 失效、Session 被撤销或账号被禁用后如何安全退出；
- 用户主动退出、退出全部设备以及远程撤销设备时如何关闭会话；
- Authentication、Authorization、Subscription/Entitlement 如何保持职责分离；
- 如何提供可测试、可观测、可审计、可扩展且不泄露凭证的认证基础设施。

本文同时修复当前故障暴露出的系统性问题：业务接口返回 401 后，错误不应继续下沉为“目标表达播放失败”，而应先由认证基础设施完成刷新、重试或统一退登。

## 2. 目标与非目标

### 2.1 目标

- 采用短生命周期 Access Token 与较长生命周期 Refresh Token。
- 以服务端 Session 作为长期登录状态与设备状态的事实来源。
- 客户端业务模块不直接读写 Token，也不自行刷新或强制退出。
- 对可恢复的 Token 过期实现用户无感刷新。
- 对不可恢复的认证失败提供确定、统一且安全的退出路径。
- 对 Refresh Token Rotation、重放检测、多设备会话和安全事件撤销提供商业级支持。
- 对所有认证路径建立稳定错误码、审计事件、指标和验收测试。

### 2.2 非目标

- 本文不定义会员订阅、课程购买或内容授权规则。
- 本文不要求第一阶段自建完整的第三方 OAuth/OIDC 身份提供商。
- 本文不要求业务服务保存每个 Access Token。
- 本文不把设备指纹当作绝对可信身份凭证。
- 本文不规定必须使用某一家身份云服务或某一种 Flutter 状态管理框架。
- 本文不把网络超时、DNS、TLS 或 5xx 错误误判为登录失效。

## 3. 标准基础与关键结论

本方案采用以下标准方向：

- OAuth 2.0 / OAuth 2.0 Security Best Current Practice：定义 Access Token、Refresh Token、最小权限、撤销与安全刷新要求。
- OAuth 2.0 for Native Apps：移动 APP 属于 public client，不得依赖可保密的客户端密钥；标准授权登录使用 Authorization Code + PKCE，并通过外部浏览器或系统安全浏览器会话完成。
- OpenID Connect：在 OAuth 2.0 之上提供身份认证与 ID Token；ID Token 不得替代 Business API 的 Access Token。

结论：当前的 `Authentication + ApiClient + Auth Interceptor` 是合理的客户端工程结构，但它不是独立的行业标准。完整方案必须同时包含服务端 Authorization Server、Session Store、Refresh Token Rotation、Resource Server 校验、Revocation 和客户端状态机。

## 4. 总体架构

```text
                         Flutter APP
                              │
              ┌───────────────┴────────────────┐
              │                                │
        Authentication                    Business Features
              │                                │
       Login / Logout                     Course / Learning
       Refresh / Restore                  User / TTS / AI
       Social Login                       Progress / Profile
              │                                │
              └──────────────┬─────────────────┘
                             │
                          ApiClient
                             │
                      Auth Interceptor
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
  TokenProvider       RefreshCoordinator       ErrorMapper
       │                Single-Flight              │
       └─────────────────────┬─────────────────────┘
                             │
                         AuthManager
                             │
              ┌──────────────┼──────────────┐
              │              │              │
          TokenStore      AuthState      Session Cache
              │
        Secure Storage

============================================================

                            Backend
                              │
                    Authorization Server
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
        Login              Refresh              Logout
          │               Rotation            Revocation
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                         Session Store
                              │
                         Token Service
                              │
                         Access Token
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
       User API           Course API           AI API
          └────────────── Resource Servers ──────┘
```

## 5. 角色与职责

### 5.1 Authentication Service

负责登录凭证验证、账号状态检查、第三方身份归一、Session 创建、Token 签发、Refresh、Logout、Revocation、设备会话查询及安全事件处理。

不得负责课程、学习进度、TTS、AI 对话或会员权益判断。

### 5.2 Resource Server

包括 User、Course、Learning、TTS、AI 等业务 API。每次请求必须验证 Access Token 的签名或有效性、过期时间、issuer、audience、scope 和 Session 状态策略。

Resource Server 不接受 Refresh Token，也不负责刷新 Token。

### 5.3 AuthManager

Flutter 客户端认证状态的唯一入口，负责：

- 当前认证状态；
- 当前用户与 Session 摘要；
- Token 读取、保存、更新和清除；
- APP 启动会话恢复；
- 主动刷新与被动 401 恢复；
- Logout 与 Force Logout；
- 向 UI 发布稳定的认证状态变化。

业务模块不得直接访问 Secure Storage、Refresh Token 或 Logout 流程。

### 5.4 Auth Interceptor

负责为业务请求注入 Access Token、识别认证错误、调用 RefreshCoordinator、在满足条件时重放原请求，并阻止刷新死循环。

### 5.5 RefreshCoordinator

负责 Single-Flight Refresh。同一客户端进程同一时刻最多只有一个刷新请求；其他请求等待同一个刷新结果。

### 5.6 TokenStore

提供原子化凭证读写接口。生产实现必须使用 iOS Keychain 或 Android Keystore-backed Secure Storage。业务层不得直接依赖具体存储实现。

## 6. 核心数据模型

### 6.1 Access Token

Access Token 用于访问 Business API：

```http
Authorization: Bearer <access_token>
```

若采用 JWT，至少应包含或可解析为：

| Claim | 含义 |
| --- | --- |
| `iss` | 签发者 |
| `sub` | 用户 ID |
| `aud` | 目标 Resource Server |
| `exp` | 过期时间 |
| `iat` | 签发时间 |
| `jti` | Token 唯一 ID |
| `sid` | Session ID |
| `scope` | 最小权限集合 |

默认生命周期为 15 分钟，可由服务端按风险策略配置。Access Token 不得用于刷新自身。

### 6.2 Refresh Token

Refresh Token 只允许发送给认证端点，不得发送给 Business API：

```http
POST /auth/refresh
```

Refresh Token 应使用不可预测的高熵随机值。服务端不得保存可直接使用的明文值，应保存安全摘要及 Token Family 关系。

默认策略：

- 空闲有效期：30 天；
- Session 绝对有效期：90 天；
- 每次成功刷新后执行 Rotation；
- 旧 Refresh Token 立即失效；
- 重放旧 Token 时撤销对应 Token Family 和 Session；
- 生命周期参数由服务端配置，不由客户端决定。

### 6.3 Refresh Token Family

```text
Session S001
  └── Family F001
        ├── RT1  used
        ├── RT2  used
        └── RT3  active
```

每次刷新必须在一个服务端事务中完成：校验当前 Token、标记旧 Token 已使用、签发新 Token、更新 Session 活跃时间。

如果已经使用的 RT1 再次出现，系统应产生 `TOKEN_REUSE_DETECTED` 安全事件，撤销 F001 和 S001，并要求重新登录。

### 6.4 User Session

服务端至少保存：

| 字段 | 说明 |
| --- | --- |
| `session_id` | 会话唯一标识 |
| `user_id` | 用户标识 |
| `refresh_token_family_id` | Refresh Token Family |
| `device_id` | APP 安装级匿名设备标识 |
| `device_name` | 用户可识别的设备名称，需最小化采集 |
| `platform` | iOS / Android |
| `app_version` | 创建或最后使用版本 |
| `created_at` | 创建时间 |
| `last_active_at` | 最近刷新或可信活动时间 |
| `idle_expires_at` | 空闲过期时间 |
| `absolute_expires_at` | 绝对过期时间 |
| `revoked_at` | 撤销时间 |
| `revoked_reason` | 撤销原因 |
| `ip_created_hash` | 可选，按隐私策略脱敏 |
| `ip_last_seen_hash` | 可选，按隐私策略脱敏 |

Session 状态至少包括：`ACTIVE`、`EXPIRED`、`REVOKED`。

## 7. 客户端认证状态机

```text
UNKNOWN
   │
   ▼
INITIALIZING
   │
   ├────────── no credentials ─────────► UNAUTHENTICATED
   │
   └────────── credentials found
                    │
                    ├── valid access token ─────► AUTHENTICATED
                    │
                    └── expired / near expiry
                                  │
                                  ▼
                              REFRESHING
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                 success    auth failure   infra failure
                    │             │             │
                    ▼             ▼             ▼
             AUTHENTICATED  UNAUTHENTICATED  DEGRADED/OFFLINE

AUTHENTICATED ── user logout ──► LOGGING_OUT ──► UNAUTHENTICATED
```

UI 只能依赖 AuthState，不得使用 `token != null` 判断用户已登录。

## 8. 功能需求

### 8.1 登录与身份归一

| ID | Requirement |
| --- | --- |
| AUTH-001 | 手机号、邮箱、Apple、微信等登录方式最终必须归一为同一内部 User、Session、Access Token 和 Refresh Token 模型。 |
| AUTH-002 | Business API 只接受 SpeakEasy Access Token，不接受 Apple、微信或其他上游身份提供商 Token。 |
| AUTH-003 | 服务端必须在创建 Session 前验证上游凭证、账号状态和登录风险。 |
| AUTH-004 | 移动 APP 不得内置可被视为机密的 OAuth client secret。 |
| AUTH-005 | 采用 OAuth/OIDC 浏览器授权时，必须使用 Authorization Code + PKCE、外部浏览器或系统安全浏览器会话，并校验 `state`、`nonce` 和精确 redirect URI。 |
| AUTH-006 | 不得使用嵌入式 WebView 收集第三方 OAuth/OIDC 用户凭证。 |
| AUTH-007 | 第一方手机号、邮箱验证码登录可使用自有认证接口，但成功后必须进入同一 Session/Token 模型。 |
| AUTH-008 | ID Token 只用于认证结果与身份声明校验，不得作为 Business API 的 Access Token。 |

### 8.2 Token 签发与校验

| ID | Requirement |
| --- | --- |
| TOKEN-001 | Access Token 默认生命周期为 15 分钟，并支持服务端配置。 |
| TOKEN-002 | Access Token 必须限制 issuer、audience 和 scope，权限应遵循最小化原则。 |
| TOKEN-003 | JWT Access Token 应使用非对称签名并支持 `kid` 与密钥轮换；若使用 opaque token，则 Resource Server 必须通过受控 introspection 校验。 |
| TOKEN-004 | Resource Server 必须校验签名或 introspection 结果、`exp`、`iss`、`aud`、scope 及必要的 Session 状态。 |
| TOKEN-005 | 客户端不得依赖本地解析结果作为最终授权依据；服务端校验始终是权威。 |
| TOKEN-006 | Refresh Token 必须是高熵随机值，服务端只保存不可逆摘要和必要的 Family 元数据。 |
| TOKEN-007 | Refresh Token 必须绑定 User、Session、Client 与已授权的 scope/resource。 |
| TOKEN-008 | Refresh Token 不得出现在 URL、日志、分析事件、崩溃报告或业务请求中。 |

### 8.3 Refresh Token Rotation

| ID | Requirement |
| --- | --- |
| REFRESH-001 | 每次成功刷新必须同时签发新的 Access Token 和 Refresh Token。 |
| REFRESH-002 | 新 Token 签发后，旧 Refresh Token 必须失效，同时保留 Family 关系用于重放检测。 |
| REFRESH-003 | 服务端必须原子执行旧 Token 消耗、新 Token 创建和 Session 更新时间。 |
| REFRESH-004 | 已使用 Refresh Token 再次出现时，必须撤销整个 Token Family 与对应 Session。 |
| REFRESH-005 | Refresh Token 空闲过期、绝对 Session 过期、账号禁用和安全撤销必须返回稳定错误码。 |
| REFRESH-006 | 刷新端点必须限流，并记录脱敏的成功、失败和重放安全事件。 |
| REFRESH-007 | Refresh 接口不得被 Auth Interceptor 再次触发刷新。 |
| REFRESH-008 | 客户端收到新的 Token Pair 后，必须以原子方式替换旧凭证。 |

### 8.4 客户端请求与自动恢复

| ID | Requirement |
| --- | --- |
| CLIENT-001 | 所有需要认证的请求必须由 Auth Interceptor 注入 Access Token。 |
| CLIENT-002 | Course、Audio、Learning、User、AI 等业务服务不得自行读取 Refresh Token、执行 Refresh 或 Force Logout。 |
| CLIENT-003 | 请求发送前若 Access Token 剩余有效期低于 60 秒，客户端应通过 RefreshCoordinator 主动刷新。 |
| CLIENT-004 | 服务端明确返回 `ACCESS_TOKEN_EXPIRED` 时，客户端应尝试一次 Refresh，并在成功后重试原请求一次。 |
| CLIENT-005 | `ACCESS_TOKEN_INVALID`、`SESSION_REVOKED`、`ACCOUNT_DISABLED` 等错误不得尝试刷新。 |
| CLIENT-006 | 同一原始请求最多因认证问题重试一次，禁止 401/Refresh 无限循环。 |
| CLIENT-007 | 403 不得触发 Refresh；403 由权限或权益层处理。 |
| CLIENT-008 | 重试非幂等请求时必须复用原 Idempotency-Key；认证层 401 必须发生在业务写入前。 |
| CLIENT-009 | 用户取消的请求在等待 Refresh 时不得被无条件重放。 |
| CLIENT-010 | 刷新等待队列必须有数量和时间上限，防止异常期间无限堆积。 |

### 8.5 Single-Flight Refresh

| ID | Requirement |
| --- | --- |
| CONCURRENCY-001 | 同一 APP 进程同一时刻最多执行一个 Refresh 请求。 |
| CONCURRENCY-002 | 其他因 Token 过期而暂停的请求必须等待同一个 Future/Promise 结果。 |
| CONCURRENCY-003 | Refresh 成功后，等待请求使用同一批新凭证继续。 |
| CONCURRENCY-004 | Refresh 认证失败后，等待请求统一失败且只触发一次退登事件。 |
| CONCURRENCY-005 | Refresh 基础设施失败后，等待请求收到可重试的网络/服务错误，不得清空 Session。 |

### 8.6 APP 启动与生命周期恢复

| ID | Requirement |
| --- | --- |
| RESTORE-001 | APP 启动时必须先进入 `INITIALIZING`，完成凭证读取和状态判断后再展示登录态页面。 |
| RESTORE-002 | 本地存在 Token 不等于已认证；必须检查有效期或执行 Refresh。 |
| RESTORE-003 | Access Token 有效时可恢复 `AUTHENTICATED`，但后台仍可异步获取 `/user/me` 验证当前用户状态。 |
| RESTORE-004 | Access Token 过期但 Refresh Token 可用时，必须先刷新再开放需认证业务请求。 |
| RESTORE-005 | APP 从后台恢复到前台时，应检查 Token 是否临近过期，并复用 RefreshCoordinator。 |
| RESTORE-006 | 网络不可用时不得仅因刷新超时清除凭证；UI 应进入可恢复的离线或降级状态。 |

### 8.7 Logout 与会话撤销

| ID | Requirement |
| --- | --- |
| LOGOUT-001 | 主动退出必须调用服务端 Logout，撤销当前 Session 与 Token Family。 |
| LOGOUT-002 | 无论服务端 Logout 是否因网络失败，客户端都必须清除本地凭证、用户敏感缓存和认证内存状态。 |
| LOGOUT-003 | 客户端清除凭证后不得为“稍后撤销”继续保留 Refresh Token 明文。 |
| LOGOUT-004 | `logout-all` 必须撤销用户所有 Session，并使其他设备在下一次请求或刷新时退出。 |
| LOGOUT-005 | 远程撤销指定设备必须只影响目标 Session。 |
| LOGOUT-006 | Logout、Force Logout 与账号注销必须有不同的审计原因和 UI 文案。 |

### 8.8 多设备与安全事件

| ID | Requirement |
| --- | --- |
| SESSION-001 | 每台设备或每次独立安装建立独立 Session。 |
| SESSION-002 | 用户应能查看当前设备及其他活跃 Session 的最小必要信息。 |
| SESSION-003 | 用户应能退出指定设备和退出其他所有设备。 |
| SESSION-004 | 密码重置默认撤销全部 Session；密码修改策略必须明确是否保留当前 Session。 |
| SESSION-005 | 账号禁用必须撤销全部 Session。 |
| SESSION-006 | Refresh Token 重放必须撤销受影响的 Token Family 和 Session。 |
| SESSION-007 | 管理员撤销必须记录操作者、原因、时间和审计引用，不得记录 Token。 |

### 8.9 凭证存储

| ID | Requirement |
| --- | --- |
| STORAGE-001 | Refresh Token 必须存储在 iOS Keychain 或 Android Keystore-backed Secure Storage。 |
| STORAGE-002 | Access Token 主要在内存使用；如需跨启动保存，也必须使用安全存储。 |
| STORAGE-003 | Token Pair 更新必须原子化，避免只保存新 Access Token 而丢失新 Refresh Token。 |
| STORAGE-004 | 普通 SharedPreferences、Hive 明文箱、日志文件和数据库不得保存生产 Refresh Token。 |
| STORAGE-005 | Logout、账号注销和不可恢复认证失败必须清除全部本地凭证。 |
| STORAGE-006 | 备份与设备迁移策略必须防止 Refresh Token 被非预期恢复到另一设备。 |

### 8.10 错误、UX 与降级

| ID | Requirement |
| --- | --- |
| ERROR-001 | 后端必须返回稳定机器错误码、用户安全消息和 `request_id`。 |
| ERROR-002 | 客户端不得通过英文错误字符串或 HTTP reason phrase 判断认证分支。 |
| ERROR-003 | 网络超时、DNS、TLS 和 5xx 不得触发 Force Logout。 |
| ERROR-004 | 只有明确的 Refresh Token/Session 认证失败才能结束登录状态。 |
| ERROR-005 | 自动刷新成功时用户不应看到“登录过期”或业务失败提示。 |
| ERROR-006 | Session 确认失效时，UI 应提示“登录状态已过期，请重新登录”，并保留可安全恢复的导航目标。 |
| ERROR-007 | 403 权限不足、订阅不足与 401 身份失效必须展示不同的恢复路径。 |
| ERROR-008 | TTS 等业务模块不得把 401 映射成“播放失败”；认证恢复失败后应先显示认证级提示。 |

### 8.11 安全、隐私与可观测性

| ID | Requirement |
| --- | --- |
| SECURITY-001 | 所有认证和业务端点必须使用 TLS；生产环境不得允许明文 HTTP。 |
| SECURITY-002 | 客户端不得把 client secret 当作可保密凭证。 |
| SECURITY-003 | Access Token、Refresh Token、验证码、第三方授权码和 Authorization Header 不得写日志。 |
| SECURITY-004 | 日志只允许记录 `request_id`、脱敏 `user_id/session_id`、错误码、结果、延迟和客户端版本。 |
| SECURITY-005 | 认证端点必须具备账号、设备、网络维度的限流和异常检测。 |
| SECURITY-006 | Token 签名密钥必须支持轮换、隔离、最小权限访问和应急撤销。 |
| SECURITY-007 | 设备信息和网络信息必须按隐私最小化原则收集，并有明确保留期。 |
| SECURITY-008 | 证书固定（certificate pinning）属于风险评估后的可选加固，不作为默认强制要求；采用时必须设计密钥轮换和失效恢复。 |
| OBS-001 | 必须记录登录成功率、Refresh 成功率、Refresh 失败分类、401 率、Token 重放事件和 Force Logout 数量。 |
| OBS-002 | 必须能按 APP 版本、平台和 API family 聚合认证错误，但不得保留原始 Token。 |
| OBS-003 | 认证告警必须覆盖 Refresh 失败率突增、401 突增、重放检测和签名校验异常。 |

## 9. 标准流程

### 9.1 登录流程

```text
User chooses login method
        ↓
Validate credential / upstream identity
        ↓
Resolve or create internal User
        ↓
Check account status and risk policy
        ↓
Create device Session and Token Family
        ↓
Issue Access Token + Refresh Token
        ↓
Client atomically stores Token Pair
        ↓
AuthState = AUTHENTICATED
```

### 9.2 401 自动恢复

```text
Business Request
      ↓
401 + ACCESS_TOKEN_EXPIRED
      ↓
Request has not retried before?
      ├── No  → stop and map error
      └── Yes
             ↓
       RefreshCoordinator
             ↓
      Single-Flight Refresh
             ↓
    ┌────────┼─────────┐
    │        │         │
 Success  Auth fail  Infra fail
    │        │         │
Save pair  Clear     Keep credentials
    │      locally       │
Retry once Force logout  Return retryable error
```

### 9.3 并发刷新

```text
/user/me ──401──┐
/courses ──401──┤
/ai/tts  ──401──┤
/progress ─401──┘
                 ↓
          RefreshCoordinator
                 ↓
          one POST /auth/refresh
                 ↓
      resume or fail all waiting requests
```

### 9.4 Refresh 失败分类

| 类别 | 示例 | 客户端处理 |
| --- | --- | --- |
| Success | 新 AT/RT 已返回 | 原子保存并重试原请求一次 |
| Authentication failure | `REFRESH_TOKEN_EXPIRED`、`SESSION_REVOKED`、`TOKEN_REUSE_DETECTED` | 清除凭证并进入登录页 |
| Authorization failure | scope 不允许 | 不刷新，映射为权限错误 |
| Infrastructure failure | timeout、DNS、TLS、502、503 | 保留凭证，展示可重试状态 |
| Invalid response | schema 缺失或签发字段非法 | 保留旧凭证但停止业务重试，上报高优先级错误 |

### 9.5 Logout 流程

```text
User taps Logout
       ↓
Best-effort POST /auth/logout
       ↓
Server revokes Session and Token Family
       ↓
Client clears Token Pair and sensitive cache
       ↓
AuthState = UNAUTHENTICATED
       ↓
Navigate to login screen
```

## 10. 推荐 API

### 10.1 第一阶段

```text
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
POST   /auth/logout-all
GET    /auth/sessions
DELETE /auth/sessions/{session_id}
GET    /user/me
```

### 10.2 登录响应

```json
{
  "access_token": "<opaque-or-jwt>",
  "token_type": "Bearer",
  "expires_in": 900,
  "refresh_token": "<opaque-random-token>",
  "refresh_expires_in": 2592000,
  "session_id": "session_123",
  "scope": "user.read course.read learning.write tts.use"
}
```

### 10.3 Refresh 请求与响应

```json
{
  "refresh_token": "RT1"
}
```

```json
{
  "access_token": "AT2",
  "token_type": "Bearer",
  "expires_in": 900,
  "refresh_token": "RT2",
  "refresh_expires_in": 2592000,
  "session_id": "session_123"
}
```

服务端返回成功响应前必须完成 `RT1 → used` 与 `RT2 → active` 的原子事务。

### 10.4 统一错误响应

```json
{
  "code": "ACCESS_TOKEN_EXPIRED",
  "message": "Access token expired",
  "request_id": "req_123456"
}
```

推荐认证错误码：

| HTTP | Code | Refresh? | 客户端行为 |
| --- | --- | --- | --- |
| 401 | `ACCESS_TOKEN_EXPIRED` | Yes, once | Single-Flight Refresh |
| 401 | `ACCESS_TOKEN_INVALID` | No | 清除本地状态并登录 |
| 401 | `REFRESH_TOKEN_EXPIRED` | No | Force Logout |
| 401 | `REFRESH_TOKEN_INVALID` | No | Force Logout |
| 401 | `SESSION_REVOKED` | No | Force Logout |
| 401 | `TOKEN_REUSE_DETECTED` | No | Force Logout + 安全提示 |
| 401 | `ACCOUNT_DISABLED` | No | Force Logout + 账号状态提示 |
| 403 | `INSUFFICIENT_SCOPE` | No | 权限错误 |
| 403 | `SUBSCRIPTION_REQUIRED` | No | 进入权益恢复路径 |
| 429 | `AUTH_RATE_LIMITED` | No | 按 `Retry-After` 等待 |
| 503 | `AUTH_SERVICE_UNAVAILABLE` | No | 保留凭证并允许重试 |

## 11. 客户端组件建议

```text
lib/core/auth/
  auth_manager.dart
  auth_state.dart
  auth_repository.dart
  token_pair.dart
  token_store.dart
  secure_token_store.dart
  token_provider.dart
  refresh_coordinator.dart
  session_summary.dart
  auth_error.dart

lib/core/network/
  api_client.dart
  auth_interceptor.dart
  api_error.dart
  error_mapper.dart
```

依赖方向：

```text
UI
 ↓
Feature Services
 ↓
ApiClient
 ↓
AuthInterceptor
 ↓
AuthManager / RefreshCoordinator / TokenStore
```

禁止以下依赖：

```text
AudioService → refreshToken()
CourseService → secureStorage
LearningService → forceLogout()
```

## 12. 服务端实现要求

- Authorization Server 必须集中签发和刷新 Token。
- Refresh Token Rotation 必须使用事务或等价的并发安全机制。
- Session 与 Refresh Token Family 必须可撤销且可审计。
- Resource Server 必须共享一致的 Token 校验策略。
- 认证过滤器必须在业务处理前拒绝无效 Token。
- 非幂等 API 应支持 Idempotency-Key，保证认证恢复后安全重放。
- 认证错误码必须跨 API 一致。
- JWT 密钥轮换期间必须同时支持当前和仍在有效期内的上一代公钥。
- 不得在响应、日志或管理端暴露 Token 原文、签名密钥或第三方凭证。

## 13. 验收标准

### 13.1 正常路径

| ID | 场景 | 预期结果 |
| --- | --- | --- |
| AC-001 | 新用户完成任一登录方式 | 创建 User/Session，返回并安全保存 Token Pair |
| AC-002 | Access Token 有效时调用业务 API | 直接返回业务结果，不触发 Refresh |
| AC-003 | Access Token 临近过期 | 请求前刷新一次并使用新 Token |
| AC-004 | Access Token 已过期，Refresh Token 有效 | 自动刷新、原请求重试一次、用户无感 |
| AC-005 | APP 重启且 Session 有效 | 不闪现登录页，正确恢复认证状态 |
| AC-006 | APP 从后台恢复且 Token 过期 | 通过同一 RefreshCoordinator 恢复 |

### 13.2 并发与 Rotation

| ID | 场景 | 预期结果 |
| --- | --- | --- |
| AC-010 | 四个 API 同时收到 Token 过期 | 只调用一次 `/auth/refresh` |
| AC-011 | Refresh 成功 | 所有等待请求使用同一新 Token Pair 恢复 |
| AC-012 | 旧 Refresh Token 被再次使用 | 整个 Family 与 Session 被撤销 |
| AC-013 | Refresh 响应返回时 APP 被中断 | Token Pair 不出现半更新状态 |
| AC-014 | 重试后的请求再次 401 | 不再刷新，停止循环并进入统一认证失败路径 |

### 13.3 失败与离线

| ID | 场景 | 预期结果 |
| --- | --- | --- |
| AC-020 | Refresh 返回 `REFRESH_TOKEN_EXPIRED` | 清除凭证并提示重新登录 |
| AC-021 | Refresh 超时或 DNS 失败 | 保留凭证，不强制退出，允许重试 |
| AC-022 | Business API 返回 403 | 不刷新 Token，交由权限/权益层处理 |
| AC-023 | `/ai/tts` 返回 401 Token 过期 | 先恢复认证，不显示“播放失败” |
| AC-024 | Auth 服务返回 503 | 保留 Session，显示服务暂不可用 |
| AC-025 | Logout 时离线 | 本地立即退出，不保留 Refresh Token |

### 13.4 安全与隐私

| ID | 场景 | 预期结果 |
| --- | --- | --- |
| AC-030 | 检查 APP 日志和崩溃报告 | 不包含 Access/Refresh Token、验证码和第三方授权码 |
| AC-031 | 检查本地普通存储 | 不包含生产 Refresh Token 明文 |
| AC-032 | 检查后端数据库 | 不包含可直接使用的 Refresh Token 明文 |
| AC-033 | 模拟签名密钥轮换 | 已签发且未过期 Token 在策略期内可验证，新 Token 使用新 `kid` |
| AC-034 | 管理员禁用账号 | 所有 Session 被撤销，后续请求不能继续访问 |
| AC-035 | 查看设备会话 | 只展示最小必要设备信息，不暴露 Token 或精确敏感网络数据 |

## 14. 测试策略

### 14.1 客户端单元测试

- AuthState 状态转换；
- Token 剩余有效期计算与时钟偏差；
- Auth Interceptor 注入规则；
- 401 错误码路由；
- Single-Flight Refresh；
- 认证重试最多一次；
- Refresh 端点跳过拦截；
- Token Pair 原子替换；
- 离线刷新不退登；
- Logout 清理顺序。

### 14.2 服务端测试

- Login/Refresh/Logout API contract；
- Refresh Rotation 事务与并发；
- Token Family 重放检测；
- Session idle/absolute expiry；
- scope/audience/issuer 校验；
- 账号禁用、密码重置和管理员撤销；
- 多设备会话隔离；
- Refresh 限流；
- 日志脱敏和审计字段。

### 14.3 端到端测试

- 登录后访问 `/user/me`、课程、学习进度和 `/ai/tts`；
- 测试环境主动缩短 Access Token TTL，验证无感刷新；
- 同时触发多个 API，确认只刷新一次；
- 撤销当前 Session，确认 APP 统一退登；
- 模拟离线、超时、503，确认不会错误退出；
- 远程撤销另一设备，确认当前设备不受影响；
- 旧 Refresh Token 重放，确认安全撤销闭环。

## 15. 可观测性与审计

建议指标：

```text
auth.login.success_rate
auth.login.failure_rate{reason}
auth.refresh.success_rate
auth.refresh.failure_rate{class,reason}
auth.refresh.single_flight_waiters
auth.access_token.401_rate{api_family}
auth.session.force_logout_count{reason}
auth.session.revoke_count{reason}
auth.token_reuse_detected_count
auth.endpoint.latency{endpoint,status}
```

审计事件至少包括：

- Session 创建；
- 当前设备退出；
- 全部设备退出；
- 指定设备撤销；
- 账号禁用或管理员撤销；
- Refresh Token 重放；
- 签名密钥轮换；
- 认证策略变更。

审计记录不得包含原始 Token、Authorization Header、验证码、密码或第三方 provider payload。

## 16. 分阶段落地建议

### Phase 0：当前故障修复

- 保存 Refresh Token，而不是只保存 Access Token；
- 实现 `/auth/refresh` 客户端调用；
- 对 `/user/me`、`/ai/tts` 等 401 先执行认证恢复；
- Refresh 失败时统一清理并返回登录页；
- 将认证错误与 TTS/课程业务错误分离。

### Phase 1：客户端统一认证基础设施

- AuthManager、AuthState、SecureTokenStore；
- Auth Interceptor；
- RefreshCoordinator Single-Flight；
- 主动刷新、一次重试和错误分类；
- 冷启动、热启动、前后台恢复；
- 客户端自动化测试。

### Phase 2：服务端 Session 与 Rotation

- Auth Session、Refresh Token Family 持久化；
- Rotation、重放检测、撤销和多设备会话；
- 稳定认证错误码；
- 事务、并发、限流和审计测试。

### Phase 3：账户安全与运营能力

- 设备会话列表与远程退出；
- Logout all；
- 密码重置/账号禁用联动；
- 安全指标、告警和管理端审计。

### Phase 4：标准化与高级加固

- 对标准 OAuth/OIDC 登录采用 Authorization Code + PKCE；
- Authorization Server Metadata / OIDC Discovery；
- 密钥自动轮换；
- 基于风险评估选择 DPoP、设备证明或证书固定等增强措施。

## 17. 完成定义

本方案达到可上线状态至少需要满足：

- 所有认证接口和错误码有稳定契约；
- 客户端 Single-Flight Refresh 与一次重试通过自动化测试；
- Refresh Token Rotation、重放检测和 Session 撤销通过服务端并发测试；
- APP 启动、后台恢复、离线和 401 路径通过端到端测试；
- 日志、崩溃报告、数据库和管理端没有 Token 泄露；
- `/user/me`、课程、学习进度、TTS 和 AI API 共享同一认证恢复能力；
- 403、订阅不足、网络故障与认证失败不会相互误判；
- 监控能够识别 401/Refresh 异常并定位到 APP 版本和 API family；
- 用户可以退出当前设备，服务端能撤销对应 Session；
- 安全事件能够撤销 Session 并留下脱敏审计证据。

## 18. 参考标准

- [RFC 9700: Best Current Practice for OAuth 2.0 Security](https://www.rfc-editor.org/info/rfc9700/)
- [RFC 8252: OAuth 2.0 for Native Apps](https://www.rfc-editor.org/info/rfc8252/)
- [RFC 7636: Proof Key for Code Exchange by OAuth Public Clients](https://www.rfc-editor.org/info/rfc7636/)
- [OpenID Connect Core and related specifications](https://openid.net/wg/connect/specifications/)
