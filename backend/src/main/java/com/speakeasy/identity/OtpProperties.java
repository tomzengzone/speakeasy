package com.speakeasy.identity;

import java.time.Duration;
import java.util.LinkedHashSet;
import java.util.Set;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "speakeasy.identity.otp")
public class OtpProperties {
  private String defaultRegion = "CN";
  private Set<String> allowedCountries = new LinkedHashSet<>(Set.of("CN", "US"));
  private int codeLength = 6;
  private Duration challengeTtl = Duration.ofMinutes(5);
  private Duration maxChallengeTtl = Duration.ofMinutes(10);
  private Duration resendCooldown = Duration.ofSeconds(60);
  private int maxPhoneSendsPerHour = 5;
  private int maxPhoneSendsPerDay = 10;
  private int maxContextSendsPerHour = 20;
  private int maxIpSendsPerHour = 30;
  private int maxIpSendsPerDay = 100;
  private int maxDeviceSendsPerHour = 10;
  private int maxDeviceSendsPerDay = 30;
  private int maxInstallSendsPerHour = 10;
  private int maxInstallSendsPerDay = 30;
  private int maxAttemptsPerChallenge = 5;
  private int phoneFailureLockThreshold = 10;
  private Duration phoneFailureWindow = Duration.ofMinutes(30);
  private Duration phoneFailureLockDuration = Duration.ofMinutes(15);
  private Duration retentionInvalidationAfterExpiry = Duration.ofHours(24);
  private String hmacSecret = "local-dev-otp-hmac-secret";
  private String retentionPolicyVersion = "otp-retention-v1";
  private String currentConsentVersion = "terms-privacy-v1";
  private boolean captchaRequired = false;
  private String riskMode = "allow";
  private boolean enforceSecureTransport = false;
  private boolean trustForwardedProto = false;

  public String getDefaultRegion() {
    return defaultRegion;
  }

  public void setDefaultRegion(String defaultRegion) {
    String cleaned = clean(defaultRegion);
    this.defaultRegion = cleaned.isBlank() ? "CN" : cleaned.toUpperCase();
  }

  public Set<String> getAllowedCountries() {
    return allowedCountries;
  }

  public void setAllowedCountries(Set<String> allowedCountries) {
    if (allowedCountries == null || allowedCountries.isEmpty()) {
      return;
    }
    LinkedHashSet<String> cleaned = new LinkedHashSet<>();
    allowedCountries.stream()
        .map(this::clean)
        .filter(value -> !value.isBlank())
        .map(String::toUpperCase)
        .forEach(cleaned::add);
    if (!cleaned.isEmpty()) {
      this.allowedCountries = cleaned;
    }
  }

  public int getCodeLength() {
    return codeLength;
  }

  public void setCodeLength(int codeLength) {
    this.codeLength = Math.max(6, codeLength);
  }

  public Duration getChallengeTtl() {
    return challengeTtl.compareTo(maxChallengeTtl) > 0 ? maxChallengeTtl : challengeTtl;
  }

  public void setChallengeTtl(Duration challengeTtl) {
    this.challengeTtl = normalizePositive(challengeTtl, Duration.ofMinutes(5));
  }

  public Duration getMaxChallengeTtl() {
    return maxChallengeTtl;
  }

  public void setMaxChallengeTtl(Duration maxChallengeTtl) {
    Duration normalized = normalizePositive(maxChallengeTtl, Duration.ofMinutes(10));
    this.maxChallengeTtl = normalized.compareTo(Duration.ofMinutes(10)) > 0 ? Duration.ofMinutes(10) : normalized;
  }

  public Duration getResendCooldown() {
    return resendCooldown;
  }

  public void setResendCooldown(Duration resendCooldown) {
    this.resendCooldown = normalizePositive(resendCooldown, Duration.ofSeconds(60));
  }

  public int getMaxPhoneSendsPerHour() {
    return maxPhoneSendsPerHour;
  }

  public void setMaxPhoneSendsPerHour(int maxPhoneSendsPerHour) {
    this.maxPhoneSendsPerHour = Math.max(1, maxPhoneSendsPerHour);
  }

  public int getMaxPhoneSendsPerDay() {
    return maxPhoneSendsPerDay;
  }

  public void setMaxPhoneSendsPerDay(int maxPhoneSendsPerDay) {
    this.maxPhoneSendsPerDay = Math.max(1, maxPhoneSendsPerDay);
  }

  public int getMaxContextSendsPerHour() {
    return maxContextSendsPerHour;
  }

  public void setMaxContextSendsPerHour(int maxContextSendsPerHour) {
    this.maxContextSendsPerHour = Math.max(1, maxContextSendsPerHour);
  }

  public int getMaxIpSendsPerHour() {
    return maxIpSendsPerHour;
  }

  public void setMaxIpSendsPerHour(int maxIpSendsPerHour) {
    this.maxIpSendsPerHour = Math.max(1, maxIpSendsPerHour);
  }

  public int getMaxIpSendsPerDay() {
    return maxIpSendsPerDay;
  }

