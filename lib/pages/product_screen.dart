import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class ProductScreen extends StatelessWidget {
  final String slug;
  const ProductScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final api = StorefrontApi();
    return Scaffold(
      body: SafeArea(
        child: PageLoader(
          pageType: 'PRODUCT',
          slug: slug,
          loader: () => api.getProductPage(slug),
        ),
      ),
    );
  }
}
