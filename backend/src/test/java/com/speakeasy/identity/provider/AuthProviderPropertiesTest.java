package com.speakeasy.identity.provider;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class AuthProviderPropertiesTest {
  @Test
  void deterministicProvidersRequireExplicitTestOnlyOptIn() {
    AuthProviderProperties properties = new AuthProviderProperties();
    properties.setMode(AuthProviderProperties.Mode.DETERMINISTIC);

    assertThatThrownBy(properties::validate)
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("test-only opt-in");
  }

  @Test
  void productionModeFailsStartupUntilEveryProviderBoundaryIsConfigured() {
    AuthProviderProperties properties = new AuthProviderProperties();
    properties.setMode(AuthProviderProperties.Mode.PRODUCTION);

    assertThatThrownBy(properties::validate)
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("phone.request-url");
  }

  @Test
  void acceptsACompleteHttpsProductionBoundary() {
    AuthProviderProperties properties = new AuthProviderProperties();
    properties.setMode(AuthProviderProperties.Mode.PRODUCTION);
    properties.getPhone().setRequestUrl("https://verification.example.test/request");
    properties.getPhone().setVerifyUrl("https://verification.example.test/verify");
    properties.getPhone().setBearerToken("secret-from-runtime");
    properties.getApple().setClientId("com.example.speakeasy");
    properties.getWechat().setAppId("wechat-app-id");
    properties.getWechat().setAppSecret("wechat-secret");

    assertThatCode(properties::validate).doesNotThrowAnyException();
  }
}
