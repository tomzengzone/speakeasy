# MVP Backend Onboarding Content Spec

## 状态
Draft - onboarding/content executable product spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 onboarding/content spec IDs。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-BE-SPEC-003 | MVP-SI-003 | MVP-BE-FR-003 | Flow-MVP-BE-003 onboarding and learning route |
| MVP-BE-SPEC-004 | MVP-SI-004 | MVP-BE-FR-004 | Flow-MVP-BE-004 official scenario content |
| MVP-BE-SPEC-005 | MVP-SI-005 | MVP-BE-FR-005 | Flow-MVP-BE-005 user scenario state and home summary |

## Flow-MVP-BE-003 Onboarding And Learning Route
1. Authenticated user submits assessment answers.
2. Backend validates required choices and stores assessment.
3. Backend maps English interview to `job_interview`.
4. Backend maps onboarding/work communication to `onboarding_introduction`.
5. Backend refuses to create a real official scene for daily service or unsupported directions.
6. Backend returns learning route and current scenario state.

## Flow-MVP-BE-004 Official Scenario Content
1. Client requests visible official scenarios.
2. Backend returns only published Product Base official scenarios.
3. Client requests scenario detail and level content.
4. Backend returns versioned content, level code, target expressions, dialogue/material references, and traceable content version.
5. Missing, unpublished, or unsupported content returns deterministic errors.

## Flow-MVP-BE-005 User Scenario State And Home Summary
1. User joins, removes, sets current scenario, or changes level.
2. Backend persists user-scene state.
3. Home summary reads current scene, joined scenes, progress placeholders/data, review/weakness/next action placeholders/data.
4. State changes are visible to later practice, expression queue, and summary endpoints.

## Required States
| State domain | States |
| --- | --- |
| Assessment | incomplete, complete, invalid |
| Learning route | no-route, route-created, route-updated |
| Scenario content | draft, published, retired |
| User scene | not-joined, joined, current, removed |
| Home summary | empty, ready, partially-available |

## Non-goals
- 不定义 P0.1 training planner。
- 不定义 CMS 或内容审核后台。
