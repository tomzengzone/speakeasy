# Traceability：商业化订阅上线准备

## 状态
Draft - 增量级需求、规格、验收和下游证据追溯矩阵。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.2-stage-scope-id-migration |
| Last updated | 2026-05-28 |
| Owner | Product Manager Agent |
| Scope change | 无。本次只建立 Stage Scope ID 到 FR/Spec/AC/证据的结构化追溯，不新增产品范围。 |
| Workflow state | Pre-implementation / contract gaps open；Domain/API/Architecture/UX/QA/DevOps/implementation/test/release evidence 未完成。 |

## 上游
- Definition：`docs/product/increments/commercial-subscription-readiness/definition.md`
- Requirements：`docs/product/increments/commercial-subscription-readiness/requirements.md`
- Spec：`docs/product/increments/commercial-subscription-readiness/spec.md`
- Acceptance：`docs/product/increments/commercial-subscription-readiness/acceptance.md`

## Full Traceability Matrix

| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| COM-TR-001 | COM-SI-001 | commercial-subscription-readiness | FR-COM-001 服务端订阅权益事实 | COM-SPEC-001 | AC-COM-001, AC-COM-005, AC-COM-006 | Domain/API/Architecture evidence pending | 待实现 | 待生成 | Not started | Planned | COM-GAP-001, COM-GAP-002, COM-GAP-003, COM-GAP-007, COM-GAP-008 |
| COM-TR-002 | COM-SI-002 | commercial-subscription-readiness | FR-COM-002 Apple 订阅校验 | COM-SPEC-002 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005 | Domain/API/Architecture evidence pending；需 Apple sandbox/config evidence | 待实现 | 待生成；需沙盒验收 | Not started | Planned | COM-GAP-001, COM-GAP-002, COM-GAP-003, COM-GAP-007, COM-GAP-008, COM-GAP-010 |
| COM-TR-003 | COM-SI-003 | commercial-subscription-readiness | FR-COM-003 Android 订阅闭环 | COM-SPEC-003 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005 | Domain/API/Architecture evidence pending；需 Google Play config evidence | 待实现 | 待生成；需 Google Play 内测验收 | Not started | Planned | COM-GAP-001, COM-GAP-002, COM-GAP-003, COM-GAP-007, COM-GAP-008, COM-GAP-010 |
| COM-TR-004 | COM-SI-004 | commercial-subscription-readiness | FR-COM-004 生产账号体系 | COM-SPEC-004 | AC-COM-008 | Domain/API/Architecture/DevOps evidence pending | 待实现 | 待生成 | Not started | Planned | COM-GAP-001, COM-GAP-002, COM-GAP-003, COM-GAP-006, COM-GAP-007, COM-GAP-008 |
| COM-TR-005 | COM-SI-005 | commercial-subscription-readiness | FR-COM-005 社交登录生产配置 | COM-SPEC-005 | AC-COM-009 | Architecture/DevOps/platform config evidence pending | 待实现 | 待生成；需平台配置验收 | Not started | Planned | COM-GAP-003, COM-GAP-006, COM-GAP-007, COM-GAP-008, COM-GAP-010 |
| COM-TR-006 | COM-SI-006 | commercial-subscription-readiness | FR-COM-008 账号注销与数据删除 | COM-SPEC-006 | AC-COM-010 | Domain/API/Architecture/UX evidence pending | 待实现 | 待生成 | Not started | Planned | COM-GAP-001, COM-GAP-002, COM-GAP-003, COM-GAP-004, COM-GAP-007, COM-GAP-008 |
| COM-TR-007 | COM-SI-007 | commercial-subscription-readiness | FR-COM-006 商业权益 gating | COM-SPEC-007 | AC-COM-006, AC-COM-012 | Domain/API/Architecture/UX evidence pending | 待实现 | 待生成 | Not started | Planned | COM-GAP-001, COM-GAP-002, COM-GAP-003, COM-GAP-004, COM-GAP-007, COM-GAP-008 |
| COM-TR-008 | COM-SI-008 | commercial-subscription-readiness | FR-COM-007 官方场景库 gating | COM-SPEC-008 | AC-COM-007 | UX/API/Architecture evidence pending | 待实现 | 待生成 | Not started | Planned | COM-GAP-002, COM-GAP-003, COM-GAP-004, COM-GAP-007, COM-GAP-008 |
| COM-TR-009 | COM-SI-009 | commercial-subscription-readiness | FR-COM-009 商业文案一致性 | COM-SPEC-009 | AC-COM-011 | UX/Release evidence pending | 待实现 | 待生成；需人工文案验收 | Not started | Planned | COM-GAP-004, COM-GAP-006, COM-GAP-007, COM-GAP-008 |
| COM-TR-010 | COM-SI-010 | commercial-subscription-readiness | FR-COM-010 AI 成本与滥用控制 | COM-SPEC-010 | AC-COM-012 | Architecture/API/AI runtime evidence pending | 待实现 | 待生成 | Not started | Planned | COM-GAP-002, COM-GAP-003, COM-GAP-007, COM-GAP-008 |
| COM-TR-011 | COM-SI-011 | commercial-subscription-readiness | FR-COM-011 商业边界测试 | COM-SPEC-011 | AC-COM-013 | QA/Test Plan evidence pending | 不适用 | 待生成 QA 记录 | Not started | Planned | COM-GAP-005, COM-GAP-008 |
| COM-TR-012 | COM-SI-012 | commercial-subscription-readiness | FR-COM-012 发布门禁 | COM-SPEC-012 | AC-COM-014 | DevOps/Release evidence pending | 待实现 release gates | 待生成 release 验收 | Not started | Planned | COM-GAP-006, COM-GAP-007, COM-GAP-008, COM-GAP-010 |

