# Scenario Practice Runtime Migration SWC Allocation

## Status
Accepted - 2026-06-12 独立 Software Architecture Governance Check 已通过，架构设计可作为后续实现输入；本文是 architecture-only，不批准业务代码变更。

## Scope
- Increment ID: `scenario-practice-runtime-migration`
- Active stage: `docs/product/stages/p0-1-expression-automation.md`
- Covered Stage Scope IDs: P01-SI-001、P01-SI-005、P01-SI-007、P01-SI-008、P01-SI-009、P01-SI-011 仅作为 refactor evidence；不声明新增 stage-scope completion。
- Primary feature: `voice-scenario-practice`
- Affected features: `official-scenario-library`, `listening-shadowing`, `expression-practice-queue`, `learning-memory-review`, `scoring-feedback`
- Explicit non-goals: 本增量不修改业务代码；不修改 backend/OpenAPI/DB/provider；不新增 official scenario；共享 runtime 抽取前不新增第三套 scenario-practice implementation package。
- Change mode: `behavior-preserving-refactor`

## Existing Implementation Baseline
| Baseline item | Existing evidence required before new design |
| --- | --- |
| Existing user flow | Current main official scenario practice opens the interview/onboarding practice route, loads reviewed scene/domain context, records or accepts text input, optionally uses ASR/TTS/coach/feedback, updates local wiki/progress/review surfaces, and renders recoverable UI states. |
| Existing code paths | `lib/features/interview/`, `lib/application/scene/`, `lib/features/scenario/`, `lib/services/audio_service.dart`, `lib/services/voice_chat_service.dart`, `lib/services/voice_turn_orchestrator.dart`, `lib/services/api_client.dart`, `lib/services/app_session.dart`, `lib/application/session/session_stats_coordinator.dart`, `lib/services/stats_service.dart`, `lib/models/learning_stats_model.dart`. |
| Existing SWCs | `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE`, `FE-TRAINING`, `BE-CONTENT-SCENARIO`, `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING`, `DB-TRAINING-LEARNING`, `DB-AI-MEDIA-OPS`, `AI-PROMPT-SCHEMA`. |
| Existing global Flow IDs | `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`, with inherited boundaries from `SWC-FLOW-USAGE-AI`, `SWC-FLOW-MEDIA-AUDIO-UPLOAD`, and `SWC-FLOW-OBSERVABILITY`. |
| Existing API/OpenAPI calls | Existing OpenAPI operations listed in API Contract Decision For This Frontend-Only Migration; legacy non-OpenAPI `/user/stats*` paths are existing compatibility paths only and must stay behind stats/history adapters. |
| Existing domain/data ownership | `FE-SCENARIO-PRACTICE` owns scenario-practice domain UI/orchestration and local transition cache; `FE-PRACTICE-RUNTIME` owns reusable mechanics only; backend SWCs own server facts; Flutter must not own final entitlement, final mastery, trusted media refs, provider secrets, or provider-readable URLs. |
| Existing tests/evidence | `test/features/interview/`, existing `test/application/scene_*`, `test/application/session_stats_coordinator_test.dart`, future runtime tests listed by MIG-TC-001..011. |
| Behavior that must not regress | Current main scenario practice route, scene graph/domain context, text/voice turn flow, ASR/TTS fallback behavior, coach/review/wiki/progress rendering, legacy sandbox maintenance behavior, stats/history adapter behavior, and no-backend-contract-drift decision. |
| Known legacy/deprecated parts | `FE-SCENARIO-INTERVIEW` is a deprecated alias; `FE-LEGACY-SCENARIO-SANDBOX` remains legacy-compatible; `/user/stats*` paths are legacy non-OpenAPI and not promoted by this increment. Migration owner: System Architect + Frontend. Expiry: once `FE-PRACTICE-RUNTIME` exists with tests and duplicated page-local runtime loops are removed. |

## Delta From Existing Baseline
| Delta item | Decision |
| --- | --- |
| Reused SWCs | Must reuse `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE`, and existing backend owner SWCs when remote calls apply. |
| Reused Flow IDs | Reuse `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`; inherit `SWC-FLOW-USAGE-AI`, `SWC-FLOW-MEDIA-AUDIO-UPLOAD`, and `SWC-FLOW-OBSERVABILITY` only as boundaries. |
| Changed behavior | Architecture allocation only: classify current main-flow vs legacy sandbox, define target runtime extraction boundaries, and define future implementation slices. |
| Unchanged behavior | No product behavior, backend behavior, API schema, DB schema, provider routing, entitlement, media ref ownership, or learning/mastery ownership changes in this increment. |
| New code allowed | Future implementation may create `lib/application/practice_runtime/` and tests under `test/application/practice_runtime/` only after this allocation passes independent check; no code is created by this architecture-only increment. |
| New code forbidden | No third scenario-practice runtime, no duplicate voice/message/TTS/session loops, no duplicate auth/audit/media/AI provider/entitlement/usage/training/goal/learning store, no direct provider calls, no Flutter-generated trusted `media://audio/...` refs, no stable-contract claim over `/user/stats*`. |
| Existing code modified | Future implementation may modify `lib/features/interview/`, `lib/application/scene/`, `lib/features/scenario/`, `lib/services/audio_service.dart`, `lib/services/voice_chat_service.dart`, `lib/services/voice_turn_orchestrator.dart`, `lib/services/api_client.dart`, `lib/services/app_session.dart`, `lib/application/session/session_stats_coordinator.dart`, `lib/services/stats_service.dart`, and `lib/models/learning_stats_model.dart` only within the target SWC boundaries above. |
| Migration/deprecation impact | `legacy-compatible` migration for `FE-LEGACY-SCENARIO-SANDBOX` and deprecated `FE-SCENARIO-INTERVIEW` alias. Owner: System Architect + Frontend. Expiry: runtime extraction completion with regression tests and no page-local duplicated runtime loops. |
| Regression proof required | MIG-TC-001..011, interview/scenario/runtime/session-stats tests, OpenAPI drift check proving no contract change, and independent Software Architecture Governance Check pass before coding. |

