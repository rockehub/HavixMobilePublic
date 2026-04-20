import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/api/commerce_api.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slug = widget.config['productSlug'] as String?;
    if (slug != null) {
      try {
        _product = await _api.getProduct(slug);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: 300, color: Colors.white, margin: const EdgeInsets.all(16)),
      );
    }
    if (_product == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: _product!.images.isNotEmpty
                  ? CachedNetworkImage(imageUrl: _product!.images.first, width: 140, height: 200, fit: BoxFit.cover)
                  : Container(width: 140, height: 200, color: Colors.grey[200]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_product!.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(fmt.format(_product!.price), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final variantId = _product!.variants.isNotEmpty ? _product!.variants.first.id : '';
                          context.read<CartStore>().addToCart(variantId, 1);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho!')));
                        },
                        child: const Text('Adicionar ao Carrinho'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
