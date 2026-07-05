package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class FoundationErrorContractTest {
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
  void validationErrorUsesSharedErrorSchemaAndRequestId() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .header("X-Request-Id", "req_foundation_validation")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "+8613800138020",
                  "verification_code": "123456",
                  "terms_accepted": true
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.message", not(blankOrNullString())))
        .andExpect(jsonPath("$.error.request_id").value("req_foundation_validation"))
        .andExpect(jsonPath("$.error.details.field").value("schemaVersion"))
        .andExpect(jsonPath("$.trace").doesNotExist())
        .andExpect(jsonPath("$.exception").doesNotExist());
  }

  @Test
  void malformedJsonUsesSharedErrorSchema() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .header("X-Request-Id", "req_foundation_malformed")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.message").value("Request body is malformed."))
        .andExpect(jsonPath("$.error.request_id").value("req_foundation_malformed"))
        .andExpect(jsonPath("$.error.details.reason").value("malformed_json"))
        .andExpect(jsonPath("$.trace").doesNotExist())
        .andExpect(jsonPath("$.exception").doesNotExist());
  }

  @Test
  void unauthenticatedErrorUsesSharedErrorSchemaAndRequestId() throws Exception {
    mvc.perform(get("/user/me").header("X-Request-Id", "req_foundation_unauthenticated"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"))
        .andExpect(jsonPath("$.error.message", not(blankOrNullString())))
        .andExpect(jsonPath("$.error.request_id").value("req_foundation_unauthenticated"))
        .andExpect(jsonPath("$.error.details").isMap())
        .andExpect(jsonPath("$.trace").doesNotExist())
        .andExpect(jsonPath("$.exception").doesNotExist());
  }
}
