package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import com.speakeasy.common.CefrLevel;
import com.speakeasy.identity.provider.PhoneVerificationProvider;
import com.speakeasy.identity.provider.PhoneVerificationPurpose;
import com.speakeasy.identity.provider.SocialIdentityVerifier;
import com.speakeasy.ops.AccountDeletionJobRepository;
import com.speakeasy.ops.AuthAuditService;
import com.speakeasy.security.AuthScopes;
import com.speakeasy.security.CurrentUser;
import com.speakeasy.security.TokenHasher;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Consumer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
  private final UserAccountRepository users;
  private final UserProfileRepository profiles;
  private final AuthIdentityRepository identities;
  private final AuthSessionRepository sessions;
  private final AuthAccessTokenRepository accessTokens;
  private final AuthRefreshTokenFamilyRepository tokenFamilies;
  private final AuthRefreshTokenRepository refreshTokens;
  private final AccountDeletionJobRepository deletionJobs;
  private final AccountSecurityService accountSecurity;
  private final AuthAuditService audit;
  private final AuthMetrics metrics;
  private final PhoneVerificationProvider phoneVerification;
  private final SocialIdentityVerifier socialIdentities;
  private final Clock clock;
  private final Duration accessTokenTtl;
  private final Duration sessionIdleTtl;
  private final Duration sessionAbsoluteTtl;
  private final String clientId;
  private final String audience;
  private final AuthGrantPolicy grantPolicy;
  private final AccountRecoveryCapabilityPolicy accountRecoveryCapability;
  private final SecureRandom secureRandom = new SecureRandom();

  public AuthService(
      UserAccountRepository users,
      UserProfileRepository profiles,
      AuthIdentityRepository identities,
      AuthSessionRepository sessions,
      AuthAccessTokenRepository accessTokens,
      AuthRefreshTokenFamilyRepository tokenFamilies,
      AuthRefreshTokenRepository refreshTokens,
      AccountDeletionJobRepository deletionJobs,
      AccountSecurityService accountSecurity,
      AuthAuditService audit,
      AuthMetrics metrics,
      @Qualifier("phoneVerificationProvider") PhoneVerificationProvider phoneVerification,
      @Qualifier("socialIdentityVerifier") SocialIdentityVerifier socialIdentities,
      Clock clock,
      @Value("${speakeasy.auth.access-token-ttl:15m}") Duration accessTokenTtl,
      @Value("${speakeasy.auth.session-idle-ttl:30d}") Duration sessionIdleTtl,
      @Value("${speakeasy.auth.session-absolute-ttl:90d}") Duration sessionAbsoluteTtl,
      @Value("${speakeasy.auth.client-id:speakeasy-mobile}") String clientId,
      @Value("${speakeasy.auth.audience:speakeasy-api}") String audience,
      AuthGrantPolicy grantPolicy,
      AccountRecoveryCapabilityPolicy accountRecoveryCapability) {
    this.users = users;
    this.profiles = profiles;
    this.identities = identities;
    this.sessions = sessions;
    this.accessTokens = accessTokens;
    this.tokenFamilies = tokenFamilies;
    this.refreshTokens = refreshTokens;
    this.deletionJobs = deletionJobs;
    this.accountSecurity = accountSecurity;
    this.audit = audit;
    this.metrics = metrics;
    this.phoneVerification = phoneVerification;
    this.socialIdentities = socialIdentities;
    this.clock = clock;
    this.accessTokenTtl = accessTokenTtl;
    this.sessionIdleTtl = sessionIdleTtl;
    this.sessionAbsoluteTtl = sessionAbsoluteTtl;
    this.clientId = clientId;
    this.audience = audience;
    this.grantPolicy = grantPolicy;
    this.accountRecoveryCapability = accountRecoveryCapability;
  }

  @Transactional
  public AuthSessionResult loginPhone(String phoneNumber, String verificationCode, boolean termsAccepted) {
    return loginPhone(phoneNumber, verificationCode, termsAccepted, DeviceMetadata.unknown());
  }

  @Transactional
  public AuthSessionResult loginPhone(
      String phoneNumber, String verificationCode, boolean termsAccepted, DeviceMetadata device) {
    if (!termsAccepted) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Terms must be accepted.");
    }
    if (phoneNumber == null || phoneNumber.isBlank() || verificationCode == null || verificationCode.isBlank()) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Phone number and verification code are required.");
    }
    String normalizedPhone = phoneNumber.trim();
    phoneVerification.verify(
        normalizedPhone, verificationCode.trim(), PhoneVerificationPurpose.LOGIN);
    return loginOrCreate("phone", TokenHasher.hash(normalizedPhone), "Phone User", device);
  }

  public void requestPhoneVerificationCode(String phoneNumber) {
    if (phoneNumber == null || phoneNumber.isBlank()) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Phone number is required.");
    }
    phoneVerification.requestCode(phoneNumber.trim(), PhoneVerificationPurpose.LOGIN);
  }

  public void requestPhoneAccountRecoveryCode(String phoneNumber) {
    accountRecoveryCapability.requireEnabled();
    String normalizedPhone = validateRecoveryPhone(phoneNumber);
    try {
      phoneVerification.requestCode(
          normalizedPhone, PhoneVerificationPurpose.ACCOUNT_RECOVERY);
    } catch (ApiException exception) {
      throw recoveryProviderFailure(exception);
    }
  }

  @Transactional
  public void recoverPhoneAccount(
      String phoneNumber, String verificationCode, String requestId) {
    accountRecoveryCapability.requireEnabled();
    String normalizedPhone = validateRecoveryPhone(phoneNumber);
    if (verificationCode == null || verificationCode.isBlank()
        || verificationCode.trim().length() > 32) {
      throw schemaError("Verification code is required and must not exceed 32 characters.");
    }
    try {
      phoneVerification.verify(
          normalizedPhone,
          verificationCode.trim(),
          PhoneVerificationPurpose.ACCOUNT_RECOVERY);
    } catch (ApiException exception) {
      throw recoveryProviderFailure(exception);
    }

    UserAccount user = identities
        .findByProviderAndProviderSubject("phone", TokenHasher.hash(normalizedPhone))
        .flatMap(identity -> users.findByIdForUpdate(identity.getUserId()))
        .filter(account -> "active".equals(account.getAccountStatus()))
        .orElseThrow(AuthService::accountRecoveryFailed);
    accountSecurity.revokeForHighRiskCredentialChange(
        user.getUserId(), "account_recovery", requestId);
  }

  @Transactional
  public AuthSessionResult loginSocial(String provider, String providerToken, boolean termsAccepted) {
    return loginSocial(provider, providerToken, null, termsAccepted, DeviceMetadata.unknown(), identity -> {});
  }

  @Transactional
  public AuthSessionResult loginSocial(
      String provider, String providerToken, boolean termsAccepted, DeviceMetadata device) {
    return loginSocial(provider, providerToken, null, termsAccepted, device, identity -> {});
  }

  @Transactional
  public AuthSessionResult loginSocial(
      String provider,
      String providerToken,
      String nonce,
      boolean termsAccepted,
      DeviceMetadata device,
      Consumer<String> verifiedSubjectGate) {
    if (!termsAccepted) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Terms must be accepted.");
    }
    if (providerToken == null || providerToken.isBlank()) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Provider token is required.");
    }
    SocialIdentityVerifier.VerifiedIdentity identity =
        socialIdentities.verify(provider, providerToken, nonce);
    verifiedSubjectGate.accept(identity.subject());
    return loginOrCreate(
        provider, TokenHasher.hash(identity.subject()), provider + " User", device);
  }

  @Transactional(noRollbackFor = ApiException.class)
  public AuthSessionResult refresh(String refreshToken) {
    return refresh(refreshToken, identity -> {});
  }

  @Transactional(noRollbackFor = ApiException.class)
  public AuthSessionResult refresh(
      String refreshToken, Consumer<RefreshRateLimitIdentity> preRotationGate) {
    if (refreshToken == null || refreshToken.isBlank()) {
      metrics.refresh("invalid");
      throw authError("REFRESH_TOKEN_INVALID", "Refresh token is invalid.");
    }
    Instant now = Instant.now(clock);
    String tokenHash = TokenHasher.hash(refreshToken);
    AuthRefreshTokenRepository.TokenLocator locator = refreshTokens.findProjectedByTokenHash(tokenHash)
        .orElseThrow(() -> {
          metrics.refresh("invalid");
          return authError("REFRESH_TOKEN_INVALID", "Refresh token is invalid.");
        });
    preRotationGate.accept(new RefreshRateLimitIdentity(locator.getUserId(), locator.getFamilyId()));

    UserAccount user = users.findByIdForUpdate(locator.getUserId())
        .orElseThrow(() -> authError("REFRESH_TOKEN_INVALID", "Refresh token is invalid."));
    AuthSession session = sessions.findByIdForUpdate(locator.getSessionId())
        .orElseThrow(() -> authError("SESSION_REVOKED", "Session has been revoked."));
    AuthRefreshTokenFamily family = tokenFamilies.findByIdForUpdate(locator.getFamilyId())
        .orElseThrow(() -> authError("SESSION_REVOKED", "Session has been revoked."));
    AuthRefreshToken token = refreshTokens.findByIdForUpdate(locator.getTokenId())
        .orElseThrow(() -> authError("REFRESH_TOKEN_INVALID", "Refresh token is invalid."));

    if ("disabled".equals(user.getAccountStatus())) {
      metrics.refresh("account_disabled");
      throw authError("ACCOUNT_DISABLED", "Account is disabled.");
    }
    if (!"active".equals(user.getAccountStatus())) {
      metrics.refresh("session_revoked");
      throw authError("SESSION_REVOKED", "Session has been revoked.");
    }
    if ("used".equals(token.getStatus())) {
      revokeFamilyForReuse(user, session, family, now);
      metrics.refresh("token_reuse");
      metrics.securityEvent("token_reuse");
      metrics.securityOperation("token_reuse", "success");
      audit.recordSystemEvent("auth_token_reuse_detected", user.getUserId(), session.getSessionId(),
          "token_reuse", 1, null);
      throw authError("TOKEN_REUSE_DETECTED", "Refresh token reuse was detected.");
    }
    if (!session.isActive() || !family.isActive() || !"active".equals(token.getStatus())
        || session.getSecurityEpoch() != user.getSecurityEpoch()) {
      metrics.refresh("session_revoked");
      throw authError("SESSION_REVOKED", "Session has been revoked.");
    }
    if (token.isExpiredAt(now) || session.isSessionExpiredAt(now)) {
      session.revoke(now, "expired");
      family.revoke(now, "expired");
      token.revoke(now);
      metrics.refresh("expired");
      throw authError("REFRESH_TOKEN_EXPIRED", "Refresh token has expired.");
    }

    IssuedTokens issued = issueTokens();
    Instant accessExpiresAt = now.plus(accessTokenTtl);
    Instant refreshExpiresAt = minimum(now.plus(sessionIdleTtl), session.getAbsoluteExpiresAt());
    token.markUsed(now);
    AuthRefreshToken nextToken = new AuthRefreshToken(
        UUID.randomUUID(), family.getFamilyId(), session.getSessionId(), user.getUserId(), token.getTokenId(),
        TokenHasher.hash(issued.refreshToken()), now, refreshExpiresAt);
    refreshTokens.save(nextToken);
    accessTokens.save(new AuthAccessToken(
        UUID.randomUUID(), TokenHasher.hash(issued.accessToken()), session.getSessionId(), user.getUserId(),
        family.getClientId(), family.getAudience(), family.getScope(), now, accessExpiresAt));
    session.touch(now, sessionIdleTtl);
    metrics.refresh("success");
    return result(user, issued, session, accessExpiresAt, refreshExpiresAt);
  }

  @Transactional
  public void logout(UUID sessionId) {
    AuthSession session = sessions.findById(sessionId)
        .orElseThrow(() -> authError("SESSION_REVOKED", "Session has been revoked."));
    accountSecurity.logoutCurrent(session.getUserId(), sessionId, null);
  }

  @Transactional
  public AccessTokenInspection inspectAccessToken(String accessToken) {
    if (accessToken == null || accessToken.isBlank()) return failedAccess("ACCESS_TOKEN_INVALID");
    Instant now = Instant.now(clock);
    AuthAccessToken token = accessTokens.findByTokenHash(TokenHasher.hash(accessToken)).orElse(null);
    if (token == null || !token.isActive()
        || !clientId.equals(token.getClientId()) || !audience.equals(token.getAudience())) {
      return failedAccess("ACCESS_TOKEN_INVALID");
    }
    AuthSession session = sessions.findByIdForUpdate(token.getSessionId()).orElse(null);
    if (session == null || !token.getUserId().equals(session.getUserId())) {
      return failedAccess("ACCESS_TOKEN_INVALID", session);
    }
    UserAccount user = users.findById(session.getUserId()).orElse(null);
    if (user == null) return failedAccess("ACCESS_TOKEN_INVALID", session);
    if ("disabled".equals(user.getAccountStatus())) return failedAccess("ACCOUNT_DISABLED", session);
    if (!"active".equals(user.getAccountStatus()) || !session.isActive()
        || session.getSecurityEpoch() != user.getSecurityEpoch() || session.isSessionExpiredAt(now)) {
      return failedAccess("SESSION_REVOKED", session);
    }
    if (token.isExpiredAt(now)) return failedAccess("ACCESS_TOKEN_EXPIRED", session);
    session.touch(now, sessionIdleTtl);
    metrics.access("authenticated");
    return new AccessTokenInspection(
        "AUTHENTICATED", currentUser(token), session.getPlatform(), session.getAppVersion());
  }

  @Transactional
  public Optional<CurrentUser> authenticateAccessToken(String accessToken) {
    return Optional.ofNullable(inspectAccessToken(accessToken).currentUser());
  }

  @Transactional(readOnly = true)
  public Optional<CurrentUser> authenticateAccountDeletionRetry(String accessToken, String idempotencyKey) {
    if (accessToken == null || accessToken.isBlank() || idempotencyKey == null || idempotencyKey.isBlank()) {
      return Optional.empty();
    }
    return accessTokens.findByTokenHash(TokenHasher.hash(accessToken))
        .filter(token -> clientId.equals(token.getClientId()) && audience.equals(token.getAudience()))
        .flatMap(token -> sessions.findById(token.getSessionId())
            .filter(session -> token.getUserId().equals(session.getUserId()))
            .flatMap(session -> users.findById(session.getUserId())
            .filter(user -> "deleted".equals(user.getAccountStatus()) || "deletion_requested".equals(user.getAccountStatus()))
            .filter(user -> deletionJobs.findByUserIdAndIdempotencyKey(user.getUserId(), idempotencyKey).isPresent())
            .map(user -> currentUser(token))));
  }

  @Transactional
  public void revokeUserSessions(UUID userId) {
    accountSecurity.revokeUserSessions(userId, "account_deletion");
  }

  private AuthSessionResult loginOrCreate(
      String provider, String providerSubject, String defaultDisplayName, DeviceMetadata rawDevice) {
    Instant now = Instant.now(clock);
    UserAccount user = identities.findByProviderAndProviderSubject(provider, providerSubject)
        .flatMap(identity -> users.findByIdForUpdate(identity.getUserId()))
        .orElseGet(() -> createUser(provider, providerSubject, defaultDisplayName, now));

    if ("disabled".equals(user.getAccountStatus())) {
      metrics.login(provider, "account_disabled");
      throw authError("ACCOUNT_DISABLED", "Account is disabled.");
    }
    if (!"active".equals(user.getAccountStatus())) {
      metrics.login(provider, "rejected");
      throw authError("SESSION_REVOKED", "Account is not active.");
    }

    DeviceMetadata device = rawDevice == null ? DeviceMetadata.unknown() : rawDevice.normalized();
    IssuedTokens issued = issueTokens();
    UUID sessionId = UUID.randomUUID();
    UUID familyId = UUID.randomUUID();
    Instant absoluteExpiresAt = now.plus(sessionAbsoluteTtl);
    Instant refreshExpiresAt = minimum(now.plus(sessionIdleTtl), absoluteExpiresAt);
    Instant accessExpiresAt = now.plus(accessTokenTtl);
    String authorizedScope = AuthScopes.serialize(
        grantPolicy.scopesFor(new AuthGrantPolicy.LoginContext(clientId, provider)));
    AuthSession session = new AuthSession(
        sessionId, user.getUserId(), familyId, now, refreshExpiresAt, absoluteExpiresAt,
        device.deviceId(), device.deviceName(), device.platform(), device.appVersion(), user.getSecurityEpoch());
    sessions.save(session);
    tokenFamilies.save(new AuthRefreshTokenFamily(
        familyId, sessionId, user.getUserId(), clientId, audience, authorizedScope, now));
    refreshTokens.save(new AuthRefreshToken(
        UUID.randomUUID(), familyId, sessionId, user.getUserId(), null,
        TokenHasher.hash(issued.refreshToken()), now, refreshExpiresAt));
    accessTokens.save(new AuthAccessToken(
        UUID.randomUUID(), TokenHasher.hash(issued.accessToken()), sessionId, user.getUserId(),
        clientId, audience, authorizedScope, now, accessExpiresAt));
    audit.recordUserEvent(user.getUserId(), "auth_session_created", user.getUserId(), sessionId,
        provider, 1, null);
    metrics.login(provider, "success");
    return result(user, issued, session, accessExpiresAt, refreshExpiresAt);
  }

  private void revokeFamilyForReuse(
      UserAccount user, AuthSession session, AuthRefreshTokenFamily family, Instant now) {
    session.revoke(now, "token_reuse");
    family.revoke(now, "token_reuse");
    refreshTokens.findByFamilyIdForUpdate(family.getFamilyId()).forEach(token -> token.revoke(now));
  }

  private AccessTokenInspection failedAccess(String code) {
    return failedAccess(code, null);
  }

  private AccessTokenInspection failedAccess(String code, AuthSession session) {
    metrics.access(code.toLowerCase());
    return new AccessTokenInspection(
        code,
        null,
        session == null ? "unknown" : session.getPlatform(),
        session == null ? null : session.getAppVersion());
  }

  private AuthSessionResult result(
      UserAccount user,
      IssuedTokens issued,
      AuthSession session,
      Instant accessExpiresAt,
      Instant refreshExpiresAt) {
    Instant now = Instant.now(clock);
    return new AuthSessionResult(
        user, ensureProfile(user.getUserId(), user.getDisplayName(), now), session.getSessionId(),
        issued.accessToken(), issued.refreshToken(), accessExpiresAt, refreshExpiresAt);
  }

  private CurrentUser currentUser(AuthAccessToken token) {
    Set<String> scopes = AuthScopes.parse(token.getScope());
    return new CurrentUser(
        token.getUserId(), token.getSessionId(), token.getClientId(), token.getAudience(), scopes);
  }

  private UserAccount createUser(String provider, String providerSubject, String defaultDisplayName, Instant now) {
    UserAccount user = users.save(new UserAccount(UUID.randomUUID(), defaultDisplayName, now));
    identities.save(new AuthIdentity(UUID.randomUUID(), user.getUserId(), provider, providerSubject, now));
    profiles.save(new UserProfile(user.getUserId(), user.getDisplayName(), CefrLevel.DEFAULT, 10, now));
    return user;
  }

  private UserProfile ensureProfile(UUID userId, String displayName, Instant now) {
    return profiles.findById(userId)
        .orElseGet(() -> profiles.save(new UserProfile(userId, displayName, CefrLevel.DEFAULT, 10, now)));
  }

  private IssuedTokens issueTokens() {
    return new IssuedTokens(randomToken(), randomToken());
  }

  private String randomToken() {
    byte[] bytes = new byte[32];
    secureRandom.nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
  }

  private static Instant minimum(Instant first, Instant second) {
    return first.isBefore(second) ? first : second;
  }

  private static ApiException authError(String code, String message) {
    return new ApiException(HttpStatus.UNAUTHORIZED, code, message);
  }

  private String validateRecoveryPhone(String phoneNumber) {
    if (phoneNumber == null || phoneNumber.isBlank()
        || phoneNumber.trim().length() > 32) {
      throw schemaError("Phone number is required and must not exceed 32 characters.");
    }
    return phoneNumber.trim();
  }

  private static ApiException recoveryProviderFailure(ApiException exception) {
    if (exception.getStatus().is5xxServerError()) {
      return new ApiException(
          HttpStatus.SERVICE_UNAVAILABLE,
          "AUTH_SERVICE_UNAVAILABLE",
          "Authentication service is temporarily unavailable.",
          java.util.Map.of("retryable", true));
    }
    return accountRecoveryFailed();
  }

  private static ApiException accountRecoveryFailed() {
    return new ApiException(
        HttpStatus.UNAUTHORIZED,
        "ACCOUNT_RECOVERY_VERIFICATION_FAILED",
        "Account recovery could not be verified.");
  }

  private static ApiException schemaError(String message) {
    return new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", message);
  }

  public record DeviceMetadata(String deviceId, String deviceName, String platform, String appVersion) {
    public static DeviceMetadata unknown() {
      return new DeviceMetadata(null, "Unknown device", "unknown", null);
    }

    DeviceMetadata normalized() {
      return new DeviceMetadata(
          clean(deviceId, null, 120), clean(deviceName, "Unknown device", 120),
          normalizePlatform(platform), clean(appVersion, null, 40));
    }

    private static String normalizePlatform(String value) {
      String normalized = clean(value, "unknown", 40);
      return switch (normalized) {
        case "ios", "android", "unknown" -> normalized;
        default -> "unknown";
      };
    }

    private static String clean(String value, String fallback, int maxLength) {
      if (value == null || value.isBlank()) return fallback;
      String cleaned = value.trim();
      return cleaned.substring(0, Math.min(cleaned.length(), maxLength));
    }
  }

  public record AccessTokenInspection(
      String code, CurrentUser currentUser, String platform, String appVersion) {}

  public record RefreshRateLimitIdentity(UUID userId, UUID familyId) {}

  public record AuthSessionResult(
      UserAccount user,
      UserProfile profile,
      UUID sessionId,
      String accessToken,
      String refreshToken,
      Instant expiresAt,
      Instant refreshExpiresAt) {}

  private record IssuedTokens(String accessToken, String refreshToken) {}
}
