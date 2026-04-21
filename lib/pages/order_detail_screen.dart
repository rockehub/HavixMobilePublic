import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/api/auth_api.dart';
import '../core/api/commerce_api.dart';
import '../core/models/commerce_models.dart';

class OrderDetailScreen extends StatefulWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _commerceApi = CommerceApi();
  final _authApi = AuthApi();
  CustomerOrder? _order;
  List<OrderItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _commerceApi.getOrder(widget.id),
        _authApi.getOrderItems(widget.id),
      ]);
      if (mounted) {
        setState(() {
          _order = results[0] as CustomerOrder;
          _items = results[1] as List<OrderItem>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
        ),
        title: _order != null ? Text('Pedido #${_order!.number}') : const Text('Pedido'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? Center(child: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Status card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('Status: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_order!.statusLabel ?? 'Aguardando',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                        ]),
                        if (_order!.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(dateFmt.format(_order!.createdAt!),
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.55))),
                        ],
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Items
                    if (_items.isNotEmpty) ...[
                      Text('Itens', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      ..._items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name ?? 'Produto',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (item.variantName != null)
                              Text(item.variantName!,
                                  style: TextStyle(fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.55))),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${item.quantity}x', style: const TextStyle(fontSize: 12)),
                            Text(fmt.format(item.unitPrice),
                                style: TextStyle(fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary)),
                          ]),
                        ]),
                      )),
                    ],

                    const Divider(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(fmt.format(_order!.total),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18,
                              color: theme.colorScheme.primary)),
                    ]),
                  ],
                ),
    );
  }
}
