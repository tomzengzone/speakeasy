# Issue Management Spec

## Purpose
Provide a project-local issue management skill that creates, triages, updates, and links repository issues without turning issues into product or implementation source of truth.

## Scope
This project-local skill applies to development tracking around repository issues, pull requests, branches, status labels, and evidence links. It supports the existing Product Manager and Development Orchestrator workflow and must not silently expand product scope or bypass Definition of Done gates.

## Trigger Context
- A request needs a structured issue title/body before planning or implementation.
- A bug, follow-up, release blocker, workflow change, or implementation slice needs issue tracking.
- An existing issue needs labels, lifecycle status, source-of-truth links, PR links, or evidence links.
- Product Manager has classified a request and wants optional issue tracking for coordination.

## Inputs
- User issue request or existing issue context.
- Product Manager classification and priority decision when available.
- `docs/process/workflow.md`
- `docs/product/development_status.md`
- `docs/product/feature_registry.md`
- `docs/product/feature_backlog.md`
- `docs/product/stages/<stage-id>.md`
- `docs/product/increments/<increment-id>/`
- `docs/reports/implementation_report.md`
- `docs/reports/test_report.md`
- `docs/reports/quality_report.md`
- Existing issue, pull request, branch, CI, or release evidence links when provided.

## Outputs
- Structured issue title/body drafts.
- Issue update/comment drafts.
- Suggested labels, status, milestone, owner, and checker references.
- Branch and pull request linking guidance.
- Blocked findings when product classification or local evidence is missing.

## Quality Bar
- Issues are tracking containers only; local product artifacts remain source of truth.
- Product Manager classification and priority are required before an issue implies accepted scope or current-stage commitment.
- Every issue that represents committed work links to the owning feature, stage, increment, Stage Scope Item ID, FR, AC, TC, owner agent, and checker agent when those artifacts exist.
- `Refs` is used for planning, partial work, investigations, and blocked evidence; `Closes` is reserved for complete Definition of Done evidence.
- Labels, status, and milestone suggestions do not conflict with Product Manager decisions or workflow gates.
- The skill does not create requirements, specs, acceptance criteria, tests, implementation evidence, release evidence, or Product Base merge claims.

## Maintenance Notes
- Keep `SKILL.md` concise and operational.
- Run `python scripts/validate_agent_skills.py` after editing this skill.
- Update `docs/process/workflow.md` if the optional issue tracking step changes.
- If an issue manager agent is later added, keep this skill as the task procedure and make the agent a routing/ownership wrapper only.
- If issue templates or automation are added later, treat that as a separate workflow/governance change and validate runner/skill consistency.
- No external content is vendored in this skill; external references are used as design inspiration only.

## External References
- GitHub issue triage with AI documentation: https://docs.github.com/en/issues/tracking-your-work-with-issues/administering-issues/triaging-an-issue-with-ai
- Waypoint issue template skill pattern: https://raw.githubusercontent.com/poindexter12/waypoint/main/workflows/skills/gh-issue-templates/SKILL.md
- Waypoint issue triage skill pattern: https://raw.githubusercontent.com/poindexter12/waypoint/main/workflows/skills/gh-issue-triage/SKILL.md
- Waypoint issue lifecycle skill pattern: https://raw.githubusercontent.com/poindexter12/waypoint/main/workflows/skills/gh-issue-lifecycle/SKILL.md
- PyTorch conservative issue triage pattern: https://raw.githubusercontent.com/pytorch/pytorch/main/.claude/skills/triaging-issues/SKILL.md
