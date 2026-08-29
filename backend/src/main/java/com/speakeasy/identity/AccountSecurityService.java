package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AuthAuditService;
import java.time.Clock;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountSecurityService {
  private final UserAccountRepository users;
  private final AuthSessionRepository sessions;
  private final AuthRefreshTokenFamilyRepository families;
  private final AuthRefreshTokenRepository refreshTokens;
  private final AuthAuditService audit;
  private final AuthMetrics metrics;
  private final Clock clock;

  public AccountSecurityService(
      UserAccountRepository users,
      AuthSessionRepository sessions,
      AuthRefreshTokenFamilyRepository families,
      AuthRefreshTokenRepository refreshTokens,
      AuthAuditService audit,
      AuthMetrics metrics,
      Clock clock) {
    this.users = users;
    this.sessions = sessions;
    this.families = families;
    this.refreshTokens = refreshTokens;
    this.audit = audit;
    this.metrics = metrics;
    this.clock = clock;
  }

  @Transactional(readOnly = true)
  public List<SessionView> listSessions(UUID userId, UUID currentSessionId) {
    Instant now = Instant.now(clock);
    return sessions.findByUserIdOrderByLastActiveAtDesc(userId).stream()
        .filter(AuthSession::isActive)
        .filter(session -> !session.isSessionExpiredAt(now))
        .map(session -> new SessionView(
            session.getSessionId(),
            session.getSessionId().equals(currentSessionId),
            session.getDeviceName(),
            session.getPlatform(),
            session.getAppVersion(),
            session.getCreatedAt(),
            session.getLastActiveAt()))
        .sorted(Comparator.comparing(SessionView::current).reversed()
            .thenComparing(SessionView::lastActiveAt, Comparator.reverseOrder()))
        .toList();
  }

  @Transactional
  public void logoutCurrent(UUID userId, UUID sessionId, String requestId) {
    monitor("session_revoke", () -> {
      lockUser(userId);
      AuthSession session = lockOwnedSession(userId, sessionId);
      int revoked = revokeSession(session, "logout_current");
      audit.recordUserEvent(userId, "auth_session_logout_current", userId, sessionId,
          "logout_current", revoked, requestId);
      metrics.revocation("logout_current");
      return null;
    });
  }

  @Transactional
  public void revokeSession(UUID userId, UUID currentSessionId, UUID targetSessionId, String requestId) {
    monitor("session_revoke", () -> {
      lockUser(userId);
      AuthSession target = lockOwnedSession(userId, targetSessionId);
      int revoked = revokeSession(target, "revoked_by_user");
      audit.recordUserEvent(userId, "auth_session_revoked_by_user", userId, targetSessionId,
          "revoked_by_user", revoked, requestId);
      metrics.revocation("single");
      return null;
    });
  }

  @Transactional
  public int logoutOthers(UUID userId, UUID currentSessionId, String requestId) {
    return monitor("session_revoke", () -> {
      lockUser(userId);
      int revoked = revokeMatching(userId, session -> !session.getSessionId().equals(currentSessionId), "logout_others");
      audit.recordUserEvent(userId, "auth_sessions_logout_others", userId, currentSessionId,
          "logout_others", revoked, requestId);
      metrics.revocation("logout_others");
      return revoked;
    });
  }

  @Transactional
  public int logoutAll(UUID userId, UUID currentSessionId, String requestId) {
    return monitor("session_revoke", () -> {
      lockUser(userId);
      int revoked = revokeMatching(userId, session -> true, "logout_all");
      audit.recordUserEvent(userId, "auth_sessions_logout_all", userId, currentSessionId,
          "logout_all", revoked, requestId);
      metrics.revocation("logout_all");
      return revoked;
    });
  }

  @Transactional
  public int revokeUserSessions(UUID userId, String reasonCode) {
    return monitor("session_revoke", () -> {
      lockUser(userId);
      int revoked = revokeMatching(userId, session -> true, reasonCode);
      audit.recordSystemEvent("auth_sessions_revoked", userId, null, reasonCode, revoked, null);
      metrics.revocation(reasonCode);
      return revoked;
    });
  }

  @Transactional
  public int revokeForHighRiskCredentialChange(UUID userId, String reasonCode, String requestId) {
    UserAccount user = lockUser(userId);
    user.advanceSecurityEpoch(Instant.now(clock));
    int revoked = revokeMatching(userId, session -> true, reasonCode);
    audit.recordSystemEvent("auth_sessions_revoked_credential_change", userId, null, reasonCode, revoked, requestId);
    metrics.securityEvent("credential_change");
    metrics.securityOperation("credential_change", "success");
    return revoked;
  }

  @Transactional
  public AccountStatusChange disableAccount(
      UUID userId, String principalId, String reasonCode, String caseReference, String requestId) {
    return monitor("account_disable", () -> {
      UserAccount user = lockUser(userId);
      user.disable(reasonCode, Instant.now(clock));
      int revoked = revokeMatching(userId, session -> true, "account_disabled");
      audit.recordOpsEvent(principalId, "account_disabled", userId, reasonCode, revoked, caseReference, requestId);
      metrics.securityEvent("account_disabled");
      metrics.securityOperation("account_disable", "success");
      return new AccountStatusChange(userId, user.getAccountStatus(), revoked);
    });
  }

  @Transactional
  public AccountStatusChange enableAccount(
      UUID userId, String principalId, String reasonCode, String caseReference, String requestId) {
    return monitor("account_enable", () -> {
      UserAccount user = lockUser(userId);
      user.enable(Instant.now(clock));
      audit.recordOpsEvent(principalId, "account_enabled", userId, reasonCode, 0, caseReference, requestId);
      metrics.securityEvent("account_enabled");
      metrics.securityOperation("account_enable", "success");
      return new AccountStatusChange(userId, user.getAccountStatus(), 0);
    });
  }

  private UserAccount lockUser(UUID userId) {
    return users.findByIdForUpdate(userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "User was not found."));
  }

  private AuthSession lockOwnedSession(UUID userId, UUID sessionId) {
    AuthSession session = sessions.findByIdForUpdate(sessionId)
        .orElseThrow(AccountSecurityService::sessionNotFound);
    if (!session.getUserId().equals(userId)) throw sessionNotFound();
    return session;
  }

  private int revokeMatching(UUID userId, java.util.function.Predicate<AuthSession> predicate, String reasonCode) {
    int revoked = 0;
    for (AuthSession session : sessions.findByUserIdForUpdate(userId)) {
      if (predicate.test(session)) revoked += revokeSession(session, reasonCode);
    }
    return revoked;
  }

  private int revokeSession(AuthSession session, String reasonCode) {
    if (!session.isActive()) return 0;
    Instant now = Instant.now(clock);
    session.revoke(now, reasonCode);
    families.findByIdForUpdate(session.getRefreshTokenFamilyId()).ifPresent(family -> {
      family.revoke(now, reasonCode);
      refreshTokens.findByFamilyIdForUpdate(family.getFamilyId()).forEach(token -> token.revoke(now));
    });
    return 1;
  }

  private static ApiException sessionNotFound() {
    return new ApiException(HttpStatus.NOT_FOUND, "SESSION_NOT_FOUND", "Session was not found.");
  }

  private <T> T monitor(String operation, java.util.function.Supplier<T> work) {
    try {
      return work.get();
    } catch (RuntimeException exception) {
      if (!(exception instanceof ApiException)) metrics.securityOperation(operation, "failure");
      throw exception;
    }
  }

  public record SessionView(
      UUID sessionId,
      boolean current,
      String deviceName,
      String platform,
      String appVersion,
      Instant createdAt,
      Instant lastActiveAt) {}

  public record AccountStatusChange(UUID userId, String accountStatus, int revokedSessionCount) {}
}
