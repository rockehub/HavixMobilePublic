import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/storefront_models.dart';
import '../core/store/cart_store.dart';

class MiniCartWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const MiniCartWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carrinho (${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'itens'})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            if (cart.cart.lines.isEmpty)
              const Text('Seu carrinho está vazio')
            else ...[
              ...cart.cart.lines.take(3).map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${l.quantity}x ${l.productName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                    Text(fmt.format(l.totalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
              if (cart.cart.lines.length > 3)
                Text('+ ${cart.cart.lines.length - 3} item(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fmt.format(cart.cart.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => context.go('/cart'), child: const Text('Ver carrinho completo')),
            ),
          ],
        ),
      ),
    );
  }
}
