import 'package:freezed_annotation/freezed_annotation.dart';

import 'certificate_status.dart';

part 'certificate.freezed.dart';

/// A site's certificate for one half-month period. The period columns are
/// derived by the database from [certificateDate]; they are read-only here.
@freezed
abstract class Certificate with _$Certificate {
  const factory Certificate({
    required String id,
    required String siteId,
    required DateTime certificateDate,
    required int periodYear,
    required int periodMonth,
    required int periodHalf,

    /// Decimal amount as a string to avoid floating-point drift.
    required String amount,
    String? notes,
    required CertificateStatus status,
    String? returnNote,
    required String createdBy,
    DateTime? submittedAt,
    DateTime? lockedAt,
    DateTime? deletedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Certificate;
}
