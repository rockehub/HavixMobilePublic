import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class HeroBannerWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final List<WidgetButton> buttons;
  final StorefrontResolveResponse storefront;

  const HeroBannerWidget({super.key, required this.config, required this.buttons, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final imageUrl = config['imageUrl'] as String?;
    final title = config['title'] as String? ?? '';
    final subtitle = config['subtitle'] as String? ?? '';
    final height = (config['minHeight'] as num?)?.toDouble() ?? 360;
    final overlayOpacity = (config['overlayOpacity'] as num?)?.toDouble() ?? 0.4;
    final textColor = Colors.white;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
          else
            Container(color: Theme.of(context).colorScheme.primary),
          Container(color: Colors.black.withOpacity(overlayOpacity)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16)),
                ],
                if (buttons.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: buttons.asMap().entries.map((e) {
                      final btn = e.value;
                      final isPrimary = e.key == 0;
                      void onTap() {
                        final url = btn.url ?? '';
                        if (url.startsWith('/')) {
                          context.go(url);
                        } else if (url.isNotEmpty) {
                          launchUrl(Uri.parse(url));
                        }
                      }

                      return isPrimary
                          ? ElevatedButton(onPressed: onTap, child: Text(btn.label))
                          : OutlinedButton(
                              onPressed: onTap,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: Text(btn.label),
                            );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
