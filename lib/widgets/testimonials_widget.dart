import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/models/storefront_models.dart';

class TestimonialsWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const TestimonialsWidget({super.key, required this.config, required this.storefront});

  @override
  State<TestimonialsWidget> createState() => _TestimonialsWidgetState();
}

class _TestimonialsWidgetState extends State<TestimonialsWidget> {
  final _controller = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config['title'] as String? ?? 'O que nossos clientes dizem';
    final items = (widget.config['items'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('"${item['quote'] ?? ''}"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic), textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (item['avatarUrl'] != null)
                                CircleAvatar(radius: 18, backgroundImage: CachedNetworkImageProvider(item['avatarUrl'] as String)),
                              const SizedBox(width: 8),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['author'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                if (item['role'] != null) Text(item['role'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (items.length > 1)
            SmoothPageIndicator(controller: _controller, count: items.length, effect: WormEffect(dotWidth: 8, dotHeight: 8, activeDotColor: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
