import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api/commerce_api.dart';
import '../core/models/commerce_models.dart';

class OrderDetailScreen extends StatefulWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _api = CommerceApi();
  late Future<Order> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getOrder(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.id.substring(0, 8)}')),
      body: FutureBuilder<Order>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _future = _api.getOrder(widget.id)),
                child: const Text('Tentar novamente'),
              ),
            );
          }
          final order = snapshot.data!;
          final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.status}', style: Theme.of(context).textTheme.titleMedium),
                      if (order.createdAt != null)
                        Text(dateFmt.format(order.createdAt!), style: Theme.of(context).textTheme.bodySmall),
                      if (order.trackingCode != null) ...[
                        const SizedBox(height: 8),
                        Text('Rastreio: ${order.trackingCode}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...order.lines.map((line) => ListTile(
                title: Text(line.productName),
                subtitle: Text(line.variantName ?? ''),
                trailing: Text('${line.quantity}x ${fmt.format(line.totalPrice)}'),
              )),
              const Divider(),
              ListTile(
                title: const Text('Total'),
                trailing: Text(fmt.format(order.total), style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          );
        },
      ),
    );
  }
}
