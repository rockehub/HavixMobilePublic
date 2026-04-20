import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class ContentScreen extends StatelessWidget {
  final String path;
  const ContentScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageLoader(
          pageType: 'CONTENT',
          loader: () => StorefrontApi().getPageByPath('/$path'),
        ),
      ),
    );
  }
}
