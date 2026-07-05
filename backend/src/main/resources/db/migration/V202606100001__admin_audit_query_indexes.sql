CREATE INDEX idx_audit_logs_created_id ON audit_logs(created_at DESC, audit_log_id DESC);
CREATE INDEX idx_audit_logs_actor_created ON audit_logs(actor_type, created_at DESC);
CREATE INDEX idx_audit_logs_target_created ON audit_logs(target_ref, created_at DESC);
