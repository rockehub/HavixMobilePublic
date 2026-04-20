import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api/commerce_api.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class B2bQuickOrderWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const B2bQuickOrderWidget({super.key, required this.config, required this.storefront});

  @override
  State<B2bQuickOrderWidget> createState() => _B2bQuickOrderWidgetState();
}

class _B2bQuickOrderWidgetState extends State<B2bQuickOrderWidget> {
  final _api = CommerceApi();
  final _searchCtrl = TextEditingController();
  List<ProductSummary> _results = [];
  final Map<String, int> _qtys = {};
  bool _searching = false;

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      _results = await _api.getProducts(search: _searchCtrl.text, limit: 10);
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.storefront.b2bEnabled) return const SizedBox.shrink();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedido Rápido', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(hintText: 'Buscar por SKU ou nome...', prefixIcon: Icon(Icons.search)),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _search, child: const Text('Buscar')),
            ],
          ),
          const SizedBox(height: 12),
          if (_searching) const Center(child: CircularProgressIndicator()),
          ..._results.map((p) {
            _qtys.putIfAbsent(p.id, () => 1);
            return ListTile(
              title: Text(p.name),
              subtitle: Text(fmt.format(p.price)),
              trailing: SizedBox(
                width: 120,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => setState(() => _qtys[p.id] = (_qtys[p.id]! - 1).clamp(1, 999))),
                    Text('${_qtys[p.id]}'),
                    IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setState(() => _qtys[p.id] = _qtys[p.id]! + 1)),
                  ],
                ),
              ),
            );
          }),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final cart = context.read<CartStore>();
                  for (final p in _results) {
                    if (p.inStock) {
                      await cart.addToCart(p.id, _qtys[p.id] ?? 1);
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itens adicionados ao carrinho!')));
                },
                child: const Text('Adicionar todos ao carrinho'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
