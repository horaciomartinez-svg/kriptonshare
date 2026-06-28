// lib/services/r2_signature_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Firma peticiones AWS Signature Version 4 para Cloudflare R2 (S3-compatible).
///
/// Cloudflare R2 utiliza la región fija `'auto'` y el servicio `'s3'`.
/// Este servicio genera los headers `Authorization`, `x-amz-date`,
/// `x-amz-content-sha256` y `host` necesarios para PUT, GET y DELETE de objetos.
class R2SignatureService {
  final String accessKeyId;
  final String secretAccessKey;
  final String endpoint;
  final String region;
  final String service;

  const R2SignatureService({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.endpoint,
    this.region = 'auto',
    this.service = 's3',
  });

  /// Firma una petición HTTP y retorna el mapa de headers completos listos para enviar.
  ///
  /// [method]      HTTP method en mayúsculas o minúsculas ('PUT', 'GET', 'DELETE').
  /// [path]        Ruta del objeto incluyendo el bucket, ej. '/kriptonshare-ephemeral/uuid'.
  /// [queryParams] Parámetros de query string (opcional).
  /// [headers]     Headers adicionales del usuario (opcional). No deben incluir 'host',
  ///               'x-amz-date' ni 'x-amz-content-sha256' porque este método los genera.
  /// [payloadHash] Hash SHA256 hex del payload. Si es null, usa 'UNSIGNED-PAYLOAD'.
  Map<String, String> signRequest({
    required String method,
    required String path,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? payloadHash,
  }) {
    final now = DateTime.now().toUtc();
    final timestamp = _formatTimestamp(now);
    final dateStamp = _formatDate(now);

    final uri = Uri.parse(endpoint);
    final host = uri.host;

    final requestHeaders = <String, String>{
      'host': host,
      'x-amz-date': timestamp,
      'x-amz-content-sha256': payloadHash ?? 'UNSIGNED-PAYLOAD',
      if (headers != null) ...headers,
    };

    final canonicalHeaders = _canonicalHeaders(requestHeaders);
    final signedHeaders = _signedHeaders(requestHeaders);
    final canonicalRequest = [
      method.toUpperCase(),
      _canonicalUri(path),
      _canonicalQueryString(queryParams ?? {}),
      canonicalHeaders,
      signedHeaders,
      payloadHash ?? 'UNSIGNED-PAYLOAD',
    ].join('\n');

    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      timestamp,
      credentialScope,
      canonicalRequestHash,
    ].join('\n');

    final signingKey = _deriveSigningKey(dateStamp);
    final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        'AWS4-HMAC-SHA256 Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    return {
      ...requestHeaders,
      'Authorization': authorization,
    };
  }

  String _formatTimestamp(DateTime dt) {
    return '${_pad4(dt.year)}${_pad2(dt.month)}${_pad2(dt.day)}T${_pad2(dt.hour)}${_pad2(dt.minute)}${_pad2(dt.second)}Z';
  }

  String _formatDate(DateTime dt) {
    return '${_pad4(dt.year)}${_pad2(dt.month)}${_pad2(dt.day)}';
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');
  String _pad4(int n) => n.toString().padLeft(4, '0');

  List<int> _deriveSigningKey(String dateStamp) {
    final kDate = _hmac(utf8.encode('AWS4$secretAccessKey'), utf8.encode(dateStamp));
    final kRegion = _hmac(kDate, utf8.encode(region));
    final kService = _hmac(kRegion, utf8.encode(service));
    final kSigning = _hmac(kService, utf8.encode('aws4_request'));
    return kSigning;
  }

  List<int> _hmac(List<int> key, List<int> message) {
    return Hmac(sha256, key).convert(message).bytes;
  }

  String _canonicalHeaders(Map<String, String> headers) {
    final sorted = headers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return sorted.map((e) => '${e.key.toLowerCase()}:${e.value.trim()}\n').join();
  }

  String _signedHeaders(Map<String, String> headers) {
    final sorted = headers.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted.map((k) => k.toLowerCase()).join(';');
  }

  String _canonicalUri(String path) {
    if (path.isEmpty) return '/';
    final segments = path.split('/').where((s) => s.isNotEmpty).map((s) => Uri.encodeComponent(s)).join('/');
    return '/$segments';
  }

  String _canonicalQueryString(Map<String, String> query) {
    if (query.isEmpty) return '';
    final sorted = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
  }
}
