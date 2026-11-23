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
import 'package:gawda_app/features/home/presentation/pages/site_home_page.dart';
import 'package:gawda_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  const admin = AppUser(id: 'a', fullName: 'مدير (seed)', role: UserRole.admin, isActive: true);
  const site = AppUser(id: 's', fullName: 'موقع (seed)', role: UserRole.siteUser, isActive: true);

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.events).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async => const Right(null));
  });

  Widget buildApp(SessionCubit cubit, GoRouter router) => RepositoryProvider<AuthRepository>.value(
    value: repo,
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
    expect(find.byType(SiteHomePage), findsOneWidget);

    router.go('/admin');
    await tester.pumpAndSettle();

    expect(find.byType(SiteHomePage), findsOneWidget);
    expect(find.byType(AdminHomePage), findsNothing);
  });
}
