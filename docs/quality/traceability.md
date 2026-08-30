# Canonical Traceability

## 文档状态

- Artifact ID: `TRACEABILITY`
- Status: candidate
- Projection: `derived-read-only`

本文是从 owning sources 重建的 canonical 完整链路投影，不拥有任何直接边。若投影与源不一致，必须先修复 `STORY_MAP`、`FUNCTIONAL_REQUIREMENT_CATALOG`、适用 Engineering Contract 或 `TEST_CASE_CATALOG`，再重新生成本文；不得在这里覆盖关系。

## 派生分支

| Story | Vertical Slice | Functional Requirement | FR-TC | FR-TC selector |
| --- | --- | --- | --- | --- |
| `US-TRAIN-001` | `VS-TRAIN-001-1` | `FR-TRAIN-001` | `TC-FR-TRAIN-001` | `training_recap_panel` |
| `US-CONTENT-001` | `VS-CONTENT-001-1` | `FR-CONTENT-001` | `TC-FR-CONTENT-001` | `content_theme_catalog -> selected_theme_course_summaries` |
| `US-CONTENT-002` | `VS-CONTENT-002-1` | `FR-CONTENT-002` | `TC-FR-CONTENT-002` | `course_card -> course_detail_header` |
| `US-ACC-009` | `VS-ACC-009-1` | `FR-ACC-001` | `TC-FR-ACC-001` | `PhoneAccountRecoveryTest / existing-identity-purpose-bound-one-time-code` |
| `US-ACC-009` | `VS-ACC-009-1` | `FR-ACC-002` | `TC-FR-ACC-002` | `PhoneAccountRecoveryTest / recoveryPreservesTheAccountRevokesEverySessionAndIssuesNoSession` |
| `US-ACC-009` | `VS-ACC-009-1` | `FR-ACC-003` | `TC-FR-ACC-003` | `PhoneAccountRecoveryTest / privacy-safe-failure-and-transaction-rollback` |

| Functional Requirement | Affected Engineering Contract | Contract-TC | Contract-TC selector |
| --- | --- | --- | --- |
| `FR-TRAIN-001` | — 本次治理切换无 Engineering Contract 事实变化 | — | — |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `DOMAIN_SCHEMA`; `ENTITY_RELATIONSHIP`; `DOMAIN_MODEL` (`training_model.md`, `content_model.md`); `OPENAPI` (`LevelCode`; Course catalog 与 version-pinned detail paths/schemas machine boundary) | — 通过下列 `API_CONTRACT` 分支派生覆盖 | — |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-001` | `CONTENT-CEFR-API-001 -> CefrLevelContractTest` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-002` | `CONTENT-CEFR-API-001 -> V202608050001__strict_cefr_level_cutover.sql` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-003` | `CONTENT-CEFR-API-001 -> scene phases/tracks/levelMap/nodes/references` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-004` | `CONTENT-CEFR-API-001 -> LevelCode enum and OpenAPI hash` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-005` | `CONTENT-CEFR-API-001 -> GoalMasteryLevel and hint ladder` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-006` | `CONTENT-CEFR-API-001 -> storage migration v2` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-001` | `CONTENT-COURSE-CATALOG-API-001/scenario-all` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-002` | `CONTENT-COURSE-CATALOG-API-001/course-list` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-005` | `CONTENT-COURSE-CATALOG-API-001/binding-integrity` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-006` | `CONTENT-COURSE-CATALOG-API-001/schema-and-errors` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-007` | `CONTENT-COURSE-CATALOG-API-001/privacy-visibility` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-008` | `CONTENT-COURSE-CATALOG-API-001/private-etag` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-009` | `CONTENT-COURSE-CATALOG-API-001/generated-drift` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-010` | `CONTENT-COURSE-CATALOG-API-001/compatibility-rollback` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-003` | `CONTENT-COURSE-CATALOG-API-001/course-detail` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-004` | `CONTENT-COURSE-CATALOG-API-001/exact-version` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-005` | `CONTENT-COURSE-CATALOG-API-001/binding-integrity` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-006` | `CONTENT-COURSE-CATALOG-API-001/schema-and-errors` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-007` | `CONTENT-COURSE-CATALOG-API-001/privacy-visibility` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-008` | `CONTENT-COURSE-CATALOG-API-001/private-etag` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-009` | `CONTENT-COURSE-CATALOG-API-001/generated-drift` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-010` | `CONTENT-COURSE-CATALOG-API-001/compatibility-rollback` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-001` | `AUTH-ACCOUNT-RECOVERY-API-001/request-code-privacy` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-002` | `AUTH-ACCOUNT-RECOVERY-API-001/purpose-bound-at-most-once` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-003` | `AUTH-ACCOUNT-RECOVERY-API-001/atomic-all-session-revocation` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-004` | `AUTH-ACCOUNT-RECOVERY-API-001/rollback-zero-side-effects` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-005` | `AUTH-ACCOUNT-RECOVERY-API-001/privacy-errors-rate-limit-observability` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-006` | `AUTH-ACCOUNT-RECOVERY-API-001/generated-drift-and-result-unknown` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-007` | `AUTH-ACCOUNT-RECOVERY-API-001/additive-compatibility-rollback` |
| `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `API_CONTRACT` (`AUTH-ACCOUNT-RECOVERY-API-001`) | `TC-CONTRACT-AUTH-RECOVERY-008` | `AUTH-ACCOUNT-RECOVERY-API-001/capability-fail-closed` |

