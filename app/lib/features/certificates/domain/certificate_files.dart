/// Pure helpers for certificate dates and attachment files. They mirror the
/// database rules: `period_half` (day 1–15 → 1, else 2), the storage path
/// format checked by `private.path_site_id`, and the allowed file types.
library;

/// Maximum attachment size accepted by the `certificates` bucket (2 MiB).
const maxAttachmentBytes = 2097152;

/// Half of the month for [d]: days 1–15 are 1, the rest are 2.
int periodHalfOf(DateTime d) => d.day <= 15 ? 1 : 2;

/// `YYYY-MM-DD` from the local calendar fields of [d], with no UTC shift.
String formatDbDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

const _mimeByExtension = {
  'pdf': 'application/pdf',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
};

String? _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toLowerCase();
}

/// MIME type for an allowed file name, or null when the type is not allowed.
String? mimeForFileName(String name) => _mimeByExtension[_extensionOf(name)];

/// `site/year/month/half/<id>.<ext>` with unpadded month and half, as the
/// storage policies require. The extension is lower-cased.
String buildStoragePath({
  required String siteId,
  required DateTime certificateDate,
  required String fileName,
  required String Function() newId,
}) {
  final ext = _extensionOf(fileName);
  final name = ext == null ? newId() : '${newId()}.$ext';
  return '$siteId/${certificateDate.year}/${certificateDate.month}/'
      '${periodHalfOf(certificateDate)}/$name';
}
