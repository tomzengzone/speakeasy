# ADR 0001: Project-local Codex Development Pipeline

## Status
Accepted

## Context
The project needs a controlled software engineering workflow for Codex-assisted development. The workflow must prevent scope drift, preserve architecture decisions, and keep implementation traceable to requirements and tests.

## Decision
Use project-local agents, skills, templates, and docs under `codex/` and `docs/` before promoting reusable actions to global Codex skills.

## Consequences
- Every feature starts with a feature spec and acceptance criteria.
- Cross-layer changes must update product, domain, architecture, AI runtime, tests, and reports as needed.
- Project-local skills are Markdown playbooks, not globally installed Codex skills.
- Global skills may be created later only after repeated successful project use.

## Alternatives Considered
- Global skills first: rejected because project-specific domain and architecture are still evolving.
- No formal process: rejected because AI-assisted implementation would be harder to audit.

