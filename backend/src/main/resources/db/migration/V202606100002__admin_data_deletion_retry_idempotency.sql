CREATE TABLE account_deletion_retry_idempotency (
  retry_id UUID PRIMARY KEY,
  deletion_job_id UUID NOT NULL REFERENCES account_deletion_jobs(deletion_job_id),
  idempotency_key VARCHAR(160) NOT NULL,
  status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  failure_reason TEXT,
  CONSTRAINT uq_account_deletion_retry_idempotency UNIQUE (deletion_job_id, idempotency_key)
);

CREATE INDEX idx_account_deletion_retry_job_status
  ON account_deletion_retry_idempotency(deletion_job_id, status, created_at);
