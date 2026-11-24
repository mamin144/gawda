import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/certificates/domain/entities/attachment.dart';
import 'package:gawda_app/features/certificates/domain/entities/attachment_kind.dart';
import 'package:gawda_app/features/certificates/domain/entities/certificate.dart';
import 'package:gawda_app/features/certificates/domain/entities/certificate_status.dart';
import 'package:gawda_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:gawda_app/features/certificates/presentation/bloc/certificate_cubit.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCertificatesRepository extends Mock implements CertificatesRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

Certificate _cert({String id = 'c1', CertificateStatus status = CertificateStatus.draft}) =>
    Certificate(
      id: id,
      siteId: 's1',
      certificateDate: DateTime(2026, 3, 1),
      periodYear: 2026,
      periodMonth: 3,
      periodHalf: 1,
      amount: '10',
      status: status,
      createdBy: 'u1',
      createdAt: DateTime.utc(2026, 3, 1),
      updatedAt: DateTime.utc(2026, 3, 1),
    );

final _att = Attachment(
  id: 'a1',
  certificateId: 'c1',
  kind: AttachmentKind.initial,
  storagePath: 's1/2026/3/1/a.pdf',
  fileName: 'a.pdf',
  mime: 'application/pdf',
  sizeBytes: 10,
  sha256: 'aa',
  uploadedBy: 'u1',
  uploadedAt: DateTime.utc(2026, 3, 1),
);

const _site = Site(id: 's1', code: 'A01', name: 'Site', isActive: true, archivedAt: null);

