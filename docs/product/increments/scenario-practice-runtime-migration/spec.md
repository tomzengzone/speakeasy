# 场景练习 Runtime 迁移规格

## 状态
架构设计已就绪。`swc_allocation.md` 和独立架构审查通过前，不得开始实现。

## 架构决策
当前代码已经存在两个类似 scenario 的区域，但它们的职责不同：

| Current area | Decision | Reason |
| --- | --- | --- |
| `lib/features/interview/` | Treat as current main flow and target SWC `FE-SCENARIO-PRACTICE`; path is legacy-compatible until migration finishes. | It owns the reachable interview/onboarding scenario practice, expression graph, mastery, wiki, queue, listening/shadowing, and current voice practice UI. |
| `lib/features/scenario/` | Treat as `FE-LEGACY-SCENARIO-SANDBOX`; no new expansion. | It implements a large generic virtual-friend/custom scenario sandbox and is documented as non-main-flow / unreachable in current Product Base paths. |
| `lib/application/scene/` | Treat as existing partial runtime source that can be migrated into `FE-PRACTICE-RUNTIME`. | It already contains setup, conversation, hint, voice runtime, voice binding, lifecycle, turn rules, and auxiliary coordinators. |
| New `lib/features/scenario_practice/` | Not allowed in the first migration slice. | Creating a third feature path before extracting shared runtime would increase duplication. |

## 目标 SWC
| SWC | Target role | Initial code-path decision |
| --- | --- | --- |
| `FE-SCENARIO-PRACTICE` | Main official scenario practice domain and UI. Owns interview/onboarding expression graph, mastery, wiki, queue, reviewed content, listening/shadowing, and practice-page composition. | Continue using `lib/features/interview/` during migration; optional later path rename needs separate approval. |
| `FE-PRACTICE-RUNTIME` | Reusable runtime primitives for practice sessions: voice capture, message loop, TTS/playback, feedback recorder, retry/fallback state, session recovery, runtime telemetry adapters. | New target boundary `lib/application/practice_runtime/`; existing `lib/application/scene/` can be migrated or adapter-wrapped into it. |
| `FE-LEGACY-SCENARIO-SANDBOX` | Non-main-flow legacy sandbox for generic virtual friend/custom scene. | Keep `lib/features/scenario/`; only maintenance fixes and runtime reuse adapters are allowed. |
| `FE-AUDIO-PLATFORM` | Platform mic/audio recording, playback, voice-chat service integration. | Reuse existing audio services; no duplicate voice stack. |
| `FE-API-CLIENT` | OpenAPI/client boundary for all backend calls. | Reuse existing client/generator; no DTO drift. |
| `FE-LOCAL-CACHE` | Display cache, recoverable local state, local preferences. | Reuse existing storage service; no new independent store for final facts. |
| `FE-LOCAL-CACHE` / practice stats adapter | Practice history display cache and best-effort stats synchronization. | Reuse `AppSession`, `SessionStatsCoordinator`, `StatsService`, `LearningStatsModel`, and `ApiClient`; current `/user/stats*` calls are legacy non-OpenAPI paths and must not be treated as stable cross-end contracts. |
| `FE-TRAINING` | Backend-owned Training UI/adapter. | Remains separate; scenario-practice runtime must not become Training source of truth. |

