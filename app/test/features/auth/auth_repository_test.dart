import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gawda_app/features/auth/data/services/auth_service.dart';
import 'package:gawda_app/features/auth/data/services/profile_service.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

class MockProfileService extends Mock implements ProfileService {}

void main() {
  late MockAuthService auth;
  late MockProfileService profiles;
  late AuthRepositoryImpl repo;

  const activeRow = {
    'id': 'u1',
    'full_name': 'مستخدم تجريبي (seed)',
    'role': 'site_user',
    'is_active': true,
  };

  setUp(() {
    auth = MockAuthService();
    profiles = MockProfileService();
    repo = AuthRepositoryImpl(auth, profiles);
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  void stubSignedInFetch(Map<String, dynamic> row) {
    when(() => auth.currentUserId).thenReturn('u1');
    when(() => profiles.fetchProfile('u1')).thenAnswer((_) async => row);
  }

  group('signIn', () {
    test('returns the domain user on success', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      stubSignedInFetch(activeRow);

      final result = await repo.signIn(email: 'site1@example.test', password: 'x');

      expect(result.isRight(), isTrue);
      final user = result.getOrElse((l) => throw StateError('expected Right'));
      expect(user.id, 'u1');
      expect(user.role, UserRole.siteUser);
      verifyNever(() => auth.signOut());
    });

    test('maps invalid credentials to InvalidCredentialsFailure', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials', code: 'invalid_credentials'));

      final result = await repo.signIn(email: 'site1@example.test', password: 'wrong');

      expect(result.isLeft(), isTrue);
      expect(result.match((l) => l, (r) => null), isA<InvalidCredentialsFailure>());
    });

    test('signs out and returns AccountInactiveFailure for a deactivated account', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      stubSignedInFetch(Map<String, dynamic>.from(activeRow)..['is_active'] = false);

      final result = await repo.signIn(email: 'site1@example.test', password: 'x');

      expect(result.match((l) => l, (r) => null), isA<AccountInactiveFailure>());
      verify(() => auth.signOut()).called(1);
    });

    test('maps network errors to NetworkFailure', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const SocketException('offline'));

      final result = await repo.signIn(email: 'site1@example.test', password: 'x');

      expect(result.match((l) => l, (r) => null), isA<NetworkFailure>());
    });
  });

  group('restoreSession', () {
    test('returns NoSessionFailure when nothing is persisted', () async {
      when(() => auth.hasSession).thenReturn(false);

      final result = await repo.restoreSession();

      expect(result.match((l) => l, (r) => null), isA<NoSessionFailure>());
      verifyNever(() => profiles.fetchProfile(any()));
    });

    test('restores the user when the session and profile exist', () async {
      when(() => auth.hasSession).thenReturn(true);
      stubSignedInFetch(activeRow);

      final result = await repo.restoreSession();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((l) => throw StateError('expected Right')).id, 'u1');
    });

    test('signs out and fails closed when the profile row is missing', () async {
      when(() => auth.hasSession).thenReturn(true);
      when(() => auth.currentUserId).thenReturn('u1');
      when(() => profiles.fetchProfile('u1')).thenThrow(
        const PostgrestException(message: 'no rows', code: 'PGRST116'),
      );

      final result = await repo.restoreSession();

      expect(result.match((l) => l, (r) => null), isA<ServerFailure>());
      verify(() => auth.signOut()).called(1);
    });

    test('signs out a deactivated account on restore', () async {
      when(() => auth.hasSession).thenReturn(true);
      stubSignedInFetch(Map<String, dynamic>.from(activeRow)..['is_active'] = false);

      final result = await repo.restoreSession();

      expect(result.match((l) => l, (r) => null), isA<AccountInactiveFailure>());
      verify(() => auth.signOut()).called(1);
    });

    test('keeps the session on a network error (no sign-out)', () async {
      when(() => auth.hasSession).thenReturn(true);
      when(() => auth.currentUserId).thenReturn('u1');
      when(() => profiles.fetchProfile('u1')).thenThrow(const SocketException('offline'));

      final result = await repo.restoreSession();

      expect(result.match((l) => l, (r) => null), isA<NetworkFailure>());
      verifyNever(() => auth.signOut());
    });
  });

  group('signOut', () {
    test('returns Right on success', () async {
      final result = await repo.signOut();
      expect(result.isRight(), isTrue);
      verify(() => auth.signOut()).called(1);
    });

    test('maps failures instead of throwing', () async {
      when(() => auth.signOut()).thenThrow(const SocketException('offline'));
      final result = await repo.signOut();
      expect(result.match((l) => l, (r) => null), isA<NetworkFailure>());
    });
  });

  test('events passes the service stream through unchanged', () async {
    final controller = StreamController<AuthEvent>();
    when(() => auth.events).thenAnswer((_) => controller.stream);

    final expectation = expectLater(
      repo.events,
      emitsInOrder([AuthEvent.signedIn, AuthEvent.signedOut]),
    );
    controller.add(AuthEvent.signedIn);
    controller.add(AuthEvent.signedOut);
    await controller.close();
    await expectation;
  });
}
