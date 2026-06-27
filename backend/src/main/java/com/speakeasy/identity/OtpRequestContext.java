package com.speakeasy.identity;

public record OtpRequestContext(
    String requestId,
    String remoteIp,
    boolean secureTransport,
    String forwardedProto,
    String deviceId,
    String installId) {
  public boolean hasTrustedSecureTransport() {
    return hasTrustedSecureTransport(false);
  }

  public boolean hasTrustedSecureTransport(boolean trustForwardedProto) {
    return secureTransport || (trustForwardedProto && "https".equalsIgnoreCase(forwardedProto == null ? "" : forwardedProto.trim()));
  }

  public static OtpRequestContext empty() {
    return new OtpRequestContext("unknown", "unknown", false, null, null, null);
  }
}
