# Test Cases：商业化订阅上线准备

## 状态
Executed partial - AC-to-TC gate 已通过；2026-06-10 `TC-COM-024` 已关闭 `/admin/audit` 本地后端实现、OPS 鉴权、分页过滤、脱敏和自审计证据；2026-06-10 `TC-COM-025` 已关闭 `/admin/data-deletion/{job_id}/retry` 本地后端实现、状态流转、OPS 鉴权、幂等和审计证据；manual/external/release-blocker 用例保持阻断状态，商业发布不得视为 ready。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/commercial-subscription-readiness/definition.md`
- `docs/product/increments/commercial-subscription-readiness/requirements.md`
- `docs/product/increments/commercial-subscription-readiness/spec.md`
- `docs/product/increments/commercial-subscription-readiness/acceptance.md`
- `docs/product/increments/commercial-subscription-readiness/traceability.md`
- `docs/domain/domain_schema.md`
- `docs/architecture/api_contract.md`
- `docs/architecture/openapi/speakeasy-api.yaml`
- `docs/architecture/security_design.md`
- `docs/ux/screen_spec.md`

## AC-to-TC Coverage Summary
| Acceptance Criteria | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-COM-001 | COM-TR-001, COM-TR-002, COM-TR-003 | TC-COM-001, TC-COM-002, TC-COM-023 | mapped / planned |
| AC-COM-002 | COM-TR-002, COM-TR-003 | TC-COM-003, TC-COM-023 | mapped / planned |
| AC-COM-003 | COM-TR-002, COM-TR-003 | TC-COM-004, TC-COM-023 | mapped / planned |
| AC-COM-004 | COM-TR-002, COM-TR-003 | TC-COM-005, TC-COM-023 | mapped / planned |
| AC-COM-005 | COM-TR-001, COM-TR-002, COM-TR-003 | TC-COM-006, TC-COM-007, TC-COM-023 | mapped / planned |
| AC-COM-006 | COM-TR-001, COM-TR-007 | TC-COM-008, TC-COM-009, TC-COM-023 | mapped / planned |
| AC-COM-007 | COM-TR-008 | TC-COM-010, TC-COM-023 | mapped / planned |
| AC-COM-008 | COM-TR-004 | TC-COM-011 | mapped / planned |
| AC-COM-009 | COM-TR-005 | TC-COM-012 | mapped / planned |
| AC-COM-010 | COM-TR-006 | TC-COM-013, TC-COM-014, TC-COM-023, TC-COM-025 | local deletion retry passed |
| AC-COM-011 | COM-TR-009 | TC-COM-015, TC-COM-016 | mapped / planned |
| AC-COM-012 | COM-TR-007, COM-TR-010 | TC-COM-009, TC-COM-017, TC-COM-018, TC-COM-023 | mapped / planned |
| AC-COM-013 | COM-TR-011 | TC-COM-019, TC-COM-020, TC-COM-024, TC-COM-025 | local admin audit/data deletion retry passed / external provider evidence blocked |
| AC-COM-014 | COM-TR-012 | TC-COM-021, TC-COM-022, TC-COM-023, TC-COM-024 | local admin audit/API contract passed / strict release evidence blocked |

## Requirement-to-Test Coverage
| Requirement | Stage Scope ID | Acceptance Criteria | Test Case IDs | Coverage status |
| --- | --- | --- | --- | --- |
| FR-COM-001 | COM-SI-001 | AC-COM-001, AC-COM-005, AC-COM-006 | TC-COM-001, TC-COM-002, TC-COM-006, TC-COM-008, TC-COM-009, TC-COM-023 | 100% mapped |
| FR-COM-002 | COM-SI-002 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005 | TC-COM-001, TC-COM-003, TC-COM-004, TC-COM-005, TC-COM-006, TC-COM-023 | 100% mapped |
| FR-COM-003 | COM-SI-003 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005 | TC-COM-002, TC-COM-003, TC-COM-004, TC-COM-005, TC-COM-006, TC-COM-023 | 100% mapped |
| FR-COM-004 | COM-SI-004 | AC-COM-008 | TC-COM-011 | 100% mapped |
| FR-COM-005 | COM-SI-005 | AC-COM-009 | TC-COM-012 | 100% mapped |
| FR-COM-006 | COM-SI-007 | AC-COM-006, AC-COM-012 | TC-COM-008, TC-COM-009, TC-COM-017, TC-COM-018, TC-COM-023 | 100% mapped |
| FR-COM-007 | COM-SI-008 | AC-COM-007 | TC-COM-010, TC-COM-023 | 100% mapped |
| FR-COM-008 | COM-SI-006 | AC-COM-010 | TC-COM-013, TC-COM-014, TC-COM-023, TC-COM-025 | 100% mapped |
| FR-COM-009 | COM-SI-009 | AC-COM-011 | TC-COM-015, TC-COM-016 | 100% mapped |
| FR-COM-010 | COM-SI-010 | AC-COM-012 | TC-COM-009, TC-COM-017, TC-COM-018, TC-COM-023 | 100% mapped |
| FR-COM-011 | COM-SI-011 | AC-COM-013 | TC-COM-019, TC-COM-020, TC-COM-024, TC-COM-025 | 100% mapped |
| FR-COM-012 | COM-SI-012 | AC-COM-014 | TC-COM-011, TC-COM-012, TC-COM-021, TC-COM-022, TC-COM-023, TC-COM-024 | 100% mapped |

## 2026-05-29 QA Execution Overlay
The overlay below is the authoritative execution status for completed commercial readiness slices. The detailed TC table keeps the original planned rows for stable AC-to-TC design history unless a later execution update rewrites the individual row.

| TC ID | Current result | Evidence |
| --- | --- | --- |
| TC-COM-001 | passed | `AppleSubscriptionVerificationTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-002 | passed | `GoogleSubscriptionVerificationTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-003 | passed | `SubscriptionCredentialValidationTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-004 | passed | `SubscriptionRestoreTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-005 | passed | `SubscriptionRestoreEmptyTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-006 | passed | `PaymentProviderEventDowngradeTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-007 | passed | `test/features/commercial/entitlement_downgrade_widget_test.dart`, `flutter test`, `docs/reports/test_report.md` |
| TC-COM-008 | passed | `EntitlementGateServiceTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-009 | passed | `UsageQuotaGateTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-010 | passed | `test/features/commercial/scenario_gating_consistency_test.dart`, `flutter test test/features/commercial/scenario_gating_consistency_test.dart`, `docs/reports/test_report.md` |
| TC-COM-011 | passed | `scripts/check_release_configuration.sh` with production fixture env, `docs/reports/test_report.md` |
| TC-COM-012 | env-fixture passed / strict blocked | `scripts/check_social_login_release_config.sh --env-only` passed; strict mode blocks iOS placeholder and missing Apple Sign In entitlement; manual native evidence steps in `tests/commercial/manual_external_evidence_checklist.md` |
| TC-COM-013 | passed | `CommercialAccountDeletionProcessorTest` plus account deletion backend tests, Maven commercial test command |
| TC-COM-014 | passed | `test/features/commercial/account_deletion_cleanup_test.dart`, `flutter test`, `docs/reports/test_report.md` |
| TC-COM-015 | internal copy passed / external pending | In-repo membership/profile/release copy reviewed; store/privacy/support screenshots still require external evidence; manual copy evidence steps in `tests/commercial/manual_external_evidence_checklist.md` |
| TC-COM-016 | passed | `scripts/check_commercial_copy_contract.py`, `python3 scripts/check_commercial_copy_contract.py`, `docs/reports/test_report.md` |
| TC-COM-017 | passed | `UsageReservationLifecycleTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-018 | passed | `CommercialAbuseControlTest`, Maven commercial test command, `docs/reports/test_report.md` |
| TC-COM-019 | evidence gate ready / external pending | `tests/commercial/provider_sandbox_matrix.md`, `tests/commercial/manual_external_evidence_checklist.md`, `scripts/check_provider_sandbox_evidence.py`; Apple sandbox and Google Play internal-track provider evidence not supplied |
| TC-COM-020 | local passed | `integration_test/commercial_boundary_test.dart`, `flutter test integration_test/commercial_boundary_test.dart`, `docs/reports/test_report.md` |
| TC-COM-021 | evidence gate ready / external pending | `tests/commercial/store_submission_matrix.md`, `tests/commercial/manual_external_evidence_checklist.md`, `scripts/check_store_submission_evidence.py`; store metadata, privacy/support URL, subscription terms and reviewer account evidence not supplied |
| TC-COM-022 | env-fixture passed / strict blocked | `scripts/check_release_readiness.sh --env-only` passed; strict mode blocks native iOS social-login config; release evidence steps in `tests/commercial/manual_external_evidence_checklist.md` |
| TC-COM-023 | passed | `npm run check:api-contract` passed outside sandbox after sandbox `uv` panic |
| TC-COM-024 | passed | `AdminAuditControllerTest`, command `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest test`, `docs/reports/test_report.md#2026-06-10-p0-commercial-admin-audit-endpoint-closure` |
| TC-COM-025 | passed | `AdminDataDeletionControllerTest`, `AdminDataDeletionRetryFailureTest`, account deletion/admin audit regressions, `npm run check:api-contract`, `docs/reports/test_report.md#2026-06-10-p0-commercial-admin-data-deletion-retry-closure` |

