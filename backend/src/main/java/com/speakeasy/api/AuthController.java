package com.speakeasy.api;

import com.speakeasy.common.ApiException;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.IdentityService;
import com.speakeasy.identity.OtpRequestContext;
import com.speakeasy.identity.OtpService;
import com.speakeasy.ops.AccountDeletionService;
import com.speakeasy.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthController {
  private final AuthService authService;
  private final OtpService otpService;
  private final IdentityService identityService;
  private final AccountDeletionService accountDeletionService;

  public AuthController(
      AuthService authService,
      OtpService otpService,
      IdentityService identityService,
      AccountDeletionService accountDeletionService) {
    this.authService = authService;
    this.otpService = otpService;
    this.identityService = identityService;
    this.accountDeletionService = accountDeletionService;
  }

  @PostMapping("/auth/otp/send")
  public OtpSendResponse sendOtp(@Valid @RequestBody OtpSendRequest request, HttpServletRequest servletRequest) {
    return OtpSendResponse.from(otpService.sendOtp(new OtpService.SendOtpCommand(
        request.phoneNumber(),
        Boolean.TRUE.equals(request.termsAccepted()),
        request.consentVersion(),
        request.captchaToken(),
        requestContext(servletRequest, request.deviceId(), request.installId()))));
  }

  @PostMapping("/auth/otp/step-up")
  public OtpStepUpResponse submitOtpStepUp(@Valid @RequestBody OtpStepUpRequest request, HttpServletRequest servletRequest) {
    return OtpStepUpResponse.from(otpService.submitStepUp(
        parseUuid(request.challengeId(), "challenge_id"),
        request.stepUpToken(),
        requestContext(servletRequest, null, null)));
  }

  @PostMapping("/auth/login/phone")
  public AuthSessionResponse loginPhone(@Valid @RequestBody PhoneLoginRequest request, HttpServletRequest servletRequest) {
    if (request.schemaVersion() == 1) {
      return AuthSessionResponse.from(authService.loginPhone(request.phoneNumber(), request.verificationCode(), request.termsAccepted()));
    }
    UUID challengeId = parseUuid(request.challengeId(), "challenge_id");
    return AuthSessionResponse.from(authService.loginPhone(
        challengeId,
        request.phoneNumber(),
        request.verificationCode(),
        request.termsAccepted(),
        requestContext(servletRequest, request.deviceId(), request.installId())));
  }

  @PostMapping("/auth/login/apple")
  public AuthSessionResponse loginApple(@Valid @RequestBody SocialLoginRequest request) {
    return AuthSessionResponse.from(authService.loginSocial("apple", request.providerToken(), request.termsAccepted()));
  }

  @PostMapping("/auth/login/wechat")
  public AuthSessionResponse loginWechat(@Valid @RequestBody SocialLoginRequest request) {
    return AuthSessionResponse.from(authService.loginSocial("wechat", request.providerToken(), request.termsAccepted()));
  }

  @PostMapping("/auth/refresh")
  public AuthSessionResponse refresh(@Valid @RequestBody RefreshTokenRequest request) {
    return AuthSessionResponse.from(authService.refresh(request.refreshToken()));
  }

  @PostMapping("/auth/logout")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void logout(@AuthenticationPrincipal CurrentUser currentUser) {
    authService.logout(currentUser.sessionId());
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

  public record OtpSendRequest(
      @NotNull @Min(2) @Max(2) Integer schemaVersion,
      @NotBlank @Size(min = 3, max = 32) String phoneNumber,
      @NotNull Boolean termsAccepted,
      @NotBlank @Size(max = 64) String consentVersion,
      @Size(min = 8, max = 4096) String captchaToken,
      @Size(min = 1, max = 128) String deviceId,
      @Size(min = 1, max = 128) String installId) {}

  public record OtpStepUpRequest(
      @NotNull @Min(2) @Max(2) Integer schemaVersion,
      @NotBlank @Size(min = 16, max = 160) String challengeId,
      @NotBlank @Size(min = 8, max = 4096) String stepUpToken) {}

  public record PhoneLoginRequest(
      @NotNull @Min(1) @Max(2) Integer schemaVersion,
      @Size(min = 16, max = 160) String challengeId,
      @NotBlank @Size(min = 3, max = 32) String phoneNumber,
      @NotBlank @Pattern(regexp = "^[0-9]{6,10}$") String verificationCode,
      @NotNull @AssertTrue Boolean termsAccepted,
      @Size(min = 1, max = 128) String deviceId,
      @Size(min = 1, max = 128) String installId) {}

  public record SocialLoginRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String providerToken,
      String nonce,
      @NotNull @AssertTrue Boolean termsAccepted) {}

  public record RefreshTokenRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, @NotBlank String refreshToken) {}

  public record UpdateUserProfileRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String displayName,
      String avatarRef,
      String targetLevel,
      @Min(1) Integer dailyMinutes,
      Boolean reminderEnabled,
      @Pattern(regexp = "^([01][0-9]|2[0-3]):[0-5][0-9]$") String reminderTime) {}

  public record AuthSessionResponse(
      int schemaVersion, UserProfileDto user, String accessToken, String refreshToken, Instant expiresAt) implements SchemaResponse {
    static AuthSessionResponse from(AuthService.AuthSessionResult result) {
      return new AuthSessionResponse(
          1,
          UserProfileDto.from(result.user(), result.profile()),
          result.accessToken(),
          result.refreshToken(),
          result.expiresAt());
    }
  }

  public record OtpSendResponse(
      int schemaVersion,
      UUID challengeId,
      Instant expiresAt,
      long resendAfterSeconds,
      String riskDecision,
      String stepUpStatus) implements SchemaResponse {
    static OtpSendResponse from(OtpService.SendOtpResult result) {
      return new OtpSendResponse(
          2,
          result.challengeId(),
          result.expiresAt(),
          result.resendAfterSeconds(),
          result.riskDecision(),
          result.stepUpStatus());
    }
  }

  public record OtpStepUpResponse(int schemaVersion, UUID challengeId, String stepUpStatus) implements SchemaResponse {
    static OtpStepUpResponse from(OtpService.StepUpResult result) {
      return new OtpStepUpResponse(2, result.challengeId(), result.stepUpStatus());
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

  private UUID parseUuid(String value, String field) {
    if (value == null || value.isBlank()) {
      throw validation(field + " is required.");
    }
    try {
      return UUID.fromString(value.trim());
    } catch (IllegalArgumentException exception) {
      throw validation(field + " is invalid.");
    }
  }

  private OtpRequestContext requestContext(HttpServletRequest request, String deviceId, String installId) {
    String requestId = request.getHeader("X-Request-Id");
    return new OtpRequestContext(
        requestId == null || requestId.isBlank() ? "unknown" : requestId,
        request.getRemoteAddr(),
        request.isSecure(),
        request.getHeader("X-Forwarded-Proto"),
        deviceId,
        installId);
  }

  private ApiException validation(String message) {
    return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", message);
  }

}