## Baseline References
| Reference type | Required value |
| --- | --- |
| Global SWC architecture baseline | `docs/architecture/software_component_architecture.md` |
| Referenced global Flow IDs | `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`, `SWC-FLOW-USAGE-AI`, `SWC-FLOW-MEDIA-AUDIO-UPLOAD`, `SWC-FLOW-TRAINING-TURN` only as boundary-not-to-own reference, `SWC-FLOW-OBSERVABILITY` |
| Referenced SWC Catalog IDs | `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE`, `FE-TRAINING`, `BE-API-CONTROLLERS`, `BE-PRACTICE`, `BE-CONTENT-SCENARIO`, `BE-AI-GATEWAY`, `BE-MEDIA-STORAGE`, `BE-LEARNING`, `DB-TRAINING-LEARNING`, `DB-AI-MEDIA-OPS`, `AI-PROMPT-SCHEMA` |
| Inherited data flow rules | `docs/architecture/data_flow.md#product-base-practice-turn-flow`, `docs/architecture/data_flow.md#p0-commercial-ai-provider-hardening-flow`, `docs/architecture/data_flow.md#ai-provider-fallback-flow` |
| Inherited module boundary rules | `docs/architecture/module_boundary.md#frontend-module-boundary`, `docs/architecture/module_boundary.md#data-ownership`, `docs/architecture/module_boundary.md#ai-runtime-boundary` |
| Local flow classification | Uses global `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`; `legacy-compatible` for `FE-LEGACY-SCENARIO-SANDBOX` flows |
| Local flow migration owner and expiry | Owner: System Architect + Frontend. Expiry: once `FE-PRACTICE-RUNTIME` exists with tests and `FE-SCENARIO-PRACTICE` no longer depends on page-local duplicated runtime loops. |

## API 契约决策（Frontend-Only Migration）
- 稳定 OpenAPI operation 可以被引用，但不得在本迁移中修改：`listScenarios`, `getScenario`, `getScenarioLevel`, `startPracticeSession`, `getPracticeSession`, `submitPracticeTurn`, `completePracticeSession`, `createAudioUpload`, `completeAudioUpload`, `transcribeAudio`, `synthesizeSpeech`, `coachTurn`, `generateFeedback`, `scorePronunciation`, `listLearningEvidence`, `createLearningEvidence`, `listMastery`, `listPersonalWiki`, `listLearningHistory`, `getMvpLearningReportSummary`, `listReviewItems`, `submitReviewResult`。
- 当前 stats/practice-history client call 是 **legacy non-OpenAPI path**：`GET /user/stats`、`POST /user/stats/session`、`POST /user/stats/session/feedback`、`POST /user/stats/session-group/delete`。`FE-PRACTICE-RUNTIME` 只能通过基于 `AppSession` / `SessionStatsCoordinator` / `StatsService` 的 `PracticeHistoryRecorder` adapter 访问它们；不得把它们视为稳定 cross-end contract。
- 如果要把 practice history 稳定为 server-owned product contract，必须单独创建 API Contract / OpenAPI / backend / DB traceability increment；本迁移不批准该变化。

## System Responsibility Allocation
| Layer | Responsibilities in this increment | Non-responsibilities | Facts owned here |
| --- | --- | --- | --- |
| Frontend | Define SWC split; preserve current practice UX; extract reusable runtime in a later implementation; render recoverable states; keep local display/session cache. | Final entitlement, final mastery, trusted media refs, provider secrets, backend facts, Training source of truth. | Client-cache-only facts only. |
| Backend | Existing API/domain/provider facts remain referenced but unchanged. | No new endpoints, DTOs, migrations, provider logic, or persistence changes in this migration. | Server-owned facts remain in owning backend SWCs. |
| Database | No migration. | No schema/table/index change. | Tables/migrations owned by backend SWCs only. |
| Provider / AI runtime | Existing candidate output and fallback boundaries remain referenced. | No direct Flutter provider call, no provider credential exposure, no AI final mastery ownership. | Candidate outputs only; accepted persistent facts stay backend/domain-owned after deterministic rules accept them. |
| Ops / release | Architecture gate, traceability check, duplicate-boundary review, later test evidence. | Product scope approval or commercial release approval. | Gates, audit, rollback, observability evidence. |

