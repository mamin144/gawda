import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  const user = AppUser(
    id: 'u1',
    fullName: 'مستخدم تجريبي (seed)',
    role: UserRole.siteUser,
    isActive: true,
  );

  setUp(() {
    repo = MockAuthRepository();
  });

  blocTest<LoginCubit, LoginState>(
    'empty submit sets required errors and never calls the repository',
    build: () => LoginCubit(repo),
    act: (cubit) => cubit.submitted(),
    expect: () => [
      const LoginState(
        emailError: LoginFieldError.required,
        passwordError: LoginFieldError.required,
      ),
    ],
    verify: (_) => verifyNever(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );

  blocTest<LoginCubit, LoginState>(
    'email without @ is invalid',
    build: () => LoginCubit(repo),
    act: (cubit) async {
      cubit.emailChanged('not-an-email');
      cubit.passwordChanged('secret');
      await cubit.submitted();
    },
    expect: () => [
      const LoginState(email: 'not-an-email'),
      const LoginState(email: 'not-an-email', password: 'secret'),
      const LoginState(
        email: 'not-an-email',
        password: 'secret',
        emailError: LoginFieldError.invalidEmail,
      ),
    ],
    verify: (_) => verifyNever(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );

  blocTest<LoginCubit, LoginState>(
    'valid submit emits submitting then success and trims the email',
    setUp: () => when(
      () => repo.signIn(email: 'site1@example.test', password: 'secret'),
    ).thenAnswer((_) async => const Right(user)),
    build: () => LoginCubit(repo),
    act: (cubit) async {
      cubit.emailChanged('  site1@example.test  ');
      cubit.passwordChanged('secret');
      await cubit.submitted();
    },
    expect: () => [
      const LoginState(email: '  site1@example.test  '),
      const LoginState(email: '  site1@example.test  ', password: 'secret'),
      const LoginState(
        email: 'site1@example.test',
        password: 'secret',
        status: LoginStatus.submitting,
      ),
      const LoginState(
        email: 'site1@example.test',
        password: 'secret',
        status: LoginStatus.success,
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'repository failure emits submitting then failure preserving the failure',
    setUp: () => when(
      () => repo.signIn(email: 'site1@example.test', password: 'secret'),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    build: () => LoginCubit(repo),
    act: (cubit) async {
      cubit.emailChanged('site1@example.test');
      cubit.passwordChanged('secret');
      await cubit.submitted();
    },
    expect: () => [
      const LoginState(email: 'site1@example.test'),
      const LoginState(email: 'site1@example.test', password: 'secret'),
      const LoginState(
        email: 'site1@example.test',
        password: 'secret',
        status: LoginStatus.submitting,
      ),
      const LoginState(
        email: 'site1@example.test',
        password: 'secret',
        status: LoginStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'changing the email clears its error',
    build: () => LoginCubit(repo),
    act: (cubit) async {
      await cubit.submitted();
      cubit.emailChanged('a@b.c');
    },
    expect: () => [
      const LoginState(
        emailError: LoginFieldError.required,
        passwordError: LoginFieldError.required,
      ),
      const LoginState(email: 'a@b.c', passwordError: LoginFieldError.required),
    ],
  );
}
