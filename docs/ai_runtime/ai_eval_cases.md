# AI Evaluation Cases

## Case Format

```json
{
  "id": "case_001",
  "scenario": "job_interview_status_update",
  "input": {
    "action_step": "flag_risks",
    "learner_turn": "export function has risk"
  },
  "expected": {
    "valid_json": true,
    "main_issue_type": "naturalness",
    "next_action_type": "continue_dialogue"
  }
}
```

## MVP Cases
- Learner gives a clear but unnatural answer.
- Learner gives a grammatically wrong answer.
- Learner is off-topic.
- Learner answer is too short.
- Learner completes the action step.
- Provider returns invalid JSON.

## MVP Backend Practice/AI Cases
| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-MVP-BE-001 | `mvp-backend-practice-ai` | Valid interview answer with one naturalness issue | Valid JSON, `feedback_type=next_question`, score signal includes `source=server_side_adapter`, evidence remains candidate-only. |
| AI-EVAL-MVP-BE-002 | `mvp-backend-practice-ai` | Off-topic answer | Valid JSON, `main_issue.type=off_topic`, next action asks retry, no mastery update. |
| AI-EVAL-MVP-BE-003 | `mvp-backend-practice-ai` | Provider invalid schema | Fallback output, `recoverable_error.retryable=true`, no successful feedback or evidence candidate. |
| AI-EVAL-MVP-BE-004 | `mvp-backend-practice-ai` | ASR unavailable for audio-only turn | Session preserved as recoverable, learner input/audio ref retained, no pseudo success feedback. |

## P0.1 Training AI Eval Cases

Executable validator:

```bash
dart run scripts/check_ai_eval_cases.dart
```

Fixture: `tests/ai_runtime/p0_1_ai_eval_cases.json`。

Scope: TC-P01-014 validates the documented P0.1 `TrainingFeedbackCandidate` AI eval cases by calling the runtime schema validator in `lib/features/training/training_contract.dart`。The validator checks all seven P0.1 cases below, planner-approved next actions, recoverable fallback behavior, pressure prompt gating, candidate-only learning evidence, pronunciation-unavailable continuation and prohibited final mastery/billing/review fields。Official scenario/version allowlist is owned by backend Training content mapping; the Flutter schema validator must not hard-code the two original scenes.

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P01-001 | `p0-1-expression-automation-training` | `job_interview`, `SayOne`, sentence-frame hint, learner covers opening intent with slightly unnatural wording | Valid `TrainingFeedbackCandidate`; `completion_signal.status=met` or `partial`; one concise naturalness suggestion; evidence remains `candidate`; no final mastery. |
| AI-EVAL-P01-002 | `p0-1-expression-automation-training` | `ChooseOne`, learner chooses option that misses the intent | Valid schema; `task_signal.status=not_met`; `recommended_next_action.type=retry` or `raise_hint`; no pressure prompt. |
| AI-EVAL-P01-003 | `p0-1-expression-automation-training` | `ShadowOne`, pronunciation score unavailable but transcript is acceptable | Valid schema; `pronunciation_signal.status=unavailable`; feedback continues; user is not failed solely due to missing score. |
| AI-EVAL-P01-004 | `p0-1-expression-automation-training` | ASR failure with audio ref and no transcript | Recoverable fallback candidate; `recommended_next_action.type=retry` or `text_fallback`; no weak evidence candidate. |
| AI-EVAL-P01-005 | `p0-1-expression-automation-training` | Consecutive success context with planner allowing pressure check | Valid schema; may include `pressure_prompt_candidate.enabled=true` only with `recommended_next_action.type=pressure_check`; prompt stays in current session/scenario. |
| AI-EVAL-P01-006 | `p0-1-expression-automation-training` | LLM attempts to output `mastered=true` or a cross-day schedule | Validation rejects or strips prohibited fields; deterministic fallback returns candidate-only feedback. |
| AI-EVAL-P01-007 | `p0-1-expression-automation-training` | Future/custom scene id with invented target expression/action step | Validation fails for invented action-chain step or micro-action; scene officialness is fail-closed by backend scenario/version/mapping, not a Flutter two-scene allowlist. |

## P0.2 Followup-B AI Eval Cases

Status: planned contract only. This section documents AI eval coverage required before implementation; it does not create executable `tests/ai_eval/` fixtures in this step.

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

Traceability:
- `AC-P02-FUB-007`
- `AC-P02-FUB-008`
- `TC-P02-FUB-014` primary AI eval
- `TC-P02-FUB-015` supporting replay-input coverage only

Planned validator target: backend/runtime schema validator for `FollowupBMasteryTransitionExplanationCandidate` plus deterministic fallback handling. The validator must reject forbidden persistent fields before any AI candidate can be rendered or associated with a `MasteryTransitionDecision`.

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P02-FUB-001 | `p0-2-followup-b-autopilot-control-planner-memory` | Deterministic `MasteryTransitionDecision` promotes L2 -> L3 with accepted evidence refs, medium confidence and no official-score claim | Valid `followup_b_mastery_transition_explanation_candidate`; explanation is concise, product-internal, candidate-only and does not create final mastery or review schedule. |
| AI-EVAL-P02-FUB-002 | `p0-2-followup-b-autopilot-control-planner-memory` | Deterministic decision holds L2 because evidence is low confidence or partial support | Valid candidate explains hold conservatively; no forced promotion, goal completion claim or high-confidence wording. |
| AI-EVAL-P02-FUB-003 | `p0-2-followup-b-autopilot-control-planner-memory` | Repeated failure/retrieval regression produces deterministic demotion or hold | Valid candidate explains risk using safe reason code; does not blame provider/ASR failure or expose raw transcript. |
| AI-EVAL-P02-FUB-004 | `p0-2-followup-b-autopilot-control-planner-memory` | Malicious/invalid provider output includes `final_mastery_level`, `review_due_at`, `notification_schedule`, `goal_completed` or `official_score` | Schema validation rejects or ignores candidate for persistence; deterministic fallback uses `MasteryTransitionDecision.reason_code`; no state mutation. |
| AI-EVAL-P02-FUB-005 | `p0-2-followup-b-autopilot-control-planner-memory` | Provider output exposes raw transcript, raw audio ref, provider payload, provider name or sensitive diagnostic detail | Candidate is rejected; fallback explanation is rendered from redacted deterministic facts only; logs omit sensitive raw content. |
| AI-EVAL-P02-FUB-006 | `p0-2-followup-b-autopilot-control-planner-memory` | Provider timeout or unavailable during explanation generation | Deterministic fallback explanation is returned; existing transition and replay audit remain unchanged; no duplicate transition record. |
| AI-EVAL-P02-FUB-007 | `p0-2-followup-b-autopilot-control-planner-memory` | Replay fixture reuses the same transition input, reason code and rule version | Deterministic replay compares decision, reason code, output state and rule version; candidate prose is not treated as source-of-truth evidence. |

Forbidden-field assertion for `TC-P02-FUB-014`: every AI eval case that contains a forbidden persistent field must fail schema validation or be stripped before rendering, and must not update `MasteryTransitionDecision`, `MemoryItemPolicyState`, `NotificationOutboxRecord`, `UserAutopilotControl`, `RecoveryPlanDecision` or any review schedule.
