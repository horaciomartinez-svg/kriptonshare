import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';
import 'core/utils/constants.dart';
import 'core/utils/theme.dart';
import 'features/data_room/data/datasources/local_database_datasource.dart';
import 'features/data_room/data/repositories/crypto_repository_impl.dart';
import 'features/data_room/data/repositories/data_room_repository_impl.dart';
import 'features/data_room/domain/repositories/i_crypto_repository.dart';
import 'features/data_room/domain/repositories/i_data_room_repository.dart';
import 'features/data_room/presentation/notifiers/data_room_notifier.dart';
import 'features/qna/data/datasources/supabase_chat_datasource.dart';
import 'features/qna/data/repositories/qna_repository_impl.dart';
import 'features/qna/domain/repositories/i_qna_repository.dart';
import 'features/telemetry/data/repositories/telemetry_repository_impl.dart';
import 'features/telemetry/domain/repositories/i_telemetry_repository.dart';
import 'features/telemetry/presentation/notifiers/telemetry_notifier.dart';
import 'providers/router_provider.dart';
import 'services/crypto_service.dart';
import 'services/screenshot_service.dart';

// ─── Providers de la nueva arquitectura Clean Architecture ───

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl());

final localDatabaseProvider = Provider<LocalDatabaseDataSource>((ref) {
  return LocalDatabaseDataSource();
});

final cryptoRepositoryProvider = Provider<ICryptoRepository>((ref) {
  return CryptoRepositoryImpl(CryptoService());
});

final dataRoomRepositoryProvider = Provider<IDataRoomRepository>((ref) {
  return DataRoomRepositoryImpl(
    localDB: ref.watch(localDatabaseProvider),
    supabase: Supabase.instance.client,
  );
});

final dataRoomNotifierProvider = StateNotifierProvider<DataRoomNotifier, DataRoomState>((ref) {
  return DataRoomNotifier(
    dataRoomRepository: ref.watch(dataRoomRepositoryProvider),
    cryptoRepository: ref.watch(cryptoRepositoryProvider),
  );
});

final qnaRepositoryProvider = Provider<IQnaRepository>((ref) {
  return QnaRepositoryImpl(
    SupabaseChatDataSource(Supabase.instance.client),
  );
});

final telemetryRepositoryProvider = Provider<ITelemetryRepository>((ref) {
  return TelemetryRepositoryImpl(
    supabase: Supabase.instance.client,
    localDB: ref.watch(localDatabaseProvider),
  );
});

final telemetryNotifierProvider = StateNotifierProvider<TelemetryNotifier, TelemetryState>((ref) {
  return TelemetryNotifier(ref.watch(telemetryRepositoryProvider));
});

// ─── App Entry Point ───

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait for security
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  
  // Initialize screenshot blocker on Android
  await ScreenshotService.initialize();
  
  runApp(
    const ProviderScope(
      child: KriptonShareApp(),
    ),
  );
}

class KriptonShareApp extends ConsumerWidget {
  const KriptonShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'KRIPTONSHARE',
      debugShowCheckedModeBanner: false,
      theme: KriptonTheme.darkTheme,
      routerConfig: router,
    );
  }
}
