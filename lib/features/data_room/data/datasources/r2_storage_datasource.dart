import 'dart:typed_data';
import '../../../../core/network/r2_client.dart';

/// Fuente de datos para almacenamiento de blobs cifrados en Cloudflare R2.
class R2StorageDataSource {
  final R2Client _client;

  R2StorageDataSource({R2Client? client}) : _client = client ?? R2Client();

  Future<void> uploadEncryptedObject({
    required String objectKey,
    required Uint8List encryptedBytes,
  }) async {
    await _client.uploadObject(
      objectKey: objectKey,
      bytes: encryptedBytes,
      contentType: 'application/octet-stream',
    );
  }

  Future<Uint8List> downloadEncryptedObject(String objectKey) async {
    return _client.downloadObject(objectKey);
  }

  Future<void> deleteEncryptedObject(String objectKey) async {
    await _client.deleteObject(objectKey);
  }
}
