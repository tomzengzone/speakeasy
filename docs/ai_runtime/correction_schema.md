# Correction Schema

## Correction Object

```json
{
  "type": "naturalness",
  "original": "export function has risk",
  "better": "the export feature is a bit of a risk",
  "explanation_cn": "This sounds more natural in a project update.",
  "severity": "medium",
  "can_save_to_notebook": true
}
```

## Severity
- low
- medium
- high

## Rules
- Show one main correction per learner turn.
- Prefer practical alternatives over abstract grammar lectures.
- Keep explanation short enough for mobile UI.
- If correction is saved, create or update a notebook item.

