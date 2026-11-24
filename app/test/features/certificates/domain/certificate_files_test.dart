import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/features/certificates/domain/certificate_files.dart';

void main() {
  group('periodHalfOf', () {
    test('day 15 is the first half', () => expect(periodHalfOf(DateTime(2026, 3, 15)), 1));
    test('day 16 is the second half', () => expect(periodHalfOf(DateTime(2026, 3, 16)), 2));
    test('Feb 29 2028 is the second half', () => expect(periodHalfOf(DateTime(2028, 2, 29)), 2));
    test('Dec 31 is the second half', () => expect(periodHalfOf(DateTime(2026, 12, 31)), 2));
  });

  test('formatDbDate keeps the local calendar date (no UTC shift)', () {
    expect(formatDbDate(DateTime(2026, 3, 1, 0, 0)), '2026-03-01');
    expect(formatDbDate(DateTime(2026, 12, 9, 23, 59)), '2026-12-09');
  });

  test('mimeForFileName maps allowed extensions, case-insensitive', () {
    expect(mimeForFileName('a.pdf'), 'application/pdf');
    expect(mimeForFileName('b.JPG'), 'image/jpeg');
    expect(mimeForFileName('c.jpeg'), 'image/jpeg');
    expect(mimeForFileName('d.png'), 'image/png');
    expect(mimeForFileName('e.gif'), isNull);
    expect(mimeForFileName('noext'), isNull);
  });

  test('buildStoragePath uses site/year/month/half/<id>.<ext>, unpadded', () {
    const site = '0b7f6a3e-1111-4222-8333-944455556666';
    expect(
      buildStoragePath(
        siteId: site,
        certificateDate: DateTime(2026, 3, 16),
        fileName: 'photo.PNG',
        newId: () => 'abc',
      ),
      '$site/2026/3/2/abc.png',
    );
    expect(
      buildStoragePath(
        siteId: site,
        certificateDate: DateTime(2026, 11, 2),
        fileName: 'scan.pdf',
        newId: () => 'x',
      ),
      '$site/2026/11/1/x.pdf',
    );
  });

  test('maxAttachmentBytes is 2 MiB', () => expect(maxAttachmentBytes, 2097152));
}
