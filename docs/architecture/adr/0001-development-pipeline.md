# ADR 0001: Project-local Codex Development Pipeline

## Status
Accepted

已接受。

## Context
The project needs a controlled software engineering workflow for Codex-assisted development. The workflow must prevent scope drift, preserve architecture decisions, and keep implementation traceable to requirements and tests.

项目需要一套受控的软件工程流程来承接 Codex 辅助开发。该流程必须防止范围漂移，保护已经做出的架构决策，并让实现能够追溯到需求和测试。

## Decision
Use project-local agents, skills, templates, and docs under `codex/` and `docs/` before promoting reusable actions to global Codex skills.

先使用 `codex/` 和 `docs/` 下的项目本地 agents、skills、templates 和文档来沉淀工作流；只有在项目内反复验证有效后，才把可复用动作提升为全局 Codex skills。

## Consequences
- Every feature starts with a feature spec and acceptance criteria.
- Cross-layer changes must update product, domain, architecture, AI runtime, tests, and reports as needed.
- Project-local skills are Markdown playbooks, not globally installed Codex skills.
- Global skills may be created later only after repeated successful project use.

- 每个 feature 都必须从 feature spec 和 acceptance criteria 开始。
- 跨层变更需要按影响范围同步更新 product、domain、architecture、AI runtime、tests 和 reports。
- 项目本地 skills 是 Markdown 形式的执行手册，不是全局安装的 Codex skills。
- 只有在项目内多次成功复用后，才考虑创建全局 skills。

## Alternatives Considered
- Global skills first: rejected because project-specific domain and architecture are still evolving.
- No formal process: rejected because AI-assisted implementation would be harder to audit.

- 先做全局 skills：拒绝，因为项目专属领域和架构仍在演进。
- 不设正式流程：拒绝，因为 AI 辅助实现会更难审计和追溯。
