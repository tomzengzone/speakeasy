# Canonical Traceability

## 文档状态

- Artifact ID: `TRACEABILITY`
- Status: candidate
- Projection: `derived-read-only`

本文是从 owning sources 重建的 canonical 完整链路投影，不拥有任何直接边。若投影与源不一致，必须先修复 `STORY_MAP`、`FUNCTIONAL_REQUIREMENT_CATALOG`、适用 Engineering Contract 或 `TEST_CASE_CATALOG`，再重新生成本文；不得在这里覆盖关系。

## 派生分支

| Story | Vertical Slice | Functional Requirement | FR-TC | FR-TC selector |
| --- | --- | --- | --- | --- |
| `US-TRAIN-001` | `VS-TRAIN-001-1` | `FR-TRAIN-001` | `TC-FR-TRAIN-001` | `training_recap_panel` |
| `US-CONTENT-001` | `VS-CONTENT-001-1` | `FR-CONTENT-001` | `TC-FR-CONTENT-001` | `content_theme_catalog -> selected_theme_course_summaries` |
| `US-CONTENT-002` | `VS-CONTENT-002-1` | `FR-CONTENT-002` | `TC-FR-CONTENT-002` | `course_card -> course_detail_header` |

| Functional Requirement | Affected Engineering Contract | Contract-TC | Contract-TC selector |
| --- | --- | --- | --- |
| `FR-TRAIN-001` | — 本次治理切换无 Engineering Contract 事实变化 | — | — |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `DOMAIN_SCHEMA`; `ENTITY_RELATIONSHIP`; `DOMAIN_MODEL` (`training_model.md`, `content_model.md`); `OPENAPI` (`LevelCode`; Course catalog 与 version-pinned detail paths/schemas machine boundary) | — 通过下列 `API_CONTRACT` 分支派生覆盖 | — |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-001` | `CONTENT-CEFR-API-001 -> CefrLevelContractTest` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-002` | `CONTENT-CEFR-API-001 -> V202608050001__strict_cefr_level_cutover.sql` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-003` | `CONTENT-CEFR-API-001 -> scene phases/tracks/levelMap/nodes/references` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-004` | `CONTENT-CEFR-API-001 -> LevelCode enum and OpenAPI hash` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-005` | `CONTENT-CEFR-API-001 -> GoalMasteryLevel and hint ladder` |
| `FR-CONTENT-001`, `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-CEFR-API-001`) | `TC-CONTRACT-CONTENT-CEFR-006` | `CONTENT-CEFR-API-001 -> storage migration v2` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-001` | `CONTENT-COURSE-CATALOG-API-001/scenario-all` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-002` | `CONTENT-COURSE-CATALOG-API-001/course-list` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-005` | `CONTENT-COURSE-CATALOG-API-001/binding-integrity` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-006` | `CONTENT-COURSE-CATALOG-API-001/schema-and-errors` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-007` | `CONTENT-COURSE-CATALOG-API-001/privacy-visibility` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-008` | `CONTENT-COURSE-CATALOG-API-001/private-etag` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-009` | `CONTENT-COURSE-CATALOG-API-001/generated-drift` |
| `FR-CONTENT-001` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-010` | `CONTENT-COURSE-CATALOG-API-001/compatibility-rollback` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-003` | `CONTENT-COURSE-CATALOG-API-001/course-detail` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-004` | `CONTENT-COURSE-CATALOG-API-001/exact-version` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-005` | `CONTENT-COURSE-CATALOG-API-001/binding-integrity` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-006` | `CONTENT-COURSE-CATALOG-API-001/schema-and-errors` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-007` | `CONTENT-COURSE-CATALOG-API-001/privacy-visibility` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-008` | `CONTENT-COURSE-CATALOG-API-001/private-etag` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-009` | `CONTENT-COURSE-CATALOG-API-001/generated-drift` |
| `FR-CONTENT-002` | `API_CONTRACT` (`CONTENT-COURSE-CATALOG-API-001`) | `TC-CONTRACT-CONTENT-COURSE-010` | `CONTENT-COURSE-CATALOG-API-001/compatibility-rollback` |

| Vertical Slice | VS-TC | VS-TC selector |
| --- | --- | --- |
| `VS-TRAIN-001-1` | `TC-VS-TRAIN-001-1` | `training_session_view -> training_recap_panel` |
| `VS-CONTENT-001-1` | `TC-VS-CONTENT-001-1` | `content_asset_entry -> theme_card -> course_summary_list` |
| `VS-CONTENT-002-1` | `TC-VS-CONTENT-002-1` | `course_summary_card -> course_detail_header` |

## Coverage join

`TC-VS-TRAIN-001-1`、`TC-VS-CONTENT-001-1` 与 `TC-VS-CONTENT-002-1` 分别通过当前存在的 VS-to-FR 分支派生覆盖 `FR-TRAIN-001`、`FR-CONTENT-001` 与 `FR-CONTENT-002`；VS-TC 自身不保存 FR ID 集合。`CONTENT-CEFR-API-001` 的六条 Contract-TC 形成严格 CEFR API、服务端持久化迁移、内容资产、OpenAPI/client drift、mastery/hint namespace 与 Flutter 本地数据清理的派生 contract coverage。`CONTENT-COURSE-CATALOG-API-001` 的 `TC-CONTRACT-CONTENT-COURSE-001`、`002` 覆盖 `FR-CONTENT-001` 的主题全集与课程摘要集合，`TC-CONTRACT-CONTENT-COURSE-003`、`004` 覆盖 `FR-CONTENT-002` 的课程详情与精确版本解析，`TC-CONTRACT-CONTENT-COURSE-005` 至 `010` 共同覆盖两条 FR 的 binding 完整性、成功/错误 schema、隐私可见性、私有 ETag、generated drift 与兼容回滚边界。当前 projection 无悬空引用，已登记 FR 的直接 VS lineage 与 FR-TC coverage、approved VS 的 VS-TC coverage、以及受影响 Engineering Contract 的 Contract-TC coverage 均完整。没有 FR 时不生成 FR、FR-TC 或对应 coverage join。执行证据只可链接绑定 exact commit SHA 的外部测试或 CI 记录，不在本文复制易过期结果状态。
