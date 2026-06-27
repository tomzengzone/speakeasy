CREATE TABLE goal_profiles (
  goal_profile_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  goal_type VARCHAR(80) NOT NULL,
  target_score DOUBLE PRECISION,
  target_ability TEXT,
  deadline DATE NOT NULL,
  daily_minutes INTEGER NOT NULL,
  intensity_preference VARCHAR(40) NOT NULL,
  support_status VARCHAR(40) NOT NULL,
  status VARCHAR(40) NOT NULL,
  revision INTEGER NOT NULL,
  limitation_message TEXT NOT NULL,
  quiet_hours_start VARCHAR(8),
  quiet_hours_end VARCHAR(8),
  notification_consent BOOLEAN NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_profiles_user_status
  ON goal_profiles (user_id, status, updated_at);

CREATE TABLE goal_diagnostic_assessments (
  diagnostic_assessment_id UUID PRIMARY KEY,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  status VARCHAR(40) NOT NULL,
  confidence_band VARCHAR(40) NOT NULL,
  sample_count INTEGER NOT NULL,
  rubric_scores_json TEXT NOT NULL,
  weakness_tags_json TEXT NOT NULL,
  claim_guard_json TEXT NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_diagnostics_goal_created
  ON goal_diagnostic_assessments (goal_profile_id, created_at);

CREATE TABLE goal_mastery_initial_states (
  state_id UUID PRIMARY KEY,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  dimension_key VARCHAR(120) NOT NULL,
  initial_level VARCHAR(20) NOT NULL,
  evidence_ref VARCHAR(160) NOT NULL,
  source VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_mastery_initial_states_goal
  ON goal_mastery_initial_states (goal_profile_id, dimension_key);

CREATE TABLE goal_backplans (
  weekly_backplan_id UUID PRIMARY KEY,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  plan_version VARCHAR(80) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  milestone TEXT NOT NULL,
  session_count INTEGER NOT NULL,
  review_windows TEXT NOT NULL,
  checkpoint_due_date DATE NOT NULL,
  status VARCHAR(40) NOT NULL,
  stale_reason VARCHAR(120),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_backplans_user_status
  ON goal_backplans (user_id, status, start_date);

CREATE TABLE goal_daily_plans (
  daily_plan_id UUID PRIMARY KEY,
  weekly_backplan_id UUID NOT NULL REFERENCES goal_backplans(weekly_backplan_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  plan_date DATE NOT NULL,
  total_minutes INTEGER NOT NULL,
  status VARCHAR(40) NOT NULL,
  limitation_message TEXT NOT NULL,
  memory_policy_version VARCHAR(80) NOT NULL,
  forgetting_risk VARCHAR(40) NOT NULL,
  next_review_interval_days INTEGER NOT NULL,
  overlearning_cap INTEGER NOT NULL,
  interleaving_rule VARCHAR(160) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_daily_plans_user_date
  ON goal_daily_plans (user_id, plan_date, status);

CREATE TABLE goal_plan_items (
  plan_item_id UUID PRIMARY KEY,
  daily_plan_id UUID NOT NULL REFERENCES goal_daily_plans(daily_plan_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  item_type VARCHAR(40) NOT NULL,
  title TEXT NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  duration_minutes INTEGER NOT NULL,
  status VARCHAR(40) NOT NULL,
  memory_risk VARCHAR(40) NOT NULL,
  pressure_level VARCHAR(40) NOT NULL,
  order_index INTEGER NOT NULL,
  completed_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_plan_items_daily_status
  ON goal_plan_items (daily_plan_id, status, order_index);

CREATE TABLE goal_progress_forecasts (
  forecast_id UUID PRIMARY KEY,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  gap_summary TEXT NOT NULL,
  eta_date DATE,
  eta_window VARCHAR(80) NOT NULL,
  confidence_band VARCHAR(40) NOT NULL,
  risk_level VARCHAR(40) NOT NULL,
  risk_reason TEXT NOT NULL,
  next_checkpoint_date DATE NOT NULL,
  claim_guard_json TEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_forecasts_goal_updated
  ON goal_progress_forecasts (goal_profile_id, updated_at);

CREATE TABLE goal_outcome_checkpoints (
  checkpoint_id UUID PRIMARY KEY,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  checkpoint_type VARCHAR(80) NOT NULL,
  cadence VARCHAR(40) NOT NULL,
  result_status VARCHAR(40) NOT NULL,
  confidence_band VARCHAR(40) NOT NULL,
  summary TEXT NOT NULL,
  plan_update_signal VARCHAR(80) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_checkpoints_goal_created
  ON goal_outcome_checkpoints (goal_profile_id, created_at);
