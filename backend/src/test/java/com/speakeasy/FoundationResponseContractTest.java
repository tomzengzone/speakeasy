package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import com.speakeasy.commerce.PaymentProviderEventRepository;
import com.speakeasy.commerce.PurchaseRepository;
import com.speakeasy.commerce.SubscriptionRepository;
import com.speakeasy.commerce.SubscriptionPlan;
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
class FoundationResponseContractTest {
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
  void authLoginReturnsOpenApiDtoNotSessionEntity() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138010",
                  "verification_code": "123456",
                  "terms_accepted": true
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.user.user_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.user.account_status").value("active"))
        .andExpect(jsonPath("$.access_token", not(blankOrNullString())))
        .andExpect(jsonPath("$.refresh_token", not(blankOrNullString())))
        .andExpect(jsonPath("$.expires_at", not(blankOrNullString())))
        .andExpect(jsonPath("$.session_id").doesNotExist())
        .andExpect(jsonPath("$.access_token_hash").doesNotExist())
        .andExpect(jsonPath("$.refresh_token_hash").doesNotExist())
        .andExpect(jsonPath("$.issued_at").doesNotExist());
  }

  @Test
  void currentUserReturnsProfileDtoNotPersistenceShape() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138011");

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.user.user_id").value(tokens.userId()))
        .andExpect(jsonPath("$.user.display_name").value("Phone User"))
        .andExpect(jsonPath("$.user.target_level").value("L1"))
        .andExpect(jsonPath("$.user.daily_minutes").value(10))
        .andExpect(jsonPath("$.user.created_at").doesNotExist())
        .andExpect(jsonPath("$.user.updated_at").doesNotExist())
        .andExpect(jsonPath("$.user.reminder_enabled").doesNotExist());
  }

  @Test
  void commercialFoundationListReturnsDtoNotJpaEntityShape() throws Exception {
    UUID planId = UUID.randomUUID();
    plans.save(new SubscriptionPlan(planId, "apple", "speakeasy.monthly", "monthly"));

    mvc.perform(get("/subscription/plans"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.plans[0].plan_id").value(planId.toString()))
        .andExpect(jsonPath("$.plans[0].product_id").value("speakeasy.monthly"))
        .andExpect(jsonPath("$.plans[0].subscription_plan_id").doesNotExist())
        .andExpect(jsonPath("$.plans[0].created_at").doesNotExist())
        .andExpect(jsonPath("$.plans[0].updated_at").doesNotExist());
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
        .andReturn();

    String body = result.getResponse().getContentAsString();
    return new AuthTokens(
        JsonPath.read(body, "$.user.user_id"),
        JsonPath.read(body, "$.access_token"),
        JsonPath.read(body, "$.refresh_token"));
  }

  private String bearer(String token) {
    return "Bearer " + token;
  }

  private record AuthTokens(String userId, String accessToken, String refreshToken) {}
}