## Requirement Allocation Matrix
| Stage Scope ID | FR | Spec | AC | FE SWC | BE SWC | API/OpenAPI | Domain Entity | DB Table/Migration | Provider/AI Boundary | TC | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P01-SI-001 | MIG-FR-001 Current main-flow classification | `spec.md#architecture-decision` | MIG-AC-002 | `FE-SCENARIO-PRACTICE` | N/A - frontend classification only, no backend change | N/A | Scenario, ScenarioLevel, InterviewSceneGraph as frontend-reviewed asset/domain model reference | N/A | N/A | MIG-TC-001 | `lib/features/interview/` remains physical path during migration. |
| P01-SI-001 | MIG-FR-002 Legacy sandbox classification | `spec.md#architecture-decision` | MIG-AC-003 | `FE-LEGACY-SCENARIO-SANDBOX` | N/A - frontend legacy classification only, no backend change | N/A | Legacy `SceneDraft`/`SceneChatMessage` are not canonical Domain Schema | N/A | N/A | MIG-TC-002 | No new feature expansion under `lib/features/scenario/`. |
| P01-SI-007, P01-SI-011 | MIG-FR-003 Shared runtime extraction | `spec.md#target-swcs` | MIG-AC-004, MIG-AC-009 | `FE-PRACTICE-RUNTIME`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE` | `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING` only when current OpenAPI calls are used | OpenAPI: `startPracticeSession`, `getPracticeSession`, `submitPracticeTurn`, `completePracticeSession`, `createAudioUpload`, `completeAudioUpload`, `transcribeAudio`, `synthesizeSpeech`, `coachTurn`, `generateFeedback`, `scorePronunciation`, `listLearningEvidence`, `createLearningEvidence`; no contract drift | `PracticeSession`, `DialogueTurn`, `MediaAsset`, `LearningEvidence`, `LearningEvidenceCandidate`, `SessionSummary`; frontend owns runtime state only | `training_*`, `ai_media_*`, `learning_*` table groups read/write only through owning backend SWCs; no migration | `BE-AI-GATEWAY`, `BE-MEDIA-STORAGE`, `AI-PROMPT-SCHEMA` candidate-only | MIG-TC-003 | Runtime owns mechanics, not domain decisions. |
| P01-SI-005, P01-SI-008, P01-SI-009 | MIG-FR-004 Domain logic stays in scenario practice | `spec.md#implementation-constraints` | MIG-AC-008 | `FE-SCENARIO-PRACTICE` | `BE-LEARNING`, `BE-PRACTICE`, `BE-AI-GATEWAY` only via current APIs | OpenAPI: `coachTurn`, `generateFeedback`, `listLearningEvidence`, `createLearningEvidence`, `listMastery`, `listPersonalWiki`, `listLearningHistory`, `getMvpLearningReportSummary`, `listReviewItems`, `submitReviewResult`; no contract drift | `LearningEvidence`, `LearningEvidenceCandidate`, `EvidenceRuleTrace`, `MasteryRecord`, `ReviewItem`, `LearningHistoryEntry`, `FavoriteExpression`, `SavedExpression`, `SessionSummary` | `learning_*` table group through `BE-LEARNING`; no migration | `AI-PROMPT-SCHEMA` candidate-only; LLM never writes final mastery/evidence | MIG-TC-004 | Expression graph, mastery, wiki and queue do not move into generic runtime. |
| P01-SI-007, P01-SI-008, P01-SI-011 | MIG-FR-005 No backend contract drift | `definition.md#frontend-only-decision` | MIG-AC-001 | `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE`, `FE-TRAINING` | `BE-CONTENT-SCENARIO`, `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING`, `BE-TRAINING` remain unchanged | No OpenAPI change | No Domain Schema change | No DB migration | No provider routing change | MIG-TC-005 | Any drift creates a separate cross-layer increment. |
| P01-SI-001, P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | MIG-FR-006 Complete old-function inventory | `spec.md#current-file-inventory` | MIG-AC-005 | `FE-SCENARIO-PRACTICE`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-PRACTICE-RUNTIME` candidates | N/A - architecture inventory only, no backend change | N/A - no API/OpenAPI change; inventory references the API operations listed in this document where applicable | N/A - no Domain Schema change; inventory references `Scenario`, `PracticeSession`, `DialogueTurn`, `LearningEvidence`, `MediaAsset` where applicable | N/A - no DB migration | N/A - no provider boundary change | MIG-TC-006 | Inventory must be updated if implementation discovers extra files. |
| P01-SI-001, P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | MIG-FR-007 Complete target-function allocation | `spec.md#target-swcs` | MIG-AC-006 | `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE`, `FE-TRAINING` boundary | `BE-CONTENT-SCENARIO`, `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING`; no new backend ownership | OpenAPI operations listed in API Contract Decision; legacy non-OpenAPI `/user/stats*` only behind adapter | `Scenario`, `ScenarioVersion`, `ScenarioLevel`, `TargetExpression`, `PracticeSession`, `DialogueTurn`, `MediaAsset`, `LearningEvidence`, `LearningEvidenceCandidate`, `SessionSummary` | `content_*`, `training_*`, `ai_media_*`, `learning_*`; no migration | `BE-AI-GATEWAY`, `BE-MEDIA-STORAGE`, `AI-PROMPT-SCHEMA`; no direct provider | MIG-TC-007 | Downstream tasks must cite target SWC, not just "frontend". |
| P01-SI-005, P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | MIG-FR-008 Complete runtime data flows | `spec.md#data-flow-summary` | MIG-AC-007 | `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE` | `BE-CONTENT-SCENARIO`, `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING` when remote calls apply | OpenAPI: `listScenarios`, `getScenario`, `getScenarioLevel`, `startPracticeSession`, `getPracticeSession`, `submitPracticeTurn`, `completePracticeSession`, `createAudioUpload`, `completeAudioUpload`, `transcribeAudio`, `synthesizeSpeech`, `coachTurn`, `generateFeedback`, `scorePronunciation`, learning/review operations listed above; legacy non-OpenAPI `/user/stats*` only for history adapter | `Scenario`, `TargetExpression`, `PracticeSession`, `DialogueTurn`, `MediaAsset`, `LearningEvidence`, `LearningEvidenceCandidate`, `SessionSummary` | `content_*`, `training_*`, `ai_media_*`, `learning_*`; no migration | `BE-AI-GATEWAY`, `BE-MEDIA-STORAGE`, `AI-PROMPT-SCHEMA`; provider secrets stay backend-only | MIG-TC-008 | Full flows below are implementation baseline. |
| P01-SI-010, P01-SI-011 | MIG-FR-009 Reuse and forbidden boundaries | `spec.md#implementation-constraints` | MIG-AC-009 | `FE-API-CLIENT`, `FE-AUDIO-PLATFORM`, `FE-LOCAL-CACHE`, `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-TRAINING` boundary | N/A - no backend change; remote calls may only use `BE-CONTENT-SCENARIO`, `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING` through `FE-API-CLIENT` | N/A - no API/OpenAPI change; forbidden to bypass OpenAPI operations or legacy stats adapter limits | N/A - no Domain Schema change | N/A - no DB migration | N/A - no provider change; direct provider calls forbidden | MIG-TC-009 | Blocks duplicate runtime and direct provider/local-final-fact bypasses. |
| P01-SI-001..011 refactor evidence only | MIG-FR-010 Migration slices and gates | `spec.md#migration-slices` | MIG-AC-010 | `FE-SCENARIO-PRACTICE`, `FE-PRACTICE-RUNTIME`, `FE-LEGACY-SCENARIO-SANDBOX`, `FE-AUDIO-PLATFORM`, `FE-API-CLIENT`, `FE-LOCAL-CACHE`, `FE-TRAINING` | N/A - architecture gates only, no backend change | N/A | N/A | N/A | N/A | MIG-TC-010 | Coding starts only after independent check passes. |
| P01-SI-009, P01-SI-011 | MIG-FR-011 Practice history and stats adapter parity | `spec.md#target-swcs` | MIG-AC-011 | `FE-PRACTICE-RUNTIME`, `FE-LOCAL-CACHE`, `FE-API-CLIENT` | N/A - no stable BE SWC in this migration; current stats backend remains legacy/non-OpenAPI and is not promoted | Legacy non-OpenAPI ApiClient methods: `getLearningStats` -> `GET /user/stats`, `recordPracticeSession` -> `POST /user/stats/session`, `upsertPracticeFeedback` -> `POST /user/stats/session/feedback`, `deletePracticeSceneGroup` -> `POST /user/stats/session-group/delete`; not OpenAPI | `LearningStatsModel` and `PracticeHistoryModel` are frontend display/cache models, not Domain Schema facts; server stats ownership requires future API contract | N/A - no DB contract or migration; do not infer table ownership from legacy path | N/A | MIG-TC-011 | Legacy sandbox writes this path today; runtime may use adapter but must not treat it as stable cross-end contract. |

