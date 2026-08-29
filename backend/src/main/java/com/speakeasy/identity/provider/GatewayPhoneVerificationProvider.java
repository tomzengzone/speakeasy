package com.speakeasy.identity.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import org.springframework.http.HttpStatus;

final class GatewayPhoneVerificationProvider implements PhoneVerificationProvider {
  private final AuthProviderProperties.Phone properties;
  private final Duration timeout;
  private final HttpClient client;
  private final ObjectMapper mapper;

  GatewayPhoneVerificationProvider(
      AuthProviderProperties.Phone properties,
      Duration timeout,
      HttpClient client,
      ObjectMapper mapper) {
    this.properties = properties;
    this.timeout = timeout;
    this.client = client;
    this.mapper = mapper;
  }

  @Override
  public void requestCode(String phoneNumber) {
    HttpResponse<String> response = post(properties.getRequestUrl(), Map.of("phone_number", phoneNumber));
    if (response.statusCode() < 200 || response.statusCode() >= 300) throw unavailable();
  }

  @Override
  public void verify(String phoneNumber, String verificationCode) {
    HttpResponse<String> response = post(properties.getVerifyUrl(), Map.of(
        "phone_number", phoneNumber, "verification_code", verificationCode));
    if (response.statusCode() == 400 || response.statusCode() == 401) throw invalidCode();
    if (response.statusCode() < 200 || response.statusCode() >= 300) throw unavailable();
    try {
      JsonNode body = mapper.readTree(response.body());
      if (!body.path("valid").asBoolean(false)) throw invalidCode();
    } catch (ApiException exception) {
      throw exception;
    } catch (Exception exception) {
      throw unavailable();
    }
  }

  private HttpResponse<String> post(String url, Map<String, String> body) {
    try {
      HttpRequest request = HttpRequest.newBuilder(URI.create(url))
          .timeout(timeout)
          .header("Authorization", "Bearer " + properties.getBearerToken())
          .header("Content-Type", "application/json")
          .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)))
          .build();
      return client.send(request, HttpResponse.BodyHandlers.ofString());
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw unavailable();
    } catch (Exception exception) {
      throw unavailable();
    }
  }

  private ApiException invalidCode() {
    return new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Verification code is invalid.");
  }

  private ApiException unavailable() {
    return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "Phone verification is unavailable.");
  }
}
