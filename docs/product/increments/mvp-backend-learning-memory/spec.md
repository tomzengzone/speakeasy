# MVP Backend Learning Memory Spec

## 状态
Draft - learning/memory executable product spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 learning/memory spec IDs。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-BE-SPEC-007 | MVP-SI-007 | MVP-BE-FR-007 | Flow-MVP-BE-007 expression queue, review and favorites |
| MVP-BE-SPEC-010 | MVP-SI-010 | MVP-BE-FR-010 | Flow-MVP-BE-010 learning evidence and memory |

## Flow-MVP-BE-007 Expression Queue, Review And Favorites
1. Backend reads joined/current scenario and learning state.
2. Backend returns expression queue ordered by review due items, weakness, and variants where data exists.
3. Backend returns explicit empty state when no joined scenario or no queue source exists.
4. Backend records task completion, best score/transcript/progress/review timing where available.
5. Backend creates, lists, and deletes favorites by stable expression ID with dedupe.

## Flow-MVP-BE-010 Learning Evidence And Memory
1. Practice/session completion or expression task completion creates evidence candidate.
2. Backend validates candidate against deterministic rules.
3. Accepted evidence updates mastery, weakness, review timing, personal wiki, history, or summary.
4. Rejected or partial evidence is recorded as non-final candidate or ignored with reason.
5. Read APIs expose learning results to home, expression queue, personal wiki, profile/history, or report boundary.

## Required States
| State domain | States |
| --- | --- |
| Queue | empty-no-scene, empty-no-due-items, ready, in-progress |
| Favorite | not-favorited, favorited |
| Evidence | candidate, accepted, rejected, superseded |
| Mastery | unknown, seen, practiced, weak, mastered-product-base |
| History | no-history, recorded, deleted |

## Non-goals
- 不定义跨天 planner。
- 不定义完整评分产品化。