## Old SWC / File Responsibility Inventory
| Current SWC or candidate | Files | Functional requirements currently carried |
| --- | --- | --- |
| `FE-SCENARIO-PRACTICE` legacy-compatible path | `lib/features/interview/interview_practice_page.dart` | Current main voice scenario practice, bootstrap/restore, scene map, answer submit, voice recording/ASR, text fallback, coach/hint, translation/playback, review, wiki writes, UI state. |
| `FE-SCENARIO-PRACTICE` domain engine | `lib/features/interview/interview_engine.dart`, `interview_models.dart` | Scene catalog/graph, expression mastery, practice engine, session/turn/review/wiki/progress models. |
| `FE-SCENARIO-PRACTICE` AI/domain scheduling | `lib/features/interview/interview_llm_scheduler.dart`, `interview_coach_schema.dart` | Coach/hint/review/wiki/mastery AI scheduling and schema constants; candidate-only AI boundary. |
| `FE-SCENARIO-PRACTICE` learning memory | `lib/features/interview/interview_wiki_store.dart`, `expression_daily_queue_coordinator.dart`, `expression_scene_orchestrator.dart` | Local wiki/growth wiki/session/progress, daily queue, expression scene orchestration. |
| `FE-SCENARIO-PRACTICE` listening/shadowing | `lib/features/interview/interview_scene_listening_page.dart`, `interview_scene_dialogue_builder.dart`, `expression_shadow_scoring.dart`, `interview_expression_learning_page.dart` | Listening/shadowing UI, dialogue building, local shadow scoring, expression learning page. |
| `FE-LEGACY-SCENARIO-SANDBOX` | `lib/features/scenario/scene_page.dart`, `scene_runtime_models.dart`, `scene_widgets.dart`, `scene_logic.dart` | Generic virtual friend/custom scenario sandbox, draft/edit/chat/feedback, text/voice chat, TTS, feedback, history; non-main-flow. |
| `FE-PRACTICE-RUNTIME` candidate source | `lib/application/scene/*.dart`, `lib/services/voice_turn_orchestrator.dart` | Existing partial shared coordinators for scene setup, conversation, hint, voice runtime/session/binding/lifecycle/turn rules/user turn, assistant voice-turn buffering/finalization, auxiliary and support helpers. |
| `FE-AUDIO-PLATFORM` | `lib/services/audio_service.dart`, `lib/services/voice_chat_service.dart` | Platform recording/playback and voice runtime service; must be reused by runtime. |
| `FE-API-CLIENT` | `lib/services/api_client.dart`, `lib/generated/api/` | OpenAPI/generated client boundary plus known legacy client wrappers; no direct provider/DTO fork. |
| `FE-LOCAL-CACHE` | `lib/services/storage_service.dart`, local stores | Display cache, preferences, recoverable session state; no final server fact ownership. |
| `FE-LOCAL-CACHE` / practice stats adapter | `lib/services/app_session.dart`, `lib/application/session/session_stats_coordinator.dart`, `lib/services/stats_service.dart`, `lib/models/learning_stats_model.dart` | Practice history display cache, stats merge, `recordPracticeSession`, `upsertPracticeFeedback`, stats API sync. Current legacy sandbox calls this path; current interview parity is not proven and must be resolved or explicitly non-goal. |
| `FE-TRAINING` | `lib/features/training/` | Backend-owned Training UI/adapter; referenced only as a boundary that scenario practice must not absorb. |

