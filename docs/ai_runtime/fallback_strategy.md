# Fallback Strategy

## Provider Failure
- Show a short retryable error.
- Keep learner input intact.
- Do not create correction, notebook item, or review item.
- Preserve the practice session and return `recoverable_error` when the turn cannot be evaluated.

## Invalid JSON
- Attempt one repair parse if safe.
- If repair fails, return typed fallback.
- Log raw failure only in safe server logs.
- Do not persist invalid provider output as successful `CoachFeedback`.

## Low-confidence Analysis
- Ask a clarifying follow-up.
- Do not advance action step.

## User Experience Rule
Fallbacks should preserve learner progress and avoid blaming the learner.

## MVP Practice/AI Mapping
- ASR unavailable: keep the turn/session recoverable and ask the user to retry or type the answer.
- TTS/playback unavailable: return typed `provider_unavailable` without changing session state.
- Coach invalid schema: return fallback feedback with no learning evidence candidate.
- Pronunciation unavailable: return a score signal with `status = unavailable`; do not block the session.

## P0.1 Training Fallback Mapping

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

| Failure | Required behavior | Prohibited behavior |
| --- | --- | --- |
| ASR failed or transcript empty | Return `recoverable_error.code=ASR_UNAVAILABLE`, preserve audio/input refs, recommend `retry` or `text_fallback` | Mark learner answer as failed or write weak evidence |
| Microphone denied | Recommend `text_fallback` and permission recovery | Treat text fallback as default primary path |
| TTS/model audio failed | Show text prompt and typed recoverable error | Block session start if text prompt is available |
| LLM invalid JSON | Attempt safe repair once; otherwise return deterministic fallback candidate with no learning evidence candidate | Persist invalid output as successful feedback |
| LLM off-scope next action | Reject the next action and ask deterministic planner for allowed retry/fallback | Apply a next action outside planner-supplied options |
| Score unavailable | Set pronunciation signal `status=unavailable` and continue expression/task feedback | Fail the user solely because pronunciation score is absent |
| Evidence write failed | Preserve `TrainingRecap`, mark evidence write retryable | Clear recap or mark session completed without visible result |
| Provider timeout during pressure check | Return to prior valid state or retry with higher hint | Advance to cross-day schedule or L0-L5 state |

P0.1 fallback outputs are candidate-only. The deterministic planner decides whether to retry, raise hint, lower hint, enter pressure check, recap, or show fallback UI.

## DashScope Provider Adapter Fallback Mapping

Owning change request: `CR-20260601-001`。

| Provider area | Failure | Required normalized output |
| --- | --- | --- |
| Qwen LLM | timeout, unavailable, invalid JSON, schema mismatch, final mastery/billing fields | `CoachResult.feedbackType=recoverable_error`, `validationStatus=fallback`, provider status `timeout`, `provider_unavailable` or `invalid_schema`; no learning evidence candidate accepted |
| Paraformer ASR | blank/local-path `audio_ref`, unsigned HTTP media ref, no task id, failed task, empty transcript | `TranscribeResult.status=no_result`, schema/policy error, or `provider_unavailable`, transcript empty, usage reservation released |
| DashScope TTS | empty text, provider unavailable, missing audio URL | `TtsResult.status=provider_unavailable`, no session state mutation |
| Pronunciation | no selected real scoring provider | `ScoreResult.status=unavailable`, planner continues using completion/task signals |

Fallback logs must omit raw audio, provider keys and complete sensitive transcript. Observability may include provider, model, status, latency, fallback reason and schema version.
