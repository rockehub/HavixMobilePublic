import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../core/models/storefront_models.dart';

class RichTextWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const RichTextWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final content = config['content'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Html(data: content),
    );
  }
}
