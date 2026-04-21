import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  void setToken(String? token) => _token = token;

  final _cookieJar = CookieJar();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.addAll([
      CookieManager(_cookieJar),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          if (AppConfig.tenantId.isNotEmpty) {
            options.headers['X-Tenant-Id'] = AppConfig.tenantId;
          }
          if (kDebugMode) {
            debugPrint('[HTTP] --> ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[HTTP] <-- ${response.statusCode} ${response.requestOptions.uri}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('[HTTP] ERR ${error.response?.statusCode} ${error.requestOptions.uri} — ${error.message}');
          }
          handler.next(error);
        },
      ),
    ]);
}
