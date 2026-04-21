import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class ProductScreen extends StatelessWidget {
  final String slug;
  const ProductScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final api = StorefrontApi();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: PageLoader(
              pageType: 'PRODUCT',
              slug: slug,
              loader: () => api.getProductPage(slug),
            ),
          ),
        ],
      ),
    );
  }
}
