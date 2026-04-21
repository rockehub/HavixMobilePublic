import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/api/commerce_api.dart';
import '../core/config/app_config.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class ProductFeaturedWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const ProductFeaturedWidget({super.key, required this.config, required this.storefront});

  @override
  State<ProductFeaturedWidget> createState() => _ProductFeaturedWidgetState();
}

class _ProductFeaturedWidgetState extends State<ProductFeaturedWidget> {
  final _api = CommerceApi();
  ProductDetail? _product;
  bool _loading = true;
  bool _adding = false;
  String? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slug = widget.config['productSlug'] as String?
        ?? widget.config['slug'] as String?
        ?? widget.config['product'] as String?;
    if (kDebugMode) {
      debugPrint('[ProductFeatured] config keys: ${widget.config.keys.toList()} slug=$slug');
    }
    if (slug != null && slug.isNotEmpty) {
      try {
        _product = await _api.getProduct(slug);
        if (_product!.variants.isNotEmpty) {
          _selectedVariantId = _product!.variants.first.id;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[ProductFeatured] load error: $e');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    setState(() => _adding = true);
    final ok = await context.read<CartStore>().addToCart(
      _selectedVariantId,
      1,
      productId: _product!.id,
    );
    if (mounted) {
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Adicionado ao carrinho!' : 'Erro ao adicionar. Tente novamente.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? Colors.green[700] : Colors.red[700],
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _FeaturedShimmer();
    if (_product == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final p = _product!;
    final ctaText = widget.config['ctaText'] as String? ?? 'Adicionar ao Carrinho';
    final showDescription = widget.config['showDescription'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge overlay
            Stack(
              children: [
                GestureDetector(
                  onTap: () => context.push('/product/${p.slug}'),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: p.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.resolveMediaUrl(p.images.first),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(color: Colors.grey[100]),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[100],
                              child: const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.grey)),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Center(child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey)),
                          ),
                  ),
                ),
                // "Destaque" badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DESTAQUE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                  ),
                ),
                if (p.compareAtPrice != null && p.compareAtPrice! > p.price)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${((1 - p.price / p.compareAtPrice!) * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/product/${p.slug}'),
                    child: Text(
                      p.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (showDescription && p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p.description!.replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(p.price),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                      ),
                      if (p.compareAtPrice != null && p.compareAtPrice! > p.price) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            fmt.format(p.compareAtPrice!),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.45),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.inStock ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          p.inStock ? 'Em estoque' : 'Esgotado',
                          style: TextStyle(fontSize: 12, color: p.inStock ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: p.inStock && !_adding ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            disabledBackgroundColor: Colors.grey.shade200,
                          ),
                          child: _adding
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.shopping_cart_outlined, size: 16),
                                  const SizedBox(width: 6),
                                  Text(ctaText, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.push('/product/${p.slug}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: 16 / 9, child: Container(color: Colors.white)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 22, width: double.infinity, color: Colors.white),
                const SizedBox(height: 10),
                Container(height: 28, width: 140, color: Colors.white),
                const SizedBox(height: 16),
                Container(height: 44, width: double.infinity, color: Colors.white),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
