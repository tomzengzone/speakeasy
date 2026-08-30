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
import com.speakeasy.identity.AuthAccessTokenRepository;
import com.speakeasy.identity.AuthRefreshTokenFamilyRepository;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.identity.LearningRouteRepository;
import com.speakeasy.identity.OnboardingAssessmentRepository;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.UserProfileRepository;
import com.speakeasy.identity.ratelimit.AuthRateLimitException;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.security.TokenHasher;
import com.speakeasy.usage.UsageLedgerRepository;
import com.speakeasy.usage.UsageReservationRepository;
import java.time.Instant;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class AuthSessionLifecycleTest {
  @Autowired AuthService authService;
  @Autowired AuthAccessTokenRepository accessTokens;
  @Autowired AuthRefreshTokenFamilyRepository tokenFamilies;
  @Autowired AuthSessionRepository sessions;
  @Autowired AuthIdentityRepository identities;
  @Autowired UserScenarioStateRepository userScenarioStates;
  @Autowired LearningRouteRepository routes;
  @Autowired OnboardingAssessmentRepository assessments;
  @Autowired UserProfileRepository profiles;
  @Autowired AccountDeletionJobRepository deletionJobs;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired UsageReservationRepository reservations;
  @Autowired SubscriptionPlanRepository plans;
  @Autowired PurchaseRepository purchases;
  @Autowired SubscriptionRepository subscriptions;
  @Autowired PaymentProviderEventRepository providerEvents;
  @Autowired UserAccountRepository users;
  @Autowired JdbcTemplate jdbc;

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
  void expiredAccessTokenCannotAuthenticate() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138028", "123456", true);
    jdbc.update(
        "UPDATE auth_access_tokens SET expires_at = ? WHERE token_hash = ?",
        Instant.EPOCH, TokenHasher.hash(login.accessToken()));

    assertThat(authService.inspectAccessToken(login.accessToken()).code()).isEqualTo("ACCESS_TOKEN_EXPIRED");
  }

  @Test
  void expiredRefreshTokenIsRejected() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138029", "123456", true);
    jdbc.update(
        "UPDATE auth_refresh_tokens SET expires_at = ? WHERE token_hash = ?",
        Instant.EPOCH, TokenHasher.hash(login.refreshToken()));

    assertThatThrownBy(() -> authService.refresh(login.refreshToken()))
        .isInstanceOfSatisfying(ApiException.class,
            exception -> assertThat(exception.getCode()).isEqualTo("REFRESH_TOKEN_EXPIRED"));
  }

  @Test
  void refreshRotatesRefreshTokenAndKeepsBothUnexpiredAccessTokensValid() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138030", "123456", true);

    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());

    assertThat(refreshed.accessToken()).isNotEqualTo(login.accessToken());
    assertThat(refreshed.refreshToken()).isNotEqualTo(login.refreshToken());
    assertThat(authService.authenticateAccessToken(login.accessToken())).isPresent();
    assertThat(authService.authenticateAccessToken(refreshed.accessToken())).isPresent();
  }

  @Test
  void oldAccessTokenExpiresNaturallyWithoutInvalidatingRefreshedAccessToken() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138033", "123456", true);
    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());

    jdbc.update(
        "UPDATE auth_access_tokens SET expires_at = ? WHERE token_hash = ?",
        Instant.EPOCH, TokenHasher.hash(login.accessToken()));

    assertThat(authService.inspectAccessToken(login.accessToken()).code()).isEqualTo("ACCESS_TOKEN_EXPIRED");
    assertThat(authService.authenticateAccessToken(refreshed.accessToken())).isPresent();
  }

  @Test
  void logoutInvalidatesEveryAccessTokenAndTheActiveRefreshTokenForTheSession() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138034", "123456", true);
    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());

    authService.logout(login.sessionId());

    assertThat(authService.authenticateAccessToken(login.accessToken())).isEmpty();
    assertThat(authService.authenticateAccessToken(refreshed.accessToken())).isEmpty();
    assertThatThrownBy(() -> authService.refresh(refreshed.refreshToken()))
        .isInstanceOfSatisfying(ApiException.class,
            exception -> assertThat(exception.getCode()).isEqualTo("SESSION_REVOKED"));
  }

  @Test
  void refreshInheritsTheCanonicalGrantContextWithoutExpandingScope() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138035", "123456", true);
    var family = tokenFamilies.findBySessionId(login.sessionId()).orElseThrow();

    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());
    var refreshedAccess = accessTokens.findByTokenHash(TokenHasher.hash(refreshed.accessToken())).orElseThrow();

    assertThat(refreshedAccess.getClientId()).isEqualTo(family.getClientId());
    assertThat(refreshedAccess.getAudience()).isEqualTo(family.getAudience());
    assertThat(refreshedAccess.getScope()).isEqualTo(family.getScope());
  }

  @Test
  void refreshRateLimitGateRunsBeforeTokenRotation() {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138032", "123456", true);

    assertThatThrownBy(() -> authService.refresh(login.refreshToken(), identity -> {
      throw AuthRateLimitException.rejected("refresh", "family", Duration.ofSeconds(30));
    })).isInstanceOf(AuthRateLimitException.class);

    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());
    assertThat(refreshed.refreshToken()).isNotEqualTo(login.refreshToken());
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
