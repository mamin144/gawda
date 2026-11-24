import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/presentation/widgets/site_form_dialog.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';

import '../../../helpers/localized_app.dart';

void main() {
  final l10n = AppLocalizationsAr();

  /// Pumps a launcher button, opens the dialog and returns the submit calls.
  Future<List<(String, String)>> openDialog(
    WidgetTester tester, {
    Site? initial,
    AppFailure? failure,
    List<Object?>? popped,
  }) async {
    final calls = <(String, String)>[];
    await tester.pumpWidget(
      wrapLocalized(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showSiteFormDialog(
                  context,
                  initial: initial,
                  onSubmit: (code, name) async {
                    calls.add((code, name));
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

  Finder codeField() => find.widgetWithText(TextFormField, l10n.siteCodeLabel);
  Finder nameField() => find.widgetWithText(TextFormField, l10n.siteNameLabel);

  testWidgets('empty code shows fieldRequired and does not submit', (tester) async {
    final calls = await openDialog(tester);
    await tester.enterText(nameField(), 'Site name');
    await tester.tap(find.text(l10n.save));
    await tester.pump();
    expect(find.text(l10n.fieldRequired), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('whitespace-only name counts as empty', (tester) async {
    final calls = await openDialog(tester);
    await tester.enterText(codeField(), 'A1');
    await tester.enterText(nameField(), '   ');
    await tester.tap(find.text(l10n.save));
    await tester.pump();
    expect(find.text(l10n.fieldRequired), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('code and name inputs are limited to 20 and 120 characters', (tester) async {
    await openDialog(tester);
    final code = tester.widget<TextField>(
      find.descendant(of: codeField(), matching: find.byType(TextField)),
    );
    final name = tester.widget<TextField>(
      find.descendant(of: nameField(), matching: find.byType(TextField)),
    );
    expect(code.maxLength, 20);
    expect(name.maxLength, 120);
  });

  testWidgets('submits trimmed values and closes on success', (tester) async {
    final popped = <Object?>[];
    final calls = await openDialog(tester, popped: popped);
    await tester.enterText(codeField(), '  A1 ');
    await tester.enterText(nameField(), ' North Tower  ');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(calls, [('A1', 'North Tower')]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(popped, [true]);
  });

  testWidgets('duplicate shows siteCodeDuplicate under the code field and stays open', (
    tester,
  ) async {
    await openDialog(tester, failure: const DuplicateFailure());
    await tester.enterText(codeField(), 'A1');
    await tester.enterText(nameField(), 'North');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(of: codeField(), matching: find.text(l10n.siteCodeDuplicate)),
      findsOneWidget,
    );
  });

  testWidgets('code_locked shows siteCodeLocked under the code field', (tester) async {
    const site = Site(id: 's1', code: 'A1', name: 'North', isActive: true);
    await openDialog(tester, initial: site, failure: const BusinessRuleFailure('code_locked'));
    expect(find.text(l10n.siteEditTitle), findsOneWidget);
    await tester.enterText(codeField(), 'A2');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: codeField(), matching: find.text(l10n.siteCodeLocked)),
      findsOneWidget,
    );
  });

  testWidgets('other failures show a general message in the dialog', (tester) async {
    await openDialog(tester, failure: const ForbiddenFailure());
    await tester.enterText(codeField(), 'A1');
    await tester.enterText(nameField(), 'North');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l10n.errorForbidden), findsOneWidget);
  });

  testWidgets('editing the code clears its server error', (tester) async {
    await openDialog(tester, failure: const DuplicateFailure());
    await tester.enterText(codeField(), 'A1');
    await tester.enterText(nameField(), 'North');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    await tester.enterText(codeField(), 'A3');
    await tester.pump();
    expect(find.text(l10n.siteCodeDuplicate), findsNothing);
  });

  testWidgets('edit mode pre-fills the fields', (tester) async {
    const site = Site(id: 's1', code: 'A1', name: 'North', isActive: true);
    await openDialog(tester, initial: site);
    expect(find.widgetWithText(TextFormField, 'A1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'North'), findsOneWidget);
  });
}
