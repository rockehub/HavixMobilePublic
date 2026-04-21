import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../core/api/commerce_api.dart';
import '../core/helpers/media_image.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';

class ProductListingWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;
  final String? categorySlug;

  const ProductListingWidget({super.key, required this.config, required this.storefront, this.categorySlug});

  @override
  State<ProductListingWidget> createState() => _ProductListingWidgetState();
}

class _ProductListingWidgetState extends State<ProductListingWidget> {
  final _api = CommerceApi();
  List<ProductSummary> _products = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 0;
  String _sort = 'newest';
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 0;
      _products = [];
      _hasMore = true;
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final results = await _api.getProducts(category: widget.categorySlug, sort: _sort, page: _page, limit: 20);
      _products = reset ? results : [..._products, ...results];
      _hasMore = results.length == 20;
      _page++;
    } catch (_) {}
    if (mounted) setState(() { _loading = false; _loadingMore = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Ordenar:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sort,
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Mais recentes')),
                  DropdownMenuItem(value: 'price_asc', child: Text('Menor preço')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Maior preço')),
                ],
                onChanged: (v) { _sort = v!; _load(reset: true); },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7),
                itemCount: 6,
                itemBuilder: (_, __) => Container(color: Colors.white, height: 200),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7),
              itemCount: _products.length,
              itemBuilder: (context, i) {
                final p = _products[i];
                return GestureDetector(
                  onTap: () => context.push('/product/${p.slug}'),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MediaImage(url: p.imageUrl, fit: BoxFit.cover, width: double.infinity),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              Text(fmt.format(p.price), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_hasMore && !_loading) ...[
            const SizedBox(height: 16),
            _loadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(onPressed: () => _load(), child: const Text('Carregar mais')),
          ],
        ],
      ),
    );
  }
}
