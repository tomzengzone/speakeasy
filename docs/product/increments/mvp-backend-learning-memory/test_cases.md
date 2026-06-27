# MVP Backend Learning Memory Test Cases

## 状态
Executed - `mvp-backend-learning-memory` 的 AC-to-TC implementation gate 和 QA evidence 已通过；TC-MVP-BE-026 到 TC-MVP-BE-032 均已自动化并执行通过。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/mvp-backend-learning-memory/definition.md`
- `docs/product/increments/mvp-backend-learning-memory/requirements.md`
- `docs/product/increments/mvp-backend-learning-memory/spec.md`
- `docs/product/increments/mvp-backend-learning-memory/acceptance.md`
- `docs/product/increments/mvp-backend-learning-memory/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-BE-007 | MVP-BE-TR-007 | TC-MVP-BE-026, TC-MVP-BE-027, TC-MVP-BE-028, TC-MVP-BE-029 | passed |
| AC-MVP-BE-010 | MVP-BE-TR-010 | TC-MVP-BE-030, TC-MVP-BE-031, TC-MVP-BE-032 | passed |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-026 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/ExpressionQueueControllerTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | User without joined scenario fixture | 用户没有已加入场景时，推荐表达队列返回明确空状态。 |
| TC-MVP-BE-027 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/ExpressionQueueOrderingTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | Due review, weak expression, variant and duplicate expression fixtures | 队列按到期复习、薄弱表达和表达变体优先级返回，并按稳定表达 ID 去重。 |
| TC-MVP-BE-028 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/ExpressionTaskProgressTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | Completed expression task fixture | 表达任务完成后记录进度、最佳得分、转写、复习时间或 mastery 关联中的至少一种。 |
| TC-MVP-BE-029 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/FavoriteExpressionControllerTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | Duplicate favorite and delete favorite fixtures | 同一稳定表达 ID 多次收藏不生成重复收藏；取消收藏后列表不再返回该收藏。 |
| TC-MVP-BE-030 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/LearningEvidenceValidationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | Accepted and rejected evidence candidate fixtures | session 或任务完成生成 evidence candidate 后，后端先验证再写入最终学习事实；不满足规则时不得标记为最终 mastery。 |
| TC-MVP-BE-031 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/LearningEvidenceProjectionTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | Accepted evidence affecting home, queue, wiki, history or profile fixtures | 被接受的 evidence 至少影响首页、推荐表达、personal wiki、history 或个人中心中的一种读模型。 |
| TC-MVP-BE-032 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | MVP-BE-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/LearningHistoryWikiControllerTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` | passed | `docs/reports/test_report.md` | History/wiki read and delete/anonymize fixtures | history 或 personal wiki 返回与已接受 evidence 一致的数据或明确空状态；删除历史后读结果反映删除或匿名化策略。 |

## Handoff Notes
- 本库已完成 AC-to-TC 映射、脚本实现和 QA 执行证据更新；每个 TC 行均包含脚本路径、实际执行命令、结果状态和证据报告。
- TC-MVP-BE-026 到 TC-MVP-BE-032 一经发布不得重排或复用。
