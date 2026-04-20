import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const ImageWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final imageUrl = config['imageUrl'] as String? ?? '';
    final linkUrl = config['linkUrl'] as String?;
    final altText = config['alt'] as String? ?? '';

    Widget image = imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey[200], height: 200),
            errorWidget: (_, __, ___) => Container(color: Colors.grey[200], height: 100, child: const Icon(Icons.image)),
          )
        : Container(color: Colors.grey[200], height: 200);

    if (linkUrl != null && linkUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(linkUrl)),
        child: image,
      );
    }
    return image;
  }
}
