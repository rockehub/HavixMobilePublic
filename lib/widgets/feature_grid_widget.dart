import 'package:flutter/material.dart';
import '../core/models/storefront_models.dart';

class FeatureGridWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const FeatureGridWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String?;
    final items = (config['items'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i] as Map<String, dynamic>;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['icon'] as String? ?? '✨', style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(item['title'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(item['description'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
