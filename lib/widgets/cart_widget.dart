import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/helpers/media_image.dart';
import '../core/models/commerce_models.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartStore>().fetchCart();
    });
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cart.cart.lines.map((line) => _CartLineCard(line: line, fmt: fmt)),

          const SizedBox(height: 16),

          // Coupon input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    hintText: 'Cupom de desconto',
                    prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                    suffixIcon: cart.cart.discountCode != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => cart.removeDiscount(),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await cart.applyDiscount(_discountController.text.trim());
                  messenger.showSnackBar(
                    SnackBar(content: Text(ok ? 'Cupom aplicado!' : 'Cupom inválido ou expirado')),
                  );
                  if (ok) _discountController.clear();
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Applied coupon badge
          if (cart.cart.discountCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Cupom ${cart.cart.discountCode} aplicado',
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Applied promotions
          for (final promo in cart.cart.appliedPromotions)
            if (promo.displayLabel != null && promo.discountAmount > 0)
              _summaryRow(
                promo.displayLabel!,
                '-${fmt.format(promo.discountAmount)}',
                color: Colors.green,
                icon: Icons.sell_outlined,
              ),

          _summaryRow('Subtotal', fmt.format(cart.cart.subtotal)),
          if (cart.cart.discount != null && cart.cart.discount! > 0)
            _summaryRow('Desconto total', '-${fmt.format(cart.cart.discount!)}', color: Colors.green),
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

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 14)),
          ),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: bold ? 15 : 14)),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartLine line;
  final NumberFormat fmt;

  const _CartLineCard({required this.line, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartStore>();

    // Build variant label: prefer propertiesDescription ("Tamanho: M, Cor: Azul"),
    // fall back to plain variantName.
    final variantLabel = (line.propertiesDescription?.isNotEmpty == true)
        ? line.propertiesDescription
        : line.variantName;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaImage(
              url: line.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (variantLabel != null && variantLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _VariantChips(description: variantLabel),
                    ),
                  const SizedBox(height: 6),
                  Text(fmt.format(line.totalPrice),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13)),
                  if (line.quantity > 1)
                    Text('${fmt.format(line.unitPrice)} × ${line.quantity}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: line.quantity > 1 ? () => cart.updateItem(line.id, line.quantity - 1) : null),
                    Text('${line.quantity}', style: const TextStyle(fontSize: 14)),
                    IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => cart.updateItem(line.id, line.quantity + 1)),
                  ],
                ),
                IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => cart.removeItem(line.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders "Tamanho: M, Cor: Azul" as individual label chips.
class _VariantChips extends StatelessWidget {
  final String description;

  const _VariantChips({required this.description});

  @override
  Widget build(BuildContext context) {
    final parts = description.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: parts.map((part) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(part, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        );
      }).toList(),
    );
  }
}
