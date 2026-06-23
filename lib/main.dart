import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';
import 'core/utils/theme.dart';
import 'utils/constants.dart';
import 'features/data_room/data/repositories/crypto_repository_impl.dart';
import 'features/data_room/data/repositories/data_room_repository_impl.dart';
import 'features/data_room/domain/repositories/i_crypto_repository.dart';
import 'features/data_room/domain/repositories/i_data_room_repository.dart';
import 'features/data_room/presentation/notifiers/data_room_notifier.dart';
import 'providers/local_database_provider.dart';
import 'features/qna/data/datasources/supabase_chat_datasource.dart';
import 'features/qna/data/repositories/qna_repository_impl.dart';
import 'features/qna/domain/repositories/i_qna_repository.dart';
import 'providers/router_provider.dart';
import 'services/crypto_service.dart';
import 'services/screenshot_service.dart';

// ─── Providers de la nueva arquitectura Clean Architecture ───

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl());

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

class KriptonShareApp extends ConsumerStatefulWidget {
  const KriptonShareApp({super.key});

  @override
  ConsumerState<KriptonShareApp> createState() => _KriptonShareAppState();
}

class _KriptonShareAppState extends ConsumerState<KriptonShareApp> {
  late final AppLinks _appLinks;
  GoRouter? _router;
  Uri? _pendingDeepLink;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle links that opened the app while it was closed.
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (_) {
      // Ignore initial link errors.
    }

    // Handle links when the app is already running.
    _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (_) {
        // Ignore stream errors.
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    final router = _router;
    if (router == null) {
      // Router not ready yet; store for later.
      _pendingDeepLink = uri;
      return;
    }

    // Supported paths:
    //   https://kriptonshare.com/room/<id>
    //   kriptonshare://room/<id>
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'room') {
      final linkId = uri.pathSegments[1];
      router.go('/room/$linkId');
    }
  }

  void _flushPendingDeepLink() {
    final pending = _pendingDeepLink;
    if (pending == null) return;
    _pendingDeepLink = null;
    _handleDeepLink(pending);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    _router = router;

    // Process any deep link that arrived before the router was ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingDeepLink();
    });

    return MaterialApp.router(
      title: 'KRIPTONSHARE',
      debugShowCheckedModeBanner: false,
      theme: KriptonTheme.darkTheme,
      routerConfig: router,
    );
  }
}
