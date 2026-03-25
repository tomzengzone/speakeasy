import 'package:flutter/material.dart';

import 'package:speakeasy/pages/feature_placeholder_page.dart';
import 'package:speakeasy/l10n/l10n.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return FeaturePlaceholderPage(
      title: l10n.myFavorites,
      icon: Icons.favorite_border_rounded,
      accentColor: const Color(0xFFE06B6B),
      description: l10n.favoritesDescription,
      emptyTitle: l10n.noFavorites,
      emptySubtitle: l10n.noFavoritesSubtitle,
      isLoading: isLoading,
    );
  }
}
