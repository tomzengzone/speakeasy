package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.security.CurrentUser;
import com.speakeasy.security.TokenHasher;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
  private static final Duration ACCESS_TOKEN_TTL = Duration.ofMinutes(30);
  private static final Duration REFRESH_TOKEN_TTL = Duration.ofDays(30);

  private final UserAccountRepository users;
  private final UserProfileRepository profiles;
  private final AuthIdentityRepository identities;
  private final AuthSessionRepository sessions;
  private final AccountDeletionJobRepository deletionJobs;
  private final Clock clock;
  private final SecureRandom secureRandom = new SecureRandom();

  public AuthService(
      UserAccountRepository users,
      UserProfileRepository profiles,
      AuthIdentityRepository identities,
      AuthSessionRepository sessions,
      AccountDeletionJobRepository deletionJobs,
      Clock clock) {
    this.users = users;
    this.profiles = profiles;
    this.identities = identities;
    this.sessions = sessions;
    this.deletionJobs = deletionJobs;
    this.clock = clock;
  }

  @Transactional
  public AuthSessionResult loginPhone(String phoneNumber, String verificationCode, boolean termsAccepted) {
    if (!termsAccepted) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Terms must be accepted.");
    }
    if (phoneNumber == null || phoneNumber.isBlank() || verificationCode == null || verificationCode.isBlank()) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Phone number and verification code are required.");
    }
    return loginOrCreate("phone", phoneNumber.trim(), "Phone User");
  }

  @Transactional
  public AuthSessionResult loginSocial(String provider, String providerToken, boolean termsAccepted) {
    if (!termsAccepted) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Terms must be accepted.");
    }
    if (providerToken == null || providerToken.isBlank()) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Provider token is required.");
    }
    return loginOrCreate(provider, TokenHasher.hash(providerToken), provider + " User");
  }

  @Transactional
  public AuthSessionResult refresh(String refreshToken) {
    if (refreshToken == null || refreshToken.isBlank()) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Refresh token is required.");
    }
    Instant now = Instant.now(clock);
    AuthSession session = sessions.findByRefreshTokenHash(TokenHasher.hash(refreshToken))
        .filter(candidate -> candidate.canRefreshAt(now))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Refresh token is invalid."));

    UserAccount user = users.findById(session.getUserId())
        .filter(candidate -> "active".equals(candidate.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));

    IssuedTokens tokens = issueTokens();
    session.rotate(TokenHasher.hash(tokens.accessToken()), TokenHasher.hash(tokens.refreshToken()), now, now.plus(ACCESS_TOKEN_TTL),
        now.plus(REFRESH_TOKEN_TTL));
    return new AuthSessionResult(user, ensureProfile(user.getUserId(), user.getDisplayName(), now), tokens.accessToken(),
        tokens.refreshToken(), session.getExpiresAt());
  }

  @Transactional
  public void logout(UUID sessionId) {
    AuthSession session = sessions.findById(sessionId)
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Session is invalid."));
    session.revoke(Instant.now(clock));
  }

  @Transactional(readOnly = true)
  public Optional<CurrentUser> authenticateAccessToken(String accessToken) {
    if (accessToken == null || accessToken.isBlank()) {
      return Optional.empty();
    }
    Instant now = Instant.now(clock);
    return sessions.findByAccessTokenHash(TokenHasher.hash(accessToken))
        .filter(session -> session.isActiveAt(now))
        .flatMap(session -> users.findById(session.getUserId())
            .filter(user -> "active".equals(user.getAccountStatus()))
            .map(user -> new CurrentUser(user.getUserId(), session.getSessionId())));
  }

  @Transactional(readOnly = true)
  public Optional<CurrentUser> authenticateAccountDeletionRetry(String accessToken, String idempotencyKey) {
    if (accessToken == null || accessToken.isBlank() || idempotencyKey == null || idempotencyKey.isBlank()) {
      return Optional.empty();
    }
    return sessions.findByAccessTokenHash(TokenHasher.hash(accessToken))
        .flatMap(session -> users.findById(session.getUserId())
            .filter(user -> "deleted".equals(user.getAccountStatus()) || "deletion_requested".equals(user.getAccountStatus()))
            .filter(user -> deletionJobs.findByUserIdAndIdempotencyKey(user.getUserId(), idempotencyKey).isPresent())
            .map(user -> new CurrentUser(user.getUserId(), session.getSessionId())));
  }

  @Transactional
  public void revokeUserSessions(UUID userId) {
    Instant now = Instant.now(clock);
    sessions.findByUserIdAndStatus(userId, "active").forEach(session -> session.revoke(now));
  }

  private AuthSessionResult loginOrCreate(String provider, String providerSubject, String defaultDisplayName) {
    Instant now = Instant.now(clock);
    UserAccount user = identities.findByProviderAndProviderSubject(provider, providerSubject)
        .flatMap(identity -> users.findById(identity.getUserId()))
        .orElseGet(() -> createUser(provider, providerSubject, defaultDisplayName, now));

    if (!"active".equals(user.getAccountStatus())) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active.");
    }

    IssuedTokens tokens = issueTokens();
    AuthSession session = new AuthSession(
        UUID.randomUUID(),
        user.getUserId(),
        TokenHasher.hash(tokens.accessToken()),
        TokenHasher.hash(tokens.refreshToken()),
        now,
        now.plus(ACCESS_TOKEN_TTL),
        now.plus(REFRESH_TOKEN_TTL));
    sessions.save(session);
    return new AuthSessionResult(user, ensureProfile(user.getUserId(), user.getDisplayName(), now), tokens.accessToken(),
        tokens.refreshToken(), session.getExpiresAt());
  }

  private UserAccount createUser(String provider, String providerSubject, String defaultDisplayName, Instant now) {
    UserAccount user = users.save(new UserAccount(UUID.randomUUID(), defaultDisplayName, now));
    identities.save(new AuthIdentity(UUID.randomUUID(), user.getUserId(), provider, providerSubject, now));
    profiles.save(new UserProfile(user.getUserId(), user.getDisplayName(), "L1", 10, now));
    return user;
  }

  private UserProfile ensureProfile(UUID userId, String displayName, Instant now) {
    return profiles.findById(userId).orElseGet(() -> profiles.save(new UserProfile(userId, displayName, "L1", 10, now)));
  }

  private IssuedTokens issueTokens() {
    return new IssuedTokens(randomToken(), randomToken());
  }

  private String randomToken() {
    byte[] bytes = new byte[32];
    secureRandom.nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
  }

  public record AuthSessionResult(
      UserAccount user, UserProfile profile, String accessToken, String refreshToken, Instant expiresAt) {}

  private record IssuedTokens(String accessToken, String refreshToken) {}
}
