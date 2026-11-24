import 'package:fpdart/fpdart.dart';

import '../../../../core/error/result.dart';
import '../entities/attachment.dart';
import '../entities/attachment_kind.dart';
import '../entities/certificate.dart';

/// Site-user and admin access to certificates. RLS, DB guards and the
/// `finalize-certificate` Edge Function enforce authorization and business
/// rules; failures come back as [Result] lefts.
abstract interface class CertificatesRepository {
  /// Certificates visible to the caller for [siteId] (RLS-filtered).
  Future<Result<List<Certificate>>> listForSite(String siteId);

  Future<Result<Certificate>> getById(String id);

  /// Creates a draft certificate for [siteId] in the period derived from
  /// [certificateDate].
  Future<Result<Certificate>> createDraft({
    required String siteId,
    required DateTime certificateDate,
    required String amount,
    String? notes,
  });

  Future<Result<Certificate>> updateDraft(
    String id, {
    DateTime? certificateDate,
    String? amount,
    String? notes,
  });

  /// Soft-deletes a draft/returned certificate (`delete_certificate` RPC).
  Future<Result<Unit>> delete(String id);

  /// Soft-deletes an attachment of a draft/returned certificate
  /// (`remove_attachment` RPC). The storage object is kept.
  Future<Result<Unit>> removeAttachment(String id);

  /// Submits a draft/returned certificate for review.
  Future<Result<Certificate>> submit(String id);

  Future<Result<List<Attachment>>> listAttachments(String certificateId);

  /// Uploads [bytes] as an attachment of [certificateId]. Duplicate detection
  /// (SHA-256) is the caller's responsibility before calling.
  Future<Result<Attachment>> uploadAttachment({
    required String certificateId,
    required AttachmentKind kind,
    required List<int> bytes,
    required String fileName,
    required String mime,
    required String sha256Hex,
    required String storagePath,
  });

  Future<Result<String>> signedUrl(String storagePath);

  /// Finalizes an awaiting-signature certificate through the Edge Function.
  Future<Result<Certificate>> finalize({
    required String certificateId,
    required String actorId,
  });
}
