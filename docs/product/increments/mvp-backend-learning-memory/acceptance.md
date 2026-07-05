# MVP Backend Learning Memory Acceptance

## 状态
Draft - learning/memory acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 learning/memory AC。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Coverage Map
| AC | Stage Scope ID | FR | Spec |
| --- | --- | --- | --- |
| AC-MVP-BE-007 | MVP-SI-007 | MVP-BE-FR-007 | MVP-BE-SPEC-007 |
| AC-MVP-BE-010 | MVP-SI-010 | MVP-BE-FR-010 | MVP-BE-SPEC-010 |

## AC-MVP-BE-007 Expression Queue, Review And Favorites
- 给定用户没有已加入场景，后端推荐表达队列必须返回明确空状态。
- 给定用户有到期复习、薄弱表达或表达变体，后端队列必须按优先级和去重规则返回。
- 给定用户完成表达任务，后端必须能记录进度、最佳得分、转写、复习时间或掌握关联中的至少一种。
- 给定用户收藏同一稳定表达 ID 多次，后端不得生成重复收藏。
- 给定用户取消收藏，后端收藏列表不得继续返回该收藏。

## AC-MVP-BE-010 Learning Evidence And Memory
- 给定 session 或任务完成生成 evidence candidate，后端必须验证后才写入最终学习事实。
- 给定 evidence 被接受，至少一种结果必须能影响首页、推荐表达、personal wiki、history 或个人中心。
- 给定 evidence 不满足规则，后端不得把它标记为最终 mastery。
- 给定用户查看 history 或 personal wiki，后端必须返回与已接受 evidence 一致的数据或明确空状态。
- 给定用户删除历史记录，相关读取结果必须反映删除或匿名化策略。

## Traceability
完整追溯见 `docs/product/increments/mvp-backend-learning-memory/traceability.md`。
