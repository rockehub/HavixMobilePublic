import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrinho')),
      body: SafeArea(
        child: PageLoader(
          pageType: 'CART',
          loader: () => StorefrontApi().getPageByType('CART'),
        ),
      ),
    );
  }
}
