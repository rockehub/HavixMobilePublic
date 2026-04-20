import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class SearchScreen extends StatelessWidget {
  final String query;
  const SearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final api = StorefrontApi();
    return Scaffold(
      appBar: AppBar(title: Text(query.isNotEmpty ? 'Busca: $query' : 'Buscar')),
      body: SafeArea(
        child: PageLoader(
          pageType: 'SEARCH',
          loader: () => api.getPageByType('SEARCH'),
        ),
      ),
    );
  }
}
