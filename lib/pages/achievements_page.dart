import 'package:flutter/material.dart';

import 'package:speakeasy/pages/feature_placeholder_page.dart';
import 'package:speakeasy/l10n/l10n.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return FeaturePlaceholderPage(
      title: l10n.achievements,
      icon: Icons.emoji_events_outlined,
      accentColor: const Color(0xFFC8955A),
      description: l10n.achievementsDescription,
      emptyTitle: l10n.noAchievements,
      emptySubtitle: l10n.noAchievementsSubtitle,
      isLoading: isLoading,
    );
  }
}
