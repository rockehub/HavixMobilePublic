import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../api/auth_api.dart';
import '../api/api_client.dart';
import '../models/commerce_models.dart';

class AuthStore extends ChangeNotifier {
  final _api = AuthApi();
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  CustomerProfile? user;
  bool isAuthenticated = false;
  bool isLoading = false;
  String? error;

  // Non-null when backend returned requires2FA — holds the challengeToken.
  String? pendingChallengeToken;
  bool get requires2FA => pendingChallengeToken != null;

  // Biometrics
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> initBiometrics() async {
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      final saved = await _storage.read(key: 'biometric_enabled');
      final hasCredentials = await _storage.read(key: 'bio_identifier') != null;
      _biometricEnabled = saved == 'true' && hasCredentials;
      notifyListeners();
    } catch (_) {
      _biometricAvailable = false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para entrar na conta',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated) return false;
      final identifier = await _storage.read(key: 'bio_identifier');
      final password = await _storage.read(key: 'bio_password');
      if (identifier == null || password == null) return false;
      return await login(identifier, password);
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[Biometric] error: $e');
      return false;
    }
  }

  Future<void> enableBiometric(String identifier, String password) async {
    await _storage.write(key: 'bio_identifier', value: identifier);
    await _storage.write(key: 'bio_password', value: password);
    await _storage.write(key: 'biometric_enabled', value: 'true');
    _biometricEnabled = true;
    notifyListeners();
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: 'bio_identifier');
    await _storage.delete(key: 'bio_password');
    await _storage.write(key: 'biometric_enabled', value: 'false');
    _biometricEnabled = false;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    await initBiometrics();
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;
    ApiClient().setToken(token);
    try {
      user = await _api.getProfile();
      isAuthenticated = user != null;
      if (kDebugMode) debugPrint('[Auth] restoreSession: ok email=${user?.email}');
      notifyListeners();
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] restoreSession: access token invalid ($e), trying refresh');
    }
    // Access token invalid — try refresh
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh != null) {
      try {
        final data = await _api.refreshToken(refresh);
        await _applySession(data);
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('[Auth] restoreSession: refresh failed ($e)');
      }
    }
    await _clearSession();
  }

  /// Returns true on success, false if 2FA is required (check [pendingChallengeToken]),
  /// throws on credential error so the UI can show the error message.
  Future<bool> login(String identifier, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.login(identifier, password);
      if (data['requires2FA'] == true) {
        pendingChallengeToken = data['challengeToken'] as String?;
        isLoading = false;
        notifyListeners();
        return false; // caller should open 2FA dialog
      }
      await _applySession(data);
      return true;
    } catch (e) {
      error = _parseError(e);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyTwoFactor(String code) async {
    if (pendingChallengeToken == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.verifyTwoFactor(code, pendingChallengeToken!);
      pendingChallengeToken = null;
      await _applySession(data);
    } catch (e) {
      error = _parseError(e);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void cancelTwoFactor() {
    pendingChallengeToken = null;
    notifyListeners();
  }

  Future<void> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? phone,
    int? areaCode,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        phone: phone,
        areaCode: areaCode,
      );
      await _applySession(data);
    } catch (e) {
      error = _parseError(e);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String firstname,
    required String lastname,
    String? phone,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _api.updateProfile(
          firstname: firstname, lastname: lastname, phone: phone);
      notifyListeners();
    } catch (e) {
      error = _parseError(e);
      rethrow;
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

  // ── OAuth ─────────────────────────────────────────────────────────────────

  Future<String> getOAuthUrl(String provider) => _api.getOAuthUrl(provider);

  Future<List<String>> getActiveProviders() => _api.getActiveProviders();

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _applySession(Map<String, dynamic> data) async {
    if (kDebugMode) debugPrint('[Auth] _applySession keys=${data.keys.toList()}');
    final token = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (token == null) {
      if (kDebugMode) debugPrint('[Auth] _applySession: NO accessToken in response!');
      return;
    }
    ApiClient().setToken(token);
    await _storage.write(key: 'access_token', value: token);
    if (refresh != null) await _storage.write(key: 'refresh_token', value: refresh);

    final customerRaw = data['customer'];
    if (kDebugMode) debugPrint('[Auth] _applySession customer raw type=${customerRaw.runtimeType}');
    if (customerRaw is Map<String, dynamic>) {
      user = CustomerProfile.fromJson(customerRaw);
    } else {
      try {
        user = await _api.getProfile();
      } catch (e) {
        if (kDebugMode) debugPrint('[Auth] _applySession getProfile failed: $e');
      }
    }
    // Consider any logged-in user (even guest) as authenticated for UI purposes
    isAuthenticated = user != null;
    if (kDebugMode) debugPrint('[Auth] _applySession done: isAuthenticated=$isAuthenticated user=${user?.email} guest=${user?.guest}');
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    ApiClient().setToken(null);
    user = null;
    isAuthenticated = false;
    pendingChallengeToken = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('403')) return 'E-mail ou senha incorretos';
    if (msg.contains('409')) return 'Este e-mail já está cadastrado';
    return 'Ocorreu um erro. Tente novamente.';
  }
}
