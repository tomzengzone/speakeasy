package com.speakeasy.security;

import java.util.Arrays;
import java.util.Collection;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

public final class AuthScopes {
  public static final String USER_READ = "user:read";
  public static final String USER_WRITE = "user:write";
  public static final String COURSE_READ = "course:read";
  public static final String LEARNING_READ = "learning:read";
  public static final String LEARNING_WRITE = "learning:write";
  public static final String AI_USE = "ai:use";
  public static final String SESSION_MANAGE = "session:manage";

  private AuthScopes() {}

  public static Set<String> parse(String value) {
    if (value == null || value.isBlank()) return Set.of();
    return Arrays.stream(value.trim().split("\\s+"))
        .filter(scope -> !scope.isBlank())
        .collect(Collectors.toUnmodifiableSet());
  }

  public static String serialize(Collection<String> scopes) {
    return String.join(" ", new TreeSet<>(scopes));
  }

  public static String authority(String scope) {
    return "SCOPE_" + scope;
  }
}
