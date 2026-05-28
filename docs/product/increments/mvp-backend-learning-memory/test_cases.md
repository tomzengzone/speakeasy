# MVP Backend Learning Memory Test Cases

## 状态
Draft - 实现前测试用例库；用于关闭 `mvp-backend-learning-memory` 的 AC-to-TC implementation gate，不代表测试脚本已实现或已通过。

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
| AC-MVP-BE-007 | MVP-BE-TR-007 | TC-MVP-BE-026, TC-MVP-BE-027, TC-MVP-BE-028, TC-MVP-BE-029 | planned |
| AC-MVP-BE-010 | MVP-BE-TR-010 | TC-MVP-BE-030, TC-MVP-BE-031, TC-MVP-BE-032 | planned |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-026 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/ExpressionQueueControllerTest.java` | `mvn.cmd -q "-Dtest=ExpressionQueueControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | User without joined scenario fixture | 用户没有已加入场景时，推荐表达队列返回明确空状态。 |
| TC-MVP-BE-027 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | unit | planned | `backend/src/test/java/com/speakeasy/ExpressionQueueOrderingTest.java` | `mvn.cmd -q "-Dtest=ExpressionQueueOrderingTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Due review, weak expression, variant and duplicate expression fixtures | 队列按到期复习、薄弱表达和表达变体优先级返回，并按稳定表达 ID 去重。 |
| TC-MVP-BE-028 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/ExpressionTaskProgressTest.java` | `mvn.cmd -q "-Dtest=ExpressionTaskProgressTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Completed expression task fixture | 表达任务完成后记录进度、最佳得分、转写、复习时间或 mastery 关联中的至少一种。 |
| TC-MVP-BE-029 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 | AC-MVP-BE-007 | MVP-BE-TR-007 | MVP-BE-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/FavoriteExpressionControllerTest.java` | `mvn.cmd -q "-Dtest=FavoriteExpressionControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Duplicate favorite and delete favorite fixtures | 同一稳定表达 ID 多次收藏不生成重复收藏；取消收藏后列表不再返回该收藏。 |
| TC-MVP-BE-030 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | MVP-BE-GAP-006 | unit | planned | `backend/src/test/java/com/speakeasy/LearningEvidenceValidationTest.java` | `mvn.cmd -q "-Dtest=LearningEvidenceValidationTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Accepted and rejected evidence candidate fixtures | session 或任务完成生成 evidence candidate 后，后端先验证再写入最终学习事实；不满足规则时不得标记为最终 mastery。 |
| TC-MVP-BE-031 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | MVP-BE-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/LearningEvidenceProjectionTest.java` | `mvn.cmd -q "-Dtest=LearningEvidenceProjectionTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Accepted evidence affecting home, queue, wiki, history or profile fixtures | 被接受的 evidence 至少影响首页、推荐表达、personal wiki、history 或个人中心中的一种读模型。 |
| TC-MVP-BE-032 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 | AC-MVP-BE-010 | MVP-BE-TR-010 | MVP-BE-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/LearningHistoryWikiControllerTest.java` | `mvn.cmd -q "-Dtest=LearningHistoryWikiControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | History/wiki read and delete/anonymize fixtures | history 或 personal wiki 返回与已接受 evidence 一致的数据或明确空状态；删除历史后读结果反映删除或匿名化策略。 |

## Handoff Notes
- 本库只建立测试设计和 AC-to-TC 映射；Backend / Domain Schema / QA 仍需在后续执行中实现脚本并更新执行证据。
- TC-MVP-BE-026 到 TC-MVP-BE-032 一经发布不得重排或复用。
