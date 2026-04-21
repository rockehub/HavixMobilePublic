import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Renders a resolved, cached image from a media URL.
/// Applies [AppConfig.resolveMediaUrl] so localhost URLs work on physical devices.
class MediaImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const MediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = url != null && url!.isNotEmpty
        ? AppConfig.resolveMediaUrl(url!)
        : '';

    final Widget fallback = placeholder ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        );

    if (resolved.isEmpty) return fallback;

    Widget image = CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

/// Resolves a media URL without rendering anything.
/// Use this when you only need the resolved URL string (e.g. to pass to other APIs).
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  return AppConfig.resolveMediaUrl(url);
}
