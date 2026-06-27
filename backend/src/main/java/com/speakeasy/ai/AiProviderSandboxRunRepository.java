package com.speakeasy.ai;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiProviderSandboxRunRepository extends JpaRepository<AiProviderSandboxRun, String> {
  List<AiProviderSandboxRun> findAllByOrderByExecutedAtDescCreatedAtDescEvidenceIdAsc();
}