## 当前文件清单
| Current SWC | File or path | Current functional responsibility | Target allocation |
| --- | --- | --- | --- |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_practice_page.dart` | Main voice scenario practice page; bootstrap/restore; scene map; answer submit; streaming/recorded voice; ASR fallback; coach turn; translation/playback; review; wiki writes; UI state. | UI composition stays in `FE-SCENARIO-PRACTICE`; voice/message/session/recovery primitives migrate to `FE-PRACTICE-RUNTIME`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_engine.dart` | Scene catalog/graph loading, expression mastery judge, practice engine, local question/reply/review helpers. | Domain practice logic stays in `FE-SCENARIO-PRACTICE`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_models.dart` | Interview scene catalog, graph, node, expression, session, turn, review, wiki/progress models. | Domain models stay unless a later Domain Schema migration is approved. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_llm_scheduler.dart` | AI session scheduling for coach, hint, review, wiki, mastery and diagnosis. | Domain scheduling stays; common request/retry shell can reuse `FE-PRACTICE-RUNTIME`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_wiki_store.dart` | Local wiki, compiled wiki, growth wiki, active session, expression progress and preferences. | Stays in `FE-SCENARIO-PRACTICE`; may call runtime feedback recorder for event capture only. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_expression_learning_page.dart` | Expression learning and daily micro-drills UI. | Stays in `FE-SCENARIO-PRACTICE`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/expression_daily_queue_coordinator.dart` | Daily expression queue from weak/review/progress/new/variant inputs. | Stays in `FE-SCENARIO-PRACTICE`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/expression_scene_orchestrator.dart` | Expression scene graph navigation/orchestration. | Stays in `FE-SCENARIO-PRACTICE`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/expression_shadow_scoring.dart` | Local shadow scoring for listening/shadowing. | Stays in `FE-SCENARIO-PRACTICE`; voice playback capture uses `FE-AUDIO-PLATFORM`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_scene_listening_page.dart` | Listening/shadowing page. | Stays in `FE-SCENARIO-PRACTICE`; shared audio control can reuse runtime/audio boundary. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_scene_dialogue_builder.dart` | Dialogue turns for listening/shadowing. | Stays in `FE-SCENARIO-PRACTICE`. |
| `FE-SCENARIO-PRACTICE` | `lib/features/interview/interview_coach_schema.dart` | Coach schema constants. | Stays in `FE-SCENARIO-PRACTICE` or AI contract boundary if a later AI runtime migration is approved. |
| `FE-LEGACY-SCENARIO-SANDBOX` | `lib/features/scenario/scene_page.dart` | Generic virtual friend/custom scene home/create/draft/edit/chat/feedback flow; text/voice chat; TTS; feedback; history; non-main-flow. | Mark legacy; do not expand; allowed to consume `FE-PRACTICE-RUNTIME` adapters only when reducing duplication. |
| `FE-LEGACY-SCENARIO-SANDBOX` | `lib/features/scenario/scene_runtime_models.dart` | Runtime DTO-like models for virtual friend, turn contract, service state/policy/trace, chat messages. | Freeze for legacy compatibility; do not become canonical domain schema. |
| `FE-LEGACY-SCENARIO-SANDBOX` | `lib/features/scenario/scene_widgets.dart` | Legacy sandbox UI widgets. | Freeze except maintenance/runtime adapter work. |
| `FE-LEGACY-SCENARIO-SANDBOX` | `lib/features/scenario/scene_logic.dart` | Legacy part-file marker. | Freeze. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_setup_coordinator.dart` | Scene draft/setup orchestration and remote API adapter. | Split generic runtime setup from legacy sandbox-specific draft generation. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_conversation_coordinator.dart` | Message send/recovery and turn metadata. | Migrate message-loop core to `FE-PRACTICE-RUNTIME`; keep legacy adapter names until callers move. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_hint_coordinator.dart` | Hint request orchestration. | Migrate reusable hint request/recovery shell. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_voice_runtime_coordinator.dart` | Voice runtime connection/session updates. | Migrate reusable voice runtime orchestration. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_voice_session_binding_coordinator.dart` | Voice session binding. | Migrate reusable voice binding. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_voice_session_lifecycle_coordinator.dart` | Voice session lifecycle. | Migrate reusable lifecycle. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_voice_turn_rules_coordinator.dart` | Voice turn rules. | Migrate reusable turn-rule evaluation. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_voice_user_turn_coordinator.dart` | User voice turn capture/submit support. | Migrate reusable voice-turn coordination. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_auxiliary_coordinator.dart` | Auxiliary translation/summary support. | Migrate only generic response-decoration shell; domain-specific copy remains with owner SWC. |
| `FE-PRACTICE-RUNTIME` candidate | `lib/application/scene/scene_runtime_support_coordinator.dart` | Runtime support helpers. | Migrate reusable helpers after API is stabilized. |
| `FE-AUDIO-PLATFORM` | `lib/services/audio_service.dart`, `lib/services/voice_chat_service.dart` | Recording, playback, local audio metadata, realtime/voice-chat interaction. | Reused by runtime; no duplicate service. |
| `FE-API-CLIENT` | `lib/services/api_client.dart`, `lib/generated/api/` | Backend API boundary and typed client. | Reused by runtime/domain adapters; no direct provider or DTO fork. |
| `FE-LOCAL-CACHE` | `lib/services/storage_service.dart` and local stores | Display cache, preferences, recoverable local state. | Reused; no server-owned final facts. |
| `FE-LOCAL-CACHE` / stats adapter | `lib/services/app_session.dart`, `lib/application/session/session_stats_coordinator.dart`, `lib/services/stats_service.dart`, `lib/models/learning_stats_model.dart` | Practice history cache, `recordPracticeSession`, `upsertPracticeFeedback`, recent-practice merge, legacy stats sync, profile/report/home display inputs. | Reused through a runtime `PracticeHistoryRecorder` adapter; `/user/stats`, `/user/stats/session`, `/user/stats/session/feedback`, and `/user/stats/session-group/delete` remain legacy non-OpenAPI client paths until a separate API Contract increment stabilizes them. |
| `FE-TRAINING` | `lib/features/training/` | Backend-owned Training contract adapter/session loop UI. | Separate source-of-truth boundary; scenario-practice migration must not absorb it. |

