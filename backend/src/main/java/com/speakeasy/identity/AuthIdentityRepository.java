package com.speakeasy.identity;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthIdentityRepository extends JpaRepository<AuthIdentity, UUID> {
  Optional<AuthIdentity> findByProviderAndProviderSubject(String provider, String providerSubject);
}
