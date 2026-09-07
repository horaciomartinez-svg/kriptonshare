import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/utils/supported_formats.dart';

void main() {
  group('SupportedFormats.isViewable', () {
    test('acepta MIME types exactos', () {
      expect(
        SupportedFormats.isViewable(
          mimeType: 'application/pdf',
          fileName: 'doc.pdf',
        ),
        isTrue,
      );
      expect(
        SupportedFormats.isViewable(
          mimeType: 'text/csv',
          fileName: 'data.csv',
        ),
        isTrue,
      );
    });

    test('acepta prefijos image/ y video/', () {
      expect(
        SupportedFormats.isViewable(
          mimeType: 'image/png',
          fileName: 'pic.png',
        ),
        isTrue,
      );
      expect(
        SupportedFormats.isViewable(
          mimeType: 'video/mp4',
          fileName: 'clip.mp4',
        ),
        isTrue,
      );
    });

    test('acepta por extensión cuando el MIME es application/octet-stream', () {
      expect(
        SupportedFormats.isViewable(
          mimeType: 'application/octet-stream',
          fileName: 'report.pdf',
        ),
        isTrue,
      );
      expect(
        SupportedFormats.isViewable(
          mimeType: 'application/octet-stream',
          fileName: 'image.JPG',
        ),
        isTrue,
      );
    });

    test('extensiones son case-insensitive', () {
      expect(
        SupportedFormats.isViewable(
          mimeType: '',
          fileName: 'README.MD',
        ),
        isTrue,
      );
      expect(
        SupportedFormats.isViewable(
          mimeType: '',
          fileName: 'PICTURE.PNG',
        ),
        isTrue,
      );
    });

    test('rechaza office, ejecutables y comprimidos', () {
      const rejected = <(String, String)>[
        ('application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'report.docx'),
        ('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'book.xlsx'),
        ('application/vnd.openxmlformats-officedocument.presentationml.presentation', 'deck.pptx'),
        ('application/msword', 'old.doc'),
        ('application/vnd.ms-excel', 'old.xls'),
        ('application/vnd.ms-powerpoint', 'old.ppt'),
        ('application/x-msdownload', 'setup.exe'),
        ('application/zip', 'bundle.zip'),
        ('application/octet-stream', 'secret.docx'),
      ];
      for (final (mime, name) in rejected) {
        expect(
          SupportedFormats.isViewable(mimeType: mime, fileName: name),
          isFalse,
          reason: '$name debería rechazarse',
        );
      }
    });
  });

  group('SupportedFormats.viewableListForHumans', () {
    test('muestra la lista contractual de formatos', () {
      expect(
        SupportedFormats.viewableListForHumans,
        'PDF, JPG, JPEG, PNG, GIF, WEBP, BMP, HEIC, TXT, MD, CSV, MP4, MOV, WEBM, MKV',
      );
    });
  });
}
