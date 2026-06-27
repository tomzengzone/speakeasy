package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import com.speakeasy.commerce.PaymentProviderEventRepository;
import com.speakeasy.commerce.PurchaseRepository;
import com.speakeasy.commerce.SubscriptionRepository;
import com.speakeasy.commerce.SubscriptionPlanRepository;
import com.speakeasy.content.UserScenarioStateRepository;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.identity.LearningRouteRepository;
import com.speakeasy.identity.OnboardingAssessmentRepository;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.UserProfileRepository;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.usage.UsageLedgerRepository;
import com.speakeasy.usage.UsageReservationRepository;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerTest {
  @Autowired MockMvc mvc;
  @Autowired AccountDeletionJobRepository deletionJobs;
  @Autowired UserScenarioStateRepository userScenarioStates;
  @Autowired LearningRouteRepository routes;
  @Autowired OnboardingAssessmentRepository assessments;
  @Autowired AuthSessionRepository sessions;
  @Autowired AuthIdentityRepository identities;
  @Autowired UserProfileRepository profiles;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired UsageReservationRepository reservations;
  @Autowired SubscriptionPlanRepository plans;
  @Autowired PurchaseRepository purchases;
  @Autowired SubscriptionRepository subscriptions;
  @Autowired PaymentProviderEventRepository providerEvents;
  @Autowired UserAccountRepository users;

  @BeforeEach
  void setUp() {
    deletionJobs.deleteAll();
    userScenarioStates.deleteAll();
    routes.deleteAll();
    assessments.deleteAll();
    sessions.deleteAll();
    identities.deleteAll();
    profiles.deleteAll();
    entitlements.deleteAll();
    providerEvents.deleteAll();
    subscriptions.deleteAll();
    purchases.deleteAll();
    reservations.deleteAll();
    ledgers.deleteAll();
    plans.deleteAll();
    users.deleteAll();
  }

  @Test
  void getMeRequiresBearerToken() throws Exception {
    mvc.perform(get("/user/me"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void patchAndDeleteMeRequireBearerToken() throws Exception {
    mvc.perform(patch("/user/me")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "display_name": "Blocked"
                }
                """))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    mvc.perform(delete("/user/me"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void loginAndGetMeBindToCurrentUser() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138000");

    mvc.perform(get("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-User-Id", "00000000-0000-0000-0000-000000000099"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.user.user_id").value(tokens.userId()))
        .andExpect(jsonPath("$.user.account_status").value("active"));
  }

  @Test
  void socialLoginsBindToCurrentUserAndPreserveProviderNamespace() throws Exception {
    AuthTokens apple = loginSocial("/auth/login/apple", "shared-social-provider-token");
    AuthTokens appleAgain = loginSocial("/auth/login/apple", "shared-social-provider-token");
    AuthTokens wechat = loginSocial("/auth/login/wechat", "shared-social-provider-token");
    AuthTokens wechatAgain = loginSocial("/auth/login/wechat", "shared-social-provider-token");

    assertThat(appleAgain.userId()).isEqualTo(apple.userId());
    assertThat(wechatAgain.userId()).isEqualTo(wechat.userId());
    assertThat(wechat.userId()).isNotEqualTo(apple.userId());

    assertCurrentUserMatches(apple);
    assertCurrentUserMatches(wechat);
  }

  @Test
  void patchMeUpdatesAuthenticatedUserProfile() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138001");

    mvc.perform(patch("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "display_name": "Updated Name",
                  "avatar_ref": "assets/images/avatars/default_avatar_2.png",
                  "target_level": "L2",
                  "daily_minutes": 15,
                  "reminder_enabled": true,
                  "reminder_time": "09:30"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.display_name").value("Updated Name"))
        .andExpect(jsonPath("$.user.avatar_ref").value("assets/images/avatars/default_avatar_2.png"))
        .andExpect(jsonPath("$.user.target_level").value("L2"))
        .andExpect(jsonPath("$.user.daily_minutes").value(15));

    mvc.perform(patch("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "display_name": "Updated Again"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.display_name").value("Updated Again"))
        .andExpect(jsonPath("$.user.avatar_ref").value("assets/images/avatars/default_avatar_2.png"));

    mvc.perform(patch("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "avatar_ref": null
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.avatar_ref").value("assets/images/avatars/default_avatar_2.png"));

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.user.avatar_ref").value("assets/images/avatars/default_avatar_2.png"));

    assertThat(users.findById(UUID.fromString(tokens.userId())).orElseThrow().getAvatarRef())
        .isEqualTo("assets/images/avatars/default_avatar_2.png");
  }

  @Test
  void patchMeRejectsUnsupportedAvatarRef() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138004");

    for (String avatarRef : List.of(
        "https://example.com/avatar.png",
        "",
        "assets/images/avatars/default_avatar_7.png",
        " assets/images/avatars/default_avatar_1.png ")) {
      mvc.perform(patch("/user/me")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
              .contentType(MediaType.APPLICATION_JSON)
              .content("""
                  {
                    "schema_version": 1,
                    "avatar_ref": "%s"
                  }
                  """.formatted(avatarRef)))
          .andExpect(status().isUnprocessableEntity())
          .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
    }
  }

  @Test
  void refreshRotatesTokenAndLogoutRevokesSession() throws Exception {
    AuthTokens login = loginPhone("+8613800138002");

    MvcResult refreshResult = mvc.perform(post("/auth/refresh")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "refresh_token": "%s"
                }
                """.formatted(login.refreshToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.access_token", not(blankOrNullString())))
        .andReturn();

    String refreshedAccessToken = JsonPath.read(refreshResult.getResponse().getContentAsString(), "$.access_token");

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(login.accessToken())))
        .andExpect(status().isUnauthorized());
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(refreshedAccessToken)))
        .andExpect(status().isOk());

    mvc.perform(post("/auth/logout").header(HttpHeaders.AUTHORIZATION, bearer(refreshedAccessToken)))
        .andExpect(status().isNoContent());
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(refreshedAccessToken)))
        .andExpect(status().isUnauthorized());
  }

  @Test
  void refreshRejectsInvalidToken() throws Exception {
    mvc.perform(post("/auth/refresh")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "refresh_token": "invalid-refresh-token"
                }
                """))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void loginRejectsUnsupportedSchemaVersion() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "+8613800138003",
                  "verification_code": "123456",
                  "terms_accepted": true
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @Test
  void socialLoginRejectsInvalidRequestContracts() throws Exception {
    for (String path : List.of("/auth/login/apple", "/auth/login/wechat")) {
      assertSocialLoginValidationFailure(path, """
          {
            "schema_version": 2,
            "provider_token": "provider-token",
            "terms_accepted": true
          }
          """);
      assertSocialLoginValidationFailure(path, """
          {
            "schema_version": 1,
            "terms_accepted": true
          }
          """);
      assertSocialLoginValidationFailure(path, """
          {
            "schema_version": 1,
            "provider_token": " ",
            "terms_accepted": true
          }
          """);
      assertSocialLoginValidationFailure(path, """
          {
            "schema_version": 1,
            "provider_token": "provider-token",
            "terms_accepted": false
          }
          """);
    }
  }

  private AuthTokens loginPhone(String phoneNumber) throws Exception {
    MvcResult result = mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "%s",
                  "verification_code": "123456",
                  "terms_accepted": true
                }
                """.formatted(phoneNumber)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.access_token", not(blankOrNullString())))
        .andExpect(jsonPath("$.refresh_token", not(blankOrNullString())))
        .andReturn();

    String body = result.getResponse().getContentAsString();
    return new AuthTokens(
        JsonPath.read(body, "$.user.user_id"),
        JsonPath.read(body, "$.access_token"),
        JsonPath.read(body, "$.refresh_token"));
  }

  private AuthTokens loginSocial(String path, String providerToken) throws Exception {
    MvcResult result = mvc.perform(post(path)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "provider_token": "%s",
                  "terms_accepted": true
                }
                """.formatted(providerToken)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.access_token", not(blankOrNullString())))
        .andExpect(jsonPath("$.refresh_token", not(blankOrNullString())))
        .andExpect(jsonPath("$.user.account_status").value("active"))
        .andReturn();

    String body = result.getResponse().getContentAsString();
    return new AuthTokens(
        JsonPath.read(body, "$.user.user_id"),
        JsonPath.read(body, "$.access_token"),
        JsonPath.read(body, "$.refresh_token"));
  }

  private void assertSocialLoginValidationFailure(String path, String content) throws Exception {
    mvc.perform(post(path)
            .contentType(MediaType.APPLICATION_JSON)
            .content(content))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  private void assertCurrentUserMatches(AuthTokens tokens) throws Exception {
    mvc.perform(get("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.user.user_id").value(tokens.userId()))
        .andExpect(jsonPath("$.user.account_status").value("active"));
  }

  private String bearer(String token) {
    return "Bearer " + token;
  }

  private record AuthTokens(String userId, String accessToken, String refreshToken) {}
}
