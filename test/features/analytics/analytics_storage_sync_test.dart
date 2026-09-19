import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/core/error/failures.dart';
import 'package:kriptonshare/features/analytics/analytics_providers.dart';
import 'package:kriptonshare/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:kriptonshare/features/analytics/domain/entities/dashboard_metrics_entity.dart';
import 'package:kriptonshare/features/analytics/domain/entities/link_analytics_detail_entity.dart';
import 'package:kriptonshare/features/analytics/domain/repositories/i_analytics_repository.dart';
import 'package:kriptonshare/features/analytics/domain/usecases/get_dashboard_metrics.dart';
import 'package:kriptonshare/features/analytics/domain/usecases/get_events.dart';
import 'package:kriptonshare/features/analytics/domain/usecases/get_link_analytics_detail.dart';
import 'package:kriptonshare/features/analytics/presentation/notifiers/analytics_notifier.dart';
import 'package:kriptonshare/features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import 'package:kriptonshare/l10n/app_localizations.dart';
import 'package:kriptonshare/models/active_links_summary.dart';
import 'package:kriptonshare/models/kripton_file.dart';
import 'package:kriptonshare/providers/auth_provider.dart';
import 'package:kriptonshare/providers/file_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int _mb = 1024 * 1024;

/// Repositorio fake: devuelve métricas fijas sin tocar Supabase.
class _FakeAnalyticsRepository implements IAnalyticsRepository {
  _FakeAnalyticsRepository(this._metrics);

  final DashboardMetricsEntity _metrics;

  @override
  Future<dartz.Either<Failure, List<AnalyticsEventEntity>>> getEventsByLinkId(
    String linkId,
  ) async =>
      const dartz.Right([]);

  @override
  Future<dartz.Either<Failure, DashboardMetricsEntity>> getDashboardMetrics(
    String ownerId,
  ) async =>
      dartz.Right(_metrics);

  @override
  Future<dartz.Either<Failure, LinkAnalyticsDetailEntity>>
      getLinkAnalyticsDetail(String linkId) async {
    throw UnimplementedError();
  }
}

/// Notifier con métricas ya cargadas: evita el fetch RPC al abrir la pantalla.
AnalyticsNotifier _buildNotifier(DashboardMetricsEntity metrics) {
  final repo = _FakeAnalyticsRepository(metrics);
  return AnalyticsNotifier(
    getEvents: GetEventsUseCase(repo),
    getDashboardMetrics: GetDashboardMetricsUseCase(repo),
    getLinkDetail: GetLinkAnalyticsDetailUseCase(repo),
  )..state = AnalyticsState(metrics: metrics);
}

DashboardMetricsEntity _buildMetrics() {
  return DashboardMetricsEntity(
    totalLinks: 2,
    activeLinks: 2,
    expiredLinks: 0,
    totalViews: 0,
    totalDownloads: 0,
    averageViewDurationMs: 0,
    eventsLast24h: 0,
    topLinks: const [],
    generatedAt: DateTime(2026, 9, 16),
  );
}

ShareLink _link({
  required String id,
  required int fileSizeBytes,
  bool isActive = true,
  DateTime? now,
}) {
  final reference = now ?? DateTime(2026, 9, 16, 12);
  return ShareLink(
    id: id,
    fileId: 'file-$id',
    createdBy: 'user-1',
    expiresAt: reference.add(const Duration(hours: 1)),
    createdAt: reference,
    isActive: isActive,
    fileSizeBytes: fileSizeBytes,
  );
}

/// Estado mutable de los links para simular la revocación en caliente.
final _linksProvider = StateProvider<List<ShareLink>>((ref) => const []);

void main() {
  final fakeSupabaseClient = SupabaseClient(
    'https://fake.supabase.co',
    'fake-anon-key',
  );

  Widget buildScreen(DashboardMetricsEntity metrics) {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(fakeSupabaseClient),
        analyticsNotifierProvider.overrideWith((ref) => _buildNotifier(metrics)),
        userLinksProvider.overrideWith((ref) async => ref.watch(_linksProvider)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AnalyticsDashboardScreen(),
      ),
    );
  }

  /// flutter_animate programa timers que deben agotarse antes de terminar el
  /// test (mismo patrón que test/widget_test.dart).
  Future<void> pumpAndSettleAnimations(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('Storage muestra el total vivo calculado desde userLinksProvider', (
    tester,
  ) async {
    final now = DateTime.now();
    final links = [
      _link(id: 'a', fileSizeBytes: 10 * _mb, now: now),
      _link(id: 'b', fileSizeBytes: 48 * _mb, now: now),
    ];

    await tester.pumpWidget(buildScreen(_buildMetrics()));
    // Sembramos los links tras el primer frame para que el provider los lea.
    final element = tester.element(find.byType(AnalyticsDashboardScreen));
    final container = ProviderScope.containerOf(element);
    container.read(_linksProvider.notifier).state = links;
    await tester.pump();
    await tester.pump();

    // 10 MB + 48 MB = 58 MB (mismo cálculo que el chip del Dashboard).
    expect(find.text('58.0 MB'), findsOneWidget);
    await pumpAndSettleAnimations(tester);
  });

  testWidgets('Al revocar un link el Storage baja sin recargar la pantalla', (
    tester,
  ) async {
    final now = DateTime.now();
    final links = [
      _link(id: 'a', fileSizeBytes: 10 * _mb, now: now),
      _link(id: 'b', fileSizeBytes: 48 * _mb, now: now),
    ];

    await tester.pumpWidget(buildScreen(_buildMetrics()));
    final element = tester.element(find.byType(AnalyticsDashboardScreen));
    final container = ProviderScope.containerOf(element);
    container.read(_linksProvider.notifier).state = links;
    await tester.pump();
    await tester.pump();

    expect(find.text('58.0 MB'), findsOneWidget);

    // Simula la revocación: se invalida userLinksProvider (como hace
    // links_screen) y la lista vuelve sin el link de 48 MB.
    links.removeWhere((l) => l.id == 'b');
    container.read(_linksProvider.notifier).state = List.of(links);
    container.invalidate(userLinksProvider);
    await tester.pump();
    await tester.pump();

    expect(find.text('10.0 MB'), findsOneWidget);
    expect(find.text('58.0 MB'), findsNothing);
    await pumpAndSettleAnimations(tester);
  });

  test('analyticsActiveStorageProvider coincide con ActiveLinksSummary', () async {
    final now = DateTime.now();
    final links = [
      _link(id: 'a', fileSizeBytes: 10 * _mb, now: now),
      _link(id: 'b', fileSizeBytes: 48 * _mb, now: now),
      _link(id: 'c', fileSizeBytes: 7 * _mb, isActive: false, now: now),
    ];

    final container = ProviderContainer(overrides: [
      userLinksProvider.overrideWith((ref) async => links),
    ]);
    addTearDown(container.dispose);

    final sub = container.listen(analyticsActiveStorageProvider, (_, __) {});
    final total = await container.read(analyticsActiveStorageProvider.future);
    sub.close();

    // Dashboard y Analytics consumen el mismo cálculo (fuente única).
    expect(total, ActiveLinksSummary.sumActiveFileBytes(links, now: now));
    expect(total, 58 * _mb);
  });
}
