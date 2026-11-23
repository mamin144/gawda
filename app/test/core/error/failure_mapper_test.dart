import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/error/failure_mapper.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('maps invalid_credentials AuthException to InvalidCredentialsFailure', () {
      const error = AuthException('Invalid login credentials', code: 'invalid_credentials');
      expect(mapExceptionToFailure(error), isA<InvalidCredentialsFailure>());
    });

    test('maps other AuthException to ServerFailure preserving code and message', () {
      const error = AuthException('Too many requests', code: 'over_request_rate_limit');
      final failure = mapExceptionToFailure(error);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 'over_request_rate_limit');
      expect(failure.message, 'Too many requests');
    });

    test('maps PostgrestException to ServerFailure preserving code and message', () {
      const error = PostgrestException(message: 'permission denied', code: '42501');
      final failure = mapExceptionToFailure(error);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, '42501');
      expect(failure.message, 'permission denied');
    });

    test('maps SocketException to NetworkFailure', () {
      const error = SocketException('Failed host lookup');
      expect(mapExceptionToFailure(error), isA<NetworkFailure>());
    });

    test('maps TimeoutException to NetworkFailure', () {
      final error = TimeoutException('slow', const Duration(seconds: 30));
      expect(mapExceptionToFailure(error), isA<NetworkFailure>());
    });

    test('maps http ClientException to NetworkFailure', () {
      final error = http.ClientException('Connection closed');
      expect(mapExceptionToFailure(error), isA<NetworkFailure>());
    });

    test('maps anything else to UnexpectedFailure keeping the cause', () {
      final error = StateError('boom');
      final failure = mapExceptionToFailure(error);
      expect(failure, isA<UnexpectedFailure>());
      expect((failure as UnexpectedFailure).cause, same(error));
    });
  });

  test('AppFailure is sealed and exhaustively matchable without a default arm', () {
    // Compile-time proof: adding a new subtype breaks this switch.
    String label(AppFailure failure) => switch (failure) {
      InvalidCredentialsFailure() => 'invalidCredentials',
      NetworkFailure() => 'network',
      AccountInactiveFailure() => 'accountInactive',
      NoSessionFailure() => 'noSession',
      ServerFailure() => 'server',
      UnexpectedFailure() => 'unexpected',
    };
    expect(label(const InvalidCredentialsFailure()), 'invalidCredentials');
    expect(label(const AccountInactiveFailure()), 'accountInactive');
    expect(label(const NoSessionFailure()), 'noSession');
  });
}
