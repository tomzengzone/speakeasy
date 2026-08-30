# API Contract / API 契约

本文只保留 [测试用例目录](../quality/test_cases.md) 中 Contract-TC 直接引用的 API 决策。机器可校验的路径、schema、示例和错误定义以 [OpenAPI](openapi/speakeasy-api.yaml) 为准。

## 保留范围

| Decision ID | Scope | Product inputs |
| --- | --- | --- |
| `CONTENT-CEFR-API-001` | API、持久化、Flutter 资产和 generated client 的 CEFR 值域 | `VS-CONTENT-001-1`, `VS-CONTENT-002-1`, `FR-CONTENT-001`, `FR-CONTENT-002` |
| `CONTENT-COURSE-CATALOG-API-001` | 已发布可见主题、课程摘要和精确课程版本详情 | `VS-CONTENT-001-1`, `VS-CONTENT-002-1`, `FR-CONTENT-001`, `FR-CONTENT-002` |
| `AUTH-ACCOUNT-RECOVERY-API-001` | 通过已绑定手机号恢复既有账号 | `US-ACC-009`, `VS-ACC-009-1`, `FR-ACC-001..003` |

## 通用规则

- 所有响应使用 JSON；错误使用 OpenAPI 登记的 typed `ErrorResponse`。
- 认证资源必须按当前用户限定，不能通过错误差异泄漏资源或账号存在性。
- OpenAPI、generated Dart path/error registry、SHA-256 marker 和 drift manifest 必须来自同一候选版本。
- Flutter wrapper 只构造请求和解析机器契约已有字段，不得另建 path、DTO 或错误语义。
- 依赖、查询或完整性故障不得伪装为空集合、`404` 或成功。

## CONTENT-CEFR-API-001

- API-facing CEFR 值只允许 `A1`, `A2`, `B1`, `B2`, `C1`, `C2`。L1/L2/L3、旧英文别名和未知值必须在 validation 边界拒绝，不能转换或 fallback。
- 合法但没有内容的等级返回定义的空集合或资源不存在；不得替换成相邻等级。
- 一次性持久化迁移将 L1→A2、L2→B1、L3→B2，并保留稳定 ID、内容版本和会话状态；迁移后建立六值约束且不得残留双写值。
- 当前 bundled 内容可以只提供 A2/B1/B2，但引用必须完整；mastery L0–L5 和 hint L1–L4 是独立命名空间，不受 CEFR 迁移影响。
- 本地存储升级必须原子清理受旧等级或旧 node ID 影响的数据；失败时不得提前推进 migration version。

## CONTENT-COURSE-CATALOG-API-001

### 主题与课程集合

- `GET /scenarios` 在省略可选过滤参数时返回全部已发布且对学习者可见的主题，并按 `scenario_id` 升序；零可见课程的主题仍保留。
- 可选过滤只能缩小同一已认证、已发布且可见的集合，不能改变后续无过滤请求的全集语义。
- `GET /scenarios/{scenario_id}/courses` 返回该主题下全部 current、published、visible 的课程摘要，按 `Course.sort_order` 升序；真实零课程返回 `200` 和空集合。
- 目录响应中的必备字段、成功 envelope、请求 ID、错误和缓存头必须与 OpenAPI 一致。查询、依赖或完整性故障返回 typed retryable `503`，不能返回部分集合。

### 精确课程详情

- `GET /courses/{course_id}/versions/{course_version_id}` 只解析请求中的 exact current published visible 版本，绝不回退到 latest、同课程其他版本、其他课程或相邻 CEFR。
- 详情中的 course/version/binding、英文标题、中文简介和 CEFR 必须与摘要一致，并额外返回大于零的典型完成时长、非空单位和可空背景资源引用。
- 每个 CourseVersion 必须恰好绑定一个同主题且同 CEFR 的可用内容版本；binding 缺失、重复、跨主题、跨等级或不可用时，整个投影以 typed retryable `503` 失败。
- 缺失、未发布、不可见或 course/version 身份不匹配统一返回 privacy-safe `404 RESOURCE_NOT_FOUND`，不能暴露资源或 entitlement 存在性。
- learner-private 响应的 ETag 必须由完整投影和用户可见性共同决定；`304` 不得携带 body，跨账号或可见性变化不得复用旧 validator。
- 这些路径和字段是 additive；安全回滚可以关闭客户端入口，但不得破坏既有场景 API 或删除已提交的兼容 schema。

## AUTH-ACCOUNT-RECOVERY-API-001

### 路径与结果

- `POST /auth/account-recovery/phone/verification-codes` 申请 recovery-purpose 验证码。对已绑定、未绑定、不存在和不可用手机号返回相同的 privacy-safe `202 accepted` 外形。
- `POST /auth/account-recovery/phone` 只使用有效、未过期、未消费且 purpose 为 `account_recovery` 的验证码解析唯一既有账号；不得调用 login-or-create。
- 成功响应精确表达 `schema_version: 1`, `status: recovered`, `next_action: login_phone`，不得包含 user、session、token 或 revoked-count，也不得创建新 Session 或签发 Access/Refresh Token。

### 原子性与安全

- 成功恢复保留同一账号、profile、学习数据和订阅权益快照，推进 security epoch，并在一个事务中撤销全部既有 Session、Refresh Token family/token 和旧 Access Token。
- 账号不存在、手机号未绑定/不可用、验证码或 provider 失败、事务中断和审计写入失败必须保持账号、身份、epoch、会话、token 和审计快照不变。
- recovery code 与普通手机号登录 code 双向隔离；已消费 code 不能重放，失败后只能申请新的 recovery code 重试。
- 验证失败统一为 `401 ACCOUNT_RECOVERY_VERIFICATION_FAILED`；格式错误为 `400 SCHEMA_VALIDATION_FAILED`；限流为 `429 AUTH_RATE_LIMITED` 并带有效 `Retry-After`；临时依赖失败为 retryable `503 AUTH_SERVICE_UNAVAILABLE`。
- 所有 recovery 响应必须携带 `Cache-Control: no-store` 和 `X-Request-Id`。响应、日志和 metrics 不得包含 raw phone、验证码、token、user/session/device ID 或高基数原始标签。
- backend capability 只有显式配置 `true` 才启用；缺失、`false`、非法或其他 truthy 值均在 provider、identity、session 和 audit 副作用前 fail closed。
- 该 API 是 additive。关闭客户端入口不得改变既有 phone verification/login method、path、schema、purpose 或成功/错误语义。

## 可执行校验

- `npm run lint:openapi`
- `npm run check:openapi-contract`
- `npm run check:dart-client-drift`
- [测试用例目录](../quality/test_cases.md) 中所有 `source_contract_id: API_CONTRACT` 的命令
