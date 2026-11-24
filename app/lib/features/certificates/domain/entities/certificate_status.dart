/// Lifecycle states of a certificate (see `docs/PROJECT_PLAN.md` §4).
enum CertificateStatus {
  draft,
  inReview,
  returned,
  awaitingSignature,
  approved;

  String toDb() => switch (this) {
    CertificateStatus.draft => 'draft',
    CertificateStatus.inReview => 'in_review',
    CertificateStatus.returned => 'returned',
    CertificateStatus.awaitingSignature => 'awaiting_signature',
    CertificateStatus.approved => 'approved',
  };

  static CertificateStatus fromDb(String value) => switch (value) {
    'draft' => CertificateStatus.draft,
    'in_review' => CertificateStatus.inReview,
    'returned' => CertificateStatus.returned,
    'awaiting_signature' => CertificateStatus.awaitingSignature,
    'approved' => CertificateStatus.approved,
    _ => throw FormatException('unknown certificate status: $value'),
  };
}
