import '../models/commerce_models.dart';
import 'api_client.dart';

class AuthApi {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/v1/commerce/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _dio.post('/api/v1/commerce/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/api/v1/commerce/auth/logout');
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/api/v1/commerce/auth/refresh', data: {'refreshToken': refreshToken});
    return response.data as Map<String, dynamic>;
  }

  Future<CustomerProfile> getProfile() async {
    final response = await _dio.get('/api/v1/commerce/customers/me');
    return CustomerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CustomerProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/commerce/customers/me', data: data);
    return CustomerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/api/v1/commerce/auth/forgot-password', data: {'email': email});
  }
}
