# MVP Backend Membership Boundary Spec

## 状态
Draft - membership/boundary executable product spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 membership/boundary spec IDs。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-BE-SPEC-011 | MVP-SI-011 | MVP-BE-FR-011 | Flow-MVP-BE-011 account deletion and data processing |
| MVP-BE-SPEC-012 | MVP-SI-012 | MVP-BE-FR-012 | Flow-MVP-BE-012 MVP membership and report boundary |

## Flow-MVP-BE-011 Account Deletion And Data Processing
1. Authenticated user requests account deletion.
2. Backend validates identity/session and creates deletion job or executes synchronous deletion.
3. Backend deletes or anonymizes profile, session, learning route, practice, learning evidence, favorites/history and related audit-safe records according to policy.
4. Backend invalidates active sessions.
5. Backend records audit evidence without retaining unnecessary personal learning data.
6. Client can receive deletion status or final success/failure.

## Flow-MVP-BE-012 MVP Membership And Report Boundary
1. Client requests membership/report/placeholder boundary state.
2. Backend returns current MVP-safe status: entry available, platform-limited, placeholder, or commercial-not-ready.
3. Android subscription is represented as not connected until P0 commercial readiness completes.
4. Offline content, achievements and full report are represented as placeholder/empty unless implemented by later increments.
5. Commercial subscription readiness remains the owning increment for real payment and entitlement facts.

## Required States
| State domain | States |
| --- | --- |
| Deletion job | requested, processing, completed, failed |
| User data | active, deletion-pending, deleted, anonymized |
| Membership boundary | entry-only, platform-limited, commercial-not-ready, active-from-commercial |
| Placeholder | empty, not-implemented, future-scope |

## Non-goals
- 不定义 Apple/Google provider 校验。
- 不定义 P0 commercial entitlement state machine。
