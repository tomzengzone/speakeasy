package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiMediaAssetRepository;
import com.speakeasy.ai.AiProviderInvocationMetricRepository;
import com.speakeasy.ai.AiRetentionJobRepository;
import com.speakeasy.ai.AiTtsCacheEntryRepository;
import com.speakeasy.ai.AiTtsCacheOwnerRepository;
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
import com.speakeasy.learning.ExpressionPracticeAttemptRepository;
import com.speakeasy.learning.FavoriteExpressionRepository;
import com.speakeasy.learning.LearningEvidenceRepository;
import com.speakeasy.learning.LearningHistoryEntryRepository;
import com.speakeasy.learning.MasteryRecordRepository;
import com.speakeasy.learning.PracticeQueueItemRepository;
import com.speakeasy.learning.ReviewItemRepository;
import com.speakeasy.learning.SavedExpressionRepository;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.ops.AuditLogRepository;
import com.speakeasy.practice.CoachFeedbackRepository;
import com.speakeasy.practice.PracticeSessionRepository;
import com.speakeasy.practice.PracticeTurnRepository;
import com.speakeasy.practice.SessionSummaryRepository;
import com.speakeasy.usage.UsageLedgerRepository;
import com.speakeasy.usage.UsageReservationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

abstract class BackendIntegrationTestSupport {
  @Autowired protected MockMvc mvc;
  @Autowired AccountDeletionJobRepository deletionJobs;
  @Autowired AuditLogRepository auditLogs;
  @Autowired UserScenarioStateRepository userScenarioStates;
  @Autowired LearningRouteRepository routes;
  @Autowired OnboardingAssessmentRepository assessments;
  @Autowired AuthSessionRepository sessions;
  @Autowired CoachFeedbackRepository coachFeedbacks;
  @Autowired SessionSummaryRepository sessionSummaries;
  @Autowired PracticeTurnRepository practiceTurns;
  @Autowired PracticeSessionRepository practiceSessions;
  @Autowired ExpressionPracticeAttemptRepository expressionAttempts;
  @Autowired PracticeQueueItemRepository practiceQueueItems;
  @Autowired FavoriteExpressionRepository favoriteExpressions;
  @Autowired LearningEvidenceRepository learningEvidences;
  @Autowired MasteryRecordRepository masteryRecords;
  @Autowired ReviewItemRepository reviewItems;
  @Autowired SavedExpressionRepository savedExpressions;
  @Autowired LearningHistoryEntryRepository learningHistoryEntries;
  @Autowired AuthIdentityRepository identities;
  @Autowired UserProfileRepository profiles;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired PaymentProviderEventRepository providerEvents;
  @Autowired SubscriptionRepository subscriptions;
  @Autowired PurchaseRepository purchases;
  @Autowired UsageReservationRepository usageReservations;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired SubscriptionPlanRepository plans;
  @Autowired UserAccountRepository users;
  @Autowired AiMediaAssetRepository mediaAssets;
  @Autowired AiTtsCacheEntryRepository ttsCacheEntries;
  @Autowired AiTtsCacheOwnerRepository ttsCacheOwners;
  @Autowired AiProviderInvocationMetricRepository aiProviderMetrics;
  @Autowired AiRetentionJobRepository aiRetentionJobs;

  @BeforeEach
  void cleanUserData() {
    deletionJobs.deleteAll();
    aiRetentionJobs.deleteAll();
    aiProviderMetrics.deleteAll();
    ttsCacheOwners.deleteAll();
    ttsCacheEntries.deleteAll();
    mediaAssets.deleteAll();
    auditLogs.deleteAll();
    expressionAttempts.deleteAll();
    favoriteExpressions.deleteAll();
    practiceQueueItems.deleteAll();
    reviewItems.deleteAll();
    savedExpressions.deleteAll();
    masteryRecords.deleteAll();
    learningHistoryEntries.deleteAll();
    learningEvidences.deleteAll();
    coachFeedbacks.deleteAll();
    sessionSummaries.deleteAll();
    practiceTurns.deleteAll();
    practiceSessions.deleteAll();
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
    usageReservations.deleteAll();
    ledgers.deleteAll();
    plans.deleteAll();
    users.deleteAll();
  }

  protected AuthTokens loginPhone(String phoneNumber) throws Exception {
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
        .andReturn();

    String body = result.getResponse().getContentAsString();
    return new AuthTokens(
        JsonPath.read(body, "$.user.user_id"),
        JsonPath.read(body, "$.access_token"),
        JsonPath.read(body, "$.refresh_token"));
  }

  protected String bearer(String token) {
    return "Bearer " + token;
  }

  protected record AuthTokens(String userId, String accessToken, String refreshToken) {}
}
