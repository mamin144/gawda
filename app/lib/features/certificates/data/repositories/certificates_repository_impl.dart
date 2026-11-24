import 'dart:convert';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/attachment_kind.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/certificate_files.dart';
import '../../domain/repositories/certificates_repository.dart';
import '../models/attachment_row.dart';
import '../models/certificate_row.dart';
import '../services/certificates_service.dart';

class CertificatesRepositoryImpl implements CertificatesRepository {
  CertificatesRepositoryImpl(this._service);

  final CertificatesService _service;

  @override
  Future<Result<List<Certificate>>> listForSite(String siteId) => _guard(() async {
    final rows = await _service.fetchForSite(siteId);
    return rows.map(_toCertificate).toList(growable: false);
  });

  @override
  Future<Result<Certificate>> getById(String id) =>
      _guard(() async => _toCertificate(await _service.fetchById(id)));

  @override
  Future<Result<Certificate>> createDraft({
    required String siteId,
    required DateTime certificateDate,
    required String amount,
    String? notes,
  }) => _guard(
    () async => _toCertificate(
      await _service.insertCertificate({
        'site_id': siteId,
        'certificate_date': formatDbDate(certificateDate),
        'amount': amount,
        'notes': notes,
      }),
    ),
  );

  @override
  Future<Result<Certificate>> updateDraft(
    String id, {
    DateTime? certificateDate,
    String? amount,
    String? notes,
  }) => _guard(() async {
    final values = <String, dynamic>{};
    if (certificateDate != null) {
      values['certificate_date'] = formatDbDate(certificateDate);
    }
    if (amount != null) values['amount'] = amount;
    if (notes != null) values['notes'] = notes;
    return _toCertificate(await _service.updateCertificate(id, values));
  });

  @override
  Future<Result<Unit>> delete(String id) => _guard(() async {
    await _service.deleteCertificate(id);
    return unit;
  });

  @override
  Future<Result<Unit>> removeAttachment(String id) => _guard(() async {
    await _service.removeAttachment(id);
    return unit;
  });

  @override
  Future<Result<Certificate>> submit(String id) => _guard(
    () async => _toCertificate(await _service.submitCertificate(id)),
  );

  @override
  Future<Result<List<Attachment>>> listAttachments(String certificateId) => _guard(() async {
    final rows = await _service.fetchAttachments(certificateId);
    return rows.map(_toAttachment).toList(growable: false);
  });

  @override
  Future<Result<Attachment>> uploadAttachment({
    required String certificateId,
    required AttachmentKind kind,
    required List<int> bytes,
    required String fileName,
    required String mime,
    required String sha256Hex,
    required String storagePath,
  }) => _guard(() async {
    await _service.uploadFile(storagePath, Uint8List.fromList(bytes), mime);
    return _toAttachment(
      await _service.insertAttachment({
        'certificate_id': certificateId,
        'kind': kind.toDb(),
        'storage_path': storagePath,
        'file_name': fileName,
        'mime': mime,
        'size_bytes': bytes.length,
        'sha256': sha256Hex,
      }),
    );
  }, mapError: (error) => _mapUploadError(error));

  @override
  Future<Result<String>> signedUrl(String storagePath) =>
      _guard(() => _service.signedUrl(storagePath));

  @override
  Future<Result<Certificate>> finalize({
    required String certificateId,
    required String actorId,
  }) => _guard(
    () async {
      await _service.finalizeCertificate(certificateId);
      return _toCertificate(await _service.fetchById(certificateId));
    },
    mapError: (error) => _mapFinalizeError(error),
  );

  Certificate _toCertificate(Map<String, dynamic> row) => CertificateRow.fromJson(row).toDomain();

  Attachment _toAttachment(Map<String, dynamic> row) => AttachmentRow.fromJson(row).toDomain();

  AppFailure _mapUploadError(Object error) {
    if (error is StorageException) {
      return ServerFailure(code: error.statusCode ?? 'storage_error', message: error.message);
    }
    return mapExceptionToFailure(error);
  }

  AppFailure _mapFinalizeError(Object error) {
    if (error is FunctionException && error is! FunctionsFetchException) {
      final code = _errorCode(error.details);
      switch ((error.status, code)) {
        case (401, _):
          return const NoSessionFailure();
        case (403, _):
          return const ForbiddenFailure();
        case (404, _):
          return const ServerFailure(code: 'not_found');
        case (409, 'signed_copy_missing'):
          return const BusinessRuleFailure('signed_copy_missing');
        case (409, _):
          return const BusinessRuleFailure('invalid_transition');
        case (500, 'initial_delete_failed'):
          return const ServerFailure(code: 'initial_delete_failed');
        case (500, _):
          return ServerFailure(code: code ?? 'internal_error');
      }
    }
    return mapExceptionToFailure(error);
  }

  static String? _errorCode(Object? details) {
    var body = details;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } on FormatException {
        return null;
      }
    }
    if (body is Map && body['error'] is String) return body['error'] as String;
    return null;
  }

  Future<Result<T>> _guard<T>(
    Future<T> Function() body, {
    AppFailure Function(Object error) mapError = mapExceptionToFailure,
  }) async {
    try {
      return Right(await body());
    } catch (error) {
      return Left(mapError(error));
    }
  }
}
