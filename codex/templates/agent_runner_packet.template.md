# Project Agent Execution Packet

## Runner Contract
- The live project-local agent definition was loaded from `{{AGENT_DEFINITION_PATH}}`.
- `codex/agents/*.md` remains the only source of truth for project agent behavior.
- This packet is a handoff boundary: execute only the named agent role and only the task below.
- Do not infer permissions from previous conversation context when the loaded agent definition is stricter.
- If the task needs a downstream agent, produce the handoff artifact required by the loaded agent instead of doing the downstream work directly.

## Agent
`{{AGENT_NAME}}`

## Task
{{TASK}}

## Upstream Handoff
{{UPSTREAM_HANDOFF}}

## Required Execution Behavior
- Restate the loaded agent's task understanding before substantive work.
- Use the loaded definition's Inputs, Outputs, Allowed Paths, Process/Protocol, and Rules.
- Produce only artifacts permitted by the loaded definition.
- Preserve source-of-truth boundaries from the upstream handoff.
- For checker work, return the result values required by the loaded checker definition with concrete files and required corrections.

## Loaded Agent Definition

```markdown
{{AGENT_DEFINITION}}
```
