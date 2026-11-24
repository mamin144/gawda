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

    test('maps unclassified PostgrestException to ServerFailure preserving code and message', () {
      const error = PostgrestException(message: 'check violation', code: '23514');
      final failure = mapExceptionToFailure(error);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, '23514');
      expect(failure.message, 'check violation');
    });

    test('maps unique violation 23505 to DuplicateFailure', () {
      const error = PostgrestException(message: 'duplicate key value', code: '23505');
      expect(mapExceptionToFailure(error), isA<DuplicateFailure>());
    });

    test('maps permission denied 42501 to ForbiddenFailure', () {
      const error = PostgrestException(message: 'permission denied', code: '42501');
      expect(mapExceptionToFailure(error), isA<ForbiddenFailure>());
    });

    test('maps P0001 forbidden to ForbiddenFailure', () {
      const error = PostgrestException(message: 'forbidden', code: 'P0001');
      expect(mapExceptionToFailure(error), isA<ForbiddenFailure>());
    });

    for (final code in const [
      'cannot_change_self',
      'last_admin',
      'code_locked',
      'invalid_sites',
      'invalid_target',
      'archive_inconsistent',
      'user_exists',
    ]) {
      test('maps P0001 $code to BusinessRuleFailure($code)', () {
        final error = PostgrestException(message: code, code: 'P0001');
        expect(mapExceptionToFailure(error), BusinessRuleFailure(code));
      });
    }

    test('maps unknown P0001 message to ServerFailure preserving code and message', () {
      const error = PostgrestException(message: 'something_else', code: 'P0001');
      final failure = mapExceptionToFailure(error);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 'P0001');
      expect(failure.message, 'something_else');
    });

    test('maps Edge Function HTTP 403 to ForbiddenFailure', () {
      const error = FunctionException(status: 403, details: {'error': 'forbidden'});
      expect(mapExceptionToFailure(error), isA<ForbiddenFailure>());
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

  test('BusinessRuleFailure has value equality on its code', () {
    expect(const BusinessRuleFailure('last_admin'), BusinessRuleFailure('last_admin'.toString()));
    expect(
      const BusinessRuleFailure('last_admin') == const BusinessRuleFailure('code_locked'),
      isFalse,
    );
  });

  test('AppFailure is sealed and exhaustively matchable without a default arm', () {
    // Compile-time proof: adding a new subtype breaks this switch.
    String label(AppFailure failure) => switch (failure) {
      InvalidCredentialsFailure() => 'invalidCredentials',
      NetworkFailure() => 'network',
      AccountInactiveFailure() => 'accountInactive',
      NoSessionFailure() => 'noSession',
      ServerFailure() => 'server',
      DuplicateFailure() => 'duplicate',
      ForbiddenFailure() => 'forbidden',
      BusinessRuleFailure() => 'businessRule',
      UnexpectedFailure() => 'unexpected',
    };
    expect(label(const InvalidCredentialsFailure()), 'invalidCredentials');
    expect(label(const AccountInactiveFailure()), 'accountInactive');
    expect(label(const NoSessionFailure()), 'noSession');
    expect(label(const BusinessRuleFailure('last_admin')), 'businessRule');
  });
}
