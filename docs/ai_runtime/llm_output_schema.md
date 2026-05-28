# LLM Output Schema

## Practice Turn Response

```json
{
  "schema_version": 1,
  "intent_covered": true,
  "current_action_step": "string",
  "stage_satisfied": false,
  "coach_reply": "string",
  "feedback": "string",
  "main_issue": {
    "type": "none",
    "original": "string",
    "better": "string",
    "explanation_cn": "string"
  },
  "saved_expression_candidates": [
    {
      "text": "string",
      "meaning_cn": "string",
      "example": "string"
    }
  ],
  "next_action": {
    "type": "continue_dialogue",
    "prompt": "string"
  },
  "score_signal": {
    "score_kind": "pronunciation",
    "value": 0.85,
    "confidence": 0.85,
    "status": "available",
    "source": "server_side_adapter"
  },
  "recoverable_error": {
    "code": "string",
    "message": "string",
    "retryable": true
  }
}
```

## Allowed `main_issue.type`
- none
- grammar
- vocabulary
- naturalness
- tone
- pronunciation
- fluency
- missing_intent
- off_topic

## Allowed `next_action.type`
- continue_dialogue
- retry
- model_then_retry
- advance_step
- complete_session
- fallback

## Validation Rules
- `schema_version` is required.
- `coach_reply` and `next_action.prompt` must not be empty.
- `main_issue.type` must be from the allowed set.
- If `main_issue.type` is not `none`, `original`, `better`, and `explanation_cn` are required.
- `score_signal.source` must be `server_side_adapter` when present.
- `recoverable_error` is allowed only with `next_action.type = fallback` or provider/schema fallback handling.
- The schema cannot write final mastery status; it may only emit candidate feedback or learning evidence candidates.
