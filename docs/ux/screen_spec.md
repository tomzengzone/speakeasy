# Screen Spec

## Required Screen Spec Fields
Every new screen must define:
- purpose
- entry points
- primary user action
- core components
- states
- API dependencies
- empty state
- loading state
- error state
- analytics or logging events if needed
- acceptance criteria mapping

## MVP Screens

### Scenario List
- Purpose: choose a scenario.
- States: loading, loaded, empty, error.
- Primary action: open scenario detail or practice.

### Practice
- Purpose: complete a guided scenario.
- States: idle, submitting, analyzing, feedback_shown, retry_needed, completed, error.
- Primary action: submit learner turn.

### Notebook
- Purpose: review saved expressions.
- States: empty, loaded, deleting, error.
- Primary action: open saved expression.

### Review
- Purpose: complete due review tasks.
- States: due, answering, completed, empty.
- Primary action: submit review answer.

