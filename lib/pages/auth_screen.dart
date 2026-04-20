import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: PageLoader(
          pageType: 'AUTH',
          loader: () => StorefrontApi().getPageByType('AUTH'),
        ),
      ),
    );
  }
}
