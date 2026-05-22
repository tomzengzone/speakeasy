import 'package:flutter/material.dart';

import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/app_session.dart';

class LearningReportPage extends StatelessWidget {
  const LearningReportPage({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppSession session = AppSessionScope.of(context);
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        title: Text(l10n.learningReport),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<LearningProfileSummary?>(
        future: session.fetchLearningProfile(),
        builder: (
          BuildContext context,
          AsyncSnapshot<LearningProfileSummary?> snapshot,
        ) {
          final LearningProfileSummary? profile = snapshot.data;
          final List<PracticeHistoryModel> recentPractices =
              session.stats.recentPractices;
          if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profile == null ||
              (profile.summary.trim().isEmpty &&
                  profile.strengths.isEmpty &&
                  profile.weaknesses.isEmpty &&
                  profile.progress.isEmpty &&
                  profile.nextFocus.isEmpty)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  l10n.noLearningReport,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF706A63),
                  ),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _SectionCard(
                title: '当前概况',
                accent: const Color(0xFF4A7244),
                body: profile.summary.trim(),
                footer:
                    '基于 ${profile.evidenceCount} 条已完成练习${profile.updatedAt == null ? '' : ' · 最近更新 ${_formatDate(profile.updatedAt!)}'}',
              ),
              if (profile.strengths.isNotEmpty)
                _ListSectionCard(
                  title: '最近做得更好的地方',
                  accent: const Color(0xFF557C4D),
                  items: profile.strengths,
                ),
              if (profile.weaknesses.isNotEmpty)
                _ListSectionCard(
                  title: '当前最明显的不足',
                  accent: const Color(0xFFAF6A45),
                  items: profile.weaknesses,
                ),
              if (profile.progress.isNotEmpty)
                _ListSectionCard(
                  title: '近期变化',
                  accent: const Color(0xFF5A6FA8),
                  items: profile.progress,
                ),
              if (profile.nextFocus.isNotEmpty)
                _ListSectionCard(
                  title: '下一轮最该练的点',
                  accent: const Color(0xFF8A6A2F),
                  items: profile.nextFocus,
                ),
              if (recentPractices.isNotEmpty)
                _RecentPracticeCard(practices: recentPractices.take(5).toList()),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accent,
    required this.body,
    this.footer,
  });

  final String title;
  final Color accent;
  final String body;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DED1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, accent: accent),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2925),
            ),
          ),
          if (footer?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              footer!.trim(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B8175),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListSectionCard extends StatelessWidget {
  const _ListSectionCard({
    required this.title,
    required this.accent,
    required this.items,
  });

  final String title;
  final Color accent;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DED1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, accent: accent),
          const SizedBox(height: 12),
          ...items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF4E4740),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPracticeCard extends StatelessWidget {
  const _RecentPracticeCard({required this.practices});

  final List<PracticeHistoryModel> practices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DED1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '最近练习证据',
            accent: Color(0xFF70543A),
          ),
          const SizedBox(height: 12),
          ...practices.map(
            (PracticeHistoryModel item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F2A25),
                          ),
                        ),
                        if (item.feedbackStatus?.trim().isNotEmpty ?? false)
                          Text(
                            item.feedbackStatus!.trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B8175),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.score != null)
                    Text(
                      '${item.score}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A7244),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2F2A25),
          ),
        ),
      ],
    );
  }
}
