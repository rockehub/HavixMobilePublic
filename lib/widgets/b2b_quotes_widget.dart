import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/storefront_models.dart';

class B2bQuotesWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const B2bQuotesWidget({super.key, required this.config, required this.storefront});

  static const _statusColors = {
    'PENDING': Colors.orange,
    'APPROVED': Colors.green,
    'REJECTED': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    if (!storefront.b2bEnabled) return const SizedBox.shrink();

    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final quotes = (config['quotes'] as List<dynamic>? ?? []);
    final statusColors = _statusColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cotações', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (quotes.isEmpty)
            const Text('Nenhuma cotação encontrada.')
          else
            ...quotes.map((q) {
              final quote = q as Map<String, dynamic>;
              final status = quote['status'] as String? ?? 'PENDING';
              final color = statusColors[status] ?? Colors.grey;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text('Cotação #${(quote['id'] as String? ?? '').substring(0, 8)}'),
                  subtitle: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: TextStyle(color: color, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Text(fmt.format((quote['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  children: [
                    ...(quote['items'] as List<dynamic>? ?? []).map((item) {
                      final i = item as Map<String, dynamic>;
                      return ListTile(dense: true, title: Text(i['name'] as String? ?? ''), trailing: Text('${i['quantity']}x'));
                    }),
                    if (status == 'APPROVED')
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(onPressed: () {}, child: const Text('Converter em pedido')),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
