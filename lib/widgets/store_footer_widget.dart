import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class StoreFooterWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const StoreFooterWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final logoUrl = storefront.logo?.hdUrl;
    final links = (config['links'] as List<dynamic>? ?? []);
    final socialLinks = (config['socialLinks'] as List<dynamic>? ?? []);
    final copyright = config['copyrightText'] as String? ?? '© ${DateTime.now().year} ${storefront.storeName}';

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (logoUrl != null)
            CachedNetworkImage(imageUrl: logoUrl, height: 40, errorWidget: (_, __, ___) => const SizedBox()),
          if (socialLinks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: socialLinks.map<Widget>((s) {
                final url = s['url'] as String? ?? '';
                return IconButton(
                  icon: const Icon(Icons.link, color: Colors.white70),
                  onPressed: () => launchUrl(Uri.parse(url)),
                );
              }).toList(),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: links.map<Widget>((l) {
                return TextButton(
                  onPressed: () => launchUrl(Uri.parse(l['url'] as String? ?? '')),
                  child: Text(l['label'] as String? ?? '', style: const TextStyle(color: Colors.white70)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text(copyright, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
