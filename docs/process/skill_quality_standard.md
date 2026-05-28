# Skill Quality Standard

This repository uses project-local Codex development skills under `.agents/skills/`.
The goal is to make Codex act as a controlled software engineering pipeline, not as an unconstrained code generator.

## Directory Contract

Each skill must live in its own directory:

```text
.agents/skills/<skill-name>/
  SKILL.md
  SPEC.md
```

The old flat `codex/skills/*.md` layout is deprecated for active project skills and must not exist in the repository.

## Product Planning Document Paths

- Product roadmap: `docs/product/roadmap.md`
- Product development status: `docs/product/development_status.md`
- Product backlog: `docs/product/feature_backlog.md`
- Feature registry: `docs/product/feature_registry.md`
- Product baselines: `docs/product/baselines/<baseline-slug>.md`
- Stage scopes: `docs/product/stages/<stage-id>.md`
- Stable feature definition: `docs/product/features/<feature-slug>/README.md`
- Stable feature requirements: `docs/product/features/<feature-slug>/requirements.md`
- Increment definition: `docs/product/increments/<increment-id>/definition.md`
- Increment requirements: `docs/product/increments/<increment-id>/requirements.md`
- Increment specs: `docs/product/increments/<increment-id>/spec.md`
- Increment acceptance criteria: `docs/product/increments/<increment-id>/acceptance.md`
- Increment traceability: `docs/product/increments/<increment-id>/traceability.md`
- Feature requirements: `docs/product/features/<feature-slug>-requirements.md`
- Feature specs: `docs/product/features/<feature-slug>-spec.md`
- Feature acceptance criteria: `docs/product/features/<feature-slug>-acceptance.md`
- Requirement traceability matrix: `docs/product/traceability_matrix.md`

## Architecture And API Document Paths

- API contract overview: `docs/architecture/api_contract.md`
- OpenAPI source of truth: `docs/architecture/openapi/speakeasy-api.yaml`

`docs/architecture/api_contract.md` records API families, product-object traceability, unified error semantics, versioning, compatibility policy, and generation boundaries. `docs/architecture/openapi/speakeasy-api.yaml` is the only machine-readable source of truth for OpenAPI paths, components, request/response schemas, examples, and lint checks. These two documents must not duplicate ownership of implementation-level schema.

Product Manager owns roadmap, development status, and backlog priority. Requirement Development owns feature requirements, user stories, and acceptance criteria.

## Product Object Governance

Product documents must distinguish product objects before choosing a path:

- Feature: a long-lived APP capability. It belongs in the feature registry and `docs/product/features/<feature-slug>/`.
- Stage: a delivery horizon or priority window. It belongs in `docs/product/stages/<stage-id>.md`.
- Stage Scope Item: a stable, ID-addressable capability, obligation, or explicit deferral inside a stage. Active stage scope items belong in the owning stage file and use stable IDs such as `P01-SI-001`.
- Increment: a scoped delivery slice inside a stage. It belongs in `docs/product/increments/<increment-id>/`.
- Baseline: a snapshot of implemented behavior. It belongs in `docs/product/baselines/<baseline-slug>.md`.
- Change request: a scope decision record. It remains in `docs/process/change_request.md`.

Legacy flat paths such as `docs/product/features/<feature-slug>-requirements.md` remain valid for existing artifacts until migration, but new product work should prefer the object-based paths above after classification and increment definition.

Do not use a stage name, MVP baseline name, or roadmap horizon as a feature slug. A feature slug must name a stable product capability.

## Stage-To-Increment Traceability

Committed stage work must be traceable before downstream artifacts are generated:

```text
Stage Scope ID
-> Increment ID
-> Requirement ID
-> Spec section/state ID
-> Acceptance Criteria ID
-> Contract ID, when applicable
-> Work Package ID, when available
-> Code Evidence
-> Test Evidence
-> Release Evidence
```

Rules:

- Active stage files must expose scope as stable Stage Scope Item IDs and classify each item as `required`, `deferred`, or `not applicable`.
- Increment definitions must list `Covered Stage Scope Items` and `Excluded Stage Scope Items`.
- Requirement artifacts for new increment work must cite the Stage Scope Item IDs they refine.
- Specs and acceptance criteria must preserve the Stage Scope Item IDs rather than replacing them with prose-only references.
- Traceability matrices must prove 100% coverage for committed scope: every required Stage Scope Item ID is covered by an increment or has an explicit deferred/not-applicable decision, every increment requirement traces to at least one Stage Scope Item ID, every FR has at least one AC, and every AC has code/test evidence or a documented exception when implementation has started.
- Future roadmap placeholders may be traced only to feature/stage boundaries and architecture compatibility notes until Product Manager accepts them into an increment; they must not be represented as implementation-ready requirements.

## Naming

- Directory names use lowercase kebab-case.
- `SKILL.md` frontmatter `name` must exactly match the directory name.
- Names should describe one reusable action, not a role or department.
- Keep skills small enough to be executed and verified independently.

## SKILL.md Required Structure

`SKILL.md` is the runtime instruction file. It must start with YAML frontmatter:

```yaml
---
name: skill-name
description: Use when ... Do not use ...
---
```

Required sections:

- `## Overview`
- `## When to Use`
- `## When NOT to Use`
- `## Inputs`
- `## Outputs`
- `## 文档路径约定`
- `## Process`
- `## Red Flags`
- `## Verification`
- `## Common Rationalizations`

The description must contain both positive and negative trigger boundaries using the phrases `Use when` and `Do not use`.

## SPEC.md Required Structure

`SPEC.md` is the governance and maintenance contract for the skill.

Required sections:

- `## Purpose`
- `## Scope`
- `## Trigger Context`
- `## Inputs`
- `## Outputs`
- `## Quality Bar`
- `## Maintenance Notes`
- `## External References`