## Target SWC Allocation
| Function family | Target SWC | Inputs | Outputs | Dependencies | Owned data | Called APIs/provider boundaries | Test responsibility |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Official scenario practice UI composition | `FE-SCENARIO-PRACTICE` | Route args, selected scenario/level, runtime state, domain models | Rendered practice UI and user intents | `FE-PRACTICE-RUNTIME`, `FE-API-CLIENT`, `FE-LOCAL-CACHE` | UI state and local display cache | OpenAPI via `FE-API-CLIENT`: `listScenarios`, `getScenario`, `getScenarioLevel`, `startPracticeSession`, `getPracticeSession`, `submitPracticeTurn`, `completePracticeSession`, `listLearningEvidence`, `listMastery`, `listPersonalWiki`; no DTO drift | Interview widget/golden/regression tests. |
| Expression graph/mastery/wiki/queue | `FE-SCENARIO-PRACTICE` | Scene graph, turn/review results, local progress, accepted backend facts when available | Next prompt/domain decision, wiki/progress/queue updates | `FE-LOCAL-CACHE`, `FE-API-CLIENT` | Local transition cache only | OpenAPI: `coachTurn`, `generateFeedback`, `listLearningEvidence`, `createLearningEvidence`, `listMastery`, `listPersonalWiki`, `listLearningHistory`, `getMvpLearningReportSummary`, `listReviewItems`, `submitReviewResult`; AI candidate-only | Domain unit tests and wiki/queue tests. |
| Runtime session recovery | `FE-PRACTICE-RUNTIME` | Runtime session id, local cached draft, backend response/failure, route lifecycle | Resume/clear/retry/exit state | `FE-LOCAL-CACHE`, `FE-API-CLIENT` | Recoverable runtime state only | OpenAPI if remote recovery is used: `startPracticeSession`, `getPracticeSession`, `completePracticeSession`; local cache otherwise | Runtime unit tests. |
| Message loop | `FE-PRACTICE-RUNTIME` | User text/transcript, current runtime turn, domain adapter callbacks | Pending/sent/failed message state and normalized response event | `FE-API-CLIENT`, domain adapter from `FE-SCENARIO-PRACTICE` | Runtime message state only | OpenAPI: `submitPracticeTurn`, `coachTurn`, `generateFeedback`; idempotency through existing `Idempotency-Key` where submit path uses it | Message-loop success/failure/idempotency tests. |
| Voice capture and ASR shell | `FE-PRACTICE-RUNTIME` + `FE-AUDIO-PLATFORM` | Mic permission, audio stream/file, cancel/send intents | Recording state, transcript or recoverable ASR failure | `FE-AUDIO-PLATFORM`, `FE-API-CLIENT` | Temporary local audio before accepted upload only | OpenAPI: `createAudioUpload`, `completeAudioUpload`, `transcribeAudio`, `scorePronunciation`; trusted refs only from backend | Audio/runtime tests; no fake trusted refs. |
| Voice turn finalization mechanics | `FE-PRACTICE-RUNTIME` candidate over existing `lib/services/voice_turn_orchestrator.dart` | Assistant text deltas, audio/speaking signals, session key, realtime or turn-based mode | `VoiceAssistantTurnReady` event for the owning runtime/domain adapter | `FE-AUDIO-PLATFORM`, existing `VoiceChatService` metadata only | Runtime turn buffer and local finalization state only | No API/provider call; finalization must feed existing runtime/API adapter boundaries instead of bypassing them | Voice-turn orchestrator/runtime finalization tests under MIG-TC-008. |
| TTS/playback | `FE-PRACTICE-RUNTIME` + `FE-AUDIO-PLATFORM` | Text/voice/language request, response text | Playback state, recoverable TTS failure | `FE-AUDIO-PLATFORM`, `FE-API-CLIENT` | Playback state only | OpenAPI: `synthesizeSpeech`; backend `BE-AI-GATEWAY` / `BE-AI-OPS` TTS cache boundary only | Playback/fallback tests. |
| Hint request shell | `FE-PRACTICE-RUNTIME` | Current turn, domain context, hint intent | Hint loading/result/fallback event | `FE-API-CLIENT`, domain adapter | Runtime hint state only | OpenAPI when remote hint/coach is used: `coachTurn`, `generateFeedback`; Training hint `requestTrainingHint` is `FE-TRAINING` boundary only and not owned here | Hint fallback tests. |
| Feedback recorder | `FE-PRACTICE-RUNTIME` + `FE-SCENARIO-PRACTICE` | Turn result, coach feedback, review result, runtime trace | Domain callback for wiki/progress/recap; runtime trace | `FE-LOCAL-CACHE`, `FE-API-CLIENT` | Runtime trace; domain data remains owner SWC | OpenAPI: `generateFeedback`, `coachTurn`, `completePracticeSession`, `createLearningEvidence`, `listLearningHistory`, `getMvpLearningReportSummary`; no final mastery from AI | Feedback/review/wiki regression tests. |
| Practice history recorder | `FE-PRACTICE-RUNTIME` + `FE-LOCAL-CACHE` | Session summary, feedback summary, scene/friend/title metadata, duration, timestamps | `PracticeHistoryModel` merge, stats sync call, display refresh | `AppSession`, `SessionStatsCoordinator`, `StatsService`, `FE-API-CLIENT` | Display cache only; backend stats facts are not stabilized by this migration | Legacy non-OpenAPI only: `GET /user/stats`, `POST /user/stats/session`, `POST /user/stats/session/feedback`, `POST /user/stats/session-group/delete`; must remain behind adapter | Session stats coordinator and runtime history adapter tests. |
| Legacy sandbox maintenance | `FE-LEGACY-SCENARIO-SANDBOX` | Current legacy route/state only | Current sandbox UI behavior | Optional `FE-PRACTICE-RUNTIME` adapters | Legacy local state only | OpenAPI if current legacy calls remain: `startPracticeSession`, `submitPracticeTurn`, `synthesizeSpeech`, `transcribeAudio`, `generateFeedback`; legacy non-OpenAPI `/user/stats*` only behind stats adapter | Smoke/static guard if touched. |

## SWC Data Flows

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-START-RESUME
- 全局 Flow ID 或本地分类：global `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`。
- 触发条件：用户打开当前 interview/onboarding practice route，或返回 active session。
- 成功路径：
  ```text
  UI route in FE-BOOTSTRAP-ROUTING
    -> FE-SCENARIO-PRACTICE reads route args and domain assets
    -> FE-PRACTICE-RUNTIME checks recoverable local runtime state
    -> FE-LOCAL-CACHE returns active display/session cache if present
    -> FE-SCENARIO-PRACTICE validates scene graph, level, expression domain context
    -> optional FE-API-CLIENT uses OpenAPI `listScenarios`/`getScenario`/`getScenarioLevel` or practice/learning operations when remote refresh applies
    -> BE-API-CONTROLLERS -> owning BE SWC -> response
    -> FE-PRACTICE-RUNTIME normalizes ready/resume/error state
    -> FE-SCENARIO-PRACTICE renders first prompt or resumed turn
  ```