## 迁移切片
| Slice | Goal | Code movement allowed in later implementation | Required gate |
| --- | --- | --- | --- |
| M0 Architecture baseline | Approve SWC IDs, data flows, file inventory, reuse/forbidden boundaries. | None in this planning increment. | Independent Software Architecture Governance Check. |
| M1 Runtime API design | Define `FE-PRACTICE-RUNTIME` public interfaces for session recovery, message loop, voice capture, TTS, feedback recorder. | Add tests and interfaces only; no route behavior change. | Flutter tests + SWC allocation update. |
| M2 Extract from application scene coordinators | Move/wrap reusable coordinator logic from `lib/application/scene/` into runtime boundary. | Adapter wrappers keep old callers working. | Existing `test/application/scene_*` plus new runtime tests. |
| M3 Rewire interview main flow | Replace page-local voice/message/recovery duplication with runtime calls. | Keep `lib/features/interview/` path and routes stable. | Interview practice regression tests. |
| M4 Freeze legacy sandbox | Add static guard / documentation and optionally rewire legacy sandbox to runtime adapters. | Maintenance only; no feature expansion. | Static architecture check and smoke test if route exists. |
| M5 Practice history adapter parity | Introduce or approve a `PracticeHistoryRecorder` adapter over `AppSession`/`SessionStatsCoordinator`; decide whether interview main flow writes stats history or documents non-goal. | Adapter-only behavior; no duplicate stats store; legacy `/user/stats*` paths stay non-OpenAPI and cannot be promoted without API contract work. | `test/application/session_stats_coordinator_test.dart` plus runtime adapter tests. |
| M6 Optional path rename | Decide whether `FE-SCENARIO-PRACTICE` needs a new physical package. | Only after runtime extraction is stable; use route-preserving adapter. | Separate migration approval. |

## 数据流摘要
完整 flow 定义以 `swc_allocation.md` 为准。实现至少必须覆盖：
- 启动或恢复 session。
- 加载 scene graph 和内容。
- Voice capture 和 ASR。
- 文本 fallback 提交。
- Message loop 以及 AI/NPC/coach response。
- TTS/playback。
- Hint request。
- Feedback/review。
- Wiki、learning memory 和 queue 更新。
- Practice history 和 stats synchronization。
- Exit、recovery 和 stale session 处理。
- Legacy sandbox 的 no-expansion 路径。

## 实现约束
- 不得在新的 feature folder 内创建第三套 runtime loop。
- 不得把 expression graph、mastery、wiki、reviewed content 或 queue 逻辑迁入 generic runtime。
- 前端不得直接调用 backend providers。
- 不得在本地创建可信 `audio_ref` 或 final mastery facts。
- 不得把 legacy sandbox models 作为 canonical Domain Schema。
- 不得让 `FE-PRACTICE-RUNTIME` 拥有产品决策；它只拥有可复用 mechanics。
- 不得创建第二套 practice history/statistics store；必须通过 adapter 复用 `AppSession`、`SessionStatsCoordinator`、`StatsService` 和 `ApiClient`，且不得把 legacy `/user/stats*` 路径视为稳定 OpenAPI。
