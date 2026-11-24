// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttachmentRow _$AttachmentRowFromJson(Map<String, dynamic> json) => _AttachmentRow(
  id: json['id'] as String,
  certificateId: json['certificate_id'] as String,
  kind: json['kind'] as String,
  storagePath: json['storage_path'] as String,
  fileName: json['file_name'] as String,
  mime: json['mime'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  sha256: json['sha256'] as String,
  uploadedBy: json['uploaded_by'] as String,
  uploadedAt: DateTime.parse(json['uploaded_at'] as String),
  deletedAt: json['deleted_at'] == null ? null : DateTime.parse(json['deleted_at'] as String),
  deletedBy: json['deleted_by'] as String?,
  deleteReason: json['delete_reason'] as String?,
);

Map<String, dynamic> _$AttachmentRowToJson(_AttachmentRow instance) => <String, dynamic>{
  'id': instance.id,
  'certificate_id': instance.certificateId,
  'kind': instance.kind,
  'storage_path': instance.storagePath,
  'file_name': instance.fileName,
  'mime': instance.mime,
  'size_bytes': instance.sizeBytes,
  'sha256': instance.sha256,
  'uploaded_by': instance.uploadedBy,
  'uploaded_at': instance.uploadedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'deleted_by': instance.deletedBy,
  'delete_reason': instance.deleteReason,
};
