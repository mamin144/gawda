import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/router/app_router.dart';
import 'package:gawda_app/core/theme/app_theme.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/bloc/session_cubit.dart';
import 'package:gawda_app/features/auth/presentation/pages/login_page.dart';
import 'package:gawda_app/features/home/presentation/pages/admin_home_page.dart';
import 'package:gawda_app/features/admin/presentation/admin_shell.dart';
import 'package:gawda_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/features/certificates/presentation/pages/certificate_entry_page.dart';
import 'package:gawda_app/features/sites/presentation/pages/sites_page.dart';
import 'package:gawda_app/features/users/domain/entities/managed_user.dart';
import 'package:gawda_app/features/users/domain/repositories/users_repository.dart';
import 'package:gawda_app/features/users/presentation/pages/users_page.dart';
import 'package:gawda_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

class MockCertificatesRepository extends Mock implements CertificatesRepository {}

class MockUsersRepository extends Mock implements UsersRepository {}

void main() {
  late MockAuthRepository repo;
  late MockSitesRepository sitesRepo;
  late MockCertificatesRepository certsRepo;
  late MockUsersRepository usersRepo;

  const admin = AppUser(id: 'a', fullName: 'مدير (seed)', role: UserRole.admin, isActive: true);
  const site = AppUser(id: 's', fullName: 'موقع (seed)', role: UserRole.siteUser, isActive: true);

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.events).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async => const Right(null));
    sitesRepo = MockSitesRepository();
    when(() => sitesRepo.list()).thenAnswer((_) async => const Right(<Site>[]));
    certsRepo = MockCertificatesRepository();
    usersRepo = MockUsersRepository();
    when(() => usersRepo.list()).thenAnswer((_) async => const Right(<ManagedUser>[]));
  });

  Widget buildApp(SessionCubit cubit, GoRouter router) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: repo),
      RepositoryProvider<SitesRepository>.value(value: sitesRepo),
      RepositoryProvider<CertificatesRepository>.value(value: certsRepo),
      RepositoryProvider<UsersRepository>.value(value: usersRepo),
    ],
    child: BlocProvider<SessionCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );

  testWidgets('cold start without a session lands on the login page', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure()));
    final cubit = SessionCubit(repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(buildApp(cubit, buildRouter(cubit)));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('restored admin session lands on the admin home', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(admin));
    final cubit = SessionCubit(repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(buildApp(cubit, buildRouter(cubit)));
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomePage), findsOneWidget);
    expect(find.text('مرحبًا، مدير (seed)'), findsOneWidget);
  });

  testWidgets('site user navigating to /admin is redirected back to /site', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(site));
    final cubit = SessionCubit(repo);
    addTearDown(cubit.close);
    final router = buildRouter(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(cubit, router));
    await tester.pumpAndSettle();
    expect(find.byType(CertificateEntryPage), findsOneWidget);

    router.go('/admin');
    await tester.pumpAndSettle();

    expect(find.byType(CertificateEntryPage), findsOneWidget);
    expect(find.byType(AdminHomePage), findsNothing);
  });

  testWidgets('admin deep link to /admin/users renders the users page inside the shell', (
    tester,
  ) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(admin));
    final cubit = SessionCubit(repo);
    addTearDown(cubit.close);
    final router = buildRouter(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(cubit, router));
    await tester.pumpAndSettle();
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(AdminHomePage), findsOneWidget);

    router.go('/admin/users');
    await tester.pumpAndSettle();

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(UsersPage), findsOneWidget);
  });

  testWidgets('admin can open /admin/sites inside the shell', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(admin));
    final cubit = SessionCubit(repo);
    addTearDown(cubit.close);
    final router = buildRouter(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(cubit, router));
    await tester.pumpAndSettle();
    router.go('/admin/sites');
    await tester.pumpAndSettle();

    expect(find.byType(SitesPage), findsOneWidget);
  });

  testWidgets('site user deep-linking /admin/sites is redirected back to /site', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(site));
    final cubit = SessionCubit(repo);
    addTearDown(cubit.close);
    final router = buildRouter(cubit);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildApp(cubit, router));
    await tester.pumpAndSettle();
    router.go('/admin/sites');
    await tester.pumpAndSettle();

    expect(find.byType(CertificateEntryPage), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
  });
}
