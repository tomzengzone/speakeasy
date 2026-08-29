package com.speakeasy.identity.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.http.HttpClient;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

@Configuration
@EnableConfigurationProperties(AuthProviderProperties.class)
public class AuthProviderConfiguration {
  @Bean
  PhoneVerificationProvider phoneVerificationProvider(
      AuthProviderProperties properties, ObjectMapper mapper) {
    return switch (properties.getMode()) {
      case DISABLED -> new DisabledAuthProviders();
      case DETERMINISTIC -> new DeterministicAuthProviders();
      case PRODUCTION -> new GatewayPhoneVerificationProvider(
          properties.getPhone(), properties.getTimeout(), httpClient(properties), mapper);
    };
  }

  @Bean
  SocialIdentityVerifier socialIdentityVerifier(
      AuthProviderProperties properties, ObjectMapper mapper) {
    return switch (properties.getMode()) {
      case DISABLED -> new DisabledAuthProviders();
      case DETERMINISTIC -> new DeterministicAuthProviders();
      case PRODUCTION -> new ProductionSocialIdentityVerifier(
          new AppleIdentityVerifier(appleDecoder(properties)),
          new WechatIdentityVerifier(
              properties.getWechat(), properties.getTimeout(), httpClient(properties), mapper));
    };
  }

  private HttpClient httpClient(AuthProviderProperties properties) {
    return HttpClient.newBuilder().connectTimeout(properties.getTimeout()).build();
  }

  private JwtDecoder appleDecoder(AuthProviderProperties properties) {
    NimbusJwtDecoder decoder = NimbusJwtDecoder
        .withJwkSetUri(properties.getApple().getJwkSetUri())
        .build();
    OAuth2TokenValidator<Jwt> issuer =
        JwtValidators.createDefaultWithIssuer(properties.getApple().getIssuer());
    OAuth2TokenValidator<Jwt> audience = jwt -> jwt.getAudience().contains(properties.getApple().getClientId())
        ? OAuth2TokenValidatorResult.success()
        : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Invalid audience.", null));
    decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(issuer, audience));
    return decoder;
  }
}
