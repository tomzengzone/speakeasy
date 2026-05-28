# MVP Backend Learning Memory Traceability

## 状态
Validated - learning/memory traceability matrix 已完成代码、测试、报告双向追溯。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 learning/memory traceability rows。 |
| v1.0 | 2026-05-29 | Validated | 更新 learning-memory 后端、数据库、API、测试和 QA evidence，关闭 MVP-BE-GAP-006。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-learning-memory/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-007 | MVP-SI-007 | `mvp-backend-learning-memory` | MVP-BE-FR-007 expression queue/review/favorites | MVP-BE-SPEC-007 | AC-MVP-BE-007 | OpenAPI `/expressions/queue`, `/expressions/tasks/{queue_item_id}/complete`, `/favorites/expressions`, `/review/items`, `/review/items/{review_item_id}/result`; `docs/architecture/api_contract.md`; `docs/domain/domain_schema.md`; `docs/domain/entity_relationship.md` | `backend/src/main/resources/db/migration/V202605290003__learning_memory.sql`; `backend/src/main/java/com/speakeasy/api/LearningMemoryController.java`; `backend/src/main/java/com/speakeasy/learning/*`; migration tests updated in `FoundationMigrationTest` and `PostgresFoundationMigrationTest` | TC-MVP-BE-026 `ExpressionQueueControllerTest`, TC-MVP-BE-027 `ExpressionQueueOrderingTest`, TC-MVP-BE-028 `ExpressionTaskProgressTest`, TC-MVP-BE-029 `FavoriteExpressionControllerTest`; command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` passed; full `mvn test` passed; evidence `docs/reports/test_report.md` | N/A - backend foundation increment, no release artifact changed | Done | MVP-BE-GAP-006 closed |
| MVP-BE-TR-010 | MVP-SI-010 | `mvp-backend-learning-memory` | MVP-BE-FR-010 learning evidence and memory | MVP-BE-SPEC-010 | AC-MVP-BE-010 | OpenAPI `/learning/evidence`, `/learning/mastery`, `/learning/wiki`, `/learning/history`, `/learning/history/{history_entry_id}`; `docs/architecture/api_contract.md`; `docs/domain/domain_schema.md`; `docs/domain/entity_relationship.md` | `backend/src/main/resources/db/migration/V202605290003__learning_memory.sql`; `LearningEvidence`, `MasteryRecord`, `ReviewItem`, `SavedExpression`, `LearningHistoryEntry` entities/repositories; `LearningMemoryService` evidence validation/projection rules; `LearningMemoryController` | TC-MVP-BE-030 `LearningEvidenceValidationTest`, TC-MVP-BE-031 `LearningEvidenceProjectionTest`, TC-MVP-BE-032 `LearningHistoryWikiControllerTest`; command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` passed; `npm run check:api-contract` passed with OpenAPI hash `d677224d822630f0ca30bdcdd55b8c0793b778b7e8e8a65dbfa58f38be15886e`; evidence `docs/reports/test_report.md` | N/A - backend foundation increment, no release artifact changed | Done | MVP-BE-GAP-006 closed |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-006 | 推荐表达、收藏、复习、learning evidence、mastery、history 和 personal wiki 缺服务端持久化闭环。 | MVP-BE-TR-007, MVP-BE-TR-010 | Backend + Domain Schema + QA | Closed 2026-05-29 - 后端持久化/API/测试/报告证据已落地。 |

## Completion Rule
本 increment 的 MVP-BE-TR-007 和 MVP-BE-TR-010 已更新 code/test evidence；TC-MVP-BE-026 到 TC-MVP-BE-032 均有脚本路径、执行命令、pass 结果和 `docs/reports/test_report.md` 证据；MVP-BE-GAP-006 已关闭。本 increment 可进入独立 QA / Product Object Governance Check 结论阶段。
