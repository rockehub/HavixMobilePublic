import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Compra')),
      body: SafeArea(
        child: PageLoader(
          pageType: 'CHECKOUT',
          loader: () => StorefrontApi().getPageByType('CHECKOUT'),
        ),
      ),
    );
  }
}