## 2026-06-02 QA Revalidation Overlay
The overlay below records the blocker retest result. It does not close manual/external/native/release gates.

| Area | Current result | Evidence |
| --- | --- | --- |
| Backend subscription/commercial local tests | passed | `AppleSubscriptionVerificationTest`, `GoogleSubscriptionVerificationTest`, `SubscriptionCredentialValidationTest`, `SubscriptionRestoreTest`, `SubscriptionRestoreEmptyTest`, `EntitlementGateServiceTest`, `UsageQuotaGateTest`, `CommercialAccountDeletionProcessorTest`, `UsageReservationLifecycleTest`, `CommercialAbuseControlTest`, `AiCostDashboardTest` |
| Account deletion idempotency | passed after stale assertion update | `CommercialAccountDeletionProcessorTest` now counts `account_deletion_completed` audit events instead of all audit rows |
| Flutter commercial widget tests | passed | `scenario_gating_consistency_test.dart`, `entitlement_downgrade_widget_test.dart`, `account_deletion_cleanup_test.dart` |
| Commercial boundary integration | passed | `flutter test integration_test/commercial_boundary_test.dart` |
| System E2E commercial paths | passed | `scripts/run_mvp_system_e2e.sh --suite membership-boundary` and `--suite commercial-boundary` |
| API contract | passed | `npm run check:api-contract`; 68 paths, 73 operations, generated Dart drift passed |
| Evidence gates | non-strict passed / strict external blocked | `check_provider_sandbox_evidence.py`, `check_store_submission_evidence.py`, `check_manual_external_evidence_plan.py`, `check_commercial_copy_contract.py` |
| Remaining blockers | open | TC-COM-012 native social-login strict evidence, TC-COM-015 external copy/privacy/support, TC-COM-019 Apple/Google provider evidence, TC-COM-021 store/reviewer/privacy/support evidence, TC-COM-022 strict release evidence |

