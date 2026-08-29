package com.speakeasy.identity.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.springframework.http.HttpStatus;

final class WechatIdentityVerifier {
  private final AuthProviderProperties.Wechat properties;
  private final Duration timeout;
  private final HttpClient client;
  private final ObjectMapper mapper;

  WechatIdentityVerifier(
      AuthProviderProperties.Wechat properties,
      Duration timeout,
      HttpClient client,
      ObjectMapper mapper) {
    this.properties = properties;
    this.timeout = timeout;
    this.client = client;
    this.mapper = mapper;
  }

  SocialIdentityVerifier.VerifiedIdentity verify(String code) {
    if (code == null || code.isBlank()) throw invalid();
    String query = "appid=" + encode(properties.getAppId())
        + "&secret=" + encode(properties.getAppSecret())
        + "&code=" + encode(code.trim())
        + "&grant_type=authorization_code";
    try {
      HttpRequest request = HttpRequest.newBuilder(URI.create(properties.getTokenUrl() + "?" + query))
          .timeout(timeout)
          .GET()
          .build();
      HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
      if (response.statusCode() < 200 || response.statusCode() >= 300) throw unavailable();
      JsonNode body = mapper.readTree(response.body());
      if (body.has("errcode")) {
        int errorCode = body.path("errcode").asInt();
        if (errorCode == 40029 || errorCode == 40163) throw invalid();
        throw unavailable();
      }
      String subject = body.path("unionid").asText("").trim();
      if (subject.isBlank()) subject = body.path("openid").asText("").trim();
      if (subject.isBlank()) throw invalid();
      return new SocialIdentityVerifier.VerifiedIdentity(subject);
    } catch (ApiException exception) {
      throw exception;
    } catch (InterruptedException exception) {
      Thread.currentThread().interrupt();
      throw unavailable();
    } catch (Exception exception) {
      throw unavailable();
    }
  }

  private String encode(String value) {
    return URLEncoder.encode(value, StandardCharsets.UTF_8);
  }

  private ApiException invalid() {
    return new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "WeChat authorization code is invalid.");
  }

  private ApiException unavailable() {
    return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "WeChat login is unavailable.");
  }
}
