import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supported_locales.dart';

const String kLocaleStorageKey = 'selected_user_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier({SupabaseClient? supabase}) : _supabase = supabase, super(kFallbackLocale) {
    _initializeLocale();
  }

  /// Cliente opcional inyectado (para tests). Si es null, se resuelve el
  /// singleton de Supabase solo cuando está inicializado; si no, la
  /// sincronización remota se omite (offline-first).
  final SupabaseClient? _supabase;

  SupabaseClient? get _client {
    if (_supabase != null) return _supabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static List<Locale> get supportedLocales =>
      kSupportedLocales.map((s) => s.locale).toList();

  /// Prioridad: 1) preferencia local explícita → 2) idioma del SO → 3) fallback 'en'
  Future<void> _initializeLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kLocaleStorageKey);

    if (saved != null && isSupportedLanguageCode(saved)) {
      state = Locale(saved);
      return;
    }

    final systemLocale = PlatformDispatcher.instance.locale;
    state = isSupportedLanguageCode(systemLocale.languageCode)
        ? Locale(systemLocale.languageCode)
        : kFallbackLocale;
  }

  /// Cambio manual de idioma: persiste local y, si hay sesión, sincroniza a Supabase.
  Future<void> setLocale(String languageCode) async {
    if (!isSupportedLanguageCode(languageCode)) return;
    state = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocaleStorageKey, languageCode);
    await _pushToRemote(languageCode);
  }

  /// Reconciliación tras login: remoto manda si el usuario nunca eligió en este
  /// dispositivo; en caso contrario, el local se promueve a remoto.
  Future<void> reconcileWithRemote() async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final localChoice = prefs.getString(kLocaleStorageKey);

    try {
      final row = await client
          .from('users')
          .select('preferred_language')
          .eq('id', user.id)
          .single();
      final remote = row['preferred_language'] as String?;

      if (localChoice == null &&
          remote != null &&
          isSupportedLanguageCode(remote)) {
        state = Locale(remote);
        await prefs.setString(kLocaleStorageKey, remote);
      } else if (localChoice != null && localChoice != remote) {
        await _pushToRemote(localChoice);
      }
    } catch (_) {
      // Offline-first: si falla la red, el locale local permanece. Sin crash.
    }
  }

  Future<void> _pushToRemote(String languageCode) async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      await client
          .from('users')
          .update({'preferred_language': languageCode})
          .eq('id', user.id);
    } catch (_) {
      // Se reintentará en el próximo reconcileWithRemote().
    }
  }
}
