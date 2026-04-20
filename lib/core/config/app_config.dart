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
}
