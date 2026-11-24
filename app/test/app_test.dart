import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/app.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/pages/login_page.dart';
import 'package:gawda_app/features/home/presentation/pages/admin_home_page.dart';
import 'package:gawda_app/features/admin/presentation/admin_shell.dart';
import 'package:gawda_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/features/users/domain/repositories/users_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

class MockCertificatesRepository extends Mock implements CertificatesRepository {}

class MockUsersRepository extends Mock implements UsersRepository {}

void main() {
  late MockAuthRepository repo;
  final sitesRepo = MockSitesRepository();
  final usersRepo = MockUsersRepository();
  final certsRepo = MockCertificatesRepository();

  App buildApp() => App(repo: repo, sitesRepo: sitesRepo, usersRepo: usersRepo, certsRepo: certsRepo);

  const admin = AppUser(id: 'a', fullName: 'مدير (seed)', role: UserRole.admin, isActive: true);

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.events).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async => const Right(null));
  });

  testWidgets('App boots to the Arabic RTL login when no session exists', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure()));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LoginPage))),
      TextDirection.rtl,
    );
  });

  testWidgets('App boots to the admin home when an admin session is restored', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(admin));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomePage), findsOneWidget);
  });

  testWidgets('App provides the sites and users repositories to the admin shell', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(admin));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final shell = tester.element(find.byType(AdminShell));
    expect(shell.read<SitesRepository>(), same(sitesRepo));
    expect(shell.read<UsersRepository>(), same(usersRepo));
  });

  testWidgets('ConfigErrorApp shows the Arabic configuration error', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pumpAndSettle();

    expect(find.text('إعدادات التطبيق غير مكتملة. تواصل مع المسؤول'), findsOneWidget);
  });
}
