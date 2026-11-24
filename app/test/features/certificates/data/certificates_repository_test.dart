import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/certificates/data/repositories/certificates_repository_impl.dart';
import 'package:gawda_app/features/certificates/data/services/certificates_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockCertificatesService extends Mock implements CertificatesService {}

const _certRow = <String, dynamic>{
  'id': 'c1',
  'site_id': 's1',
  'certificate_date': '2026-03-01',
  'period_year': 2026,
  'period_month': 3,
  'period_half': 1,
  'amount': '1500.00',
  'notes': null,
  'status': 'draft',
  'return_note': null,
  'created_by': 'u1',
  'submitted_at': null,
  'locked_at': null,
  'deleted_at': null,
  'created_at': '2026-03-01T08:00:00+00:00',
  'updated_at': '2026-03-01T08:00:00+00:00',
};

const _attRow = <String, dynamic>{
  'id': 'a1',
  'certificate_id': 'c1',
  'kind': 'initial',
  'storage_path': 's1/2026/3/1/x.pdf',
  'file_name': 'x.pdf',
  'mime': 'application/pdf',
  'size_bytes': 10,
  'sha256': 'aa',
  'uploaded_by': 'u1',
  'uploaded_at': '2026-03-01T08:00:00+00:00',
  'deleted_at': '2026-03-02T08:00:00+00:00',
  'deleted_by': 'u1',
  'delete_reason': null,
};

void main() {
  late MockCertificatesService service;
  late CertificatesRepositoryImpl repo;

  setUp(() {
    service = MockCertificatesService();
    repo = CertificatesRepositoryImpl(service);
  });

  test('createDraft sends the local date and no status', () async {
    when(() => service.insertCertificate(any())).thenAnswer((_) async => _certRow);

    final result = await repo.createDraft(
      siteId: 's1',
      certificateDate: DateTime(2026, 3, 1),
      amount: '1500.00',
    );

    expect(result.isRight(), isTrue);
    final sent =
        verify(() => service.insertCertificate(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(sent.containsKey('status'), isFalse);
    expect(sent['certificate_date'], '2026-03-01');
    expect(sent['site_id'], 's1');
  });

  test('updateDraft sends the local date', () async {
    when(() => service.updateCertificate(any(), any())).thenAnswer((_) async => _certRow);

    await repo.updateDraft('c1', certificateDate: DateTime(2026, 3, 1));

    final sent =
        verify(() => service.updateCertificate('c1', captureAny())).captured.single
            as Map<String, dynamic>;
    expect(sent, {'certificate_date': '2026-03-01'});
  });

  test('delete calls the delete_certificate RPC with the id', () async {
    when(() => service.deleteCertificate(any())).thenAnswer((_) async => _certRow);

    expect(await repo.delete('c1'), const Right<AppFailure, Unit>(unit));
    verify(() => service.deleteCertificate('c1')).called(1);
  });

  test('delete maps invalid_transition to BusinessRuleFailure', () async {
    when(() => service.deleteCertificate(any()))
        .thenThrow(const PostgrestException(message: 'invalid_transition', code: 'P0001'));

    expect(
      await repo.delete('c1'),
      const Left<AppFailure, Unit>(BusinessRuleFailure('invalid_transition')),
    );
  });

  test('removeAttachment calls the remove_attachment RPC', () async {
    when(() => service.removeAttachment(any())).thenAnswer((_) async => _attRow);

    expect(await repo.removeAttachment('a1'), const Right<AppFailure, Unit>(unit));
    verify(() => service.removeAttachment('a1')).called(1);
  });

  test('removeAttachment maps forbidden to ForbiddenFailure', () async {
    when(() => service.removeAttachment(any()))
        .thenThrow(const PostgrestException(message: 'forbidden', code: 'P0001'));

    expect(await repo.removeAttachment('a1'), const Left<AppFailure, Unit>(ForbiddenFailure()));
  });
}
