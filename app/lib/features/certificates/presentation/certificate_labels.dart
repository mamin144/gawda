import '../../../l10n/gen/app_localizations.dart';
import '../domain/entities/attachment_kind.dart';
import '../domain/entities/certificate_status.dart';

/// Arabic label for a certificate status (never the raw enum name).
String certificateStatusLabel(CertificateStatus status, AppLocalizations l10n) => switch (status) {
  CertificateStatus.draft => l10n.statusDraft,
  CertificateStatus.inReview => l10n.statusInReview,
  CertificateStatus.returned => l10n.statusReturned,
  CertificateStatus.awaitingSignature => l10n.statusAwaitingSignature,
  CertificateStatus.approved => l10n.statusApproved,
};

/// Arabic label for an attachment kind.
String attachmentKindLabel(AttachmentKind kind, AppLocalizations l10n) => switch (kind) {
  AttachmentKind.initial => l10n.attachmentKindInitial,
  AttachmentKind.signed => l10n.attachmentKindSigned,
};

/// `YYYY-MM (النصف N)` for a certificate period.
String periodLabel(int year, int month, int half, AppLocalizations l10n) =>
    l10n.periodLabel(year, month.toString().padLeft(2, '0'), half);

/// Site users may edit, delete and remove files only while the certificate
/// is a draft or was returned (mirrors the database guards).
bool isEditableStatus(CertificateStatus status) =>
    status == CertificateStatus.draft || status == CertificateStatus.returned;
