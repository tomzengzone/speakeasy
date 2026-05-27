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