## 2026-06-03 Strict External Gate Overlay
The overlay below records the latest external gate execution. It supersedes fixture-only wording where it could be misread as release readiness.

| TC ID | Current result | Latest evidence |
| --- | --- | --- |
| TC-COM-012 | strict blocked | `scripts/check_social_login_release_config.sh --env-only` failed because `WECHAT_APP_ID` and `WECHAT_UNIVERSAL_LINK` are missing；full strict also failed because iOS still has the placeholder WeChat URL scheme and lacks Apple Sign In entitlement。 |
| TC-COM-015 | local copy passed / strict external blocked | `python3 scripts/check_commercial_copy_contract.py` passed in non-strict mode；`--strict-external` failed because `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL` and `SUPPORT_URL` are missing。 |
| TC-COM-019 | evidence matrix passed / strict external blocked | `python3 scripts/check_provider_sandbox_evidence.py` passed in non-strict mode；`--strict-external` failed because `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` are missing。 |
| TC-COM-021 | evidence matrix passed / strict external blocked | `python3 scripts/check_store_submission_evidence.py` passed in non-strict mode；`--strict-external` failed because `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL` and `SUPPORT_URL` are missing。 |
| TC-COM-022 | strict release blocked | `scripts/check_release_configuration.sh`, `scripts/check_release_readiness.sh --env-only` and full `scripts/check_release_readiness.sh` failed because production API/env, social/native config, Sentry/signing, provider/store/AI evidence refs, symbol upload, rollback and privacy/support URLs are missing。 |

