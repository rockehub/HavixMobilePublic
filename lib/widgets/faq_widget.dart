import 'package:flutter/material.dart';
import '../core/models/storefront_models.dart';

class FaqWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const FaqWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? 'Perguntas Frequentes';
    final items = (config['items'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...items.map((item) {
            final m = item as Map<String, dynamic>;
            return ExpansionTile(
              title: Text(m['question'] as String? ?? ''),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(m['answer'] as String? ?? ''),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
