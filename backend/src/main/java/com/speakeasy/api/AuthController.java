package com.speakeasy.api;

import com.speakeasy.common.ApiException;
import com.speakeasy.common.CefrLevel;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.identity.AccountRecoveryCapabilityPolicy;
import com.speakeasy.identity.AccountSecurityService;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.IdentityService;
import com.speakeasy.identity.ratelimit.AuthRateLimitService;
import com.speakeasy.ops.AccountDeletionService;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthController {
  private final AuthService authService;
  private final IdentityService identityService;
  private final AccountDeletionService accountDeletionService;
  private final AccountSecurityService accountSecurityService;
  private final AuthRateLimitService rateLimits;
  private final AccountRecoveryCapabilityPolicy accountRecoveryCapability;

  public AuthController(
      AuthService authService,
      IdentityService identityService,
      AccountDeletionService accountDeletionService,
      AccountSecurityService accountSecurityService,
      AuthRateLimitService rateLimits,
      AccountRecoveryCapabilityPolicy accountRecoveryCapability) {
    this.authService = authService;
    this.identityService = identityService;
    this.accountDeletionService = accountDeletionService;
    this.accountSecurityService = accountSecurityService;
    this.rateLimits = rateLimits;
    this.accountRecoveryCapability = accountRecoveryCapability;
  }

  @PostMapping("/auth/login/phone")
  public AuthSessionResponse loginPhone(
      @Valid @RequestBody PhoneLoginRequest request, HttpServletRequest servletRequest) {
    rateLimits.check("phone-login", servletRequest,
        dimensions("device", request.deviceId(), "account", request.phoneNumber()));
    return AuthSessionResponse.from(authService.loginPhone(
        request.phoneNumber(), request.verificationCode(), request.termsAccepted(), request.deviceMetadata()));
  }

  @PostMapping("/auth/verification-codes/phone")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public PhoneVerificationCodeResponse requestPhoneVerificationCode(
      @Valid @RequestBody PhoneVerificationCodeRequest request,
      HttpServletRequest servletRequest) {
    rateLimits.check("phone-code-request", servletRequest,
        dimensions("device", request.deviceId(), "account", request.phoneNumber()));
    authService.requestPhoneVerificationCode(request.phoneNumber());
    return new PhoneVerificationCodeResponse(1, "sent");
  }

  @PostMapping("/auth/account-recovery/phone/verification-codes")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public PhoneAccountRecoveryCodeResponse requestPhoneAccountRecoveryCode(
      @RequestBody PhoneAccountRecoveryCodeRequest request,
      HttpServletRequest servletRequest,
      HttpServletResponse servletResponse) {
    requireAccountRecoveryEnabled(servletResponse);
    validateRecoverySchema(request.schemaVersion(), request.phoneNumber(), null, request.deviceId());
    rateLimits.check("phone-account-recovery-code-request", servletRequest,
        dimensions("device", request.deviceId(), "account", request.phoneNumber()));
    authService.requestPhoneAccountRecoveryCode(request.phoneNumber());
    servletResponse.setHeader("Cache-Control", "no-store");
    return new PhoneAccountRecoveryCodeResponse(1, "accepted");
  }

  @PostMapping("/auth/account-recovery/phone")
  public PhoneAccountRecoveryResponse recoverAccountByPhone(
      @RequestBody PhoneAccountRecoveryRequest request,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId,
      HttpServletRequest servletRequest,
      HttpServletResponse servletResponse) {
    requireAccountRecoveryEnabled(servletResponse);
    validateRecoverySchema(
        request.schemaVersion(), request.phoneNumber(), request.verificationCode(), request.deviceId());
    rateLimits.check("phone-account-recovery", servletRequest,
        dimensions("device", request.deviceId(), "account", request.phoneNumber()));
    authService.recoverPhoneAccount(
        request.phoneNumber(), request.verificationCode(), requestId);
    servletResponse.setHeader("Cache-Control", "no-store");
    return new PhoneAccountRecoveryResponse(1, "recovered", "login_phone");
  }

  private void requireAccountRecoveryEnabled(HttpServletResponse response) {
    response.setHeader("Cache-Control", "no-store");
    accountRecoveryCapability.requireEnabled();
  }

  @PostMapping("/auth/login/apple")
  public AuthSessionResponse loginApple(
      @Valid @RequestBody SocialLoginRequest request, HttpServletRequest servletRequest) {
    rateLimits.check("apple-login", servletRequest,
        dimensions("device", request.deviceId(), "credential", request.providerToken()));
    return AuthSessionResponse.from(authService.loginSocial(
        "apple", request.providerToken(), request.nonce(), request.termsAccepted(), request.deviceMetadata(),
        subject -> rateLimits.checkAdditional("apple-login", dimensions("account", subject),
            servletRequest.getHeader("X-Request-Id"))));
  }

  @PostMapping("/auth/login/wechat")
  public AuthSessionResponse loginWechat(
      @Valid @RequestBody SocialLoginRequest request, HttpServletRequest servletRequest) {
    rateLimits.check("wechat-login", servletRequest,
        dimensions("device", request.deviceId(), "credential", request.providerToken()));
    return AuthSessionResponse.from(authService.loginSocial(
        "wechat", request.providerToken(), request.nonce(), request.termsAccepted(), request.deviceMetadata(),
        subject -> rateLimits.checkAdditional("wechat-login", dimensions("account", subject),
            servletRequest.getHeader("X-Request-Id"))));
  }

  @PostMapping("/auth/refresh")
  public AuthSessionResponse refresh(
      @Valid @RequestBody RefreshTokenRequest request, HttpServletRequest servletRequest) {
    rateLimits.check("refresh", servletRequest,
        dimensions("device", request.deviceId(), "credential", request.refreshToken()));
    return AuthSessionResponse.from(authService.refresh(request.refreshToken(), identity ->
        rateLimits.checkAdditional("refresh", dimensions(
            "account", identity.userId().toString(), "family", identity.familyId().toString()),
            servletRequest.getHeader("X-Request-Id"))));
  }

  @PostMapping("/auth/logout")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void logout(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId,
      HttpServletRequest servletRequest) {
    checkSessionManagement(currentUser, servletRequest);
    accountSecurityService.logoutCurrent(currentUser.userId(), currentUser.sessionId(), requestId);
  }

  @GetMapping("/auth/sessions")
  public DeviceSessionsResponse sessions(
      @AuthenticationPrincipal CurrentUser currentUser, HttpServletRequest servletRequest) {
    checkSessionManagement(currentUser, servletRequest);
    return new DeviceSessionsResponse(
        1,
        accountSecurityService.listSessions(currentUser.userId(), currentUser.sessionId()).stream()
            .map(DeviceSessionDto::from)
            .toList());
  }

  @DeleteMapping("/auth/sessions/{sessionId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void revokeSession(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable UUID sessionId,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId,
      HttpServletRequest servletRequest) {
    checkSessionManagement(currentUser, servletRequest);
    accountSecurityService.revokeSession(currentUser.userId(), currentUser.sessionId(), sessionId, requestId);
  }

  @PostMapping("/auth/logout-others")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void logoutOthers(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId,
      HttpServletRequest servletRequest) {
    checkSessionManagement(currentUser, servletRequest);
    accountSecurityService.logoutOthers(currentUser.userId(), currentUser.sessionId(), requestId);
  }

  @PostMapping("/auth/logout-all")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void logoutAll(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId,
      HttpServletRequest servletRequest) {
    checkSessionManagement(currentUser, servletRequest);
    accountSecurityService.logoutAll(currentUser.userId(), currentUser.sessionId(), requestId);
  }

  @GetMapping("/user/me")
  public UserProfileResponse getMe(@AuthenticationPrincipal CurrentUser currentUser) {
    return UserProfileResponse.from(identityService.getCurrentUser(currentUser.userId()));
  }

  @PatchMapping("/user/me")
  public UserProfileResponse updateMe(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody UpdateUserProfileRequest request) {
    return UserProfileResponse.from(identityService.updateCurrentUser(currentUser.userId(),
        new IdentityService.UpdateUserProfileCommand(
            request.displayName(),
            request.avatarRef(),
            request.targetLevel(),
            request.dailyMinutes(),
            request.reminderEnabled(),
            request.reminderTime())));
  }

  @DeleteMapping("/user/me")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public AccountDeletionJobResponse requestAccountDeletion(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId) {
    return AccountDeletionJobResponse.from(
        1, accountDeletionService.requestDeletion(currentUser.userId(), idempotencyKey, requestId));
  }

  @GetMapping("/user/deletion-status")
  public AccountDeletionJobResponse deletionStatus(@AuthenticationPrincipal CurrentUser currentUser) {
    return AccountDeletionJobResponse.from(1, accountDeletionService.latestDeletionJob(currentUser.userId()));
  }

  public record PhoneLoginRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String phoneNumber,
      @NotBlank String verificationCode,
      @NotNull @AssertTrue Boolean termsAccepted,
      @Size(max = 120) String deviceId,
      @Size(max = 120) String deviceName,
      @Pattern(regexp = "^(ios|android|unknown)$") String platform,
      @Size(max = 40) String appVersion) {
    AuthService.DeviceMetadata deviceMetadata() {
      return new AuthService.DeviceMetadata(deviceId, deviceName, platform, appVersion);
    }
  }

  public record PhoneVerificationCodeRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String phoneNumber,
      @Size(max = 120) String deviceId) {}

  public record PhoneVerificationCodeResponse(int schemaVersion, String status) implements SchemaResponse {}

  public record PhoneAccountRecoveryCodeRequest(
      Integer schemaVersion,
      String phoneNumber,
      String deviceId) {}

  public record PhoneAccountRecoveryCodeResponse(int schemaVersion, String status)
      implements SchemaResponse {}

  public record PhoneAccountRecoveryRequest(
      Integer schemaVersion,
      String phoneNumber,
      String verificationCode,
      String deviceId) {}

  public record PhoneAccountRecoveryResponse(
      int schemaVersion,
      String status,
      String nextAction) implements SchemaResponse {}

  public record SocialLoginRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String providerToken,
      String nonce,
      @NotNull @AssertTrue Boolean termsAccepted,
      @Size(max = 120) String deviceId,
      @Size(max = 120) String deviceName,
      @Pattern(regexp = "^(ios|android|unknown)$") String platform,
      @Size(max = 40) String appVersion) {
    AuthService.DeviceMetadata deviceMetadata() {
      return new AuthService.DeviceMetadata(deviceId, deviceName, platform, appVersion);
    }
  }

  public record RefreshTokenRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String refreshToken,
      @Size(max = 120) String deviceId) {}

  private void checkSessionManagement(CurrentUser currentUser, HttpServletRequest servletRequest) {
    rateLimits.check("session-management", servletRequest, dimensions(
        "session", currentUser.sessionId().toString(), "account", currentUser.userId().toString()));
  }

  private static Map<String, String> dimensions(String... entries) {
    Map<String, String> result = new LinkedHashMap<>();
    for (int index = 0; index < entries.length; index += 2) {
      if (entries[index + 1] != null && !entries[index + 1].isBlank()) {
        result.put(entries[index], entries[index + 1]);
      }
    }
    return result;
  }

  private static void validateRecoverySchema(
      Integer schemaVersion, String phoneNumber, String verificationCode, String deviceId) {
    if (!Integer.valueOf(1).equals(schemaVersion)
        || phoneNumber == null || phoneNumber.isBlank() || phoneNumber.trim().length() > 32
        || (verificationCode != null
            && (verificationCode.isBlank() || verificationCode.trim().length() > 32))
        || (deviceId != null && deviceId.length() > 120)) {
      throw new com.speakeasy.common.ApiException(
          HttpStatus.BAD_REQUEST,
          "SCHEMA_VALIDATION_FAILED",
          "Account recovery request is invalid.");
    }
  }

  public record UpdateUserProfileRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String displayName,
      String avatarRef,
      @Pattern(regexp = CefrLevel.REGEXP) String targetLevel,
      @Min(1) Integer dailyMinutes,
      Boolean reminderEnabled,
      @Pattern(regexp = "^([01][0-9]|2[0-3]):[0-5][0-9]$") String reminderTime) {}

  public record AuthSessionResponse(
      int schemaVersion,
      UserProfileDto user,
      UUID sessionId,
      String accessToken,
      String refreshToken,
      Instant expiresAt,
      Instant refreshExpiresAt) implements SchemaResponse {
    static AuthSessionResponse from(AuthService.AuthSessionResult result) {
      return new AuthSessionResponse(
          1,
          UserProfileDto.from(result.user(), result.profile()),
          result.sessionId(),
          result.accessToken(),
          result.refreshToken(),
          result.expiresAt(),
          result.refreshExpiresAt());
    }
  }

  public record DeviceSessionsResponse(int schemaVersion, List<DeviceSessionDto> sessions) implements SchemaResponse {}

  public record DeviceSessionDto(
      UUID sessionId,
      boolean current,
      String deviceName,
      String platform,
      String appVersion,
      Instant createdAt,
      Instant lastActiveAt) {
    static DeviceSessionDto from(AccountSecurityService.SessionView session) {
      return new DeviceSessionDto(
          session.sessionId(), session.current(), session.deviceName(), session.platform(), session.appVersion(),
          session.createdAt(), session.lastActiveAt());
    }
  }

  public record UserProfileResponse(int schemaVersion, UserProfileDto user) implements SchemaResponse {
    static UserProfileResponse from(IdentityService.UserProfileView user) {
      return new UserProfileResponse(
          1,
          new UserProfileDto(
              user.userId(),
              user.displayName(),
              user.avatarRef(),
              user.locale(),
              user.targetLevel(),
              user.dailyMinutes(),
              user.accountStatus(),
              user.onboardingStatus()));
    }
  }

  public record UserProfileDto(
      UUID userId,
      String displayName,
      String avatarRef,
      String locale,
      String targetLevel,
      Integer dailyMinutes,
      String accountStatus,
      String onboardingStatus) {
    static UserProfileDto from(com.speakeasy.identity.UserAccount user, com.speakeasy.identity.UserProfile profile) {
      return new UserProfileDto(
          user.getUserId(),
          user.getDisplayName(),
          user.getAvatarRef(),
          user.getLocale(),
          profile.getTargetLevel(),
          profile.getDailyMinutes(),
          user.getAccountStatus(),
          user.getOnboardingStatus());
    }
  }

}
