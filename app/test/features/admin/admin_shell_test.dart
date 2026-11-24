import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/theme/app_theme.dart';
import 'package:gawda_app/features/admin/presentation/admin_shell.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/bloc/session_cubit.dart';
import 'package:gawda_app/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late SessionCubit cubit;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.events).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async => const Right(null));
    when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure()));
    cubit = SessionCubit(repo);
  });

  tearDown(() => cubit.close());

  /// Shell under test with plain body widgets, so only the shell is exercised.
  GoRouter buildShellRouter({String initial = '/admin'}) => GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const SizedBox(key: Key('overview')),
          ),
          GoRoute(
            path: '/admin/sites',
            builder: (context, state) => const SizedBox(key: Key('sites')),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const SizedBox(key: Key('users')),
          ),
        ],
      ),
    ],
  );

  Future<GoRouter> pumpShell(WidgetTester tester, Size size, {String initial = '/admin'}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = buildShellRouter(initial: initial);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<SessionCubit>.value(
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
    await tester.pumpAndSettle();
    return router;
  }

  String currentPath(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

  group('wide layout (1280x800)', () {
    testWidgets('shows an extended NavigationRail with 3 destinations, no drawer', (tester) async {
      await pumpShell(tester, const Size(1280, 800));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(3));
      expect(rail.extended, isTrue);
      expect(rail.selectedIndex, 0);
      expect(find.byKey(const Key('overview')), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(Directionality.of(tester.element(find.byType(NavigationRail))), TextDirection.rtl);
    });

    testWidgets('tapping المواقع navigates to /admin/sites and selects it', (tester) async {
      final router = await pumpShell(tester, const Size(1280, 800));

      await tester.tap(
        find.descendant(of: find.byType(NavigationRail), matching: find.text('المواقع')),
      );
      await tester.pumpAndSettle();

      expect(currentPath(router), '/admin/sites');
      expect(find.byKey(const Key('sites')), findsOneWidget);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, 1);
    });

    testWidgets('deep link to /admin/users selects the users destination', (tester) async {
      await pumpShell(tester, const Size(1280, 800), initial: '/admin/users');

      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, 2);
    });
  });

  testWidgets('medium width (900) shows a collapsed rail with labels', (tester) async {
    await pumpShell(tester, const Size(900, 800));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
  });

  group('compact layout (400x800)', () {
    testWidgets('no rail; the drawer button opens 3 entries', (tester) async {
      await pumpShell(tester, const Size(400, 800));

      expect(find.byType(NavigationRail), findsNothing);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDrawerDestination), findsNWidgets(3));
    });

    testWidgets('tapping المواقع in the drawer navigates and closes it', (tester) async {
      final router = await pumpShell(tester, const Size(400, 800));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(NavigationDrawer), matching: find.text('المواقع')),
      );
      await tester.pumpAndSettle();

      expect(currentPath(router), '/admin/sites');
      expect(find.byKey(const Key('sites')), findsOneWidget);
      expect(find.byType(NavigationDrawer), findsNothing);
    });
  });

  testWidgets('the app bar logout action signs out', (tester) async {
    await pumpShell(tester, const Size(1280, 800));

    await tester.tap(find.byTooltip('تسجيل الخروج'));
    await tester.pumpAndSettle();

    verify(() => repo.signOut()).called(1);
  });

  testWidgets('navigation targets are at least 48dp', (tester) async {
    await pumpShell(tester, const Size(400, 800));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
