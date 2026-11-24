import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/features/certificates/domain/certificate_files.dart';
import 'package:gawda_app/features/certificates/domain/entities/certificate.dart';
import 'package:gawda_app/features/certificates/domain/entities/certificate_status.dart';
import 'package:gawda_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:gawda_app/features/certificates/presentation/bloc/certificate_cubit.dart';
import 'package:gawda_app/features/certificates/presentation/pages/site_dashboard_page.dart';
import 'package:gawda_app/features/certificates/presentation/pages/site_records_page.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/localized_app.dart';

class MockCertificatesRepository extends Mock implements CertificatesRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

const _s1 = Site(id: 's1', code: 'A01', name: 'North Tower', isActive: true);

Certificate _cert(DateTime date, CertificateStatus status, String id) => Certificate(
  id: id,
  siteId: 's1',
  certificateDate: date,
  periodYear: date.year,
  periodMonth: date.month,
  periodHalf: periodHalfOf(date),
  amount: '2500',
  status: status,
  createdBy: 'u1',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  final l10n = AppLocalizationsAr();
  late MockCertificatesRepository certs;
  late MockSitesRepository sites;

  setUp(() {
    certs = MockCertificatesRepository();
    sites = MockSitesRepository();
    when(() => sites.list()).thenAnswer((_) async => const Right([_s1]));
  });

  Future<void> pump(WidgetTester tester, Widget page, List<Certificate> records) async {
    when(() => certs.listForSite(any())).thenAnswer((_) async => Right(records));
    final cubit = CertificateCubit(certs, sites);
    addTearDown(cubit.close);
    await cubit.loadSitesAndRecords();
    await tester.pumpWidget(wrapLocalized(BlocProvider.value(value: cubit, child: page)));
    await tester.pumpAndSettle();
  }

  group('SiteDashboardPage', () {
    testWidgets('shows the current period certificate with an Arabic status', (tester) async {
      final now = DateTime.now();
      await pump(tester, const SiteDashboardPage(), [_cert(now, CertificateStatus.inReview, 'c1')]);

      expect(find.text(l10n.statusInReview), findsOneWidget);
      expect(find.textContaining('half'), findsNothing);
    });

    testWidgets('shows the empty message when the period has no certificate', (tester) async {
      await pump(tester, const SiteDashboardPage(), []);

      expect(find.text(l10n.noCertificates), findsOneWidget);
      verify(() => certs.listForSite('s1')).called(1);
    });
  });

  group('SiteRecordsPage', () {
    testWidgets('lists certificates with period and status labels', (tester) async {
      await pump(tester, const SiteRecordsPage(), [
        _cert(DateTime(2026, 3, 20), CertificateStatus.approved, 'c1'),
        _cert(DateTime(2026, 4, 2), CertificateStatus.draft, 'c2'),
      ]);

      expect(find.text(l10n.periodLabel(2026, '03', 2)), findsOneWidget);
      expect(find.text(l10n.periodLabel(2026, '04', 1)), findsOneWidget);
      expect(find.text(l10n.statusApproved), findsOneWidget);
      expect(find.text(l10n.statusDraft), findsOneWidget);
    });

    testWidgets('shows the empty state instead of reloading forever', (tester) async {
      await pump(tester, const SiteRecordsPage(), []);

      expect(find.text(l10n.noCertificates), findsOneWidget);
      verify(() => certs.listForSite('s1')).called(1);
    });
  });
}
