CREATE TABLE otp_challenges (
  challenge_id UUID PRIMARY KEY,
  phone_e164 VARCHAR(32) NOT NULL,
  phone_hash VARCHAR(128) NOT NULL,
  purpose VARCHAR(40) NOT NULL,
  status VARCHAR(40) NOT NULL,
  hash_version VARCHAR(40) NOT NULL,
  otp_hmac_digest VARCHAR(128) NOT NULL,
  sent_at TIMESTAMP NOT NULL,
  active_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  consumed_at TIMESTAMP,
  invalidated_at TIMESTAMP,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL,
  context_hash VARCHAR(128),
  risk_decision VARCHAR(40) NOT NULL,
  step_up_status VARCHAR(40) NOT NULL,
  request_id VARCHAR(120),
  retention_policy_version VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT chk_otp_challenges_status CHECK (status IN ('pending', 'active', 'consumed', 'expired', 'invalidated', 'locked')),
  CONSTRAINT chk_otp_challenges_risk_decision CHECK (risk_decision IN ('allow', 'block', 'step_up')),
  CONSTRAINT chk_otp_challenges_step_up_status CHECK (step_up_status IN ('not_required', 'pending', 'passed', 'failed', 'blocked')),
  CONSTRAINT chk_otp_challenges_attempts CHECK (attempt_count >= 0 AND max_attempts > 0 AND attempt_count <= max_attempts),
  CONSTRAINT chk_otp_challenges_expiry CHECK (expires_at > active_at)
);

CREATE INDEX idx_otp_challenges_phone_purpose_status
  ON otp_challenges(phone_hash, purpose, status);

CREATE INDEX idx_otp_challenges_expires_at
  ON otp_challenges(expires_at);

CREATE INDEX idx_otp_challenges_created_at
  ON otp_challenges(created_at);

CREATE TABLE otp_rate_counters (
  rate_counter_id UUID PRIMARY KEY,
  subject_type VARCHAR(40) NOT NULL,
  subject_hash VARCHAR(128) NOT NULL,
  purpose VARCHAR(40) NOT NULL,
  window_start TIMESTAMP NOT NULL,
  window_end TIMESTAMP NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_otp_rate_counters_window UNIQUE (subject_type, subject_hash, purpose, window_start, window_end),
  CONSTRAINT chk_otp_rate_counters_window CHECK (window_end > window_start),
  CONSTRAINT chk_otp_rate_counters_count CHECK (count >= 0)
);

CREATE TABLE otp_failure_locks (
  failure_lock_id UUID PRIMARY KEY,
  phone_hash VARCHAR(128) NOT NULL,
  purpose VARCHAR(40) NOT NULL,
  failure_count INTEGER NOT NULL DEFAULT 0,
  window_start TIMESTAMP NOT NULL,
  locked_until TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_otp_failure_locks_phone_purpose UNIQUE (phone_hash, purpose),
  CONSTRAINT chk_otp_failure_locks_count CHECK (failure_count >= 0)
);
