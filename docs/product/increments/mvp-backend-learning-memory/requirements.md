# MVP Backend Learning Memory Requirements

## 状态
Draft - derived from MVP backend stage。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 learning/memory requirement IDs。 |

## Owner
Requirement Development Agent

## Capability Classification
- Primary Capability ID：`CAP-MEMORY`
- Primary Sub-capability ID：`CAP-MEMORY-02`
- Affected Capability IDs：`CAP-PLAN`、`CAP-TRAIN`、`CAP-NOTE`
- Affected Sub-capability IDs：`CAP-MEMORY-01`、`CAP-MEMORY-03`、`CAP-MEMORY-04`、`CAP-MEMORY-05`、`CAP-PLAN-05`、`CAP-TRAIN-04`、`CAP-NOTE-04`、`CAP-NOTE-05`

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-BE-FR-007 | MVP-SI-007 | 后端必须承接推荐表达队列、任务进度、复习状态、收藏和去重规则，并能根据 Product Base 的到期复习、薄弱表达和表达变体提供队列数据或明确缺省状态。 |
| MVP-BE-FR-010 | MVP-SI-010 | 后端必须持久化 session summary、learning evidence、mastery、weakness、history 和 personal wiki 所需数据，并用确定性规则控制最终学习事实写入。 |

## Success Criteria
- SC-MVP-BE-016：已加入场景用户可从后端读取推荐表达队列或明确空状态。
- SC-MVP-BE-017：收藏表达使用稳定 ID 去重，取消收藏后不继续出现在收藏结果中。
- SC-MVP-BE-018：任务完成后进度、复习时间、最佳得分、转写或掌握关联至少一种可持久化。
- SC-MVP-BE-019：session summary 后至少一种学习证据能影响首页、推荐表达、personal wiki 或个人中心。
- SC-MVP-BE-020：LLM 只能提供 candidate，最终 mastery/weakness 写入必须由后端确定性规则确认。

## Non-goals
- 不承诺收藏自动生成复习任务。
- 不承诺完整 L0-L5 掌握阶梯。
- 不承诺跨天自动训练编排。

## Downstream Artifacts
- `docs/product/increments/mvp-backend-learning-memory/spec.md`
- `docs/product/increments/mvp-backend-learning-memory/acceptance.md`
- `docs/product/increments/mvp-backend-learning-memory/traceability.md`
