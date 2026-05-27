# Review Model

## ReviewItem
- id
- user_id
- source_type
- source_id
- prompt_type
- prompt
- answer
- due_at
- interval_days
- mastery_score
- status

## Prompt Types
- flashcard
- multiple_choice
- fill_blank
- speaking_challenge

## Lifecycle
```text
created -> due -> completed -> rescheduled
created -> dismissed
```

## MVP Scheduling Rule
- Correct answer increases mastery score.
- Incorrect answer lowers mastery score and shortens next interval.
- The exact scheduling algorithm can remain simple in MVP.

