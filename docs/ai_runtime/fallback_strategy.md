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
