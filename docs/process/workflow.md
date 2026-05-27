# Codex Development Workflow

## Product Planning Layer
```text
user request
-> Product Manager intake
-> product classification
-> feature registry / stage scope check
-> increment definition
-> roadmap / development status update
-> PM execution brief
```

Product Manager is the unified user-facing entry point. It decides the active stage goal, backlog priority, roadmap horizon, accepted/deferred scope, and current progress status. Users should not need to choose specialist agents directly.

## Product Object Model
```text
Feature = long-lived product capability
Product Base = living source of truth for accepted product requirements, specs, acceptance, and traceability
Stage = delivery horizon or priority window
Increment = scoped delivery slice inside a stage
Baseline = frozen snapshot of Product Base at a stage, version, release, or audit point
Change Request = decision record for scope change
Artifact = requirements, spec, acceptance, contracts, tests, reports, release evidence
```

Feature and stage are separate axes. A feature is not a stage, and a stage is not a feature. The Product Base is the living product requirement library. Requirements, specs, acceptance criteria, and traceability for accepted stable behavior live in `docs/product/base/`. Increment artifacts live in `docs/product/increments/<increment-id>/` until they are done and approved to merge back into Product Base. Baselines under `docs/product/baselines/` are frozen snapshots and must not replace Product Base.

## Execution Layer
```text
PM execution brief -> Development Orchestrator -> workflow gate check -> specialist agents -> validation evidence -> PM status update -> user summary
```

Development Orchestrator is the internal execution dispatcher. It does not decide whether a product goal is worth doing; it decides which workflow step is currently legal and necessary for approved scope.

## Standard Flow
```text
idea/change intake
-> product classification
-> feature registry / stage scope check
-> increment definition
-> requirement development
-> increment spec
-> acceptance criteria
-> architecture/domain/API/screen/AI specs
-> implementation plan
-> code
-> tests
-> review
-> report
-> product base merge when done
-> optional baseline freeze
-> release
```

Requirement Development owns requirement quality for a scoped feature or change. Development Orchestrator owns workflow routing, cross-module execution, and Definition of Done verification.

## Required Gates
1. No feature/increment document before product classification.
2. No requirements/spec/acceptance artifact before feature registry and stage scope are confirmed.
3. No implementation before increment spec.
4. No cross-layer implementation before contract updates.
5. No AI UI rendering before schema definition.
6. No completion without tests or documented test gap.
7. No release without release checklist.
8. No increment may merge into Product Base until acceptance, traceability, implementation, test, and report evidence are complete or explicitly excepted.
9. No multi-step product or documentation governance task may proceed to the next step until an independent checker agent returns a pass finding for the completed step.

## Product Classification Gate
Every incoming request must be classified before requirements or specs are created:
- `product-base-consolidation`: consolidates accepted stable product behavior into the living Product Base under `docs/product/base/`.
- `baseline-consolidation`: freezes Product Base into an implemented capability snapshot under `docs/product/baselines/`.
- `new-feature`: adds a long-lived product capability.
- `feature-increment`: changes or extends an existing feature inside a stage.
- `bugfix`: corrects existing behavior without changing product scope.
- `refactor`: changes implementation structure without changing user-visible behavior.
- `experiment`: investigates feasibility and produces findings, not delivery commitment.
- `scope-change`: changes accepted scope and requires `docs/process/change_request.md`.

The classification must identify the primary feature when one exists, affected features when multiple capabilities are touched, active stage, expected increment, and whether a change request is required.

## Increment Definition Gate
Before requirement development starts, the active increment must state:
- increment id and name
- active stage
- primary feature
- affected features
- scope and non-goals
- upstream decision source
- required downstream artifacts
- owner agent and checker agent

If the work is product-base consolidation, the artifact must update `docs/product/base/` and must only include accepted stable behavior. If the work is baseline consolidation, the artifact must be marked as a frozen baseline snapshot and must not replace the living Product Base.

