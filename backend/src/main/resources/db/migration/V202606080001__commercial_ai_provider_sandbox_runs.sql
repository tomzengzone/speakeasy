CREATE TABLE ai_provider_sandbox_runs (
  evidence_id VARCHAR(120) PRIMARY KEY,
  provider_family VARCHAR(80) NOT NULL,
  capability VARCHAR(40) NOT NULL,
  model VARCHAR(120),
  fixture_ref VARCHAR(240),
  latency_p50_ms INTEGER,
  latency_p95_ms INTEGER,
  status VARCHAR(40) NOT NULL,
  error_code VARCHAR(120),
  estimated_cost DECIMAL(12, 6),
  reviewed_status VARCHAR(40) NOT NULL,
  evidence_ref VARCHAR(240) NOT NULL,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewer_ref_hash VARCHAR(120),
  executed_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_ai_provider_sandbox_runs_ops
  ON ai_provider_sandbox_runs(executed_at DESC, created_at DESC, evidence_id);

CREATE INDEX idx_ai_provider_sandbox_runs_gate
  ON ai_provider_sandbox_runs(provider_family, capability, status, reviewed_status);
