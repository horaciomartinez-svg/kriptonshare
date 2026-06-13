import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';

final loggerProvider = Provider<Logger>((ref) => Logger());

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authProvider = StreamProvider<KriptonUser?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  await for (final authState in client.auth.onAuthStateChange) {
    if (authState.session != null) {
      final userData = await client
          .from('users')
          .select()
          .eq('id', authState.session!.user.id)
          .single();

      yield KriptonUser.fromJson(userData);
    } else {
      yield null;
    }
  }
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<KriptonUser?>>((ref) {
  return AuthNotifier(ref);
});

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
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
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

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(supabaseClientProvider);
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user record in users table
        await client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'subscription_tier': 'free',
          'monthly_links_generated': 0,
          'monthly_links_reset_at': DateTime.now().toIso8601String(),
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
}