  public void setMaxIpSendsPerDay(int maxIpSendsPerDay) {
    this.maxIpSendsPerDay = Math.max(1, maxIpSendsPerDay);
  }

  public int getMaxDeviceSendsPerHour() {
    return maxDeviceSendsPerHour;
  }

  public void setMaxDeviceSendsPerHour(int maxDeviceSendsPerHour) {
    this.maxDeviceSendsPerHour = Math.max(1, maxDeviceSendsPerHour);
  }

  public int getMaxDeviceSendsPerDay() {
    return maxDeviceSendsPerDay;
  }

  public void setMaxDeviceSendsPerDay(int maxDeviceSendsPerDay) {
    this.maxDeviceSendsPerDay = Math.max(1, maxDeviceSendsPerDay);
  }

  public int getMaxInstallSendsPerHour() {
    return maxInstallSendsPerHour;
  }

  public void setMaxInstallSendsPerHour(int maxInstallSendsPerHour) {
    this.maxInstallSendsPerHour = Math.max(1, maxInstallSendsPerHour);
  }

  public int getMaxInstallSendsPerDay() {
    return maxInstallSendsPerDay;
  }

  public void setMaxInstallSendsPerDay(int maxInstallSendsPerDay) {
    this.maxInstallSendsPerDay = Math.max(1, maxInstallSendsPerDay);
  }

  public int getMaxAttemptsPerChallenge() {
    return maxAttemptsPerChallenge;
  }

  public void setMaxAttemptsPerChallenge(int maxAttemptsPerChallenge) {
    this.maxAttemptsPerChallenge = Math.max(1, maxAttemptsPerChallenge);
  }

  public int getPhoneFailureLockThreshold() {
    return phoneFailureLockThreshold;
  }

  public void setPhoneFailureLockThreshold(int phoneFailureLockThreshold) {
    this.phoneFailureLockThreshold = Math.max(1, phoneFailureLockThreshold);
  }

  public Duration getPhoneFailureWindow() {
    return phoneFailureWindow;
  }

  public void setPhoneFailureWindow(Duration phoneFailureWindow) {
    this.phoneFailureWindow = normalizePositive(phoneFailureWindow, Duration.ofMinutes(30));
  }

  public Duration getPhoneFailureLockDuration() {
    return phoneFailureLockDuration;
  }

  public void setPhoneFailureLockDuration(Duration phoneFailureLockDuration) {
    this.phoneFailureLockDuration = normalizePositive(phoneFailureLockDuration, Duration.ofMinutes(15));
  }

  public Duration getRetentionInvalidationAfterExpiry() {
    return retentionInvalidationAfterExpiry;
  }

  public void setRetentionInvalidationAfterExpiry(Duration retentionInvalidationAfterExpiry) {
    this.retentionInvalidationAfterExpiry = normalizePositive(retentionInvalidationAfterExpiry, Duration.ofHours(24));
  }

  public String getHmacSecret() {
    return hmacSecret;
  }

  public void setHmacSecret(String hmacSecret) {
    String cleaned = clean(hmacSecret);
    this.hmacSecret = cleaned.isBlank() ? this.hmacSecret : cleaned;
  }

  public String getRetentionPolicyVersion() {
    return retentionPolicyVersion;
  }

  public void setRetentionPolicyVersion(String retentionPolicyVersion) {
    String cleaned = clean(retentionPolicyVersion);
    this.retentionPolicyVersion = cleaned.isBlank() ? this.retentionPolicyVersion : cleaned;
  }

  public String getCurrentConsentVersion() {
    return currentConsentVersion;
  }

  public void setCurrentConsentVersion(String currentConsentVersion) {
    String cleaned = clean(currentConsentVersion);
    this.currentConsentVersion = cleaned.isBlank() ? this.currentConsentVersion : cleaned;
  }

  public boolean isCaptchaRequired() {
    return captchaRequired;
  }

  public void setCaptchaRequired(boolean captchaRequired) {
    this.captchaRequired = captchaRequired;
  }

  public String getRiskMode() {
    return riskMode;
  }

  public void setRiskMode(String riskMode) {
    String cleaned = clean(riskMode).toLowerCase();
    this.riskMode = switch (cleaned) {
      case "allow", "block", "step_up" -> cleaned;
      default -> "allow";
    };
  }

  public boolean isEnforceSecureTransport() {
    return enforceSecureTransport;
  }

  public void setEnforceSecureTransport(boolean enforceSecureTransport) {
    this.enforceSecureTransport = enforceSecureTransport;
  }

  public boolean isTrustForwardedProto() {
    return trustForwardedProto;
  }

  public void setTrustForwardedProto(boolean trustForwardedProto) {
    this.trustForwardedProto = trustForwardedProto;
  }

  private Duration normalizePositive(Duration value, Duration fallback) {
    return value == null || value.isZero() || value.isNegative() ? fallback : value;
  }

  private String clean(String value) {
    return value == null ? "" : value.trim();
  }
}