## Out-of-Scope AI Provider Hardening Tests
- `TC-COM-001` through `TC-COM-025` cover subscription, entitlement, usage gating, admin audit, admin data deletion retry, commercial copy, store/release and payment-provider evidence.
- Production AI provider hardening has separate stable IDs `TC-COM-AI-001` through `TC-COM-AI-007` in `docs/product/increments/commercial-ai-provider-hardening/test_cases.md`.
- Do not mark paid AI voice, production ASR media lifecycle, persistent TTS cache, DashScope live evidence, cost dashboard, or AI data retention as closed from this subscription test suite.

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-COM-001 | COM-SI-001, COM-SI-002 | FR-COM-001, FR-COM-002 | COM-SPEC-001, COM-SPEC-002 | AC-COM-001 | COM-TR-001, COM-TR-002 | COM-GAP-007, COM-GAP-008, COM-GAP-010 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/AppleSubscriptionVerificationTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AppleSubscriptionVerificationTest test` | planned | `docs/reports/test_report.md` | Valid Apple transaction, authenticated user, matching product allowlist | 后端校验 Apple transaction 后写入 Purchase/Subscription/EntitlementSnapshot，客户端刷新为付费权益。 |
| TC-COM-002 | COM-SI-001, COM-SI-003 | FR-COM-001, FR-COM-003 | COM-SPEC-001, COM-SPEC-003 | AC-COM-001 | COM-TR-001, COM-TR-003 | COM-GAP-007, COM-GAP-008, COM-GAP-010 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/GoogleSubscriptionVerificationTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoogleSubscriptionVerificationTest test` | planned | `docs/reports/test_report.md` | Valid Google purchase token, authenticated user, matching product allowlist | 后端校验 Google purchase token 后授予服务端权益，Flutter 刷新后展示订阅生效。 |
| TC-COM-003 | COM-SI-002, COM-SI-003 | FR-COM-002, FR-COM-003 | COM-SPEC-002, COM-SPEC-003 | AC-COM-002 | COM-TR-002, COM-TR-003 | COM-GAP-007, COM-GAP-008, COM-GAP-010 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/SubscriptionCredentialValidationTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=SubscriptionCredentialValidationTest test` | planned | `docs/reports/test_report.md` | Invalid receipt/token, product mismatch, wrong user fixture | 无效凭据、商品不匹配或用户不匹配时返回 typed error，不写权益。 |
| TC-COM-004 | COM-SI-002, COM-SI-003 | FR-COM-002, FR-COM-003 | COM-SPEC-002, COM-SPEC-003 | AC-COM-003 | COM-TR-002, COM-TR-003 | COM-GAP-007, COM-GAP-008, COM-GAP-010 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/SubscriptionRestoreTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=SubscriptionRestoreTest test` | planned | `docs/reports/test_report.md` | Existing active provider subscription fixture | 恢复购买经后端校验后恢复同一用户权益，并返回 restored 状态。 |
| TC-COM-005 | COM-SI-002, COM-SI-003 | FR-COM-002, FR-COM-003 | COM-SPEC-002, COM-SPEC-003 | AC-COM-004 | COM-TR-002, COM-TR-003 | COM-GAP-007, COM-GAP-008, COM-GAP-010 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/SubscriptionRestoreEmptyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=SubscriptionRestoreEmptyTest test` | planned | `docs/reports/test_report.md` | No active provider subscription fixture | 空恢复返回 empty restore，不授予权益，不误报购买成功。 |
| TC-COM-006 | COM-SI-001, COM-SI-002, COM-SI-003 | FR-COM-001, FR-COM-002, FR-COM-003 | COM-SPEC-001, COM-SPEC-002, COM-SPEC-003 | AC-COM-005 | COM-TR-001, COM-TR-002, COM-TR-003 | COM-GAP-007, COM-GAP-008, COM-GAP-010 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/PaymentProviderEventDowngradeTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PaymentProviderEventDowngradeTest test` | planned | `docs/reports/test_report.md` | Refund, expired, revoked, grace-period provider events | provider event 触发 subscription/entitlement 降级；重复或乱序事件幂等。 |
| TC-COM-007 | COM-SI-001, COM-SI-007 | FR-COM-001, FR-COM-006 | COM-SPEC-001, COM-SPEC-007 | AC-COM-005, AC-COM-006 | COM-TR-001, COM-TR-007 | COM-GAP-007, COM-GAP-008 | widget | planned | `test/features/commercial/entitlement_downgrade_widget_test.dart` | `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart` | planned | `docs/reports/test_report.md` | Expired/refunded entitlement snapshot fixture | Flutter 刷新后显示降级、重新订阅或管理订阅入口，不继续开放付费能力。 |
| TC-COM-008 | COM-SI-007 | FR-COM-006 | COM-SPEC-007 | AC-COM-006 | COM-TR-007 | COM-GAP-007, COM-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/EntitlementGateServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=EntitlementGateServiceTest test` | planned | `docs/reports/test_report.md` | Free user, paid user, expired user entitlement fixtures | 免费/过期/无权益用户被阻止，付费有效用户允许进入受限能力。 |
| TC-COM-009 | COM-SI-007, COM-SI-010 | FR-COM-006, FR-COM-010 | COM-SPEC-007, COM-SPEC-010 | AC-COM-006, AC-COM-012 | COM-TR-007, COM-TR-010 | COM-GAP-007, COM-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/UsageQuotaGateTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=UsageQuotaGateTest test` | planned | `docs/reports/test_report.md` | Free quota, paid quota, exhausted quota fixtures | 额度耗尽时阻止或降级高成本调用，并记录可审计事件。 |
| TC-COM-010 | COM-SI-008 | FR-COM-007 | COM-SPEC-008 | AC-COM-007 | COM-TR-008 | COM-GAP-007, COM-GAP-008 | widget | automated | `test/features/commercial/scenario_gating_consistency_test.dart` | `flutter test test/features/commercial/scenario_gating_consistency_test.dart` | passed | `docs/reports/test_report.md` | Free and Pro user paid L3 scenario fixtures | 场景列表、场景详情、训练入口对同一用户返回一致 gating 结果。 |
| TC-COM-011 | COM-SI-004, COM-SI-012 | FR-COM-004, FR-COM-012 | COM-SPEC-004, COM-SPEC-012 | AC-COM-008 | COM-TR-004, COM-TR-012 | COM-GAP-006, COM-GAP-007, COM-GAP-008 | release-check | planned | `scripts/check_release_configuration.sh` | `scripts/check_release_configuration.sh` | planned | `docs/reports/test_report.md` | Release env with test login, missing API, missing products | release 构建在测试登录开启、生产 API 或支付商品缺失时失败。 |
| TC-COM-012 | COM-SI-005, COM-SI-012 | FR-COM-005, FR-COM-012 | COM-SPEC-005, COM-SPEC-012 | AC-COM-009 | COM-TR-005, COM-TR-012 | COM-GAP-006, COM-GAP-007, COM-GAP-008, COM-GAP-010 | release-check | external-dependency | `scripts/check_social_login_release_config.sh`; `tests/commercial/manual_external_evidence_checklist.md` | `scripts/check_social_login_release_config.sh` plus manual native/social-login review | env-fixture passed / strict blocked | `docs/reports/test_report.md`; `tests/commercial/manual_external_evidence_checklist.md` | WeChat/Apple production config, iOS/Android native config, real device login smoke | 商店版本不得保留占位 AppID、URL scheme、universal link 或未启用能力；真实微信/Apple 登录 smoke 通过并记录证据。 |
| TC-COM-013 | COM-SI-006 | FR-COM-008 | COM-SPEC-006 | AC-COM-010 | COM-TR-006 | COM-GAP-007, COM-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/CommercialAccountDeletionProcessorTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialAccountDeletionProcessorTest test` | planned | `docs/reports/test_report.md` | User with profile, practice, learning, purchase and audit fixtures | 后端删除或匿名化云端学习数据，保留最小审计，删除 job 可追踪。 |
| TC-COM-014 | COM-SI-006 | FR-COM-008 | COM-SPEC-006 | AC-COM-010 | COM-TR-006 | COM-GAP-007, COM-GAP-008 | widget | planned | `test/features/commercial/account_deletion_cleanup_test.dart` | `flutter test test/features/commercial/account_deletion_cleanup_test.dart` | planned | `docs/reports/test_report.md` | Completed deletion job and populated local cache fixture | 删除完成后清理本地会话、资料、学习进度、收藏、个人 Wiki、会话和缓存，回到未登录。 |
| TC-COM-015 | COM-SI-009 | FR-COM-009 | COM-SPEC-009 | AC-COM-011 | COM-TR-009 | COM-GAP-006, COM-GAP-008 | manual | manual-verification | `docs/ux/copywriting_guideline.md`; `docs/release/release_checklist.md`; `scripts/check_commercial_copy_contract.py`; `tests/commercial/manual_external_evidence_checklist.md` | `python3 scripts/check_commercial_copy_contract.py` plus manual in-repo/store/privacy review | internal passed / external pending | `docs/reports/test_report.md`; `tests/commercial/manual_external_evidence_checklist.md` | Membership page, profile upsell, store metadata, privacy declaration screenshots, support URL screenshots | 未完成能力不作为已兑现付费承诺；权益名称跨会员页、商店和隐私说明一致；外部商店/隐私截图证据缺失时继续阻断 release。 |
| TC-COM-016 | COM-SI-009 | FR-COM-009 | COM-SPEC-009 | AC-COM-011 | COM-TR-009 | COM-GAP-007, COM-GAP-008 | contract | automated | `scripts/check_commercial_copy_contract.py` | `python3 scripts/check_commercial_copy_contract.py` | passed | `docs/reports/test_report.md` | SubscriptionPlan and EntitlementRule benefit map fixtures | 会员页权益文案能追溯到可售计划和权益规则，缺失项会阻断 release。 |
| TC-COM-017 | COM-SI-010 | FR-COM-010 | COM-SPEC-010 | AC-COM-012 | COM-TR-010 | COM-GAP-007, COM-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/UsageReservationLifecycleTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=UsageReservationLifecycleTest test` | planned | `docs/reports/test_report.md` | Reserve, commit, release, expire, provider timeout fixtures | AI/ASR/TTS/评分调用前 reserve，成功 commit，失败 release/expire，过程可审计。 |
| TC-COM-018 | COM-SI-010 | FR-COM-010 | COM-SPEC-010 | AC-COM-012 | COM-TR-010 | COM-GAP-007, COM-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/commercial/CommercialAbuseControlTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialAbuseControlTest test` | planned | `docs/reports/test_report.md` | Excessive receipt, scripted login and excessive provider call fixtures | 风控限制阻止或降级调用，并写入脱敏审计事件。 |
| TC-COM-019 | COM-SI-011 | FR-COM-011 | COM-SPEC-011 | AC-COM-013 | COM-TR-011 | COM-GAP-008, COM-GAP-010 | manual | external-dependency | `tests/commercial/provider_sandbox_matrix.md`; `tests/commercial/manual_external_evidence_checklist.md`; `scripts/check_provider_sandbox_evidence.py` | `python3 scripts/check_provider_sandbox_evidence.py` plus manual Apple/Google provider execution | evidence gate ready / external pending | `docs/reports/test_report.md`; `tests/commercial/manual_external_evidence_checklist.md` | Apple sandbox and Google Play internal tracks, transaction ids, purchase token hashes, backend/webhook logs | 购买、恢复、退款、过期、宽限期、账号切换在真实 provider sandbox/internal test 中记录结果和独立审查。 |
| TC-COM-020 | COM-SI-011 | FR-COM-011 | COM-SPEC-011 | AC-COM-013 | COM-TR-011 | COM-GAP-007, COM-GAP-008 | e2e | automated | `integration_test/commercial_boundary_test.dart` | `flutter test integration_test/commercial_boundary_test.dart` | passed | `docs/reports/test_report.md` | First install, old storage, weak network/provider error, quota exhausted fixtures | 商业边界测试矩阵覆盖非支付 provider 的端到端边界，并记录结果。 |
| TC-COM-021 | COM-SI-012 | FR-COM-012 | COM-SPEC-012 | AC-COM-014 | COM-TR-012 | COM-GAP-006, COM-GAP-008, COM-GAP-010 | manual | external-dependency | `tests/commercial/store_submission_matrix.md`; `tests/commercial/manual_external_evidence_checklist.md`; `scripts/check_store_submission_evidence.py`; `docs/release/release_checklist.md`; `docs/release/version_log.md` | `python3 scripts/check_store_submission_evidence.py` plus manual store submission review | evidence gate ready / external pending | `docs/reports/test_report.md`; `tests/commercial/manual_external_evidence_checklist.md` | App Store Connect, Play Console, subscription terms, privacy/support URL, reviewer account | 商店元数据、订阅条款、隐私 URL、支持 URL、审核账号和人工审查结果齐备。 |
| TC-COM-022 | COM-SI-012 | FR-COM-012 | COM-SPEC-012 | AC-COM-014 | COM-TR-012 | COM-GAP-006, COM-GAP-008 | release-check | external-dependency | `scripts/check_release_readiness.sh`; `scripts/check_manual_external_evidence_plan.py`; `tests/commercial/manual_external_evidence_checklist.md`; `docs/release/rollback_plan.md` | `python3 scripts/check_manual_external_evidence_plan.py` then `scripts/check_release_readiness.sh` | env-fixture passed / strict blocked | `docs/reports/test_report.md`; `tests/commercial/manual_external_evidence_checklist.md` | Release secrets, signing, dSYM/ProGuard, rollback, provider/store/native evidence refs | release secrets、签名、符号表上传、回滚方案、外部证据和 strict gate 齐备，否则发布阻断。 |
| TC-COM-023 | COM-SI-001, COM-SI-002, COM-SI-003, COM-SI-006, COM-SI-007, COM-SI-008, COM-SI-010, COM-SI-012 | FR-COM-001, FR-COM-002, FR-COM-003, FR-COM-006, FR-COM-007, FR-COM-008, FR-COM-010, FR-COM-012 | COM-SPEC-001, COM-SPEC-002, COM-SPEC-003, COM-SPEC-006, COM-SPEC-007, COM-SPEC-008, COM-SPEC-010, COM-SPEC-012 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005, AC-COM-006, AC-COM-007, AC-COM-010, AC-COM-012, AC-COM-014 | COM-TR-001, COM-TR-002, COM-TR-003, COM-TR-006, COM-TR-007, COM-TR-008, COM-TR-010, COM-TR-012 | COM-GAP-002 | contract | automated | `scripts/check_openapi_contract.py`; `scripts/check_openapi_dart_drift.py`; `docs/architecture/openapi/speakeasy-api.yaml` | `npm run check:api-contract` | passed | `docs/reports/test_report.md` | OpenAPI commercial endpoints, examples, traceability metadata and generated Dart drift manifest | P0 commercial implementation-level API paths have operationId、traceability、schemas、examples、errors and generated client drift gate coverage. |
| TC-COM-024 | COM-SI-011, COM-SI-012 | FR-COM-011, FR-COM-012 | COM-SPEC-011, COM-SPEC-012 | AC-COM-013, AC-COM-014 | COM-TR-011, COM-TR-012 | COM-GAP-007, COM-GAP-008 | integration / contract | automated | `backend/src/test/java/com/speakeasy/AdminAuditControllerTest.java`; `docs/architecture/openapi/speakeasy-api.yaml` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest test`; `npm run check:api-contract`; `npm run check:dart-client-drift` | passed | `docs/reports/test_report.md#2026-06-10-p0-commercial-admin-audit-endpoint-closure` | Seeded `AuditLog` rows with user/system/ops actors, pagination cursor, event/actor/target/time filters, JSON and legacy sensitive redaction fixtures | `/admin/audit` is OPS-only, paginated and filterable; non-OPS access fails; responses omit `actor_id`, sanitize `redacted_details`, do not leak token/receipt/raw audio/full transcript/signed URL, and each audit read writes `admin_audit_events_listed`. |
| TC-COM-025 | COM-SI-006, COM-SI-011 | FR-COM-008, FR-COM-011 | COM-SPEC-006, COM-SPEC-011 | AC-COM-010, AC-COM-013 | COM-TR-006, COM-TR-011 | COM-GAP-007, COM-GAP-008 | integration / contract | automated | `backend/src/test/java/com/speakeasy/AdminDataDeletionControllerTest.java`; `backend/src/test/java/com/speakeasy/AdminDataDeletionRetryFailureTest.java`; `docs/architecture/openapi/speakeasy-api.yaml` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminDataDeletionControllerTest,AdminDataDeletionRetryFailureTest,AccountDeletionControllerTest,AccountDeletionFailureAuditTest,CommercialAccountDeletionProcessorTest,AdminAuditControllerTest test`; `npm run check:api-contract` | passed | `docs/reports/test_report.md#2026-06-10-p0-commercial-admin-data-deletion-retry-closure` | Failed deletion job, completed deletion job, in-progress deletion job, duplicate `Idempotency-Key`, OPS/non-OPS bearer and real `AiRetentionService` failure fixtures | `/admin/data-deletion/{job_id}/retry` is OPS-only, requires `Idempotency-Key`, executes only failed jobs, treats completed jobs as no-op, rejects in-progress jobs with `DELETE_IN_PROGRESS`, replays duplicate retry keys without new retry/audit/AI retention work, records redacted retry audit events, and persists failed retry status with sanitized `failure_reason`. |

