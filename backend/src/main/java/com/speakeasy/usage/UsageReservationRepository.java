package com.speakeasy.usage;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsageReservationRepository extends JpaRepository<UsageReservation, UUID> {
  Optional<UsageReservation> findByUserIdAndIdempotencyKey(UUID userId, String idempotencyKey);

  Optional<UsageReservation> findByReservationIdAndUserId(UUID reservationId, UUID userId);

  List<UsageReservation> findByUserIdOrderByReservedAtDesc(UUID userId);
}
