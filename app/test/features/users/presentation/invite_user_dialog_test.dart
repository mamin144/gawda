import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/users/presentation/widgets/invite_user_dialog.dart';
import 'package:gawda_app/features/users/presentation/widgets/site_multi_select.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';

import '../../../helpers/localized_app.dart';

typedef _InviteCall = ({String email, String fullName, UserRole role, List<String> siteIds});

void main() {
  final l10n = AppLocalizationsAr();

  const alpha = Site(id: 's1', code: 'ALPHA', name: 'North Tower', isActive: true);
  const gamma = Site(id: 's3', code: 'GAM-1', name: 'Gamma Tower', isActive: true);
  const sites = [alpha, gamma];

  /// Pumps a launcher button, opens the dialog and records submit calls.
  Future<List<_InviteCall>> openDialog(
    WidgetTester tester, {
    AppFailure? failure,
    List<Object?>? popped,
  }) async {
    final calls = <_InviteCall>[];
    await tester.pumpWidget(
      wrapLocalized(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showInviteUserDialog(
                  context,
                  sites: sites,
                  onSubmit:
                      ({
                        required String email,
                        required String fullName,
                        required UserRole role,
                        required List<String> siteIds,
                      }) async {
                        calls.add((
                          email: email,
                          fullName: fullName,
                          role: role,
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

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'new.user@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'مستخدم جديد');
  }

  testWidgets('shows the site selector for the default site user role', (tester) async {
    await openDialog(tester);
    expect(find.text(l10n.userInviteTitle), findsOneWidget);
    expect(find.byType(SiteMultiSelect), findsOneWidget);
    expect(find.text('North Tower'), findsOneWidget);
  });

  testWidgets('choosing the admin role hides and clears the site selector', (tester) async {
    final calls = await openDialog(tester);
    await tester.tap(find.text('Gamma Tower'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.userRoleAdmin));
    await tester.pumpAndSettle();
    expect(find.byType(SiteMultiSelect), findsNothing);

    await fillValid(tester);
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(calls.single.role, UserRole.admin);
    expect(calls.single.siteIds, isEmpty);
  });

  testWidgets('an invalid email shows invalidEmail and does not submit', (tester) async {
    final calls = await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'مستخدم جديد');
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.invalidEmail), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('an empty name shows fieldRequired and does not submit', (tester) async {
    final calls = await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'new.user@example.test');
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fieldRequired), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('user_exists shows the email taken message and keeps the dialog open', (
    tester,
  ) async {
    final popped = <Object?>[];
    await openDialog(tester, failure: const BusinessRuleFailure('user_exists'), popped: popped);
    await fillValid(tester);
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.userExists), findsOneWidget);
    expect(find.text(l10n.userInviteTitle), findsOneWidget);
    expect(popped, isEmpty);
  });

  testWidgets('invalid_sites shows inviteInvalidSites', (tester) async {
    await openDialog(tester, failure: const BusinessRuleFailure('invalid_sites'));
    await fillValid(tester);
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.inviteInvalidSites), findsOneWidget);
  });

  testWidgets('config_missing shows inviteNotConfigured', (tester) async {
    await openDialog(tester, failure: const ServerFailure(code: 'config_missing'));
    await fillValid(tester);
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(find.text(l10n.inviteNotConfigured), findsOneWidget);
  });

  testWidgets('success pops true and submits trimmed values with the chosen sites', (tester) async {
    final popped = <Object?>[];
    final calls = await openDialog(tester, popped: popped);
    await tester.enterText(find.byType(TextFormField).at(0), '  new.user@example.test ');
    await tester.enterText(find.byType(TextFormField).at(1), '  مستخدم جديد ');
    await tester.tap(find.text('North Tower'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await tester.pumpAndSettle();

    expect(popped, [true]);
    expect(calls.single.email, 'new.user@example.test');
    expect(calls.single.fullName, 'مستخدم جديد');
    expect(calls.single.role, UserRole.siteUser);
    expect(calls.single.siteIds, ['s1']);
  });
}
