import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/attachment_kind.dart';

part 'attachment_row.freezed.dart';
part 'attachment_row.g.dart';

@freezed
abstract class AttachmentRow with _$AttachmentRow {
  const factory AttachmentRow({
    required String id,
    @JsonKey(name: 'certificate_id') required String certificateId,
    required String kind,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'file_name') required String fileName,
    required String mime,
    @JsonKey(name: 'size_bytes') required int sizeBytes,
    required String sha256,
    @JsonKey(name: 'uploaded_by') required String uploadedBy,
    @JsonKey(name: 'uploaded_at') required DateTime uploadedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'deleted_by') String? deletedBy,
    @JsonKey(name: 'delete_reason') String? deleteReason,
  }) = _AttachmentRow;

  factory AttachmentRow.fromJson(Map<String, dynamic> json) => _$AttachmentRowFromJson(json);
}

extension AttachmentRowMapping on AttachmentRow {
  Attachment toDomain() => Attachment(
    id: id,
    certificateId: certificateId,
    kind: AttachmentKind.fromDb(kind),
    storagePath: storagePath,
    fileName: fileName,
    mime: mime,
    sizeBytes: sizeBytes,
    sha256: sha256,
    uploadedBy: uploadedBy,
    uploadedAt: uploadedAt,
    deletedAt: deletedAt,
    deletedBy: deletedBy,
    deleteReason: deleteReason,
  );
}