void main() {
  late MockCertificatesRepository certs;
  late MockSitesRepository sites;
  late CertificateCubit cubit;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    certs = MockCertificatesRepository();
    sites = MockSitesRepository();
    when(() => sites.list()).thenAnswer((_) async => const Right([_site]));
    cubit = CertificateCubit(certs, sites, autoSaveDelay: const Duration(milliseconds: 20));
  });

  tearDown(() => cubit.close());

  void stubCreate([Certificate? c]) => when(
    () => certs.createDraft(
      siteId: any(named: 'siteId'),
      certificateDate: any(named: 'certificateDate'),
      amount: any(named: 'amount'),
      notes: any(named: 'notes'),
    ),
  ).thenAnswer((_) async => Right(c ?? _cert()));

  void stubUpdate() => when(
    () => certs.updateDraft(
      any(),
      certificateDate: any(named: 'certificateDate'),
      amount: any(named: 'amount'),
      notes: any(named: 'notes'),
    ),
  ).thenAnswer((_) async => Right(_cert()));

  void verifyNoCreate() => verifyNever(
    () => certs.createDraft(
      siteId: any(named: 'siteId'),
      certificateDate: any(named: 'certificateDate'),
      amount: any(named: 'amount'),
      notes: any(named: 'notes'),
    ),
  );

  Future<bool> save([String amount = '10']) =>
      cubit.saveDraft(siteId: 's1', date: DateTime(2026, 3, 1), amount: amount, notes: null);

  test('first save creates the draft, the second updates it', () async {
    await cubit.loadSites();
    stubCreate();
    stubUpdate();

    expect(await save(), isTrue);
    expect(await save('20'), isTrue);

    verify(
      () => certs.createDraft(
        siteId: 's1',
        certificateDate: DateTime(2026, 3, 1),
        amount: '10',
        notes: null,
      ),
    ).called(1);
    verify(
      () =>
          certs.updateDraft('c1', certificateDate: DateTime(2026, 3, 1), amount: '20', notes: null),
    ).called(1);
    expect((cubit.state as CertificateLoaded).certificate, _cert());
  });

  test('two concurrent saves create only once', () async {
    await cubit.loadSites();
    final gate = Completer<void>();
    when(
      () => certs.createDraft(
        siteId: any(named: 'siteId'),
        certificateDate: any(named: 'certificateDate'),
        amount: any(named: 'amount'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async {
      await gate.future;
      return Right(_cert());
    });
    stubUpdate();

    final first = save();
    final second = save('20');
    gate.complete();
    await Future.wait([first, second]);

    verify(
      () => certs.createDraft(
        siteId: any(named: 'siteId'),
        certificateDate: any(named: 'certificateDate'),
        amount: any(named: 'amount'),
        notes: any(named: 'notes'),
      ),
    ).called(1);
    verify(
      () => certs.updateDraft(
        'c1',
        certificateDate: any(named: 'certificateDate'),
        amount: '20',
        notes: any(named: 'notes'),
      ),
    ).called(1);
  });

  test('a certificate that is not draft or returned is not saved', () async {
    await cubit.loadSites();
    stubCreate(_cert(status: CertificateStatus.inReview));
    await save();

    expect(await save('20'), isFalse);

    verifyNever(
      () => certs.updateDraft(
        any(),
        certificateDate: any(named: 'certificateDate'),
        amount: any(named: 'amount'),
        notes: any(named: 'notes'),
      ),
    );
    expect(
      (cubit.state as CertificateLoaded).actionError,
      const BusinessRuleFailure('invalid_transition'),
    );
  });

  test('auto-save fires once after the debounce for several edits', () async {
    await cubit.loadSites();
    stubCreate();

    cubit
      ..scheduleAutoSave(siteId: 's1', date: DateTime(2026, 3, 1), amount: '1', notes: null)
      ..scheduleAutoSave(siteId: 's1', date: DateTime(2026, 3, 1), amount: '12', notes: null)
      ..scheduleAutoSave(siteId: 's1', date: DateTime(2026, 3, 1), amount: '123', notes: null);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    verify(
      () => certs.createDraft(
        siteId: 's1',
        certificateDate: DateTime(2026, 3, 1),
        amount: '123',
        notes: null,
      ),
    ).called(1);
  });

  test('auto-save is skipped with an empty amount or no site', () async {
    await cubit.loadSites();
    stubCreate();

    cubit.scheduleAutoSave(siteId: 's1', date: DateTime(2026, 3, 1), amount: '  ', notes: null);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    cubit.scheduleAutoSave(siteId: null, date: DateTime(2026, 3, 1), amount: '5', notes: null);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNoCreate();
  });

  test('closing the cubit cancels a pending auto-save', () async {
    await cubit.loadSites();
    stubCreate();

    cubit.scheduleAutoSave(siteId: 's1', date: DateTime(2026, 3, 1), amount: '5', notes: null);
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNoCreate();
  });

  test('deleteCertificate clears the open certificate', () async {
    await cubit.loadSites();
    stubCreate();
    await save();
    when(() => certs.delete(any())).thenAnswer((_) async => const Right(unit));

    expect(await cubit.deleteCertificate('c1'), isTrue);

    final s = cubit.state as CertificateLoaded;
    expect(s.certificate, isNull);
    expect(s.attachments, isEmpty);
    verify(() => certs.delete('c1')).called(1);
  });

  test('removeAttachment reloads the attachments', () async {
    await cubit.loadSites();
    stubCreate();
    await save();
    when(() => certs.removeAttachment(any())).thenAnswer((_) async => const Right(unit));
    when(() => certs.listAttachments(any())).thenAnswer((_) async => Right([_att]));

    expect(await cubit.removeAttachment('a9'), isTrue);

    verify(() => certs.removeAttachment('a9')).called(1);
    verify(() => certs.listAttachments('c1')).called(1);
    expect((cubit.state as CertificateLoaded).attachments, [_att]);
  });

  test('a failed delete surfaces actionError and keeps the certificate', () async {
    await cubit.loadSites();
    stubCreate();
    await save();
    when(() => certs.delete(any())).thenAnswer((_) async => const Left(ForbiddenFailure()));

    expect(await cubit.deleteCertificate('c1'), isFalse);

    final s = cubit.state as CertificateLoaded;
    expect(s.actionError, const ForbiddenFailure());
    expect(s.certificate, _cert());
  });

  test('loadSitesAndRecords loads the first site records once', () async {
    when(() => certs.listForSite(any())).thenAnswer((_) async => Right([_cert()]));

    await cubit.loadSitesAndRecords();

    verify(() => certs.listForSite('s1')).called(1);
    final s = cubit.state as CertificateLoaded;
    expect(s.sites, [_site]);
    expect(s.records, [_cert()]);
  });

  test('loadSitesAndRecords with no sites does not query records', () async {
    when(() => sites.list()).thenAnswer((_) async => const Right(<Site>[]));

    await cubit.loadSitesAndRecords();

    verifyNever(() => certs.listForSite(any()));
    expect(cubit.state, const CertificateLoaded(sites: []));
  });

  test('loadRecords keeps the open certificate', () async {
    await cubit.loadSites();
    stubCreate();
    await save();
    when(() => certs.listForSite(any())).thenAnswer((_) async => Right([_cert(id: 'c2')]));

    await cubit.loadRecords('s1');

    final s = cubit.state as CertificateLoaded;
    expect(s.certificate, _cert());
    expect(s.records, [_cert(id: 'c2')]);
  });
}
