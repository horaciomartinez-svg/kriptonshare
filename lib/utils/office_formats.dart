/// Utilidades para detectar documentos convertibles a PDF (Fase 1).
class OfficeFormats {
  static const Set<String> convertibleMimeTypes = {
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.presentation',
    'application/rtf',
    'text/rtf',
  };

  static const Set<String> convertibleExtensions = {
    'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp', 'rtf',
  };

  /// Verdadero si el archivo debe pasar por el servicio de conversión.
  /// [mimeType] puede venir vacío o como application/octet-stream en Android;
  /// en ese caso se decide por extensión de [fileName].
  static bool isConvertible({required String mimeType, required String fileName}) {
    if (convertibleMimeTypes.contains(mimeType.toLowerCase())) return true;
    final parts = fileName.split('.');
    if (parts.length < 2) return false;
    final ext = parts.last.toLowerCase();
    return convertibleExtensions.contains(ext);
  }
}
