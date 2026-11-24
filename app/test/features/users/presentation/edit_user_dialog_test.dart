import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/users/domain/entities/managed_user.dart';
import 'package:gawda_app/features/users/presentation/widgets/edit_user_dialog.dart';
import 'package:gawda_app/features/users/presentation/widgets/site_multi_select.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';

import '../../../helpers/localized_app.dart';

typedef _EditCall = ({String fullName, UserRole role, bool isActive, List<String> siteIds});

void main() {
  final l10n = AppLocalizationsAr();

  const alpha = Site(id: 's1', code: 'ALPHA', name: 'North Tower', isActive: true);
  const gamma = Site(id: 's3', code: 'GAM-1', name: 'Gamma Tower', isActive: true);
  const sites = [alpha, gamma];

  const siteUser = ManagedUser(
    id: 'u2',
    email: 'site.user@example.test',
    fullName: 'سامي الموقع',
    role: UserRole.siteUser,
    isActive: true,
    invitePending: false,
    siteIds: ['s1'],
  );

  const selfAdmin = ManagedUser(
    id: 'u1',
    email: 'admin@example.test',
    fullName: 'مدير النظام',
    role: UserRole.admin,
    isActive: true,
    invitePending: false,
    siteIds: [],
  );

  Future<List<_EditCall>> openDialog(
    WidgetTester tester, {
    ManagedUser initial = siteUser,
    bool isSelf = false,
    AppFailure? failure,
    List<Object?>? popped,
  }) async {
    final calls = <_EditCall>[];
    await tester.pumpWidget(
      wrapLocalized(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showEditUserDialog(
                  context,
                  initial: initial,
                  activeSites: sites,
                  isSelf: isSelf,
                  onSubmit:
                      ({
                        required String fullName,
                        required UserRole role,
                        required bool isActive,
                        required List<String> siteIds,
                      }) async {
                        calls.add((
                          fullName: fullName,
                          role: role,
                          isActive: isActive,
                          siteIds: siteIds,
                        ));
                        return failure;
                      },
                );
                popped?.add(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('prefills the name, role, active state and sites', (tester) async {
    await openDialog(tester);
    expect(find.text(l10n.userEditTitle), findsOneWidget);
    expect(find.text('سامي الموقع'), findsOneWidget);
    final radios = tester.widgetList<RadioListTile<UserRole>>(find.byType(RadioListTile<UserRole>));
    expect(radios.map((radio) => radio.value), containsAll([UserRole.admin, UserRole.siteUser]));
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byType(SiteMultiSelect), findsOneWidget);
  });

  testWidgets('the signed-in admin cannot change their own role or active state', (tester) async {
    await openDialog(tester, initial: selfAdmin, isSelf: true);

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.onChanged, isNull);
    for (final radio in tester.widgetList<RadioListTile<UserRole>>(
      find.byType(RadioListTile<UserRole>),
    )) {
      expect(radio.enabled, isFalse);
    }
    expect(find.text(l10n.userSelfEditHint), findsOneWidget);
  });

  testWidgets('an empty name shows fieldRequired and does not submit', (tester) async {
    final calls = await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fieldRequired), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('choosing the admin role hides and clears the site selector', (tester) async {
    final calls = await openDialog(tester);
    await tester.tap(find.text(l10n.userRoleAdmin));
    await tester.pumpAndSettle();
    expect(find.byType(SiteMultiSelect), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(calls.single.role, UserRole.admin);
    expect(calls.single.siteIds, isEmpty);
  });

  testWidgets('last_admin shows lastAdminError and keeps the dialog open', (tester) async {
    final popped = <Object?>[];
    await openDialog(
      tester,
      initial: selfAdmin,
      isSelf: true,
      failure: const BusinessRuleFailure('last_admin'),
      popped: popped,
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.lastAdminError), findsOneWidget);
    expect(find.text(l10n.userEditTitle), findsOneWidget);
    expect(popped, isEmpty);
  });

  testWidgets('success pops true and submits the edited values', (tester) async {
    final popped = <Object?>[];
    final calls = await openDialog(tester, popped: popped);
    await tester.enterText(find.byType(TextFormField), 'سامي الجديد');
    await tester.tap(find.text('Gamma Tower'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(popped, [true]);
    expect(calls.single.fullName, 'سامي الجديد');
    expect(calls.single.role, UserRole.siteUser);
    expect(calls.single.isActive, isFalse);
    expect(calls.single.siteIds, ['s1', 's3']);
  });
}
