ALTER TABLE usage_reservations
  ADD COLUMN source_ref VARCHAR(256) NOT NULL DEFAULT 'legacy';

ALTER TABLE usage_reservations
  ADD COLUMN provider_usage_event_ref VARCHAR(256);
