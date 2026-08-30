package com.speakeasy;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = "speakeasy.auth.account-recovery-enabled=invalid")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountRecoveryCapabilityInvalidServiceTest
    extends AbstractAccountRecoveryCapabilityServiceGateTest {}
