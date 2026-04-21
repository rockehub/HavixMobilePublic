import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api/auth_api.dart';
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
  final _api = AuthApi();
  List<CustomerOrder> _orders = [];
  bool _loading = true;
  String? _expandedId;
  final Map<String, List<OrderItem>> _itemsCache = {};
  final Map<String, bool> _itemsLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!context.read<AuthStore>().isAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      _orders = await _api.listOrders();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleExpand(String orderId) async {
    if (_expandedId == orderId) {
      setState(() => _expandedId = null);
      return;
    }
    setState(() => _expandedId = orderId);
    if (_itemsCache.containsKey(orderId)) return;
    setState(() => _itemsLoading[orderId] = true);
    try {
      final items = await _api.getOrderItems(orderId);
      if (mounted) setState(() => _itemsCache[orderId] = items);
    } catch (_) {
      if (mounted) setState(() => _itemsCache[orderId] = []);
    } finally {
      if (mounted) setState(() => _itemsLoading[orderId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    if (!auth.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Área restrita', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Faça login para ver seus pedidos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Entrar'),
            ),
          ]),
        ),
      );
    }

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: List.generate(3, (_) => _OrderSkeleton())),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Você ainda não fez nenhum pedido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meus Pedidos',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text('${_orders.length} pedido${_orders.length != 1 ? 's' : ''}',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),
          ..._orders.map((order) {
            final expanded = _expandedId == order.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(children: [
                  // Header row
                  InkWell(
                    onTap: () => _toggleExpand(order.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('Pedido #${order.number}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(width: 10),
                            _StatusBadge(statusCode: order.statusCode,
                                label: order.statusLabel ?? 'Aguardando'),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            '${order.createdAt != null ? dateFmt.format(order.createdAt!) : ''}  ·  ${order.itemsCount} ${order.itemsCount == 1 ? 'item' : 'itens'}  ·  ',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.55)),
                          ),
                          Text(fmt.format(order.total),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                        ])),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              color: accent),
                        ),
                      ]),
                    ),
                  ),

                  // Expanded items
                  if (expanded) ...[
                    Divider(height: 0, color: theme.dividerColor),
                    if (_itemsLoading[order.id] == true)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (_itemsCache[order.id] != null)
                      ..._itemsCache[order.id]!.map((item) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.inventory_2_outlined, size: 18, color: accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name ?? 'Produto',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (item.variantName != null)
                              Text(item.variantName!,
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.55))),
                          ])),
                          Text('${item.quantity}x  ${fmt.format(item.unitPrice)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      )),
                    const SizedBox(height: 12),
                  ],
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? statusCode;
  final String label;
  const _StatusBadge({this.statusCode, required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = (statusCode ?? '').toLowerCase();
    Color color;
    if (normalized.contains('delivered') || normalized.contains('entregue')) {
      color = Colors.green;
    } else if (normalized.contains('shipped') || normalized.contains('enviado')) {
      color = Colors.indigo;
    } else if (normalized.contains('paid') || normalized.contains('pago')) {
      color = Colors.blue;
    } else if (normalized.contains('cancel')) {
      color = Colors.red;
    } else if (normalized.contains('processing') || normalized.contains('process')) {
      color = Colors.purple;
    } else {
      color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _OrderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
