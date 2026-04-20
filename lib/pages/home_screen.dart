import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = StorefrontApi();
    return Scaffold(
      body: SafeArea(
        child: PageLoader(
          pageType: 'HOME',
          loader: () => api.getPageByType('HOME'),
        ),
      ),
    );
  }
}
