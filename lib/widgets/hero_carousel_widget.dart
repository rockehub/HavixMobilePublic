import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/storefront_models.dart';

class HeroCarouselWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final List<WidgetButton> buttons;
  final StorefrontResolveResponse storefront;

  const HeroCarouselWidget({super.key, required this.config, required this.buttons, required this.storefront});

  @override
  State<HeroCarouselWidget> createState() => _HeroCarouselWidgetState();
}

class _HeroCarouselWidgetState extends State<HeroCarouselWidget> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = (widget.config['slides'] as List<dynamic>? ?? []);
    final height = (widget.config['height'] as num?)?.toDouble() ?? 360;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            itemBuilder: (context, i) {
              final slide = slides[i] as Map<String, dynamic>;
              final overlayOpacity = (slide['overlayOpacity'] as num?)?.toDouble() ?? 0.4;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: slide['imageUrl'] as String? ?? '', fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                  ),
                  Container(color: Colors.black.withOpacity(overlayOpacity)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (slide['title'] != null)
                          Text(slide['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        if (slide['subtitle'] != null) ...[
                          const SizedBox(height: 8),
                          Text(slide['subtitle'] as String, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                        if (slide['buttonText'] != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final url = slide['buttonUrl'] as String? ?? '';
                              if (url.startsWith('/')) context.go(url);
                              else if (url.isNotEmpty) launchUrl(Uri.parse(url));
                            },
                            child: Text(slide['buttonText'] as String),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 12),
          SmoothPageIndicator(controller: _controller, count: slides.length, effect: WormEffect(dotWidth: 8, dotHeight: 8, activeDotColor: Theme.of(context).colorScheme.primary)),
        ],
      ],
    );
  }
}
