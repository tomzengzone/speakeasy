package com.speakeasy.identity.provider;

public interface SocialIdentityVerifier {
  VerifiedIdentity verify(String provider, String credential, String nonce);

  record VerifiedIdentity(String subject) {}
}
