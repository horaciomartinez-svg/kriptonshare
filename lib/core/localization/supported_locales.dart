import 'dart:ui';

/// Descriptor de un idioma soportado por KRIPTONSHARE.
class SupportedLocale {
  final Locale locale;
  final String nativeName; // Nombre en su propio idioma (siempre igual, sin traducir)
  final String flagEmoji; // Bandera representativa para el selector

  const SupportedLocale(this.locale, this.nativeName, this.flagEmoji);
}

/// Catálogo único de verdad para los 5 idiomas.
const List<SupportedLocale> kSupportedLocales = [
  SupportedLocale(Locale('es'), 'Español', '🇪🇸'),
  SupportedLocale(Locale('en'), 'English', '🇬🇧'),
  SupportedLocale(Locale('fr'), 'Français', '🇫🇷'),
  SupportedLocale(Locale('de'), 'Deutsch', '🇩🇪'),
  SupportedLocale(Locale('pt'), 'Português', '🇧🇷'),
];

const Locale kFallbackLocale = Locale('en');

bool isSupportedLanguageCode(String code) =>
    kSupportedLocales.any((s) => s.locale.languageCode == code);
