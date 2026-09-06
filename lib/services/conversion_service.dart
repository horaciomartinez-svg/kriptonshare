import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Resultado de una conversión Office → PDF.
class ConversionResult {
  final Uint8List pdfBytes;
  const ConversionResult(this.pdfBytes);
}

class ConversionException implements Exception {
  final String code;
  final String message;
  const ConversionException(this.code, this.message);
  @override
  String toString() => 'ConversionException($code): $message';
}

/// Resuelve la URL efectiva del gateway para conectar con Gotenberg.
///
/// 📱 DISPOSITIVO FÍSICO vs. EMULADOR:
///
/// Un emulador de Android se ejecuta dentro de una máquina virtual en tu PC.
/// Desde dentro del emulador, "localhost" (127.0.0.1) se refiere al propio
/// emulador, NO a tu PC anfitrión. Por eso el emulador proporciona un alias
/// especial: 10.0.2.2, que redirige el tráfico al loopback del host (127.0.0.1).
///
/// Un dispositivo físico real NO tiene ese alias. Para alcanzar el servidor
/// en tu PC, debe usar la IP LAN real de tu máquina (ej: 192.168.0.21).
/// Además, tanto el teléfono como el PC deben estar conectados a la misma
/// red Wi-Fi, de lo contrario no habrá conectividad entre ellos.
///
/// Estrategia:
///   1) En modo debug + Android → usar la IP LAN real del host (dispositivo físico).
///   2) En release o no-Android → usar la URL configurada via --dart-define.
String _resolveGatewayUrl() {
  const baseUrl = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://192.168.0.21:8080',
  );
  if (kDebugMode && Platform.isAndroid) {
    debugPrint('[CONVERSION] Debug + Android → host LAN IP: $baseUrl');
    return baseUrl;
  }

  const raw = AppConstants.conversionServiceUrl;
  debugPrint('[CONVERSION] Using configured URL: $raw');
  return raw;
}

/// Patrón Fail-Fast: Verificación rápida del servidor antes de iniciar la conversión.
///
/// El objetivo es detectar problemas de conectividad en ~3s, antes de lanzar
/// una petición POST de 60s. Esto mejora la UX al evitar pantallas congeladas
/// durante un minuto completo cuando el dispositivo y el PC no están en la misma red.
///
/// Si el servidor responde con 404 o 405 (esperado al hacer GET a la raíz),
/// se ignora el error porque significa que el servidor SÍ está vivo.
Future<void> checkServerHealth(Dio dio, String gatewayUrl) async {
  try {
    await dio.get(
      gatewayUrl,
      options: Options(
        connectTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      throw ConversionException(
        'network',
        'No se puede alcanzar el servidor de conversión. Verifique que la IP del PC siga siendo 192.168.0.21',
      );
    }
    if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
      return;
    }
  }
}

/// Cliente del conversion-gateway (Fase 1).
/// Envía el documento Office en texto plano por TLS autenticado con el JWT
/// de Supabase del usuario y devuelve el PDF. El servidor no persiste nada.
class ConversionService {
  final Dio _dio;
  final String gatewayUrl;

  factory ConversionService({Dio? dio}) {
    final baseUrl = _resolveGatewayUrl();
    debugPrint('[CONVERSION] Gateway URL: $baseUrl');
    return ConversionService._(
      dio ?? Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      )),
      baseUrl,
    );
  }

  ConversionService._(this._dio, this.gatewayUrl);

  Future<ConversionResult> convertOfficeToPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String accessToken,
    required int maxBytes,
  }) async {
    // Patrón Fail-Fast: Verificar conectividad antes de iniciar la conversión.
    // Esto permite detectar problemas de red en ~3s, evitando que la UI
    // se congele durante 60s si el servidor no es alcanzable.
    await checkServerHealth(_dio, gatewayUrl);

    if (fileBytes.length > maxBytes) {
      throw ConversionException(
        'too_large',
        'File exceeds the ${maxBytes ~/ (1024 * 1024)} MB limit of your plan.',
      );
    }
    final endpoint = '$gatewayUrl/v1/convert/office';
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
      final rootCause = e.error;
      debugPrint('[CONVERSION] Error Dio: code=$code status=$status '
          'serverError=$serverCode tipo=${e.type} '
          'rootCause=${rootCause?.runtimeType ?? rootCause}');
      final message = switch (code) {
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
