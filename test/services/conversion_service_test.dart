import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/services/conversion_service.dart';
import 'package:kriptonshare/utils/constants.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ConversionService service;

  setUp(() {
    mockDio = MockDio();
    service = ConversionService(dio: mockDio);
  });

  group('convertOfficeToPdf', () {
    test('returns PDF bytes on 200', () async {
      final pdfBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      when(() => mockDio.post<List<int>>(
            '/v1/convert/office',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/convert/office'),
          data: pdfBytes,
          statusCode: 200,
        ),
      );

      final result = await service.convertOfficeToPdf(
        fileBytes: Uint8List.fromList([10, 20, 30]),
        fileName: 'doc.docx',
        accessToken: 'token',
        maxBytes: AppConstants.freeMaxFileSizeBytes,
      );

      expect(result.pdfBytes, equals(pdfBytes));
    });

    test('throws too_large when client-side limit exceeded', () async {
      await expectLater(
        () => service.convertOfficeToPdf(
          fileBytes: Uint8List(AppConstants.freeMaxFileSizeBytes + 1),
          fileName: 'doc.docx',
          accessToken: 'token',
          maxBytes: AppConstants.freeMaxFileSizeBytes,
        ),
        throwsA(isA<ConversionException>().having((e) => e.code, 'code', 'too_large')),
      );
      verifyNever(() => mockDio.post<List<int>>(any(), data: any(named: 'data'), options: any(named: 'options')));
    });

    test('throws unauthorized on 401', () async {
      when(() => mockDio.post<List<int>>(
            '/v1/convert/office',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/convert/office'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/convert/office'),
            statusCode: 401,
          ),
        ),
      );

      await expectLater(
        () => service.convertOfficeToPdf(
          fileBytes: Uint8List.fromList([1]),
          fileName: 'doc.docx',
          accessToken: 'token',
          maxBytes: AppConstants.freeMaxFileSizeBytes,
        ),
        throwsA(isA<ConversionException>().having((e) => e.code, 'code', 'unauthorized')),
      );
    });

    test('throws unsupported_format on 415', () async {
      when(() => mockDio.post<List<int>>(
            '/v1/convert/office',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/convert/office'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/convert/office'),
            statusCode: 415,
          ),
        ),
      );

      await expectLater(
        () => service.convertOfficeToPdf(
          fileBytes: Uint8List.fromList([1]),
          fileName: 'doc.exe',
          accessToken: 'token',
          maxBytes: AppConstants.freeMaxFileSizeBytes,
        ),
        throwsA(isA<ConversionException>().having((e) => e.code, 'code', 'unsupported_format')),
      );
    });

    test('throws conversion_timeout on 504', () async {
      when(() => mockDio.post<List<int>>(
            '/v1/convert/office',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/convert/office'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/convert/office'),
            statusCode: 504,
          ),
        ),
      );

      await expectLater(
        () => service.convertOfficeToPdf(
          fileBytes: Uint8List.fromList([1]),
          fileName: 'doc.docx',
          accessToken: 'token',
          maxBytes: AppConstants.freeMaxFileSizeBytes,
        ),
        throwsA(isA<ConversionException>().having((e) => e.code, 'code', 'conversion_timeout')),
      );
    });

    test('throws conversion_timeout on Dio timeout', () async {
      when(() => mockDio.post<List<int>>(
            '/v1/convert/office',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/convert/office'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      await expectLater(
        () => service.convertOfficeToPdf(
          fileBytes: Uint8List.fromList([1]),
          fileName: 'doc.docx',
          accessToken: 'token',
          maxBytes: AppConstants.freeMaxFileSizeBytes,
        ),
        throwsA(isA<ConversionException>().having((e) => e.code, 'code', 'conversion_timeout')),
      );
    });
  });
}
