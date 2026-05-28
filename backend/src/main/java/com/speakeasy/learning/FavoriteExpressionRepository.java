package com.speakeasy.learning;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FavoriteExpressionRepository extends JpaRepository<FavoriteExpression, UUID> {
  List<FavoriteExpression> findByUserIdAndStatus(UUID userId, String status);

  Optional<FavoriteExpression> findByFavoriteIdAndUserId(UUID favoriteId, UUID userId);

  Optional<FavoriteExpression> findByUserIdAndTargetExpressionId(UUID userId, UUID targetExpressionId);
}
