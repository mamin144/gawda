import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/app.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gawda_app/features/auth/presentation/pages/login_page.dart';
import 'package:gawda_app/features/home/presentation/pages/admin_home_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  const admin = AppUser(id: 'a', fullName: 'مدير (seed)', role: UserRole.admin, isActive: true);

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.events).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async => const Right(null));
  });

  testWidgets('App boots to the Arabic RTL login when no session exists', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Left(NoSessionFailure()));

    await tester.pumpWidget(App(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LoginPage))),
      TextDirection.rtl,
    );
  });

  testWidgets('App boots to the admin home when an admin session is restored', (tester) async {
    when(() => repo.restoreSession()).thenAnswer((_) async => const Right(admin));

    await tester.pumpWidget(App(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomePage), findsOneWidget);
  });

  testWidgets('ConfigErrorApp shows the Arabic configuration error', (tester) async {
    await tester.pumpWidget(const ConfigErrorApp());
    await tester.pumpAndSettle();

    expect(find.text('إعدادات التطبيق غير مكتملة. تواصل مع المسؤول'), findsOneWidget);
  });
}
