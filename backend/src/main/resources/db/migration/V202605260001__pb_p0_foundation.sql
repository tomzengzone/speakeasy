CREATE TABLE user_accounts (
  user_id UUID PRIMARY KEY,
  display_name VARCHAR(120) NOT NULL,
  avatar_ref VARCHAR(255),
  locale VARCHAR(20) NOT NULL DEFAULT 'zh-CN',
  account_status VARCHAR(40) NOT NULL,
  onboarding_status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE auth_identities (
  auth_identity_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  provider VARCHAR(40) NOT NULL,
  provider_subject VARCHAR(255) NOT NULL,
  linked_at TIMESTAMP NOT NULL,
  status VARCHAR(40) NOT NULL,
  CONSTRAINT uq_auth_identity_provider_subject UNIQUE (provider, provider_subject)
);

CREATE INDEX idx_auth_identities_user ON auth_identities(user_id);

CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES user_accounts(user_id),
  nickname VARCHAR(120),
  target_level VARCHAR(20),
  daily_minutes INTEGER NOT NULL DEFAULT 10,
  reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  reminder_time VARCHAR(20),
  theme VARCHAR(40),
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE onboarding_assessments (
  assessment_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  goal_direction VARCHAR(80) NOT NULL,
  pain_points TEXT,
  output_level VARCHAR(20) NOT NULL,
  daily_minutes INTEGER NOT NULL,
  completed_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_onboarding_assessments_user ON onboarding_assessments(user_id);

CREATE TABLE learning_routes (
  route_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  current_scenario_id VARCHAR(80) NOT NULL,
  target_level VARCHAR(20) NOT NULL,
  source_assessment_id UUID REFERENCES onboarding_assessments(assessment_id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_learning_routes_user ON learning_routes(user_id);

CREATE TABLE scenarios (
  scenario_id VARCHAR(80) PRIMARY KEY,
  slug VARCHAR(80) NOT NULL UNIQUE,
  title VARCHAR(160) NOT NULL,
  summary TEXT,
  category VARCHAR(80),
  status VARCHAR(40) NOT NULL
);

CREATE TABLE scenario_versions (
  scenario_version_id UUID PRIMARY KEY,
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  version VARCHAR(40) NOT NULL,
  content_status VARCHAR(40) NOT NULL,
  published_at TIMESTAMP,
  CONSTRAINT uq_scenario_versions_version UNIQUE (scenario_id, version)
);

CREATE INDEX idx_scenario_versions_scenario ON scenario_versions(scenario_id);

CREATE TABLE scenario_levels (
  scenario_level_id UUID PRIMARY KEY,
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  level_code VARCHAR(20) NOT NULL,
  target_level VARCHAR(20) NOT NULL,
  expression_count INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT uq_scenario_levels_level UNIQUE (scenario_id, level_code)
);

CREATE TABLE target_expressions (
  target_expression_id UUID PRIMARY KEY,
  scenario_version_id UUID NOT NULL REFERENCES scenario_versions(scenario_version_id),
  level_code VARCHAR(20) NOT NULL,
  text TEXT NOT NULL,
  meaning_cn TEXT,
  tags TEXT,
  usage_note TEXT
);

CREATE INDEX idx_target_expressions_version_level ON target_expressions(scenario_version_id, level_code);

CREATE TABLE subscription_plans (
  plan_id UUID PRIMARY KEY,
  platform VARCHAR(40) NOT NULL,
  product_id VARCHAR(160) NOT NULL,
  billing_period VARCHAR(40) NOT NULL,
  entitlement_template_id VARCHAR(120),
  status VARCHAR(40) NOT NULL,
  CONSTRAINT uq_subscription_plans_product UNIQUE (platform, product_id)
);

CREATE TABLE purchases (
  purchase_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  platform VARCHAR(40) NOT NULL,
  provider_transaction_id VARCHAR(255) NOT NULL,
  product_id VARCHAR(160) NOT NULL,
  verification_status VARCHAR(40) NOT NULL,
  purchased_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_purchases_provider_transaction UNIQUE (platform, provider_transaction_id)
);

CREATE INDEX idx_purchases_user ON purchases(user_id);

CREATE TABLE subscriptions (
  subscription_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  plan_id UUID NOT NULL REFERENCES subscription_plans(plan_id),
  platform VARCHAR(40) NOT NULL,
  status VARCHAR(40) NOT NULL,
  starts_at TIMESTAMP,
  expires_at TIMESTAMP,
  grace_until TIMESTAMP,
  latest_purchase_id UUID REFERENCES purchases(purchase_id)
);

CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);

CREATE TABLE entitlement_snapshots (
  entitlement_snapshot_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  source_subscription_id UUID REFERENCES subscriptions(subscription_id),
  plan VARCHAR(40) NOT NULL,
  feature_flags TEXT NOT NULL,
  quota_limits TEXT NOT NULL,
  status VARCHAR(40) NOT NULL,
  valid_until TIMESTAMP,
  generated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_entitlement_snapshots_user_generated ON entitlement_snapshots(user_id, generated_at);

CREATE TABLE usage_ledgers (
  ledger_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  usage_family VARCHAR(40) NOT NULL,
  period VARCHAR(40) NOT NULL,
  reserved_amount INTEGER NOT NULL DEFAULT 0,
  committed_amount INTEGER NOT NULL DEFAULT 0,
  limit_amount INTEGER NOT NULL,
  status VARCHAR(40) NOT NULL,
  CONSTRAINT uq_usage_ledgers_user_family_period UNIQUE (user_id, usage_family, period)
);

CREATE TABLE usage_reservations (
  reservation_id UUID PRIMARY KEY,
  ledger_id UUID NOT NULL REFERENCES usage_ledgers(ledger_id),
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  usage_family VARCHAR(40) NOT NULL,
  amount INTEGER NOT NULL,
  status VARCHAR(40) NOT NULL,
  idempotency_key VARCHAR(160) NOT NULL,
  reserved_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_usage_reservations_idempotency UNIQUE (user_id, idempotency_key)
);

CREATE INDEX idx_usage_reservations_ledger ON usage_reservations(ledger_id);

CREATE TABLE payment_provider_events (
  provider_event_id VARCHAR(255) PRIMARY KEY,
  platform VARCHAR(40) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  received_at TIMESTAMP NOT NULL,
  processed_status VARCHAR(40) NOT NULL,
  related_subscription_id UUID REFERENCES subscriptions(subscription_id),
  payload_ref VARCHAR(255)
);

CREATE TABLE account_deletion_jobs (
  deletion_job_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  status VARCHAR(40) NOT NULL,
  requested_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  failure_reason TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_account_deletion_jobs_user_status ON account_deletion_jobs(user_id, status);

CREATE TABLE audit_logs (
  audit_log_id UUID PRIMARY KEY,
  actor_type VARCHAR(40) NOT NULL,
  actor_id VARCHAR(120),
  event_type VARCHAR(120) NOT NULL,
  target_ref VARCHAR(160),
  redacted_details TEXT,
  request_id VARCHAR(120),
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_logs_event_created ON audit_logs(event_type, created_at);
