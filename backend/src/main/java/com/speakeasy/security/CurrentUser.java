package com.speakeasy.security;

import java.util.Set;
import java.util.UUID;

public record CurrentUser(
    UUID userId,
    UUID sessionId,
    String clientId,
    String audience,
    Set<String> scopes) {
  public CurrentUser {
    scopes = Set.copyOf(scopes);
  }
}
