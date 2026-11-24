import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/bloc/session_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late StreamController<AuthEvent> events;

  const user = AppUser(
    id: 'u1',
    fullName: 'مستخدم تجريبي (seed)',
    role: UserRole.siteUser,
    isActive: true,
  );

  setUp(() {
    repo = MockAuthRepository();
    events = StreamController<AuthEvent>.broadcast();
    when(() => repo.events).thenAnswer((_) => events.stream);
    when(() => repo.signOut()).thenAnswer((_) async => const Right(null));
  });

  tearDown(() => events.close());

  blocTest<SessionCubit, SessionState>(
    'bootstrap with a valid session emits authenticated',
    setUp: () => when(() => repo.restoreSession()).thenAnswer((_) async => const Right(user)),
    build: () => SessionCubit(repo),
    expect: () => const [SessionAuthenticated(user)],
  );

  blocTest<SessionCubit, SessionState>(
    'bootstrap without a session emits unauthenticated',
    setUp: () =>
        when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure())),
    build: () => SessionCubit(repo),
    expect: () => const [SessionUnauthenticated()],
  );

  blocTest<SessionCubit, SessionState>(
    'bootstrap with a deactivated account emits inactive',
    setUp: () => when(
      () => repo.restoreSession(),
    ).thenAnswer((_) async => const Left(AccountInactiveFailure())),
    build: () => SessionCubit(repo),
    expect: () => const [SessionInactive()],
  );

  blocTest<SessionCubit, SessionState>(
    'bootstrap with a server error falls back to unauthenticated',
    setUp: () => when(
      () => repo.restoreSession(),
    ).thenAnswer((_) async => const Left(ServerFailure(code: '500'))),
    build: () => SessionCubit(repo),
    expect: () => const [SessionUnauthenticated()],
  );

  blocTest<SessionCubit, SessionState>(
    'signedOut event emits unauthenticated',
    setUp: () =>
        when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure())),
    build: () => SessionCubit(repo),
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      events.add(AuthEvent.signedOut);
    },
    expect: () => const [SessionUnauthenticated()],
  );

  blocTest<SessionCubit, SessionState>(
    'signedIn event refetches the profile',
    setUp: () {
      var calls = 0;
      when(() => repo.restoreSession()).thenAnswer((_) async {
        calls++;
        return calls == 1 ? const Left(NoSessionFailure()) : const Right(user);
      });
    },
    build: () => SessionCubit(repo),
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      events.add(AuthEvent.signedIn);
    },
    expect: () => const [SessionUnauthenticated(), SessionAuthenticated(user)],
  );

  test('signOut delegates to the repository', () async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure()));
    final cubit = SessionCubit(repo);
    await cubit.signOut();
    verify(() => repo.signOut()).called(1);
    await cubit.close();
  });
}
