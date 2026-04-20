import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/models/storefront_models.dart';

class ScreenshotShowcaseWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const ScreenshotShowcaseWidget({super.key, required this.config, required this.storefront});

  @override
  State<ScreenshotShowcaseWidget> createState() => _ScreenshotShowcaseWidgetState();
}

class _ScreenshotShowcaseWidgetState extends State<ScreenshotShowcaseWidget> {
  final _controller = PageController(viewportFraction: 0.8);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config['title'] as String?;
    final subtitle = widget.config['subtitle'] as String?;
    final screenshots = (widget.config['screenshots'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _controller,
              itemCount: screenshots.length,
              itemBuilder: (context, i) {
                final sc = screenshots[i] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: sc['imageUrl'] as String? ?? '', fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (screenshots.length > 1)
            SmoothPageIndicator(controller: _controller, count: screenshots.length, effect: WormEffect(dotWidth: 8, dotHeight: 8, activeDotColor: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
