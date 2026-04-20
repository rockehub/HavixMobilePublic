import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class CategoryScreen extends StatelessWidget {
  final String slug;
  const CategoryScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final api = StorefrontApi();
    return Scaffold(
      body: SafeArea(
        child: PageLoader(
          pageType: 'CATEGORY',
          slug: slug,
          loader: () => api.getCategoryPage(slug),
        ),
      ),
    );
  }
}
