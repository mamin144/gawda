import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/widgets/empty_view.dart';
import 'package:gawda_app/core/widgets/error_view.dart';
import 'package:gawda_app/core/widgets/loading_view.dart';

import '../../helpers/localized_app.dart';

void main() {
  testWidgets('LoadingView shows a progress indicator and optional message', (tester) async {
    await tester.pumpWidget(wrapLocalized(const LoadingView(message: 'جارٍ التحميل...')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('جارٍ التحميل...'), findsOneWidget);
  });

  testWidgets('EmptyView shows the given message', (tester) async {
    await tester.pumpWidget(wrapLocalized(const EmptyView(message: 'لا توجد بيانات')));
    expect(find.text('لا توجد بيانات'), findsOneWidget);
  });

  testWidgets('ErrorView shows the message and invokes retry exactly once', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrapLocalized(ErrorView(message: 'حدث خطأ', onRetry: () => calls++)),
    );
    expect(find.text('حدث خطأ'), findsOneWidget);
    final retry = find.text('إعادة المحاولة');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    expect(calls, 1);
  });

  testWidgets('ErrorView without onRetry renders no retry button', (tester) async {
    await tester.pumpWidget(wrapLocalized(const ErrorView(message: 'حدث خطأ')));
    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('retry button meets the 48dp touch target', (tester) async {
    await tester.pumpWidget(wrapLocalized(ErrorView(message: 'x', onRetry: () {})));
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
