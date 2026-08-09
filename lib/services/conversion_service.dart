import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
            )) {
    debugPrint('[CONVERSION] Gateway URL: ${AppConstants.conversionServiceUrl}');
  }

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
    const endpoint = '${AppConstants.conversionServiceUrl}/v1/convert/office';
    debugPrint('[CONVERSION] POST $endpoint '
        '($fileName, ${fileBytes.length} bytes, max=$maxBytes)');
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final response = await _dio.post<List<int>>(
        '/v1/convert/office',
        data: form,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $accessToken',
            // ngrok free muestra una página interstitial de aviso en la primera
            // petición de un navegador; este header la desactiva también para
            // clientes HTTP sin necesidad de usar --host-header.
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );
      debugPrint('[CONVERSION] HTTP ${response.statusCode}: '
          '${response.data?.length ?? 0} bytes PDF');
      return ConversionResult(Uint8List.fromList(response.data!));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final raw = e.response?.data;
      String? serverCode;
      int? limitBytes;
      // Con ResponseType.bytes el body de error del gateway llega como bytes,
      // no como Map. Decodificamos los 3 formatos posibles (Map, bytes, String)
      // para extraer `error` y `limit_bytes` del JSON del gateway.
      Map<String, dynamic>? decoded;
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      } else if (raw is List<int>) {
        try {
          final json = jsonDecode(utf8.decode(raw));
          if (json is Map<String, dynamic>) decoded = json;
        } catch (_) {}
      } else if (raw is String) {
        try {
          final json = jsonDecode(raw);
          if (json is Map<String, dynamic>) decoded = json;
        } catch (_) {}
      }
      if (decoded != null) {
        serverCode = decoded['error'] as String?;
        limitBytes = decoded['limit_bytes'] as int?;
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
      // Causa raíz del fallo de red (SocketException, ConnectionError,
      // TimeoutException...) que explica por qué la petición no llegó al gateway.
      final rootCause = e.error;
      // Log de UNA línea y sin stack trace: la vista previa es opcional y no
      // debe saturar la consola. El detalle técnico queda en el mensaje de la UI.
      debugPrint('[CONVERSION] Error Dio: code=$code status=$status '
          'serverError=$serverCode tipo=${e.type} '
          'rootCause=${rootCause?.runtimeType ?? rootCause}');
      final message = switch (code) {
        // 401: mensaje amigable sin ruido técnico (el preview es opcional).
        'unauthorized' => 'Authentication failed. Please sign in again.',
        _ => limitBytes != null
            ? 'File exceeds the ${limitBytes ~/ (1024 * 1024)} MB limit of your plan.'
            : 'Conversion error (HTTP ${status ?? '-'}) '
                '[${e.type}] ${rootCause ?? e.message}',
      };
      throw ConversionException(code, message);
    } catch (e) {
      debugPrint('[CONVERSION] Error inesperado: $e');
      throw ConversionException('network', 'Unexpected conversion error: $e');
    }
  }
}
