import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/analytics/services/funnel_metrics_service.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/supported_locales.dart';
import '../models/user_model.dart';
import '../models/trial_start_outcome.dart';
import '../utils/constants.dart';

final loggerProvider = Provider<Logger>((ref) => Logger());

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authProvider = StreamProvider<KriptonUser?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  // El router depende de este stream para decidir autenticación. Si una
  // excepción se propaga aquí, el stream `async*` muere y Riverpod queda en
  // AsyncError para siempre: el login "exitoso" rebota a /auth sin mensaje.
  // Por eso cada error se captura y loguea, y el stream nunca muere.
  await for (final authState in client.auth.onAuthStateChange) {
    if (authState.session != null) {
      final userId = authState.session!.user.id;
      try {
        final userData = await _fetchUserRow(client, userId);
        yield KriptonUser.fromJson(userData);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST116') {
          // Sesión válida pero sin registro en public.users (usuario creado
          // desde el dashboard de Auth, p. ej.). Crearlo aquí también para
          // que el stream nunca quede huérfano y bloquee el acceso.
          debugPrint('[authProvider] PGRST116: public.users ausente para '
              '$userId. Intentando crearlo...');
          final email = authState.session!.user.email;
          try {
            if (email == null || email.isEmpty) {
              debugPrint('[authProvider] Sin email para crear el registro.');
              yield null;
            } else {
              await _upsertUserRecord(client, userId: userId, email: email);
              final userData = await _fetchUserRow(client, userId);
              yield KriptonUser.fromJson(userData);
            }
          } catch (e2) {
            debugPrint('[authProvider] No se pudo crear public.users: $e2');
            yield null;
          }
        } else {
          debugPrint('[authProvider] Error leyendo public.users '
              '(code=${e.code}): ${e.message}');
          yield null;
        }
      } catch (e, st) {
        debugPrint('[authProvider] Error inesperado leyendo public.users: '
            '$e\n$st');
        yield null;
      }
    } else {
      yield null;
    }
  }
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<KriptonUser?>>((ref) {
  return AuthNotifier(ref);
});

/// Lee la fila de public.users del usuario autenticado.
Future<Map<String, dynamic>> _fetchUserRow(SupabaseClient client, String userId) async {
  return await client.from('users').select().eq('id', userId).single();
}

/// Carga el perfil de public.users; si no existe (usuario huérfano anterior al
/// trigger `on_auth_user_created`), lo crea con un upsert idempotente.
///
/// El trigger server-side es la fuente de verdad: en el flujo normal la fila
/// ya existe y aquí solo se hace SELECT (nunca INSERT), evitando 23505/42501.
Future<Map<String, dynamic>> _loadOrCreateUserRow(
  SupabaseClient client, {
  required String userId,
  required String email,
}) async {
  try {
    return await _fetchUserRow(client, userId);
  } on PostgrestException catch (e) {
    if (e.code != 'PGRST116') rethrow;
  }

  await _upsertUserRecord(client, userId: userId, email: email);
  return await _fetchUserRow(client, userId);
}

