CREATE TABLE ai_provider_invocation_metrics (
  metric_id UUID PRIMARY KEY,
  user_hash VARCHAR(80) NOT NULL,
  plan VARCHAR(40) NOT NULL,
  provider_family VARCHAR(80) NOT NULL,
  model VARCHAR(120) NOT NULL,
  capability VARCHAR(40) NOT NULL,
  status VARCHAR(40) NOT NULL,
  cache_hit BOOLEAN NOT NULL,
  token_estimate INTEGER,
  audio_duration_seconds INTEGER,
  estimated_cost DECIMAL(12, 6) NOT NULL,
  budget_bucket VARCHAR(80) NOT NULL,
  margin_risk VARCHAR(40) NOT NULL,
  fallback_reason VARCHAR(120),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_ai_provider_invocation_metrics_created
  ON ai_provider_invocation_metrics(created_at);

CREATE INDEX idx_ai_provider_invocation_metrics_ops
  ON ai_provider_invocation_metrics(created_at, plan, user_hash, provider_family, model, capability, status, cache_hit);
