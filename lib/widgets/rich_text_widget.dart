import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../core/models/storefront_models.dart';

class RichTextWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const RichTextWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    // Match web's logic: config.content.body || config.body || config.description
    final content = config['content'];
    final Map<String, dynamic> resolved =
        content is Map<String, dynamic> ? content : config;

    final body = resolved['body'] as String? ??
        resolved['description'] as String? ??
        '';

    if (body.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Html(
        data: body,
        style: {
          'body': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
          'h1': Style(fontSize: FontSize(22), fontWeight: FontWeight.w800),
          'h2': Style(fontSize: FontSize(19), fontWeight: FontWeight.w700),
          'h3': Style(fontSize: FontSize(16), fontWeight: FontWeight.w700),
          'p': Style(fontSize: FontSize(14), lineHeight: LineHeight(1.6)),
          'li': Style(fontSize: FontSize(14), lineHeight: LineHeight(1.5)),
          'a': Style(color: Theme.of(context).colorScheme.primary),
        },
      ),
    );
  }
}
