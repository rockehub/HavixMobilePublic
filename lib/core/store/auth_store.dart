import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/auth_api.dart';
import '../api/api_client.dart';
import '../models/commerce_models.dart';

class AuthStore extends ChangeNotifier {
  final _api = AuthApi();
  final _storage = const FlutterSecureStorage();

  CustomerProfile? user;
  bool isAuthenticated = false;
  bool isLoading = false;

  Future<void> restoreSession() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      ApiClient().setToken(token);
      try {
        user = await _api.getProfile();
        isAuthenticated = true;
        notifyListeners();
      } catch (_) {
        await _clearSession();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      final token = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (token != null) {
        ApiClient().setToken(token);
        await _storage.write(key: 'access_token', value: token);
        if (refresh != null) await _storage.write(key: 'refresh_token', value: refresh);
        user = await _api.getProfile();
        isAuthenticated = true;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _api.register(name, email, password);
      final token = data['accessToken'] as String?;
      if (token != null) {
        ApiClient().setToken(token);
        await _storage.write(key: 'access_token', value: token);
        user = await _api.getProfile();
        isAuthenticated = true;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _clearSession();
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    ApiClient().setToken(null);
    user = null;
    isAuthenticated = false;
    notifyListeners();
  }
}
