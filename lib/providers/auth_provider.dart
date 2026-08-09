import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/supported_locales.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

final loggerProvider = Provider<Logger>((ref) => Logger());

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authProvider = StreamProvider<KriptonUser?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  // El router depende de este stream para decidir autenticación. Si una
  // excepción se propaga aquí, el stream `async*` muere y Riverpod queda en
  // AsyncError para siempre: el login "exitoso" rebota a /auth sin mensaje.
  // Por eso TODO error se captura y loguea, y el stream nunca muere.
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
              await _createPublicUserRecord(client, userId: userId, email: email);
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

/// Crea el registro en public.users para un usuario autenticado que aún no
/// tiene fila (por ejemplo, usuarios creados desde el dashboard de Auth).
/// Idempotente: si la fila ya existe (23505 unique_violation), no hace nada.
Future<void> _createPublicUserRecord(
  SupabaseClient client, {
  required String userId,
  required String email,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final preferredLanguage =
        prefs.getString(kLocaleStorageKey) ?? kFallbackLocale.languageCode;

    await client.from('users').insert({
      'id': userId,
      'email': email,
      'subscription_tier': 'free',
      'monthly_links_generated': 0,
      'monthly_links_reset_at': DateTime.now().toIso8601String(),
      'total_storage_used_bytes': 0,
      'max_storage_premium_bytes': AppConstants.premiumMaxStorageBytes,
      'max_storage_bytes': PremiumLimits.premiumBaseStorageBytes,
      'preferred_language': preferredLanguage,
    });
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

      try {
        final userData = await client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        state = AsyncValue.data(KriptonUser.fromJson(userData));
        await _ref.read(localeProvider.notifier).reconcileWithRemote();
      } on PostgrestException catch (e) {
        // Si el registro no existe, intentar crearlo automáticamente.
        // Esto suele ocurrir cuando el UUID en public.users no coincide
        // con auth.users (p. ej. usuario recreado en Auth).
        debugPrint('[AuthNotifier.signIn] PostgrestException al leer users: '
            'code=${e.code} message=${e.message}');
        if (e.code == 'PGRST116') {
          await _ensureUserRecord(client, user.id, email);
          final userData = await client
              .from('users')
              .select()
              .eq('id', user.id)
              .single();
          state = AsyncValue.data(KriptonUser.fromJson(userData));
          await _ref.read(localeProvider.notifier).reconcileWithRemote();
        } else {
          rethrow;
        }
      } catch (e) {
        throw Exception(
          'Authenticated user not found in the users table. '
          'Make sure to run test_users_setup.sql with the correct UUID.',
        );
      }
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
        // Propagar el idioma seleccionado localmente al registro remoto.
        final prefs = await SharedPreferences.getInstance();
        final preferredLanguage =
            prefs.getString(kLocaleStorageKey) ?? kFallbackLocale.languageCode;

        // Create user record in users table
        await client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'subscription_tier': 'free',
          'monthly_links_generated': 0,
          'monthly_links_reset_at': DateTime.now().toIso8601String(),
          'total_storage_used_bytes': 0,
          'max_storage_premium_bytes': AppConstants.premiumMaxStorageBytes,
          'max_storage_bytes': PremiumLimits.premiumBaseStorageBytes,
          'preferred_language': preferredLanguage,
        });

        final userData = await client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();
        state = AsyncValue.data(KriptonUser.fromJson(userData));
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

  /// Crea el registro de usuario en public.users si no existe.
  /// Útil cuando el UUID en auth.users no coincide con public.users.
  Future<void> _ensureUserRecord(SupabaseClient client, String userId, String email) async {
    await _createPublicUserRecord(client, userId: userId, email: email);
  }

  /// Modo prueba Premium: activa/desactiva tier premium directamente en Supabase
  /// sin pasar por RevenueCat. Solo disponible en debug builds.
  Future<void> setPremiumSimulation(bool enabled) async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      await client.from('users').update({
        'subscription_tier': enabled ? 'premium' : 'free',
        'max_storage_bytes': enabled ? PremiumLimits.premiumBaseStorageBytes : 0,
      }).eq('id', currentUser.id);

      await refreshUser();
    } catch (e) {
      // Silently fail
    }
  }
}
