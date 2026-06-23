import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/local_database_provider.dart';
import 'data/repositories/telemetry_repository_impl.dart';
import 'domain/repositories/i_telemetry_repository.dart';
import 'presentation/notifiers/telemetry_notifier.dart';

/// Repositorio de telemetría: SQLite offline + Supabase eventual.
final telemetryRepositoryProvider = Provider<ITelemetryRepository>((ref) {
  return TelemetryRepositoryImpl(
    supabase: Supabase.instance.client,
    localDB: ref.watch(localDatabaseProvider),
  );
});

/// Notifier de telemetría para auditoría B2B.
final telemetryNotifierProvider = StateNotifierProvider<TelemetryNotifier, TelemetryState>((ref) {
  return TelemetryNotifier(ref.watch(telemetryRepositoryProvider));
});
