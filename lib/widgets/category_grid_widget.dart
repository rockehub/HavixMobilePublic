import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/models/storefront_models.dart';

class CategoryGridWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const CategoryGridWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String?;
    final categories = (config['categories'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i] as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => context.go('/category/${cat['slug']}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: cat['imageUrl'] as String? ?? '', fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                      ),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)]))),
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Text(cat['title'] as String? ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
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
