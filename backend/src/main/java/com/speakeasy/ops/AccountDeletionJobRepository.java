package com.speakeasy.ops;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountDeletionJobRepository extends JpaRepository<AccountDeletionJob, UUID> {}