## Product Base Gate
`docs/product/base/` is the living source of truth for accepted product behavior:
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`

Current MVP legacy artifacts may be migrated into Product Base only when they describe implemented or accepted stable behavior. Planned increment behavior must remain under the owning increment until it satisfies Definition of Done evidence and Product Manager approves the merge.

## Change Flow
Use `docs/process/change_request.md` when a change:
- expands MVP scope
- changes domain schema
- changes API contract
- changes AI output schema
- changes release behavior

## Agent Handoffs
- Product Manager sets roadmap priority and updates `docs/product/development_status.md`.
- Product Manager sends approved or investigatory work to Development Orchestrator using the PM execution brief in `codex/templates/pm_orchestrator_brief.template.md`.
- Product Manager owns product classification, stage scope, and increment priority.
- Requirement Development converts accepted scope into user stories, feature requirements, and acceptance criteria.
- Development Orchestrator routes the approved work through specialist agents and reports workflow progress or DoD gaps back to Product Manager.
- Product Manager is responsible for user-facing summaries, product tradeoff explanations, and development status updates after Orchestrator returns execution findings.
- Product Object Governance Change Agent applies governance rule changes one small step at a time.
- Product Object Governance Check Agent verifies each governance step before the next step starts.

## Dynamic Project Agent Runner
Project-local agents are executed through a dynamic runner contract rather than copied into static tool definitions.

```text
PM execution brief
-> scripts/project_agent_runner.py packet development_orchestrator
-> Orchestrator routing finding
-> scripts/project_agent_runner.py packet <specialist-agent>
-> specialist output
-> scripts/project_agent_runner.py packet product_object_governance_check
-> checker finding
```

Runner rules:
- The only authoritative agent definitions are `codex/agents/*.md`.
- Before a project agent runs, the runner must load the current matching markdown file and emit a Project Agent Execution Packet.
- The packet must include the user task, upstream handoff, loaded agent definition path, and full loaded definition.
- The next agent must read the previous agent's handoff output rather than reconstructing scope from memory.
- Main thread work is limited to routing, packet generation, integration, and user-facing summary unless no suitable project agent exists.
- A static multi-agent tool role such as `worker` or `default` may execute the packet, but it must not replace or override the loaded project-local agent definition.
- Validate runner integrity with `python scripts/project_agent_runner.py validate` after changing `codex/agents/`, the runner script, or the runner packet template.

## PM-Orchestrator Decision Boundary
- Product Manager answers: should this be done now, later, or not now; what is the active product stage; what is the product classification; what is in scope; what is explicitly out of scope.
- Development Orchestrator answers: what workflow gate is current; which artifact is missing; which specialist agent or skill should run next; what validation evidence is required.
- Requirement Development answers: whether accepted scope is expressed as testable requirements, user stories, and acceptance criteria.
- Specialist agents answer: how to produce their owned artifact or implementation within the approved scope.

## Governance Change Control
Changes to workflow, document categories, path rules, content contracts, traceability rules, or agent/skill governance must follow:
```text
approved remediation step
-> Product Object Governance Change Agent edit
-> Product Object Governance Check Agent finding
-> validation command when skills change
-> next step only after pass
```

The checker must verify that the edit matches the intended step, does not change product scope, does not migrate existing product artifacts unless explicitly authorized, and does not introduce a new source-of-truth conflict.

For any multi-step product, requirement, workflow, or documentation governance task, each step must follow:
```text
approved step scope
-> specialist agent edits
-> independent checker agent finding
-> next step only after pass
```

The default checker is Product Object Governance Check Agent for product-object, path, workflow, agent, or skill changes; Documentation Governance Agent may be used for pure documentation content-boundary checks.

## User Communication Rule
The user-facing response should come from the Product Manager viewpoint unless the user explicitly asks for a specialist review or implementation detail. Internally, Product Manager may consult Development Orchestrator, but the final user summary should explain product status, next step, owner, and risk in product terms.
