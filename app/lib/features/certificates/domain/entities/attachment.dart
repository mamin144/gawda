import 'package:freezed_annotation/freezed_annotation.dart';

import 'attachment_kind.dart';

part 'attachment.freezed.dart';

/// A file attached to a certificate (initial scan or signed copy).
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    required String certificateId,
    required AttachmentKind kind,
    required String storagePath,
    required String fileName,
    required String mime,
    required int sizeBytes,
    required String sha256,
    required String uploadedBy,
    required DateTime uploadedAt,
    DateTime? deletedAt,
    String? deletedBy,
    String? deleteReason,
  }) = _Attachment;
}
