import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/theme/app_status_colors.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/bloc/session_cubit.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/features/users/domain/entities/managed_user.dart';
import 'package:gawda_app/features/users/domain/repositories/users_repository.dart';
import 'package:gawda_app/features/users/presentation/pages/users_page.dart';
import 'package:gawda_app/features/users/presentation/widgets/site_multi_select.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/localized_app.dart';

class MockUsersRepository extends Mock implements UsersRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  final l10n = AppLocalizationsAr();

  const admin = AppUser(
    id: 'u1',
    fullName: 'مدير النظام',
    role: UserRole.admin,
    isActive: true,
  );

  const alpha = Site(id: 's1', code: 'ALPHA', name: 'برج الشمال', isActive: true);
  final beta = Site(
    id: 's2',
    code: 'BETA',
    name: 'Old Depot',
    isActive: false,
    archivedAt: DateTime.utc(2026, 11, 1),
  );
  const gamma = Site(id: 's3', code: 'GAM-1', name: 'Gamma Tower', isActive: true);

  const adminUser = ManagedUser(
    id: 'u1',
    email: 'admin@example.test',
    fullName: 'مدير النظام',
    role: UserRole.admin,
    isActive: true,
    invitePending: false,
    siteIds: [],
  );
  const siteUser = ManagedUser(
    id: 'u2',
    email: 'site.user@example.test',
    fullName: 'سامي الموقع',
    role: UserRole.siteUser,
    isActive: true,
    invitePending: false,
    siteIds: ['s1'],
  );
  const pendingUser = ManagedUser(
    id: 'u3',
    email: 'pending@example.test',
    fullName: 'دعوة جديدة',
    role: UserRole.siteUser,
    isActive: true,
    invitePending: true,
    siteIds: [],
  );
  const inactiveUser = ManagedUser(
    id: 'u4',
    email: 'gone@example.test',
    fullName: 'حساب موقوف',
    role: UserRole.siteUser,
    isActive: false,
    invitePending: false,
    siteIds: [],
  );
  const users = [adminUser, siteUser, pendingUser, inactiveUser];

  late MockUsersRepository usersRepo;
  late MockSitesRepository sitesRepo;
  late MockAuthRepository authRepo;

  setUp(() {
    usersRepo = MockUsersRepository();
    sitesRepo = MockSitesRepository();
    authRepo = MockAuthRepository();
    when(() => usersRepo.list()).thenAnswer((_) async => const Right(users));
    when(() => sitesRepo.list()).thenAnswer((_) async => Right([alpha, beta, gamma]));
    when(() => authRepo.events).thenAnswer((_) => const Stream.empty());
    when(() => authRepo.signOut()).thenAnswer((_) async => const Right(null));
    when(() => authRepo.restoreSession()).thenAnswer((_) async => const Right(admin));
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final session = SessionCubit(authRepo);
    addTearDown(session.close);
    await tester.pumpWidget(
      wrapLocalized(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<UsersRepository>.value(value: usersRepo),
            RepositoryProvider<SitesRepository>.value(value: sitesRepo),
          ],
          child: BlocProvider<SessionCubit>.value(
            value: session,
            child: const Scaffold(body: UsersPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows name, email, role and site count with a green active chip', (tester) async {
    await pumpPage(tester);

    expect(find.text('مدير النظام'), findsOneWidget);
    expect(find.text('admin@example.test'), findsOneWidget);
    expect(find.text(l10n.userRoleAdmin), findsOneWidget);
    expect(find.text(l10n.userRoleSiteUser), findsNWidgets(3));
    expect(find.text(l10n.userSiteCount(1)), findsOneWidget);

    final chip = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text(l10n.userActive), matching: find.byType(DecoratedBox)).first,
    );
    expect((chip.decoration as BoxDecoration).color, AppStatusColors.light().approvedContainer);
  });

  testWidgets('an invite pending row shows the yellow pending chip', (tester) async {
    await pumpPage(tester);
    final chip = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text(l10n.userInvitePending), matching: find.byType(DecoratedBox))
          .first,
    );
    expect((chip.decoration as BoxDecoration).color, AppStatusColors.light().needsReviewContainer);
  });

  testWidgets('an inactive row shows the grey inactive chip', (tester) async {
    await pumpPage(tester);
    final chip = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text(l10n.userInactive), matching: find.byType(DecoratedBox)).first,
    );
    expect((chip.decoration as BoxDecoration).color, AppStatusColors.light().archivedContainer);
  });

  testWidgets('search filters by name or email', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'gone@example');
    await tester.pumpAndSettle();
    expect(find.text('حساب موقوف'), findsOneWidget);
    expect(find.text('مدير النظام'), findsNothing);

    await tester.enterText(find.byType(TextField), 'سامي');
    await tester.pumpAndSettle();
    expect(find.text('سامي الموقع'), findsOneWidget);
    expect(find.text('حساب موقوف'), findsNothing);
  });

  testWidgets('an empty search result shows the search empty message', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(l10n.usersEmptySearch), findsOneWidget);
  });

  testWidgets('the invite button is at least 48dp and opens the invite dialog', (tester) async {
    await pumpPage(tester);
    final fab = find.byTooltip(l10n.userInvite);
    final size = tester.getSize(fab);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.text(l10n.userInviteTitle), findsOneWidget);
  });

  testWidgets("the signed-in admin's own row disables role and active controls", (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('مدير النظام'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.userEditTitle), findsOneWidget);
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.onChanged, isNull);
    for (final radio in tester.widgetList<RadioListTile<UserRole>>(
      find.byType(RadioListTile<UserRole>),
    )) {
      expect(radio.enabled, isFalse);
    }
  });

  testWidgets('saving a site user update calls update then setSites when sites changed', (
    tester,
  ) async {
    when(
      () => usersRepo.update('u2', fullName: 'سامي الجديد', role: UserRole.siteUser, isActive: true),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => usersRepo.setSites('u2', const ['s1', 's3']),
    ).thenAnswer((_) async => const Right(null));

    await pumpPage(tester);
    await tester.tap(find.text('سامي الموقع'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'سامي الجديد');
    await tester.tap(find.text('Gamma Tower'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    verifyInOrder([
      () => usersRepo.update(
        'u2',
        fullName: 'سامي الجديد',
        role: UserRole.siteUser,
        isActive: true,
      ),
      () => usersRepo.setSites('u2', const ['s1', 's3']),
    ]);
  });

  testWidgets('promoting a site user to admin clears the sites before updating', (tester) async {
    when(
      () => usersRepo.setSites('u2', const <String>[]),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => usersRepo.update('u2', fullName: 'سامي الموقع', role: UserRole.admin, isActive: true),
    ).thenAnswer((_) async => const Right(null));

    await pumpPage(tester);
    await tester.tap(find.text('سامي الموقع'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.userRoleAdmin),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SiteMultiSelect), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    verifyInOrder([
      () => usersRepo.setSites('u2', const <String>[]),
      () => usersRepo.update(
        'u2',
        fullName: 'سامي الموقع',
        role: UserRole.admin,
        isActive: true,
      ),
    ]);
    verifyNever(() => usersRepo.setSites('u2', const ['s1']));
  });

  testWidgets('load failure shows an error with retry', (tester) async {
    when(() => usersRepo.list()).thenAnswer((_) async => const Left(NetworkFailure()));
    await pumpPage(tester);
    expect(find.text(l10n.errorNetwork), findsOneWidget);

    when(() => usersRepo.list()).thenAnswer((_) async => const Right(users));
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text('مدير النظام'), findsOneWidget);
  });
}
