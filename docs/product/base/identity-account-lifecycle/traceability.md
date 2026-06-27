# Identity & Account Lifecycle Traceability（身份认证与账号生命周期追溯矩阵）

## 状态
Draft（草案） - 当前文件建立两类追溯：已实现代码基线需求的 `Requirement -> Spec Flow -> Code Evidence` 部分追溯，以及真实短信 OTP、真实 Apple / WeChat provider validation、生产凭证门禁和 identity release gate 目标态需求的 pending 追溯。当前已生成的 spec item 均写入具体 `Spec Flow` / `Spec Item`；全部 `AC`、`TC`、测试证据和验收结论仍待后续补齐。

## Owner（负责人）
Document Traceability Check Skill（文档追溯检查技能）

## 上游来源
- Requirements（需求）: `docs/product/base/identity-account-lifecycle/requirements.md`
- 当前代码基线：`backend/src/main/java/com/speakeasy/api/AuthController.java`, `backend/src/main/java/com/speakeasy/identity/`, `backend/src/main/java/com/speakeasy/security/`, `backend/src/main/java/com/speakeasy/ops/`, `backend/src/main/resources/db/migration/`

## 追溯范围
- 本轮把 Product Base identity-account-lifecycle 需求分为已实现代码基线需求、目标态 OTP 待实现需求、目标态 provider validation 待实现需求、生产凭证门禁待实现需求和 release gate target boundary。
- 已实现代码基线需求必须追溯到代码证据；已生成并复审的 spec item 必须写入 `Spec Flow`。当前已生成 spec item 的 `Spec Flow` / `Spec Item` 已回填具体 spec ID；未来新增需求在 spec 生成前才可把对应 `Spec Flow` 暂记为 `TBD - 后续补齐`，全部 `AC`、`TC` 在生成前标记为 `TBD - 后续补齐`。
- 目标态 OTP 待实现需求只进入 pending 追溯区，`Code Evidence` 必须显式标记为 `Not implemented - target requirement`，不得被计为 code evidence traced。
- 目标态 Apple / WeChat provider validation、生产凭证门禁和 release gate target boundary 只进入 pending 追溯区，`Code Evidence` 必须显式标记为 `Not implemented - target requirement`、`Not implemented - target boundary` 或 `Not implemented - release target boundary`，不得被计为 code evidence traced。
- 代码证据只证明当前代码存在对应行为，不等同于验收通过或测试覆盖完成。
- pending 追溯只证明目标需求已被纳入需求链路，不等同于代码实现、验收通过或测试覆盖完成。

