# Scene Model

## Scenario
- id
- title
- level
- category
- objective
- learner_role
- ai_role
- background
- target_expressions
- action_chain

## Action Chain Step
- id
- label
- learner_task
- success_condition
- hints
- sample_answer

## Scene Lifecycle
```text
draft -> available -> selected -> in_progress -> completed -> archived
```

## Practice State
```text
idle -> awaiting_user -> analyzing -> awaiting_ai -> feedback_shown -> completed
```

## Rules
- A scenario must have at least one objective and one action step.
- A practice session must know the current action step.
- AI should not advance the action step unless success conditions are met.

