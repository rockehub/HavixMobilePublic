import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Cached from last successful resolve — available before API call completes
  String? cachedLogoUrl;
  String? cachedStoreName;

  Future<void> initialize(ThemeProvider themeProvider) async {
    isLoading = true;
    hasError = false;
    errorMessage = null;

    // Load cached branding so splash can show it immediately
    final prefs = await SharedPreferences.getInstance();
    cachedLogoUrl  = prefs.getString('cached_logo_url');
    cachedStoreName = prefs.getString('cached_store_name');

    try {
      notifyListeners();
    } catch (_) {}

    try {
      resolveData = await _api.resolve();
      if (resolveData?.publicToken != null) {
        ApiClient().setToken(resolveData!.publicToken);
        await _storage.write(key: 'public_token', value: resolveData!.publicToken);
      }
      themeProvider.applyStorefrontTheme(resolveData?.theme);

      // Persist logo + store name for next cold start
      final logo = resolveData?.logo?.hdUrl ?? resolveData?.logo?.smUrl;
      final name = resolveData?.storeName;
      if (logo != null) await prefs.setString('cached_logo_url', logo);
      if (name != null) await prefs.setString('cached_store_name', name);
      cachedLogoUrl  = logo ?? cachedLogoUrl;
      cachedStoreName = name ?? cachedStoreName;
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
      debugPrint('[storefront] resolve error: $e');
    } finally {
      isLoading = false;
      try {
        notifyListeners();
      } catch (_) {}
    }
  }
}
