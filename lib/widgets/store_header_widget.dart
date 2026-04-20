import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class StoreHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const StoreHeaderWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final logoUrl = storefront.logo?.hdUrl;
    final cartCount = context.watch<CartStore>().itemCount;

    return AppBar(
      leading: logoUrl != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(Icons.store),
              ),
            )
          : const Icon(Icons.store),
      title: Text(storefront.storeName ?? ''),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.go('/search'),
        ),
        IconButton(
          icon: badges.Badge(
            showBadge: cartCount > 0,
            badgeContent: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          onPressed: () => context.go('/cart'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
