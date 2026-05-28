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
