/// Kind of an attachment on a certificate.
enum AttachmentKind {
  initial,
  signed;

  String toDb() => name;

  static AttachmentKind fromDb(String value) => switch (value) {
    'initial' => AttachmentKind.initial,
    'signed' => AttachmentKind.signed,
    _ => throw FormatException('unknown attachment kind: $value'),
  };
}
