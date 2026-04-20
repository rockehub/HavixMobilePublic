import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class CtaWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final List<WidgetButton> buttons;
  final StorefrontResolveResponse storefront;

  const CtaWidget({super.key, required this.config, required this.buttons, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? '';
    final subtitle = config['subtitle'] as String? ?? '';

    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          if (title.isNotEmpty)
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          ],
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: buttons.asMap().entries.map((e) {
                final btn = e.value;
                void onTap() {
                  final url = btn.url ?? '';
                  if (url.startsWith('/')) context.go(url);
                  else if (url.isNotEmpty) launchUrl(Uri.parse(url));
                }
                return e.key == 0
                    ? ElevatedButton(onPressed: onTap, child: Text(btn.label))
                    : OutlinedButton(onPressed: onTap, child: Text(btn.label));
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
