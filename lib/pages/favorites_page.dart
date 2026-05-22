import 'package:flutter/material.dart';

import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/pages/feature_placeholder_page.dart';
import 'package:speakeasy/services/storage_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, this.isLoading = false});

  final bool isLoading;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteExpressionStorageModel> _items =
      const <FavoriteExpressionStorageModel>[];

  @override
  void initState() {
    super.initState();
    _items = _loadItems();
  }

  List<FavoriteExpressionStorageModel> _loadItems() {
    final List<FavoriteExpressionStorageModel> items = StorageService.instance
        .getFavoriteExpressions()
        .where(
          (FavoriteExpressionStorageModel item) =>
              item.practiceText.trim().isNotEmpty,
        )
        .toList(growable: false);
    return items.toList()..sort(
      (FavoriteExpressionStorageModel a, FavoriteExpressionStorageModel b) =>
          b.savedAt.compareTo(a.savedAt),
    );
  }

  Future<void> _remove(FavoriteExpressionStorageModel item) async {
    final List<FavoriteExpressionStorageModel> next = _items
        .where((FavoriteExpressionStorageModel value) => value.id != item.id)
        .toList(growable: false);
    await StorageService.instance.saveFavoriteExpressions(next);
    if (!mounted) {
      return;
    }
    setState(() => _items = next);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (widget.isLoading || _items.isEmpty) {
      return FeaturePlaceholderPage(
        title: l10n.myFavorites,
        icon: Icons.favorite_border_rounded,
        accentColor: const Color(0xFFE06B6B),
        description: l10n.favoritesDescription,
        emptyTitle: l10n.noFavorites,
        emptySubtitle: l10n.noFavoritesSubtitle,
        isLoading: widget.isLoading,
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color panelColor = isDark
        ? colorScheme.surfaceContainerHigh
        : Colors.white;
    final Color borderColor = colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.42 : 0.68,
    );

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(l10n.myFavorites),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _FavoritesIntro(
                count: _items.length,
                description: l10n.favoritesDescription,
              );
            }
            final FavoriteExpressionStorageModel item = _items[index - 1];
            return _FavoriteExpressionTile(
              item: item,
              panelColor: panelColor,
              borderColor: borderColor,
              onRemove: () => _remove(item),
            );
          },
        ),
      ),
    );
  }
}

class _FavoritesIntro extends StatelessWidget {
  const _FavoritesIntro({required this.count, required this.description});

  final int count;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE06B6B).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFE06B6B),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已收藏 $count 条表达',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteExpressionTile extends StatelessWidget {
  const _FavoriteExpressionTile({
    required this.item,
    required this.panelColor,
    required this.borderColor,
    required this.onRemove,
  });

  final FavoriteExpressionStorageModel item;
  final Color panelColor;
  final Color borderColor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.sourceLabel.isEmpty ? '收藏表达' : item.sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFE06B6B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: '取消收藏',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.favorite_rounded, size: 19),
                  color: const Color(0xFFE06B6B),
                ),
              ],
            ),
            Text(
              item.practiceText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.22,
              ),
            ),
            if (item.translation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.translation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (item.contextNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.contextNote,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.86),
                  height: 1.36,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
