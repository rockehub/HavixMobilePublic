import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/storefront_models.dart';

class B2bDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const B2bDashboardWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    if (!storefront.b2bEnabled) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('B2B não habilitado para esta loja.')),
      );
    }

    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final creditLimit = (config['creditLimit'] as num?)?.toDouble() ?? 0;
    final usedCredit = (config['usedCredit'] as num?)?.toDouble() ?? 0;
    final openOrders = config['openOrders'] as int? ?? 0;
    final pendingQuotes = config['pendingQuotes'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _card(context, 'Limite de Crédito', fmt.format(creditLimit), Icons.account_balance, Colors.blue),
          _card(context, 'Crédito Disponível', fmt.format(creditLimit - usedCredit), Icons.credit_score, Colors.green),
          _card(context, 'Pedidos Abertos', '$openOrders', Icons.shopping_bag_outlined, Colors.orange),
          _card(context, 'Cotações Pendentes', '$pendingQuotes', Icons.request_quote_outlined, Colors.purple),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