## 已实现代码基线追溯矩阵（Requirement -> Spec Flow -> Code Evidence）
| Requirement | Spec Flow | AC | TC | Code Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| IDENTITY-ACCOUNT-001 | IDENTITY-SPEC-ACCOUNT-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:47-55` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-002 | IDENTITY-SPEC-ACCOUNT-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:127-131`; `backend/src/main/java/com/speakeasy/identity/AuthIdentityRepository.java:7-8` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-003 | IDENTITY-SPEC-ACCOUNT-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:127-131`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:151-155` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-004 | IDENTITY-SPEC-ACCOUNT-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/UserAccount.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-005 | IDENTITY-SPEC-ACCOUNT-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/UserAccount.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-006 | IDENTITY-SPEC-ACCOUNT-006 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/UserAccount.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-007 | IDENTITY-SPEC-ACCOUNT-007 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:151-154`; `backend/src/main/java/com/speakeasy/identity/AuthIdentity.java:34-41` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-008 | IDENTITY-SPEC-ACCOUNT-008 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:151-155`; `backend/src/main/java/com/speakeasy/identity/UserProfile.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-009 | IDENTITY-SPEC-ACCOUNT-009 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/resources/db/migration/V202605260001__pb_p0_foundation.sql:12-20` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-010 | IDENTITY-SPEC-ACCOUNT-010 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/UserProfile.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-ACCOUNT-011 | IDENTITY-SPEC-ACCOUNT-011 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/UserProfile.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-OTP-001 | IDENTITY-SPEC-OTP-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:99-103`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:51-53` | Code evidence traced; AC/TC pending |
| IDENTITY-OTP-002 | IDENTITY-SPEC-OTP-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:99-103`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:51-53` | Code evidence traced; AC/TC pending |
| IDENTITY-OTP-003 | IDENTITY-SPEC-OTP-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:51-53` | Code evidence traced; AC/TC pending |
| IDENTITY-PROVIDER-001 | IDENTITY-SPEC-PROVIDER-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:45-48`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:58-66` | Code evidence traced; AC/TC pending |
| IDENTITY-PROVIDER-002 | IDENTITY-SPEC-PROVIDER-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:50-53`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:58-66` | Code evidence traced; AC/TC pending |
| IDENTITY-PROVIDER-003 | IDENTITY-SPEC-PROVIDER-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:105-109`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:62-64` | Code evidence traced; AC/TC pending |
| IDENTITY-PROVIDER-004 | IDENTITY-SPEC-PROVIDER-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:58-66`; `backend/src/main/java/com/speakeasy/security/TokenHasher.java:11-15` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-001 | IDENTITY-SPEC-LOGIN-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:99-103`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:47-50` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-002 | IDENTITY-SPEC-LOGIN-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:105-109`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:58-61` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-003 | IDENTITY-SPEC-LOGIN-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/security/SecurityConfig.java:30-32` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-004 | IDENTITY-SPEC-LOGIN-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:127-135` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-005 | IDENTITY-SPEC-LOGIN-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:137-146`; `backend/src/main/java/com/speakeasy/identity/AuthSession.java:43-59` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-006 | IDENTITY-SPEC-LOGIN-006 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:122-130`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:172-173` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGIN-007 | IDENTITY-SPEC-LOGIN-007 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:99-111` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-001 | IDENTITY-SPEC-TOKEN-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:162-170` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-002 | IDENTITY-SPEC-TOKEN-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:7-9`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:162-170` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-003 | IDENTITY-SPEC-TOKEN-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:137-146`; `backend/src/main/java/com/speakeasy/security/TokenHasher.java:11-15`; `backend/src/main/resources/db/migration/V202605270001__auth_sessions.sql:1-13` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-004 | IDENTITY-SPEC-TOKEN-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:20-21`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:137-145` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-005 | IDENTITY-SPEC-TOKEN-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:20-21`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:137-145` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-006 | IDENTITY-SPEC-TOKEN-006 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:40-47` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-007 | IDENTITY-SPEC-TOKEN-007 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:96-106`; `backend/src/main/java/com/speakeasy/identity/AuthSession.java:77-79` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-008 | IDENTITY-SPEC-TOKEN-008 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:101-106` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-009 | IDENTITY-SPEC-TOKEN-009 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:68-80`; `backend/src/main/java/com/speakeasy/identity/AuthSession.java:81-83` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-010 | IDENTITY-SPEC-TOKEN-010 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:82-86`; `backend/src/main/java/com/speakeasy/identity/AuthSession.java:85-91` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-011 | IDENTITY-SPEC-TOKEN-011 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:68-80`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:82-86` | Code evidence traced; AC/TC pending |
| IDENTITY-TOKEN-012 | IDENTITY-SPEC-TOKEN-012 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/security/SecurityConfig.java:28-30` | Code evidence traced; AC/TC pending |
| IDENTITY-ME-001 | IDENTITY-SPEC-ME-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:66-69`; `backend/src/main/java/com/speakeasy/security/SecurityConfig.java:37-40` | Code evidence traced; AC/TC pending |
| IDENTITY-ME-002 | IDENTITY-SPEC-ME-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:134-170`; `backend/src/main/java/com/speakeasy/identity/IdentityService.java:104-123` | Code evidence traced; AC/TC pending |
| IDENTITY-ME-003 | IDENTITY-SPEC-ME-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:134-170`; `backend/src/main/java/com/speakeasy/identity/IdentityService.java:104-123` | Code evidence traced; AC/TC pending |
| IDENTITY-ME-004 | IDENTITY-SPEC-ME-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:96-106`; `backend/src/main/java/com/speakeasy/identity/IdentityService.java:71-75` | Code evidence traced; AC/TC pending |
| IDENTITY-ME-005 | IDENTITY-SPEC-ME-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:71-81`; `backend/src/main/java/com/speakeasy/identity/IdentityService.java:50-59`; `backend/src/main/java/com/speakeasy/identity/UserProfile.java:81-95` | Code evidence traced; AC/TC pending |
| IDENTITY-ME-006 | IDENTITY-SPEC-ME-006 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/IdentityService.java:16-22`; `backend/src/main/java/com/speakeasy/identity/IdentityService.java:77-94` | Code evidence traced; AC/TC pending |
| IDENTITY-LINK-001 | IDENTITY-SPEC-LINK-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:151-154` | Code evidence traced; AC/TC pending |
| IDENTITY-LINK-002 | IDENTITY-SPEC-LINK-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthIdentity.java:34-41` | Code evidence traced; AC/TC pending |
| IDENTITY-LINK-003 | IDENTITY-SPEC-LINK-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthIdentityRepository.java:7-8`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:127-131` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGOUT-001 | IDENTITY-SPEC-LOGOUT-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:60-64`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:89-94` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGOUT-002 | IDENTITY-SPEC-LOGOUT-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:89-93` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGOUT-003 | IDENTITY-SPEC-LOGOUT-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthSession.java:93-96` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGOUT-004 | IDENTITY-SPEC-LOGOUT-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthSession.java:93-96`; `backend/src/main/resources/db/migration/V202605270001__auth_sessions.sql:1-10` | Code evidence traced; AC/TC pending |
| IDENTITY-LOGOUT-005 | IDENTITY-SPEC-LOGOUT-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthSession.java:77-79`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:96-106` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-001 | IDENTITY-SPEC-DELETE-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:84-92`; `backend/src/main/java/com/speakeasy/security/SecurityConfig.java:37-40` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-002 | IDENTITY-SPEC-DELETE-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:206-209` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-003 | IDENTITY-SPEC-DELETE-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:57-63`; `backend/src/main/resources/db/migration/V202605290004__commercial_foundation_hardening.sql:1-5` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-004 | IDENTITY-SPEC-DELETE-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:64-69` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-005 | IDENTITY-SPEC-DELETE-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:115-122`; `backend/src/main/java/com/speakeasy/identity/AuthService.java:121-125` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-006 | IDENTITY-SPEC-DELETE-006 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:123-127`; `backend/src/main/java/com/speakeasy/ops/AccountDeletionRetentionRunner.java:18-20`; `backend/src/main/java/com/speakeasy/ai/AiRetentionService.java:84-99`; `backend/src/main/java/com/speakeasy/ai/AiRetentionService.java:134-140`; `backend/src/main/java/com/speakeasy/ai/AiRetentionService.java:175-223` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-007 | IDENTITY-SPEC-DELETE-007 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:131-139`; `backend/src/main/java/com/speakeasy/identity/UserAccount.java:93-99` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-008 | IDENTITY-SPEC-DELETE-008 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/UserAccount.java:93-99` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-009 | IDENTITY-SPEC-DELETE-009 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AuthController.java:94-97`; `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:72-76` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-010 | IDENTITY-SPEC-DELETE-010 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AdminDataDeletionController.java:17-24`; `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:78-107` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-011 | IDENTITY-SPEC-DELETE-011 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:85-95` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-012 | IDENTITY-SPEC-DELETE-012 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/identity/AuthService.java:109-119`; `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:79-84` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-013 | IDENTITY-SPEC-DELETE-013 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:198` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-014 | IDENTITY-SPEC-DELETE-014 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:199` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-015 | IDENTITY-SPEC-DELETE-015 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:187-189` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-016 | IDENTITY-SPEC-DELETE-016 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:184-186` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-017 | IDENTITY-SPEC-DELETE-017 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:177-182` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-018 | IDENTITY-SPEC-DELETE-018 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:190-197` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-019 | IDENTITY-SPEC-DELETE-019 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:171-176`; `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:183` | Code evidence traced; AC/TC pending |
| IDENTITY-DELETE-020 | IDENTITY-SPEC-DELETE-020 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:154-170` | Code evidence traced; AC/TC pending |
| IDENTITY-RISK-001 | IDENTITY-SPEC-RISK-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:59-62`; `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:86-92` | Code evidence traced; AC/TC pending |
| IDENTITY-RISK-002 | IDENTITY-SPEC-RISK-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:49-55`; `backend/src/main/java/com/speakeasy/security/SecurityConfig.java:37-38` | Code evidence traced; AC/TC pending |
| IDENTITY-RISK-003 | IDENTITY-SPEC-RISK-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:28-35`; `backend/src/main/java/com/speakeasy/security/BearerTokenAuthenticationFilter.java:71-73`; `backend/src/main/java/com/speakeasy/security/TokenHasher.java:11-15` | Code evidence traced; AC/TC pending |
| IDENTITY-AUDIT-001 | IDENTITY-SPEC-AUDIT-001 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AuditLog.java:50-67`; `backend/src/main/java/com/speakeasy/ops/AuditRedaction.java:118-128` | Code evidence traced; AC/TC pending |
| IDENTITY-AUDIT-002 | IDENTITY-SPEC-AUDIT-002 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AuditRedaction.java:13-29`; `backend/src/main/java/com/speakeasy/ops/AuditRedaction.java:93-116` | Code evidence traced; AC/TC pending |
| IDENTITY-AUDIT-003 | IDENTITY-SPEC-AUDIT-003 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:263-280` | Code evidence traced; AC/TC pending |
| IDENTITY-AUDIT-004 | IDENTITY-SPEC-AUDIT-004 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:284-303` | Code evidence traced; AC/TC pending |
| IDENTITY-AUDIT-005 | IDENTITY-SPEC-AUDIT-005 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:97-107`; `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java:243-260` | Code evidence traced; AC/TC pending |
| IDENTITY-AUDIT-006 | IDENTITY-SPEC-AUDIT-006 | TBD - 后续补齐 | TBD - 后续补齐 | `backend/src/main/java/com/speakeasy/api/AdminAuditController.java:21-39`; `backend/src/main/java/com/speakeasy/ops/AuditLogService.java:37-52`; `backend/src/main/java/com/speakeasy/ops/AuditLogService.java:96-107` | Code evidence traced; AC/TC pending |

## 目标态 OTP 待实现追溯矩阵（Requirement -> Pending Implementation）
| Requirement | Spec Flow | AC | TC | Code Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| IDENTITY-OTP-004 | IDENTITY-SPEC-OTP-004 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-005 | IDENTITY-SPEC-OTP-005 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-006 | IDENTITY-SPEC-OTP-006 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-007 | IDENTITY-SPEC-OTP-007 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-032 | IDENTITY-SPEC-OTP-032 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-008 | IDENTITY-SPEC-OTP-008 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-009 | IDENTITY-SPEC-OTP-009 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-010 | IDENTITY-SPEC-OTP-010 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-011 | IDENTITY-SPEC-OTP-011 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-012 | IDENTITY-SPEC-OTP-012 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-013 | IDENTITY-SPEC-OTP-013 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-014 | IDENTITY-SPEC-OTP-014 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-015 | IDENTITY-SPEC-OTP-015 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-016 | IDENTITY-SPEC-OTP-016 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-017 | IDENTITY-SPEC-OTP-017 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-018 | IDENTITY-SPEC-OTP-018 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-033 | IDENTITY-SPEC-OTP-033 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-019 | IDENTITY-SPEC-OTP-019 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-020 | IDENTITY-SPEC-OTP-020 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-021 | IDENTITY-SPEC-OTP-021 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-022 | IDENTITY-SPEC-OTP-022 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-023 | IDENTITY-SPEC-OTP-023 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target requirement pending AC/TC/code |
| IDENTITY-OTP-025 | IDENTITY-SPEC-OTP-025 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-026 | IDENTITY-SPEC-OTP-026 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-027 | IDENTITY-SPEC-OTP-027 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-034 | IDENTITY-SPEC-OTP-034 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-028 | IDENTITY-SPEC-OTP-028 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-035 | IDENTITY-SPEC-OTP-035 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-036 | IDENTITY-SPEC-OTP-036 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-029 | IDENTITY-SPEC-OTP-029 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-030 | IDENTITY-SPEC-OTP-030 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-037 | IDENTITY-SPEC-OTP-037 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target boundary pending AC/TC/code |
| IDENTITY-OTP-024 | IDENTITY-SPEC-OTP-024 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - release target boundary | Release target boundary pending AC/TC/code |

## 目标态 Apple / WeChat provider validation 待实现追溯矩阵（Requirement -> Pending Implementation）
| Requirement | Spec Flow | AC | TC | Code Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| IDENTITY-PROVIDER-005 | IDENTITY-SPEC-PROVIDER-005 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-006 | IDENTITY-SPEC-PROVIDER-006 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-007 | IDENTITY-SPEC-PROVIDER-007 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-008 | IDENTITY-SPEC-PROVIDER-008 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-009 | IDENTITY-SPEC-PROVIDER-009 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-010 | IDENTITY-SPEC-PROVIDER-010 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-011 | IDENTITY-SPEC-PROVIDER-011 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-012 | IDENTITY-SPEC-PROVIDER-012 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-013 | IDENTITY-SPEC-PROVIDER-013 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target boundary | Target provider subject boundary pending AC/TC/code |
| IDENTITY-PROVIDER-014 | IDENTITY-SPEC-PROVIDER-014 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |
| IDENTITY-PROVIDER-015 | IDENTITY-SPEC-PROVIDER-015 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target provider validation pending AC/TC/code |

## 目标态生产凭证门禁与 release gate 待实现追溯矩阵（Requirement -> Pending Implementation）
| Requirement | Spec Flow | AC | TC | Code Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| IDENTITY-LOGIN-008 | IDENTITY-SPEC-LOGIN-008 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - target requirement | Target login credential gate pending AC/TC/code |
| IDENTITY-RELEASE-001 | IDENTITY-SPEC-RELEASE-001 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - release target boundary | Release target boundary pending AC/TC/code |
| IDENTITY-RELEASE-002 | IDENTITY-SPEC-RELEASE-002 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - release target boundary | Release target boundary pending AC/TC/code |
| IDENTITY-RELEASE-003 | IDENTITY-SPEC-RELEASE-003 | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - release target boundary | Release target boundary pending AC/TC/code |

## OTP QA / 可测试性输入（不作为 Requirement 追溯行）
| Testability input | Spec Flow | AC | TC | Code Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| OTP-TESTABILITY-001 | N/A - not Product Base requirement/spec item | TBD - 后续补齐 | TBD - 后续补齐 | Not implemented - testability input | QA/testability pending; not counted as requirement or code evidence |

## 当前未纳入矩阵的边界
- `IDENTITY-RELEASE-001..003` 已作为 release target pending 追溯行记录；当前仍没有已实现 identity 专属 release gate code evidence。
- 真实短信 OTP 目标态需求已进入 pending 追溯区，但尚未归档为已实现需求。
- `OTP-TESTABILITY-001` 只作为 QA/testability 输入单独记录，不计为 Product Base requirement 或 code evidence。
- Apple/WeChat 真实服务端校验和生产凭证门禁已作为 target pending 追溯行记录；登录限流、身份绑定/解绑接口、登录/refresh/logout/profile 更新审计事件仍未归档为已实现需求。
- 首评提交后的 onboarding status 推进与首页摘要下一步动作已从 Identity 模块删除；后续若需要承接，应由 access-onboarding / Home Summary / Learning Entry 的独立文档链路定义，不在本 Identity 追溯矩阵中作为 `IDENTITY-*` 行维护。

## 后续补齐规则
后续生成 `acceptance.md` 和测试用例后，必须把本矩阵中的 `AC`、`TC` 和测试证据占位替换为具体追溯项；已写入的 `Spec Flow` / `Spec Item` 必须保持与 `spec.md` 的具体 spec ID 一致。目标态 OTP、Apple / WeChat provider validation、生产凭证门禁和 release gate 需求完成代码实现后，必须把 `Not implemented - target requirement`、`Not implemented - target boundary` 或 `Not implemented - release target boundary` 替换为具体代码证据；替换前不得声明该目标需求达到代码覆盖或完整 Product Base 追溯。
