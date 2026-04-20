import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class CartWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const CartWidget({super.key, required this.config, required this.storefront});

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CartStore>().fetchCart();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final cart = context.watch<CartStore>();

    if (cart.cart.lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Seu carrinho está vazio', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/'), child: const Text('Continuar comprando')),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...cart.cart.lines.map((line) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: line.imageUrl != null
                        ? CachedNetworkImage(imageUrl: line.imageUrl!, width: 70, height: 70, fit: BoxFit.cover)
                        : Container(width: 70, height: 70, color: Colors.grey[200]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2),
                        if (line.variantName != null)
                          Text(line.variantName!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(fmt.format(line.totalPrice), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: line.quantity > 1 ? () => cart.updateItem(line.id, line.quantity - 1) : null),
                          Text('${line.quantity}'),
                          IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => cart.updateItem(line.id, line.quantity + 1)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => cart.removeItem(line.id)),
                    ],
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  decoration: const InputDecoration(hintText: 'Cupom de desconto'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final ok = await cart.applyDiscount(_discountController.text);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Cupom aplicado!' : 'Cupom inválido')));
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', fmt.format(cart.cart.subtotal)),
          if (cart.cart.discount != null && cart.cart.discount! > 0)
            _summaryRow('Desconto', '-${fmt.format(cart.cart.discount!)}', color: Colors.green),
          if (cart.cart.shipping != null)
            _summaryRow('Frete', fmt.format(cart.cart.shipping!)),
          const Divider(),
          _summaryRow('Total', fmt.format(cart.cart.total), bold: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/checkout'),
              child: const Text('Finalizar Compra'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
