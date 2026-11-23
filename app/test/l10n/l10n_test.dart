import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('Arabic locale forces RTL and exposes Arabic strings', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(Directionality.of(captured), TextDirection.rtl);
    final l10n = AppLocalizations.of(captured);
    expect(l10n.loginButton, 'دخول');
    expect(l10n.appTitle, 'نظام متابعة الجودة المالية للمواقع');
    expect(l10n.welcomeUser('أحمد'), 'مرحبًا، أحمد');
  });

  test('only Arabic is supported in P2', () {
    expect(AppLocalizations.supportedLocales, const [Locale('ar')]);
  });
}
