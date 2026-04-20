import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../core/models/storefront_models.dart';

class ImageGalleryWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const ImageGalleryWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final images = (config['images'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: images.length,
        itemBuilder: (context, i) {
          final img = images[i] as Map<String, dynamic>;
          final url = img['imageUrl'] as String? ?? '';
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: SizedBox(
                    height: 400,
                    child: PhotoView(imageProvider: CachedNetworkImageProvider(url)),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
