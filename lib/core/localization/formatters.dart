import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

/// Formatea una duración en formato compacto localizado ("2m 04s" / "1h 05m").
String formatDurationCompact(BuildContext context, int milliseconds) {
  final l10n = AppLocalizations.of(context);
  final totalSeconds = (milliseconds / 1000).round();
  if (totalSeconds < 60) return l10n.durationSecondsCompact(totalSeconds);

  final minutes = totalSeconds ~/ 60;
  final remainingSeconds = totalSeconds % 60;
  if (minutes < 60) {
    final mm = l10n.durationMinutesCompact(minutes);
    if (remainingSeconds == 0) return mm;
    return '$mm ${_twoDigits(l10n.durationSecondsCompact, remainingSeconds)}';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  final hh = l10n.durationHoursCompact(hours);
  if (remainingMinutes == 0) return hh;
  return '$hh ${_twoDigits(l10n.durationMinutesCompact, remainingMinutes)}';
}

String _twoDigits(String Function(int) format, int value) {
  return format(int.parse(value.toString().padLeft(2, '0')));
}

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
