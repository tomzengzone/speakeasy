package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.identity.AuthGrantPolicy;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.MobileClientGrantPolicy;
import com.speakeasy.security.CurrentUser;
import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthGrantPolicyIntegrationTest extends BackendIntegrationTestSupport {
  private static final String FUTURE_SCOPE = "future:read";

  @Autowired AuthService authService;
  @Autowired MutableAuthGrantPolicy grantPolicy;

  @BeforeEach
  void resetGrantPolicy() {
    grantPolicy.reset();
  }

  @AfterEach
  void removeGrantPolicyTestData() {
    cleanUserData();
  }

  @Test
  void lp001DefaultTokenContainsOnlyTheExplicitAuthenticatedMobileBaseline() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138500");

    CurrentUser currentUser = authService.inspectAccessToken(tokens.accessToken()).currentUser();

    assertThat(currentUser).isNotNull();
    assertThat(currentUser.scopes())
        .containsExactlyInAnyOrderElementsOf(MobileClientGrantPolicy.AUTHENTICATED_MOBILE_SCOPES);
  }

  @Test
  void lp004ClientSuppliedScopeHeaderCannotChangeTheServerGrant() throws Exception {
    MvcResult result = mvc.perform(post("/auth/login/phone")
            .header("Scope", FUTURE_SCOPE)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138501",
                  "verification_code": "123456",
                  "terms_accepted": true
                }
                """))
        .andExpect(status().isOk())
        .andReturn();

    String accessToken = JsonPath.read(result.getResponse().getContentAsString(), "$.access_token");
    CurrentUser currentUser = authService.inspectAccessToken(accessToken).currentUser();

    assertThat(currentUser).isNotNull();
    assertThat(currentUser.scopes())
        .containsExactlyInAnyOrderElementsOf(MobileClientGrantPolicy.AUTHENTICATED_MOBILE_SCOPES)
        .doesNotContain(FUTURE_SCOPE);
  }

  @Test
  void lp005ExistingTokenDoesNotGainPermissionsWhenTheServerPolicyExpands() throws Exception {
    AuthTokens oldTokens = loginPhone("+8613800138502");

    grantPolicy.addScope(FUTURE_SCOPE);
    AuthTokens newTokens = loginPhone("+8613800138503");

    CurrentUser oldCurrentUser = authService.inspectAccessToken(oldTokens.accessToken()).currentUser();
    CurrentUser newCurrentUser = authService.inspectAccessToken(newTokens.accessToken()).currentUser();
    assertThat(oldCurrentUser).isNotNull();
    assertThat(newCurrentUser).isNotNull();
    assertThat(oldCurrentUser.scopes()).doesNotContain(FUTURE_SCOPE);
    assertThat(newCurrentUser.scopes()).contains(FUTURE_SCOPE);
  }

  @TestConfiguration
  static class GrantPolicyTestConfiguration {
    @Bean
    @Primary
    MutableAuthGrantPolicy mutableAuthGrantPolicy() {
      return new MutableAuthGrantPolicy();
    }
  }

  static final class MutableAuthGrantPolicy implements AuthGrantPolicy {
    private volatile Set<String> scopes = MobileClientGrantPolicy.AUTHENTICATED_MOBILE_SCOPES;

    @Override
    public Set<String> scopesFor(LoginContext context) {
      return scopes;
    }

    void reset() {
      scopes = MobileClientGrantPolicy.AUTHENTICATED_MOBILE_SCOPES;
    }

    void addScope(String scope) {
      Set<String> expanded = new HashSet<>(scopes);
      expanded.add(scope);
      scopes = Set.copyOf(expanded);
    }
  }
}