| Vertical Slice | VS-TC | VS-TC selector |
| --- | --- | --- |
| `VS-TRAIN-001-1` | `TC-VS-TRAIN-001-1` | `training_session_view -> training_recap_panel` |
| `VS-CONTENT-001-1` | `TC-VS-CONTENT-001-1` | `content_asset_entry -> theme_card -> course_summary_list` |
| `VS-CONTENT-002-1` | `TC-VS-CONTENT-002-1` | `course_summary_card -> course_detail_header` |
| `VS-ACC-009-1` | `TC-VS-ACC-009-1` | `account_recovery_phone_input -> account_recovery_code_request_accepted -> account_recovery_submit -> account_recovery_success | account_recovery_retry_after_unknown | account_recovery_retry_local_cleanup` |

## 账号恢复 UX coverage 投影

下表只投影 canonical UX Artifact 对已批准恢复分支的细化及其用户可见测试覆盖，不为 UX Artifact 或 VS-TC 创建新的直接边。

| UX Artifact | Canonical scope | Derived product scope | User-visible coverage |
| --- | --- | --- | --- |
| `SCREEN_SPEC` | `Phone Login Recovery Entry`; `Phone Account Recovery` | `VS-ACC-009-1`; `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `TC-VS-ACC-009-1` |
| `USER_FLOW` | `手机号账号恢复跨屏流程`; `恢复成功、本机清理与重新登录`; `恢复失败、限流与取消流程`; `恢复结果未知流程` | `VS-ACC-009-1`; `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `TC-VS-ACC-009-1` |
| `USABILITY_CHECKLIST` | `Phone Account Recovery` | `VS-ACC-009-1`; `FR-ACC-001`, `FR-ACC-002`, `FR-ACC-003` | `TC-VS-ACC-009-1` |

## 账号恢复测试执行路由投影

下表从 `TEST_CASE_CATALOG` 投影测试类型、层级、selector 与执行命令，只提供稳定的执行定位，不记录任何运行结果。

