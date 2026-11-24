import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/theme/app_status_colors.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/features/sites/presentation/pages/sites_page.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/localized_app.dart';

class MockSitesRepository extends Mock implements SitesRepository {}

void main() {
  final l10n = AppLocalizationsAr();
  late MockSitesRepository repo;

  const alpha = Site(id: 's1', code: 'ALPHA', name: 'North Tower', isActive: true);
  final beta = Site(
    id: 's2',
    code: 'BETA',
    name: 'Old Depot',
    isActive: false,
    archivedAt: DateTime.utc(2026, 11, 1),
  );

  setUp(() {
    repo = MockSitesRepository();
    when(() => repo.list()).thenAnswer((_) async => Right([alpha, beta]));
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapLocalized(
        RepositoryProvider<SitesRepository>.value(
          value: repo,
          child: const Scaffold(body: SitesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows active sites by default with a green active chip', (tester) async {
    await pumpPage(tester);
    expect(find.text('North Tower'), findsOneWidget);
    expect(find.text('ALPHA'), findsOneWidget);
    expect(find.text('Old Depot'), findsNothing);
    final colors = AppStatusColors.light();
    final chip = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text(l10n.siteActive), matching: find.byType(DecoratedBox)).first,
    );
    expect((chip.decoration as BoxDecoration).color, colors.approvedContainer);
  });

  testWidgets('archived row shows the grey chip text siteArchived', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text(l10n.sitesFilterArchived));
    await tester.pumpAndSettle();
    expect(find.text('Old Depot'), findsOneWidget);
    expect(find.text('North Tower'), findsNothing);
    final chip = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text(l10n.siteArchived), matching: find.byType(DecoratedBox)).first,
    );
    expect((chip.decoration as BoxDecoration).color, AppStatusColors.light().archivedContainer);
  });

  testWidgets('search filters by code or name', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text(l10n.sitesFilterAll));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'depot');
    await tester.pumpAndSettle();
    expect(find.text('Old Depot'), findsOneWidget);
    expect(find.text('North Tower'), findsNothing);
  });

  testWidgets('empty search result shows the search empty message', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(l10n.sitesEmptySearch), findsOneWidget);
  });

  testWidgets('archive asks confirmation then calls setArchived(id, archived: true)', (
    tester,
  ) async {
    when(
      () => repo.setArchived('s1', archived: true),
    ).thenAnswer((_) async => Right(alpha.copyWith(isActive: false)));
    await pumpPage(tester);

    await tester.tap(find.byTooltip(l10n.siteActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.siteArchive));
    await tester.pumpAndSettle();

    expect(find.text(l10n.siteArchiveConfirmTitle), findsOneWidget);
    verifyNever(() => repo.setArchived(any(), archived: any(named: 'archived')));

    await tester.tap(find.widgetWithText(FilledButton, l10n.siteArchive));
    await tester.pumpAndSettle();
    verify(() => repo.setArchived('s1', archived: true)).called(1);
  });

  testWidgets('cancelling the archive confirmation does nothing', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byTooltip(l10n.siteActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.siteArchive));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    verifyNever(() => repo.setArchived(any(), archived: any(named: 'archived')));
  });

  testWidgets('restore on an archived row calls setArchived(id, archived: false)', (tester) async {
    when(() => repo.setArchived('s2', archived: false)).thenAnswer((_) async => Right(beta));
    await pumpPage(tester);
    await tester.tap(find.text(l10n.sitesFilterArchived));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.siteActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.siteRestore));
    await tester.pumpAndSettle();
    verify(() => repo.setArchived('s2', archived: false)).called(1);
  });

  testWidgets('a failed archive shows the failure message in a snackbar', (tester) async {
    when(
      () => repo.setArchived('s1', archived: true),
    ).thenAnswer((_) async => const Left(ForbiddenFailure()));
    await pumpPage(tester);
    await tester.tap(find.byTooltip(l10n.siteActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.siteArchive));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.siteArchive));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorForbidden), findsOneWidget);
    expect(find.text('North Tower'), findsOneWidget);
  });

  testWidgets('add button is at least 48dp and opens the form dialog', (tester) async {
    await pumpPage(tester);
    final fab = find.byTooltip(l10n.siteAdd);
    final size = tester.getSize(fab);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.text(l10n.siteAddTitle), findsOneWidget);
  });

  testWidgets('load failure shows an error with retry', (tester) async {
    when(() => repo.list()).thenAnswer((_) async => const Left(NetworkFailure()));
    await pumpPage(tester);
    expect(find.text(l10n.errorNetwork), findsOneWidget);
    when(() => repo.list()).thenAnswer((_) async => Right([alpha]));
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text('North Tower'), findsOneWidget);
  });
}
