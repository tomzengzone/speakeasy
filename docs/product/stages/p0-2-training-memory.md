# P0.2 阶段范围：跨 session 训练编排与记忆引擎

## 状态
Draft - future stage，用于明确 P0.1 非目标。

## 阶段目标
在 P0.1 session 内训练闭环稳定后，扩展为跨 session、跨天、跨场景的训练编排和记忆引擎，让用户不需要自己决定今天练什么、练几组、哪些表达要复现、哪些薄弱点要插入新场景。

## 入口条件
- P0.1 训练型 Agent 已可验收。
- P0.1 学习证据写回稳定可追踪。
- P0.1 未完成项和测试缺口已记录。

## 阶段范围
- Daily training planner。
- Cross-session pressure ladder。
- L0-L5 mastery ladder。
- Long-term session planner。
- 到期复习、薄弱表达、未完成 session 和当前目标场景的跨天编排。
- 训练证据进入首页推荐、表达队列和个人 Wiki。

## 阶段非目标
- 不在 P0.2 承诺完整 A1-C2 内容体系。
- 不在 P0.2 承诺任意公开场景生成。
- 不把笔记本和完整评分产品化作为 P0.2 阻塞项。

## 纳入 increment
- 待 Product Manager 在 P0.1 验收后定义。

## 出口条件
- 至少一个跨 session 训练编排 increment 完成需求、规格、验收、测试和实现报告。
- L0-L5 状态推进规则有明确 domain model 和测试覆盖。
- 长期记忆调度不由 LLM 直接写入最终持久化状态。
