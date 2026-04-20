import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class LogoCloudWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const LogoCloudWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String?;
    final logos = (config['logos'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          if (title != null) ...[
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: logos.map((l) {
                final logo = l as Map<String, dynamic>;
                final url = logo['url'] as String?;
                return GestureDetector(
                  onTap: url != null ? () => launchUrl(Uri.parse(url)) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CachedNetworkImage(
                      imageUrl: logo['imageUrl'] as String? ?? '',
                      height: 40,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const SizedBox(width: 80),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
