import 'package:flutter/material.dart';
import '../core/models/storefront_models.dart';

class StatsCounterWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const StatsCounterWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String?;
    final stats = (config['stats'] as List<dynamic>? ?? []);
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          if (title != null) ...[
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          Row(
            children: stats.map((s) {
              final stat = s as Map<String, dynamic>;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        '${stat['prefix'] ?? ''}${stat['value'] ?? ''}${stat['suffix'] ?? ''}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accent),
                        textAlign: TextAlign.center,
                      ),
                      Text(stat['label'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
