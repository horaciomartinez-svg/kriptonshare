import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Resultado de una conversión Office → PDF.
class ConversionResult {
  final Uint8List pdfBytes;
  const ConversionResult(this.pdfBytes);
}

class ConversionException implements Exception {
  final String code;   // 'too_large' | 'unsupported_format' | 'conversion_failed'
                       // | 'conversion_timeout' | 'unauthorized' | 'network'
  final String message;
  const ConversionException(this.code, this.message);
  @override
  String toString() => 'ConversionException($code): $message';
}

/// Cliente del conversion-gateway (Fase 1).
/// Envía el documento Office en texto plano por TLS autenticado con el JWT
/// de Supabase del usuario y devuelve el PDF. El servidor no persiste nada.
class ConversionService {
  final Dio _dio;

  ConversionService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.conversionServiceUrl,
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: AppConstants.conversionTimeout,
              receiveTimeout: AppConstants.conversionTimeout,
            ));

  Future<ConversionResult> convertOfficeToPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String accessToken,
    required int maxBytes, // AppConstants.conversionMaxBytesFor(isPremium: ...)
  }) async {
    if (fileBytes.length > maxBytes) {
      throw ConversionException(
        'too_large',
        'File exceeds the ${maxBytes ~/ (1024 * 1024)} MB limit of your plan.',
      );
    }
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final response = await _dio.post<List<int>>(
        '/v1/convert/office',
        data: form,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return ConversionResult(Uint8List.fromList(response.data!));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String? serverCode;
      int? limitBytes;
      if (data is Map<String, dynamic>) {
        serverCode = data['error'] as String?;
        limitBytes = data['limit_bytes'] as int?;
      }
      final code = serverCode ?? switch (status) {
        401 => 'unauthorized',
        413 => 'too_large',
        415 => 'unsupported_format',
        422 => 'conversion_failed',
        429 => 'rate_limited',
        504 => 'conversion_timeout',
        _ => e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout
            ? 'conversion_timeout'
            : 'network',
      };
      final message = limitBytes != null
          ? 'File exceeds the ${limitBytes ~/ (1024 * 1024)} MB limit of your plan.'
          : 'Conversion error (HTTP ${status ?? '-'})';
      throw ConversionException(code, message);
    }
  }
}
