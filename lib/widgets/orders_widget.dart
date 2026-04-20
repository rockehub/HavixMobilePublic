import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api/commerce_api.dart';
import '../core/models/commerce_models.dart';
import '../core/models/storefront_models.dart';
import '../core/store/auth_store.dart';

class OrdersWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final StorefrontResolveResponse storefront;

  const OrdersWidget({super.key, required this.config, required this.storefront});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  final _api = CommerceApi();
  List<Order> _orders = [];
  bool _loading = true;

  static const _statusColors = {
    'PENDING': Colors.orange,
    'PAID': Colors.blue,
    'PROCESSING': Colors.purple,
    'SHIPPED': Colors.indigo,
    'DELIVERED': Colors.green,
    'CANCELLED': Colors.red,
  };

  static const _statusLabels = {
    'PENDING': 'Aguardando',
    'PAID': 'Pago',
    'PROCESSING': 'Processando',
    'SHIPPED': 'Enviado',
    'DELIVERED': 'Entregue',
    'CANCELLED': 'Cancelado',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthStore>();
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    try {
      _orders = await _api.getOrders();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Você ainda não fez nenhum pedido.')));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final order = _orders[i];
        final color = _statusColors[order.status] ?? Colors.grey;
        final label = _statusLabels[order.status] ?? order.status;
        final date = order.createdAt;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Pedido #${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null) Text(dateFmt.format(date), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(order.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () => context.go('/orders/${order.id}'),
          ),
        );
      },
    );
  }
}