- 失败路径：missing scene graph、stale local session、backend unavailable、unauthorized、entitlement display mismatch 或 corrupted cache 必须转成 recoverable route state，并提供明确 retry/start-over/exit action。
- Auth / authorization：前端使用现有 auth/session bootstrap 和 API client token 处理；不得信任 page state 中的 user id。
- Idempotency / retry：resume 不得创建重复 backend session 或重复 local active session；显式 reset 前 retry 复用既有 runtime key。
- Rollback or compensation：corrupted local runtime cache 只清理本 practice session；resume 失败不得修改 domain wiki/progress。
- Audit / logging / metrics：后续实现应通过现有 observability hooks 发出脱敏 session-start/resume/failure event；不得记录 raw transcript/audio。
- Permission / privacy：local cache 只存 display/recovery data；不得生成 provider secret 或 trusted media ref。
- Response-to-UI mapping（响应映射）：ready -> practice prompt；stale -> restart banner；unauthorized -> login/session recovery；backend unavailable -> offline/retry state。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-CONTENT-LOAD
- 全局 Flow ID 或本地分类：global `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`。
- 触发条件：start/resume 需要 scene catalog、scene graph、target expression、question plan、listening dialogue 或 reviewed content。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE
    -> loads bundled reviewed interview scene catalog/graph or existing scenario content API projection
    -> validates scenario id, level, node, target expression and domain invariants
    -> FE-PRACTICE-RUNTIME receives only runtime-safe prompt/turn context
    -> UI renders current prompt/listening/dialogue state
  ```
- 失败路径：missing asset、invalid node、unsupported level 或 backend content failure 返回 recoverable "content unavailable" state，并阻止 turn submission。
- Auth / authorization：backend content call 使用现有 API auth；bundled reviewed assets 不需要 server auth，但不能凭空创建新 official content。
- Idempotency / retry：reload 不修改 wiki/progress/session；retry 只读。
- Rollback or compensation：content validation 通过前不做持久化 mutation。
- Audit / logging / metrics：content-load failure 只记录 scenario id/level。
- Permission / privacy：content-load log 不记录 learner transcript/audio。
- Response-to-UI mapping（响应映射）：valid content -> prompt/dialogue；invalid content -> retry/exit。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-VOICE-ASR
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`，并继承 `SWC-FLOW-MEDIA-AUDIO-UPLOAD`、`SWC-FLOW-USAGE-AI` 作为边界。
- 触发条件：用户 start、cancel、finish 或 submit voice turn。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE record/send intent
    -> FE-PRACTICE-RUNTIME voice turn coordinator
    -> FE-AUDIO-PLATFORM requests mic permission and records/streams audio
    -> FE-PRACTICE-RUNTIME handles cancel/retry/submit state
    -> FE-API-CLIENT uses existing media/ASR/practice API path when backend ASR is needed
    -> BE-API-CONTROLLERS
    -> BE-MEDIA-STORAGE validates trusted media ref when applicable
    -> BE-AI-GATEWAY calls provider through backend only
    -> response transcript/status/fallback
    -> FE-PRACTICE-RUNTIME normalizes transcript or ASR recoverable failure
    -> FE-SCENARIO-PRACTICE submits transcript to domain message loop
  ```
- 失败路径：mic denied、recording failure、cancel、upload failure、invalid audio ref、ASR no result、provider unavailable、timeout 或 invalid schema。
- Auth / authorization：media/ASR call 使用现有 auth；backend 校验 media ref ownership。
- Idempotency / retry：cancel 丢弃本地 temporary audio；retry 创建新的用户可见 attempt，但不得重复提交 accepted turn。
- Rollback or compensation：recording/ASR 失败不得写 wiki/progress 或 final feedback；temporary local audio 被清理，或仅在现有代码批准时作为 recoverable draft 保留。
- Audit / logging / metrics：只记录脱敏 mic/ASR status、provider status、latency bucket；日志不得包含 raw audio/full transcript。
- Permission / privacy：Flutter 永不创建生产可信 `media://audio/...` ref 或 provider-readable signed URL。
- Response-to-UI mapping（响应映射）：success -> transcript confirmation/send；mic denied/ASR failed -> text fallback and retry；provider unavailable -> recoverable fallback。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-TEXT-TURN
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`。
- 触发条件：用户直接提交文本，或在 ASR fallback 后提交文本。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE text submit
    -> FE-PRACTICE-RUNTIME validates non-empty turn and current runtime state
    -> domain adapter in FE-SCENARIO-PRACTICE attaches scenario/node/expression context
    -> FE-PRACTICE-RUNTIME message loop sends through existing domain/API adapter
    -> FE-API-CLIENT if backend practice/AI call is needed
    -> backend owner SWCs or local domain engine as current implementation allows
    -> normalized response
    -> FE-PRACTICE-RUNTIME records sent/failed state
    -> FE-SCENARIO-PRACTICE renders coach/NPC response and next prompt
  ```
- 失败路径：empty text、stale session、duplicate submit、backend timeout、AI fallback 或 local domain exception。
- Auth / authorization：backend call 使用现有 API auth；local-only path 不得声明 server fact。
- Idempotency / retry：backend 支持时 runtime 保留 client turn id/idempotency key；重复点击不得提交重复可见 turn。
- Rollback or compensation：submit 失败可 retry 或 edit；accepted turn result 存在前不得修改 review/wiki。
- Audit / logging / metrics：记录脱敏 turn-submit status 和 fallback reason。
- Permission / privacy：除现有已批准 local UI/cache 外，不记录完整敏感 transcript。
- Response-to-UI mapping：sent -> pending/response；failed -> retry/edit；duplicate -> 保持单一 pending state。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-AI-COACH-TURN
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`、`SWC-FLOW-USAGE-AI`。
- 触发条件：user turn 需要 NPC/coach response、grammar/feedback、mastery candidate、hint、review、wiki generation 或 diagnosis。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE domain scheduler
    -> FE-PRACTICE-RUNTIME request/retry shell
    -> FE-API-CLIENT
    -> BE-API-CONTROLLERS
    -> BE-USAGE-CONTROL when high-cost AI applies
    -> BE-AI-GATEWAY
    -> AI provider/runtime
    -> BE-AI-OPS redacted evidence/metrics
    -> typed response/fallback
    -> FE-PRACTICE-RUNTIME normalizes result
    -> FE-SCENARIO-PRACTICE applies domain rules and renders response
  ```