## Gap Register
| Gap ID | Gap | Affected traceability rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| COM-GAP-001 | Domain Schema for subscription, entitlement, purchase, refund, grace period, usage, account deletion, and audit objects is missing. | COM-TR-001, COM-TR-002, COM-TR-003, COM-TR-004, COM-TR-006, COM-TR-007 | Domain Schema Agent / domain-model-generate | Open |
| COM-GAP-002 | API Contract for entitlements, receipt/token validation, restore purchase, account deletion, usage query, and usage decrement is missing. | COM-TR-001, COM-TR-002, COM-TR-003, COM-TR-004, COM-TR-006, COM-TR-007, COM-TR-008, COM-TR-010 | System Architect / api-contract-generate | Open |
| COM-GAP-003 | Architecture/Security design for service-side entitlement truth, payment boundary, secrets, cost control, deletion, and audit is missing. | COM-TR-001 through COM-TR-008, COM-TR-010 | System Architect | Open |
| COM-GAP-004 | UX/Screen Spec for paywall, restore purchase, downgrade, account deletion, copy consistency, and gating states is missing. | COM-TR-006, COM-TR-007, COM-TR-008, COM-TR-009 | UX Review / screen-spec-generate | Open |
| COM-GAP-005 | QA/Test Plan and commercial boundary test matrix are missing. | COM-TR-011 | QA / test-case-generate | Open |
| COM-GAP-006 | DevOps/Release plan for stores, secrets, signing, symbols, review material, and rollback is missing. | COM-TR-004, COM-TR-005, COM-TR-009, COM-TR-012 | DevOps Agent | Open |
| COM-GAP-007 | Implementation has not started for commercial readiness behavior. | COM-TR-001 through COM-TR-010, COM-TR-012 | Backend / Frontend / DevOps as routed | Open |
| COM-GAP-008 | Automated/manual test evidence has not been generated. | COM-TR-001 through COM-TR-012 | QA / test-case-generate | Open |
| COM-GAP-009 | Implementation, test, and quality reports have not been updated for completed work. | All rows after implementation starts | Implementation Report / QA / Documentation Governance | Open |
| COM-GAP-010 | External platform configuration evidence for Apple, Google Play, social login, and store review is missing. | COM-TR-002, COM-TR-003, COM-TR-005, COM-TR-012 | DevOps / Release owner | Open |

## Required Downstream Evidence
- Domain Schema：待创建或更新。
- API Contract：待创建或更新。
- Architecture / Security：待创建或更新。
- UX / Screen Spec：待创建或更新。
- QA / Test Plan：待创建或更新。
- DevOps / Release：待创建或更新。
- Implementation Report：待实现后更新。
- Test Report：待测试后更新。
- Quality Report：待质量复审后更新。
