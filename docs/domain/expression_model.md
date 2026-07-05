# Expression Model

## TargetExpression
- id
- text
- meaning_cn
- usage_note
- level
- tags
- source_scenario_id

## Saved Expression
- id
- user_id
- expression_text
- normalized_text
- meaning_cn
- example
- source_type
- source_id
- created_at

## Rules
- Normalize expression text before duplicate checks.
- Keep user notes separate from authored expression metadata.
- Saved expressions can generate review items.

- 重复检查前必须先规范化表达文本。
- 用户笔记必须与官方编写的表达元数据分离。
- SavedExpression 可以按规则生成 ReviewItem。