- 失败路径：quota/entitlement denial、provider timeout、invalid schema、no result、safety fallback 或 backend unavailable。
- Auth / authorization：现有 auth 和 entitlement/usage gate 仍由服务端拥有。
- Idempotency / retry：backend 提供 idempotency 时，retry 不得重复扣费或重复生成可见 coach turn；否则 runtime 必须把 retry 标记为新的用户动作。
- Rollback or compensation：AI fallback 不能写 final mastery 或 accepted evidence；usage release/commit 仍归 backend 拥有。
- Audit / logging / metrics：记录 request id、provider label、status、latency/cost bucket；不得记录 raw provider payload。
- Permission / privacy：provider secret 只留在 backend。
- Response-to-UI mapping（响应映射）：typed success -> coach/NPC response；fallback -> safe retry/hint/degraded feedback；quota denied -> entitlement/limit UI。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-TTS-PLAYBACK
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`、`SWC-FLOW-USAGE-AI`。
- 触发条件：系统需要播放 model sentence、NPC/coach response、listening dialogue 或 shadowing audio。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE playback intent
    -> FE-PRACTICE-RUNTIME TTS/playback coordinator
    -> FE-API-CLIENT requests OpenAPI `synthesizeSpeech` when required
    -> BE-API-CONTROLLERS -> BE-AI-GATEWAY / BE-AI-OPS TTS cache boundary
    -> response with playable result/status
    -> FE-AUDIO-PLATFORM plays audio
    -> FE-PRACTICE-RUNTIME updates playback state
    -> UI shows playing/paused/complete state
  ```
- 失败路径：TTS unavailable、playback device error、stale request、network timeout 或 cache miss failure。
- Auth / authorization：backend TTS 使用现有 auth/usage；local playback 使用 platform permission。
- Idempotency / retry：相同 playback request 可在可用时复用 backend cache；重复点击不得创建重叠 playback。
- Rollback or compensation：停止 playback 并保持文本可见；不产生 learning mutation。
- Audit / logging / metrics：通过 `BE-AI-GATEWAY` / `BE-AI-OPS` 记录脱敏 TTS status/cache/provider metrics。
- Permission / privacy：frontend 不知道 provider cache key 或 credential。
- Response-to-UI mapping（响应映射）：success -> audio controls；fail -> text-only fallback。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-HINT
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`；使用 backend AI hint 时继承 `SWC-FLOW-USAGE-AI`。
- 触发条件：用户请求 hint，或 runtime/domain rule 在失败尝试后升级支持。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE hint intent/domain trigger
    -> FE-PRACTICE-RUNTIME hint request shell
    -> FE-SCENARIO-PRACTICE supplies scenario/node/expression context
    -> FE-API-CLIENT if remote coach/hint is needed
    -> BE-AI-GATEWAY candidate response or existing local hint rule
    -> FE-PRACTICE-RUNTIME normalizes hint state
    -> FE-SCENARIO-PRACTICE renders hint ladder UI
  ```
- 失败路径：no context、AI unavailable、invalid hint、quota denied。
- Auth / authorization：remote hint 使用 backend 时复用现有 auth/usage。
- Idempotency / retry：多次点击 hint 只更新一个 hint panel，不复制 turn。
- Rollback or compensation：单独 hint 不产生 progress/wiki mutation。
- Audit / logging / metrics：记录 hint requested/shown/fallback 和脱敏 context id。
- Permission / privacy：hint context 最小化到必要 scenario/expression id。
- Response-to-UI mapping：hint -> ladder panel；failure -> local fallback 或 disabled state。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-FEEDBACK-REVIEW
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`、`SWC-FLOW-USAGE-AI`，并继承现有 Product Base Practice Turn Flow。
- 触发条件：用户完成 turn、请求 feedback、完成 review，或带着足够数据退出 session。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE review/feedback trigger
    -> FE-PRACTICE-RUNTIME feedback recorder collects runtime trace and turn status
    -> FE-SCENARIO-PRACTICE domain engine/scheduler computes or requests feedback/review
    -> FE-API-CLIENT if backend practice/AI/learning API is used
    -> BE-PRACTICE / BE-AI-GATEWAY / BE-LEARNING as current contract allows
    -> typed feedback/review response
    -> FE-SCENARIO-PRACTICE applies deterministic frontend transition rules where still local
    -> FE-LOCAL-CACHE stores display/cache only
    -> UI renders recap, review note, next action
  ```
