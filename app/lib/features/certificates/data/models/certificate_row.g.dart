// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CertificateRow _$CertificateRowFromJson(Map<String, dynamic> json) => _CertificateRow(
  id: json['id'] as String,
  siteId: json['site_id'] as String,
  certificateDate: DateTime.parse(json['certificate_date'] as String),
  periodYear: (json['period_year'] as num).toInt(),
  periodMonth: (json['period_month'] as num).toInt(),
  periodHalf: (json['period_half'] as num).toInt(),
  amount: json['amount'] as String,
  notes: json['notes'] as String?,
  status: json['status'] as String,
  returnNote: json['return_note'] as String?,
  createdBy: json['created_by'] as String,
  submittedAt: json['submitted_at'] == null ? null : DateTime.parse(json['submitted_at'] as String),
  lockedAt: json['locked_at'] == null ? null : DateTime.parse(json['locked_at'] as String),
  deletedAt: json['deleted_at'] == null ? null : DateTime.parse(json['deleted_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CertificateRowToJson(_CertificateRow instance) => <String, dynamic>{
  'id': instance.id,
  'site_id': instance.siteId,
  'certificate_date': instance.certificateDate.toIso8601String(),
  'period_year': instance.periodYear,
  'period_month': instance.periodMonth,
  'period_half': instance.periodHalf,
  'amount': instance.amount,
  'notes': instance.notes,
  'status': instance.status,
  'return_note': instance.returnNote,
  'created_by': instance.createdBy,
  'submitted_at': instance.submittedAt?.toIso8601String(),
  'locked_at': instance.lockedAt?.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
