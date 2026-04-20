import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/api/commerce_api.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class ProductDetailWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;
  final String? slug;

  const ProductDetailWidget({super.key, required this.config, required this.storefront, this.slug});

  @override
  State<ProductDetailWidget> createState() => _ProductDetailWidgetState();
}

class _ProductDetailWidgetState extends State<ProductDetailWidget> {
  final _api = CommerceApi();
  final _pageController = PageController();
  ProductDetail? _product;
  bool _loading = true;
  int _qty = 1;
  Map<String, String> _selectedOptions = {};
  String? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final slug = widget.slug ?? widget.config['productSlug'] as String?;
    if (slug != null) {
      try {
        _product = await _api.getProduct(slug);
        if (_product!.variants.isNotEmpty) _selectedVariantId = _product!.variants.first.id;
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  void _selectOption(String key, String value) {
    setState(() {
      _selectedOptions[key] = value;
      final match = _product?.variants.where((v) {
        return _selectedOptions.entries.every((e) => v.options[e.key] == e.value);
      }).firstOrNull;
      if (match != null) _selectedVariantId = match.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(children: [
          Container(height: 300, color: Colors.white),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Container(height: 24, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 20, width: 100, color: Colors.white),
          ])),
        ]),
      );
    }
    if (_product == null) return const Center(child: Text('Produto não encontrado'));

    final p = _product!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.images.isNotEmpty)
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                itemCount: p.images.length,
                itemBuilder: (_, i) => CachedNetworkImage(imageUrl: p.images[i], fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(fmt.format(p.price), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    if (p.compareAtPrice != null) ...[
                      const SizedBox(width: 12),
                      Text(fmt.format(p.compareAtPrice!), style: const TextStyle(fontSize: 16, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ...p.optionGroups.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: entry.value.map((val) => ChoiceChip(
                        label: Text(val),
                        selected: _selectedOptions[entry.key] == val,
                        onSelected: (_) => _selectOption(entry.key, val),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                )),
                Row(
                  children: [
                    const Text('Quantidade:'),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.remove), onPressed: _qty > 1 ? () => setState(() => _qty--) : null),
                    Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _qty++)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Adicionar ao Carrinho'),
                    onPressed: _selectedVariantId == null ? null : () {
                      context.read<CartStore>().addToCart(_selectedVariantId!, _qty);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho!')));
                    },
                  ),
                ),
                if (p.description != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  Html(data: p.description!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
