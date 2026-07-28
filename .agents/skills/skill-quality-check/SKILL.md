---
name: skill-quality-check
description: Use when：项目本地 Skill 定义、直接链接的 Skill 资源、Skill 质量标准或 Skill validator 发生变更，并需要进行结构与语义治理校验。Do not use：应用行为、应用代码质量或普通文档审查。
---

# Skill Quality Check

## Overview

审查 active Skill 是否只包含可复用的当前状态方法、是否具有清晰的触发条件，以及是否与 Governance Contract authority 保持职责分离。

## When to Use

修改 `SKILL.md`、其直接链接的 Skill 资源、Skill 质量标准或 Skill validator 后使用。

## When NOT to Use

不用于审查应用行为、应用代码质量、普通文档，也不用于审查 active graph 之外已退役或仅供历史使用的 package。

## Contract

这是用于 `SKILL_DEFINITION`、`SKILL_RESOURCE` 和 `SKILL_QUALITY_STANDARD` 的 method Skill。治理事实必须通过 Artifact ID 解析；除非明确要求生成受治理报告，否则检查结果仅在当前任务中临时有效。

## Inputs

发生变更的 active Skill 定义、这些 Skill 直接链接且实际存在的资源、当前质量标准、相关 Artifact/Gate 记录，以及 validator 输出。

## Outputs

输出 `pass` 或 `block` 检查结论，并包含准确的文件引用、authority separation 修正项、validator 证据，以及适用时的 Gate-selected independent checker 结果。

## Process

1. 根据 active method Skill 及其直接链接的资源确定检查范围，不扫描整个 Skill 目录作为默认范围。
2. 通过 `SKILL_DEFINITION` 解析并运行其 `validation_command`。
   Derived operational pointer：`python scripts/validate_agent_skills.py`。
3. 解析当前任务适用的 Gate；如果命中 `G-INDEPENDENT-CHECK`，只有 Gate-selected independent checker 返回 `pass` 后，最终检查结果才能为 `pass`，validator 证据不得替代独立检查。
4. 检查 trigger/non-trigger、必需的 method 章节、边界明确的 inputs/outputs、red flags 和可执行的 verification。
5. 检查 Skill 的自然语言、技术标识符、规范性用词和术语一致性是否符合 `SKILL_QUALITY_STANDARD`；不得在本 Skill 中复制具体语言规则。
6. 拒绝复制 canonical path、owner、lifecycle、dependency 或 Gate authority；只允许使用与 contract 一致且明确标记为 `Derived operational pointer` 的指针。
7. 确认已退役 Skill 不会出现在 discovery 中，并且历史说明没有被用作 active fallback。

## Red Flags

需要阻止以下情况：始终触发的 trigger；active instructions 中保留过程历史；建立第二套 governance registry；引用未链接资源；保留 tombstone Skill；重复定义行为或输出 authority；忽略 validator 结果；用 validator 证据替代适用的 Gate-selected independent checker。

## Verification

Validator 必须以退出码 `0` 结束；如果命中 `G-INDEPENDENT-CHECK`，Gate-selected independent checker 也必须返回 `pass`；active definition 只能包含可复用的当前状态义务；所有 method target 均可解析；operational pointer 与 contract 一致；已退役 package 不可被发现。自然语言与技术标识符边界符合 `SKILL_QUALITY_STANDARD`；同一概念没有未经定义的多种译名；示例和 Derived operational pointer 均真实、可复制并可执行。
