import 'package:flutter/material.dart';

import 'feature_placeholder_page.dart';
import '../l10n/l10n.dart';

class LearningReportPage extends StatelessWidget {
  const LearningReportPage({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return FeaturePlaceholderPage(
      title: l10n.learningReport,
      icon: Icons.bar_chart_rounded,
      accentColor: const Color(0xFF4A7244),
      description: l10n.learningReportDescription,
      emptyTitle: l10n.noLearningReport,
      emptySubtitle: l10n.noLearningReportSubtitle,
      isLoading: isLoading,
    );
  }
}