| Test Case | Type / layer | Selector | Command |
| --- | --- | --- | --- |
| `TC-FR-ACC-001` | `FR-TC` / `backend-integration` | `PhoneAccountRecoveryTest / existing-identity-purpose-bound-one-time-code` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test` |
| `TC-FR-ACC-002` | `FR-TC` / `backend-integration` | `PhoneAccountRecoveryTest / recoveryPreservesTheAccountRevokesEverySessionAndIssuesNoSession` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test` |
| `TC-FR-ACC-003` | `FR-TC` / `backend-integration` | `PhoneAccountRecoveryTest / privacy-safe-failure-and-transaction-rollback` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test` |
| `TC-CONTRACT-AUTH-RECOVERY-001` | `Contract-TC` / `api-contract` | `AUTH-ACCOUNT-RECOVERY-API-001/request-code-privacy -> PhoneAccountRecoveryTest` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test` |
| `TC-CONTRACT-AUTH-RECOVERY-002` | `Contract-TC` / `provider-contract-integration` | `AUTH-ACCOUNT-RECOVERY-API-001/purpose-bound-at-most-once -> PhoneAccountRecoveryTest, PhoneAccountRecoveryProviderFailureTest` | `mvn -f backend/pom.xml "-Dtest=PhoneAccountRecoveryTest,PhoneAccountRecoveryProviderFailureTest" test` |
| `TC-CONTRACT-AUTH-RECOVERY-003` | `Contract-TC` / `postgres-integration` | `AUTH-ACCOUNT-RECOVERY-API-001/atomic-all-session-revocation` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryPostgresTest test` |
| `TC-CONTRACT-AUTH-RECOVERY-004` | `Contract-TC` / `fault-injection-integration` | `AUTH-ACCOUNT-RECOVERY-API-001/rollback-zero-side-effects` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryPostgresTest test` |
| `TC-CONTRACT-AUTH-RECOVERY-005` | `Contract-TC` / `security-integration` | `AUTH-ACCOUNT-RECOVERY-API-001/privacy-errors-rate-limit-observability -> PhoneAccountRecoveryTest, PhoneAccountRecoveryProviderFailureTest, PhoneAccountRecoveryRateLimitHttpTest` | `mvn -f backend/pom.xml "-Dtest=PhoneAccountRecoveryTest,PhoneAccountRecoveryProviderFailureTest,PhoneAccountRecoveryRateLimitHttpTest" test` |
| `TC-CONTRACT-AUTH-RECOVERY-006` | `Contract-TC` / `contract-and-widget-integration` | `AUTH-ACCOUNT-RECOVERY-API-001/generated-drift-and-result-unknown` | `flutter test test/services/api_client_contract_test.dart test/pages/phone_account_recovery_page_test.dart` |
| `TC-CONTRACT-AUTH-RECOVERY-007` | `Contract-TC` / `compatibility-regression` | `AUTH-ACCOUNT-RECOVERY-API-001/additive-compatibility-rollback -> PhoneAccountRecoveryTest` | `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test` |
| `TC-CONTRACT-AUTH-RECOVERY-008` | `Contract-TC` / `configuration-and-api-integration` | `AUTH-ACCOUNT-RECOVERY-API-001/capability-fail-closed` | `mvn -f backend/pom.xml -Dtest=AccountRecoveryCapabilityDisabledTest,AccountRecoveryCapabilityInvalidConfigTest,PhoneAccountRecoveryTest test` |
| `TC-VS-ACC-009-1` | `VS-TC` / `widget-integration` | `account_recovery_phone_input -> account_recovery_code_request_accepted -> account_recovery_submit -> account_recovery_back | account_recovery_success | account_recovery_retry_after_unknown | account_recovery_retry_local_cleanup` | `flutter test test/pages/phone_account_recovery_page_test.dart` |

## Coverage join

`TC-VS-TRAIN-001-1`、`TC-VS-CONTENT-001-1`、`TC-VS-CONTENT-002-1` 与 `TC-VS-ACC-009-1` 分别通过当前存在的 VS-to-FR 分支派生覆盖各自 FR；VS-TC 自身不保存 FR ID 集合。`CONTENT-CEFR-API-001` 的六条 Contract-TC 形成严格 CEFR API、服务端持久化迁移、内容资产、OpenAPI/client drift、mastery/hint namespace 与 Flutter 本地数据清理的派生 contract coverage。`CONTENT-COURSE-CATALOG-API-001` 的 `TC-CONTRACT-CONTENT-COURSE-001`、`002` 覆盖 `FR-CONTENT-001` 的主题全集与课程摘要集合，`TC-CONTRACT-CONTENT-COURSE-003`、`004` 覆盖 `FR-CONTENT-002` 的课程详情与精确版本解析，`TC-CONTRACT-CONTENT-COURSE-005` 至 `010` 共同覆盖两条 FR 的 binding 完整性、成功/错误 schema、隐私可见性、私有 ETag、generated drift 与兼容回滚边界。`AUTH-ACCOUNT-RECOVERY-API-001` 的 `TC-CONTRACT-AUTH-RECOVERY-001` 至 `008` 共同覆盖恢复码隐私安全、purpose 隔离与重放、原账号保留和全会话撤销、失败回滚、限流与脱敏观测、generated path/schema/error/hash 与 typed wrapper 一致性、明确失败/result-unknown 不自动进入 login-or-create、additive 上线回滚，以及 backend capability 缺失、关闭、非法或非显式 `true` 时默认关闭并 fail-closed；客户端 feature flag 不能替代 backend capability。`SCREEN_SPEC`、`USER_FLOW` 与 `USABILITY_CHECKLIST` 的账号恢复范围通过 `TC-VS-ACC-009-1` 加入用户可见 coverage：只有明确 `200 recovered` 且本机清理完成才显示成功态登录动作；明确失败不会自动登录，但允许用户主动返回并在返回前清空 recovery code，只保留手机号；result-unknown 锁定返回并要求新 recovery code，本机清理失败也锁定返回且只重试本机清理。该 join 不把 VS-TC 改写为任一 UX Artifact 的 direct Contract-TC。当前 projection 无悬空引用，已登记 FR 的直接 VS lineage 与 FR-TC coverage、approved VS 的 VS-TC coverage、以及存在 direct Contract-TC 的受影响 Engineering Contract coverage 均完整。没有 FR 时不生成 FR、FR-TC 或对应 coverage join。执行证据只可链接绑定 exact commit SHA 的外部测试或 CI 记录，不在本文复制易过期结果状态。
