import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatea una fecha de expiración respetando el locale activo.
///
/// Ejemplos:
/// - es: 28/7/2026 14:35
/// - en: 7/28/2026 14:35
/// - de: 28.7.2026 14:35
String formatExpiry(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(date);
}

/// Formatea bytes a KB/MB/GB respetando el locale activo.
///
/// Ejemplos:
/// - en/es/pt: 2.5 MB
/// - de/fr: 2,5 MB
String formatBytes(BuildContext context, int bytes) {
  final locale = Localizations.localeOf(context).toString();
  final nf = NumberFormat('#,##0.0', locale);
  if (bytes >= 1073741824) {
    return '${nf.format(bytes / 1073741824)} GB';
  }
  if (bytes >= 1048576) {
    return '${nf.format(bytes / 1048576)} MB';
  }
  if (bytes >= 1024) {
    return '${nf.format(bytes / 1024)} KB';
  }
  return '$bytes B';
}
