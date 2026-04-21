import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/store/storefront_store.dart';
import 'core/store/cart_store.dart';
import 'core/store/auth_store.dart';
import 'core/theme/theme_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final themeProvider = ThemeProvider();
  final storefrontStore = StorefrontStore();
  final authStore = AuthStore();
  final cartStore = CartStore();

  // Bridge: refresh cart when auth state changes (login/logout/restore).
  // Track previous state to avoid re-fetching on unrelated notifyListeners calls.
  bool wasAuthenticated = false;
  authStore.addListener(() {
    final isAuth = authStore.isAuthenticated;
    if (isAuth && !wasAuthenticated) {
      cartStore.fetchCart();
    } else if (!isAuth && wasAuthenticated) {
      cartStore.clear();
    }
    wasAuthenticated = isAuth;
  });

  // Initialize storefront and restore the saved session concurrently.
  await Future.wait([
    storefrontStore.initialize(themeProvider),
    authStore.restoreSession(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storefrontStore),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: cartStore),
        ChangeNotifierProvider.value(value: authStore),
      ],
      child: const HavixApp(),
    ),
  );
}
