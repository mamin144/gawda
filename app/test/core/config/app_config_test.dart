import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/config/app_config.dart';

String _jwtWithRole(String role) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')).replaceAll('=', '');
  final payload = base64Url.encode(utf8.encode('{"role":"$role"}')).replaceAll('=', '');
  return '$header.$payload.signature';
}

void main() {
  group('AppConfig.parse', () {
    test('accepts a valid https URL and publishable key', () {
      final config = AppConfig.parse(
        url: 'https://example.supabase.co',
        key: 'sb_publishable_abc123',
      );
      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabasePublishableKey, 'sb_publishable_abc123');
    });

    test('accepts a legacy anon JWT for compatibility', () {
      final config = AppConfig.parse(
        url: 'https://example.supabase.co',
        key: _jwtWithRole('anon'),
      );
      expect(config.supabasePublishableKey, _jwtWithRole('anon'));
    });

    test('rejects an empty URL', () {
      expect(
        () => AppConfig.parse(url: '', key: 'sb_publishable_abc123'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects a non-https URL', () {
      expect(
        () => AppConfig.parse(url: 'http://example.supabase.co', key: 'sb_publishable_abc123'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects a URL without a host', () {
      expect(
        () => AppConfig.parse(url: 'https://', key: 'sb_publishable_abc123'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects an empty key', () {
      expect(
        () => AppConfig.parse(url: 'https://example.supabase.co', key: ''),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects a secret key', () {
      expect(
        () => AppConfig.parse(url: 'https://example.supabase.co', key: 'sb_secret_abc123'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('rejects a service_role JWT', () {
      expect(
        () =>
            AppConfig.parse(url: 'https://example.supabase.co', key: _jwtWithRole('service_role')),
        throwsA(isA<ConfigException>()),
      );
    });
  });
}
