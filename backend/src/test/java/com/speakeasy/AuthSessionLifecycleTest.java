package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import com.speakeasy.commerce.SubscriptionPlanRepository;
import com.speakeasy.content.UserScenarioStateRepository;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.AuthSession;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.identity.LearningRouteRepository;
import com.speakeasy.identity.OnboardingAssessmentRepository;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.UserProfileRepository;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.security.TokenHasher;
import com.speakeasy.usage.UsageLedgerRepository;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class AuthSessionLifecycleTest {
  @Autowired AuthService authService;
  @Autowired AuthSessionRepository sessions;
  @Autowired AuthIdentityRepository identities;
  @Autowired UserScenarioStateRepository userScenarioStates;
  @Autowired LearningRouteRepository routes;
  @Autowired OnboardingAssessmentRepository assessments;
  @Autowired UserProfileRepository profiles;
  @Autowired AccountDeletionJobRepository deletionJobs;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired SubscriptionPlanRepository plans;
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
    ledgers.deleteAll();
    plans.deleteAll();
    users.deleteAll();
  }

  @Test
  void expiredAccessTokenCannotAuthenticate() {
    String accessToken = "expired-access-token";
    UserAccount user = users.save(new UserAccount(UUID.randomUUID(), "Expired Access", Instant.now()));
    sessions.save(new AuthSession(
        UUID.randomUUID(),
        user.getUserId(),
        TokenHasher.hash(accessToken),
        TokenHasher.hash("refresh-still-valid"),
        Instant.now().minusSeconds(7200),
        Instant.now().minusSeconds(60),
        Instant.now().plusSeconds(86400)));

    assertThat(authService.authenticateAccessToken(accessToken)).isEmpty();
  }

  @Test
  void expiredRefreshTokenIsRejected() {
    String refreshToken = "expired-refresh-token";
    UserAccount user = users.save(new UserAccount(UUID.randomUUID(), "Expired Refresh", Instant.now()));
    sessions.save(new AuthSession(
        UUID.randomUUID(),
        user.getUserId(),
        TokenHasher.hash("access-still-valid"),
        TokenHasher.hash(refreshToken),
        Instant.now().minusSeconds(7200),
        Instant.now().plusSeconds(1800),
        Instant.now().minusSeconds(60)));

    assertThatThrownBy(() -> authService.refresh(refreshToken))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("Refresh token is invalid");
  }

  @Test
  void refreshRotatesTokensAndInvalidatesPreviousAccessToken() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138030", "123456", true);

    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());

    assertThat(refreshed.accessToken()).isNotEqualTo(login.accessToken());
    assertThat(refreshed.refreshToken()).isNotEqualTo(login.refreshToken());
    assertThat(authService.authenticateAccessToken(login.accessToken())).isEmpty();
    assertThat(authService.authenticateAccessToken(refreshed.accessToken())).isPresent();
  }

  @Test
  void revokeUserSessionsInvalidatesAllActiveSessions() {
    AuthService.AuthSessionResult first = authService.loginPhone("+8613800138031", "123456", true);
    AuthService.AuthSessionResult second = authService.loginPhone("+8613800138031", "654321", true);

    authService.revokeUserSessions(first.user().getUserId());

    assertThat(authService.authenticateAccessToken(first.accessToken())).isEmpty();
    assertThat(authService.authenticateAccessToken(second.accessToken())).isEmpty();
  }
}
