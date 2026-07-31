# 结构变更门

只有新增、边界变更、拆分、合并、弃用或归属未确定的工作才可以读取本 reference。

## Gate A 证据

- `new-capability` 和 `new-sub-capability` 必须具有临时 ID；新的 Sub-capability 还必须具有父级 ID。
- 现有对象变更必须具有目标类型、目标 ID 和变更模式。
- `story-slice`、`stage-increment` 和 `technical-support-object` 在交接后停止；`insufficient-information` 返回缺失事实。
- 纯编辑和仅 legacy-mapping 工作没有创建或重新分类业务对象，因此 Gate A/Gate B 可以记录为 `N/A`。
- PM 已确认的现有对象边界变更可以复用其归属确认，但仍必须运行匹配的 Gate B。

## Gate B 证据

- Capability 比较必须按照结果、持有职责、排除范围和相邻关系覆盖最接近的两个顶层候选对象。
- Sub-capability 比较必须按照结果、职责、排除范围、入口和输出覆盖父级适配性及最接近的同级对象。少于两个同级对象时，必须记录比较缺口。
- Gate B 失败时必须返回修正项或重新考虑 Gate A；不得持久化记录，也不得改变 PM 已确认的归属。

## 身份和生命周期

必须使用 `CAP-<PREFIX>` 和 `CAP-<PREFIX>-<NN>`。除非 PM 记录原因，否则相邻关系必须双向。映射表达边界/分类，不表达行为。

模式为 `editorial`、`boundary-change`、`add`、`split`、`merge` 和 `deprecate`。非编辑类发现项必须列出受影响记录、相邻关系、下游引用、遗漏范围和身份转换。已发布身份不得静默消失。如果 schema 无法安全表示后继对象或 lifecycle，必须返回非持久化的 `schema governance required` 发现项；不得将其编码到 legacy mapping 或自由文本中。

在 canonical schema 支持 lifecycle 和后继身份之前，拆分、合并和弃用必须保持 fail-closed。可以起草候选后继对象分析，但不得持久化。

## 证据与 Gate 结果的区分

Gate A、PM 归属确认、Gate B、草案记录、PM 最终批准、确定性校验和任何 `G-INDEPENDENT-CHECK` 结果必须保持为不同结果。registry 只存储已批准事实；除非匹配的 contract 明确要求持久记录，否则详细发现项保持临时状态。
