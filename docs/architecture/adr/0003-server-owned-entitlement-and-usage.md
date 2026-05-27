# ADR 0003: Server-Owned Entitlement And Usage

## Status
Proposed - pending document traceability and Product Object Governance checks.

## Context
当前会员页和 Apple IAP 前端雏形只能证明客户端有商业入口，不能证明真实付费闭环。P0 商业化上线需要覆盖购买、恢复、退款、过期、宽限期、Android Billing、账号切换、商业权益 gating、AI 成本控制和发布回滚。

## Decision
订阅权益、用量额度、退款/过期/宽限期和 AI quota 以服务端为事实源。客户端只展示 EntitlementSnapshot 缓存，并通过 API 刷新状态。

Core objects:
- SubscriptionPlan
- Purchase
- SubscriptionState
- EntitlementSnapshot
- UsageLedger
- PaymentAuditLog
- ProviderUsageEvent

Required APIs:
- `GET /entitlements`
- `POST /entitlements/refresh`
- `POST /subscriptions/apple/verify`
- `POST /subscriptions/google/verify`
- `POST /subscriptions/restore`
- `GET /usage/summary`
- `POST /usage/reserve`
- `POST /usage/commit`
- `POST /usage/release`

## Alternatives
- Client-owned `memberPlan` or local entitlement flag：拒绝。容易被伪造，无法处理退款、账号切换和恢复购买。
- Store SDK status only：拒绝。无法统一 Android/iOS、服务端 gating、AI quota 和审计。
- Third-party subscription SaaS as source of truth：可作为实现选项，但项目后端仍需保存可追踪 entitlement projection 和 usage ledger。

## Consequences
- 所有付费权益判断有统一、可审计、可恢复的边界。
- AI/ASR/TTS/评分成本可以被服务端 quota 和 rate limit 控制。
- Flutter 需要支持刷新权益、超限态、恢复购买为空、退款后降级和离线缓存过期。
- 后端必须处理支付 webhook、幂等、审计和数据保留。

## Risks
- 支付 webhook 和客户端 verify 可能乱序到达。Mitigation：provider event id、idempotency key 和状态机版本。
- 离线缓存可能短期展示旧权益。Mitigation：设置 TTL，关键高成本调用服务端实时检查。
- 文案承诺可能超前于真实能力。Mitigation：商业发布 checklist 要求会员页、商店文案和 entitlement feature map 一致。

## Rollback
可以临时关闭付费墙或降级高成本功能，但不得让客户端本地会员状态重新成为最终事实源。出现支付事故时，保留服务端 entitlement projection 和 audit log 用于恢复。
