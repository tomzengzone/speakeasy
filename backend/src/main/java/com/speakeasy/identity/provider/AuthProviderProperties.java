package com.speakeasy.identity.provider;

import jakarta.annotation.PostConstruct;
import java.net.URI;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("speakeasy.auth.providers")
public class AuthProviderProperties {
  public enum Mode { DISABLED, DETERMINISTIC, PRODUCTION }

  private Mode mode = Mode.DISABLED;
  private boolean deterministicEnabled;
  private Duration timeout = Duration.ofSeconds(5);
  private final Phone phone = new Phone();
  private final Apple apple = new Apple();
  private final Wechat wechat = new Wechat();

  @PostConstruct
  void validate() {
    if (mode == Mode.DETERMINISTIC && !deterministicEnabled) {
      throw new IllegalStateException(
          "Deterministic authentication providers require an explicit test-only opt-in.");
    }
    if (mode != Mode.PRODUCTION) return;
    requireHttps(phone.requestUrl, "phone.request-url");
    requireHttps(phone.verifyUrl, "phone.verify-url");
    require(phone.bearerToken, "phone.bearer-token");
    require(apple.clientId, "apple.client-id");
    requireHttps(apple.jwkSetUri, "apple.jwk-set-uri");
    requireHttps(apple.issuer, "apple.issuer");
    require(wechat.appId, "wechat.app-id");
    require(wechat.appSecret, "wechat.app-secret");
    requireHttps(wechat.tokenUrl, "wechat.token-url");
    if (timeout == null || timeout.isZero() || timeout.isNegative()) {
      throw new IllegalStateException("Authentication provider timeout must be positive.");
    }
  }

  private void require(String value, String field) {
    if (value == null || value.isBlank()) {
      throw new IllegalStateException("Production authentication provider setting is required: " + field);
    }
  }

  private void requireHttps(String value, String field) {
    require(value, field);
    URI uri = URI.create(value);
    if (!"https".equalsIgnoreCase(uri.getScheme()) || uri.getHost() == null) {
      throw new IllegalStateException("Production authentication provider URL must use HTTPS: " + field);
    }
  }

  public Mode getMode() { return mode; }
  public void setMode(Mode mode) { this.mode = mode; }
  public boolean isDeterministicEnabled() { return deterministicEnabled; }
  public void setDeterministicEnabled(boolean deterministicEnabled) { this.deterministicEnabled = deterministicEnabled; }
  public Duration getTimeout() { return timeout; }
  public void setTimeout(Duration timeout) { this.timeout = timeout; }
  public Phone getPhone() { return phone; }
  public Apple getApple() { return apple; }
  public Wechat getWechat() { return wechat; }

  public static class Phone {
    private String requestUrl = "";
    private String verifyUrl = "";
    private String bearerToken = "";
    public String getRequestUrl() { return requestUrl; }
    public void setRequestUrl(String requestUrl) { this.requestUrl = clean(requestUrl); }
    public String getVerifyUrl() { return verifyUrl; }
    public void setVerifyUrl(String verifyUrl) { this.verifyUrl = clean(verifyUrl); }
    public String getBearerToken() { return bearerToken; }
    public void setBearerToken(String bearerToken) { this.bearerToken = clean(bearerToken); }
  }

  public static class Apple {
    private String clientId = "";
    private String issuer = "https://appleid.apple.com";
    private String jwkSetUri = "https://appleid.apple.com/auth/keys";
    public String getClientId() { return clientId; }
    public void setClientId(String clientId) { this.clientId = clean(clientId); }
    public String getIssuer() { return issuer; }
    public void setIssuer(String issuer) { this.issuer = clean(issuer); }
    public String getJwkSetUri() { return jwkSetUri; }
    public void setJwkSetUri(String jwkSetUri) { this.jwkSetUri = clean(jwkSetUri); }
  }

  public static class Wechat {
    private String appId = "";
    private String appSecret = "";
    private String tokenUrl = "https://api.weixin.qq.com/sns/oauth2/access_token";
    public String getAppId() { return appId; }
    public void setAppId(String appId) { this.appId = clean(appId); }
    public String getAppSecret() { return appSecret; }
    public void setAppSecret(String appSecret) { this.appSecret = clean(appSecret); }
    public String getTokenUrl() { return tokenUrl; }
    public void setTokenUrl(String tokenUrl) { this.tokenUrl = clean(tokenUrl); }
  }

  private static String clean(String value) {
    return value == null ? "" : value.trim();
  }
}
