import 'package:flutter/material.dart';
import '../core/models/storefront_models.dart';

class TimelineWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const TimelineWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String?;
    final items = (config['items'] as List<dynamic>? ?? []);
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ],
          ...items.asMap().entries.map((e) {
            final item = e.value as Map<String, dynamic>;
            final isLast = e.key == items.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      if (!isLast)
                        Expanded(child: Container(width: 2, color: accent.withOpacity(0.3))),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['date'] != null)
                            Text(item['date'] as String, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(item['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (item['description'] != null)
                            Text(item['description'] as String, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
