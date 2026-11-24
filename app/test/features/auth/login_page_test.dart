import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/error/result.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/bloc/login_cubit.dart';
import 'package:gawda_app/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/localized_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.events).thenAnswer((_) => const Stream.empty());
  });

  Widget buildPage() => wrapLocalized(
    BlocProvider(create: (_) => LoginCubit(repo), child: const LoginPage()),
  );

  testWidgets('renders Arabic labels and RTL direction', (tester) async {
    await tester.pumpWidget(buildPage());
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(LoginPage))), TextDirection.rtl);
  });

  testWidgets('empty submit shows Arabic required errors under both fields', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.tap(find.text('دخول'));
    await tester.pump();
    expect(find.text('هذا الحقل مطلوب'), findsNWidgets(2));
    verifyNever(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('invalid credentials show the Arabic error banner', (tester) async {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

    await tester.pumpWidget(buildPage());
    await tester.enterText(find.byType(TextField).at(0), 'site1@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('دخول'));
    await tester.pump();
    await tester.pump();

    expect(find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة'), findsOneWidget);
  });

  testWidgets('submitting disables the button and shows a spinner', (tester) async {
    final completer = Completer<Result<AppUser>>();
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildPage());
    await tester.enterText(find.byType(TextField).at(0), 'site1@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('دخول'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const Left(NetworkFailure()));
    await tester.pump();
  });
}