## Gate Result
- AC-to-TC mapping: pass. `AC-COM-001` through `AC-COM-014` all map to one or more stable TC IDs.
- Requirement-to-test coverage: pass. `FR-COM-001` through `FR-COM-012` all map through AC IDs to TC IDs.
- Implementation/QA status: partial pass. Implemented automated cases passed, including 2026-06-10 TC-COM-024 admin audit endpoint closure and TC-COM-025 admin data deletion retry closure; 2026-06-03 strict gates confirm TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022 remain external/native/store/release blockers.
- External/manual exceptions: `TC-COM-012`, `TC-COM-015`, `TC-COM-019`, `TC-COM-021`, and `TC-COM-022` are explicit manual/external/native/release gates with detailed execution steps in `tests/commercial/manual_external_evidence_checklist.md`; they block commercial release readiness until executed and independently reviewed.

## Handoff Notes
- TC-COM-001 through TC-COM-025 are stable IDs and must not be renumbered.
- Backend, Frontend, AI Runtime and DevOps may implement the planned scripts in the paths above or update the test case row with a documented replacement path before execution.
- Commercial release readiness still requires executed provider sandbox/internal test evidence, store metadata evidence, native social-login evidence, release secrets/signing/symbol evidence, rollback evidence, filled manual result records, implementation report, test report and quality report.
- Paid AI voice release additionally requires `commercial-ai-provider-hardening` execution evidence for `TC-COM-AI-001` through `TC-COM-AI-007`.
