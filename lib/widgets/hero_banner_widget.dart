import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/helpers/media_image.dart';
import '../core/models/storefront_models.dart';

class HeroBannerWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final List<WidgetButton> buttons;
  final StorefrontResolveResponse storefront;

  const HeroBannerWidget({super.key, required this.config, required this.buttons, required this.storefront});

  @override
  Widget build(BuildContext context) {
    // content fields are flattened into config by StorefrontWidget.fromJson
    // layout and style are preserved as sub-maps
    final layout = config['layout'] as Map<String, dynamic>? ?? {};
    final style  = config['style']  as Map<String, dynamic>? ?? {};

    final eyebrow     = config['eyebrow']     as String? ?? '';
    final title       = config['title']       as String? ?? '';
    final description = config['description'] as String? ?? '';
    final ctaLabel    = config['ctaLabel']    as String? ?? '';
    final ctaHref     = config['ctaHref']     as String? ?? '';
    final imageUrl    = config['imageUrl']    as String?;

    final imagePosition = layout['imagePosition'] as String? ?? 'right';

    final bgColor     = _parseColor(style['backgroundColor']) ?? Theme.of(context).colorScheme.surface;
    final textColor   = _parseColor(style['textColor'])       ?? Theme.of(context).colorScheme.onSurface;
    final accentColor = _parseColor(style['accentColor'])     ?? Theme.of(context).colorScheme.primary;

    final borderRadius = (style['borderRadius'] as num?)?.toDouble() ?? 32;
    final paddingY     = (style['paddingY']     as num?)?.toDouble() ?? 36;
    final paddingX     = (style['paddingX']     as num?)?.toDouble() ?? 36;

    // Resolve CTA — prefer buttons list, fall back to ctaLabel/ctaHref from content
    final WidgetButton? cta = buttons.isNotEmpty
        ? buttons.first
        : (ctaLabel.isNotEmpty ? WidgetButton(label: ctaLabel, url: ctaHref) : null);

    final imageWidget = (imageUrl != null && imageUrl.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius * 0.7),
            child: MediaImage(
              url: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 220,
            ),
          )
        : null;

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (eyebrow.isNotEmpty)
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        if (eyebrow.isNotEmpty) const SizedBox(height: 10),
        if (title.isNotEmpty)
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
        if (cta != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _handleTap(context, cta.url ?? ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: Text(cta.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.symmetric(horizontal: paddingX, vertical: paddingY),
      child: imageWidget == null
          // Text-only
          ? textColumn
          // Mobile: stacked (image on top when imagePosition == left, else text first)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: imagePosition == 'left'
                  ? [imageWidget, const SizedBox(height: 24), textColumn]
                  : [textColumn, const SizedBox(height: 24), imageWidget],
            ),
    );
  }

  void _handleTap(BuildContext context, String url) {
    if (url.isEmpty) return;
    if (url.startsWith('/')) {
      context.go(url);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Color? _parseColor(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final hex = value.replaceFirst('#', '');
    final full = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(full, radix: 16);
    return parsed != null ? Color(parsed) : null;
  }
}
