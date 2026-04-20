import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/store/storefront_store.dart';
import 'core/store/cart_store.dart';
import 'core/store/auth_store.dart';
import 'core/theme/theme_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  final storefrontStore = StorefrontStore();
  await storefrontStore.initialize(themeProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storefrontStore),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => CartStore()),
        ChangeNotifierProvider(create: (_) => AuthStore()..restoreSession()),
      ],
      child: const HavixApp(),
    ),
  );
}
