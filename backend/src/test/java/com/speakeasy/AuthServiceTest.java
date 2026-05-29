package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import com.speakeasy.commerce.PaymentProviderEventRepository;
import com.speakeasy.commerce.PurchaseRepository;
import com.speakeasy.commerce.SubscriptionRepository;
import com.speakeasy.commerce.SubscriptionPlanRepository;
import com.speakeasy.content.UserScenarioStateRepository;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthService;
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
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class AuthServiceTest {
  @Autowired AuthService authService;
  @Autowired AuthSessionRepository sessions;
  @Autowired AuthIdentityRepository identities;
  @Autowired UserProfileRepository profiles;
  @Autowired AccountDeletionJobRepository deletionJobs;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired UsageReservationRepository reservations;
  @Autowired SubscriptionPlanRepository plans;
  @Autowired PurchaseRepository purchases;
  @Autowired SubscriptionRepository subscriptions;
  @Autowired PaymentProviderEventRepository providerEvents;
  @Autowired UserScenarioStateRepository userScenarioStates;
  @Autowired LearningRouteRepository routes;
  @Autowired OnboardingAssessmentRepository assessments;
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
  void loginCreatesRefreshableSessionBoundToUser() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138000", "123456", true);

    assertThat(authService.authenticateAccessToken(login.accessToken())).isPresent();

    AuthService.AuthSessionResult refresh = authService.refresh(login.refreshToken());

    assertThat(refresh.user().getUserId()).isEqualTo(login.user().getUserId());
    assertThat(refresh.accessToken()).isNotEqualTo(login.accessToken());
    assertThat(authService.authenticateAccessToken(login.accessToken())).isEmpty();
    assertThat(authService.authenticateAccessToken(refresh.accessToken())).isPresent();
  }

  @Test
  void logoutRevokesCurrentSession() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138000", "123456", true);
    var currentUser = authService.authenticateAccessToken(login.accessToken()).orElseThrow();

    authService.logout(currentUser.sessionId());

    assertThat(authService.authenticateAccessToken(login.accessToken())).isEmpty();
  }

  @Test
  void loginRejectsMissingTerms() {
    assertThatThrownBy(() -> authService.loginPhone("+8613800138000", "123456", false))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("Terms");
  }
}
