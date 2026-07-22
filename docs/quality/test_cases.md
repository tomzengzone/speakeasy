# 分层测试用例目录

## 文档状态

- Artifact ID: `TEST_CASE_CATALOG`
- Status: candidate

本目录保存稳定的测试意图和 oracle，不保存运行时 `passed` / `failed` 状态。三类 TC 的直接上游互斥：FR-TC 只使用 `source_fr_id`，Contract-TC 只使用 `source_contract_id`，VS-TC 只使用 `source_vs_id`。跨层覆盖由 `TRACEABILITY` 从 owning sources 派生，不在 TC 中重复维护。

当前用例仅为已批准 `VS-TRAIN-001` 及其 mandatory FR 建立治理目录关系，不实施产品行为，也不声明旧测试或旧产品文档已完成迁移。

## FR-TC

### TC-FR-TRAIN-001 — 训练闭环展示快速验证

- type: `FR-TC`
- source_fr_id: `FR-TRAIN-001`
- layer: `widget`
- scope: `CAP-TRAIN/CAP-TRAIN-06`
- selector: `training_recap_panel`
- script_path: `test/features/training/training_recoverable_failure_test.dart`
- command: `flutter test test/features/training/training_recoverable_failure_test.dart`
- Given: 学习者已进入当前官方场景的语音训练，训练可以完成或返回无可用结果的可恢复状态。
- When: 学习者触发本轮结束动作。
- Then: 可用结果展示本轮练习总结和后续学习入口；失败或无可用结果展示可恢复错误或空状态，且不错误推进进度。
- Boundary/negative: 缺失结果不得生成总结结论，也不得把失败状态显示为已完成进度。

## Contract-TC

当前 PR-003 仅切换治理 lineage/provenance，不改变 API、Domain、Persistence、AI 或 UX Contract 事实，因此没有新增受影响 Contract，也没有新增 Contract-TC。后续 Contract 事实变更必须在同一变更中添加只含 `source_contract_id` 的 Contract-TC。

## VS-TC

### TC-VS-TRAIN-001 — 官方场景练习结束全链路验证

- type: `VS-TC`
- source_vs_id: `VS-TRAIN-001`
- layer: `integration-e2e`
- scope: `selected VS user-visible training loop`
- selector: `training_session_view -> training_recap_panel`
- script_path: `integration_test/p0_1_training_loop_test.dart`
- command: `flutter test integration_test/p0_1_training_loop_test.dart`
- Given: 学习者选择官方场景并进入当前一轮语音练习，实际受影响的训练服务、API、客户端状态和 UI 可用。
- When: 学习者完成或结束当前一轮练习。
- Then: 用户界面展示本轮总结、关键反馈、进度变化和后续学习入口。
- Boundary/negative: 服务不可用、结束失败或无可用结果时，用户看到可恢复的错误或空状态；进度不得被错误推进。

## 维护规则

- 每条 approved FR 必须有最低成本的 FR-TC；例外必须记录 owner、原因、影响和失效期限。
- 每个实施中的 VS 必须有一个用户可感知的 integration/E2E VS-TC。
- Contract 事实变化必须新增或更新对应 Contract-TC，并选择 contract、integration、migration 或 AI-eval 等适用层级。
- selector、脚本路径和命令是可执行定位信息；运行结果由绑定 exact commit SHA 的测试或 CI 系统保存。
