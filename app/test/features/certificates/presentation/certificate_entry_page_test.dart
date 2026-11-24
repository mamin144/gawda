import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/features/certificates/domain/entities/attachment.dart';
import 'package:gawda_app/features/certificates/domain/entities/attachment_kind.dart';
import 'package:gawda_app/features/certificates/domain/entities/certificate.dart';
import 'package:gawda_app/features/certificates/domain/entities/certificate_status.dart';
import 'package:gawda_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:gawda_app/features/certificates/presentation/bloc/certificate_cubit.dart';
import 'package:gawda_app/features/certificates/presentation/pages/certificate_entry_page.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/localized_app.dart';

class MockCertificatesRepository extends Mock implements CertificatesRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

Certificate _cert({CertificateStatus status = CertificateStatus.draft}) => Certificate(
  id: 'c1',
  siteId: 's1',
  certificateDate: DateTime(2026, 3, 1),
  periodYear: 2026,
  periodMonth: 3,
  periodHalf: 1,
  amount: '1500',
  status: status,
  createdBy: 'u1',
  createdAt: DateTime.utc(2026, 3, 1),
  updatedAt: DateTime.utc(2026, 3, 1),
);

final _att = Attachment(
  id: 'a1',
  certificateId: 'c1',
  kind: AttachmentKind.initial,
  storagePath: 's1/2026/3/1/x.pdf',
  fileName: 'invoice.pdf',
  mime: 'application/pdf',
  sizeBytes: 10,
  sha256: 'aa',
  uploadedBy: 'u1',
  uploadedAt: DateTime.utc(2026, 3, 1),
);

const _s1 = Site(id: 's1', code: 'A01', name: 'North Tower', isActive: true);
const _s2 = Site(id: 's2', code: 'B02', name: 'Old Depot', isActive: true);

void main() {
  final l10n = AppLocalizationsAr();
  late MockCertificatesRepository certs;
  late MockSitesRepository sites;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    certs = MockCertificatesRepository();
    sites = MockSitesRepository();
    when(() => sites.list()).thenAnswer((_) async => const Right([_s1, _s2]));
    when(
      () => certs.createDraft(
        siteId: any(named: 'siteId'),
        certificateDate: any(named: 'certificateDate'),
        amount: any(named: 'amount'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => Right(_cert()));
  });

  Future<CertificateCubit> pump(WidgetTester tester) async {
    final cubit = CertificateCubit(certs, sites, autoSaveDelay: const Duration(milliseconds: 10));
    addTearDown(cubit.close);
    await cubit.loadSites();
    await tester.pumpWidget(
      wrapLocalized(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: CertificateEntryBody()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> openExisting(WidgetTester tester, CertificateCubit cubit, Certificate cert) async {
    when(() => certs.getById(any())).thenAnswer((_) async => Right(cert));
    when(() => certs.listAttachments(any())).thenAnswer((_) async => Right([_att]));
    await cubit.openCertificate('c1');
    await tester.pumpAndSettle();
  }

  Finder amountField() => find.widgetWithText(TextFormField, l10n.certificateAmount);

  testWidgets('renders inside the host Scaffold without a nested one', (tester) async {
    await pump(tester);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('first site is preselected and save creates the draft for it', (tester) async {
    await pump(tester);
    expect(find.text('North Tower'), findsOneWidget);

    await tester.enterText(amountField(), '1500');
    await tester.tap(find.text(l10n.certificateSaveDraft));
    await tester.pumpAndSettle();

    verify(
      () => certs.createDraft(
        siteId: 's1',
        certificateDate: any(named: 'certificateDate'),
        amount: '1500',
        notes: null,
      ),
    ).called(1);
    expect(find.text(l10n.certificateDraftSaved), findsOneWidget);
  });

  testWidgets('editing the amount auto-saves after the quiet period', (tester) async {
    await pump(tester);

    await tester.enterText(amountField(), '٧٧');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    verify(
      () => certs.createDraft(
        siteId: 's1',
        certificateDate: any(named: 'certificateDate'),
        amount: '77',
        notes: null,
      ),
    ).called(1);
  });

  testWidgets('an invalid amount shows an inline error and is not saved', (tester) async {
    await pump(tester);

    await tester.enterText(amountField(), '12.345');
    await tester.tap(find.text(l10n.certificateSaveDraft));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text(l10n.certificateAmountInvalid), findsOneWidget);
    verifyNever(
      () => certs.createDraft(
        siteId: any(named: 'siteId'),
        certificateDate: any(named: 'certificateDate'),
        amount: any(named: 'amount'),
        notes: any(named: 'notes'),
      ),
    );
  });

  testWidgets('the status is shown with its Arabic label', (tester) async {
    final cubit = await pump(tester);
    await openExisting(tester, cubit, _cert(status: CertificateStatus.returned));

    expect(find.textContaining(l10n.statusReturned), findsOneWidget);
    expect(find.textContaining('returned'), findsNothing);
    expect(find.text(l10n.attachmentKindInitial), findsOneWidget);
  });

  testWidgets('delete asks for confirmation, then deletes the draft', (tester) async {
    final cubit = await pump(tester);
    await openExisting(tester, cubit, _cert());
    when(() => certs.delete(any())).thenAnswer((_) async => const Right(unit));

    await tester.ensureVisible(find.text(l10n.certificateDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.certificateDelete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.certificateDeleteConfirmTitle), findsOneWidget);
    await tester.tap(find.text(l10n.deleteButton));
    await tester.pumpAndSettle();

    verify(() => certs.delete('c1')).called(1);
    expect(find.text(l10n.certificateDelete), findsNothing);
  });

  testWidgets('removing an attachment asks first, then removes it', (tester) async {
    final cubit = await pump(tester);
    await openExisting(tester, cubit, _cert());
    when(() => certs.removeAttachment(any())).thenAnswer((_) async => const Right(unit));

    await tester.ensureVisible(find.byTooltip(l10n.attachmentRemove));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.attachmentRemove));
    await tester.pumpAndSettle();
    expect(find.text(l10n.attachmentRemoveConfirmTitle), findsOneWidget);
    await tester.tap(find.text(l10n.deleteButton));
    await tester.pumpAndSettle();

    verify(() => certs.removeAttachment('a1')).called(1);
  });

  testWidgets('a certificate under review is read-only', (tester) async {
    final cubit = await pump(tester);
    await openExisting(tester, cubit, _cert(status: CertificateStatus.inReview));

    expect(find.text(l10n.certificateDelete), findsNothing);
    expect(find.byTooltip(l10n.attachmentRemove), findsNothing);
    final field = tester.widget<TextField>(
      find.descendant(of: amountField(), matching: find.byType(TextField)),
    );
    expect(field.readOnly, isTrue);
    expect(find.text('1500'), findsOneWidget);
  });
}
