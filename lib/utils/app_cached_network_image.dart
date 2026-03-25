import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'image_cache_manager.dart';

class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 120),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final Widget placeholderWidget = placeholder ?? const AppImagePlaceholder();
    final Widget errorFallback = errorWidget ?? placeholderWidget;

    if (imageUrl.trim().isEmpty) {
      return SizedBox(width: width, height: height, child: errorFallback);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: AppImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      placeholder: (BuildContext context, String url) {
        return SizedBox(width: width, height: height, child: placeholderWidget);
      },
      errorWidget: (BuildContext context, String url, Object error) {
        return SizedBox(width: width, height: height, child: errorFallback);
      },
    );
  }
}

class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({
    super.key,
    this.color = const Color(0xFFE6E6E6),
    this.icon = Icons.image_rounded,
    this.iconColor = const Color(0xFF9E9E9E),
    this.iconSize = 24,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
