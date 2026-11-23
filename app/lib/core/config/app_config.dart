import 'dart:convert';

/// Thrown when the compile-time environment configuration is missing or unsafe.
class ConfigException implements Exception {
  const ConfigException(this.reason);

  final String reason;

  @override
  String toString() => 'ConfigException: $reason';
}

/// Compile-time app configuration supplied via `--dart-define-from-file`.
///
/// Only the project URL and the publishable key may ever reach the client.
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabasePublishableKey});

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Reads the values injected at build time and validates them.
  factory AppConfig.fromEnvironment() => AppConfig.parse(
    url: const String.fromEnvironment('SUPABASE_URL'),
    key: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Validates raw values; throws [ConfigException] on anything unsafe.
  factory AppConfig.parse({required String url, required String key}) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const ConfigException('SUPABASE_URL must be a valid https URL');
    }
    if (key.isEmpty) {
      throw const ConfigException('SUPABASE_PUBLISHABLE_KEY must not be empty');
    }
    if (key.startsWith('sb_secret_')) {
      throw const ConfigException('A secret key must never be used in the app');
    }
    if (_isServiceRoleJwt(key)) {
      throw const ConfigException('A service_role key must never be used in the app');
    }
    return AppConfig(supabaseUrl: url, supabasePublishableKey: key);
  }

  static bool _isServiceRoleJwt(String key) {
    final parts = key.split('.');
    if (parts.length != 3) {
      return false;
    }
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> && decoded['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}
