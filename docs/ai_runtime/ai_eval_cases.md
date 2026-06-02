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

Scope: TC-P01-014 validates the documented P0.1 `TrainingFeedbackCandidate` AI eval cases by calling the runtime schema validator in `lib/features/interview/interview_training_agent.dart`。The validator checks all seven P0.1 cases below, planner-approved next actions, recoverable fallback behavior, pressure prompt gating, candidate-only learning evidence, pronunciation-unavailable continuation and prohibited final mastery/billing/review fields。

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P01-001 | `p0-1-expression-automation-training` | `job_interview`, `SayOne`, sentence-frame hint, learner covers opening intent with slightly unnatural wording | Valid `TrainingFeedbackCandidate`; `completion_signal.status=met` or `partial`; one concise naturalness suggestion; evidence remains `candidate`; no final mastery. |
| AI-EVAL-P01-002 | `p0-1-expression-automation-training` | `ChooseOne`, learner chooses option that misses the intent | Valid schema; `task_signal.status=not_met`; `recommended_next_action.type=retry` or `raise_hint`; no pressure prompt. |
| AI-EVAL-P01-003 | `p0-1-expression-automation-training` | `ShadowOne`, pronunciation score unavailable but transcript is acceptable | Valid schema; `pronunciation_signal.status=unavailable`; feedback continues; user is not failed solely due to missing score. |
| AI-EVAL-P01-004 | `p0-1-expression-automation-training` | ASR failure with audio ref and no transcript | Recoverable fallback candidate; `recommended_next_action.type=retry` or `text_fallback`; no weak evidence candidate. |
| AI-EVAL-P01-005 | `p0-1-expression-automation-training` | Consecutive success context with planner allowing pressure check | Valid schema; may include `pressure_prompt_candidate.enabled=true` only with `recommended_next_action.type=pressure_check`; prompt stays in current session/scenario. |
| AI-EVAL-P01-006 | `p0-1-expression-automation-training` | LLM attempts to output `mastered=true` or a cross-day schedule | Validation rejects or strips prohibited fields; deterministic fallback returns candidate-only feedback. |
| AI-EVAL-P01-007 | `p0-1-expression-automation-training` | Non-P0.1 scene id or invented target expression | Validation fails; output cannot create session, scene, target expression or action chain step. |
