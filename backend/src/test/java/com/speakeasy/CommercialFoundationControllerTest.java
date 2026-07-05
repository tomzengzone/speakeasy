package com.speakeasy;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import com.speakeasy.commerce.PaymentProviderEventRepository;
import com.speakeasy.commerce.PurchaseRepository;
import com.speakeasy.commerce.SubscriptionRepository;
import com.speakeasy.commerce.SubscriptionPlan;
import com.speakeasy.commerce.SubscriptionPlanRepository;
import com.speakeasy.content.UserScenarioStateRepository;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthSession;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.identity.LearningRouteRepository;
import com.speakeasy.identity.OnboardingAssessmentRepository;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.UserProfileRepository;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.security.TokenHasher;
import com.speakeasy.usage.UsageLedger;
import com.speakeasy.usage.UsageLedgerRepository;
import com.speakeasy.usage.UsageReservationRepository;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CommercialFoundationControllerTest {
  private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
  private static final UUID OTHER_USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000002");
  private static final String ACCESS_TOKEN = "commercial-test-access-token";

  @Autowired MockMvc mvc;
  @Autowired UserAccountRepository users;
  @Autowired UserProfileRepository profiles;
  @Autowired AuthIdentityRepository identities;
  @Autowired AuthSessionRepository sessions;
  @Autowired SubscriptionPlanRepository plans;
  @Autowired PurchaseRepository purchases;
  @Autowired SubscriptionRepository subscriptions;
  @Autowired PaymentProviderEventRepository providerEvents;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired UsageReservationRepository reservations;
  @Autowired AccountDeletionJobRepository deletionJobs;
  @Autowired UserScenarioStateRepository userScenarioStates;
  @Autowired LearningRouteRepository routes;
  @Autowired OnboardingAssessmentRepository assessments;

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

    Instant now = Instant.now();
    users.save(new UserAccount(USER_ID, "Sample Name", now));
    sessions.save(new AuthSession(
        UUID.randomUUID(),
        USER_ID,
        TokenHasher.hash(ACCESS_TOKEN),
        TokenHasher.hash("commercial-test-refresh-token"),
        now,
        now.plusSeconds(1800),
        now.plusSeconds(86400)));
    plans.save(new SubscriptionPlan(UUID.randomUUID(), "apple", "speakeasy.monthly", "monthly"));
    entitlements.save(new EntitlementSnapshot(UUID.randomUUID(), USER_ID, "free", "{\"scenario\":true}", "{\"ai\":10}", now));
    ledgers.save(new UsageLedger(UUID.randomUUID(), USER_ID, "ai", "2026-05", 10));
  }

  @Test
  void listSubscriptionPlansReturnsOpenApiShapedResponse() throws Exception {
    mvc.perform(get("/subscription/plans"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.plans", hasSize(1)))
        .andExpect(jsonPath("$.plans[0].product_id").value("speakeasy.monthly"));
  }

  @Test
  void getEntitlementsReturnsLatestSnapshot() throws Exception {
    mvc.perform(get("/entitlements")
            .header(HttpHeaders.AUTHORIZATION, bearerToken())
            .header("X-User-Id", OTHER_USER_ID.toString()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.entitlement.plan").value("free"))
        .andExpect(jsonPath("$.entitlement.status").value("active"))
        .andExpect(jsonPath("$.entitlement.features.scenario").value(true))
        .andExpect(jsonPath("$.entitlement.generated_at").exists());
  }

  @Test
  void getUsageSummaryReturnsLedger() throws Exception {
    mvc.perform(get("/usage/summary").header(HttpHeaders.AUTHORIZATION, bearerToken()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.usage", hasSize(1)))
        .andExpect(jsonPath("$.usage[0].usage_family").value("ai"));
  }

  @Test
  void requestAccountDeletionCreatesJob() throws Exception {
    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearerToken())
            .header("Idempotency-Key", "commercial-delete-1"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.deletion_job_id").exists())
        .andExpect(jsonPath("$.status").value("completed"))
        .andExpect(jsonPath("$.requested_at").exists());
  }

  @Test
  void entitlementSummaryRequiresAuthentication() throws Exception {
    mvc.perform(get("/entitlements"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void usageSummaryRequiresAuthentication() throws Exception {
    mvc.perform(get("/usage/summary"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void releaseHealthRemainsWarningUntilProviderAndReleaseGatesExist() throws Exception {
    mvc.perform(get("/admin/release-health")
            .header(HttpHeaders.AUTHORIZATION, "Bearer ops-test-token"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("warn"));
  }

  @Test
  void releaseHealthRequiresOpsBearerToken() throws Exception {
    mvc.perform(get("/admin/release-health"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    mvc.perform(get("/admin/release-health").header(HttpHeaders.AUTHORIZATION, bearerToken()))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
  }

  private String bearerToken() {
    return "Bearer " + ACCESS_TOKEN;
  }
}
