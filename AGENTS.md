# Speakeasy Codex Working Agreement

## Default execution path

- Prefer the shortest safe path: inspect the relevant code, make the smallest scoped change, run targeted validation, and report the result.
- Use the root Codex session for ordinary analysis, bug fixes, local refactors, and other single-owner work.
- Delegate only when a specialist boundary, independent review, or genuinely parallel task materially improves correctness or speed.
- Keep delegation depth to one level. Do not create a chain of agents for work one agent can complete safely.

## 主 Agent 委派契约

在委派前，主 Agent 必须：

1. 明确用户目标、任务类型、受影响领域和 owning authority。
2. 检查工作区重叠、并行 Agent 和外部状态风险。
3. 判断是否确实需要委派；单一责任任务默认由主 Agent 完成。
4. 为每个子 Agent 指定目标、允许范围、禁止范围、交付物、验证责任和停止条件。
5. 在委派说明中明确要求子 Agent：发现范围外影响时必须返回主 Agent，不得自行扩展。

## Specialist routing

- Route stable product scope and product-object decisions to `product_manager`.
- Route architecture boundaries, public API direction, persistence topology, cross-layer design, and significant technical trade-offs to `system_architect`.
- Route implementation to the matching `backend`, `frontend`, `ai_runtime`, or `devops` specialist when that specialization is useful.
- Route domain artifacts, requirements, test design, UX, QA evidence, and documentation governance to their matching specialist only when those artifacts actually change.
- Use `product_object_governance_check` and `software_architecture_governance_check` only for applicable independent semantic review. Review agents remain read-only.

## Skills and governance

- Skills are task methods, not permanent agent attachments. Load only a skill whose description matches the requested output.
- `docs/process/governance/index.json` is the authority for governed artifact paths, owners, contributor scope, lifecycle, and Gate routing.
- Read only the relevant Artifact or Gate record when a task changes a durable governed fact or crosses a declared risk boundary.
- For product implementation, keep the default coding context to the selected approved VS, any applicable approved FR and FR-TC when present, affected Engineering Contracts and Contract-TCs, the VS-TC, adjacent code/tests, and validation commands.
- Code-only fixes, behavior-preserving refactors, UI polish, and read-only analysis do not require new governance documents unless their actual impact triggers an applicable Artifact or Gate.
- Preserve existing upstream facts. Update only the owning canonical artifact and only when its durable content changes.

## Change and verification discipline

- Preserve unrelated worktree changes and stay within the user-approved scope.
- Do not copy procedure text across agent, skill, workflow, and governance definitions. Keep each rule at its owning authority.
- Keep active agent and skill definitions limited to reusable current-state instructions and active obligations.
- Run the narrowest relevant tests first, then the applicable repository validators. Tests are evidence, not a substitute for an independent review when one is required.
- Persistent reports are written only when the applicable contract or user request requires them; otherwise findings and handoffs remain in the task response.
