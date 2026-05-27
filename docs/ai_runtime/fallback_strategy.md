# Fallback Strategy

## Provider Failure
- Show a short retryable error.
- Keep learner input intact.
- Do not create correction, notebook item, or review item.

## Invalid JSON
- Attempt one repair parse if safe.
- If repair fails, return typed fallback.
- Log raw failure only in safe server logs.

## Low-confidence Analysis
- Ask a clarifying follow-up.
- Do not advance action step.

## User Experience Rule
Fallbacks should preserve learner progress and avoid blaming the learner.

