import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class PricingTableWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final List<WidgetButton> buttons;
  final StorefrontResolveResponse storefront;

  const PricingTableWidget({super.key, required this.config, required this.buttons, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? 'Planos';
    final plans = (config['plans'] as List<dynamic>? ?? []);
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plans.map((p) {
                final plan = p as Map<String, dynamic>;
                final highlighted = plan['highlighted'] == true;
                final features = (plan['features'] as List<dynamic>? ?? []);
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: highlighted ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: highlighted ? BorderSide(color: accent, width: 2) : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (highlighted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          Text(plan['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(plan['price'] as String? ?? '', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accent)),
                          Text(plan['period'] as String? ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Divider(height: 24),
                          ...features.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              Icon(Icons.check, size: 16, color: accent),
                              const SizedBox(width: 6),
                              Expanded(child: Text(f.toString(), style: const TextStyle(fontSize: 13))),
                            ]),
                          )),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final url = plan['buttonUrl'] as String? ?? '';
                                if (url.startsWith('/')) context.go(url);
                                else if (url.isNotEmpty) launchUrl(Uri.parse(url));
                              },
                              child: Text(plan['buttonText'] as String? ?? 'Começar'),
                            ),
                          ),
                        ],
                      ),
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
