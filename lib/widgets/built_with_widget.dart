import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class BuiltWithWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const BuiltWithWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? 'Feito com';
    final subtitle = config['subtitle'] as String?;
    final items = (config['items'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: items.map((item) {
              final i = item as Map<String, dynamic>;
              return GestureDetector(
                onTap: i['url'] != null ? () => launchUrl(Uri.parse(i['url'] as String)) : null,
                child: Column(
                  children: [
                    if (i['imageUrl'] != null)
                      CachedNetworkImage(imageUrl: i['imageUrl'] as String, height: 36, fit: BoxFit.contain),
                    if (i['name'] != null)
                      Text(i['name'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
