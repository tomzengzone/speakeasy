# Canonical Traceability

## 文档状态

- Artifact ID: `TRACEABILITY`
- Status: candidate
- Projection: `derived-read-only`

本文是从 owning sources 重建的 canonical 完整链路投影，不拥有任何直接边。若投影与源不一致，必须先修复 `STORY_MAP`、`FUNCTIONAL_REQUIREMENT_CATALOG`、适用 Engineering Contract 或 `TEST_CASE_CATALOG`，再重新生成本文；不得在这里覆盖关系。

## 派生分支

| Primary Capability | Primary Sub-capability | Story | Vertical Slice | Functional Requirement | FR-TC | FR-TC selector |
| --- | --- | --- | --- | --- | --- | --- |
| `CAP-TRAIN` | `CAP-TRAIN-06` | `US-TRAIN-001` | `VS-TRAIN-001` | `FR-TRAIN-001` | `TC-FR-TRAIN-001` | `training_recap_panel` |

| Functional Requirement | Affected Engineering Contract | Contract-TC | Contract-TC selector |
| --- | --- | --- | --- |
| `FR-TRAIN-001` | — 本次治理切换无 Engineering Contract 事实变化 | — | — |

| Vertical Slice | VS-TC | VS-TC selector |
| --- | --- | --- |
| `VS-TRAIN-001` | `TC-VS-TRAIN-001` | `training_session_view -> training_recap_panel` |

## Coverage join

`TC-VS-TRAIN-001` 通过 owning edge `VS-TRAIN-001 -> FR-TRAIN-001` 派生覆盖 `FR-TRAIN-001`；VS-TC 自身不保存 FR ID 集合。当前 projection 无悬空引用，approved VS 的 mandatory FR、FR-TC 和 VS-TC coverage 均完整。执行证据只可链接绑定 exact commit SHA 的外部测试或 CI 记录，不在本文复制易过期结果状态。
