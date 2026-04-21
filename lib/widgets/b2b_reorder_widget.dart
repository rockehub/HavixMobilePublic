import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api/auth_api.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class B2bReorderWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const B2bReorderWidget({super.key, required this.config, required this.storefront});

  @override
  State<B2bReorderWidget> createState() => _B2bReorderWidgetState();
}

class _B2bReorderWidgetState extends State<B2bReorderWidget> {
  final _api = AuthApi();
  List<CustomerOrder> _orders = [];
  bool _loading = true;
  final Set<String> _reordering = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.storefront.b2bEnabled) { setState(() => _loading = false); return; }
    try { _orders = await _api.listOrders(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
          Text('Repetir Pedido', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_orders.isEmpty)
            const Text('Nenhum pedido anterior encontrado.')
          else
            ..._orders.map((order) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('Pedido #${order.number}'),
                subtitle: Text('${order.itemsCount} item(s) — ${fmt.format(order.total)}'),
                trailing: _reordering.contains(order.id)
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton(
                        onPressed: () async {
                          setState(() => _reordering.add(order.id));
                          try {
                            final items = await _api.getOrderItems(order.id);
                            final cart = context.read<CartStore>();
                            for (final item in items) {
                              await cart.addToCart(item.variantId, 1, productId: item.productId);
                            }
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itens adicionados ao carrinho!')));
                          } catch (_) {}
                          if (mounted) setState(() => _reordering.remove(order.id));
                        },
                        child: const Text('Repetir'),
                      ),
              ),
            )),
        ],
      ),
    );
  }
}
