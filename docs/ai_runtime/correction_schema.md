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

- 每个 learner turn 只展示一个主纠错点。
- 优先给出可直接使用的替代表达，而不是抽象的语法讲解。
- 解释要足够短，适合移动端 UI 展示。
- 如果纠错被保存，则创建或更新一个 notebook item。
