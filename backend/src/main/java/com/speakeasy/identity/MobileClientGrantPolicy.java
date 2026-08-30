package com.speakeasy.identity;

import com.speakeasy.security.AuthScopes;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Authorization policy for the first-party authenticated mobile client. */
@Component
public final class MobileClientGrantPolicy implements AuthGrantPolicy {
  public static final Set<String> READ_SCOPES = Set.of(
      AuthScopes.USER_READ,
      AuthScopes.COURSE_READ,
      AuthScopes.LEARNING_READ,
      AuthScopes.AI_USE);

  public static final Set<String> WRITE_SCOPES = Set.of(
      AuthScopes.USER_WRITE,
      AuthScopes.LEARNING_WRITE);

  public static final Set<String> SECURITY_SENSITIVE_SCOPES = Set.of(
      AuthScopes.SESSION_MANAGE);

  public static final Set<String> AUTHENTICATED_MOBILE_SCOPES = Set.of(
      AuthScopes.USER_READ,
      AuthScopes.USER_WRITE,
      AuthScopes.COURSE_READ,
      AuthScopes.LEARNING_READ,
      AuthScopes.LEARNING_WRITE,
      AuthScopes.AI_USE,
      AuthScopes.SESSION_MANAGE);

  private static final Set<String> SUPPORTED_AUTHENTICATION_METHODS = Set.of(
      "phone", "apple", "wechat");

  private final String clientId;

  public MobileClientGrantPolicy(
      @Value("${speakeasy.auth.client-id:speakeasy-mobile}") String clientId) {
    this.clientId = clientId;
  }

  @Override
  public Set<String> scopesFor(LoginContext context) {
    if (context == null
        || !clientId.equals(context.clientId())
        || !SUPPORTED_AUTHENTICATION_METHODS.contains(context.authenticationMethod())) {
      throw new IllegalArgumentException("Unsupported authorization grant context.");
    }
    return AUTHENTICATED_MOBILE_SCOPES;
  }
}
