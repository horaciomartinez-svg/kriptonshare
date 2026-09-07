/// Formatos que KRIPTONSHARE acepta porque pueden visualizarse de forma
/// segura dentro de la app (descifrados en memoria, sin apps externas).
class SupportedFormats {
  /// MIME types exactos aceptados.
  static const Set<String> viewableMimeTypes = {
    'application/pdf',
    'text/plain',
    'text/markdown',
    'text/csv',
  };

  /// Prefijos MIME aceptados (imágenes y video reproducibles in-app).
  static const List<String> viewableMimePrefixes = [
    'image/',
    'video/',
  ];

  /// Extensiones aceptadas (fallback cuando el MIME llega vacío o como
  /// application/octet-stream, frecuente en Android).
  static const Set<String> viewableExtensions = {
    // Documentos
    'pdf',
    // Imágenes
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
    // Texto
    'txt', 'md', 'csv', 'log',
    // Video
    'mp4', 'mov', 'webm', 'mkv', 'm4v', '3gp',
  };

  /// Verdadero si el archivo puede visualizarse dentro de la app.
  static bool isViewable({required String mimeType, required String fileName}) {
    final mime = mimeType.toLowerCase();
    if (viewableMimeTypes.contains(mime)) return true;
    if (viewableMimePrefixes.any((p) => mime.startsWith(p))) return true;
    final ext = fileName.split('.').last.toLowerCase();
    return viewableExtensions.contains(ext);
  }

  /// Lista legible para el usuario, usada en el aviso bloqueante.
  /// Orden fija y contractual: se muestra tal cual en los 5 idiomas.
  static const String viewableListForHumans =
      'PDF, JPG, JPEG, PNG, GIF, WEBP, BMP, HEIC, TXT, MD, CSV, MP4, MOV, WEBM, MKV';
}