/// Fallback: crea/actualiza el perfil de un usuario autenticado sin fila.
/// Solo se invoca cuando el SELECT confirmó que la fila no existe.
Future<void> _upsertUserRecord(
  SupabaseClient client, {
  required String userId,
  required String email,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final preferredLanguage =
        prefs.getString(kLocaleStorageKey) ?? kFallbackLocale.languageCode;

    await client.from('users').upsert({
      'id': userId,
      'email': email,
      'subscription_tier': 'free',
      'monthly_links_generated': 0,
      'monthly_links_reset_at': DateTime.now().toIso8601String(),
      'total_storage_used_bytes': 0,
      'max_storage_bytes': PremiumLimits.premiumBaseStorageBytes,
      'preferred_language': preferredLanguage,
    }, onConflict: 'id');
  } on PostgrestException catch (e) {
    // 23505 = unique_violation (race condition). Se ignora.
    if (e.code != '23505') rethrow;
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<KriptonUser?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final client = _ref.read(supabaseClientProvider);
    final session = client.auth.currentSession;

    if (session != null) {
      try {
        final userData = await client
            .from('users')
            .select()
            .eq('id', session.user.id)
            .single();
        state = AsyncValue.data(KriptonUser.fromJson(userData));
      } catch (e) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(supabaseClientProvider);
      debugPrint('[AuthNotifier.signIn] Intentando iniciar sesión con $email');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthNotifier.signIn] Sesión creada: userId=${response.user?.id}');

      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign in failed');
      }

      // El trigger server-side ya creó el perfil; aquí se lee y, solo si
      // faltara (usuario antiguo huérfano), se hace upsert de respaldo.
      final userData = await _loadOrCreateUserRow(
        client,
        userId: user.id,
        email: email,
      );
      state = AsyncValue.data(KriptonUser.fromJson(userData));
      await _ref.read(localeProvider.notifier).reconcileWithRemote();
    } catch (e, st) {
      debugPrint('[AuthNotifier.signIn] Error: tipo=${e.runtimeType} '
          'error=$e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(supabaseClientProvider);
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // El trigger on_auth_user_created ya creó el perfil: se lee (el
        // upsert queda solo como respaldo si faltara). reconcileWithRemote
        // propaga el idioma elegido vía UPDATE, sin insertar.
        final userData = await _loadOrCreateUserRow(
          client,
          userId: response.user!.id,
          email: email,
        );
        state = AsyncValue.data(KriptonUser.fromJson(userData));

        await _ref.read(localeProvider.notifier).reconcileWithRemote();

        await FunnelMetricsService().logEvent('signup_completed');
        await FunnelMetricsService().logEvent('trial_started');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    final client = _ref.read(supabaseClientProvider);
    await client.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUser() async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final userData = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();
      state = AsyncValue.data(KriptonUser.fromJson(userData));
    } catch (e) {
      // Silently fail refresh
    }
  }

  /// Modo prueba: activa/desactiva una suscripción simulada directamente en
  /// Supabase sin pasar por RevenueCat. Solo disponible en debug builds.
  Future<void> setPremiumSimulation(bool enabled, {String tier = 'premium'}) async {
    // Blindaje: la simulación jamás debe otorgar Premium en release.
    if (!kDebugMode) return;
    try {
      final client = _ref.read(supabaseClientProvider);
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final storageBytes = switch (tier) {
        'business' => PremiumLimits.businessBaseStorageBytes,
        'premium' => PremiumLimits.premiumBaseStorageBytes,
        _ => 0,
      };

      await client.from('users').update({
        'subscription_tier': enabled ? tier : 'free',
        'max_storage_bytes': enabled ? storageBytes : 0,
      }).eq('id', currentUser.id);

      await refreshUser();
    } catch (e) {
      // Silently fail
    }
  }

  /// Activa la prueba Premium de 14 días vía RPC SECURITY DEFINER.
  ///
  /// El cliente NUNCA escribe `trial_ends_at` directamente (§7.2.1): la RPC
  /// `start_premium_trial()` valida en servidor que el usuario sea free y que
  /// no haya consumido antes la prueba (impide reactivarla). Tras activar el
  /// trial se recarga el usuario para que todos los límites visibles reflejen
  /// Premium de inmediato (tamaño, duración, links, storage).
  ///
  /// Devuelve el [TrialStartOutcome] con el resultado y el código de error
  /// (`already_used`, `not_eligible`, ...) para feedback localizado.
  Future<TrialStartOutcome> startPremiumTrial() async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return const TrialStartOutcome(started: false, code: 'no_session');
      }

      final result = await client.rpc('start_premium_trial');
      await refreshUser();

      if (result is List && result.isNotEmpty) {
        final row = Map<String, dynamic>.from(result.first as Map);
        return TrialStartOutcome(
          started: row['started'] == true,
          code: row['code'] as String?,
          message: row['message'] as String?,
        );
      }
      return const TrialStartOutcome(started: false, code: 'error');
    } catch (e, st) {
      debugPrint('[AuthNotifier.startPremiumTrial] Error: $e\n$st');
      await refreshUser();
      return TrialStartOutcome.error;
    }
  }

  /// Returns the current effective tier, factoring in trials.
  String getEffectiveTier() {
    final user = state.value;
    return user?.effectiveTier ?? 'free';
  }

  /// Returns true if the current user has premium benefits (including trial).
  bool getIsPremium() {
    final user = state.value;
    return user?.isPremium ?? false;
  }
}
