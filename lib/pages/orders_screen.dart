import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: SafeArea(
        child: PageLoader(
          pageType: 'ORDERS',
          loader: () => StorefrontApi().getPageByType('ORDERS'),
        ),
      ),
    );
  }
}