- 失败路径：insufficient turns、AI feedback failure、learning write failure、local store failure 或 backend unavailable。
- Auth / authorization：backend review/learning call 使用现有 auth；local transition 不得声明 server final fact。
- Idempotency / retry：重复 review generation 不应产生重复 learning write；runtime 保存 review generation state，由 domain owner 处理 merge。
- Rollback or compensation：learning write 失败时 review 仍可见，但按现有行为标记为 retryable/local-only；不得伪造 server completion。
- Audit / logging / metrics：backend 支持时记录 feedback/review status、evidence accepted/rejected/write_failed。
- Permission / privacy：metrics 避免 raw provider payload 和完整敏感 transcript。
- Response-to-UI mapping：recap -> review UI；partial failure -> 带 retry/degraded message 的 recap；fatal failure -> recoverable exit。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-WIKI-MEMORY-QUEUE
- 全局 Flow ID 或本地分类：`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`，并继承现有 Product Base Practice Turn Flow。
- 触发条件：review completes、expression progress changes、daily queue refreshes 或 wiki compilation runs。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE review/domain result
    -> FE-SCENARIO-PRACTICE wiki/progress/queue owner applies domain-specific merge rules
    -> FE-LOCAL-CACHE persists local transition cache
    -> optional FE-API-CLIENT syncs OpenAPI `createLearningEvidence`/`listLearningEvidence`/`listMastery`/`listPersonalWiki`/`listLearningHistory` when available
    -> BE-LEARNING owns accepted server evidence
    -> response/sync status
    -> FE-SCENARIO-PRACTICE refreshes home/queue/wiki surfaces
  ```
- 失败路径：store write failure、merge conflict、backend sync failure、stale compiled wiki。
- Auth / authorization：backend learning sync 使用现有 auth；local cache 保持 user-device scoped。
- Idempotency / retry：可用时，同一个 review result 应按 review/session id 只 merge 一次。
- Rollback or compensation：local write 失败时 UI state 保留在内存并标记 retryable；backend sync 失败不得发明 server fact。
- Audit / logging / metrics：记录脱敏 write/sync status 和 source session id。
- Permission / privacy：wiki/personal material 遵守现有 local/backend privacy rules。
- Response-to-UI mapping（响应映射）：success -> updated wiki/queue/home；partial -> stale badge/retry；fail -> no false mastery。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-PRACTICE-HISTORY
- 全局 Flow ID 或本地分类：global `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME`。
- 触发条件：session starts、session completes、feedback is generated、legacy sandbox records a practice，或 scenario-practice implementation 决定暴露 history parity。
- 成功路径：
  ```text
  FE-SCENARIO-PRACTICE or FE-LEGACY-SCENARIO-SANDBOX completion/feedback event
    -> FE-PRACTICE-RUNTIME PracticeHistoryRecorder adapter
    -> AppSession.recordPracticeSession or AppSession.upsertPracticeFeedback
    -> SessionStatsCoordinator merges local and remote practice history
    -> StatsService
    -> FE-API-CLIENT legacy non-OpenAPI stats/practice client wrapper
    -> backend stats/practice owner through existing API
    -> LearningStatsModel / PracticeHistoryModel response or local fallback
    -> profile/home/report/legacy sandbox surfaces refresh display cache
  ```
- 失败路径：missing session summary、duplicate title merge ambiguity、local cache failure、stats API unavailable、auth expired、backend rejects sync、feedback update without existing practice。
- Auth / authorization：stats sync 使用现有 API client auth；runtime payload 中的 user id 不得作为 server truth。
- Idempotency / retry：可用时 adapter 应携带 stable session/review identity；重复 feedback update 必须 merge，而不是追加重复 history row。
- Rollback or compensation：remote stats sync 失败只保留 local display cache，并在 existing coordinator 支持时标记 sync retryable；不得伪造 server stats claim。
- Audit / logging / metrics：只记录脱敏 history-record/write-failed status 和 request id；不得记录 full transcript/audio/provider payload。
- Permission / privacy：practice history 可包含 user-facing title/summary/feedback，但不得包含 raw provider secret、signed media URL 或未脱敏敏感 payload。
- Response-to-UI mapping：success -> refreshed recent practices；partial -> local history with sync pending/degraded state；fail -> 不阻塞 session exit/review display。

### SWC-FLOW-SCENARIO-PRACTICE-RUNTIME-LEGACY-SANDBOX
- 全局 Flow ID 或本地分类：`legacy-compatible`。
- 触发条件：触碰 legacy sandbox route 或 maintenance code path。
- 成功路径：
  ```text
  FE-LEGACY-SCENARIO-SANDBOX route
    -> legacy sandbox UI/state remains isolated
    -> optional FE-PRACTICE-RUNTIME adapter handles shared voice/message/TTS mechanics
    -> FE-API-CLIENT calls only listed OpenAPI practice/media/AI operations, plus legacy `/user/stats*` behind stats adapter when needed
    -> response
    -> legacy sandbox renders existing behavior
  ```
- 失败路径：unsupported legacy route、draft generation failure、chat/feedback/TTS failure、no route reachability。
- Auth / authorization：只使用 existing API auth；不新增 feature entitlement。
- Idempotency / retry：保留现有 draft/chat retry semantics；不得创建新的 official practice facts。
- Rollback or compensation：maintenance change 必须是 adapter-only 或可回滚，且不影响主流程。
- Audit / logging / metrics：如果存在 telemetry，标记为 legacy/non-main-flow。
- Permission / privacy：legacy model 不得变成 canonical domain/persistence fact。
- Response-to-UI mapping：只保留当前 legacy UI；不声明 Product Base completion。

## Reuse And Forbidden Boundaries
| Boundary type | Decision |
| --- | --- |
| Existing SWCs that must be reused | `FE-API-CLIENT`, `FE-AUDIO-PLATFORM`, `FE-LOCAL-CACHE`, `FE-SCENARIO-PRACTICE` domain logic, `BE-CONTENT-SCENARIO`, `BE-PRACTICE`, `BE-MEDIA-STORAGE`, `BE-AI-GATEWAY`, `BE-LEARNING` only through `FE-API-CLIENT`, existing `lib/application/scene/` coordinators as extraction source, existing `AppSession`/`SessionStatsCoordinator`/`StatsService` practice stats path. |
| New SWCs allowed | `FE-PRACTICE-RUNTIME` only, as reusable frontend mechanics. `FE-SCENARIO-PRACTICE` is a stable rename/classification of current main flow; `FE-LEGACY-SCENARIO-SANDBOX` is a legacy classification. |
| Duplicate components forbidden | Third message loop, third voice capture service, third TTS wrapper, duplicate API DTOs, duplicate local wiki/progress store, duplicate practice history/statistics store, duplicate Training source of truth, duplicate scenario domain models as canonical schema. |
| Forbidden direct calls or bypasses | Flutter direct provider calls, provider credentials in client, client-generated trusted `audio_ref`, local final mastery/evidence as server fact, direct DB access, bypassing `FE-API-CLIENT`, bypassing `FE-AUDIO-PLATFORM`, expanding `lib/features/scenario/` with new product scope. |
| Legacy exceptions and migration plan | `lib/features/interview/` remains a legacy-compatible path for `FE-SCENARIO-PRACTICE` until runtime extraction and optional path rename are approved. `lib/features/scenario/` remains legacy-compatible and non-main-flow until archived or adapter-reduced. |

## Verification
| Check | Expected evidence |
| --- | --- |
| Expected tests | `MIG-TC-001` through `MIG-TC-011`; later implementation maps each test to exact Flutter/static command. |
| Static gates | SWC catalog contains new IDs; no new third scenario-practice package before runtime; import guard prevents runtime importing feature widgets/domain-only files. |
| OpenAPI/generated drift checks | No OpenAPI/generated drift for frontend-only migration. Any drift blocks and reclassifies as cross-layer increment. |
| Traceability checker | `traceability.md` maps FR -> Spec -> AC -> SWC -> TC. |
| Software Architecture Governance Check finding | Pass after first-round blocker correction and SWC allocation gate follow-up; see `docs/reports/quality_report.md` report `SCENARIO-PRACTICE-RUNTIME-MIGRATION-ARCH-GOV-20260612`. |

## Notes
- 本文是相对于 `docs/architecture/software_component_architecture.md` 的 delta，不是完整 SWC architecture。
- 完整 global SWC catalog 仍以 `docs/architecture/swc_catalog.md` 为准。
- 局部变更的完整 architecture reference baseline 以 `docs/architecture/software_component_architecture.md` 为准。
