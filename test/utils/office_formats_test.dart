import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/utils/office_formats.dart';

void main() {
  group('OfficeFormats.isConvertible', () {
    test('detects Word by MIME', () {
      expect(
        OfficeFormats.isConvertible(
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          fileName: 'doc.docx',
        ),
        isTrue,
      );
    });

    test('detects Excel by extension when MIME is octet-stream', () {
      expect(
        OfficeFormats.isConvertible(
          mimeType: 'application/octet-stream',
          fileName: 'budget.xlsx',
        ),
        isTrue,
      );
    });

    test('detects PowerPoint case-insensitively', () {
      expect(
        OfficeFormats.isConvertible(
          mimeType: 'application/vnd.ms-powerpoint',
          fileName: 'DECK.PPTX',
        ),
        isTrue,
      );
    });

    test('detects ODT and RTF', () {
      expect(
        OfficeFormats.isConvertible(mimeType: 'application/vnd.oasis.opendocument.text', fileName: 'a.odt'),
        isTrue,
      );
      expect(
        OfficeFormats.isConvertible(mimeType: 'application/rtf', fileName: 'a.rtf'),
        isTrue,
      );
    });

    test('rejects PDF', () {
      expect(
        OfficeFormats.isConvertible(mimeType: 'application/pdf', fileName: 'doc.pdf'),
        isFalse,
      );
    });

    test('rejects plain text', () {
      expect(
        OfficeFormats.isConvertible(mimeType: 'text/plain', fileName: 'notes.txt'),
        isFalse,
      );
    });

    test('rejects files without extension', () {
      expect(
        OfficeFormats.isConvertible(mimeType: 'application/octet-stream', fileName: 'noextension'),
        isFalse,
      );
    });

    test('rejects executable extension', () {
      expect(
        OfficeFormats.isConvertible(mimeType: 'application/octet-stream', fileName: 'malware.exe'),
        isFalse,
      );
    });
  });
}
