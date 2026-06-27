# MVP Backend Practice AI Spec

## 状态
Draft - practice/AI executable product spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 practice/AI spec IDs。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-BE-SPEC-006 | MVP-SI-006 | MVP-BE-FR-006 | Flow-MVP-BE-006 provider gateway |
| MVP-BE-SPEC-008 | MVP-SI-008 | MVP-BE-FR-008 | Flow-MVP-BE-008 practice session lifecycle |
| MVP-BE-SPEC-009 | MVP-SI-009 | MVP-BE-FR-009 | Flow-MVP-BE-009 feedback and recoverable failure |

## Flow-MVP-BE-006 Provider Gateway
1. Backend receives audio/text/provider request from authenticated client.
2. Backend validates scenario/session/user entitlement boundary for MVP.
3. Backend calls ASR/TTS/pronunciation/LLM provider through server-side adapters.
4. Backend validates provider response schema and normalizes result.
5. Backend returns typed success, recoverable error, or provider-unavailable result.

## Flow-MVP-BE-008 Practice Session Lifecycle
1. Client starts or resumes practice for scenario and level.
2. Backend returns active session or creates a new one.
3. Client submits user turn with transcript and optional authenticated-user-owned trusted `audio_ref`.
4. If `audio_ref` is present, backend validates Media ownership and validated status through the Media/AI Gateway trusted-ref boundary before persistence, even when transcript is also present.
5. Backend stores only validated turn input, obtains feedback, updates session state, and returns next state.
6. Client fetches session after interruption and receives recoverable active state.
7. Client completes session and receives summary payload or summary input.

## Flow-MVP-BE-009 Feedback And Recoverable Failure
1. Backend associates coach feedback with session and turn.
2. Feedback can include next question, retry suggestion, expression suggestion, score signal, or recoverable error.
3. Message playback/translation failures return typed errors without losing session state.
4. Invalid provider output is rejected or downgraded before it becomes product-visible feedback.

## Required States
| State domain | States |
| --- | --- |
| Practice session | not-started, active, awaiting-feedback, recoverable-error, completed |
| User turn | recording-client-side, submitted, transcribed, feedback-ready, rejected |
| Provider result | success, timeout, unavailable, invalid-schema, quota-blocked |
| Feedback | next-question, retry, expression-suggestion, score-signal, recoverable-error |

## Non-goals
- 不定义 P0.1 training state machine。
- 不定义最终 learning evidence acceptance rules。
