import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/certificate.dart';
import '../../domain/entities/certificate_status.dart';

part 'certificate_row.freezed.dart';
part 'certificate_row.g.dart';

@freezed
abstract class CertificateRow with _$CertificateRow {
  const factory CertificateRow({
    required String id,
    @JsonKey(name: 'site_id') required String siteId,
    @JsonKey(name: 'certificate_date') required DateTime certificateDate,
    @JsonKey(name: 'period_year') required int periodYear,
    @JsonKey(name: 'period_month') required int periodMonth,
    @JsonKey(name: 'period_half') required int periodHalf,
    required String amount,
    String? notes,
    required String status,
    @JsonKey(name: 'return_note') String? returnNote,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'submitted_at') DateTime? submittedAt,
    @JsonKey(name: 'locked_at') DateTime? lockedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _CertificateRow;

  factory CertificateRow.fromJson(Map<String, dynamic> json) => _$CertificateRowFromJson(json);
}

extension CertificateRowMapping on CertificateRow {
  Certificate toDomain() => Certificate(
    id: id,
    siteId: siteId,
    certificateDate: certificateDate,
    periodYear: periodYear,
    periodMonth: periodMonth,
    periodHalf: periodHalf,
    amount: amount,
    notes: notes,
    status: CertificateStatus.fromDb(status),
    returnNote: returnNote,
    createdBy: createdBy,
    submittedAt: submittedAt,
    lockedAt: lockedAt,
    deletedAt: deletedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
