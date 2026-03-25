import 'package:flutter/material.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.description,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.isLoading = false,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String description;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color panelColor = isDark
        ? colorScheme.surfaceContainerHigh
        : Colors.white;
    final Color panelBorder = colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.45 : 0.72,
    );

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              _FeatureHeroCard(
                icon: icon,
                accentColor: accentColor,
                title: title,
                description: description,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: panelBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.05,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: isLoading
                        ? _FeatureLoadingSkeleton(
                            key: const ValueKey<String>('loading'),
                            accentColor: accentColor,
                          )
                        : _FeatureEmptyState(
                            key: const ValueKey<String>('empty'),
                            icon: icon,
                            accentColor: accentColor,
                            title: emptyTitle,
                            subtitle: emptySubtitle,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureHeroCard extends StatelessWidget {
  const _FeatureHeroCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color startColor = Color.lerp(
      accentColor,
      isDark ? colorScheme.surfaceContainerHighest : Colors.white,
      isDark ? 0.18 : 0.65,
    )!;
    final Color endColor = isDark
        ? colorScheme.surfaceContainer.withValues(alpha: 0.96)
        : const Color(0xFFF7F3EE);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.30 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureEmptyState extends StatelessWidget {
  const _FeatureEmptyState({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: accentColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLoadingSkeleton extends StatefulWidget {
  const _FeatureLoadingSkeleton({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<_FeatureLoadingSkeleton> createState() =>
      _FeatureLoadingSkeletonState();
}

class _FeatureLoadingSkeletonState extends State<_FeatureLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color baseColor = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF2EEE8);
    final Color highlightColor = Color.lerp(
      widget.accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
      Colors.white,
      isDark ? 0.18 : 0.58,
    )!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final Color skeletonColor = Color.lerp(baseColor, highlightColor, t)!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _SkeletonBlock(
                    color: skeletonColor,
                    height: 88,
                    borderRadius: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SkeletonBlock(
                    color: skeletonColor,
                    height: 88,
                    borderRadius: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SkeletonBlock(
              color: skeletonColor,
              width: 96,
              height: 14,
              borderRadius: 999,
            ),
            const SizedBox(height: 12),
            _SkeletonBlock(color: skeletonColor, height: 72, borderRadius: 18),
            const SizedBox(height: 10),
            _SkeletonBlock(color: skeletonColor, height: 72, borderRadius: 18),
            const SizedBox(height: 22),
            _SkeletonBlock(
              color: skeletonColor,
              width: 120,
              height: 14,
              borderRadius: 999,
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(3, (int index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
                child: Row(
                  children: [
                    _SkeletonBlock(
                      color: skeletonColor,
                      width: 44,
                      height: 44,
                      borderRadius: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonBlock(
                            color: skeletonColor,
                            width: 148,
                            height: 14,
                            borderRadius: 999,
                          ),
                          const SizedBox(height: 8),
                          _SkeletonBlock(
                            color: skeletonColor,
                            width: 112,
                            height: 12,
                            borderRadius: 999,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.color,
    this.width,
    required this.height,
    required this.borderRadius,
  });

  final Color color;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
