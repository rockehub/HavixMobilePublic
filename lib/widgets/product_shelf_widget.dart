import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api/commerce_api.dart';
import '../core/config/app_config.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class ProductShelfWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const ProductShelfWidget({super.key, required this.config, required this.storefront});

  @override
  State<ProductShelfWidget> createState() => _ProductShelfWidgetState();
}

class _ProductShelfWidgetState extends State<ProductShelfWidget> {
  final _api = CommerceApi();
  List<ProductSummary> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final category = widget.config['categorySlug'] as String?;
      _products = await _api.getProducts(category: category, limit: 10);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config['title'] as String? ?? 'Produtos';
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _products.length,
                    itemBuilder: (context, i) {
                      final p = _products[i];
                      return GestureDetector(
                        onTap: () => context.push('/product/${p.slug}'),
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: p.imageUrl != null
                                      ? CachedNetworkImage(imageUrl: AppConfig.resolveMediaUrl(p.imageUrl!), height: 140, width: double.infinity, fit: BoxFit.cover)
                                      : Container(height: 140, color: Colors.grey[200]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(fmt.format(p.price), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
