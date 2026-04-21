import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/api/commerce_api.dart';
import '../core/config/app_config.dart';
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
  bool _adding = false;
  int _qty = 1;
  int _currentImage = 0;
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
    if (slug != null && slug.isNotEmpty) {
      try {
        _product = await _api.getProduct(slug);
        if (_product!.variants.isNotEmpty) {
          _selectedVariantId = _product!.variants.first.id;
        }
      } catch (e) {
        debugPrint('[ProductDetail] load error: $e');
      }
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

  Future<void> _addToCart() async {
    if (_product == null) return;
    setState(() => _adding = true);
    final ok = await context.read<CartStore>().addToCart(
      _selectedVariantId,
      _qty,
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
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (_loading) return _Shimmer();
    if (_product == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Produto não encontrado', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
        ]),
      );
    }

    final p = _product!;
    final selectedVariant = p.variants.where((v) => v.id == _selectedVariantId).firstOrNull;
    final displayPrice = selectedVariant?.price ?? p.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image gallery ──────────────────────────────────────────────
        _ImageGallery(
          images: p.images,
          controller: _pageController,
          currentIndex: _currentImage,
          onPageChanged: (i) => setState(() => _currentImage = i),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product name & price ───────────────────────────────
              Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(displayPrice),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                  ),
                  if (p.compareAtPrice != null && p.compareAtPrice! > displayPrice) ...[
                    const SizedBox(width: 10),
                    Text(
                      fmt.format(p.compareAtPrice!),
                      style: TextStyle(fontSize: 15, color: theme.colorScheme.outline, decoration: TextDecoration.lineThrough),
                    ),
                    const SizedBox(width: 8),
                    _DiscountBadge(original: p.compareAtPrice!, current: displayPrice),
                  ],
                ],
              ),

              // ── Stock indicator ────────────────────────────────────
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.inStock ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  p.inStock ? 'Em estoque' : 'Fora de estoque',
                  style: TextStyle(fontSize: 13, color: p.inStock ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.w500),
                ),
              ]),

              // ── Variant options ────────────────────────────────────
              if (p.optionGroups.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...p.optionGroups.entries.map((entry) => _OptionGroup(
                  name: entry.key,
                  values: entry.value,
                  selected: _selectedOptions[entry.key],
                  onSelect: (v) => _selectOption(entry.key, v),
                  accentColor: theme.colorScheme.primary,
                )),
              ],

              // ── Quantity + Add to cart ─────────────────────────────
              const SizedBox(height: 24),
              Row(
                children: [
                  _QtySelector(
                    qty: _qty,
                    onDec: _qty > 1 ? () => setState(() => _qty--) : null,
                    onInc: () => setState(() => _qty++),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AddToCartButton(
                      loading: _adding,
                      enabled: p.inStock,
                      onTap: _addToCart,
                    ),
                  ),
                ],
              ),

              // ── Secondary: go to cart ──────────────────────────────
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Ver carrinho'),
                  onPressed: () => context.go('/cart'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // ── Description ────────────────────────────────────────
              if (p.description != null && p.description!.isNotEmpty) ...[
                const SizedBox(height: 28),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 8),
                Text('Descrição', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Html(data: p.description!),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  const _ImageGallery({required this.images, required this.controller, required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 320,
        color: Colors.grey[100],
        child: const Center(child: Icon(Icons.image_outlined, size: 64, color: Colors.grey)),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: controller,
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: AppConfig.resolveMediaUrl(images[i]),
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: Colors.grey[100]),
              errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == currentIndex ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == currentIndex ? Colors.white : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        // Image counter badge
        if (images.length > 1)
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text('${currentIndex + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
      ],
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String name;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelect;
  final Color accentColor;
  const _OptionGroup({required this.name, required this.values, required this.selected, required this.onSelect, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (selected != null) ...[
            const Text(': ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(selected!, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: accentColor)),
          ],
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final isSelected = selected == v;
            return GestureDetector(
              onTap: () => onSelect(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  v,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QtySelector extends StatelessWidget {
  final int qty;
  final VoidCallback? onDec;
  final VoidCallback onInc;
  const _QtySelector({required this.qty, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _QtyBtn(icon: Icons.remove, onTap: onDec),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        _QtyBtn(icon: Icons.add, onTap: onInc),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey : Colors.black87),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  const _AddToCartButton({required this.loading, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: enabled && !loading ? onTap : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        disabledBackgroundColor: Colors.grey.shade200,
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 18),
              SizedBox(width: 8),
              Text('Adicionar ao Carrinho', style: TextStyle(fontWeight: FontWeight.w700)),
            ]),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final double original;
  final double current;
  const _DiscountBadge({required this.original, required this.current});

  @override
  Widget build(BuildContext context) {
    final pct = ((1 - current / original) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.red[600], borderRadius: BorderRadius.circular(6)),
      child: Text('-$pct%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 340, color: Colors.white),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 24, width: double.infinity, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 32, width: 160, color: Colors.white),
            const SizedBox(height: 20),
            Container(height: 48, width: double.infinity, color: Colors.white),
          ]),
        ),
      ]),
    );
  }
}
