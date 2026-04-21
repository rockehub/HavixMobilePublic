import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class StoreHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const StoreHeaderWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final fg = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;
    final cartCount = context.watch<CartStore>().itemCount;

    final rawLogoUrl = config['logoUrl'] as String? ?? storefront.logo?.hdUrl;
    final logoUrl = rawLogoUrl != null ? AppConfig.resolveMediaUrl(rawLogoUrl) : null;
    final storeName = storefront.storeName ?? config['title'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              // Logo or store initial avatar
              _Logo(logoUrl: logoUrl, storeName: storeName, accent: accent),
              const SizedBox(width: 12),
              // Store name
              Expanded(
                child: Text(
                  storeName,
                  style: TextStyle(
                    color: fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Search
              _IconBtn(
                icon: Icons.search_rounded,
                color: fg,
                onTap: () => context.go('/search'),
              ),
              // Cart with badge
              _IconBtn(
                icon: Icons.shopping_bag_outlined,
                color: fg,
                badge: cartCount > 0 ? cartCount : null,
                badgeColor: accent,
                onTap: () => context.go('/cart'),
              ),
              // Account
              _IconBtn(
                icon: Icons.person_outline_rounded,
                color: fg,
                onTap: () => context.go('/account'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logoUrl;
  final String storeName;
  final Color accent;
  const _Logo({required this.logoUrl, required this.storeName, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => _InitialAvatar(storeName: storeName, accent: accent),
        ),
      );
    }
    return _InitialAvatar(storeName: storeName, accent: accent);
  }
}

class _InitialAvatar extends StatelessWidget {
  final String storeName;
  final Color accent;
  const _InitialAvatar({required this.storeName, required this.accent});

  @override
  Widget build(BuildContext context) {
    final initial = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, color: color, size: 24);
    if (badge != null) {
      child = badges.Badge(
        badgeContent: Text(
          '$badge',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        badgeStyle: badges.BadgeStyle(badgeColor: badgeColor ?? Colors.red, padding: const EdgeInsets.all(4)),
        child: child,
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: child,
      ),
    );
  }
}
