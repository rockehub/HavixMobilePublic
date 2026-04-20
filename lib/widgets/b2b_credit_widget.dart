import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/storefront_models.dart';

class B2bCreditWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const B2bCreditWidget({super.key, required this.config, required this.storefront});

  @override
  Widget build(BuildContext context) {
    if (!storefront.b2bEnabled) return const SizedBox.shrink();

    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final limit = (config['creditLimit'] as num?)?.toDouble() ?? 0;
    final used = (config['usedCredit'] as num?)?.toDouble() ?? 0;
    final available = limit - used;
    final history = (config['history'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crédito B2B', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _creditCard(context, 'Limite Total', fmt.format(limit), Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _creditCard(context, 'Utilizado', fmt.format(used), Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _creditCard(context, 'Disponível', fmt.format(available), Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: limit > 0 ? used / limit : 0, backgroundColor: Colors.grey[200], color: used / (limit > 0 ? limit : 1) > 0.8 ? Colors.red : Colors.blue),
          const SizedBox(height: 20),
          Text('Histórico', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('Nenhuma movimentação.')
          else
            ...history.map((h) {
              final item = h as Map<String, dynamic>;
              final amount = (item['amount'] as num?)?.toDouble() ?? 0;
              final isPositive = amount > 0;
              return ListTile(
                dense: true,
                title: Text(item['description'] as String? ?? ''),
                subtitle: Text(item['date'] as String? ?? ''),
                trailing: Text(
                  '${isPositive ? '+' : ''}${fmt.format(amount)}',
                  style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _creditCard(BuildContext context, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
