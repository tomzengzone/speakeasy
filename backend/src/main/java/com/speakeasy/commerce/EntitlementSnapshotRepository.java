package com.speakeasy.commerce;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EntitlementSnapshotRepository extends JpaRepository<EntitlementSnapshot, UUID> {
  List<EntitlementSnapshot> findByUserIdOrderByGeneratedAtDesc(UUID userId);
}