`SPEC.md` must explain why the skill exists, when it should be maintained, and how quality is judged.

## Trigger Quality

A high-quality skill has clear boundaries:

- `When to Use` says which work should trigger it.
- `When NOT to Use` prevents over-triggering.
- `Red Flags` identifies failure modes, scope creep, weak assumptions, and unverifiable outputs.
- `Verification` gives concrete checks that can be performed after the skill runs.

## Spec-Driven Behavior

Project skills should follow these rules:

- List assumptions before conclusions.
- Convert requirements into testable success criteria before implementation.
- Split tasks that are expected to touch more than five files.
- Prefer contract-first API and interface design.
- Require regression tests for bug fixes.
- Record validation, risks, and follow-ups in the implementation report.

## Project Agent Runner Governance

Project-local agents live in `codex/agents/*.md` and are not duplicated into static tool metadata. When a project agent is used, the execution boundary should be generated by the dynamic runner:

```bash
python scripts/project_agent_runner.py packet <agent-name> --task "<task>"
```

Quality rules:

- `codex/agents/*.md` is the only source of truth for project-local agent roles, inputs, outputs, allowed paths, protocols, and rules.
- A Project Agent Execution Packet must include the loaded definition path, the task, upstream handoff, and the full loaded definition.
- The main thread should route and integrate; the loaded agent packet should perform the specialist step.
- The next agent must consume the previous agent's handoff output instead of relying on conversational memory.
- Checker agents must review the completed step before the workflow proceeds when the task is multi-step governance, architecture, requirement, documentation, or product-object work.
- Run `python scripts/project_agent_runner.py validate` after changing `codex/agents/`, `scripts/project_agent_runner.py`, or `codex/templates/agent_runner_packet.template.md`.

## Full-Scope Planning and Architecture Governance

Broad planning skills and architecture agents must prevent partial context from being presented as full-system conclusions.

- Every broad architecture or platform strategy task must declare scope mode: `whole-app`, `stage`, `increment`, `feature`, `refactor`, or `experiment`.
- Whole-app tasks must build a source inventory before conclusions: Product Base, feature registry, roadmap, development status, active stages, planned increments, future-stage boundaries, non-goals, current code structure, existing contracts, release artifacts, and reports.
- Whole-app architecture must include a feature/stage coverage matrix mapping product capabilities to frontend, backend, data, API, AI/runtime, security, tests, release, and operations.
- Missing coverage must be classified as blocker, deferred, or not applicable. Unclassified omissions block acceptance.
- Technology recommendations must be traceable to requirements, constraints, market/common-practice option comparison, trade-offs, team/operations fit, and rollback cost.
- ADRs document accepted or proposed decisions; they must not be used to launder exploratory or incomplete architecture into source of truth.
- Any architecture artifact that fails coverage must be removed, superseded, or marked non-source-of-truth before downstream development uses it.
- Governance fixes must address the class of failure. Do not add one-off rules such as “remember P0.2”; instead add reusable coverage, traceability, and review gates.

## 文档路径治理

项目内 skill 必须让文档输入和输出位置清晰可追踪：

- 使用明确的仓库路径或路径模板，例如 `docs/product/features/<feature-slug>-spec.md`。
- 避免只写 `updated docs`、`feature-specific notes`、`report updates` 这类泛称；如果必须使用泛称，也要同时列出具体目标路径。
- 保持 `SKILL.md` 的运行时说明与 `SPEC.md` 的维护契约一致。
- 新增持久化项目文档默认使用中文，除非用户明确要求其他语言。
- 当路径不清楚或新增文档路径时，先使用 `document-path-governance` skill 做路径归属判断。
- 当问题同时涉及路径、内容契约和追踪检查，或无法判断属于哪一类治理问题时，先使用 `document-governance` 做总控路由。

## 文档治理 skill 分层

文档治理职责拆分为四个 skill：

- `document-governance`：总控路由，负责判断问题类型、拆分任务和处理跨治理冲突。
- `document-path-governance`：路径治理，负责 canonical path、owner、source of truth、路径模板、skill 输入输出路径和 agent Allowed Paths。
- `document-content-contract`：内容契约治理，负责每类文档写什么、不写什么、必需章节、禁止内容和验收检查。
- `document-traceability-check`：追踪检查，负责需求、规格、验收、契约、测试、报告和发布证据之间的链路完整性。

新增或修改文档治理规则时，应优先更新具体子 skill；只有路由和冲突处理规则才写入 `document-governance`。

## External References and Attribution

This repository borrows workflow patterns from public skill and engineering-process repositories, but does not vendor their content directly.
If external skill content is copied into this repository later, keep attribution and license information in the skill directory.

Reference sources:

- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- OpenAI Codex skill-creator sample: https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md
- addyosmani/agent-skills: https://github.com/addyosmani/agent-skills
- addyosmani documentation-and-ADRs skill: https://github.com/addyosmani/agent-skills/blob/main/skills/documentation-and-adrs/SKILL.md
- Microsoft cloud-solution-architect skill: https://github.com/microsoft/skills/tree/main/.github/skills/cloud-solution-architect
- Callstack agent-skills React Native workflow patterns: https://github.com/callstackincubator/agent-skills
- AIWG multi-agent workflow primitives: https://github.com/jmagly/aiwg
- agent-ecosystem/skill-validator: https://github.com/agent-ecosystem/skill-validator
- getsentry/skills: https://github.com/getsentry/skills

## Local Validation

Run this command after adding or editing skills:

```bash
python scripts/validate_agent_skills.py
```

The validator is intentionally lightweight. It checks required structure and basic trigger quality. Future work may integrate a full skill validator or add semantic checks.
