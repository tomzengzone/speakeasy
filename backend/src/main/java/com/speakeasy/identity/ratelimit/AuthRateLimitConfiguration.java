package com.speakeasy.identity.ratelimit;

import java.time.Clock;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(AuthRateLimitProperties.class)
public class AuthRateLimitConfiguration {
  @Bean
  AuthRateLimitKeyFactory authRateLimitKeyFactory(AuthRateLimitProperties properties) {
    String secret = properties.getKeySecret().isBlank() ? "disabled-rate-limit-key" : properties.getKeySecret();
    return new AuthRateLimitKeyFactory(secret);
  }

  @Bean
  ClientNetworkResolver clientNetworkResolver(AuthRateLimitProperties properties) {
    return new ClientNetworkResolver(properties.getTrustedProxyCidrs());
  }

  @Bean
  RedisAuthRateLimitStore redisAuthRateLimitStore(
      org.springframework.data.redis.core.StringRedisTemplate redis, Clock clock) {
    return new RedisAuthRateLimitStore(redis, clock);
  }
}
