import 'package:flutter/material.dart';
import '../core/api/storefront_api.dart';
import 'resolved_page.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Conta')),
      body: SafeArea(
        child: PageLoader(
          pageType: 'MY_ACCOUNT',
          loader: () => StorefrontApi().getPageByType('MY_ACCOUNT'),
        ),
      ),
    );
  }
}
