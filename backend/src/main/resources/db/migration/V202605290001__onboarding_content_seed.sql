CREATE TABLE user_scenario_states (
  user_scenario_state_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  state VARCHAR(40) NOT NULL,
  current_flag BOOLEAN NOT NULL DEFAULT FALSE,
  target_level VARCHAR(20) NOT NULL,
  joined_at TIMESTAMP,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_user_scenario_states_user_scenario UNIQUE (user_id, scenario_id)
);

CREATE INDEX idx_user_scenario_states_user_state ON user_scenario_states(user_id, state);
CREATE INDEX idx_user_scenario_states_user_current ON user_scenario_states(user_id, current_flag);

INSERT INTO scenarios (scenario_id, slug, title, summary, category, status) VALUES
  ('job_interview', 'job_interview', '英语面试', '围绕求职面试中的自我介绍、项目经历和追问回应进行练习。', 'official', 'available'),
  ('onboarding_introduction', 'onboarding_introduction', '入职介绍', '围绕新团队入职介绍、工作沟通和协作开场进行练习。', 'official', 'available');

INSERT INTO scenario_versions (scenario_version_id, scenario_id, version, content_status, published_at) VALUES
  ('10000000-0000-0000-0000-000000000001', 'job_interview', '2026.05-mvp-seed', 'published', TIMESTAMP '2026-05-29 00:00:00'),
  ('10000000-0000-0000-0000-000000000002', 'onboarding_introduction', '2026.05-mvp-seed', 'published', TIMESTAMP '2026-05-29 00:00:00');

INSERT INTO scenario_levels (scenario_level_id, scenario_id, level_code, target_level, expression_count) VALUES
  ('20000000-0000-0000-0000-000000000001', 'job_interview', 'L1', 'L1', 2),
  ('20000000-0000-0000-0000-000000000002', 'job_interview', 'L2', 'L2', 2),
  ('20000000-0000-0000-0000-000000000003', 'job_interview', 'L3', 'L3', 2),
  ('20000000-0000-0000-0000-000000000004', 'onboarding_introduction', 'L1', 'L1', 2),
  ('20000000-0000-0000-0000-000000000005', 'onboarding_introduction', 'L2', 'L2', 2),
  ('20000000-0000-0000-0000-000000000006', 'onboarding_introduction', 'L3', 'L3', 2);

INSERT INTO target_expressions (target_expression_id, scenario_version_id, level_code, text, meaning_cn, tags, usage_note) VALUES
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'L1', 'Could you tell me about yourself?', '你可以介绍一下自己吗？', 'interview,opening', 'Use this to open a simple interview answer.'),
  ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'L1', 'I worked on a small project that improved our workflow.', '我参与过一个改进工作流程的小项目。', 'interview,experience', 'Use this to describe concrete experience.'),
  ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'L2', 'My main contribution was coordinating the timeline and clarifying priorities.', '我的主要贡献是协调时间线并明确优先级。', 'interview,impact', 'Use this to explain contribution.'),
  ('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'L2', 'One challenge was limited time, so I focused on the highest-risk part first.', '一个挑战是时间有限，所以我优先处理风险最高的部分。', 'interview,challenge', 'Use this to answer challenge questions.'),
  ('30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000001', 'L3', 'I would break the problem down, validate assumptions, and keep the team aligned.', '我会拆解问题、验证假设，并保持团队同步。', 'interview,method', 'Use this for structured answers.'),
  ('30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', 'L3', 'Looking back, I would communicate trade-offs earlier to reduce uncertainty.', '回顾来看，我会更早沟通取舍来降低不确定性。', 'interview,reflection', 'Use this to show reflection.'),
  ('30000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', 'L1', 'Hi, I am new to the team and happy to work with you.', '大家好，我刚加入团队，很高兴和大家合作。', 'onboarding,opening', 'Use this for a simple introduction.'),
  ('30000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000002', 'L1', 'Could you show me where I can find the project documents?', '你能告诉我在哪里可以找到项目文档吗？', 'onboarding,question', 'Use this to ask for information.'),
  ('30000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000002', 'L2', 'I would like to understand the current priorities before I start.', '开始前我想先了解当前优先级。', 'onboarding,priority', 'Use this to align with the team.'),
  ('30000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000002', 'L2', 'Please let me know if there is any context I should review first.', '如果有我应该先了解的背景信息，请告诉我。', 'onboarding,context', 'Use this to request context.'),
  ('30000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000002', 'L3', 'To make sure I am aligned, could we confirm the expected outcome and timeline?', '为了确保我理解一致，我们能确认预期结果和时间线吗？', 'onboarding,alignment', 'Use this in work communication.'),
  ('30000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000002', 'L3', 'I can take the first draft and share progress before the next checkpoint.', '我可以先完成初稿，并在下个检查点前同步进展。', 'onboarding,commitment', 'Use this to propose next action.');
