import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import '../models/commerce_models.dart';
import 'api_client.dart';

class AuthApi {
  final _dio = ApiClient().dio;

  // All auth endpoints wrap the payload: { success, message, data: T }
  T _unwrap<T>(dynamic responseData, T Function(Map<String, dynamic>) fromMap) {
    if (responseData is Map<String, dynamic>) {
      final inner = responseData['data'];
      if (inner is Map<String, dynamic>) return fromMap(inner);
    }
    throw Exception('Unexpected auth response: $responseData');
  }

  Map<String, dynamic> _unwrapMap(dynamic responseData) =>
      _unwrap(responseData, (m) => m);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await _dio.post('/api/v1/commerce/customer/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
    if (kDebugMode) debugPrint('[Auth] login raw: ${response.data}');
    return _unwrapMap(response.data);
  }

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? phone,
    int? areaCode,
  }) async {
    final response = await _dio.post('/api/v1/commerce/customer/auth/register', data: {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (areaCode != null) 'areaCode': areaCode,
    });
    if (kDebugMode) debugPrint('[Auth] register raw: ${response.data}');
    return _unwrapMap(response.data);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/commerce/customer/auth/logout');
    } catch (_) {}
  }

  // Backend expects the refresh token as the Authorization header value.
  Future<Map<String, dynamic>> refreshToken(String token) async {
    final response = await _dio.post(
      '/api/v1/commerce/customer/auth/refresh',
      options: dio_pkg.Options(headers: {'Authorization': token}),
    );
    return _unwrapMap(response.data);
  }

  Future<CustomerProfile> getProfile() async {
    final response = await _dio.get('/api/v1/commerce/customer/auth/me');
    if (kDebugMode) debugPrint('[Auth] me raw: ${response.data}');
    return _unwrap(response.data, CustomerProfile.fromJson);
  }

  Future<CustomerProfile> updateProfile({
    required String firstname,
    required String lastname,
    String? phone,
  }) async {
    final response = await _dio.put('/api/v1/commerce/customer/profile', data: {
      'firstname': firstname,
      'lastname': lastname,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _unwrap(response.data, CustomerProfile.fromJson);
  }

  Future<List<String>> getActiveProviders() async {
    try {
      final response = await _dio.get('/api/v1/commerce/auth/providers');
      final data = response.data;
      final list = (data is Map && data.containsKey('data')) ? data['data'] : data;
      if (list is List) return list.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  Future<String> getOAuthUrl(String provider) async {
    final response = await _dio.get(
        '/api/v1/commerce/customer/auth/oauth/$provider/url');
    final inner = _unwrapMap(response.data);
    return inner['authorizationUrl'] as String;
  }

  Future<Map<String, dynamic>> handleOAuthCallback(
      String provider, String code, {String? state}) async {
    final response = await _dio.post(
        '/api/v1/commerce/customer/auth/oauth/callback',
        data: {
          'provider': provider,
          'code': code,
          if (state != null) 'state': state,
        });
    return _unwrapMap(response.data);
  }

  Future<Map<String, dynamic>> verifyTwoFactor(
      String code, String challengeToken) async {
    final response = await _dio.post(
        '/api/v1/commerce/customer/auth/2fa/verify',
        data: {'code': code, 'challengeToken': challengeToken});
    return _unwrapMap(response.data);
  }

  Future<List<CustomerOrder>> listOrders({int page = 0, int size = 10}) async {
    final response = await _dio.get('/api/v1/commerce/customer/orders',
        queryParameters: {'page': page, 'size': size});
    final raw = response.data;
    final inner = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    final content =
        (inner is Map ? inner['content'] : inner) as List<dynamic>? ?? [];
    return content
        .map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final response = await _dio
        .get('/api/v1/commerce/customer/orders/$orderId/items');
    final raw = response.data;
    final list =
        (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    final items = list as List<dynamic>? ?? [];
    return items
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
