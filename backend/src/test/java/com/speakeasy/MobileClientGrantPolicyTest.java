package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.identity.AuthGrantPolicy.LoginContext;
import com.speakeasy.identity.MobileClientGrantPolicy;
import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.Test;

class MobileClientGrantPolicyTest {
  private final MobileClientGrantPolicy policy = new MobileClientGrantPolicy("speakeasy-mobile");

  @Test
  void lp001PolicyDefinesDisjointReadWriteAndSecuritySensitiveCategories() {
    Set<String> categorizedScopes = new HashSet<>(MobileClientGrantPolicy.READ_SCOPES);
    categorizedScopes.addAll(MobileClientGrantPolicy.WRITE_SCOPES);
    categorizedScopes.addAll(MobileClientGrantPolicy.SECURITY_SENSITIVE_SCOPES);

    assertThat(MobileClientGrantPolicy.READ_SCOPES)
        .doesNotContainAnyElementsOf(MobileClientGrantPolicy.WRITE_SCOPES)
        .doesNotContainAnyElementsOf(MobileClientGrantPolicy.SECURITY_SENSITIVE_SCOPES);
    assertThat(MobileClientGrantPolicy.WRITE_SCOPES)
        .doesNotContainAnyElementsOf(MobileClientGrantPolicy.SECURITY_SENSITIVE_SCOPES);
    assertThat(MobileClientGrantPolicy.AUTHENTICATED_MOBILE_SCOPES)
        .containsExactlyInAnyOrderElementsOf(categorizedScopes)
        .containsExactlyInAnyOrderElementsOf(policy.scopesFor(new LoginContext("speakeasy-mobile", "phone")));
  }

  @Test
  void lp001PolicyFailsClosedForUnknownClientOrAuthenticationMethod() {
    assertThatThrownBy(() -> policy.scopesFor(new LoginContext("unknown-client", "phone")))
        .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> policy.scopesFor(new LoginContext("speakeasy-mobile", "password")))
        .isInstanceOf(IllegalArgumentException.class);
  }
}
