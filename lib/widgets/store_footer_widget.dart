import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/models/storefront_models.dart';

class StoreFooterWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const StoreFooterWidget({super.key, required this.config, required this.storefront});

  List<({String label, String url})> _parseLinks(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => (label: m['label'] as String? ?? '', url: m['url'] as String? ?? ''))
          .where((e) => e.label.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.contains('|'))
          .map((l) {
            final p = l.split('|');
            return (label: p[0].trim(), url: p.length > 1 ? p[1].trim() : '');
          })
          .where((e) => e.label.isNotEmpty)
          .toList();
    }
    return [];
  }

  void _navigate(BuildContext context, String url) {
    if (url.isEmpty) return;
    if (url.startsWith('/')) {
      context.go(url);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final rawLogoUrl = config['logoUrl'] as String? ?? storefront.logo?.hdUrl;
    final logoUrl = rawLogoUrl != null ? AppConfig.resolveMediaUrl(rawLogoUrl) : null;
    final storeName = storefront.storeName ?? '';
    final copyright = config['copyright'] as String?
        ?? config['copyrightText'] as String?
        ?? '© ${DateTime.now().year} $storeName. Todos os direitos reservados.';
    final links = _parseLinks(config['links']);

    return Column(
      children: [
        // Top divider with accent color
        Container(height: 3, color: accent),

        // Main footer body
        Container(
          color: const Color(0xFF1A1A2E),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + store name row
              Row(
                children: [
                  if (logoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        height: 40,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => _BrandMark(name: storeName, accent: accent),
                      ),
                    )
                  else
                    _BrandMark(name: storeName, accent: accent),
                  const SizedBox(width: 12),
                  Text(
                    storeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              if (links.isNotEmpty) ...[
                const SizedBox(height: 28),
                // Links grid — 2 columns
                _LinksGrid(links: links, onTap: (url) => _navigate(context, url)),
              ],

              const SizedBox(height: 28),
              // Divider
              Container(height: 1, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 20),

              // Bottom row: copyright + social placeholder
              Row(
                children: [
                  Expanded(
                    child: Text(
                      copyright,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String name;
  final Color accent;
  const _BrandMark({required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}

class _LinksGrid extends StatelessWidget {
  final List<({String label, String url})> links;
  final void Function(String) onTap;
  const _LinksGrid({required this.links, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Split into two columns
    final half = (links.length / 2).ceil();
    final col1 = links.sublist(0, half);
    final col2 = links.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _LinkColumn(items: col1, onTap: onTap)),
        const SizedBox(width: 16),
        Expanded(child: _LinkColumn(items: col2, onTap: onTap)),
      ],
    );
  }
}

class _LinkColumn extends StatelessWidget {
  final List<({String label, String url})> items;
  final void Function(String) onTap;
  const _LinkColumn({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((l) => GestureDetector(
        onTap: () => onTap(l.url),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
