import 'package:flutter/material.dart';

import 'package:speakeasy/pages/feature_placeholder_page.dart';
import 'package:speakeasy/l10n/l10n.dart';

class OfflineContentPage extends StatelessWidget {
  const OfflineContentPage({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return FeaturePlaceholderPage(
      title: l10n.offlineContent,
      icon: Icons.download_rounded,
      accentColor: const Color(0xFF5A6FA8),
      description: l10n.offlineContentDescription,
      emptyTitle: l10n.noOfflineContent,
      emptySubtitle: l10n.noOfflineContentSubtitle,
      isLoading: isLoading,
    );
  }
}
