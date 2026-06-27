package com.speakeasy.security;

import java.util.UUID;

public record CurrentUser(UUID userId, UUID sessionId) {}
