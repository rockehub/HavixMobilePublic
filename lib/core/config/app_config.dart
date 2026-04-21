class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String tenantId = String.fromEnvironment(
    'TENANT_ID',
    defaultValue: '',
  );
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Havix Store',
  );

  /// Rewrites media URLs that contain localhost/127.0.0.1 to use the
  /// configured API base URL, so images work on physical devices and emulators.
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    final base = Uri.tryParse(apiBaseUrl);
    final uri = Uri.tryParse(url);
    if (base == null || uri == null) return url;
    final host = uri.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return uri.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
    }
    return url;
  }
}
