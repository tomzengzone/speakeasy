package com.speakeasy.identity;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OtpService {
  static final String PURPOSE_LOGIN_OR_REGISTER = "login_or_register";
  private static final String HASH_VERSION = "hmac-sha256-v1";

  private final OtpChallengeRepository challenges;
  private final OtpRateCounterRepository rateCounters;
  private final OtpFailureLockRepository failureLocks;
  private final AuditLogRepository auditLogs;
  private final PhoneNumberNormalizer phoneNumberNormalizer;
  private final OtpCodeGenerator codeGenerator;
  private final OtpHashService hashService;
  private final OtpSmsTemplate smsTemplate;
  private final OtpSmsProvider smsProvider;
  private final OtpCaptchaVerifier captchaVerifier;
  private final OtpPhoneRiskProvider phoneRiskProvider;
  private final OtpStepUpProvider stepUpProvider;
  private final OtpProperties properties;
  private final ObjectMapper objectMapper;
  private final Clock clock;

  public OtpService(
      OtpChallengeRepository challenges,
      OtpRateCounterRepository rateCounters,
      OtpFailureLockRepository failureLocks,
      AuditLogRepository auditLogs,
      PhoneNumberNormalizer phoneNumberNormalizer,
      OtpCodeGenerator codeGenerator,
      OtpHashService hashService,
      OtpSmsTemplate smsTemplate,
      OtpSmsProvider smsProvider,
      OtpCaptchaVerifier captchaVerifier,
      OtpPhoneRiskProvider phoneRiskProvider,
      OtpStepUpProvider stepUpProvider,
      OtpProperties properties,
      ObjectMapper objectMapper,
      Clock clock) {
    this.challenges = challenges;
    this.rateCounters = rateCounters;
    this.failureLocks = failureLocks;
    this.auditLogs = auditLogs;
    this.phoneNumberNormalizer = phoneNumberNormalizer;
    this.codeGenerator = codeGenerator;
    this.hashService = hashService;
    this.smsTemplate = smsTemplate;
    this.smsProvider = smsProvider;
    this.captchaVerifier = captchaVerifier;
    this.phoneRiskProvider = phoneRiskProvider;
    this.stepUpProvider = stepUpProvider;
    this.properties = properties;
    this.objectMapper = objectMapper;
    this.clock = clock;
  }

  @Transactional(noRollbackFor = ApiException.class)
  public SendOtpResult sendOtp(SendOtpCommand command) {
    Instant now = Instant.now(clock);
    requireTermsAndConsent(command.termsAccepted(), command.consentVersion());
    requireSecureTransport(command.context());
    requireCaptcha(command.captchaToken(), command.context());

    String verifiedE164Phone = phoneNumberNormalizer.normalize(command.phoneNumber());
    String phoneHash = hashService.sha256(verifiedE164Phone);
    assertNotLocked(phoneHash, now);
    enforceSendRateLimits(phoneHash, command.context(), now);

    OtpRiskDecision riskDecision = phoneRiskProvider.assess(
        new OtpPhoneRiskProvider.OtpPhoneRiskRequest(verifiedE164Phone, phoneHash, PURPOSE_LOGIN_OR_REGISTER, command.context()));
    if (OtpRiskDecision.BLOCK.equals(riskDecision)) {
      audit("otp_risk_blocked", phoneHash, PURPOSE_LOGIN_OR_REGISTER, command.context(), Map.of("risk_decision", riskDecision.value()));
      throw new ApiException(HttpStatus.FORBIDDEN, "OTP_RISK_BLOCKED", "OTP request is blocked by risk policy.");
    }

    UUID challengeId = UUID.randomUUID();
    String code = codeGenerator.generate();
    Duration ttl = properties.getChallengeTtl();
    Instant expiresAt = now.plus(ttl);
    OtpStepUpStatus stepUpStatus =
        OtpRiskDecision.STEP_UP.equals(riskDecision) ? OtpStepUpStatus.PENDING : OtpStepUpStatus.NOT_REQUIRED;
    String contextHash = hashService.sha256(safe(command.context().remoteIp()) + "|"
        + safe(command.context().deviceId()) + "|" + safe(command.context().installId()));
    String digest = hashService.hmacDigest(challengeId, verifiedE164Phone, code);
    String message = smsTemplate.render(code, ttl);
    OtpChallenge challenge = new OtpChallenge(
        challengeId,
        verifiedE164Phone,
        phoneHash,
        PURPOSE_LOGIN_OR_REGISTER,
        HASH_VERSION,
        digest,
        now,
        now,
        expiresAt,
        properties.getMaxAttemptsPerChallenge(),
        contextHash,
        riskDecision,
        stepUpStatus,
        command.context().requestId(),
        properties.getRetentionPolicyVersion(),
        now);
    challenges.saveAndFlush(challenge);

    try {
      smsProvider.send(verifiedE164Phone, message);
    } catch (ApiException exception) {
      challenge.invalidate(now);
      challenges.saveAndFlush(challenge);
      audit("otp_provider_failure", phoneHash, PURPOSE_LOGIN_OR_REGISTER, command.context(), Map.of("risk_decision", riskDecision.value()));
      throw exception;
    }

    challenges.findLatestActiveByPhoneHashAndPurpose(phoneHash, PURPOSE_LOGIN_OR_REGISTER)
        .ifPresent(previous -> previous.invalidate(now));
    challenge.activate(now);
    challenges.saveAndFlush(challenge);
    audit("otp_sent", phoneHash, PURPOSE_LOGIN_OR_REGISTER, command.context(), Map.of(
        "risk_decision", riskDecision.value(),
        "step_up_status", stepUpStatus.value(),
        "expires_at", expiresAt.toString()));
    return new SendOtpResult(challengeId, expiresAt, properties.getResendCooldown().toSeconds(), riskDecision.value(), stepUpStatus.value());
  }

  @Transactional(noRollbackFor = ApiException.class)
  public ConsumedOtpChallenge verifyAndConsume(UUID challengeId, String phoneNumber, String verificationCode, OtpRequestContext context) {
    Instant now = Instant.now(clock);
    requireSecureTransport(context);
    if (challengeId == null || verificationCode == null || verificationCode.isBlank()) {
      throw invalidCode();
    }
    String verifiedE164Phone = phoneNumberNormalizer.normalize(phoneNumber);
    String phoneHash = hashService.sha256(verifiedE164Phone);
    assertNotLocked(phoneHash, now);

    OtpChallenge challenge = challenges.findActiveByIdForUpdate(challengeId)
        .orElseThrow(this::invalidCode);
    if (!phoneHash.equals(challenge.getPhoneHash()) || !verifiedE164Phone.equals(challenge.getPhoneE164())) {
      recordVerificationFailure(challenge, phoneHash, now, context);
      throw invalidCode();
    }
    if (!challenge.getExpiresAt().isAfter(now)) {
      challenge.expire(now);
      audit("otp_expired", challenge.getPhoneHash(), challenge.getPurpose(), context, Map.of("challenge_id", challenge.getChallengeId().toString()));
      throw new ApiException(HttpStatus.GONE, "OTP_EXPIRED", "OTP challenge has expired.");
    }
    if (OtpRiskDecision.BLOCK.equals(challenge.getRiskDecision())) {
      throw new ApiException(HttpStatus.FORBIDDEN, "OTP_RISK_BLOCKED", "OTP request is blocked by risk policy.");
    }
    if (requiresCompletedStepUp(challenge.getStepUpStatus())) {
      throw new ApiException(HttpStatus.FORBIDDEN, "OTP_STEP_UP_REQUIRED", "Additional verification is required.");
    }

    String candidateDigest = hashService.hmacDigest(challenge.getChallengeId(), verifiedE164Phone, verificationCode);
    if (!hashService.constantTimeEquals(challenge.getOtpHmacDigest(), candidateDigest)) {
      recordVerificationFailure(challenge, phoneHash, now, context);
      throw invalidCode();
    }

    challenge.consume(now);
    audit("otp_verify_success", challenge.getPhoneHash(), challenge.getPurpose(), context, Map.of("challenge_id", challenge.getChallengeId().toString()));
    return new ConsumedOtpChallenge(challenge.getChallengeId(), challenge.getPhoneE164());
  }

  @Transactional(noRollbackFor = ApiException.class)
  public StepUpResult submitStepUp(UUID challengeId, String stepUpToken, OtpRequestContext context) {
    requireSecureTransport(context);
    if (challengeId == null || stepUpToken == null || stepUpToken.isBlank()) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Step-up token is required.");
    }
    Instant now = Instant.now(clock);
    OtpChallenge challenge = challenges.findActiveByIdForUpdate(challengeId)
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "OTP_INVALID_CODE", "OTP challenge is invalid."));
    if (!challenge.getExpiresAt().isAfter(now)) {
      challenge.expire(now);
      throw new ApiException(HttpStatus.GONE, "OTP_EXPIRED", "OTP challenge has expired.");
    }
    OtpStepUpStatus result = stepUpProvider.verify(new OtpStepUpProvider.OtpStepUpVerification(
        challenge.getChallengeId(), challenge.getPhoneHash(), challenge.getPurpose(), stepUpToken, context));
    if (OtpStepUpStatus.PASSED.equals(result)) {
      challenge.updateStepUpStatus(OtpStepUpStatus.PASSED, now);
      audit("otp_step_up_passed", challenge.getPhoneHash(), challenge.getPurpose(), context,
          Map.of("challenge_id", challenge.getChallengeId().toString()));
      return new StepUpResult(challenge.getChallengeId(), OtpStepUpStatus.PASSED.value());
    }
    OtpStepUpStatus blockedStatus = OtpStepUpStatus.BLOCKED.equals(result) ? OtpStepUpStatus.BLOCKED : OtpStepUpStatus.FAILED;
    challenge.updateStepUpStatus(blockedStatus, now);
    audit("otp_step_up_blocked", challenge.getPhoneHash(), challenge.getPurpose(), context,
        Map.of("challenge_id", challenge.getChallengeId().toString(), "step_up_status", blockedStatus.value()));
    throw new ApiException(HttpStatus.FORBIDDEN, "OTP_RISK_BLOCKED", "Step-up verification failed.");
  }

  @Transactional
  public int invalidateExpiredChallengeMaterial() {
    Instant now = Instant.now(clock);
    Instant expiresBefore = now.minus(properties.getRetentionInvalidationAfterExpiry());
    int invalidated = challenges.invalidateExpiredChallenges(expiresBefore, now);
    audit("otp_retention_cleanup", "otp:retention", PURPOSE_LOGIN_OR_REGISTER, OtpRequestContext.empty(), Map.of(
        "retention_policy_version", properties.getRetentionPolicyVersion(),
        "invalidated_count", invalidated));
    return invalidated;
  }

  private void requireTermsAndConsent(boolean termsAccepted, String consentVersion) {
    if (!termsAccepted || consentVersion == null || !properties.getCurrentConsentVersion().equals(consentVersion.trim())) {
      throw new ApiException(HttpStatus.FORBIDDEN, "OTP_CONSENT_REQUIRED", "Current terms and privacy consent is required.");
    }
  }

  private void requireSecureTransport(OtpRequestContext context) {
    if (properties.isEnforceSecureTransport() && !context.hasTrustedSecureTransport(properties.isTrustForwardedProto())) {
      throw new ApiException(HttpStatus.FORBIDDEN, "OTP_INSECURE_TRANSPORT", "OTP requires a secure transport boundary.");
    }
  }

  private void requireCaptcha(String captchaToken, OtpRequestContext context) {
    if (properties.isCaptchaRequired() && (captchaToken == null || captchaToken.isBlank())) {
      throw new ApiException(HttpStatus.FORBIDDEN, "OTP_CAPTCHA_REQUIRED", "CAPTCHA verification is required.");
    }
    if (properties.isCaptchaRequired()) {
      captchaVerifier.verify(captchaToken, context);
    }
  }

  private boolean requiresCompletedStepUp(OtpStepUpStatus status) {
    return !(OtpStepUpStatus.NOT_REQUIRED.equals(status) || OtpStepUpStatus.PASSED.equals(status));
  }

  private void enforceSendRateLimits(String phoneHash, OtpRequestContext context, Instant now) {
    Optional<OtpChallenge> latest = challenges.findLatestSuccessfulSendByPhoneHashAndPurpose(phoneHash, PURPOSE_LOGIN_OR_REGISTER);
    if (latest.isPresent() && latest.get().getSentAt().plus(properties.getResendCooldown()).isAfter(now)) {
      audit("otp_rate_limited", phoneHash, PURPOSE_LOGIN_OR_REGISTER, context, Map.of("limit", "resend_cooldown"));
      throw rateLimited();
    }
    incrementAndAssert("phone_hour", phoneHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofHours(1), properties.getMaxPhoneSendsPerHour());
    incrementAndAssert("phone_day", phoneHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofDays(1), properties.getMaxPhoneSendsPerDay());
    String ipHash = hashService.sha256(safe(context.remoteIp()));
    incrementAndAssert("ip_hour", ipHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofHours(1), properties.getMaxIpSendsPerHour());
    incrementAndAssert("ip_day", ipHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofDays(1), properties.getMaxIpSendsPerDay());
    if (context.deviceId() != null && !context.deviceId().isBlank()) {
      String deviceHash = hashService.sha256(context.deviceId().trim());
      incrementAndAssert("device_hour", deviceHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofHours(1), properties.getMaxDeviceSendsPerHour());
      incrementAndAssert("device_day", deviceHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofDays(1), properties.getMaxDeviceSendsPerDay());
    }
    if (context.installId() != null && !context.installId().isBlank()) {
      String installHash = hashService.sha256(context.installId().trim());
      incrementAndAssert("install_hour", installHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofHours(1), properties.getMaxInstallSendsPerHour());
      incrementAndAssert("install_day", installHash, PURPOSE_LOGIN_OR_REGISTER, now, Duration.ofDays(1), properties.getMaxInstallSendsPerDay());
    }
  }

  private void incrementAndAssert(
      String subjectType, String subjectHash, String purpose, Instant now, Duration windowDuration, int maxCount) {
    Instant windowStart = bucketStart(now, windowDuration);
    Instant windowEnd = windowStart.plus(windowDuration);
    OtpRateCounter counter = rateCounters.findByUniqueKeyForUpdate(subjectType, subjectHash, purpose, windowStart, windowEnd)
        .orElseGet(() -> rateCounters.save(new OtpRateCounter(UUID.randomUUID(), subjectType, subjectHash, purpose, windowStart, windowEnd, now)));
    if (counter.getCount() >= maxCount) {
      throw rateLimited();
    }
    counter.increment(now);
  }

  private Instant bucketStart(Instant now, Duration duration) {
    long seconds = duration.getSeconds();
    return Instant.ofEpochSecond((now.getEpochSecond() / seconds) * seconds);
  }

  private void assertNotLocked(String phoneHash, Instant now) {
    failureLocks.findByPhoneHashAndPurpose(phoneHash, PURPOSE_LOGIN_OR_REGISTER)
        .filter(lock -> lock.isLockedAt(now))
        .ifPresent(lock -> {
          throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "OTP_ATTEMPTS_LOCKED", "Too many OTP attempts.");
        });
  }

  private void recordVerificationFailure(OtpChallenge challenge, String phoneHash, Instant now, OtpRequestContext context) {
    challenge.recordAttempt(now);
    OtpFailureLock failureLock = failureLocks.findByPhoneHashAndPurposeForUpdate(phoneHash, PURPOSE_LOGIN_OR_REGISTER)
        .orElseGet(() -> failureLocks.save(new OtpFailureLock(UUID.randomUUID(), phoneHash, PURPOSE_LOGIN_OR_REGISTER, now, now)));
    if (failureLock.getWindowStart().plus(properties.getPhoneFailureWindow()).isBefore(now)) {
      failureLock.resetWindow(now, now);
    }
    failureLock.recordFailure(now);
    boolean challengeLocked = challenge.getAttemptCount() >= challenge.getMaxAttempts();
    boolean phoneLocked = failureLock.getFailureCount() >= properties.getPhoneFailureLockThreshold();
    if (challengeLocked) {
      challenge.lock(now);
    }
    if (phoneLocked) {
      failureLock.lockUntil(now.plus(properties.getPhoneFailureLockDuration()), now);
    }
    audit("otp_verify_failure", challenge.getPhoneHash(), challenge.getPurpose(), context, Map.of(
        "challenge_id", challenge.getChallengeId().toString(),
        "challenge_locked", challengeLocked,
        "phone_locked", phoneLocked));
  }

  private ApiException invalidCode() {
    return new ApiException(HttpStatus.UNAUTHORIZED, "OTP_INVALID_CODE", "OTP verification failed.");
  }

  private ApiException rateLimited() {
    return new ApiException(HttpStatus.TOO_MANY_REQUESTS, "OTP_RATE_LIMITED", "OTP rate limit exceeded.");
  }

  private void audit(String eventType, String phoneHash, String purpose, OtpRequestContext context, Map<String, Object> details) {
    Map<String, Object> safeDetails = new LinkedHashMap<>();
    safeDetails.put("schema_version", 1);
    safeDetails.put("phone_hash", phoneHash);
    safeDetails.put("purpose", purpose);
    safeDetails.put("risk_decision", details.getOrDefault("risk_decision", "unknown"));
    safeDetails.put("retention_policy_version", properties.getRetentionPolicyVersion());
    safeDetails.putAll(details);
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "system",
        "identity_otp",
        eventType,
        "phone:" + phoneHash,
        toJson(safeDetails),
        context.requestId(),
        Instant.now(clock)));
  }

  private String toJson(Map<String, Object> details) {
    try {
      return objectMapper.writeValueAsString(details);
    } catch (JsonProcessingException exception) {
      return "{\"schema_version\":1,\"summary\":\"redacted\"}";
    }
  }

  private String safe(String value) {
    return value == null || value.isBlank() ? "unknown" : value.trim();
  }

  public record SendOtpCommand(
      String phoneNumber,
      boolean termsAccepted,
      String consentVersion,
      String captchaToken,
      OtpRequestContext context) {}

  public record SendOtpResult(
      UUID challengeId,
      Instant expiresAt,
      long resendAfterSeconds,
      String riskDecision,
      String stepUpStatus) {}

  public record ConsumedOtpChallenge(UUID challengeId, String verifiedE164Phone) {}

  public record StepUpResult(UUID challengeId, String stepUpStatus) {}
}
