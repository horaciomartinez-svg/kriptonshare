// lib/core/network/r2_client.dart
// Cliente Dio para stream directo a Cloudflare R2 (S3-compatible).

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../services/r2_signature_service.dart';
import '../../utils/constants.dart';

class R2Client {
  final Dio _dio;
  final R2SignatureService _signer;

  R2Client({
    Dio? dio,
    R2SignatureService? signer,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
              sendTimeout: const Duration(minutes: 5),
            )),
        _signer = signer ??
            const R2SignatureService(
              accessKeyId: AppConstants.r2AccessKeyId,
              secretAccessKey: AppConstants.r2SecretAccessKey,
              endpoint: AppConstants.r2Endpoint,
            );

  String get _endpoint => AppConstants.r2Endpoint;
  String get _bucket => AppConstants.bucketName;

  String _objectUrl(String objectKey) =>
      '$_endpoint/$_bucket/${Uri.encodeComponent(objectKey)}';

  String _objectPath(String objectKey) => '/$_bucket/$objectKey';

  /// Sube un objeto cifrado a R2 vía PUT.
  Future<void> uploadObject({
    required String objectKey,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    final path = _objectPath(objectKey);
    final payloadHash = _sha256Hex(bytes);
    final headers = _signer.signRequest(
      method: 'PUT',
      path: path,
      headers: {'content-type': contentType},
      payloadHash: payloadHash,
    );

    await _dio.put(
      _objectUrl(objectKey),
      data: bytes,
      options: Options(headers: headers),
    );
  }

  /// Descarga un objeto cifrado de R2 vía GET.
  Future<Uint8List> downloadObject(String objectKey) async {
    final path = _objectPath(objectKey);
    final headers = _signer.signRequest(method: 'GET', path: path);

    final response = await _dio.get<List<int>>(
      _objectUrl(objectKey),
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
      ),
    );

    return Uint8List.fromList(response.data!);
  }

  /// Elimina un objeto de R2 vía DELETE.
  Future<void> deleteObject(String objectKey) async {
    final path = _objectPath(objectKey);
    final headers = _signer.signRequest(method: 'DELETE', path: path);

    await _dio.delete(
      _objectUrl(objectKey),
      options: Options(headers: headers),
    );
  }

  /// Hash SHA-256 hex del payload para firmar PUT.
  String _sha256Hex(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
