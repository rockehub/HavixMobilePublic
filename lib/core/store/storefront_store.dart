import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/storefront_api.dart';
import '../api/api_client.dart';
import '../models/storefront_models.dart';
import '../theme/theme_provider.dart';

class StorefrontStore extends ChangeNotifier {
  static final StorefrontStore _instance = StorefrontStore._internal();
  factory StorefrontStore() => _instance;
  StorefrontStore._internal();

  final _storage = const FlutterSecureStorage();
  final _api = StorefrontApi();

  StorefrontResolveResponse? resolveData;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  Future<void> initialize(ThemeProvider themeProvider) async {
    isLoading = true;
    hasError = false;
    notifyListeners();
    try {
      resolveData = await _api.resolve();
      if (resolveData?.publicToken != null) {
        ApiClient().setToken(resolveData!.publicToken);
        await _storage.write(key: 'public_token', value: resolveData!.publicToken);
      }
      themeProvider.applyStorefrontTheme(resolveData?.theme);
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
